import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/supabase_repository.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/profile_model.dart';
import '../data/admin_repository.dart';

/// لوحة المدير لإدارة الحسابات — الموافقة على الطلبات، تغيير الأدوار، والحظر.
///
/// القائمة تُجلب من جدول `profiles` الذي تحميه سياسة `profiles_admin_all`،
/// فغير المدير يحصل على 42501 ويُعرض له خطأ صلاحية واضح.
// حوار تأكيد عام — رفض/حظر الحسابات، خارج أي حالة واجهة.
/// حوار تأكيد قبل الإجراءات المصيرية (رفض/حظر) — اللمسات الخاطئة
/// على أزرار الحظر لا تمرّ مباشرة للخادم.
Future<void> confirmWith(
  BuildContext context, {
  required String title,
  required String message,
  required Future<void> Function() action,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message, style: Theme.of(context).textTheme.bodyMedium),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('تأكيد'),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  try {
    await action();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم تحديث الحساب بنجاح'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  } catch (e) {
    _onActionError(context, e);
  }
}

@override

class AdminUsersPage extends ConsumerStatefulWidget {
  const AdminUsersPage({super.key});

  @override
  ConsumerState<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends ConsumerState<AdminUsersPage> {
  final _search = TextEditingController();
  UserStatus? _statusFilter;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _onActionError(BuildContext context, Object e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e is PostgrestException && e.code == '42501'
            ? 'غير مصرّح — هذه اللوحة للمدير العام فقط'
            : arabicError(e)),
        backgroundColor: AppColors.overdue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accountsAsync = ref.watch(adminUsersProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'إدارة الحسابات',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'تحديث القائمة',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(adminUsersProvider.notifier).refresh(),
          ),
        ],
      ),
      body: accountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.admin_panel_settings_outlined,
                    size: 44, color: AppColors.overdue),
                const SizedBox(height: 12),
                Text(
                  e is PostgrestException && e.code == '42501'
                      ? 'هذه اللوحة للمدير العام فقط\nتأكد أن حسابك معتمد وبصلاحية المدير'
                      : 'تعذّر تحميل الحسابات\n$arabicError(e)',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        data: (accounts) {
          final q = _search.text.trim().toLowerCase();
          final filtered = accounts.where((p) {
            if (_statusFilter != null && p.status != _statusFilter) return false;
            if (q.isEmpty) return true;
            return p.fullName.toLowerCase().contains(q) ||
                (p.phone?.toLowerCase().contains(q) ?? false);
          }).toList();

          final pending =
              accounts.where((p) => p.status == UserStatus.pending).length;

          return Column(
            children: [
              // شريط البحث وفلاتر الحالة
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _search,
                        onChanged: (_) => setState(() {}),
                        textAlign: TextAlign.right,
                        decoration: InputDecoration(
                          hintText: 'بحث بالاسم أو الهاتف...',
                          prefixIcon:
                              const Icon(Icons.search_rounded, size: 20),
                          filled: true,
                          fillColor:
                              isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'الكل',
                      count: accounts.length,
                      selected: _statusFilter == null,
                      onTap: () => setState(() => _statusFilter = null),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'بانتظار الموافقة',
                      count: pending,
                      selected: _statusFilter == UserStatus.pending,
                      color: AppColors.pending,
                      onTap: () =>
                          setState(() => _statusFilter = UserStatus.pending),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'المعتمدون',
                      count: accounts
                          .where((p) => p.status == UserStatus.approved)
                          .length,
                      selected: _statusFilter == UserStatus.approved,
                      color: AppColors.paid,
                      onTap: () =>
                          setState(() => _statusFilter = UserStatus.approved),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'المحظورون',
                      count: accounts
                          .where((p) => p.status == UserStatus.banned)
                          .length,
                      selected: _statusFilter == UserStatus.banned,
                      color: AppColors.overdue,
                      onTap: () =>
                          setState(() => _statusFilter = UserStatus.banned),
                    ),
                  ],
                ),
              ),

              if (pending > 0) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.pending.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.pending.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.hourglass_top_rounded,
                            color: AppColors.pending, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          '$pending طلب${pending == 1 ? '' : 'ات'} حساب بانتظار موافقتك',
                          style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.group_off_outlined,
                                size: 48, color: AppColors.gold),
                            const SizedBox(height: 10),
                            Text(
                              q.isEmpty ? 'لا توجد حسابات' : 'لا نتائج مطابقة',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) =>
                            _AccountTile(profile: filtered[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AccountTile extends ConsumerWidget {
  const _AccountTile({required this.profile});

  final ProfileModel profile;

  Color get _statusColor => switch (profile.status) {
        UserStatus.pending => AppColors.pending,
        UserStatus.approved => AppColors.paid,
        UserStatus.banned => AppColors.overdue,
        UserStatus.rejected => AppColors.textOnDarkMuted,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final notifier = ref.read(adminUsersProvider.notifier);

    return GlassCard(
      blur: false,
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.gold.withValues(alpha: 0.3),
                      AppColors.green.withValues(alpha: 0.5),
                    ],
                  ),
                ),
                child: Icon(
                  profile.isBanned
                      ? Icons.person_off_rounded
                      : (profile.isPending
                          ? Icons.hourglass_empty_rounded
                          : Icons.person_rounded),
                  color: isDark ? AppColors.goldBright : AppColors.goldDark,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold),
                    ),
                    if (profile.phone != null)
                      Text(
                        profile.phone!,
                        maxLines: 1,
                        style: theme.textTheme.bodySmall,
                      ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        _MiniChip(
                          label: profile.role.label,
                          color: AppColors.gold,
                        ),
                        const SizedBox(width: 6),
                        _MiniChip(
                          label: profile.status.label,
                          color: _statusColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // الموافقة على الطلبات المعلقة
              if (profile.isPending)
                _ActionButton(
                  label: 'موافقة',
                  icon: Icons.check_circle_rounded,
                  color: AppColors.paid,
                  onTap: () => notifier.approve(profile.id),
                ),
              if (profile.isPending) const SizedBox(width: 8),
              if (profile.isPending)
                _ActionButton(
                  label: 'رفض',
                  icon: Icons.cancel_rounded,
                  color: AppColors.overdue,
                  onTap: () => confirmWith(
                    context,
                    title: 'رفض الحساب',
                    message: 'رفض طلب حساب «${profile.fullName}»؟\nسيُمنع من الدخول.',
                    action: () => notifier.reject(profile.id),
                  ),
                ),
              if (profile.isPending) const Spacer(),

              // تغيير الدور — لكل الحسابات المعتمدة والمحظورة
              if (!profile.isPending)
                Expanded(
                  child: _ActionButton(
                    label: 'الدور: ${profile.role.label}',
                    icon: Icons.badge_outlined,
                    color: AppColors.gold,
                    onTap: () {
                      // فتح اختيار الدور يتم من الأعلى
                      _openRolePicker(context, ref);
                    },
                  ),
                ),
              if (!profile.isPending) const SizedBox(width: 8),
              if (!profile.isPending)
                _ActionButton(
                  label: profile.isBanned ? 'رفع الحظر' : 'حظر',
                  icon: profile.isBanned
                      ? Icons.lock_open_rounded
                      : Icons.block_rounded,
                  color: profile.isBanned ? AppColors.paid : AppColors.overdue,
                  onTap: () => profile.isBanned
                      ? notifier.unban(profile.id)
                      : confirmWith(
                          context,
                          title: 'حظر الحساب',
                          message: 'حظر «${profile.fullName}»؟\nسيُمنع نهائيًا من استخدام التطبيق.',
                          action: () => notifier.ban(profile.id),
                        ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _openRolePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<UserRole>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
              child: Text(
                'دور جديد لـ: ${profile.fullName}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final role in UserRole.values)
              ListTile(
                leading: const Icon(Icons.badge_outlined, color: AppColors.gold),
                title: Text(role.label),
                trailing: role == profile.role
                    ? const Icon(Icons.check_rounded, color: AppColors.gold)
                    : null,
                onTap: () => Navigator.pop(context, role),
              ),
          ],
        ),
      ),
    ).then((picked) async {
      if (picked == null || picked == profile.role || !context.mounted) return;
      final notifier = ref.read(adminUsersProvider.notifier);
      try {
        await notifier.changeRole(profile.id, picked);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تغيير الدور إلى ${picked.label}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(arabicError(e)),
            backgroundColor: AppColors.overdue,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    this.color,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ChoiceChip(
        label: Text('$label ($count)'),
        selected: selected,
        onSelected: (_) => onTap(),
        labelStyle: const TextStyle(fontFamily: AppTheme.fontFamily, fontSize: 11),
        selectedColor: (color ?? AppColors.green).withValues(alpha: 0.85),
        backgroundColor: Colors.black.withValues(alpha: 0.04),
        side: BorderSide(
          color: selected
              ? Colors.transparent
              : Colors.black.withValues(alpha: 0.1),
        ),
        labelPadding: const EdgeInsets.symmetric(horizontal: 6),
        visualDensity: VisualDensity.compact,
      );
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15, color: color),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
