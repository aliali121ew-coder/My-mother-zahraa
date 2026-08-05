import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass.dart';
import '../../../shared/models/enums.dart';
import 'widgets/add_contributor_dialog.dart';

/// صفحة المشتركين والمتبرعين — تصميم بـ 6 كروت شبكية متناسقة بحسب النموذج المطلوب.
class ContributorsPage extends ConsumerWidget {
  const ContributorsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('إدارة المساهمين'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 115),
        children: [
          // 1. Hero Banner Top Card (مثل بطاقة العبادات في النموذج المرفق)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  AppColors.green,
                  AppColors.greenDeep,
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: AppColors.greenAbyss.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.groups_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'إدارة المساهمين',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'جميع الأدوات وسجلات الاشتراكات والتبرعات في مكان واحد',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.88),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // 2. شبكة الكروت الـ 6 (2 أعمدة × 3 صفوف)
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.02,
            children: [
              _GridActionCard(
                title: 'إضافة مشترك',
                subtitle: 'تسجيل مشترك جديد',
                icon: Icons.person_add_rounded,
                iconColor: const Color(0xFF2E9E6B),
                onTap: () => AddContributorDialog.show(context, ContributorType.subscriber),
              ),
              _GridActionCard(
                title: 'إضافة متبرع',
                subtitle: 'تسجيل تبرع جديد',
                icon: Icons.volunteer_activism_rounded,
                iconColor: const Color(0xFFD79A3C),
                onTap: () => AddContributorDialog.show(context, ContributorType.donor),
              ),
              _GridActionCard(
                title: 'عرض المشتركين',
                subtitle: 'سجل المشتركين وحالة سدادهم',
                icon: Icons.people_alt_rounded,
                iconColor: const Color(0xFF14512F),
                onTap: () => context.go('/contributors/subscribers'),
              ),
              _GridActionCard(
                title: 'عرض المتبرعين',
                subtitle: 'سجل الداعمين والتبرعات',
                icon: Icons.handshake_rounded,
                iconColor: const Color(0xFF3D6D78),
                onTap: () => context.go('/contributors/donors'),
              ),
              _GridActionCard(
                title: 'عرض الكل',
                subtitle: 'كافة المساهمين والداعمين',
                icon: Icons.groups_rounded,
                iconColor: const Color(0xFF7B2CBF),
                onTap: () => context.go('/contributors/all'),
              ),
              _GridActionCard(
                title: 'الدعم',
                subtitle: 'تسجيل مساهمة داعم عينية',
                icon: Icons.support_agent_rounded,
                iconColor: const Color(0xFF0077B6),
                onTap: () => AddContributorDialog.show(context, ContributorType.inKind),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GridActionCard extends StatelessWidget {
  const _GridActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GlassCard(
      blur: true,
      onTap: onTap,
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: isDark ? 0.22 : 0.14),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: iconColor.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: isDark ? iconColor.withValues(alpha: 0.95) : iconColor,
              size: 26,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textOnDark : AppColors.textOnLight,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 11,
              color: isDark ? AppColors.textOnDarkMuted : AppColors.textOnLightMuted,
            ),
          ),
        ],
      ),
    );
  }
}
