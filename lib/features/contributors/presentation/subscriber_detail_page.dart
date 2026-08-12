import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/glass.dart';
import '../../../shared/models/contributor_model.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/widgets/app_date_picker_dialog.dart';

/// أسماء الأشهر الترتيبية الـ 12 بالعربية
const _monthNames = [
  'الأول',
  'الثاني',
  'الثالث',
  'الرابع',
  'الخامس',
  'السادس',
  'السابع',
  'الثامن',
  'التاسع',
  'العاشر',
  'الحادي عشر',
  'الثاني عشر',
];

/// الشاشة التفصيلية المتطورة للمشترك (كارت البيانات الأساسية + جدول الـ 12 شهراً السنوي + النافذة الضبابية 50%).
class SubscriberDetailPage extends ConsumerStatefulWidget {
  const SubscriberDetailPage({
    super.key,
    required this.contributorId,
  });

  final String contributorId;

  @override
  ConsumerState<SubscriberDetailPage> createState() =>
      _SubscriberDetailPageState();
}

class _SubscriberDetailPageState extends ConsumerState<SubscriberDetailPage> {
  int _selectedYear = DateTime.now().year;
  Map<int, Map<String, dynamic>> _ledger = {};
  bool _isLoadingLedger = true;

  @override
  void initState() {
    super.initState();
    _loadLedger();
  }

  Future<void> _loadLedger() async {
    setState(() => _isLoadingLedger = true);
    final repo = ref.read(contributorsRepositoryProvider);
    final data = await repo.loadMonthlyLedger(widget.contributorId, _selectedYear);
    if (mounted) {
      setState(() {
        _ledger = data;
        _isLoadingLedger = false;
      });
    }
  }

  void _changeYear(int delta) {
    setState(() {
      _selectedYear += delta;
    });
    _loadLedger();
  }

  Future<void> _show3DSuccessDialog({
    required String title,
    required String subtitle,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: const EdgeInsets.symmetric(horizontal: 28),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          AppColors.greenDeep.withValues(alpha: 0.95),
                          AppColors.greenAbyss.withValues(alpha: 0.98),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.96),
                          const Color(0xFFF7F0DF).withValues(alpha: 0.96),
                        ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.45),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.green.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🌟 علامة صح 3D البارزة والجميلة 🌟
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.green,
                          AppColors.greenDeep,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: AppColors.goldBright,
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.green.withValues(alpha: 0.5),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                        BoxShadow(
                          color: AppColors.gold.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 44,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // عنوان النجاح
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTheme.displayFamily,
                      fontSize: 18.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.goldBright : AppColors.goldDark,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // التفاصيل الفرعية
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 22),

