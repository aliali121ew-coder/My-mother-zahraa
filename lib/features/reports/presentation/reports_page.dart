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
import 'widgets/reports_analytics_chart.dart';

enum _ReportCategory { all, financial, contributors, activity, security }

/// صفحة لوحة التقارير والتحليلات الملكية المكتملة (State-of-the-Art Futuristic Hub)
class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  final _searchController = TextEditingController();
  _ReportCategory _selectedCategory = _ReportCategory.all;

  @override
  void dispose() {
    _searchController.dispose();
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

              return GlassCard(
                radius: 20,
                padding: const EdgeInsets.all(16),
                borderColor: isDark
                    ? AppColors.gold.withValues(alpha: 0.35)
                    : AppColors.greenDeep.withValues(alpha: 0.25),
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          AppColors.gold.withValues(alpha: 0.18),
                          AppColors.greenDeep.withValues(alpha: 0.85),
                        ]
                      : [
                          const Color(0xFFF0F7F3),
                          Colors.white,
                        ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'إجمالي الخزنة والمقبوضات',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: 11.5,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 2),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(
                                  Fmt.money(stats.totalAmount),
                                  style: TextStyle(
                                    fontFamily: AppTheme.displayFamily,
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                    color: isDark
                                        ? AppColors.goldBright
                                        : AppColors.greenDeep,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _miniStatBadge(
                            title: 'المشتركون',
                            count: '$subscribersCount',
                            color: AppColors.greenDeep,
                            icon: Icons.groups_rounded,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _miniStatBadge(
                            title: 'المتبرعون',
                            count: '$donorsCount',
                            color: isDark ? AppColors.goldBright : Colors.teal.shade700,
                            icon: Icons.volunteer_activism_rounded,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _miniStatBadge(
                            title: 'الداعمون',
                            count: '$supportersCount',
                            color: Colors.lightBlue.shade700,
                            icon: Icons.shopping_basket_rounded,
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

          // ── 2️⃣ شريط البحث الزجاجي والتصفية السريعة ──
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'ابحث عن نوع التقرير أو السجل...',
              prefixIcon: const Icon(Icons.search_rounded, size: 21),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 19),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
            ),
          ),

          const SizedBox(height: 12),

          // شريط التبويبات الفئوية
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _categoryChip(
                    _ReportCategory.all, 'الكل', Icons.dashboard_rounded),
                const SizedBox(width: 8),
                _categoryChip(_ReportCategory.financial, 'المالية والخزنة',
                    Icons.account_balance_wallet_rounded),
                const SizedBox(width: 8),
                _categoryChip(_ReportCategory.contributors, 'المساهمون',
                    Icons.people_rounded),
                const SizedBox(width: 8),
                _categoryChip(_ReportCategory.activity, 'الرعاية والنشاط',
                    Icons.analytics_rounded),
                const SizedBox(width: 8),
                _categoryChip(_ReportCategory.security, 'الأمن والحظر',
                    Icons.security_rounded),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // ── 3️⃣ الرسم البياني التفاعلي للمقارنة الشهرية ──
          if (_selectedCategory == _ReportCategory.all ||
              _selectedCategory == _ReportCategory.financial) ...[
            const ReportsAnalyticsChart(),
            const SizedBox(height: 20),
          ],

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

  Widget _categoryChip(_ReportCategory category, String title, IconData icon) {
    final isSelected = _selectedCategory == category;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      onTap: () => setState(() => _selectedCategory = category),
      radius: 12,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      borderColor: isSelected
          ? (isDark ? AppColors.gold : AppColors.greenDeep)
          : null,
      gradient: isSelected
          ? LinearGradient(
              colors: isDark
                  ? [
                      AppColors.gold.withValues(alpha: 0.3),
                      AppColors.goldDark.withValues(alpha: 0.2),
                    ]
                  : [
                      AppColors.greenDeep.withValues(alpha: 0.15),
                      AppColors.lightGreenTint,
                    ],
            )
          : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: isSelected
                ? (isDark ? AppColors.goldBright : AppColors.greenDeep)
                : (isDark ? Colors.white60 : Colors.black54),
          ),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? (isDark ? AppColors.goldBright : AppColors.greenDeep)
                  : (isDark ? Colors.white70 : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStatBadge({
    required String title,
    required String count,
    required Color color,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 3),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Text(
                '$title: $count',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsGrid(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();

    final allReports = [
      // 1. الخزنة
      _ReportItemData(
        id: 'vault',
        title: 'الخزنة والمالية',
        description: 'رصيد الموكب الفعلي، الدفعات التراكمية، ومقبوضات الصندوق',
        icon: Icons.account_balance_wallet_rounded,
        color: AppColors.greenDeep,
        category: _ReportCategory.financial,
        route: '/reports/vault',
        badgeText: 'مالي',
      ),
      // 2. المشتريات
      _ReportItemData(
        id: 'purchases',
        title: 'المشتريات والنفقات',
        description: 'كشف مالي تفصيلي للمشتريات والفواتير الصادرة والنفقات',
        icon: Icons.shopping_cart_rounded,
        color: Colors.amber.shade800,
        category: _ReportCategory.financial,
        route: '/reports/purchases',
        badgeText: 'مصروفات',
      ),
      // 3. كل المساهمين (الفئات 3 في ملف واحد)
      _ReportItemData(
        id: 'all_consolidated',
        title: 'كل المساهمين (الفئات الـ 3 الموحدة)',
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
        title: 'تقرير المشتركين',
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
        title: 'تقرير المتبرعين',
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
        title: 'الداعمون والمساهمون (العيني)',
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
        title: 'سجل الزيارات والضيوف',
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
        title: 'سجل التفاعلات والمنشورات',
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
        title: 'طلبات التسجيل والحسابات',
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
        title: 'المستخدمون المحظورون',
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
        title: 'السجل الأرشيفي الإداري',
        description: 'أرشيف العمليات الإدارية وسجل التغييرات',
        icon: Icons.inventory_2_rounded,
        color: Colors.blueGrey,
        category: _ReportCategory.activity,
        route: '/reports/archive_log',
        badgeText: 'أرشيف',
      ),
    ];

    final filteredReports = allReports.where((r) {
      final matchesCategory = _selectedCategory == _ReportCategory.all ||
          r.category == _selectedCategory;
      final matchesQuery = query.isEmpty ||
          r.title.toLowerCase().contains(query) ||
          r.description.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();

    if (filteredReports.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Center(
          child: Text(
            'لا توجد تقارير مطابقة للبحث',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth > 600 ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: constraints.maxWidth > 600 ? 1.35 : 0.88,
          ),
          itemCount: filteredReports.length,
          itemBuilder: (context, idx) {
            final item = filteredReports[idx];
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
      padding: const EdgeInsets.all(14),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: item.color.withValues(alpha: 0.4),
                  ),
                ),
                child: Icon(item.icon, color: item.color, size: 22),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: item.color.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  item.badgeText,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: item.color,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTheme.displayFamily,
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: item.isFeatured
                      ? (isDark ? AppColors.goldBright : AppColors.goldDark)
                      : (isDark ? Colors.white : Colors.black87),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 10.5,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    'عرض الكشف',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: item.color,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(Icons.chevron_left_rounded,
                      size: 16, color: item.color),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
