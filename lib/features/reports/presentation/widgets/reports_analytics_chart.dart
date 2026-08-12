import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/glass.dart';
import '../../../../shared/models/enums.dart';

/// رسم بياني احترافي تفاعلي لمقارنة الأشهر الـ 12 لسنة 2026 من حيث:
/// - 🟢 التسديدات (الاشتراكات)
/// - 🟡 التبرعات (المالية)
/// - 🔵 الدعم العيني (المواد)
class ReportsAnalyticsChart extends ConsumerStatefulWidget {
  const ReportsAnalyticsChart({super.key});

  @override
  ConsumerState<ReportsAnalyticsChart> createState() =>
      _ReportsAnalyticsChartState();
}

class _ReportsAnalyticsChartState extends ConsumerState<ReportsAnalyticsChart> {
  int? _selectedMonthIndex; // 1 to 12

  final List<String> _monthsShort = const [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر'
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allContributorsAsync = ref.watch(allContributorsProvider);

    return allContributorsAsync.when(
      loading: () => const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator(color: AppColors.gold)),
      ),
      error: (err, stack) => const SizedBox.shrink(),
      data: (contributors) {
        // حساب مبالغ ومشاركات كل شهر
        final monthlyPayments = List<double>.filled(12, 0.0);
        final monthlyDonations = List<double>.filled(12, 0.0);
        final monthlySupportCount = List<int>.filled(12, 0);

        final repo = ref.watch(contributorsRepositoryProvider);

        for (final c in contributors) {
          for (int month = 1; month <= 12; month++) {
            final boxKey = 'ledger_${c.id}_2026';
            var raw = repo.cache.readOne(AppConfig.boxPayments, boxKey);
            raw ??= repo.cache.readOne(AppConfig.boxContributors, boxKey);
            final rawMap = raw is Map ? raw : null;
            if (rawMap != null) {
              final monthEntry = rawMap[month.toString()];
              if (monthEntry is Map) {
                final isPaid = monthEntry['is_paid'] == true;
                final amt = (monthEntry['amount'] as num?)?.toDouble() ?? 0.0;
                final donations = monthEntry['donations'] is List
                    ? (monthEntry['donations'] as List)
                    : [];

                if (c.isSubscriber && isPaid) {
                  monthlyPayments[month - 1] += amt;
                } else if (c.type == ContributorType.donor) {
                  monthlyDonations[month - 1] += amt;
                }

                if (donations.isNotEmpty) {
                  for (final d in donations) {
                    if (d is Map) {
                      final k = d['kind']?.toString();
                      if (k == 'cash' && c.type == ContributorType.donor) {
                        monthlyDonations[month - 1] +=
                            (d['amount'] as num?)?.toDouble() ?? 0.0;
                      } else if (k == 'food' || k == 'construction') {
                        monthlySupportCount[month - 1]++;
                      }
                    }
                  }
                } else {
                  final food = monthEntry['food_desc']?.toString() ?? '';
                  final constr =
                      monthEntry['construction_desc']?.toString() ?? '';
                  if (food.trim().isNotEmpty) monthlySupportCount[month - 1]++;
                  if (constr.trim().isNotEmpty) monthlySupportCount[month - 1]++;
                }
              }
            }
          }
        }

        // إيجاد القيمة القسوى للمقياس
        double maxVal = 10000;
        for (int i = 0; i < 12; i++) {
          if (monthlyPayments[i] > maxVal) maxVal = monthlyPayments[i];
          if (monthlyDonations[i] > maxVal) maxVal = monthlyDonations[i];
        }

        final selectedIdx = _selectedMonthIndex ?? (DateTime.now().month - 1);
        final selPayments = monthlyPayments[selectedIdx];
        final selDonations = monthlyDonations[selectedIdx];
        final selSupport = monthlySupportCount[selectedIdx];
        final selMonthName = _monthsShort[selectedIdx];

        return GlassCard(
          radius: 20,
          padding: const EdgeInsets.all(16),
          borderColor: AppColors.gold.withValues(alpha: 0.35),
          gradient: isDark
              ? LinearGradient(
                  colors: [
                    AppColors.greenDeep.withValues(alpha: 0.85),
                    AppColors.greenAbyss,
                  ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                )
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── الترويسة والعنوان ودليل الألوان ──
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                          Icons.bar_chart_rounded,
                          color: AppColors.goldBright,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'المقارنة التحليلية الشهرية (2026)',
                              style: TextStyle(
                                fontFamily: AppTheme.displayFamily,
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'اضغط على العمود لرؤية كشف الشهر',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 10.5,
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
                  const SizedBox(height: 10),
                  // دليل الألوان
                  Row(
                    children: [
                      _legendDot(AppColors.green, 'تسديدات'),
                      const SizedBox(width: 12),
                      _legendDot(AppColors.gold, 'تبرعات'),
                      const SizedBox(width: 12),
                      _legendDot(Colors.lightBlueAccent, 'دعم عيني'),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── شريط الرسوم البيانية للأشهر الـ 12 ──
              SizedBox(
                height: 140,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(12, (index) {
                    final isSelected = index == selectedIdx;
                    final payH = maxVal > 0
                        ? (monthlyPayments[index] / maxVal) * 90
                        : 5.0;
                    final donH = maxVal > 0
                        ? (monthlyDonations[index] / maxVal) * 90
                        : 5.0;

                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedMonthIndex = index;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.gold.withValues(alpha: 0.18)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: isSelected
                                ? Border.all(
                                    color:
                                        AppColors.gold.withValues(alpha: 0.6),
                                    width: 1,
                                  )
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // الأشرطة المقارنة
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  // عمود التسديدات الأخضر
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    width: 5,
                                    height: payH.clamp(4.0, 90.0),
                                    decoration: BoxDecoration(
                                      color: AppColors.green,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  // عمود التبرعات الذهبي
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    width: 5,
                                    height: donH.clamp(4.0, 90.0),
                                    decoration: BoxDecoration(
                                      color: AppColors.goldBright,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              // اسم الشهر
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  _monthsShort[index],
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontSize: 9.5,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? (isDark
                                            ? AppColors.goldBright
                                            : AppColors.goldDark)
                                        : (isDark
                                            ? Colors.white60
                                            : Colors.black54),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // ── ملخص الشهر المختار ──
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.25)
                      : AppColors.lightGreenTint.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'كشف تفاصيل شهر $selMonthName:',
                      style: TextStyle(
                        fontFamily: AppTheme.displayFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.goldBright
                            : AppColors.goldDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _metricBadge(
                              'التسديد:', Fmt.moneyShort(selPayments), AppColors.green),
                          const SizedBox(width: 6),
                          _metricBadge('التبرع:', Fmt.moneyShort(selDonations),
                              AppColors.goldBright),
                          const SizedBox(width: 6),
                          _metricBadge('الدعم:', '$selSupport مواد',
                              Colors.lightBlueAccent),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 9.5,
          ),
        ),
      ],
    );
  }

  Widget _metricBadge(String title, String val, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 10,
              color: color,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            val,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
