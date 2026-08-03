import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/storage/hive_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/glass.dart';
import '../../../shared/models/permissions.dart';

/// صفحة الإعدادات: الملف الشخصي، الثيم، إدارة المستخدمين، معلومات الموكب،
/// تسجيل الخروج ومسح الذاكرة المؤقتة.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final themeMode = ref.watch(themeModeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          // ── الملف الشخصي ──
          GlassCard(
            blur: true,
            padding: const EdgeInsets.all(18),
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
                  child: Icon(
                    session.isGuest
                        ? Icons.person_outline_rounded
                        : Icons.person_rounded,
                    color: AppColors.goldBright,
                    size: 26,
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
            _SectionTitle('الحساب'),
            _SettingsGroup(
              children: [
                _Tile(
                  icon: Icons.lock_outline_rounded,
                  title: 'تغيير كلمة المرور',
                  onTap: () => _soon(context),
                ),
                _Tile(
                  icon: Icons.fingerprint_rounded,
                  title: 'قفل التطبيق بالبصمة',
                  subtitle: 'يُطلب عند كل فتح للتطبيق',
                  onTap: () => _soon(context),
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
                  onTap: () => _soon(context),
                ),
                _Tile(
                  icon: Icons.admin_panel_settings_outlined,
                  title: 'الصلاحيات والأدوار',
                  onTap: () => _soon(context),
                ),
                _Tile(
                  icon: Icons.block_outlined,
                  title: 'حظر المستخدمين',
                  onTap: () => _soon(context),
                ),
                _Tile(
                  icon: Icons.collections_bookmark_outlined,
                  title: 'أقسام الستوريز',
                  onTap: () => _soon(context),
                ),
              ],
            ),
          ],

          const SizedBox(height: 22),
          _SectionTitle('البيانات'),
          _SettingsGroup(
            children: [
              _Tile(
                icon: Icons.cloud_off_outlined,
                title: 'حالة الاتصال',
                subtitle: AppConfig.isConfigured
                    ? 'متصل بقاعدة البيانات'
                    : 'وضع تجريبي — قاعدة البيانات غير مهيّأة',
                trailing: Icon(
                  AppConfig.isConfigured
                      ? Icons.check_circle_rounded
                      : Icons.info_rounded,
                  size: 19,
                  color: AppConfig.isConfigured
                      ? AppColors.paid
                      : AppColors.pending,
                ),
              ),
              _Tile(
                icon: Icons.delete_sweep_outlined,
                title: 'مسح الذاكرة المؤقتة',
                subtitle:
                    '${Fmt.count(HiveService.instance.cachedItemsCount)} عنصر محفوظ',
                onTap: () => _clearCache(context),
              ),
            ],
          ),

          const SizedBox(height: 22),
          _SectionTitle('عن التطبيق'),
          _SettingsGroup(
            children: [
              _Tile(
                icon: Icons.info_outline_rounded,
                title: 'موكب أمنا الزهراء',
                subtitle: 'الإصدار ١.٠.٠',
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

  Future<void> _clearCache(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('مسح الذاكرة المؤقتة'),
        content: const Text(
          'سيُحذف كل ما هو محفوظ على الهاتف ويُعاد تحميله من قاعدة البيانات '
          'عند الاتصال. لن تفقد أي بيانات على السيرفر.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('مسح'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await HiveService.instance.clearCache();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم مسح الذاكرة المؤقتة')),
    );
  }

  void _soon(BuildContext context) => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('هذه الشاشة قيد البناء')),
      );
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
