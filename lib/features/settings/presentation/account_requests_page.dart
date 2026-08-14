import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/supabase_repository.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/auto_hiding_app_bar.dart';
import '../../../core/widgets/glass.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/profile_model.dart';

/// شاشة طلبات الحسابات الباقية بانتظار موافقة المدير
class AccountRequestsPage extends ConsumerStatefulWidget {
  const AccountRequestsPage({super.key});

  @override
  ConsumerState<AccountRequestsPage> createState() => _AccountRequestsPageState();
}

class _AccountRequestsPageState extends ConsumerState<AccountRequestsPage> {
  late Future<List<ProfileModel>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final repo = ref.read(authRepositoryProvider);
    setState(() {
      _future = repo.fetchPendingProfiles();
    });
  }

  Future<void> _updateStatus(ProfileModel profile, UserStatus status) async {
    final actionName = status == UserStatus.approved ? 'الموافقة على' : 'رفض';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$actionName الحساب'),
        content: Text('هل أنت تأكد من $actionName حساب ${profile.fullName}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: status == UserStatus.approved
                  ? AppColors.paid
                  : AppColors.overdue,
            ),
            child: Text(status == UserStatus.approved ? 'موافقة' : 'رفض'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.updateProfileStatus(profile.id, status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(status == UserStatus.approved
              ? 'تمت الموافقة على حساب ${profile.fullName}'
              : 'تم رفض حساب ${profile.fullName}'),
          backgroundColor:
              status == UserStatus.approved ? AppColors.paid : AppColors.overdue,
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
        title: const Text('طلبات الحسابات'),
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
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 44, color: AppColors.overdue),
                      const SizedBox(height: 12),
                      Text(arabicError(snapshot.error!)),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final items = snapshot.data ?? [];
            if (items.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(32),
                children: [
                  const SizedBox(height: 80),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.how_to_reg_outlined,
                        size: 48,
                        color: AppColors.gold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد طلبات تسجيل معلّقة',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'جميع الحسابات المسجّلة تمت مراجعتها وموافقة الإدارة عليها.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                return GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.gold.withValues(alpha: 0.2),
                            child: Text(
                              item.fullName.isNotEmpty
                                  ? item.fullName.substring(0, 1)
                                  : 'م',
                              style: const TextStyle(
                                color: AppColors.goldDark,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.fullName,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.phone?.isNotEmpty == true
                                      ? item.phone!
                                      : 'بانتظار موافقة الإدارة',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          if (item.createdAt != null)
                            Text(
                              Fmt.dateShort(item.createdAt!),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.hintColor,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(height: 1),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _updateStatus(item, UserStatus.rejected),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.overdue,
                                side: BorderSide(
                                  color: AppColors.overdue.withValues(alpha: 0.5),
                                ),
                              ),
                              icon: const Icon(Icons.close_rounded, size: 18),
                              label: const Text('رفض'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () =>
                                  _updateStatus(item, UserStatus.approved),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.paid,
                              ),
                              icon: const Icon(Icons.check_rounded, size: 18),
                              label: const Text('موافقة'),
                            ),
                          ),
                        ],
                      ),
                    ],
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
