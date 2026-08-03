import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

/// ثيم التطبيق بوضعين متناسقين: ليلي وnهاري.
///
/// الوضع الليلي: أسود مائل للأخضر مع توهج أخضر وكروت زجاجية — كما طُلب.
/// الوضع النهاري: أبيض مائل للأخضر الفاتح، والزجاجي يُستبدل بأسطح بيضاء
/// شبه شفافة مع ظل ناعم، لأن التمويه على خلفية فاتحة يفقد أثره البصري.
/// الذهبي لون الإبراز في الوضعين، لكن بدرجة أغمق في النهاري ليحقق تبايناً كافياً.
abstract final class AppTheme {
  static const fontFamily = 'IBMPlexSansArabic';

  /// نصف قطر الحواف الناعمة الموحّد في كل التطبيق
  static const radius = 22.0;
  static const radiusSmall = 14.0;
  static const radiusLarge = 28.0;

  // ────────────────────────────────────────────────────────────
  // الوضع الليلي
  // ────────────────────────────────────────────────────────────
  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      primary: AppColors.gold,
      onPrimary: AppColors.greenAbyss,
      primaryContainer: AppColors.green,
      onPrimaryContainer: AppColors.goldBright,
      secondary: AppColors.greenGlow,
      onSecondary: AppColors.textOnDark,
      surface: AppColors.greenDeepest,
      onSurface: AppColors.textOnDark,
      surfaceContainerHighest: AppColors.greenDeep,
      outline: AppColors.bronze,
      error: AppColors.overdue,
      onError: AppColors.textOnDark,
    );

    return _base(scheme, AppColors.greenAbyss, Brightness.dark);
  }

  // ────────────────────────────────────────────────────────────
  // الوضع النهاري
  // ────────────────────────────────────────────────────────────
  static ThemeData get light {
    const scheme = ColorScheme.light(
      primary: AppColors.green,
      onPrimary: Colors.white,
      primaryContainer: AppColors.lightGreenTint,
      onPrimaryContainer: AppColors.green,
      secondary: AppColors.goldDark,
      onSecondary: Colors.white,
      surface: AppColors.lightSurface,
      onSurface: AppColors.textOnLight,
      surfaceContainerHighest: AppColors.lightGreenTint,
      outline: Color(0xFFD3DBD5),
      error: AppColors.overdue,
      onError: Colors.white,
    );

    return _base(scheme, AppColors.lightBg, Brightness.light);
  }

  // ────────────────────────────────────────────────────────────
  static ThemeData _base(ColorScheme scheme, Color bg, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final onBg = isDark ? AppColors.textOnDark : AppColors.textOnLight;
    final muted = isDark ? AppColors.textOnDarkMuted : AppColors.textOnLightMuted;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      fontFamily: fontFamily,
      splashFactory: InkSparkle.splashFactory,
      textTheme: _textTheme(onBg, muted),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        foregroundColor: onBg,
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 19,
          fontWeight: FontWeight.w600,
          color: onBg,
        ),
      ),
      cardTheme: CardThemeData(
        color: isDark ? AppColors.greenDeep : AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        elevation: isDark ? 0 : 2,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : AppColors.lightGreenTint.withValues(alpha: 0.6),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: TextStyle(color: muted, fontFamily: fontFamily),
        labelStyle: TextStyle(color: muted, fontFamily: fontFamily),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFD3DBD5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: const BorderSide(color: AppColors.overdue),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size.fromHeight(54),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size.fromHeight(54),
          side: BorderSide(color: scheme.primary.withValues(alpha: 0.5)),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : AppColors.lightGreenTint,
        labelStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: onBg,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      dividerTheme: DividerThemeData(
        color: isDark
            ? Colors.white.withValues(alpha: 0.07)
            : const Color(0xFFE2E8E3),
        thickness: 1,
        space: 1,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? AppColors.greenDeepest : AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusLarge)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? AppColors.greenDeep : AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 19,
          fontWeight: FontWeight.w600,
          color: onBg,
        ),
        contentTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 15,
          height: 1.6,
          color: muted,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppColors.greenMid : AppColors.textOnLight,
        contentTextStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          color: AppColors.textOnDark,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
    );
  }

  static TextTheme _textTheme(Color onBg, Color muted) => TextTheme(
        displayLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 40,
          fontWeight: FontWeight.w700,
          color: onBg,
          height: 1.2,
        ),
        displayMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: onBg,
          height: 1.25,
        ),
        headlineMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: onBg,
          height: 1.3,
        ),
        titleLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 19,
          fontWeight: FontWeight.w600,
          color: onBg,
          height: 1.4,
        ),
        titleMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: onBg,
          height: 1.45,
        ),
        bodyLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: onBg,
          height: 1.6,
        ),
        bodyMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: muted,
          height: 1.6,
        ),
        bodySmall: TextStyle(
          fontFamily: fontFamily,
          fontSize: 12.5,
          fontWeight: FontWeight.w400,
          color: muted,
          height: 1.5,
        ),
        labelLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: onBg,
        ),
      );
}
