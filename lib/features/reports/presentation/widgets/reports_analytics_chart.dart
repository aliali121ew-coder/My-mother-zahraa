import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/glass.dart';
import '../../../../shared/models/enums.dart';
import '../../../purchases/data/purchases_provider.dart';

/// رسم بياني تفاعلي احترافي باستخدام مكتبة Syncfusion Charts
class ReportsAnalyticsChart extends ConsumerStatefulWidget {
  const ReportsAnalyticsChart({super.key});

  @override
  ConsumerState<ReportsAnalyticsChart> createState() =>
      _ReportsAnalyticsChartState();
}

class _ReportsAnalyticsChartState extends ConsumerState<ReportsAnalyticsChart> {
  int? _selectedFinIndex;
  int? _selectedContribIndex;
  int _currentSegment = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statsAsync = ref.watch(statsProvider);
    final allContribsAsync = ref.watch(allContributorsProvider);
    final purchasesAsync = ref.watch(purchasesProvider);

    return statsAsync.when(
      loading: () => const SizedBox(
        height: 240,
        child: Center(child: CircularProgressIndicator(color: AppColors.gold)),
      ),
      error: (err, stack) => const SizedBox.shrink(),
      data: (stats) {
        final subscribersCount = allContribsAsync.valueOrNull
                ?.where((c) => c.isSubscriber)
                .length ??
            stats.subscribersCount;
        final donorsCount = allContribsAsync.valueOrNull
                ?.where((c) => c.type == ContributorType.donor)
                .length ??
            stats.donorsCount;
        final supportersCount = allContribsAsync.valueOrNull
                ?.where((c) => c.type == ContributorType.inKind)
                .length ??
            stats.inKindCount;

        // 1. بيانات دائرة الموقف المالي (المبلغ الكلي vs المصروف الكلي)
        final localPurchasesTotal = purchasesAsync.valueOrNull?.fold<num>(0, (sum, item) => sum + item.amount) ?? 0;
        final totalExpensesWithPurchases = stats.expensesTotal + localPurchasesTotal;
        
        final totalAmt = stats.totalAmount > 0 ? stats.totalAmount.toDouble() : 1.0;
        final expAmt = totalExpensesWithPurchases.toDouble();

        final finSegments = [
          _DonutSegmentData(
            label: 'المبلغ الكلي',
            value: totalAmt,
            formattedValue: Fmt.money(stats.totalAmount),
            color: const Color(0xFF10B981),
            darkColor: const Color(0xFF047857),
            icon: Icons.account_balance_wallet_rounded,
          ),
          _DonutSegmentData(
            label: 'المصروف الكلي',
            value: expAmt > 0 ? expAmt : 0.001,
            formattedValue: Fmt.money(totalExpensesWithPurchases),
            color: const Color(0xFFF43F5E),
            darkColor: const Color(0xFFBE123C),
            icon: Icons.receipt_long_rounded,
          ),
        ];

        // 3. حالة المشتركين (المتأخرون، في المهلة، المسددون)
        final overdueCount = allContribsAsync.valueOrNull
                ?.where((c) => c.isSubscriber && c.paymentStatus == PaymentStatus.overdue)
                .length ?? 0;
        final graceCount = allContribsAsync.valueOrNull
                ?.where((c) => c.isSubscriber && c.paymentStatus == PaymentStatus.grace)
                .length ?? 0;
        final paidCount = allContribsAsync.valueOrNull
                ?.where((c) => c.isSubscriber && c.paymentStatus == PaymentStatus.paid)
                .length ?? 0;

        // 2. بيانات دائرة الفئات والمساهمين وحالات السداد (6 فئات مدمجة)
        final combinedSegments = [
          _DonutSegmentData(
            label: 'المشتركون',
            value: subscribersCount > 0 ? subscribersCount.toDouble() : 1.0,
            formattedValue: '$subscribersCount مشترك',
            color: const Color(0xFF0284C7),
            darkColor: const Color(0xFF0369A1),
            icon: Icons.groups_rounded,
          ),
          _DonutSegmentData(
            label: 'المتبرعون',
            value: donorsCount > 0 ? donorsCount.toDouble() : 1.0,
            formattedValue: '$donorsCount متبرع',
            color: const Color(0xFFD97706),
            darkColor: const Color(0xFFB45309),
            icon: Icons.volunteer_activism_rounded,
          ),
          _DonutSegmentData(
            label: 'الداعمون',
            value: supportersCount > 0 ? supportersCount.toDouble() : 1.0,
            formattedValue: '$supportersCount داعم',
            color: const Color(0xFF7C3AED),
            darkColor: const Color(0xFF6D28D9),
            icon: Icons.shopping_basket_rounded,
          ),
          _DonutSegmentData(
            label: 'المتأخرون',
            value: overdueCount > 0 ? overdueCount.toDouble() : 1.0,
            formattedValue: '$overdueCount متأخر',
            color: const Color(0xFFE11D48),
            darkColor: const Color(0xFF9F1239),
            icon: Icons.timer_off_rounded,
          ),
          _DonutSegmentData(
            label: 'في المهلة',
            value: graceCount > 0 ? graceCount.toDouble() : 1.0,
            formattedValue: '$graceCount في المهلة',
            color: const Color(0xFFF59E0B),
            darkColor: const Color(0xFFB45309),
            icon: Icons.hourglass_bottom_rounded,
          ),
          _DonutSegmentData(
            label: 'المسددون',
            value: paidCount > 0 ? paidCount.toDouble() : 1.0,
            formattedValue: '$paidCount مسدد',
            color: const Color(0xFF10B981),
            darkColor: const Color(0xFF047857),
            icon: Icons.check_circle_rounded,
          ),
        ];

        return GlassCard(
          radius: 24,
          padding: const EdgeInsets.all(16),
          borderColor: isDark
              ? AppColors.gold.withValues(alpha: 0.4)
              : AppColors.greenDeep.withValues(alpha: 0.3),
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

                  // ── محوّل الرؤية الانزلاقي (Sliding Segmented Control) ──
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoSlidingSegmentedControl<int>(
                      backgroundColor: isDark 
                          ? Colors.black.withValues(alpha: 0.3) 
                          : AppColors.lightGreenTint.withValues(alpha: 0.5),
                      thumbColor: isDark 
                          ? AppColors.gold.withValues(alpha: 0.25)
                          : Colors.white,
                      groupValue: _currentSegment,
                      onValueChanged: (int? value) {
                        if (value != null) {
                          setState(() {
                            _currentSegment = value;
                          });
                        }
                      },
                      children: {
                        0: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'الموقف المالي',
                            style: TextStyle(
                              fontFamily: AppTheme.displayFamily,
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: _currentSegment == 0
                                  ? (isDark ? AppColors.goldBright : AppColors.greenDeep)
                                  : (isDark ? AppColors.textOnDarkMuted : AppColors.textOnLightMuted),
                            ),
                          ),
                        ),
                        1: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'الإحصائية',
                            style: TextStyle(
                              fontFamily: AppTheme.displayFamily,
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: _currentSegment == 1
                                  ? (isDark ? AppColors.goldBright : AppColors.greenDeep)
                                  : (isDark ? AppColors.textOnDarkMuted : AppColors.textOnLightMuted),
                            ),
                          ),
                        ),
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── الدائرة الرئيسية الاحترافية الكبيرة ──
                  SizedBox(
                    width: double.infinity,
                    child: _currentSegment == 0 
                        ? _buildDonutCard(
                            title: 'توزيع الأموال والمصروفات',
                            segments: finSegments,
                            selectedIndex: _selectedFinIndex,
                            onSelect: (idx) => setState(() {
                              _selectedFinIndex = _selectedFinIndex == idx ? null : idx;
                            }),
                            isDark: isDark,
                          )
                        : _buildDonutCard(
                            title: 'الإحصائية',
                            segments: combinedSegments,
                            selectedIndex: _selectedContribIndex,
                            onSelect: (idx) => setState(() {
                              _selectedContribIndex = _selectedContribIndex == idx ? null : idx;
                            }),
                            isDark: isDark,
                          ),
                  ),

                ],
              ),
        );
      },
    );
  }

  Widget _buildDonutCard({
    required String title,
    required List<_DonutSegmentData> segments,
    required int? selectedIndex,
    required ValueChanged<int?> onSelect,
    required bool isDark,
  }) {
    final selSeg = selectedIndex != null && selectedIndex >= 0 && selectedIndex < segments.length 
        ? segments[selectedIndex] 
        : null;

    final totalValue = segments.fold<double>(
      0,
      (sum, s) => sum + (s.value <= 0 ? 0.001 : s.value),
    );

    // Create chart data with transparent gaps to mimic the requested design
    final List<_DonutSegmentData> chartData = [];
    final gapValue = totalValue * 0.025; // تقليل الفراغات إلى 2.5% لتناسب الشكل الجديد

    for (int i = 0; i < segments.length; i++) {
      chartData.add(segments[i]);
      // Add gap segment
      chartData.add(_DonutSegmentData(
        label: 'gap_$i',
        value: gapValue,
        formattedValue: '',
        color: Colors.transparent,
        darkColor: Colors.transparent,
        icon: Icons.circle,
      ));
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.22)
            : Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? AppColors.gold.withValues(alpha: 0.3)
              : AppColors.greenDeep.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTheme.displayFamily,
                  fontSize: 16.0,
                  fontWeight: FontWeight.w900,
                  color: isDark ? AppColors.goldBright : AppColors.greenDeep,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 230,
            width: 230,
            child: SfCircularChart(
              margin: EdgeInsets.zero,
              annotations: <CircularChartAnnotation>[
                if (selSeg != null)
                  CircularChartAnnotation(
                    widget: SizedBox(
                      width: 120, // تقييد العرض لضمان عمل FittedBox وتفادي تجاوز النص للدائرة
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(selSeg.icon, color: selSeg.color, size: 24),
                          const SizedBox(height: 6),
                          Text(
                            selSeg.label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: AppTheme.displayFamily,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.textOnDarkMuted
                                  : AppColors.textOnLightMuted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              selSeg.formattedValue,
                              style: TextStyle(
                                fontFamily: AppTheme.displayFamily,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : const Color(0xFF1F2937),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
              series: <CircularSeries>[
                DoughnutSeries<_DonutSegmentData, String>(
                  dataSource: chartData,
                  xValueMapper: (_DonutSegmentData data, _) => data.label,
                  yValueMapper: (_DonutSegmentData data, _) => data.value,
                  pointColorMapper: (_DonutSegmentData data, _) => data.color,
                  cornerStyle: CornerStyle.bothFlat,
                  innerRadius: '66%',
                  radius: '100%',
                  explode: true,
                  explodeIndex: selectedIndex != null ? selectedIndex * 2 : -1,
                  explodeOffset: '6%',
                  animationDuration: 1200,
                  dataLabelSettings: const DataLabelSettings(
                    isVisible: true,
                    labelPosition: ChartDataLabelPosition.inside,
                    textStyle: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  dataLabelMapper: (_DonutSegmentData data, _) {
                    if (data.color == Colors.transparent) return '';
                    final pct = (data.value / totalValue) * 100;
                    return '${pct.round()}%';
                  },
                  onPointTap: (ChartPointDetails details) {
                    if (details.pointIndex != null) {
                      // Because we injected gaps, actual indices are 0, 2, 4...
                      if (details.pointIndex! % 2 == 0) {
                        final actualIndex = details.pointIndex! ~/ 2;
                        onSelect(selectedIndex == actualIndex ? null : actualIndex);
                      }
                    }
                  },
                )
              ],
            ),
          ),
        ],
      ),
    );
  }


}

class _DonutSegmentData {
  final String label;
  final double value;
  final String formattedValue;
  final Color color;
  final Color darkColor;
  final IconData icon;

  const _DonutSegmentData({
    required this.label,
    required this.value,
    required this.formattedValue,
    required this.color,
    required this.darkColor,
    required this.icon,
  });
}
