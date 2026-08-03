import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/glass.dart';
import '../../../shared/models/permissions.dart';
import '../../../shared/widgets/contributor_tile.dart';
import '../../../shared/widgets/mawkib_logo.dart';
import '../../../shared/widgets/stat_cards.dart';

/// الشاشة الرئيسية.
///
/// التخطيط كما حُدّد: كارت المبلغ الكلي عريض في الأعلى (1×1)، تحته صف 2×1
/// لكارتي عدد المتبرعين وعدد المشتركين، ثم قسم ثانٍ بقائمة **عمودية**
/// لأعلى ١٠ متبرعين مع زر «عرض الكل».
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  static const _topDonorsLimit = 10;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final stats = ref.watch(statsProvider);
    final donors = ref.watch(donorsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(statsProvider);
          ref.invalidate(donorsProvider);
          await ref.read(donorsProvider.future);
        },
        color: AppColors.gold,
        backgroundColor: theme.cardTheme.color,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: theme.scaffoldBackgroundColor.withValues(alpha: 0.86),
              surfaceTintColor: Colors.transparent,
              titleSpacing: 16,
              title: Row(
                children: [
                  const MawkibLogo(
                    height: 30,
                    small: true,
                    radius: 9,
                    padding: EdgeInsets.all(3),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'موكب أمنا الزهراء',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: 'تبديل الوضع الليلي',
                  icon: Icon(
                    theme.brightness == Brightness.dark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                  ),
                  onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
                ),
              ],
            ),

            // الزائر أو غير المعتمد: لا يرى الأرقام
            if (!session.canSeeStats)
              const SliverToBoxAdapter(child: _LockedStatsCard())
            else ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: TotalAmountCard(
                    total: stats.valueOrNull?.totalAmount ?? 0,
                    loading: stats.isLoading,
                    onTap: stats.hasValue
                        ? () => _showBreakdown(context, ref)
                        : null,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: CountCard(
                          label: 'عدد المتبرعين',
                          icon: Icons.volunteer_activism_outlined,
                          count: stats.valueOrNull?.donorsCount ?? 0,
                          loading: stats.isLoading,
                          onTap: () => context.go('/contributors'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CountCard(
                          label: 'عدد المشتركين',
                          icon: Icons.groups_2_outlined,
                          count: stats.valueOrNull?.subscribersCount ?? 0,
                          loading: stats.isLoading,
                          badge: (stats.valueOrNull?.overdueCount ?? 0) > 0
                              ? '${Fmt.count(stats.valueOrNull!.overdueCount)} متأخر'
                              : null,
                          onTap: () => context.go('/contributors'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // القسم الثاني: أعلى المتبرعين — قائمة عمودية
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 26, 16, 10),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events_outlined,
                        size: 19, color: AppColors.gold),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('أعلى المتبرعين',
                          style: theme.textTheme.titleLarge),
                    ),
                    if (donors.hasValue && donors.value!.length > _topDonorsLimit)
                      TextButton(
                        onPressed: () => context.go('/contributors/donors'),
                        child: const Text('عرض الكل'),
                      ),
                  ],
                ),
              ),
            ),

            donors.when(
              loading: () => const SliverToBoxAdapter(child: _ListSkeleton()),
              error: (e, _) => SliverToBoxAdapter(
                child: _ErrorCard(
                  message: 'تعذّر تحميل قائمة المتبرعين',
                  onRetry: () => ref.invalidate(donorsProvider),
                ),
              ),
              data: (list) {
                final top = list.take(_topDonorsLimit).toList();
                if (top.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: _EmptyCard(message: 'لا يوجد متبرعون بعد'),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList.separated(
                    itemCount: top.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => ContributorTile(
                      contributor: top[i],
                      rank: i + 1,
                      hideName: !session.role.canSeeNames,
                    ),
                  ),
                );
              },
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 28)),
          ],
        ),
      ),
    );
  }

  /// تفصيل المبلغ الكلي عند الضغط على الكارت — كما طُلب
  void _showBreakdown(BuildContext context, WidgetRef ref) {
    final s = ref.read(statsProvider).valueOrNull;
    if (s == null) return;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('تفصيل المبلغ الكلي',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 18),
              _BreakdownRow(label: 'الاشتراكات', value: s.subscriptionsTotal),
              const SizedBox(height: 12),
              _BreakdownRow(
                  label: 'التبرعات النقدية', value: s.donationsTotal),
              const Divider(height: 28),
              _BreakdownRow(
                  label: 'المجموع', value: s.totalAmount, emphasize: true),
              if (s.inKindCount > 0) ...[
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.inventory_2_outlined,
                          size: 18, color: AppColors.teal),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'يوجد ${Fmt.count(s.inKindCount)} تبرع عيني غير محسوب '
                          'في المبلغ الكلي',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final num value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: emphasize
                ? theme.textTheme.titleMedium
                : theme.textTheme.bodyLarge,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerEnd,
            child: Text(
              Fmt.money(value),
              maxLines: 1,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: emphasize ? 19 : 16,
                fontWeight: emphasize ? FontWeight.w700 : FontWeight.w600,
                color: emphasize ? AppColors.gold : theme.textTheme.bodyLarge?.color,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// يُعرض للزائر بدل الأرقام: الإحصائيات تتطلب حساباً معتمداً
class _LockedStatsCard extends ConsumerWidget {
  const _LockedStatsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: GlassCard(
        blur: true,
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.lock_outline_rounded,
                      color: AppColors.gold, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    session.isPending
                        ? 'طلبك بانتظار موافقة المدير'
                        : 'الإحصائيات للأعضاء المعتمدين',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              session.isPending
                  ? 'سيظهر المبلغ الكلي وأعداد المشتركين والمتبرعين مباشرة بعد '
                      'موافقة المدير على حسابك.'
                  : 'يمكنك تصفّح المنشورات بحرية. لرؤية المبلغ الكلي وأعداد '
                      'المشتركين والمتبرعين، أنشئ حساباً وانتظر موافقة المدير.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (!session.isPending) ...[
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () => context.go('/auth'),
                child: const Text('تسجيل الدخول أو إنشاء حساب'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: List.generate(
          4,
          (_) => Container(
            height: 72,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black)
                  .withValues(alpha: 0.045),
              borderRadius: BorderRadius.circular(AppTheme.radius),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 20),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.inbox_outlined,
                    size: 34,
                    color: Theme.of(context).textTheme.bodySmall?.color),
                const SizedBox(height: 12),
                Text(message, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ),
      );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GlassCard(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              const Icon(Icons.wifi_off_rounded,
                  size: 30, color: AppColors.overdue),
              const SizedBox(height: 12),
              Text(message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 14),
              OutlinedButton(
                  onPressed: onRetry, child: const Text('إعادة المحاولة')),
            ],
          ),
        ),
      );
}
