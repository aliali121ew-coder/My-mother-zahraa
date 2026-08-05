import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'glass.dart';

/// هيكل التطبيق: خلفية موحّدة + شريط تنقّل سفلي بخمس شاشات.
///
/// يستخدم [StatefulNavigationShell] من go_router فيحفظ حالة كل تبويب
/// (موضع التمرير، النصوص المكتوبة) عند التبديل بينها.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const _items = <_NavItem>[
    _NavItem('الرئيسية', Icons.home_outlined, Icons.home_rounded),
    _NavItem('المشتركين', Icons.groups_2_outlined, Icons.groups_2_rounded),
    _NavItem('المنشورات', Icons.dynamic_feed_outlined, Icons.dynamic_feed_rounded),
    _NavItem('التقارير', Icons.assessment_outlined, Icons.assessment_rounded),
    _NavItem('الإعدادات', Icons.settings_outlined, Icons.settings_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: shell,
        bottomNavigationBar: _GlassNavBar(
          isDark: isDark,
          currentIndex: shell.currentIndex,
          items: _items,
          onTap: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.label, this.icon, this.activeIcon);
  final String label;
  final IconData icon;
  final IconData activeIcon;
}

class _GlassNavBar extends StatelessWidget {
  const _GlassNavBar({
    required this.isDark,
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  final bool isDark;
  final int currentIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: GlassCard(
          blur: true,
          radius: 30,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          borderColor: AppColors.gold.withValues(alpha: 0.25),
          gradient: isDark
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF103623).withValues(alpha: 0.85),
                    Color(0xFF071B11).withValues(alpha: 0.95),
                  ],
                )
              : null,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _NavButton(
                    item: items[i],
                    selected: i == currentIndex,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? AppColors.goldBright : AppColors.goldDark;
    final idleColor = isDark
        ? AppColors.textOnDarkMuted
        : AppColors.textOnLightMuted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                gradient: selected
                    ? LinearGradient(
                        colors: [
                          AppColors.gold.withValues(alpha: 0.28),
                          AppColors.gold.withValues(alpha: 0.12),
                        ],
                      )
                    : null,
                color: selected ? null : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: selected
                    ? Border.all(
                        color: AppColors.gold.withValues(alpha: 0.45),
                        width: 1.0,
                      )
                    : null,
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppColors.gold.withValues(alpha: 0.25),
                          blurRadius: 10,
                          spreadRadius: -1,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                selected ? item.activeIcon : item.icon,
                size: 21,
                color: selected ? activeColor : idleColor,
              ),
            ),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                item.label,
                maxLines: 1,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 10.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  color: selected ? activeColor : idleColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
