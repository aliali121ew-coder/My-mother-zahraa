import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// خلفية التطبيق: أسود مائل للأخضر مع توهّج أخضر — كما طُلب.
///
/// التوهّج مرسوم بتدرّجين شعاعيين (RadialGradient) وليس بتمويه، لأن التدرّج
/// يُرسم مرة واحدة على الـGPU بتكلفة شبه صفرية، بينما التمويه يعيد الحساب
/// كل إطار. هذا يحفظ الـ60 إطاراً مع الحصول على نفس الأثر البصري.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!isDark) {
      return DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.lightBg, Color(0xFFEDF2EE)],
          ),
        ),
        child: child,
      );
    }
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.greenAbyss),
      child: Stack(
        children: [
          // توهّج أخضر أعلى يمين
          Positioned(
            top: -160,
            right: -110,
            child: _Glow(size: 380, color: AppColors.greenGlow, opacity: 0.26),
          ),
          // توهّج أخضر أعمق أسفل يسار
          Positioned(
            bottom: -180,
            left: -140,
            child: _Glow(size: 420, color: AppColors.green, opacity: 0.30),
          ),
          child,
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color, required this.opacity});

  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: opacity * 0.4),
              color.withValues(alpha: 0),
            ],
            stops: const [0.0, 0.45, 1.0],
          ),
        ),
      ),
    );
  }
}

/// كارت زجاجي بحواف ناعمة.
///
/// **قرار أداء مقصود:** الوسيط `blur` يتحكم في استخدام [BackdropFilter].
///  • `blur: true` — زجاج حقيقي بتمويه. يُستخدم للكروت **الثابتة** فقط
///    (كروت الرئيسية، رأس التقرير) وعددها محدود في الشاشة الواحدة.
///  • `blur: false` (الافتراضي) — نفس المظهر الزجاجي لكن بتدرّج مطلي
///    مسبقاً بلا تمويه. يُستخدم **داخل القوائم المتمرّرة** حيث يقتل
///    التمويه معدّل الإطارات لأنه يُحسب لكل عنصر في كل إطار.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.blur = true,
    this.padding = const EdgeInsets.all(18),
    this.radius = AppTheme.radius,
    this.onTap,
    this.gradient,
    this.borderColor,
    this.margin,
  });

  final Widget child;
  final bool blur;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final Color? borderColor;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final br = BorderRadius.circular(radius);

    final surface = gradient ??
        LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: isDark
              ? [
                  Colors.white.withValues(alpha: 0.09),
                  Colors.white.withValues(alpha: 0.035),
                ]
              : [
                  Colors.white.withValues(alpha: 0.95),
                  Colors.white.withValues(alpha: 0.78),
                ],
        );

    Widget content = DecoratedBox(
      decoration: BoxDecoration(
        gradient: surface,
        borderRadius: br,
        border: Border.all(
          color: borderColor ??
              (isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.9)),
          width: 1.1,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: AppColors.green.withValues(alpha: 0.07),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Padding(padding: padding, child: child),
    );

    if (blur) {
      content = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: content,
      );
    }

    Widget card = ClipRRect(borderRadius: br, child: content);

    if (onTap != null) {
      card = Material(
        color: Colors.transparent,
        borderRadius: br,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: br,
          splashColor: AppColors.gold.withValues(alpha: 0.10),
          highlightColor: AppColors.gold.withValues(alpha: 0.05),
          child: card,
        ),
      );
    }

    // RepaintBoundary يعزل إعادة رسم الكارت عن بقية الشجرة
    return RepaintBoundary(
      child: margin == null ? card : Padding(padding: margin!, child: card),
    );
  }
}

/// حدّ ذهبي متدرّج — للكروت المميّزة مثل كارت المبلغ الكلي ووسام الأعلى تبرّعاً.
class GoldBorder extends StatelessWidget {
  const GoldBorder({
    super.key,
    required this.child,
    this.radius = AppTheme.radius,
    this.width = 1.4,
    this.showGlow = true,
  });

  final Widget child;
  final double radius;
  final double width;
  final bool showGlow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(width),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(radius + width),
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.22),
                  blurRadius: 16,
                  spreadRadius: -2,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: child,
      ),
    );
  }
}
