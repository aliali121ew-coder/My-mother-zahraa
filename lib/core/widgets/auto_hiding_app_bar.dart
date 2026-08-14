import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/app_providers.dart';

/// شريط علوي (AppBar) ذكي يتوارى تدريجياً وبسلاسة أثناء تمرير الشاشة إلى الأسفل،
/// ويعود للظهور فوراً عند التمرير إلى الأعلى أو الوصول لقمة الصفحة.
class AutoHidingAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const AutoHidingAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.bottom,
    this.centerTitle = true,
    this.automaticallyImplyLeading = true,
    this.titleSpacing,
  });

  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? bottom;
  final bool centerTitle;
  final bool automaticallyImplyLeading;
  final double? titleSpacing;

  @override
  Size get preferredSize => Size.fromHeight(
      kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(scrollProgressProvider);
    final opacity = (1.0 - progress * 0.9).clamp(0.1, 1.0);
    final height = preferredSize.height;
    final translateY = -progress * (height + 10);

    final Widget? effectiveLeading = leading ??
        (automaticallyImplyLeading && context.canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => context.pop(),
              )
            : null);

    return Transform.translate(
      offset: Offset(0, translateY),
      child: Opacity(
        opacity: opacity,
        child: AppBar(
          title: title,
          actions: actions,
          leading: effectiveLeading,
          bottom: bottom,
          centerTitle: centerTitle,
          automaticallyImplyLeading: false,
          titleSpacing: titleSpacing,
        ),
      ),
    );
  }
}
