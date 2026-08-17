import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/auto_hiding_app_bar.dart';
import '../../../core/widgets/glass.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/permissions.dart';
import '../../purchases/data/purchases_provider.dart';
import 'widgets/reports_analytics_chart.dart';

enum _ReportCategory { financial, contributors, activity, security }

/// صفحة لوحة التقارير والتحليلات الملكية المكتملة (State-of-the-Art Futuristic Hub)
class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // التقارير بالأسماء للمدير والمسؤول المالي فقط
    if (!session.role.canViewReports) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const AutoHidingAppBar(title: Text('التقارير والتحليلات')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(26),
            child: GlassCard(
              blur: true,
              padding: const EdgeInsets.all(26),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline_rounded,
                      size: 38, color: AppColors.gold),
                  const SizedBox(height: 16),
                  Text('التقارير غير متاحة لدورك',
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 10),
                  Text(
                    'عرض وطباعة التقارير والتحليلات متاح للمدير العام والمسؤول المالي فقط.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final statsAsync = ref.watch(statsProvider);
    final allContribsAsync = ref.watch(allContributorsProvider);
    final purchasesAsync = ref.watch(purchasesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const AutoHidingAppBar(title: Text('لوحة التقارير والتحليلات')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
        children: [
          // ── 1️⃣ ترويسة ملكية زجاجية وملخص سريع ──
          statsAsync.when(
            loading: () => const SizedBox(height: 80),
            error: (err, stack) => const SizedBox.shrink(),
            data: (stats) {
              final subscribersCount =
                  allContribsAsync.valueOrNull
                          ?.where((c) => c.isSubscriber)
                          .length ??
                      0;
              final donorsCount = allContribsAsync.valueOrNull
                      ?.where((c) => c.type == ContributorType.donor)
                      .length ??
                  0;
              final supportersCount = allContribsAsync.valueOrNull
                      ?.where((c) => c.type == ContributorType.inKind)
                      .length ??
                  0;

              final purchasesExpenses = purchasesAsync.valueOrNull
                      ?.fold<num>(0, (sum, p) => sum + p.amount) ??
                  0;
              final totalExpenses =
                  purchasesExpenses > 0 ? purchasesExpenses : stats.expensesTotal;

              return GlassCard(
                radius: 22,
                padding: const EdgeInsets.all(14),
                borderColor: isDark
                    ? AppColors.gold.withValues(alpha: 0.4)
                    : AppColors.greenDeep.withValues(alpha: 0.3),
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          AppColors.gold.withValues(alpha: 0.12),
                          AppColors.greenDeep.withValues(alpha: 0.75),
                        ]
                      : [
                          const Color(0xFFF4F9F6),
                          Colors.white,
                        ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                child: Column(
                  children: [
                    // ── الخلايا المالية الرئيسية (المبلغ الكلي بعد خصم المصروفات والمصروف الكلي) ──
                    Row(
                      children: [
                        Expanded(
                          child: _gradientFinancialCell(
                            title: 'المبلغ الكلي',
                            amount: Fmt.money((stats.totalAmount - totalExpenses).clamp(0, double.infinity)),
                            icon: Icons.account_balance_wallet_rounded,
                            onTap: () => context.go('/reports/vault'),
                            gradient: LinearGradient(
                              colors: isDark
                                  ? const [
                                      Color(0xFF044E32),
                                      Color(0xFF0E7A4A),
                                      Color(0xFF10B981)
                                    ]
                                  : const [
                                      Color(0xFF065F46),
                                      Color(0xFF059669),
                                      Color(0xFF10B981)
                                    ],
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                            ),
                            shadowColor: const Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _gradientFinancialCell(
                            title: 'المصروف الكلي',
                            amount: Fmt.money(totalExpenses),
                            icon: Icons.receipt_long_rounded,
                            onTap: () => context.go('/reports/vault'),
                            gradient: LinearGradient(
                              colors: isDark
                                  ? const [
                                      Color(0xFF6B1124),
                                      Color(0xFF9E1C38),
                                      Color(0xFFF43F5E)
                                    ]
                                  : const [
                                      Color(0xFF9F1239),
                                      Color(0xFFE11D48),
                                      Color(0xFFF43F5E)
                                    ],
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                            ),
                            shadowColor: const Color(0xFFF43F5E),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // ── خلايا الفئات الـ 3 بتصميم مميز وتدريجي ──
                    Row(
                      children: [
                        Expanded(
                          child: _gradientCategoryBadge(
                            title: 'المشتركون',
                            count: '$subscribersCount',
                            icon: Icons.groups_rounded,
                            gradient: LinearGradient(
                              colors: isDark
                                  ? const [
                                      Color(0xFF034B75),
                                      Color(0xFF0284C7),
                                      Color(0xFF38BDF8)
                                    ]
                                  : const [
                                      Color(0xFF0369A1),
                                      Color(0xFF0284C7),
                                      Color(0xFF38BDF8)
                                    ],
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                            ),
                            shadowColor: const Color(0xFF0284C7),
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: _gradientCategoryBadge(
                            title: 'المتبرعون',
                            count: '$donorsCount',
                            icon: Icons.volunteer_activism_rounded,
                            gradient: LinearGradient(
                              colors: isDark
                                  ? const [
                                      Color(0xFF78350F),
                                      Color(0xFFD97706),
                                      Color(0xFFF59E0B)
                                    ]
                                  : const [
                                      Color(0xFFB45309),
                                      Color(0xFFD97706),
                                      Color(0xFFFBBF24)
                                    ],
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                            ),
                            shadowColor: const Color(0xFFD97706),
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: _gradientCategoryBadge(
                            title: 'الداعمون',
                            count: '$supportersCount',
                            icon: Icons.shopping_basket_rounded,
                            gradient: LinearGradient(
                              colors: isDark
                                  ? const [
                                      Color(0xFF4C1D95),
                                      Color(0xFF7C3AED),
                                      Color(0xFFA855F7)
                                    ]
                                  : const [
                                      Color(0xFF6D28D9),
                                      Color(0xFF7C3AED),
                                      Color(0xFFA855F7)
                                    ],
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                            ),
                            shadowColor: const Color(0xFF7C3AED),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          const SizedBox(height: 8),

          // ── 3️⃣ الرسم البياني التفاعلي للمقارنة الشهرية ──
          const ReportsAnalyticsChart(),
          const SizedBox(height: 20),

          // ── 4️⃣ شبكة الكروت الزجاجية للتقارير الشاملة ──
          Text(
            'سجلات وتقارير المنظومة المعتمدة',
            style: TextStyle(
              fontFamily: AppTheme.displayFamily,
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.goldBright : AppColors.greenDeep,
            ),
          ),
          const SizedBox(height: 12),

          _buildReportsGrid(context),
        ],
      ),
    );
  }


  Widget _gradientFinancialCell({
    required String title,
    required String amount,
    required IconData icon,
    required Gradient gradient,
    required Color shadowColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: shadowColor.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, size: 15, color: Colors.white),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                amount,
                style: const TextStyle(
                  fontFamily: AppTheme.displayFamily,
                  fontSize: 17.5,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gradientCategoryBadge({
    required String title,
    required String count,
    required IconData icon,
    required Gradient gradient,
    required Color shadowColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Text(
                '$title: $count',
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsGrid(BuildContext context) {
    final allReports = [
      // 1. الخزنة
      _ReportItemData(
        id: 'vault',
        title: 'سجل الخزنة',
        description: 'رصيد الموكب الفعلي، الدفعات التراكمية، ومقبوضات الصندوق',
        icon: Icons.account_balance_wallet_rounded,
        color: AppColors.greenDeep,
        category: _ReportCategory.financial,
        route: '/reports/vault',
        badgeText: 'مالي',
      ),
      // 2. كل المساهمين (الفئات 3 في ملف واحد)
      _ReportItemData(
        id: 'all_consolidated',
        title: 'سجل المساهمين الموحد',
        description: 'طباعة المشتركين والمتبرعين والداعمين العينيين في ملف A4 موحد',
        icon: Icons.picture_as_pdf_rounded,
        color: AppColors.greenDeep,
        category: _ReportCategory.contributors,
        route: '/reports/all_consolidated',
        badgeText: 'A4 موحد',
        isFeatured: true,
      ),
      // 4. المشتركون
      _ReportItemData(
        id: 'subscribers',
        title: 'سجل المشتركين',
        description: 'جدول أسماء المشتركين بالاشتراكات الشهرية والسنوية',
        icon: Icons.groups_rounded,
        color: AppColors.greenDeep,
        category: _ReportCategory.contributors,
        route: '/reports/subscribers',
        badgeText: 'اشتراكات',
      ),
      // 5. المتبرعون
      _ReportItemData(
        id: 'donors',
        title: 'سجل المتبرعين',
        description: 'كشف التبرعات النقدية الفردية والمبالغ التراكمية',
        icon: Icons.volunteer_activism_rounded,
        color: Colors.teal.shade700,
        category: _ReportCategory.contributors,
        route: '/reports/donors',
        badgeText: 'تبرعات',
      ),
      // 6. الداعمون والمساهمون العينيون
      _ReportItemData(
        id: 'supporters',
        title: 'سجل الداعمين',
        description: 'كشف المساهمات العينية المخصصة (مواد غذائية وإنشائية)',
        icon: Icons.card_giftcard_rounded,
        color: Colors.lightBlue.shade700,
        category: _ReportCategory.contributors,
        route: '/reports/supporters',
        badgeText: 'عيني',
      ),
      // 7. المسددون
      _ReportItemData(
        id: 'paid',
        title: 'سجل المسددين',
        description: 'قائمة المشتركين المسددين لااشتراكاتهم دون تأخير',
        icon: Icons.check_circle_rounded,
        color: AppColors.paid,
        category: _ReportCategory.contributors,
        route: '/reports/paid',
        badgeText: 'مسدد',
      ),
      // 8. المتأخرون
      _ReportItemData(
        id: 'overdue',
        title: 'سجل المتأخرين',
        description: 'قائمة المشتركين المتأخرين متبوعين بمهلة ودفعات المستحق',
        icon: Icons.warning_amber_rounded,
        color: AppColors.overdue,
        category: _ReportCategory.contributors,
        route: '/reports/overdue',
        badgeText: 'متأخر',
      ),
      // 9. سجل الزيارات
      _ReportItemData(
        id: 'visits_log',
        title: 'سجل الزيارات',
        description: 'كشف حركات دخول الزوار وتصفح المحتوى',
        icon: Icons.door_front_door_rounded,
        color: Colors.purple.shade400,
        category: _ReportCategory.activity,
        route: '/reports/visits_log',
        badgeText: 'زيارات',
      ),
      // 10. سجل التفاعلات والمنشورات
      _ReportItemData(
        id: 'interactions_log',
        title: 'سجل التفاعلات',
        description: 'تحليل المنشورات من حيث التعليقات والاعجابات والوصول',
        icon: Icons.thumb_up_alt_rounded,
        color: Colors.pinkAccent,
        category: _ReportCategory.activity,
        route: '/reports/interactions_log',
        badgeText: 'تفاعلات',
      ),
      // 11. طلبات الحسابات
      _ReportItemData(
        id: 'account_requests',
        title: 'سجل الطلبات',
        description: 'عدد الحسابات الجديدة المعلقة وقيد التفعيل والإدارة',
        icon: Icons.person_add_alt_1_rounded,
        color: Colors.teal,
        category: _ReportCategory.security,
        route: '/reports/account_requests',
        badgeText: 'طلبات',
      ),
      // 12. المستخدمون المحظورون
      _ReportItemData(
        id: 'blocked_users',
        title: 'سجل المحظورين',
        description: 'قائمة الحظر والأمن الإداري للحسابات المعطلة',
        icon: Icons.block_rounded,
        color: Colors.redAccent,
        category: _ReportCategory.security,
        route: '/reports/blocked_users',
        badgeText: 'حظر',
      ),
      // 13. السجل الأرشيفي الإداري
      _ReportItemData(
        id: 'archive_log',
        title: 'سجل الأرشيف',
        description: 'أرشيف العمليات الإدارية وسجل التغييرات',
        icon: Icons.inventory_2_rounded,
        color: Colors.blueGrey,
        category: _ReportCategory.activity,
        route: '/reports/archive_log',
        badgeText: 'أرشيف',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 750;
        final crossCount = isWide
            ? (constraints.maxWidth > 1050 ? 4 : 3)
            : 2;
        final ratio = isWide
            ? 1.25
            : (constraints.maxWidth < 360 ? 0.78 : 0.82);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: ratio,
          ),
          itemCount: allReports.length,
          itemBuilder: (context, idx) {
            final item = allReports[idx];
            return _ReportGridCard(item: item);
          },
        );
      },
    );
  }
}

class _ReportItemData {
  const _ReportItemData({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.category,
    required this.route,
    required this.badgeText,
    this.isFeatured = false,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final _ReportCategory category;
  final String route;
  final String badgeText;
  final bool isFeatured;
}

class _ReportGridCard extends StatelessWidget {
  const _ReportGridCard({required this.item});

  final _ReportItemData item;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      blur: true,
      onTap: () => context.go(item.route),
      radius: AppTheme.radiusLarge,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      borderColor: item.isFeatured
          ? AppColors.gold.withValues(alpha: 0.8)
          : item.color.withValues(alpha: 0.35),
      gradient: item.isFeatured
          ? LinearGradient(
              colors: [
                item.color.withValues(alpha: isDark ? 0.25 : 0.15),
                AppColors.gold.withValues(alpha: isDark ? 0.15 : 0.08),
              ],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            )
          : (isDark ? AppColors.countCardGradient : null),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ── الترويسة الأيقونة والشارة بمرونة كاملة ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: item.color.withValues(alpha: 0.4),
                  ),
                ),
                child: Icon(item.icon, color: item.color, size: 19),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: item.color.withValues(alpha: 0.3),
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      item.badgeText,
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: item.color,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // ── العنوان والوصف وزر التنقل ──
          Text(
            item.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppTheme.displayFamily,
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: item.isFeatured
                  ? (isDark ? AppColors.goldBright : AppColors.goldDark)
                  : (isDark ? Colors.white : Colors.black87),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 10,
              height: 1.2,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'عرض الكشف',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: item.color,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Icon(Icons.chevron_left_rounded, size: 15, color: item.color),
            ],
          ),
        ],
      ),
    );
  }
}