                  // زر الإغلاق الموافق
                  SizedBox(
                    width: 140,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'موافق',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final subscribersAsync = ref.watch(allContributorsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final allList = subscribersAsync.valueOrNull ?? [];
    final currentContrib = allList.firstWhere(
      (c) => c.id == widget.contributorId,
      orElse: () => ContributorModel(
        id: widget.contributorId,
        type: ContributorType.subscriber,
        fullName: 'الداعم',
      ),
    );
    final isSubscriber = currentContrib.type == ContributorType.subscriber;
    final isDonor = currentContrib.type == ContributorType.donor;
    final pageTitle = isSubscriber
        ? 'ملف المشترك التفصيلي'
        : (isDonor ? 'ملف المتبرع التفصيلي' : 'ملف الداعم التفصيلي');

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          centerTitle: true,
          title: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              pageTitle,
              style: TextStyle(
                fontFamily: AppTheme.displayFamily,
                fontSize: 22.5,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.goldBright : AppColors.goldDark,
              ),
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'حذف المساهم',
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.redAccent,
              ),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('حذف المساهم؟',
                        style: TextStyle(
                            fontFamily: AppTheme.displayFamily,
                            fontWeight: FontWeight.bold)),
                    content: Text(
                        'هل أنت تأكيد من حذف السجل "${currentContrib.fullName}" نهائياً؟'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('إلغاء'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('حذف السجل',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  final nav = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  final repo = ref.read(contributorsRepositoryProvider);
                  await repo.softDelete(currentContrib.id);
                  await Future.wait([
                    ref.refresh(donorsRawProvider.future),
                    ref.refresh(subscribersRawProvider.future),
                    ref.refresh(allContributorsRawProvider.future),
                    ref.refresh(statsRawProvider.future),
                  ]);
                  if (mounted) {
                    nav.pop();
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('تم حذف المساهم بنجاح!'),
                        backgroundColor: AppColors.greenDeep,
                      ),
                    );
                  }
                }
              },
            ),
            IconButton(
              tooltip: 'الملف الشخصي',
              icon: Icon(
                Icons.person_rounded,
                color: isDark ? AppColors.goldBright : AppColors.goldDark,
              ),
              onPressed: () {
                context.push('/subscriber_profile/${widget.contributorId}');
              },
            ),
            const SizedBox(width: 6),
          ],
        ),
        body: subscribersAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.gold),
          ),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('تعذّر تحميل البيانات\n$err',
                  textAlign: TextAlign.center),
            ),
          ),
          data: (all) {
            final subscriber = all.firstWhere(
              (c) => c.id == widget.contributorId,
              orElse: () => ContributorModel(
                id: widget.contributorId,
                type: ContributorType.subscriber,
                fullName: 'المساهم',
                subscriptionAmount: 50000,
                subscriptionType: SubscriptionType.monthly,
                createdAt: DateTime.now(),
              ),
            );

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
              children: [
                // 1️⃣ القسم الأول: كارت البيانات الأساسية بحرفية عالية
                _buildHeaderSection(context, subscriber, isDark),
                const SizedBox(height: 18),

                // 2️⃣ القسم الثاني: جدول الـ 12 شهراً للسنة المالية
                _build12MonthTableSection(context, subscriber, isDark),
              ],
            );
          },
        ),
      ),
    );
  }

  /// 1️⃣ كارت الترويسة والبيانات الأساسية
  Widget _buildHeaderSection(
      BuildContext context, ContributorModel c, bool isDark) {

    return GoldBorder(
      radius: AppTheme.radiusLarge,
      child: GlassCard(
        blur: true,
        radius: AppTheme.radiusLarge,
        padding: const EdgeInsets.all(18),
        gradient: isDark
            ? LinearGradient(
                colors: [
                  AppColors.greenDeep.withValues(alpha: 0.9),
                  AppColors.greenAbyss.withValues(alpha: 0.95),
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              )
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.gold.withValues(alpha: 0.22),
                  backgroundImage: c.photoUrl != null && c.photoUrl!.isNotEmpty
                      ? (c.photoUrl!.startsWith('http')
                          ? NetworkImage(c.photoUrl!)
                          : FileImage(File(c.photoUrl!)) as ImageProvider)
                      : null,
                  child: (c.photoUrl == null || c.photoUrl!.isEmpty)
                      ? Text(
                          c.fullName.isNotEmpty ? c.fullName[0] : 'م',
                          style: const TextStyle(
                            fontFamily: AppTheme.displayFamily,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.goldBright,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // الاسم الثلاثي
                      Text(
                        c.fullName,
                        style: TextStyle(
                          fontFamily: AppTheme.displayFamily,
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.goldBright
                              : AppColors.goldDark,
                        ),
                      ),
                      const SizedBox(height: 5),
                      // رقم الهاتف
                      if (c.phone != null && c.phone!.isNotEmpty)
                        Row(
                          children: [
                            Icon(Icons.phone_rounded,
                                size: 13,
                                color: isDark
                                    ? AppColors.textOnDarkMuted
                                    : AppColors.textOnLightMuted),
                            const SizedBox(width: 4),
                            Text(
                              c.phone!,
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.textOnDarkMuted
                                    : AppColors.textOnLightMuted,
                              ),
                            ),
                          ],
                        ),
                      // العنوان
                      if (c.address != null && c.address!.isNotEmpty) ...
                        [
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(Icons.location_on_rounded,
                                  size: 13,
                                  color: isDark
                                      ? AppColors.textOnDarkMuted
                                      : AppColors.textOnLightMuted),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  c.address!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontSize: 12,
                                    color: isDark
                                        ? AppColors.textOnDarkMuted
                                        : AppColors.textOnLightMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            // شبكة تفاصيل الكارت الثلاثية المنظمة برقي من غير أي تداخل
            Builder(builder: (context) {
              final isDonor = c.type != ContributorType.subscriber;
              final isInKind = c.type == ContributorType.inKind;

              int totalInKindContributionsCount = 0;
              num calcTotalPaid = 0;
              for (final e in _ledger.values) {
                if (e['is_paid'] == true) {
                  calcTotalPaid += (e['amount'] as num? ?? 0);
                  final donations = e['donations'];
                  if (donations is List && donations.isNotEmpty) {
                    totalInKindContributionsCount += donations.length;
                  } else {
                    totalInKindContributionsCount += 1;
                  }
                }
              }
              final displayTotalPaid =
                  calcTotalPaid > 0 ? calcTotalPaid : c.totalPaid;

              return Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildDetailMetric(
                        label: isDonor ? 'تاريخ الانضمام' : 'تاريخ الاشتراك',
                        value: Fmt.date(c.createdAt ?? c.lastPaymentAt),
                        icon: Icons.calendar_today_rounded,
                        isDark: isDark,
                      ),
                    ),
                    _vMetricDivider(isDark),
                    Expanded(
                      child: _buildDetailMetric(
                        label: isDonor ? 'نوع المساهمة' : 'فئة الاشتراك',
                        value: isDonor
                            ? c.type.label
                            : Fmt.money(c.subscriptionAmount ?? 0),
                        icon: isDonor
                            ? Icons.volunteer_activism_rounded
                            : Icons.payments_rounded,
                        isDark: isDark,
                      ),
                    ),
                    _vMetricDivider(isDark),
                    Expanded(
                      child: _buildDetailMetric(
                        label: isInKind ? 'إجمالي المساهمات' : 'إجمالي الدفعات',
                        value: isInKind
                            ? '$totalInKindContributionsCount مساهمة'
                            : Fmt.money(displayTotalPaid),
                        icon: isInKind
                            ? Icons.inventory_2_rounded
                            : Icons.monetization_on_rounded,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _vMetricDivider(bool isDark) => Container(
        width: 1,
        height: 28,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        color: isDark
            ? Colors.white.withValues(alpha: 0.14)
            : Colors.black.withValues(alpha: 0.12),
      );

  Widget _buildDetailMetric({
    required String label,
    required String value,
    required IconData icon,
    required bool isDark,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: AppColors.gold),
            const SizedBox(width: 3),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textOnDarkMuted
                        : AppColors.textOnLightMuted,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 13.0,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.goldBright : AppColors.goldDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _vDivider(bool isDark) => Container(
        width: 1,
        height: 22,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        color: isDark
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.black.withValues(alpha: 0.12),
      );

  String _formatDateHyphen(DateTime? d) {
    if (d == null) return '—';
    final local = d.toLocal();
    final m = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '$m-$day';
  }

  /// 2️⃣ جدول الـ 12 شهراً للسنة المالية
  Widget _build12MonthTableSection(
      BuildContext context, ContributorModel c, bool isDark) {
    final isSubscriberType = c.type == ContributorType.subscriber;
    final isDonorType = c.type == ContributorType.donor;

    num yearTotal = 0;
    for (final e in _ledger.values) {
      if (e['is_paid'] == true) {
        yearTotal += (e['amount'] as num? ?? 0);
      }
    }

    // حساب عدد الأشهر المسددة لعرض ملخص الاشتراك
    final paidMonths = _ledger.values.where((e) => e['is_paid'] == true).length;

    return GlassCard(
      blur: true,
      radius: AppTheme.radiusLarge,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // شريط عنوان الجدول + أزرار التنقل بين السنوات < 2026 >
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    isSubscriberType
                        ? 'جدول التسديدات الشهري (12 شهراً)'
                        : (isDonorType
                            ? 'جدول تبرعات الشهور (12 شهراً)'
                            : 'جدول مساهمات الشهور (12 شهراً)'),
                    style: const TextStyle(
                      fontFamily: AppTheme.displayFamily,
                      fontSize: 16.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // أزرار السنة
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
                      onPressed: () => _changeYear(-1),
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '$_selectedYear',
                        style: const TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.gold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                      onPressed: () => _changeYear(1),
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ملخص سريع للمشتركين والمتبرعين: عدد الأشهر المسددة
          if (isSubscriberType || isDonorType) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.greenDeep.withValues(alpha: 0.25)
                    : AppColors.greenDeep.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.green.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryChip(
                    label: isSubscriberType ? 'المسددة' : 'أشهر التبرع',
                    value: '$paidMonths',
                    color: AppColors.green,
                    icon: Icons.check_circle_rounded,
                  ),
                  _buildSummaryChip(
                    label: 'المتبقية',
                    value: '${12 - paidMonths}',
                    color: AppColors.overdue,
                    icon: Icons.timelapse_rounded,
                  ),
                  _buildSummaryChip(
                    label: 'المجموع المسدد',
                    value: Fmt.money(yearTotal),
                    color: AppColors.gold,
                    icon: Icons.payments_rounded,
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // الجدول التفاعلي للأشهر الـ 12
          if (_isLoadingLedger)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: AppColors.gold),
              ),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  children: [
                    // الترويسة تختلف حسب نوع المساهم
                    if (isSubscriberType)
                      _buildSubscriberTableHeader(isDark)
                    else if (isDonorType)
                      _buildDonorTableHeader(isDark)
                    else
                      _buildSupporterTableHeader(isDark),

                    // صفوف الأشهر الـ 12
                    for (int m = 1; m <= 12; m++) ...[
                      if (isSubscriberType)
                        _buildSubscriberMonthRow(c, m, isDark)
                      else if (isDonorType)
                        _buildDonorMonthRow(c, m, isDark)
                      else
                        _buildSupporterMonthRow(c, m, isDark),
                      if (m < 12) const Divider(height: 1, thickness: 0.5),
                    ],

                    // تذييل المجموع السنوي الفخم والاحترافي المرتّب سطر تحت سطر
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [
                                  AppColors.greenDeep.withValues(alpha: 0.95),
                                  AppColors.greenAbyss.withValues(alpha: 0.98),
                                ]
                              : [
                                  AppColors.lightGreenTint,
                                  AppColors.gold.withValues(alpha: 0.12),
                                ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        border: Border(
                          top: BorderSide(
                            color: AppColors.gold.withValues(alpha: 0.35),
                            width: 1.2,
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // السطر الأول: العنوان مع أيقونة فخمة
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.gold.withValues(alpha: 0.18),
                                  border: Border.all(
                                    color: AppColors.gold.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Icon(
                                  isSubscriberType
                                      ? Icons.account_balance_wallet_rounded
                                      : (isDonorType
                                          ? Icons.payments_rounded
                                          : Icons.inventory_2_rounded),
                                  size: 16,
                                  color: isDark ? AppColors.goldBright : AppColors.goldDark,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  isSubscriberType
                                      ? 'إجمالي اشتراكات عام $_selectedYear'
                                      : (isDonorType
                                          ? 'إجمالي تبرعات عام $_selectedYear'
                                          : 'إجمالي المساهمات لعام $_selectedYear'),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: AppTheme.displayFamily,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // السطر الثاني: شارة القيمة البارزة في المنتصف كسطر مستقل
                          Builder(builder: (context) {
                            int yearInKindCount = 0;
                            for (final e in _ledger.values) {
                              if (e['is_paid'] == true) {
                                final dons = e['donations'];
                                if (dons is List && dons.isNotEmpty) {
                                  yearInKindCount += dons.length;
                                } else {
                                  yearInKindCount += 1;
                                }
                              }
                            }
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.black.withValues(alpha: 0.35)
                                    : Colors.white.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.gold.withValues(alpha: 0.45),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.gold.withValues(alpha: 0.12),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Text(
                                (!isSubscriberType && !isDonorType)
                                    ? '$yearInKindCount مساهمة'
                                    : Fmt.money(yearTotal),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: AppTheme.displayFamily,
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? AppColors.goldBright : AppColors.goldDark,
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );

  }

  /// ويدجت ملخص صغير (عدد الأشهر / المبلغ)
  Widget _buildSummaryChip({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 10,
            color: color.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }

  /// ترويسة جدول التسديدات الخاص بالمشتركين
  Widget _buildSubscriberTableHeader(bool isDark) {
    return Container(
      height: 42,
      color: isDark ? AppColors.greenDeep : AppColors.lightGreenTint,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          const Expanded(
            flex: 22,
            child: Text('الشهر',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.bold,
                    fontSize: 11.0)),
          ),
          _vDivider(isDark),
          const Expanded(
            flex: 28,
            child: Text('مبلغ الاشتراك',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.bold,
                    fontSize: 10.5)),
          ),
          _vDivider(isDark),
          const Expanded(
            flex: 20,
            child: Text('الحالة',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.bold,
                    fontSize: 10.5)),
          ),
          _vDivider(isDark),
          const Expanded(
            flex: 22,
            child: Text('تاريخ التسديد',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.bold,
                    fontSize: 9.5)),
          ),
          _vDivider(isDark),
          const SizedBox(
            width: 32,
            child: Text('تعديل',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.bold,
                    fontSize: 10.0)),
          ),
        ],
      ),
    );
  }

  /// صف شهر مخصص للمشتركين (مبلغ الاشتراك + الحالة + تاريخ التسديد)
  Widget _buildSubscriberMonthRow(ContributorModel c, int monthIndex, bool isDark) {
    final entry = _ledger[monthIndex];
    final isPaid = entry != null && entry['is_paid'] == true;
    final paidAmount = isPaid ? (entry['amount'] as num? ?? 0) : 0;
    final paidAtStr = isPaid ? (entry['paid_at'] as String?) : null;
    final paidAt = paidAtStr != null ? DateTime.tryParse(paidAtStr) : null;
    final subscriptionAmount = c.subscriptionAmount ?? 0;

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      color: monthIndex.isEven
          ? (isDark
              ? Colors.white.withValues(alpha: 0.02)
              : Colors.black.withValues(alpha: 0.02))
          : Colors.transparent,
      child: Row(
        children: [
          // اسم الشهر
          Expanded(
            flex: 22,
            child: Text(
              monthIndex >= 11
                  ? _monthNames[monthIndex - 1].replaceAll(' ', '\n')
                  : _monthNames[monthIndex - 1],
              textAlign: TextAlign.center,
              maxLines: monthIndex >= 11 ? 2 : 1,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: monthIndex >= 11 ? 9.5 : 11.0,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _vDivider(isDark),

          // مبلغ الاشتراك المطلوب أو المسدد
          Expanded(
            flex: 28,
            child: Text(
              isPaid
                  ? Fmt.money(paidAmount)
                  : Fmt.money(subscriptionAmount),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 10.5,
                fontWeight: isPaid ? FontWeight.bold : FontWeight.w500,
                color: isPaid
                    ? AppColors.green
                    : (isDark ? Colors.white54 : Colors.black45),
              ),
            ),
          ),
          _vDivider(isDark),

          // حالة التسديد
          Expanded(
            flex: 20,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
              decoration: BoxDecoration(
                color: isPaid
                    ? AppColors.green.withValues(alpha: 0.15)
                    : AppColors.overdue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    isPaid ? '✅ مسدد' : '⏳ متأخر',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 10.0,
                      fontWeight: FontWeight.bold,
                      color: isPaid ? AppColors.green : AppColors.overdue,
                    ),
                  ),
                ),
              ),
            ),
          ),
          _vDivider(isDark),

          // تاريخ التسديد
          Expanded(
            flex: 22,
            child: Text(
              paidAt != null ? _formatDateHyphen(paidAt) : '—',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 10.0,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
          _vDivider(isDark),

          // زر التعديل
          SizedBox(
            width: 32,
            child: IconButton(
              icon: Icon(
                isPaid ? Icons.edit_note_rounded : Icons.add_circle_outline_rounded,
                size: 19,
                color: AppColors.gold,
              ),
              onPressed: () => _openSubscriberPaymentDialog(c, monthIndex, entry),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: isPaid ? 'تعديل تسديد هذا الشهر' : 'تسجيل تسديد لهذا الشهر',
            ),
          ),
        ],
      ),
    );
  }

  /// نافذة تسديد الاشتراك الشهري للمشترك أو تسجيل تبرع للمتبرع
  Future<void> _openSubscriberPaymentDialog(
    ContributorModel c,
    int monthIndex,
    Map<String, dynamic>? existingEntry,
  ) async {
    final monthName = _monthNames[monthIndex - 1];
    final isDonor = c.type == ContributorType.donor;
    final isPaid = existingEntry != null && existingEntry['is_paid'] == true;
    final currentAmount = isPaid
        ? (existingEntry['amount'] as num? ?? c.subscriptionAmount ?? 0)
        : (c.subscriptionAmount ?? 0);
    final currentPaidAt = isPaid && existingEntry['paid_at'] != null
        ? (DateTime.tryParse(existingEntry['paid_at'].toString()) ?? DateTime.now())
        : DateTime.now();

    final amountController = TextEditingController(
        text: currentAmount > 0 ? Fmt.amount(currentAmount) : '');
    DateTime paymentDate = currentPaidAt;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.50),
      builder: (ctx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Dialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22)),
                clipBehavior: Clip.antiAlias,
                insetPadding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 40),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // عنوان النافذة
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.greenDeep.withValues(alpha: 0.9),
                              AppColors.greenAbyss,
                            ],
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              isDonor
                                  ? '${isPaid ? "تعديل تبرع" : "تسجيل تبرع"} شهر $monthName'
                                  : '${isPaid ? "تعديل تسديد" : "تسجيل تسديد"} شهر $monthName',
                              style: const TextStyle(
                                fontFamily: AppTheme.displayFamily,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'السنة: $_selectedYear',
                              style: const TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // محتوى النافذة
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // حقل المبلغ
                            Text(
                              isDonor ? 'مبلغ التبرع (د.ع)' : 'مبلغ الاشتراك المسدد (د.ع)',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: amountController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: false),
                              textAlign: TextAlign.center,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                ThousandsFormatter(),
                              ],
                              style: const TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: InputDecoration(
                                hintText: Fmt.money(c.subscriptionAmount ?? 0),
                                prefixIcon: const Icon(Icons.payments_rounded, color: AppColors.gold),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // تاريخ الدفع
                            Text(
                              isDonor ? 'تاريخ التبرع' : 'تاريخ التسديد',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () async {
                                final picked = await AppDatePickerDialog.show(
                                  context: context,
                                  initialDate: paymentDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                  primaryColor: AppColors.green,
                                );
                                if (picked != null) {
                                  setModalState(() => paymentDate = picked);
                                }
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: isDark ? Colors.white30 : Colors.black26,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today_rounded,
                                        size: 18, color: AppColors.gold),
                                    const SizedBox(width: 10),
                                    Text(
                                      '${paymentDate.year}/${paymentDate.month.toString().padLeft(2, '0')}/${paymentDate.day.toString().padLeft(2, '0')}',
                                      style: const TextStyle(
                                        fontFamily: AppTheme.fontFamily,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const Spacer(),
                                    const Icon(Icons.edit_calendar_rounded,
                                        size: 16, color: AppColors.gold),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // زر الحفظ
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.save_rounded,
                                    size: 18, color: Colors.white),
                                label: Text(
                                  isPaid ? 'حفظ التعديل' : 'تسجيل التسديد ✅',
                                  style: const TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.green,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () async {
                                  final raw = amountController.text
                                      .replaceAll(',', '')
                                      .replaceAll('٬', '')
                                      .trim();
                                  final amount = num.tryParse(raw) ??
                                      (c.subscriptionAmount ?? 0);

                                  if (amount <= 0) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('يرجى إدخال مبلغ صحيح'),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                    return;
                                  }

                                  final nav = Navigator.of(ctx);
                                  final repo =
                                      ref.read(contributorsRepositoryProvider);

                                  await repo.saveMonthPayment(
                                    contributorId: c.id,
                                    year: _selectedYear,
                                    month: monthIndex,
                                    amount: amount,
                                    paidAt: paymentDate,
                                    isPaid: true,
                                  );

                                  await _loadLedger();
                                  await Future.wait([
                                    ref.refresh(statsRawProvider.future),
                                    ref.refresh(subscribersRawProvider.future),
                                    ref.refresh(allContributorsRawProvider.future),
                                  ]);

                                  if (mounted) {
                                    nav.pop();
                                    await _show3DSuccessDialog(
                                      title: isDonor
                                          ? 'تم حفظ التبرع بنجاح ✅'
                                          : 'تم حفظ التعديل بنجاح ✅',
                                      subtitle: isDonor
                                          ? 'تم تسجيل تبرع شهر $monthName بمبلغ ${Fmt.money(amount)}'
                                          : 'تم تسجيل تسديد شهر $monthName بمبلغ ${Fmt.money(amount)}',
                                    );
                                  }
                                },
                              ),
                            ),

                            // زر إلغاء التسديد (يظهر فقط إذا كان الشهر مسدداً)
                            if (isPaid) ...[
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.cancel_outlined,
                                      size: 16, color: Colors.redAccent),
                                  label: Text(
                                    isDonor ? 'إلغاء التبرع' : 'إلغاء التسديد',
                                    style: const TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                        color: Colors.redAccent),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () async {
                                    final nav = Navigator.of(ctx);
                                    final repo =
                                        ref.read(contributorsRepositoryProvider);

                                    await repo.saveMonthPayment(
                                      contributorId: c.id,
                                      year: _selectedYear,
                                      month: monthIndex,
                                      amount: 0,
                                      paidAt: DateTime.now(),
                                      isPaid: false,
                                    );

                                    await _loadLedger();
                                    await Future.wait([
                                      ref.refresh(statsRawProvider.future),
                                      ref.refresh(subscribersRawProvider.future),
                                      ref.refresh(allContributorsRawProvider.future),
                                    ]);

                                    if (mounted) {
                                      nav.pop();
                                      await _show3DSuccessDialog(
                                        title: isDonor
                                            ? 'تم إلغاء التبرع ✅'
                                            : 'تم إلغاء التسديد ✅',
                                        subtitle: isDonor
                                            ? 'تم إلغاء تبرع شهر $monthName بنجاح'
                                            : 'تم إلغاء تسديد شهر $monthName بنجاح',
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }


  /// ترويسة جدول التبرعات المخصصة للمتبرع (مطابق للمشترك بدون عمود الحالة)
  Widget _buildDonorTableHeader(bool isDark) {
    return Container(
      height: 42,
      color: isDark ? AppColors.greenDeep : AppColors.lightGreenTint,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          const Expanded(
            flex: 28,
            child: Text('الشهر',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.bold,
                    fontSize: 11.0)),
          ),
          _vDivider(isDark),
          const Expanded(
            flex: 38,
            child: Text('مبلغ التبرع',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.bold,
                    fontSize: 10.5)),
          ),
          _vDivider(isDark),
          const Expanded(
            flex: 34,
            child: Text('تاريخ التبرع',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.bold,
                    fontSize: 10.0)),
          ),
          _vDivider(isDark),
          const SizedBox(
            width: 32,
            child: Text('تعديل',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.bold,
                    fontSize: 10.0)),
          ),
        ],
      ),
    );
  }

  /// صف شهر مخصص للمتبرع (مبلغ مالي بدون عمود الحالة)
  Widget _buildDonorMonthRow(ContributorModel c, int monthIndex, bool isDark) {
    final entry = _ledger[monthIndex];
    final isPaid = entry != null && entry['is_paid'] == true;
    final paidAmount = isPaid ? (entry['amount'] as num? ?? 0) : 0;
    final paidAtStr = isPaid ? (entry['paid_at'] as String?) : null;
    final paidAt = paidAtStr != null ? DateTime.tryParse(paidAtStr) : null;

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      color: monthIndex.isEven
          ? (isDark
              ? Colors.white.withValues(alpha: 0.02)
              : Colors.black.withValues(alpha: 0.02))
          : Colors.transparent,
      child: Row(
        children: [
          // اسم الشهر
          Expanded(
            flex: 28,
            child: Text(
              monthIndex >= 11
                  ? _monthNames[monthIndex - 1].replaceAll(' ', '\n')
                  : _monthNames[monthIndex - 1],
              textAlign: TextAlign.center,
              maxLines: monthIndex >= 11 ? 2 : 1,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: monthIndex >= 11 ? 9.5 : 11.0,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _vDivider(isDark),

          // مبلغ التبرع المسدد + أيقونة ℹ️ للتفاصيل
          Expanded(
            flex: 38,
            child: isPaid
                ? InkWell(
                    onTap: () => _showMonthDonationsDetailsDialog(c, monthIndex, entry),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                Fmt.money(paidAmount),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.green,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 13,
                            color: AppColors.gold,
                          ),
                        ],
                      ),
                    ),
                  )
                : Text(
                    '—',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
          ),
          _vDivider(isDark),

          // تاريخ التبرع بصيغة (سنة - شهر)
          Expanded(
            flex: 34,
            child: Text(
              paidAt != null
                  ? '${paidAt.year}-${paidAt.month.toString().padLeft(2, '0')}'
                  : '—',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 10.0,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
          _vDivider(isDark),

          // زر التعديل / تسجيل التبرع (يفتح نافذة الإضافة والتعديل متعددة الدفعات)
          SizedBox(
            width: 32,
            child: IconButton(
              icon: Icon(
                isPaid ? Icons.edit_note_rounded : Icons.add_circle_outline_rounded,
                size: 19,
                color: AppColors.gold,
              ),
              onPressed: () => _openDonorMonthDialog(c, monthIndex, entry),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: isPaid ? 'تعديل / إضافة تبرع لهذا الشهر' : 'تسجيل تبرع لهذا الشهر',
            ),
          ),
        ],
      ),
    );
  }

  /// ترويسة جدول التبرعات العينية الخاصة بالداعمين
  Widget _buildSupporterTableHeader(bool isDark) {
    return Container(
      height: 42,
      color: isDark ? AppColors.greenDeep : AppColors.lightGreenTint,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          const Expanded(
              flex: 22,
              child: Text('الاشهر',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.bold,
                      fontSize: 11.0))),
          _vDivider(isDark),
          const Expanded(
              flex: 30,
              child: Text('مواد غذائية',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.bold,
                      fontSize: 10.5))),
          _vDivider(isDark),
          const Expanded(
              flex: 30,
              child: Text('مواد أنشائية',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.bold,
                      fontSize: 10.5))),
          _vDivider(isDark),
          const Expanded(
              flex: 18,
              child: Text('تاريخ التبرع',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.bold,
                      fontSize: 9.5))),
          _vDivider(isDark),
          const SizedBox(
              width: 32,
              child: Text('تعديل',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.bold,
                      fontSize: 10.0))),
        ],
      ),
    );
  }

  /// صف شهر مخصص للداعمين (المواد العينية)
  Widget _buildSupporterMonthRow(ContributorModel c, int monthIndex, bool isDark) {
    final entry = _ledger[monthIndex];
    final hasEntry = entry != null;
    final foodDesc = hasEntry ? (entry['food_desc'] as String?) : null;
    final constrDesc = hasEntry ? (entry['construction_desc'] as String?) : null;
    final paidAtStr = hasEntry ? (entry['paid_at'] as String?) : null;
    final paidAt = paidAtStr != null ? DateTime.tryParse(paidAtStr) : null;

    final donations = hasEntry && entry['donations'] is List
        ? List<Map<String, dynamic>>.from(entry['donations'] as List)
        : <Map<String, dynamic>>[];

    final foodItems = donations.where((d) => d['kind'] == 'food').toList();
    final constrItems =
        donations.where((d) => d['kind'] == 'construction').toList();

    final hasFood = foodDesc != null && foodDesc.trim().isNotEmpty;
    final hasConstr = constrDesc != null && constrDesc.trim().isNotEmpty;

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      color: monthIndex.isEven
          ? (isDark
              ? Colors.white.withValues(alpha: 0.02)
              : Colors.black.withValues(alpha: 0.02))
          : Colors.transparent,
      child: Row(
        children: [
          Expanded(
            flex: 22,
            child: Text(
              monthIndex >= 11
                  ? _monthNames[monthIndex - 1].replaceAll(' ', '\n')
                  : _monthNames[monthIndex - 1],
              textAlign: TextAlign.center,
              maxLines: monthIndex >= 11 ? 2 : 1,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: monthIndex >= 11 ? 9.5 : 11.0,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _vDivider(isDark),

          // 📦 مواد غذائية
          Expanded(
            flex: 30,
            child: InkWell(
              onTap: hasFood ? () => _showDonorItemsQuickView(c, monthIndex, entry) : null,
              borderRadius: BorderRadius.circular(6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      hasFood
                          ? (foodItems.isNotEmpty
                              ? foodItems.first['text_value'].toString()
                              : foodDesc)
                          : '—',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 10.5,
                        fontWeight: hasFood ? FontWeight.bold : FontWeight.normal,
                        color: hasFood ? AppColors.green : null,
                      ),
                    ),
                  ),
                  if (foodItems.length > 1) ...[
                    const SizedBox(width: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '+${foodItems.length - 1}',
                        style: const TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.green,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          _vDivider(isDark),

          // 🏗️ مواد أنشائية
          Expanded(
            flex: 30,
            child: InkWell(
              onTap: hasConstr ? () => _showDonorItemsQuickView(c, monthIndex, entry) : null,
              borderRadius: BorderRadius.circular(6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      hasConstr
                          ? (constrItems.isNotEmpty
                              ? constrItems.first['text_value'].toString()
                              : constrDesc)
                          : '—',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 10.5,
                        fontWeight: hasConstr ? FontWeight.bold : FontWeight.normal,
                        color: hasConstr ? AppColors.greenDeep : null,
                      ),
                    ),
                  ),
                  if (constrItems.length > 1) ...[
                    const SizedBox(width: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.greenDeep.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '+${constrItems.length - 1}',
                        style: const TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.greenDeep,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          _vDivider(isDark),
          Expanded(
            flex: 18,
            child: Text(
              paidAt != null ? _formatDateHyphen(paidAt) : '—',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 10.0,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
          _vDivider(isDark),
          SizedBox(
            width: 30,
            child: IconButton(
              icon: const Icon(Icons.edit_note_rounded,
                  size: 19, color: AppColors.gold),
              onPressed: () => _openDonorMonthDialog(c, monthIndex, entry),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'تعديل تبرعات هذا الشهر',
            ),
          ),
        ],
      ),
    );
  }



  /// 3️⃣ النافذة الضبابية 50% لتعديل وتسديد الشهر





  /// نافذة تفاصيل سجل الدفعات لشهر معين (تظهر عند الضغط على أيقونة ℹ️)
  Future<void> _showMonthDonationsDetailsDialog(
    ContributorModel c,
    int monthIndex,
    Map<String, dynamic>? entry,
  ) async {
    if (entry == null) return;
    final monthName = _monthNames[monthIndex - 1];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rawDonations = entry['donations'] is List
        ? List<Map<String, dynamic>>.from(entry['donations'] as List)
        : <Map<String, dynamic>>[];

    final paidAtStr = entry['paid_at']?.toString();
    final fallbackDate =
        paidAtStr != null ? DateTime.tryParse(paidAtStr) : DateTime.now();
    final totalAmt = (entry['amount'] as num?) ?? 0;

    final donations = rawDonations.isNotEmpty
        ? rawDonations
        : [
            if (totalAmt > 0)
              {
                'id': 'legacy_1',
                'kind': 'cash',
                'amount': totalAmt,
                'text_value': '',
                'date': fallbackDate?.toUtc().toIso8601String(),
              }
          ];

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            clipBehavior: Clip.antiAlias,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            child: Container(
              width: 380,
              decoration: BoxDecoration(
                color: isDark ? AppColors.greenAbyss : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.4),
                  width: 1.2,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── الهيدر الملكي ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.greenDeep.withValues(alpha: 0.95),
                          AppColors.greenAbyss,
                        ],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.gold.withValues(alpha: 0.2),
                            border: Border.all(
                              color: AppColors.gold.withValues(alpha: 0.5),
                            ),
                          ),
                          child: const Icon(
                            Icons.info_outline_rounded,
                            color: AppColors.goldBright,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'كشف تبرعات شهر $monthName',
                                style: const TextStyle(
                                  fontFamily: AppTheme.displayFamily,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'السنة المالية: $_selectedYear',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: 11.5,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── قائمة الكروت التفصيلية ──
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (donations.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Text(
                                'لا توجد دفعات مسجلة لهذا الشهر',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: 13,
                                  color: isDark ? Colors.white60 : Colors.black54,
                                ),
                              ),
                            )
                          else
                            ...List.generate(donations.length, (idx) {
                              final don = donations[idx];
                              final amt = (don['amount'] as num?) ?? 0;
                              final dateStr = don['date']?.toString();
                              final dDate = dateStr != null
                                  ? DateTime.tryParse(dateStr)
                                  : fallbackDate;
                              final kind = don['kind']?.toString() ?? 'cash';
                              final textVal = don['text_value']?.toString() ?? '';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : Colors.black.withValues(alpha: 0.03),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.gold.withValues(alpha: 0.35),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isDark
                                          ? Colors.black.withValues(alpha: 0.3)
                                          : Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // السطر الأول: رقم الدفعة #1 والمبلغ الرئيسي
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        // الوسام الرقمي للدفعة #1
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.gold.withValues(alpha: 0.18),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: AppColors.gold.withValues(alpha: 0.4),
                                            ),
                                          ),
                                          child: Text(
                                            '#${idx + 1}',
                                            style: TextStyle(
                                              fontFamily: AppTheme.displayFamily,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: isDark
                                                  ? AppColors.goldBright
                                                  : AppColors.goldDark,
                                            ),
                                          ),
                                        ),

                                        // المبلغ الرئيسي بخط عريض
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            kind == 'cash'
                                                ? Fmt.money(amt)
                                                : textVal,
                                            style: TextStyle(
                                              fontFamily: AppTheme.displayFamily,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: kind == 'cash'
                                                  ? AppColors.green
                                                  : (isDark
                                                      ? AppColors.goldBright
                                                      : AppColors.goldDark),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    const Divider(height: 1),
                                    const SizedBox(height: 10),

                                    // السطر الثاني: تاريخ الإضافة الدقيق
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today_rounded,
                                          size: 13,
                                          color: isDark
                                              ? AppColors.textOnDarkMuted
                                              : AppColors.textOnLightMuted,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'تاريخ الدفعة: ',
                                          style: TextStyle(
                                            fontFamily: AppTheme.fontFamily,
                                            fontSize: 11.5,
                                            color: isDark
                                                ? AppColors.textOnDarkMuted
                                                : AppColors.textOnLightMuted,
                                          ),
                                        ),
                                        Text(
                                          dDate != null ? Fmt.date(dDate) : '—',
                                          style: TextStyle(
                                            fontFamily: AppTheme.fontFamily,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }),

                          const SizedBox(height: 6),

                          // ── شارة المجموع النهائي منظم سطر تحت سطر بلا أي OverFlow ──
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isDark
                                    ? [
                                        AppColors.greenDeep.withValues(alpha: 0.9),
                                        AppColors.greenAbyss,
                                      ]
                                    : [
                                        AppColors.lightGreenTint,
                                        AppColors.gold.withValues(alpha: 0.1),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.gold.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'إجمالي تبرعات شهر $monthName',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: AppTheme.displayFamily,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    Fmt.money(totalAmt),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: AppTheme.displayFamily,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: isDark
                                          ? AppColors.goldBright
                                          : AppColors.goldDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── زر الإغلاق ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text(
                          'إغلاق النافذة',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 4️⃣ نافذة تبرعات المتبرعين المخصصة للشهر المالي
  Future<void> _openDonorMonthDialog(
    ContributorModel c,
    int monthIndex,
    Map<String, dynamic>? existingEntry,
  ) async {
    final monthName = _monthNames[monthIndex - 1];
    String currentMode = 'add'; // 'add' (🟢 إضافة / ✏️ تعديل) أو 'edit' (📋 القائمة)
    String selectedKind = c.type == ContributorType.donor ? 'cash' : 'construction'; // 'cash', 'construction', 'food'
    String? editingDonationId; // معرف التبرع المختار للتعديل

    final amountController = TextEditingController();
    final textValueController = TextEditingController();
    DateTime donationDate = DateTime.now();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.50),
      builder: (ctx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              final donations = existingEntry != null &&
                      existingEntry['donations'] is List
                  ? List<Map<String, dynamic>>.from(
                      existingEntry['donations'] as List)
                  : <Map<String, dynamic>>[];

              return Dialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22)),
                clipBehavior: Clip.antiAlias,
                insetPadding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 32),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ── شريط العنوان والتبويبات ──
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.green.withValues(alpha: 0.9),
                                AppColors.greenDeep,
                              ],
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                            ),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(22)),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'تبرعات شهر $monthName ($_selectedYear)',
                                style: const TextStyle(
                                  fontFamily: AppTheme.displayFamily,
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 12),
                              // تبويبا الإضافة 🟢 والتعديل 🟡
                              Row(
                                children: [
                                  // زر إضافة تبرع باللون الأخضر
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        setModalState(() {
                                          currentMode = 'add';
                                          editingDonationId = null;
                                          amountController.clear();
                                          textValueController.clear();
                                          donationDate = DateTime.now();
                                        });
                                      },
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 180),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 9),
                                        decoration: BoxDecoration(
                                          color: currentMode == 'add'
                                              ? AppColors.green
                                              : Colors.white.withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Colors.white,
                                            width: currentMode == 'add'
                                                ? 1.8
                                                : 0.5,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                                editingDonationId != null
                                                    ? Icons.edit_note_rounded
                                                    : Icons.add_circle_outline_rounded,
                                                size: 16,
                                                color: Colors.white),
                                            const SizedBox(width: 6),
                                            Flexible(
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Text(
                                                  editingDonationId != null
                                                      ? 'تعديل التبرع ✏️'
                                                      : 'إضافة تبرع',
                                                  style: const TextStyle(
                                                    fontFamily: AppTheme.fontFamily,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  // زر قائمة التبرعات باللون الذهبي/البرتقالي
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setModalState(
                                          () => currentMode = 'edit'),
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 180),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 9),
                                        decoration: BoxDecoration(
                                          color: currentMode == 'edit'
                                              ? AppColors.goldDark
                                              : Colors.white.withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Colors.white,
                                            width: currentMode == 'edit'
                                                ? 1.8
                                                : 0.5,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.list_alt_rounded,
                                                size: 16, color: Colors.white),
                                            const SizedBox(width: 6),
                                            Flexible(
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Text(
                                                  'السجل (${donations.length})',
                                                  style: const TextStyle(
                                                    fontFamily: AppTheme.fontFamily,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // ── محتوى التبويب المختارات ──
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: currentMode == 'add'
                              ? _buildAddDonorDonationView(
                                  ctx: ctx,
                                  contributorType: c.type,
                                  setModalState: setModalState,
                                  selectedKind: selectedKind,
                                  editingDonationId: editingDonationId,
                                  onKindChanged: (k) =>
                                      setModalState(() => selectedKind = k),
                                  amountController: amountController,
                                  textValueController: textValueController,
                                  donationDate: donationDate,
                                  onDateChanged: (d) =>
                                      setModalState(() => donationDate = d),
                                  isDark: isDark,
                                  onSave: () async {
                                    final numVal = num.tryParse(amountController
                                            .text
                                            .replaceAll(',', '')
                                            .replaceAll('٬', '')
                                            .trim()) ??
                                        0;
                                    final repo = ref.read(
                                        contributorsRepositoryProvider);

                                    final nav = Navigator.of(ctx);
                                    final messenger =
                                        ScaffoldMessenger.of(context);

                                    if (editingDonationId != null) {
                                      // تعديل تبرع موجود
                                      await repo.updateDonorDonation(
                                        contributorId: c.id,
                                        year: _selectedYear,
                                        month: monthIndex,
                                        donationId: editingDonationId!,
                                        kind: selectedKind,
                                        amount: selectedKind == 'cash' ? numVal : 0,
                                        textValue: selectedKind != 'cash'
                                            ? textValueController.text.trim()
                                            : '',
                                        date: donationDate,
                                      );
                                    } else {
                                      // إضافة تبرع جديد
                                      await repo.addDonorDonation(
                                        contributorId: c.id,
                                        year: _selectedYear,
                                        month: monthIndex,
                                        kind: selectedKind,
                                        amount: selectedKind == 'cash' ? numVal : 0,
                                        textValue: selectedKind != 'cash'
                                            ? textValueController.text.trim()
                                            : '',
                                        date: donationDate,
                                      );
                                    }

                                    await _loadLedger();
                                    await Future.wait([
                                      ref.refresh(statsRawProvider.future),
                                      ref.refresh(subscribersRawProvider.future),
                                      ref.refresh(
                                          allContributorsRawProvider.future),
                                    ]);

                                    if (mounted) {
                                      nav.pop();
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(editingDonationId != null
                                              ? 'تم تعديل التبرع لشهر $monthName بنجاح!'
                                              : 'تمت إضافة التبرع لشهر $monthName بنجاح!'),
                                          backgroundColor: AppColors.greenDeep,
                                        ),
                                      );
                                    }
                                  },
                                )
                              : _buildEditDonorDonationsView(
                                  donations: donations,
                                  isDark: isDark,
                                  onSelectForEdit: (don) {
                                    setModalState(() {
                                      editingDonationId = don['id']?.toString();
                                      selectedKind = don['kind']?.toString() ?? 'construction';
                                      if (selectedKind == 'cash') selectedKind = 'construction';
                                      final textVal = don['text_value']?.toString() ?? '';
                                      textValueController.text = textVal;
                                      final dateStr = don['date']?.toString();
                                      if (dateStr != null) {
                                        final parsed = DateTime.tryParse(dateStr);
                                        if (parsed != null) donationDate = parsed;
                                      }
                                      currentMode = 'add';
                                    });
                                  },
                                  onDelete: (donId) async {
                                    final repo = ref.read(
                                        contributorsRepositoryProvider);
                                    await repo.deleteDonorDonation(
                                      contributorId: c.id,
                                      year: _selectedYear,
                                      month: monthIndex,
                                      donationId: donId,
                                    );
                                    await _loadLedger();
                                    await Future.wait([
                                      ref.refresh(statsRawProvider.future),
                                      ref.refresh(subscribersRawProvider.future),
                                      ref.refresh(
                                          allContributorsRawProvider.future),
                                    ]);
                                    setModalState(() {});
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// محتوى تبويب إضافة / تعديل تبرع
  Widget _buildAddDonorDonationView({
    required BuildContext ctx,
    required ContributorType contributorType,
    required void Function(void Function()) setModalState,
    required String selectedKind,
    required String? editingDonationId,
    required void Function(String) onKindChanged,
    required TextEditingController amountController,
    required TextEditingController textValueController,
    required DateTime donationDate,
    required void Function(DateTime) onDateChanged,
    required bool isDark,
    required VoidCallback onSave,
  }) {
    final isEditing = editingDonationId != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isEditing)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.gold, width: 1),
            ),
            child: const Row(
              children: [
                Icon(Icons.edit_note_rounded, size: 18, color: AppColors.gold),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'جاري تعديل التبرع المختار... عدّل البيانات واضغط حفظ',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gold,
                    ),
                  ),
                ),
              ],
            ),
          ),

        if (contributorType == ContributorType.inKind) ...[
          Text(
            'نوع التبرع:',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textOnDarkMuted : AppColors.textOnLightMuted,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildKindChip(
                  label: 'مواد أنشائية',
                  icon: Icons.construction_rounded,
                  selected: selectedKind == 'construction',
                  onTap: () => onKindChanged('construction'),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildKindChip(
                  label: 'مواد غذائية',
                  icon: Icons.rice_bowl_rounded,
                  selected: selectedKind == 'food',
                  onTap: () => onKindChanged('food'),
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],

        // الخلية المتزحلقة بحسب نوع التبرع
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: contributorType == ContributorType.donor
              ? TextField(
                  key: const ValueKey('cash_field'),
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    ThousandsFormatter(),
                  ],
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.goldBright : AppColors.goldDark,
                  ),
                  decoration: InputDecoration(
                    labelText: 'مبلغ التبرع المالي (د.ع)',
                    hintText: '25,000',
                    prefixIcon:
                        const Icon(Icons.payments_outlined, color: AppColors.gold),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                )
              : TextField(
                  key: ValueKey('${selectedKind}_field'),
                  controller: textValueController,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 14,
                    color: isDark ? AppColors.goldBright : AppColors.goldDark,
                  ),
                  decoration: InputDecoration(
                    labelText: selectedKind == 'food'
                        ? 'وصف المواد الغذائية (مثال: 5 سلات غذائية)'
                        : 'وصف المواد الإنشائية (مثال: 10 أكياس سمنت)',
                    hintText: selectedKind == 'food'
                        ? 'أدخل نوع وكمية التبرع الغذائي'
                        : 'أدخل نوع وكمية التبرع الإنشائي',
                    prefixIcon: Icon(
                      selectedKind == 'food'
                          ? Icons.rice_bowl_outlined
                          : Icons.construction_outlined,
                      color: AppColors.gold,
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                ),
        ),
        const SizedBox(height: 16),

        // تاريخ التبرع
        InkWell(
          onTap: () async {
            final picked = await AppDatePickerDialog.show(
              context: ctx,
              initialDate: donationDate,
              firstDate: DateTime(2015),
              lastDate: DateTime(2040),
              primaryColor: AppColors.green,
            );
            if (picked != null) {
              onDateChanged(picked);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.18)
                    : Colors.black.withValues(alpha: 0.18),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 16, color: AppColors.gold),
                    SizedBox(width: 8),
                    Text('تاريخ التبرع:',
                        style: TextStyle(
                            fontFamily: AppTheme.fontFamily, fontSize: 13)),
                  ],
                ),
                Text(
                  Fmt.date(donationDate),
                  style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // أزرار الحفظ والإلغاء
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء',
                  style: TextStyle(fontFamily: AppTheme.fontFamily)),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              icon: Icon(
                isEditing ? Icons.check_circle_rounded : Icons.add_rounded,
                size: 18,
                color: Colors.white,
              ),
              label: Text(
                isEditing ? 'حفظ التعديل' : 'إضافة التبرع',
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isEditing ? AppColors.goldDark : AppColors.green,
                foregroundColor: Colors.white,
                elevation: 2,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: onSave,
            ),
          ],
        ),
      ],
    );
  }

  /// محتوى تبويب تعديل التبرعات المدخلة سابقاً
  Widget _buildEditDonorDonationsView({
    required List<Map<String, dynamic>> donations,
    required bool isDark,
    required void Function(Map<String, dynamic>) onSelectForEdit,
    required void Function(String) onDelete,
  }) {
    if (donations.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'لا توجد تبرعات مسجلة في هذا الشهر بعد',
            style: TextStyle(fontFamily: AppTheme.fontFamily, fontSize: 13.5),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'انقر على أي كارت لتعديله بالكامل (أو 🗑️ للحذف):',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.goldBright : AppColors.goldDark,
          ),
        ),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: donations.length,
          separatorBuilder: (ctx, idx) => const SizedBox(height: 8),
          itemBuilder: (ctx, idx) {
            final don = donations[idx];
            final donId = don['id']?.toString() ?? '';
            final kind = don['kind']?.toString() ?? 'cash';
            final amt = (don['amount'] as num?) ?? 0;
            final textVal = don['text_value']?.toString() ?? '';
            final dateStr = don['date']?.toString();
            final dDate =
                dateStr != null ? DateTime.tryParse(dateStr) : null;

            final kindLabel = kind == 'cash'
                ? 'مبلغ مالية'
                : (kind == 'food' ? 'مواد غذائية' : 'مواد أنشائية');
            final displayVal =
                kind == 'cash' ? Fmt.amount(amt) : textVal;

            return InkWell(
              onTap: () => onSelectForEdit(don),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? AppColors.gold.withValues(alpha: 0.3)
                        : AppColors.gold.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      kind == 'cash'
                          ? Icons.payments_rounded
                          : (kind == 'food'
                              ? Icons.rice_bowl_rounded
                              : Icons.construction_rounded),
                      size: 18,
                      color: AppColors.gold,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$kindLabel: $displayVal',
                            style: const TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (dDate != null)
                            Text(
                              Fmt.date(dDate),
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.textOnDarkMuted
                                    : AppColors.textOnLightMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_rounded,
                          size: 18, color: AppColors.gold),
                      onPressed: () => onSelectForEdit(don),
                      tooltip: 'تعديل التبرع',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          size: 18, color: AppColors.overdue),
                      onPressed: () => onDelete(donId),
                      tooltip: 'حذف التبرع',
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// شريحة اختيار نوع التبرع
  Widget _buildKindChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.green.withValues(alpha: 0.16)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppColors.green
                : (isDark
                    ? Colors.white.withValues(alpha: 0.18)
                    : Colors.black.withValues(alpha: 0.15)),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected
                  ? AppColors.green
                  : (isDark
                      ? AppColors.textOnDarkMuted
                      : AppColors.textOnLightMuted),
            ),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 10.5,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color: selected
                      ? AppColors.green
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

  /// 5️⃣ نافذة عرض مصغرة وسريعة للتبرعات المتعددة في الشهر
  Future<void> _showDonorItemsQuickView(
    ContributorModel c,
    int monthIndex,
    Map<String, dynamic>? entry,
  ) async {
    final monthName = _monthNames[monthIndex - 1];
    final donations = entry != null && entry['donations'] is List
        ? List<Map<String, dynamic>>.from(entry['donations'] as List)
        : <Map<String, dynamic>>[];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            clipBehavior: Clip.hardEdge,
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 380),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'تبرعات شهر $monthName ($_selectedYear)',
                        style: const TextStyle(
                          fontFamily: AppTheme.displayFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (donations.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          'لا توجد تبرعات مسجلة في هذا الشهر',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: donations.length,
                        separatorBuilder: (ctx, idx) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final item = donations[i];
                          final kind = item['kind']?.toString() ?? 'cash';
                          final amt = (item['amount'] as num?) ?? 0;
                          final textVal = item['text_value']?.toString() ?? '';
                          final dateStr = item['date']?.toString();
                          final dDate = dateStr != null
                              ? DateTime.tryParse(dateStr)
                              : null;

                          final kindLabel = kind == 'cash'
                              ? 'مبلغ مالي'
                              : (kind == 'food'
                                  ? 'مواد غذائية'
                                  : 'مواد أنشائية');
                          final icon = kind == 'cash'
                              ? Icons.payments_rounded
                              : (kind == 'food'
                                  ? Icons.rice_bowl_rounded
                                  : Icons.construction_rounded);
                          final valStr =
                              kind == 'cash' ? Fmt.amount(amt) : textVal;

                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.black.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.black.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(icon, size: 18, color: AppColors.gold),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '$kindLabel: $valStr',
                                        style: const TextStyle(
                                          fontFamily: AppTheme.fontFamily,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (dDate != null)
                                        Text(
                                          'تاريخ التبرع: ${Fmt.date(dDate)}',
                                          style: TextStyle(
                                            fontFamily: AppTheme.fontFamily,
                                            fontSize: 11,
                                            color: isDark
                                                ? AppColors.textOnDarkMuted
                                                : AppColors.textOnLightMuted,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.edit_note_rounded,
                          size: 18, color: Colors.white),
                      label: const Text(
                        'إدارة وتعديل التبرعات',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _openDonorMonthDialog(c, monthIndex, entry);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// منسق أرقام يضيف فوارز الآلاف تلقائياً أثناء الكتابة
class ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }
    final cleanText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanText.isEmpty) {
      return newValue.copyWith(text: '');
    }
    final number = int.tryParse(cleanText);
    if (number == null) return newValue;

    final formatted = Fmt.amount(number);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}


