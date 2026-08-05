import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/glass.dart';

/// صفحة «عرض الكل»: تحتوي على كارتات عمودية ملمومة وأنيقة للفئات الثلاث.
class AllContributorsCategoriesPage extends ConsumerWidget {
  const AllContributorsCategoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsProvider);
    final theme = Theme.of(context);
    final s = stats.valueOrNull;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('عرض الكل — فئات المساهمين'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
        children: [
          Text(
            'اختر الفئة لعرض القائمة التفصيلية الكاملة:',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),

          // 1. كارت المشتركين العمودي (ملموم ومصغّر)
          _CategoryVerticalCard(
            title: 'المشتركون',
            subtitle: 'سجل المشتركين الملتزمين بالسداد',
            icon: Icons.people_alt_rounded,
            iconColor: const Color(0xFF14512F),
            count: s?.subscribersCount,
            total: s?.subscriptionsTotal,
            badge: (s?.overdueCount ?? 0) > 0
                ? '${Fmt.count(s!.overdueCount)} متأخر'
                : null,
            onTap: () => context.go('/contributors/subscribers'),
          ),

          const SizedBox(height: 10),

          // 2. كارت المتبرعين العمودي (ملموم ومصغّر)
          _CategoryVerticalCard(
            title: 'المتبرعون',
            subtitle: 'سجل المتبرعين والداعمين ومبالغهم',
            icon: Icons.volunteer_activism_rounded,
            iconColor: const Color(0xFFD79A3C),
            count: s?.donorsCount,
            total: s?.donationsTotal,
            onTap: () => context.go('/contributors/donors'),
          ),

          const SizedBox(height: 10),

          // 3. كارت المساهمين العمودي (كافة المشتركين والمتبرعين معاً)
          _CategoryVerticalCard(
            title: 'المساهمون (كافة البيانات)',
            subtitle: 'عرض كافّة المشتركين والمتبرعين في قائمة واحدة',
            icon: Icons.groups_rounded,
            iconColor: const Color(0xFF7B2CBF),
            count: s != null ? s.subscribersCount + s.donorsCount : null,
            total: s?.totalAmount,
            onTap: () => context.go('/contributors/list_all'),
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
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      gradient: isDark ? AppColors.countCardGradient : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: isDark ? 0.22 : 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: iconColor.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Icon(icon, color: iconColor, size: 20),
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
                        fontSize: 15,
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
              const Icon(Icons.chevron_left_rounded, size: 22),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _Metric(label: 'العدد', value: Fmt.count(count ?? 0)),
              const SizedBox(width: 18),
              Flexible(
                child: _Metric(
                  label: 'المجموع',
                  value: Fmt.moneyShort(total ?? 0),
                ),
              ),
              if (badge != null) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.overdue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          size: 12, color: AppColors.overdue),
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
            ],
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 11,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.textOnDarkMuted
                : AppColors.textOnLightMuted,
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            maxLines: 1,
            style: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: AppColors.gold,
            ),
          ),
        ),
      ],
    );
  }
}
