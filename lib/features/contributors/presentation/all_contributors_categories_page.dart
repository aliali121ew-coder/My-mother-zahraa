import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/glass.dart';

/// صفحة «عرض الكل»: تحتوي على كارتات عمودية للفئات الثلاث (المشتركون، المتبرعون، المساهمون).
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
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
        children: [
          Text(
            'اختر الفئة لعرض القائمة التفصيلية الكاملة:',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // 1. كارت المشتركين العمودي
          _CategoryVerticalCard(
            title: 'المشتركون',
            subtitle: 'سجل المشتركين الملتزمين بحسب الاشتراك الشهري والسنوي',
            icon: Icons.people_alt_rounded,
            iconColor: const Color(0xFF14512F),
            count: s?.subscribersCount,
            total: s?.subscriptionsTotal,
            badge: (s?.overdueCount ?? 0) > 0
                ? '${Fmt.count(s!.overdueCount)} متأخر عن السداد'
                : null,
            onTap: () => context.go('/contributors/subscribers'),
          ),

          const SizedBox(height: 14),

          // 2. كارت المتبرعين العمودي
          _CategoryVerticalCard(
            title: 'المتبرعون',
            subtitle: 'سجل المتبرعين والداعمين للموكب ومبالغ تبرعاتهم',
            icon: Icons.volunteer_activism_rounded,
            iconColor: const Color(0xFFD79A3C),
            count: s?.donorsCount,
            total: s?.donationsTotal,
            onTap: () => context.go('/contributors/donors'),
          ),

          const SizedBox(height: 14),

          // 3. كارت المساهمين العمودي (كافة المشتركين والمتبرعين معاً)
          _CategoryVerticalCard(
            title: 'المساهمون (كافة البيانات)',
            subtitle: 'عرض كافّة المشتركين والمتبرعين في قائمة واحدة موحّدة',
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
      radius: AppTheme.radiusLarge,
      padding: const EdgeInsets.all(18),
      gradient: isDark ? AppColors.countCardGradient : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: isDark ? 0.22 : 0.14),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: iconColor.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textOnDark : AppColors.textOnLight,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12,
                        color: isDark ? AppColors.textOnDarkMuted : AppColors.textOnLightMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left_rounded, size: 26),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _Metric(label: 'العدد', value: Fmt.count(count ?? 0)),
              const SizedBox(width: 22),
              Flexible(
                child: _Metric(
                  label: 'المجموع',
                  value: Fmt.moneyShort(total ?? 0),
                ),
              ),
            ],
          ),
          if (badge != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.overdue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      size: 14, color: AppColors.overdue),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      badge!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.overdue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 11.5,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.textOnDarkMuted
                : AppColors.textOnLightMuted,
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            value,
            maxLines: 1,
            style: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
              color: AppColors.gold,
            ),
          ),
        ),
      ],
    );
  }
}
