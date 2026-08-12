import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/auto_hiding_app_bar.dart';
import '../../../core/widgets/glass.dart';

/// صفحة «عرض الكل»: كارتات عمودية احترافية وأنيقة للفئات الأربعة بلا أي اقتطاع.
class AllContributorsCategoriesPage extends ConsumerWidget {
  const AllContributorsCategoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final s = stats.valueOrNull;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AutoHidingAppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            'فئات الداعمين والمساهمين',
            style: TextStyle(
              fontFamily: AppTheme.displayFamily,
              fontSize: 18.5,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.goldBright : AppColors.goldDark,
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
        children: [
          // ترويسة الصفحة الضبابية الفاخرة
          GlassCard(
            blur: true,
            radius: 16,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.dashboard_customize_rounded,
                    size: 20,
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'دليل فئات المساهمة والدعم',
                        style: TextStyle(
                          fontFamily: AppTheme.displayFamily,
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'اختر الفئة لعرض القائمة التفصيلية الكاملة:',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 11.5,
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
          ),
          const SizedBox(height: 14),

          // 1. كارت عرض الكل الشامل العمودي الاحترافي (الأول في الأعلى)
          _CategoryVerticalCard(
            title: 'عرض الكل (كافة البيانات)',
            subtitle: 'يجمع جميع المشتركين والمتبرعين والداعمين والمساهمين معاً',
            icon: Icons.groups_rounded,
            iconColor: const Color(0xFF7B2CBF),
            count: s != null ? s.subscribersCount + s.donorsCount : null,
            total: s?.totalAmount,
            onTap: () => context.push('/contributors/list_all'),
          ),

          const SizedBox(height: 12),

          // 2. كارت المشتركين العمودي الاحترافي
          _CategoryVerticalCard(
            title: 'المشتركون',
            subtitle: 'سجل المشتركين الملتزمين بالسداد الشهري والسنوي',
            icon: Icons.people_alt_rounded,
            iconColor: const Color(0xFF14512F),
            count: s?.subscribersCount,
            total: s?.subscriptionsTotal,
            badge: (s?.overdueCount ?? 0) > 0
                ? '${Fmt.count(s!.overdueCount)} متأخر'
                : null,
            onTap: () => context.push('/contributors/subscribers'),
          ),

          const SizedBox(height: 12),

          // 3. كارت المتبرعين العمودي الاحترافي
          _CategoryVerticalCard(
            title: 'المتبرعون',
            subtitle: 'سجل المتبرعين ومبالغهم المالية المستقلة',
            icon: Icons.volunteer_activism_rounded,
            iconColor: const Color(0xFFD79A3C),
            count: s?.donorsCount,
            total: s?.donationsTotal,
            onTap: () => context.push('/contributors/donors'),
          ),

          const SizedBox(height: 12),

          // 4. كارت الداعمين والمساهمين العمودي الاحترافي
          _CategoryVerticalCard(
            title: 'الداعمين والمساهمين',
            subtitle: 'سجل الداعمين والمساهمين الذين لديهم بيانات دعم فقط',
            icon: Icons.shopping_basket_rounded,
            iconColor: const Color(0xFF0077B6),
            count: s?.donorsCount,
            total: s?.donationsTotal,
            onTap: () => context.push('/contributors/supporters'),
          ),
        ],
      ),
    );
  }
}

class _CategoryVerticalCard extends StatelessWidget {
  const _CategoryVerticalCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.count,
    this.total,
    this.badge,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final int? count;
  final num? total;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GlassCard(
      blur: true,
      onTap: onTap,
      radius: 20,
      padding: const EdgeInsets.all(14),
      gradient: isDark ? AppColors.countCardGradient : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: isDark ? 0.22 : 0.14),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: iconColor.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textOnDark : AppColors.textOnLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 11,
                        color: isDark ? AppColors.textOnDarkMuted : AppColors.textOnLightMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: isDark ? AppColors.textOnDarkMuted : AppColors.textOnLightMuted,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _Metric(
                    label: 'العدد',
                    value: Fmt.count(count ?? 0),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: _Metric(
                    label: 'المجموع',
                    value: Fmt.moneyShort(total ?? 0),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.overdue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 12,
                          color: AppColors.overdue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          badge!,
                          style: const TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.overdue,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 10.5,
            color: isDark ? AppColors.textOnDarkMuted : AppColors.textOnLightMuted,
          ),
        ),
        const SizedBox(height: 1),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            value,
            maxLines: 1,
            style: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.gold,
            ),
          ),
        ),
      ],
    );
  }
}
