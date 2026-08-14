import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/supabase_repository.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/auto_hiding_app_bar.dart';
import '../../../core/widgets/glass.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/profile_model.dart';

/// شاشة الصلاحيات والأدوار — للمدير العام لتغيير أدوار الحسابات
class UserRolesPage extends ConsumerStatefulWidget {
  const UserRolesPage({super.key});

  @override
  ConsumerState<UserRolesPage> createState() => _UserRolesPageState();
}

class _UserRolesPageState extends ConsumerState<UserRolesPage> {
  late Future<List<ProfileModel>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final repo = ref.read(authRepositoryProvider);
    setState(() {
      _future = repo.fetchApprovedProfiles();
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
      _load();
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AutoHidingAppBar(
        title: const Text('الصلاحيات والأدوار'),
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
      ),
      body: RefreshIndicator(
        onRefresh: () async => _load(),
        child: FutureBuilder<List<ProfileModel>>(
          future: _future,
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
                          UserRole.finance => Icons.account_balance_wallet_rounded,
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
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
                          const Icon(Icons.edit_rounded, size: 14, color: AppColors.goldDark),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
