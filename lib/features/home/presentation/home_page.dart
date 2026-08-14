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

  static const _topDonorsLimit = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final stats = ref.watch(statsProvider);
    final contributors = ref.watch(allContributorsProvider);
    final theme = Theme.of(context);

    final progress = ref.watch(scrollProgressProvider);
    final opacity = (1.0 - progress * 0.9).clamp(0.1, 1.0);
    final translateY = -progress * 60.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(statsProvider);
          ref.invalidate(allContributorsProvider);
          await ref.read(allContributorsProvider.future);
        },
        color: AppColors.gold,
        backgroundColor: theme.cardTheme.color,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: theme.scaffoldBackgroundColor.withValues(
                alpha: 0.86 * opacity,
              ),
              surfaceTintColor: Colors.transparent,
              titleSpacing: 16,
              title: Transform.translate(
                offset: Offset(0, translateY),
                child: Opacity(
                  opacity: opacity,
                  child: Row(
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
                            fontFamily: AppTheme.displayFamily,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                Transform.translate(
                  offset: Offset(0, translateY),
                  child: Opacity(
                    opacity: opacity,
                    child: IconButton(
                      tooltip: 'تبديل الوضع الليلي',
                      icon: Icon(
                        theme.brightness == Brightness.dark
                            ? Icons.light_mode_outlined
                            : Icons.dark_mode_outlined,
                      ),
                      onPressed: () =>
                          ref.read(themeModeProvider.notifier).toggle(),
                    ),
                  ),
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
                  child: IntrinsicHeight(
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
              ),
            ],

            // القسم الثاني: أعلى المتبرعين — قائمة عمودية
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 26, 16, 12),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7.5),
                      decoration: BoxDecoration(
                        gradient: AppColors.rank1Gradient,
                        borderRadius: BorderRadius.circular(11),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withValues(alpha: 0.45),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.military_tech_rounded,
                        size: 19,
                        color: AppColors.greenAbyss,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'أعلى المساهمين',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTheme.displayFamily,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: theme.brightness == Brightness.dark
                              ? AppColors.goldBright
                              : AppColors.goldDark,
                          shadows: [
                            Shadow(
                              color: AppColors.gold.withValues(
                                alpha: theme.brightness == Brightness.dark
                                    ? 0.45
                                    : 0.25,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (contributors.hasValue &&
                        contributors.value!.length > _topDonorsLimit)
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.3),
                            width: 0.8,
                          ),
                        ),
                        child: InkWell(
                          onTap: () => context.go('/contributors/all'),
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            child: Text(
                              'عرض الكل',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: theme.brightness == Brightness.dark
                                    ? AppColors.goldBright
                                    : AppColors.goldDark,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            contributors.when(
              loading: () => const SliverToBoxAdapter(child: _ListSkeleton()),
              error: (e, _) => SliverToBoxAdapter(
                child: _ErrorCard(
                  message: 'تعذّر تحميل قائمة المساهمين',
                  onRetry: () => ref.invalidate(allContributorsProvider),
                ),
              ),
              data: (list) {
                final top = list.take(_topDonorsLimit).toList();
                if (top.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: _EmptyCard(message: 'لا يوجد مساهمون بعد'),
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
                      showTypeBadge: true,
                    ),
                  ),
                );
              },
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 110)),
          ],
        ),
      ),
    );
  }

  /// تفصيل المبلغ الكلي عند الضغط على الكارت — تصميم UI/UX احترافي وبصري مبهر
  void _showBreakdown(BuildContext context, WidgetRef ref) {
    final s = ref.read(statsProvider).valueOrNull;
    if (s == null) return;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: isDark
          ? AppColors.greenDeepest
          : theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. ترويسة أنيقة بحلقة أيقونة وتوهج ومسمى فخم
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.gold, AppColors.goldDark],
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تفاصيل المبلغ الكلي',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.textOnDark
                                  : AppColors.textOnLight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'سجل الإيرادات المحدثة والموقف المالي الحي',
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.paid.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.paid.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 12,
                            color: AppColors.paid,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'معتمد',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.paid,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                // 2. كروت البنود المالية بلمسات زجاجية وأيقونات متميزة
                _BreakdownItemCard(
                  title: 'إجمالي الاشتراكات',
                  subtitle: 'مبالغ الاشتراكات السنوية والشهرية',
                  value: s.subscriptionsTotal,
                  icon: Icons.repeat_rounded,
                  iconColor: const Color(0xFF2E9E6B),
                  isDark: isDark,
                ),

                const SizedBox(height: 12),

                _BreakdownItemCard(
                  title: 'إجمالي التبرعات النقدية',
                  subtitle: 'التبرعات المباشرة والمساهمات النقدية',
                  value: s.donationsTotal,
                  icon: Icons.volunteer_activism_rounded,
                  iconColor: const Color(0xFFD79A3C),
                  isDark: isDark,
                ),

                const SizedBox(height: 18),

                // 3. كارت المجموع النهائي البطل (Hero Gold Border Card)
                GoldBorder(
                  radius: 20,
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [
                                AppColors.green.withValues(alpha: 0.85),
                                AppColors.greenDeep.withValues(alpha: 0.95),
                              ]
                            : [AppColors.greenDeep, AppColors.greenAbyss],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'المجموع الإجمالي',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(
                                  Fmt.money(s.totalAmount),
                                  style: const TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.goldBright,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.gold.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.stars_rounded,
                            color: AppColors.goldBright,
                            size: 26,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BreakdownItemCard extends StatelessWidget {
  const _BreakdownItemCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.isDark,
  });

  final String title;
  final String subtitle;
  final num value;
  final IconData icon;
  final Color iconColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.09)
              : Colors.black.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: isDark ? 0.20 : 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: iconColor.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textOnDark
                        : AppColors.textOnLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              Fmt.money(value),
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.goldBright : AppColors.greenDeep,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
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
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    color: AppColors.gold,
                    size: 20,
                  ),
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
              color: (isDark ? Colors.white : Colors.black).withValues(
                alpha: 0.045,
              ),
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
            Icon(
              Icons.inbox_outlined,
              size: 34,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
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
          const Icon(
            Icons.wifi_off_rounded,
            size: 30,
            color: AppColors.overdue,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    ),
  );
}

// =============================================================================
// معاينات الواجهة (Widget Previews)
// =============================================================================

/// وسم المعاينة الخاص بالفلاتر
class Preview {
  const Preview();
}

@Preview()
Widget homePageDarkPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.dark,
    home: const ProviderScope(child: HomePage()),
  );
}

@Preview()
Widget homePageLightPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    home: const ProviderScope(child: HomePage()),
  );
}

@Preview()
Widget totalAmountCardDarkPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.dark,
    home: const Scaffold(
      backgroundColor: AppColors.greenAbyss,
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: TotalAmountCard(total: 25000000),
        ),
      ),
    ),
  );
}

@Preview()
Widget totalAmountCardLightPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    home: const Scaffold(
      backgroundColor: AppColors.lightBg,
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: TotalAmountCard(total: 25000000),
        ),
      ),
    ),
  );
}
