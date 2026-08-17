import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/supabase_repository.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/profile_model.dart';

/// شاشة حظر المستخدمين — للمدير لإدارة الحظر وإلغائه بتصميم ملكي ومحصن بالكامل.
class BannedUsersPage extends ConsumerStatefulWidget {
  const BannedUsersPage({super.key});

  @override
  ConsumerState<BannedUsersPage> createState() => _BannedUsersPageState();
}

class _BannedUsersPageState extends ConsumerState<BannedUsersPage> {
  late Future<List<ProfileModel>> _future;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _load() {
    final repo = ref.read(authRepositoryProvider);
    setState(() {
      _future = repo.fetchAllProfiles();
    });
  }

  String _getUserSubtitle(ProfileModel item) {
    final email = item.email;
    if (email != null && email.trim().isNotEmpty) return email.trim();
    final phone = item.phone;
    if (phone != null && phone.trim().isNotEmpty) return phone.trim();
    final dt = item.createdAt;
    if (dt != null) return Fmt.dateShort(dt);
    return 'عضو مسجل';
  }

  Future<void> _toggleBan(ProfileModel profile) async {
    final isBanned = profile.status == UserStatus.banned;
    final newStatus = isBanned ? UserStatus.approved : UserStatus.banned;
    final actionName = isBanned ? 'إلغاء حظر' : 'حظر';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          '$actionName المستخدم',
          style: const TextStyle(fontFamily: AppTheme.fontFamily, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'هل أنت متأكد من $actionName حساب «${profile.fullName}»؟\n${isBanned ? 'سيتمكن المستخدم من تسجيل الدخول واستخدام التطبيق مجدداً.' : 'سيتم منع المستخدم من الدخول للتطبيق فوراً.'}',
          style: const TextStyle(fontFamily: AppTheme.fontFamily, height: 1.4),
        ),
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
              ? 'تم إلغاء حظر «${profile.fullName}» بنجاح'
              : 'تم حظر حساب «${profile.fullName}»'),
          backgroundColor: isBanned ? AppColors.paid : AppColors.overdue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(arabicError(e)),
          backgroundColor: AppColors.overdue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('حظر المستخدمين'),
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
      ),
      body: Column(
        children: [
          // شريط البحث المطور
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white12 : const Color(0xFFD3E7DC),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black26 : const Color(0xFF0F3824).withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'ابحث باسم المستخدم أو البريد أو الهاتف...',
                  hintStyle: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 13,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.gold),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onChanged: (q) => setState(() => _searchQuery = q.trim().toLowerCase()),
              ),
            ),
          ),

          // قائمة المستخدمين
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
                    final err = snapshot.error ?? 'حدث خطأ أثناء تحميل البيانات';
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      children: [
                        const SizedBox(height: 60),
                        const Center(
                          child: Icon(Icons.error_outline_rounded, size: 44, color: AppColors.overdue),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          arabicError(err),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontFamily: AppTheme.fontFamily),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: FilledButton.icon(
                            onPressed: _load,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('إعادة المحاولة'),
                          ),
                        ),
                      ],
                    );
                  }

                  var items = snapshot.data ?? [];
                  if (_searchQuery.isNotEmpty) {
                    items = items.where((p) {
                      final nameMatch = p.fullName.toLowerCase().contains(_searchQuery);
                      final phoneMatch = p.phone?.toLowerCase().contains(_searchQuery) ?? false;
                      final emailMatch = p.email?.toLowerCase().contains(_searchQuery) ?? false;
                      return nameMatch || phoneMatch || emailMatch;
                    }).toList();
                  }

                  if (items.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(32),
                      children: [
                        const SizedBox(height: 60),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person_search_rounded,
                              size: 44,
                              color: AppColors.gold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _searchQuery.isEmpty ? 'لا يوجد مستخدمون مسجلون' : 'لا يوجد مستخدمون مطابقون للبحث',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final isBanned = item.status == UserStatus.banned;

                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [
                                    const Color(0xFF143826).withValues(alpha: 0.85),
                                    const Color(0xFF0C2418).withValues(alpha: 0.95),
                                  ]
                                : [
                                    Colors.white,
                                    const Color(0xFFEBF6F0),
                                  ],
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isBanned
                                ? AppColors.overdue.withValues(alpha: 0.4)
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.12)
                                    : const Color(0xFFD0E8DC)),
                            width: 1.3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? Colors.black26
                                  : const Color(0xFF0F3824).withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: isBanned
                                    ? AppColors.overdue.withValues(alpha: 0.18)
                                    : AppColors.gold.withValues(alpha: 0.18),
                                child: Icon(
                                  isBanned ? Icons.block_rounded : Icons.person_rounded,
                                  color: isBanned ? AppColors.overdue : AppColors.goldBright,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            item.fullName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontFamily: AppTheme.fontFamily,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: isBanned ? AppColors.overdue : (isDark ? Colors.white : const Color(0xFF113222)),
                                              decoration: isBanned ? TextDecoration.lineThrough : null,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isBanned
                                                ? AppColors.overdue.withValues(alpha: 0.15)
                                                : AppColors.paid.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            isBanned ? 'محظور' : item.role.label,
                                            style: TextStyle(
                                              fontFamily: AppTheme.fontFamily,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: isBanned ? AppColors.overdue : AppColors.paid,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _getUserSubtitle(item),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontFamily,
                                        fontSize: 12,
                                        color: isDark ? Colors.white54 : Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              FilledButton.tonal(
                                onPressed: () => _toggleBan(item),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  backgroundColor: isBanned
                                      ? AppColors.paid.withValues(alpha: 0.15)
                                      : AppColors.overdue.withValues(alpha: 0.15),
                                  foregroundColor: isBanned ? AppColors.paid : AppColors.overdue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  isBanned ? 'إلغاء الحظر' : 'حظر',
                                  style: const TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
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
