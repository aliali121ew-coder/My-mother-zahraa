import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/auto_hiding_app_bar.dart';
import '../../../shared/models/permissions.dart';

import '../../../core/services/biometric_service.dart';
import '../../../shared/widgets/privacy_policy_dialog.dart';
import 'change_password_sheet.dart';
import 'edit_profile_page.dart';

/// صفحة الإعدادات: الملف الشخصي، الثيم، إدارة المستخدمين، معلومات الموكب،
/// تسجيل الخروج ومسح الذاكرة المؤقتة.
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _biometricEnabled = BiometricService.instance.isBiometricEnabled;
  }

  Future<void> _toggleBiometrics(bool value) async {
    final success = await BiometricService.instance.setBiometricEnabled(value);
    if (mounted) {
      if (success) {
        setState(() => _biometricEnabled = value);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value
                ? 'تم تفعيل قفل التطبيق بالبصمة'
                : 'تم إيقاف قفل التطبيق بالبصمة'),
            backgroundColor: AppColors.paid,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('الجهاز لا يدعم البصمة أو رُفض الإجراء'),
            backgroundColor: AppColors.overdue,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final themeMode = ref.watch(themeModeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AutoHidingAppBar(
        title: const Text('الإعدادات'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          // ── الملف الشخصي ──
          GlassCard(
            blur: true,
            padding: const EdgeInsets.all(18),
            onTap: session.isGuest ? null : () => EditProfilePage.navigate(context),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.gold.withValues(alpha: 0.3),
                        AppColors.green.withValues(alpha: 0.5),
                      ],
                    ),
                  ),
                  child: ClipOval(
                    child: SizedBox(
                      width: 54,
                      height: 54,
                      child: session.profile?.avatarUrl != null && session.profile!.avatarUrl!.isNotEmpty
                          ? _buildSettingsAvatar(session.profile!.avatarUrl!, theme, session)
                          : _defaultAvatarIcon(theme, session),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.profile?.fullName ?? 'زائر',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        session.isGuest
                            ? 'تشاهد المنشورات فقط'
                            : '${session.role.label} · ${session.profile!.status.label}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (session.isGuest)
                  FilledButton(
                    onPressed: () => context.go('/auth'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Text('دخول'),
                  )
                else
                  const Icon(
                    Icons.edit_outlined,
                    color: AppColors.gold,
                    size: 20,
                  ),
              ],
            ),
          ),

          const SizedBox(height: 22),
          _SectionTitle('المظهر'),
          _SettingsGroup(
            children: [
              _Tile(
                icon: Icons.brightness_6_outlined,
                title: 'الوضع',
                subtitle: switch (themeMode) {
                  ThemeMode.dark => 'ليلي',
                  ThemeMode.light => 'نهاري',
                  ThemeMode.system => 'يتبع النظام',
                },
                onTap: () => _pickTheme(context, ref, themeMode),
              ),
            ],
          ),

          if (!session.isGuest) ...[
            const SizedBox(height: 22),
            _SectionTitle('الأمان'),
            _SettingsGroup(
              children: [
                _Tile(
                  icon: Icons.lock_outline_rounded,
                  title: 'تغيير كلمة المرور',
                  onTap: () => ChangePasswordSheet.show(context),
                ),
                _Tile(
                  icon: Icons.fingerprint_rounded,
                  title: 'قفل التطبيق بالبصمة',
                  subtitle: 'يُطلب عند كل فتح للتطبيق',
                  trailing: Switch(
                    value: _biometricEnabled,
                    onChanged: _toggleBiometrics,
                    activeThumbColor: AppColors.gold,
                  ),
                  onTap: () => _toggleBiometrics(!_biometricEnabled),
                ),
              ],
            ),
          ],

          if (session.role.canManageUsers) ...[
            const SizedBox(height: 22),
            _SectionTitle('الإدارة'),
            _SettingsGroup(
              children: [
                _Tile(
                  icon: Icons.how_to_reg_outlined,
                  title: 'طلبات الحسابات',
                  subtitle: 'الموافقة أو الرفض',
                  onTap: () => context.go('/settings/account_requests'),
                ),
                _Tile(
                  icon: Icons.admin_panel_settings_outlined,
                  title: 'الصلاحيات والأدوار',
                  subtitle: 'إدارة صلاحيات المنظومة ورتب المستخدمين',
                  onTap: () => context.go('/settings/roles'),
                ),
                _Tile(
                  icon: Icons.block_outlined,
                  title: 'حظر المستخدمين',
                  onTap: () => context.go('/settings/banned_users'),
                ),
                _Tile(
                  icon: Icons.collections_bookmark_outlined,
                  title: 'أقسام الستوريز',
                  onTap: () => context.go('/settings/story_categories'),
                ),
              ],
            ),
          ],

          const SizedBox(height: 22),
          _SectionTitle('البيانات والمزامنة'),
          _SettingsGroup(
            children: [
              _Tile(
                icon: Icons.cloud_done_rounded,
                title: 'حالة الاتصال',
                subtitle: 'متصل بقاعدة بيانات Supabase السحابية',
                trailing: const Icon(
                  Icons.check_circle_rounded,
                  size: 20,
                  color: AppColors.paid,
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),
          _SectionTitle('عن التطبيق'),
          _SettingsGroup(
            children: [
              _Tile(
                icon: Icons.shield_outlined,
                title: 'سياسة الخصوصية وحماية البيانات',
                subtitle: 'تشفير AES-256 وأمان السجلات',
                onTap: () => PrivacyPolicyDialog.show(context),
              ),
              _Tile(
                icon: Icons.info_outline_rounded,
                title: AppConfig.appName,
                subtitle: AppConfig.versionDisplay,
              ),
            ],
          ),

          if (!session.isGuest) ...[
            const SizedBox(height: 26),
            OutlinedButton.icon(
              onPressed: () {
                ref.read(sessionProvider.notifier).signOut();
                context.go('/home');
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.overdue,
                side: BorderSide(
                  color: AppColors.overdue.withValues(alpha: 0.45),
                ),
              ),
              icon: const Icon(Icons.logout_rounded, size: 19),
              label: const Text('تسجيل الخروج'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickTheme(
    BuildContext context,
    WidgetRef ref,
    ThemeMode current,
  ) async {
    final picked = await showModalBottomSheet<ThemeMode>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final m in ThemeMode.values)
              ListTile(
                leading: Icon(switch (m) {
                  ThemeMode.dark => Icons.dark_mode_outlined,
                  ThemeMode.light => Icons.light_mode_outlined,
                  ThemeMode.system => Icons.settings_suggest_outlined,
                }),
                title: Text(switch (m) {
                  ThemeMode.dark => 'ليلي',
                  ThemeMode.light => 'نهاري',
                  ThemeMode.system => 'يتبع النظام',
                }),
                trailing: m == current
                    ? const Icon(Icons.check_rounded, color: AppColors.gold)
                    : null,
                onTap: () => Navigator.pop(context, m),
              ),
          ],
        ),
      ),
    );
    if (picked != null) await ref.read(themeModeProvider.notifier).set(picked);
  }

}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 4, bottom: 10),
        child: Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.gold,
              ),
        ),
      );
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => GlassCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              children[i],
              if (i != children.length - 1)
                const Divider(height: 1, indent: 54),
            ],
          ],
        ),
      );
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => ListTile(
        onTap: onTap,
        leading: Icon(icon, size: 21, color: AppColors.gold),
        title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
        subtitle: subtitle == null
            ? null
            : Text(
                subtitle!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
        trailing: trailing ??
            (onTap == null
                ? null
                : const Icon(Icons.chevron_left_rounded, size: 22)),
      );
}

