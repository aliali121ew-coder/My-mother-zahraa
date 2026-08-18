import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/glass.dart';
import '../../../shared/models/contributor_model.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/permissions.dart';
import '../../../shared/widgets/contributor_tile.dart';

enum _SortBy {
  amountDesc('الأعلى مبلغاً'),
  amountAsc('الأقل مبلغاً'),
  nameAsc('الاسم أبجدياً'),
  lateFirst('المتأخرون أولاً');

  const _SortBy(this.label);
  final String label;
}

enum _StatusFilter { all, paid, overdue }
enum _CategoryFilter { all, subscribers, donors, supporters }

/// قائمة المتبرعين أو المشتركين كاملة، مع بحث وفلترة وترتيب كما طُلب.
class ContributorsListPage extends ConsumerStatefulWidget {
  const ContributorsListPage({
    super.key,
    this.showDonors,
    this.showSupporters = false,
    this.showAll = false,
  });

  final bool? showDonors;
  final bool showSupporters;
  final bool showAll;

  @override
  ConsumerState<ContributorsListPage> createState() =>
      _ContributorsListPageState();
}

class _ContributorsListPageState extends ConsumerState<ContributorsListPage> {
  final _search = TextEditingController();
  final _SortBy _sort = _SortBy.amountDesc;
  SubscriptionType? _typeFilter;
  _StatusFilter _statusFilter = _StatusFilter.all;
  _CategoryFilter _categoryFilter = _CategoryFilter.all;

  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    if (widget.showDonors != true && !widget.showSupporters && !widget.showAll) {
      _typeFilter = SubscriptionType.monthly;
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final async = (widget.showAll || widget.showSupporters)
        ? ref.watch(allContributorsProvider)
        : (widget.showDonors == true
            ? ref.watch(donorsProvider)
            : ref.watch(subscribersProvider));

    final title = widget.showAll
        ? 'عرض الكل — كافة السجلات'
        : (widget.showSupporters
            ? 'قائمة الداعمين والمساهمين'
            : (widget.showDonors == true ? 'قائمة المتبرعين' : 'قائمة المشتركين'));

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: _isSelectionMode
            ? Center(
                child: Container(
                  width: 36,
                  height: 36,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.close_rounded, size: 20),
                    tooltip: 'إلغاء التحديد',
                    onPressed: () => setState(() {
                      _isSelectionMode = false;
                      _selectedIds.clear();
                    }),
                  ),
                ),
              )
            : null,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: _isSelectionMode
              ? AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: _selectedIds.isNotEmpty
                        ? const LinearGradient(
                            colors: [AppColors.goldDark, AppColors.gold],
                          )
                        : null,
                    color: _selectedIds.isEmpty
                        ? (isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.05))
                        : null,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.6),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _selectedIds.isEmpty
                        ? 'حدد العناصر للحذف'
                        : 'تم تحديد ${_selectedIds.length} عنصر',
                    style: TextStyle(
                      fontFamily: AppTheme.displayFamily,
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
                      color: _selectedIds.isNotEmpty
                          ? Colors.black
                          : (isDark
                              ? AppColors.goldBright
                              : AppColors.goldDark),
                    ),
                  ),
                )
              : Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        actions: [
          if (_isSelectionMode) ...[
            async.maybeWhen(
              data: (all) {
                final list = _apply(all);
                final allSelected =
                    list.isNotEmpty && _selectedIds.length == list.length;
                return IconButton(
                  icon: Icon(
                    allSelected
                        ? Icons.deselect_rounded
                        : Icons.select_all_rounded,
                    color: isDark ? AppColors.goldBright : AppColors.goldDark,
                  ),
                  tooltip: allSelected ? 'إلغاء تحديد الكل' : 'تحديد الكل',
                  onPressed: () {
                    setState(() {
                      if (allSelected) {
                        _selectedIds.clear();
                      } else {
                        _selectedIds.addAll(list.map((c) => c.id));
                      }
                    });
                  },
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
            Container(
              margin: const EdgeInsets.only(left: 10, right: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _selectedIds.isNotEmpty
                      ? [Colors.redAccent, const Color(0xFFD32F2F)]
                      : [
                          Colors.redAccent.withValues(alpha: 0.4),
                          Colors.red.withValues(alpha: 0.4)
                        ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: _selectedIds.isNotEmpty
                    ? [
                        BoxShadow(
                          color: Colors.redAccent.withValues(alpha: 0.45),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [],
              ),
              child: IconButton(
                icon: const Icon(Icons.delete_forever_rounded,
                    color: Colors.white, size: 22),
                tooltip: 'حذف المحدّد (${_selectedIds.length})',
                onPressed: () async {
                  if (_selectedIds.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('يرجى تحديد عنصر واحد على الأقل للحذف'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }
                  final count = _selectedIds.length;
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('حذف العناصر المحددة؟',
                          style: TextStyle(
                              fontFamily: AppTheme.displayFamily,
                              fontWeight: FontWeight.bold)),
                      content: Text(
                          'هل أنت تأكيد من حذف الـ ($count) مساهمين المحددين نهائياً؟'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('إلغاء'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('حذف المحدّد',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && context.mounted) {
                    final repo = ref.read(contributorsRepositoryProvider);
                    final idsToDelete = List<String>.from(_selectedIds);
                    for (final id in idsToDelete) {
                      await repo.softDelete(id);
                    }
                    await Future.wait([
                      ref.refresh(donorsRawProvider.future),
                      ref.refresh(subscribersRawProvider.future),
                      ref.refresh(allContributorsRawProvider.future),
                      ref.refresh(statsRawProvider.future),
                    ]);
                    if (context.mounted) {
                      setState(() {
                        _selectedIds.clear();
                        _isSelectionMode = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('تم حذف $count مساهمين بنجاح!'),
                          backgroundColor: AppColors.greenDeep,
                        ),
                      );
                    }
                  }
                },
              ),
            ),
          ] else if (session.role.canManageContributors) ...[
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert_rounded,
                color: isDark ? AppColors.goldBright : AppColors.goldDark,
              ),
              tooltip: 'خيارات الإدارة',
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: AppColors.gold.withValues(alpha: 0.3),
                ),
              ),
              onSelected: (val) {
                if (val == 'delete_mode') {
                  setState(() => _isSelectionMode = true);
                }
              },
              itemBuilder: (ctx) => [
                PopupMenuItem<String>(
                  value: 'delete_mode',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        widget.showAll
                            ? 'حذف المساهمين'
                            : (widget.showSupporters
                                ? 'حذف الداعمين'
                                : (widget.showDonors == true
                                    ? 'حذف المتبرعين'
                                    : 'حذف المشتركين')),
                        style: const TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: async.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('تعذّر تحميل القائمة\n$e', textAlign: TextAlign.center),
          ),
        ),
        data: (all) {
          // إذا كان المشتركون سنويين فقط والشهري 0، التبديل التلقائي إلى سنوي لعدم إظهار قائمة فارغة
          if (_typeFilter == SubscriptionType.monthly &&
              widget.showDonors != true &&
              !widget.showSupporters &&
              !widget.showAll &&
              _search.text.isEmpty) {
            final hasMonthly = all.any((c) => c.subscriptionType == SubscriptionType.monthly);
            final hasYearly = all.any((c) => c.subscriptionType == SubscriptionType.yearly);
            if (!hasMonthly && hasYearly) {
              _typeFilter = SubscriptionType.yearly;
            }
          }

          final list = _apply(all);
          return Column(
            children: [
              _buildToolbar(context, all, list.length),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await Future.wait([
                      ref.refresh(allContributorsRawProvider.future),
                      ref.refresh(subscribersRawProvider.future),
                      ref.refresh(donorsRawProvider.future),
                      ref.refresh(statsRawProvider.future),
                    ]);
                  },
                  color: AppColors.gold,
                  backgroundColor: Theme.of(context).cardTheme.color,
                  child: list.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.4,
                              child: Center(
                                child: Text('لا نتائج مطابقة',
                                    style: Theme.of(context).textTheme.bodyMedium),
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                          itemCount: list.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final item = list[i];
                            final permissions = ref.watch(appPermissionsProvider);
                            final canSeeItemName = session.isAdmin ||
                                switch (item.type) {
                                  ContributorType.subscriber =>
                                    permissions.canShowSubscriberNames,
                                  ContributorType.donor =>
                                    permissions.canShowDonorNames,
                                  ContributorType.inKind =>
                                    permissions.canShowSupporterNames,
                                };

                            return ContributorTile(
                            contributor: item,
                            showStatus: widget.showDonors != true &&
                                !widget.showSupporters,
                            showTypeBadge: widget.showAll,
                            hideName: !canSeeItemName,
                            rank: _sort == _SortBy.amountDesc ? i + 1 : null,
                            isSelectionMode: _isSelectionMode,
                            isSelected: _selectedIds.contains(item.id),
                            onSelectChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedIds.add(item.id);
                                } else {
                                  _selectedIds.remove(item.id);
                                }
                              });
                            },
                          );
                        },
                      ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildToolbar(
      BuildContext context, List<ContributorModel> all, int shown) {
    final q = _search.text.trim();

    int monthlyCount = 0;
    int yearlyCount = 0;

    final showToggle = (widget.showDonors != true && !widget.showSupporters && !widget.showAll);
    final isSubscribersOnly = (widget.showDonors != true && !widget.showSupporters && !widget.showAll);

    if (showToggle) {
      if (q.isEmpty) {
        monthlyCount = all
            .where((c) => c.subscriptionType == SubscriptionType.monthly)
            .length;
        yearlyCount = all
            .where((c) => c.subscriptionType == SubscriptionType.yearly)
            .length;
      } else {
        monthlyCount = all
            .where((c) =>
                c.subscriptionType == SubscriptionType.monthly &&
                (c.fullName.contains(q) || (c.phone?.contains(q) ?? false)))
            .length;
        yearlyCount = all
            .where((c) =>
                c.subscriptionType == SubscriptionType.yearly &&
                (c.fullName.contains(q) || (c.phone?.contains(q) ?? false)))
            .length;
      }
    }

    // حصر المشتركين حسب التبويب المختار (شهري أو سنوي) والبحث لحساب دقيق للإحصائيات
    final currentSubscribers = isSubscribersOnly
        ? all.where((c) {
            if (!c.isSubscriber) return false;
            if (_typeFilter != null && c.subscriptionType != _typeFilter) return false;
            if (q.isNotEmpty && !(c.fullName.contains(q) || (c.phone?.contains(q) ?? false))) {
              return false;
            }
            return true;
          }).toList()
        : all;

    final allSubscribersScopeCount = currentSubscribers.length;
    final paidCount = currentSubscribers.where((c) => !c.isOverdue).length;
    final overdueCount = currentSubscribers.where((c) => c.isOverdue).length;

    final subscribersCount = all.where((c) => c.isSubscriber).length;
    final donorsCount = all.where((c) => c.type == ContributorType.donor).length;
    final supportersCount = all.where((c) => c.type == ContributorType.inKind).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        children: [
          TextField(
            controller: _search,
            onChanged: (text) => _onSearchChanged(text, all),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'بحث بالاسم أو رقم الهاتف',
              prefixIcon: const Icon(Icons.search_rounded, size: 21),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 19),
                      onPressed: () {
                        _search.clear();
                        _onSearchChanged('', all);
                      },
                    ),
            ),
          ),
          if (widget.showAll) ...[
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _CategoryFilterChip(
                    title: 'الكل',
                    count: all.length,
                    icon: Icons.groups_rounded,
                    color: AppColors.gold,
                    selected: _categoryFilter == _CategoryFilter.all,
                    onTap: () => setState(() => _categoryFilter = _CategoryFilter.all),
                  ),
                  const SizedBox(width: 8),
                  _CategoryFilterChip(
                    title: 'المشتركون',
                    count: subscribersCount,
                    icon: Icons.people_alt_rounded,
                    color: AppColors.greenDeep,
                    selected: _categoryFilter == _CategoryFilter.subscribers,
                    onTap: () => setState(() => _categoryFilter = _CategoryFilter.subscribers),
                  ),
                  const SizedBox(width: 8),
                  _CategoryFilterChip(
                    title: 'المتبرعون',
                    count: donorsCount,
                    icon: Icons.volunteer_activism_rounded,
                    color: AppColors.goldDark,
                    selected: _categoryFilter == _CategoryFilter.donors,
                    onTap: () => setState(() => _categoryFilter = _CategoryFilter.donors),
                  ),
                  const SizedBox(width: 8),
                  _CategoryFilterChip(
                    title: 'الداعمين والمساهمين',
                    count: supportersCount,
                    icon: Icons.shopping_basket_rounded,
                    color: Colors.lightBlue.shade700,
                    selected: _categoryFilter == _CategoryFilter.supporters,
                    onTap: () => setState(() => _categoryFilter = _CategoryFilter.supporters),
                  ),
                ],
              ),
            ),
          ],
          if (showToggle) ...[
            const SizedBox(height: 12),
            _SlidingSubscriptionToggle(
              selectedType: _typeFilter ?? SubscriptionType.monthly,
              monthlyCount: monthlyCount,
              yearlyCount: yearlyCount,
              onChanged: (type) {
                setState(() {
                  _typeFilter = type;
                });
              },
            ),
          ],
          if (isSubscribersOnly) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _StatusFilterCard(
                    title: 'الكل',
                    count: allSubscribersScopeCount,
                    icon: Icons.groups_rounded,
                    color: AppColors.gold,
                    selected: _statusFilter == _StatusFilter.all,
                    onTap: () => setState(() => _statusFilter = _StatusFilter.all),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatusFilterCard(
                    title: 'المسددون',
                    count: paidCount,
                    icon: Icons.check_circle_rounded,
                    color: AppColors.paid,
                    selected: _statusFilter == _StatusFilter.paid,
                    onTap: () => setState(() => _statusFilter = _StatusFilter.paid),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatusFilterCard(
                    title: 'المتأخرون',
                    count: overdueCount,
                    icon: Icons.warning_amber_rounded,
                    color: AppColors.overdue,
                    selected: _statusFilter == _StatusFilter.overdue,
                    onTap: () => setState(() => _statusFilter = _StatusFilter.overdue),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _onSearchChanged(String query, List<ContributorModel> all) {
    final q = query.trim();
    if (q.isNotEmpty && widget.showDonors != true && !widget.showSupporters && !widget.showAll) {
      final matchingMonthly = all
          .where((c) =>
              c.subscriptionType == SubscriptionType.monthly &&
              (c.fullName.contains(q) || (c.phone?.contains(q) ?? false)))
          .length;

      final matchingYearly = all
          .where((c) =>
              c.subscriptionType == SubscriptionType.yearly &&
              (c.fullName.contains(q) || (c.phone?.contains(q) ?? false)))
          .length;

      if (matchingMonthly > 0 && matchingYearly == 0) {
        _typeFilter = SubscriptionType.monthly;
      } else if (matchingYearly > 0 && matchingMonthly == 0) {
        _typeFilter = SubscriptionType.yearly;
      }
    }
    setState(() {});
  }

  List<ContributorModel> _apply(List<ContributorModel> src) {
    final q = _search.text.trim();
    var list = src.where((c) {
      if (widget.showSupporters) {
        // قسم الداعمين والمساهمين يحتوي على نوع الحساب (داعم) فقط
        if (c.type != ContributorType.inKind) return false;
      }
      if (widget.showAll) {
        if (_categoryFilter == _CategoryFilter.subscribers && !c.isSubscriber) return false;
        if (_categoryFilter == _CategoryFilter.donors && c.type != ContributorType.donor) return false;
        if (_categoryFilter == _CategoryFilter.supporters && c.type != ContributorType.inKind) return false;
      }
      if (_statusFilter == _StatusFilter.overdue && !c.isOverdue) return false;
      if (_statusFilter == _StatusFilter.paid && c.isOverdue) return false;

      // تصفية نوع الاشتراك تنطبق فقط على المشتركين وليس على المتبرعين أو عرض الكل
      if (_typeFilter != null && (widget.showDonors != true && !widget.showSupporters && !widget.showAll) && c.subscriptionType != _typeFilter) {
        return false;
      }
      if (q.isEmpty) return true;
      return c.fullName.contains(q) || (c.phone?.contains(q) ?? false);
    }).toList();

    switch (_sort) {
      case _SortBy.amountDesc:
        list.sort((a, b) {
          final cmp = b.totalPaid.compareTo(a.totalPaid);
          if (cmp != 0) return cmp;
          return (b.subscriptionAmount ?? 0).compareTo(a.subscriptionAmount ?? 0);
        });
      case _SortBy.amountAsc:
        list.sort((a, b) {
          final cmp = a.totalPaid.compareTo(b.totalPaid);
          if (cmp != 0) return cmp;
          return (a.subscriptionAmount ?? 0).compareTo(b.subscriptionAmount ?? 0);
        });
      case _SortBy.nameAsc:
        list.sort((a, b) => a.fullName.compareTo(b.fullName));
      case _SortBy.lateFirst:
        list.sort((a, b) {
          if (a.isOverdue == b.isOverdue) {
            return b.daysOverdue.compareTo(a.daysOverdue);
          }
          return a.isOverdue ? -1 : 1;
        });
    }
    return list;
  }
}

class _StatusFilterCard extends StatelessWidget {
  const _StatusFilterCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final int count;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GlassCard(
      onTap: onTap,
      radius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      borderColor: selected ? color.withValues(alpha: 0.7) : null,
      gradient: selected
          ? LinearGradient(
              colors: [
                color.withValues(alpha: isDark ? 0.22 : 0.14),
                color.withValues(alpha: isDark ? 0.08 : 0.05),
              ],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            )
          : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 15,
            color: selected ? color : (isDark ? Colors.white60 : Colors.black54),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '$title ($count)',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 11.5,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                  color: selected
                      ? color
                      : (isDark ? AppColors.textOnDarkMuted : AppColors.textOnLightMuted),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryFilterChip extends StatelessWidget {
  const _CategoryFilterChip({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final int count;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GlassCard(
      onTap: onTap,
      radius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      borderColor: selected ? color.withValues(alpha: 0.7) : null,
      gradient: selected
          ? LinearGradient(
              colors: [
                color.withValues(alpha: isDark ? 0.22 : 0.14),
                color.withValues(alpha: isDark ? 0.08 : 0.05),
              ],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            )
          : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: selected ? color : (isDark ? Colors.white60 : Colors.black54),
          ),
          const SizedBox(width: 5),
          Text(
            '$title ($count)',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 11.5,
              fontWeight: selected ? FontWeight.bold : FontWeight.w600,
              color: selected
                  ? color
                  : (isDark ? AppColors.textOnDarkMuted : AppColors.textOnLightMuted),
            ),
          ),
        ],
      ),
    );
  }
}

/// مفتاح التبديل المنزلق بين (شهري - سنوي) بتصميم عالي الجودة والأنيميشن السلس.
class _SlidingSubscriptionToggle extends StatelessWidget {
  const _SlidingSubscriptionToggle({
    required this.selectedType,
    required this.monthlyCount,
    required this.yearlyCount,
    required this.onChanged,
  });

  final SubscriptionType selectedType;
  final int monthlyCount;
  final int yearlyCount;
  final ValueChanged<SubscriptionType> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isMonthly = selectedType == SubscriptionType.monthly;

    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.35)
            : AppColors.lightGreenTint.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: isDark ? 0.3 : 0.45),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / 2;
          return Stack(
            children: [
              AnimatedAlign(
                alignment:
                    isMonthly ? Alignment.centerRight : Alignment.centerLeft,
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeInOutCubic,
                child: Container(
                  width: tabWidth,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [
                              const Color(0xFF1B633C),
                              const Color(0xFF13482C),
                            ]
                          : [
                              AppColors.green,
                              AppColors.greenDeep,
                            ],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.goldBright.withValues(alpha: 0.6),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.greenGlow
                            .withValues(alpha: isDark ? 0.4 : 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _ToggleTabItem(
                      label: 'شهري',
                      count: monthlyCount,
                      isSelected: isMonthly,
                      onTap: () => onChanged(SubscriptionType.monthly),
                    ),
                  ),
                  Expanded(
                    child: _ToggleTabItem(
                      label: 'سنوي',
                      count: yearlyCount,
                      isSelected: !isMonthly,
                      onTap: () => onChanged(SubscriptionType.yearly),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ToggleTabItem extends StatelessWidget {
  const _ToggleTabItem({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark
                        ? AppColors.textOnDarkMuted
                        : AppColors.textOnLightMuted),
              ),
              child: Text(label),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.goldBright.withValues(alpha: 0.22)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06)),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppColors.goldBright.withValues(alpha: 0.75)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.08)),
                  width: 1,
                ),
              ),
              child: Text(
                Fmt.count(count),
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? AppColors.goldBright
                      : (isDark
                          ? AppColors.textOnDarkMuted
                          : AppColors.textOnLightMuted),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
