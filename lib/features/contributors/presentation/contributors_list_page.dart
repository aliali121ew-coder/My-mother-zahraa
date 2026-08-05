import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
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

/// قائمة المتبرعين أو المشتركين كاملة، مع بحث وفلترة وترتيب كما طُلب.
class ContributorsListPage extends ConsumerStatefulWidget {
  const ContributorsListPage({
    super.key,
    this.showDonors,
    this.showAll = false,
  });

  final bool? showDonors;
  final bool showAll;

  @override
  ConsumerState<ContributorsListPage> createState() =>
      _ContributorsListPageState();
}

class _ContributorsListPageState extends ConsumerState<ContributorsListPage> {
  final _search = TextEditingController();
  _SortBy _sort = _SortBy.amountDesc;
  SubscriptionType? _typeFilter;
  bool _onlyOverdue = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final async = widget.showAll
        ? ref.watch(allContributorsProvider)
        : (widget.showDonors == true
            ? ref.watch(donorsProvider)
            : ref.watch(subscribersProvider));

    final title = widget.showAll
        ? 'قائمة كافة المساهمين'
        : (widget.showDonors == true ? 'قائمة المتبرعين' : 'قائمة المشتركين');

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(title),
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
          final list = _apply(all);
          return Column(
            children: [
              _buildToolbar(context, all.length, list.length),
              Expanded(
                child: list.isEmpty
                    ? Center(
                        child: Text('لا نتائج مطابقة',
                            style: Theme.of(context).textTheme.bodyMedium),
                      )
                    : ListView.separated(
                        // physics افتراضية + builder = تمرير سلس بلا بناء كل العناصر
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                        itemCount: list.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) => ContributorTile(
                          contributor: list[i],
                          showStatus: widget.showDonors != true,
                          hideName: !session.role.canSeeNames,
                          rank: _sort == _SortBy.amountDesc ? i + 1 : null,
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildToolbar(BuildContext context, int total, int shown) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        children: [
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
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
                        setState(() {});
                      },
                    ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _chip(
                  label: _sort.label,
                  icon: Icons.swap_vert_rounded,
                  selected: true,
                  onTap: _pickSort,
                ),
                if (widget.showDonors != true) ...[
                  const SizedBox(width: 8),
                  _chip(
                    label: _typeFilter?.label ?? 'كل الأنواع',
                    icon: Icons.filter_alt_outlined,
                    selected: _typeFilter != null,
                    onTap: _pickType,
                  ),
                  const SizedBox(width: 8),
                  _chip(
                    label: 'المتأخرون فقط',
                    icon: Icons.warning_amber_rounded,
                    selected: _onlyOverdue,
                    onTap: () => setState(() => _onlyOverdue = !_onlyOverdue),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                shown == total
                    ? 'الإجمالي ${Fmt.count(total)}'
                    : 'ظهر ${Fmt.count(shown)} من ${Fmt.count(total)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GlassCard(
      onTap: onTap,
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      borderColor: selected ? AppColors.gold.withValues(alpha: 0.5) : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: selected ? AppColors.gold : null),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.gold : null,
            ),
          ),
        ],
      ),
    );
  }

  List<ContributorModel> _apply(List<ContributorModel> src) {
    final q = _search.text.trim();
    var list = src.where((c) {
      if (_onlyOverdue && !c.isOverdue) return false;
      if (_typeFilter != null && c.subscriptionType != _typeFilter) return false;
      if (q.isEmpty) return true;
      return c.fullName.contains(q) || (c.phone?.contains(q) ?? false);
    }).toList();

    num amountOf(ContributorModel c) =>
        c.isSubscriber ? (c.subscriptionAmount ?? 0) : c.totalPaid;

    switch (_sort) {
      case _SortBy.amountDesc:
        list.sort((a, b) => amountOf(b).compareTo(amountOf(a)));
      case _SortBy.amountAsc:
        list.sort((a, b) => amountOf(a).compareTo(amountOf(b)));
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

  Future<void> _pickSort() async {
    final picked = await showModalBottomSheet<_SortBy>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final s in _SortBy.values)
              ListTile(
                title: Text(s.label),
                trailing: s == _sort
                    ? const Icon(Icons.check_rounded, color: AppColors.gold)
                    : null,
                onTap: () => Navigator.pop(context, s),
              ),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _sort = picked);
  }

  Future<void> _pickType() async {
    final picked = await showModalBottomSheet<Object>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('كل الأنواع'),
              onTap: () => Navigator.pop(context, 'all'),
            ),
            for (final t in SubscriptionType.values)
              ListTile(
                title: Text(t.label),
                trailing: t == _typeFilter
                    ? const Icon(Icons.check_rounded, color: AppColors.gold)
                    : null,
                onTap: () => Navigator.pop(context, t),
              ),
          ],
        ),
      ),
    );
    if (picked == null) return;
    setState(() {
      _typeFilter = picked is SubscriptionType ? picked : null;
    });
  }
}
