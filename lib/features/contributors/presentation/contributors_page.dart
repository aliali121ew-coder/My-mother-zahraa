import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/glass.dart';

/// صفحة المشتركين: كارتان — المتبرعين والمشتركين — وكل واحد ينقل
/// لشاشة قائمة كاملة كما حُدّد.
class ContributorsPage extends ConsumerWidget {
  const ContributorsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('المشتركون والمتبرعون')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
        children: [
          Text('اختر القائمة التي تريد عرضها',
              style: theme.textTheme.bodyMedium),
          const SizedBox(height: 18),
          _BigCategoryCard(
            title: 'المتبرعون',
            subtitle: 'قائمة كاملة بالمتبرعين ومبالغهم',
            icon: Icons.volunteer_activism_rounded,
            count: stats.valueOrNull?.donorsCount,
            total: stats.valueOrNull?.donationsTotal,
            onTap: () => context.go('/contributors/donors'),
          ),
          const SizedBox(height: 14),
          _BigCategoryCard(
            title: 'المشتركون',
            subtitle: 'قائمة كاملة بالمشتركين وحالة سدادهم',
            icon: Icons.groups_2_rounded,
            count: stats.valueOrNull?.subscribersCount,
            total: stats.valueOrNull?.subscriptionsTotal,
            badge: (stats.valueOrNull?.overdueCount ?? 0) > 0
                ? '${Fmt.count(stats.valueOrNull!.overdueCount)} متأخر عن السداد'
                : null,
            onTap: () => context.go('/contributors/subscribers'),
          ),
        ],
      ),
    );
  }
}

class _BigCategoryCard extends StatelessWidget {
  const _BigCategoryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.count,
    this.total,
    this.badge,
  });

  final String title;
  final String subtitle;
  final IconData icon;
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
      padding: const EdgeInsets.all(20),
      gradient: isDark ? AppColors.countCardGradient : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.gold, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left_rounded, size: 28),
            ],
          ),
          const SizedBox(height: 18),
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
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
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
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            value,
            maxLines: 1,
            style: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.gold,
            ),
          ),
        ),
      ],
    );
  }
}
