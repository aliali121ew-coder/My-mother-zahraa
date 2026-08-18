import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/supabase_repository.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/profile_model.dart';

/// شاشة إدارة الصلاحيات والأدوار المتكاملة للمدير العام (تبويب الصلاحيات + تبويب الأدوار)
class UserRolesPage extends ConsumerStatefulWidget {
  const UserRolesPage({super.key});

  @override
  ConsumerState<UserRolesPage> createState() => _UserRolesPageState();
}

class _UserRolesPageState extends ConsumerState<UserRolesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<ProfileModel>> _futureProfiles;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProfiles();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadProfiles() {
    final repo = ref.read(authRepositoryProvider);
    setState(() {
      _futureProfiles = repo.fetchApprovedProfiles();
    });
  }

  Future<void> _pickRole(ProfileModel profile) async {
    final selectedRole = await showModalBottomSheet<UserRole>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'تغيير دور: ${profile.fullName}',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const Divider(),
            for (final role in UserRole.values)
              ListTile(
                leading: Icon(
                  switch (role) {
                    UserRole.admin => Icons.shield_rounded,
                    UserRole.finance => Icons.account_balance_wallet_rounded,
                    UserRole.publisher => Icons.campaign_rounded,
                    UserRole.member => Icons.person_rounded,
                  },
                  color: role == profile.role ? AppColors.gold : null,
                ),
                title: Text(role.label),
                trailing: role == profile.role
                    ? const Icon(Icons.check_rounded, color: AppColors.gold)
                    : null,
                onTap: () => Navigator.pop(ctx, role),
              ),
          ],
        ),
      ),
    );

    if (selectedRole == null || selectedRole == profile.role || !mounted) return;

    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.updateProfileRole(profile.id, selectedRole);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تغيير دور ${profile.fullName} إلى ${selectedRole.label}'),
          backgroundColor: AppColors.paid,
        ),
      );
      _loadProfiles();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(arabicError(e)),
          backgroundColor: AppColors.overdue,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('لوحة الصلاحيات والأدوار'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/settings');
            }
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.goldDark, AppColors.gold],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(13),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: AppColors.greenAbyss,
              unselectedLabelColor:
                  isDark ? AppColors.textOnDarkMuted : AppColors.textOnLightMuted,
              labelStyle: const TextStyle(
                fontFamily: AppTheme.displayFamily,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: const TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(
                  icon: Icon(Icons.tune_rounded, size: 18),
                  text: 'صلاحيات التطبيق',
                ),
                Tab(
                  icon: Icon(Icons.manage_accounts_rounded, size: 18),
                  text: 'أدوار المستخدمين',
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPermissionsTab(context, isDark),
          _buildUserRolesTab(context, isDark),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // التبويب الأول: صلاحيات وميزات المنظومة
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPermissionsTab(BuildContext context, bool isDark) {
    final permissions = ref.watch(appPermissionsProvider);
    final notifier = ref.read(appPermissionsProvider.notifier);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        // بانر تعريفي توضيحي
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      AppColors.greenDeep.withValues(alpha: 0.6),
                      AppColors.greenAbyss.withValues(alpha: 0.8),
                    ]
                  : [
                      const Color(0xFFEAF5EE),
                      Colors.white,
                    ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.shield_outlined,
                    color: AppColors.gold, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'التحكم بصلاحيات المنظومة',
                      style: TextStyle(
                        fontFamily: AppTheme.displayFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'يمكن تفعيل أو إلغاء أي ميزة وسجل لجميع المستخدمين بضغطة زر واحدة',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 11,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 1. قسم عمليات الإضافة
        _buildSectionHeader('عمليات الإضافة والتسجيل', Icons.add_circle_outline_rounded),
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Column(
            children: [
              _buildSwitchTile(
                title: 'إضافة مشترك',
                subtitle: 'السماح بتسجيل مشتركين جدد في الموكب',
                icon: Icons.person_add_rounded,
                iconColor: const Color(0xFF2E9E6B),
                value: permissions.canAddSubscriber,
                onChanged: (val) => notifier.toggleKey('canAddSubscriber', val),
              ),
              const Divider(height: 1),
              _buildSwitchTile(
                title: 'إضافة متبرع',
                subtitle: 'السماح بتسجيل التبرعات النقدية للموكب',
                icon: Icons.volunteer_activism_rounded,
                iconColor: const Color(0xFFD79A3C),
                value: permissions.canAddDonor,
                onChanged: (val) => notifier.toggleKey('canAddDonor', val),
              ),
              const Divider(height: 1),
              _buildSwitchTile(
                title: 'إضافة داعم / مساهمة عينية',
                subtitle: 'السماح بتسجيل المساهمات والمواد العينية',
                icon: Icons.shopping_basket_rounded,
                iconColor: const Color(0xFF0077B6),
                value: permissions.canAddSupporter,
                onChanged: (val) => notifier.toggleKey('canAddSupporter', val),
              ),
              const Divider(height: 1),
              _buildSwitchTile(
                title: 'تسجيل شراء ومصروفات',
                subtitle: 'السماح بتسجيل فواتير ومشتريات من الخزنة (افتراضياً للمدير فقط)',
                icon: Icons.receipt_long_rounded,
                iconColor: const Color(0xFFE63946),
                value: permissions.canAddPurchase,
                onChanged: (val) => notifier.toggleKey('canAddPurchase', val),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // 2. قسم رؤية الأسماء في القوائم
        _buildSectionHeader('عرض أسماء المساهمين للمسجلين', Icons.visibility_rounded),
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Column(
            children: [
              _buildSwitchTile(
                title: 'عرض أسماء المشتركين',
                subtitle: 'إظهار الأسماء في قائمة وسجلات المشتركين',
                icon: Icons.groups_rounded,
                iconColor: const Color(0xFF14512F),
                value: permissions.canShowSubscriberNames,
                onChanged: (val) => notifier.toggleKey('canShowSubscriberNames', val),
              ),
              const Divider(height: 1),
              _buildSwitchTile(
                title: 'عرض أسماء المتبرعين',
                subtitle: 'إظهار الأسماء في قائمة التبرعات النقدية',
                icon: Icons.handshake_rounded,
                iconColor: const Color(0xFF3D6D78),
                value: permissions.canShowDonorNames,
                onChanged: (val) => notifier.toggleKey('canShowDonorNames', val),
              ),
              const Divider(height: 1),
              _buildSwitchTile(
                title: 'عرض أسماء الداعمين',
                subtitle: 'إظهار الأسماء في سجل المساهمات العينية',
                icon: Icons.card_giftcard_rounded,
                iconColor: const Color(0xFF7B2CBF),
                value: permissions.canShowSupporterNames,
                onChanged: (val) => notifier.toggleKey('canShowSupporterNames', val),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // 3. قسم كارتات وسجلات التقارير التفصيلية
        _buildSectionHeader('كارتات وسجلات التقارير (كل التبويبات)', Icons.analytics_rounded),
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Column(
            children: [
              _buildSwitchTile(
                title: 'سجل الخزنة',
                subtitle: 'كشف الرصيد الفعلي ومقبوضات الصندوق والمشتريات',
                icon: Icons.account_balance_wallet_rounded,
                iconColor: AppColors.greenDeep,
                value: permissions.canViewVaultReport,
                onChanged: (val) => notifier.toggleKey('canViewVaultReport', val),
              ),
              const Divider(height: 1),
              _buildSwitchTile(
                title: 'سجل المساهمين الموحد',
                subtitle: 'طباعة وتصدير ملف A4 موحد لجميع الفئات',
                icon: Icons.picture_as_pdf_rounded,
                iconColor: AppColors.greenDeep,
                value: permissions.canViewConsolidatedReport,
                onChanged: (val) =>
                    notifier.toggleKey('canViewConsolidatedReport', val),
              ),
              const Divider(height: 1),
              _buildSwitchTile(
                title: 'كشف المشتركين',
                subtitle: 'سجل المشتركين بالاشتراكات الشهرية والسنوية',
                icon: Icons.groups_rounded,
                iconColor: AppColors.greenDeep,
                value: permissions.canViewSubscribersReport,
                onChanged: (val) =>
                    notifier.toggleKey('canViewSubscribersReport', val),
              ),
              const Divider(height: 1),
              _buildSwitchTile(
                title: 'كشف المتبرعين',
                subtitle: 'كشف التبرعات النقدية الفردية والمجاميع',
                icon: Icons.volunteer_activism_rounded,
                iconColor: Colors.teal.shade700,
                value: permissions.canViewDonorsReport,
                onChanged: (val) => notifier.toggleKey('canViewDonorsReport', val),
              ),
              const Divider(height: 1),
              _buildSwitchTile(
                title: 'كشف الداعمين والمساهمين العينيين',
                subtitle: 'كشف المساهمات العينية المخصصة والمواد',
                icon: Icons.card_giftcard_rounded,
                iconColor: Colors.lightBlue.shade700,
                value: permissions.canViewSupportersReport,
                onChanged: (val) =>
                    notifier.toggleKey('canViewSupportersReport', val),
              ),
              const Divider(height: 1),
              _buildSwitchTile(
                title: 'سجل المسددين',
                subtitle: 'قائمة المشتركين المسددين لاشتراكاتهم',
                icon: Icons.check_circle_rounded,
                iconColor: AppColors.paid,
                value: permissions.canViewPaidReport,
                onChanged: (val) => notifier.toggleKey('canViewPaidReport', val),
              ),
              const Divider(height: 1),
              _buildSwitchTile(
                title: 'سجل المتأخرين',
                subtitle: 'قائمة المشتركين المتأخرين والدفعات المستحقة',
                icon: Icons.warning_amber_rounded,
                iconColor: AppColors.overdue,
                value: permissions.canViewOverdueReport,
                onChanged: (val) => notifier.toggleKey('canViewOverdueReport', val),
              ),
              const Divider(height: 1),
              _buildSwitchTile(
                title: 'سجل الزيارات',
                subtitle: 'كشف حركات دخول الزوار والنشاط',
                icon: Icons.door_front_door_rounded,
                iconColor: Colors.purple.shade400,
                value: permissions.canViewVisitsLog,
                onChanged: (val) => notifier.toggleKey('canViewVisitsLog', val),
              ),
              const Divider(height: 1),
              _buildSwitchTile(
                title: 'سجل التفاعلات والمنشورات',
                subtitle: 'تحليل التعليقات والإعجابات والوصول',
                icon: Icons.thumb_up_alt_rounded,
                iconColor: Colors.pinkAccent,
                value: permissions.canViewInteractionsLog,
                onChanged: (val) =>
                    notifier.toggleKey('canViewInteractionsLog', val),
              ),
              const Divider(height: 1),
              _buildSwitchTile(
                title: 'سجل طلبات الحسابات',
                subtitle: 'طلبات الانضمام الجديدة وإدارتها',
                icon: Icons.person_add_alt_1_rounded,
                iconColor: Colors.teal,
                value: permissions.canViewAccountRequests,
                onChanged: (val) =>
                    notifier.toggleKey('canViewAccountRequests', val),
              ),
              const Divider(height: 1),
              _buildSwitchTile(
                title: 'سجل المستخدمين المحظورين',
                subtitle: 'قائمة الحظر والأمان الإداري للحسابات المعطلة',
                icon: Icons.block_rounded,
                iconColor: Colors.redAccent,
                value: permissions.canViewBlockedUsers,
                onChanged: (val) =>
                    notifier.toggleKey('canViewBlockedUsers', val),
              ),
              const Divider(height: 1),
              _buildSwitchTile(
                title: 'السجل الأرشيفي الإداري',
                subtitle: 'أرشيف العمليات الإدارية وسجل التغييرات',
                icon: Icons.inventory_2_rounded,
                color: Colors.blueGrey,
                value: permissions.canViewArchiveLog,
                onChanged: (val) => notifier.toggleKey('canViewArchiveLog', val),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(right: 4, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.gold),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              fontFamily: AppTheme.displayFamily,
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: AppColors.gold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    Color? iconColor,
    Color? color,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final effectiveColor = iconColor ?? color ?? AppColors.gold;
    return SwitchListTile.adaptive(
      contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      secondary: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: effectiveColor.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: effectiveColor.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        child: Icon(icon, color: effectiveColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 10.5,
        ),
      ),
      value: value,
      activeThumbColor: AppColors.gold,
      activeTrackColor: AppColors.greenDeep,
      onChanged: onChanged,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // التبويب الثاني: أدوار المستخدمين
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildUserRolesTab(BuildContext context, bool isDark) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () async => _loadProfiles(),
      child: FutureBuilder<List<ProfileModel>>(
        future: _futureProfiles,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 40, color: AppColors.overdue),
                  const SizedBox(height: 10),
                  Text(arabicError(snapshot.error!)),
                ],
              ),
            );
          }

          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return Center(
              child: Text('لا توجد حسابات معتمدة حالياً',
                  style: theme.textTheme.bodyMedium),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              return GlassCard(
                padding: EdgeInsets.zero,
                child: ListTile(
                  onTap: () => _pickRole(item),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.gold.withValues(alpha: 0.2),
                    child: Icon(
                      switch (item.role) {
                        UserRole.admin => Icons.shield_rounded,
                        UserRole.finance =>
                          Icons.account_balance_wallet_rounded,
                        UserRole.publisher => Icons.campaign_rounded,
                        UserRole.member => Icons.person_rounded,
                      },
                      color: AppColors.goldDark,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    item.fullName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text('الدور الحالي: ${item.role.label}'),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.role.label,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.goldDark,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.edit_rounded,
                            size: 14, color: AppColors.goldDark),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