Widget _defaultAvatarIcon(ThemeData theme, AppSession session) {
  return Icon(
    session.isGuest ? Icons.person_outline_rounded : Icons.person_rounded,
    color: theme.brightness == Brightness.dark
        ? AppColors.goldBright
        : AppColors.goldDark,
    size: 26,
  );
}

Widget _buildSettingsAvatar(String url, ThemeData theme, AppSession session) {
  if (url.isEmpty) return _defaultAvatarIcon(theme, session);

  // 1. ملف محلي
  if (!url.startsWith('http://') && !url.startsWith('https://') && !url.startsWith('data:image')) {
    try {
      final file = File(url);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover, width: 54, height: 54);
      }
    } catch (_) {}
  }

  // 2. Data URL Base64
  if (url.startsWith('data:image')) {
    try {
      final commaIdx = url.indexOf(',');
      if (commaIdx != -1) {
        final base64Str = url.substring(commaIdx + 1);
        final bytes = base64Decode(base64Str);
        return Image.memory(bytes, fit: BoxFit.cover, width: 54, height: 54);
      }
    } catch (_) {}
  }

  // 3. Network
  return Image.network(
    url,
    fit: BoxFit.cover,
    width: 54,
    height: 54,
    errorBuilder: (_, _, _) => _defaultAvatarIcon(theme, session),
  );
}
