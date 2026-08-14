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

/// شاشة حظر المستخدمين — للمدير لإدارة الحظر وإلغائه
class BannedUsersPage extends ConsumerStatefulWidget {
  const BannedUsersPage({super.key});

  @override
  ConsumerState<BannedUsersPage> createState() => _BannedUsersPageState();
}

class _BannedUsersPageState extends ConsumerState<BannedUsersPage> {
  late Future<List<ProfileModel>> _future;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final repo = ref.read(authRepositoryProvider);
    setState(() {
      _future = repo.fetchAllProfiles();
    });
  }

  Future<void> _toggleBan(ProfileModel profile) async {
    final isBanned = profile.status == UserStatus.banned;
    final newStatus = isBanned ? UserStatus.approved : UserStatus.banned;
    final actionName = isBanned ? 'إلغاء حظر' : 'حظر';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$actionName المستخدم'),
        content: Text('هل أنت تأكد من $actionName ${profile.fullName}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: isBanned ? AppColors.paid : AppColors.overdue,
            ),
            child: Text(actionName),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.updateProfileStatus(profile.id, newStatus);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isBanned
              ? 'تم إلغاء حظر ${profile.fullName}'
              : 'تم حظر ${profile.fullName}'),
          backgroundColor: isBanned ? AppColors.paid : AppColors.overdue,
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
        title: const Text('حظر المستخدمين'),
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'ابحث باسم المستخدم...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (q) => setState(() => _searchQuery = q.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _load(),
              child: FutureBuilder<List<ProfileModel>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(arabicError(snapshot.error!)),
                    );
                  }

                  var items = snapshot.data ?? [];
                  if (_searchQuery.isNotEmpty) {
                    items = items
                        .where((p) =>
                            p.fullName.toLowerCase().contains(_searchQuery) ||
                            (p.phone?.contains(_searchQuery) ?? false))
                        .toList();
                  }

                  if (items.isEmpty) {
                    return Center(
                      child: Text('لا يوجد مستخدمون مطابقون للبحث',
                          style: theme.textTheme.bodyMedium),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final isBanned = item.status == UserStatus.banned;

                      return GlassCard(
                        padding: EdgeInsets.zero,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isBanned
                                ? AppColors.overdue.withValues(alpha: 0.2)
                                : AppColors.gold.withValues(alpha: 0.2),
                            child: Icon(
                              isBanned
                                  ? Icons.block_rounded
                                  : Icons.person_rounded,
                              color: isBanned ? AppColors.overdue : AppColors.goldDark,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            item.fullName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              decoration: isBanned ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          subtitle: Text(
                            'الحالة: ${item.status.label} · الدور: ${item.role.label}',
                          ),
                          trailing: FilledButton.tonal(
                            onPressed: () => _toggleBan(item),
                            style: FilledButton.styleFrom(
                              backgroundColor: isBanned
                                  ? AppColors.paid.withValues(alpha: 0.15)
                                  : AppColors.overdue.withValues(alpha: 0.15),
                              foregroundColor: isBanned ? AppColors.paid : AppColors.overdue,
                            ),
                            child: Text(isBanned ? 'إلغاء الحظر' : 'حظر'),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
