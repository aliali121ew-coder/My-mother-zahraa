import 'package:flutter/material.dart';

/// لوحة ألوان تطبيق موكب أمنا الزهراء.
///
/// الذهبي والبرونزي والعنابي والفيروزي مستخرجة **قياساً فعلياً** من بكسلات
/// شعار الموكب المرفوع، فتتناسق الواجهة مع الشعار بلا تخمين. سلّم الأخضر
/// الداكن هو أساس الخلفيات كما طُلب، والذهبي يعمل لون إبراز فوقه.
abstract final class AppColors {
  // ── ذهبيات الشعار ──────────────────────────────────────────
  /// الذهبي الأساسي — مقياس وسيط لبكسلات الدرع والقبة
  static const gold = Color(0xFFC6A77B);

  /// ذهبي فاتح — لمعات الشعار (المئين ٨٠)
  static const goldLight = Color(0xFFDCBD8D);

  /// ذهبي ساطع — للنصوص المهمة على الخلفيات الداكنة
  static const goldBright = Color(0xFFEBD3A8);

  /// برونزي — إطار الدرع المنقوش
  static const bronze = Color(0xFF8D7759);

  /// ذهبي داكن — للنصوص على الخلفيات الفاتحة (تباين كافٍ)
  static const goldDark = Color(0xFF8A6A33);

  // ── ألوان الشعار الثانوية ──────────────────────────────────
  /// عنابي — لون كلمة "موكب أمنا" في الشعار
  static const maroon = Color(0xFF7D493A);

  /// فيروزي — راية الشعار
  static const teal = Color(0xFF3D6D78);

  // ── سلّم الأخضر الداكن ─────────────────────────────────────
  /// أسود مائل للأخضر — خلفية الوضع الليلي
  static const greenAbyss = Color(0xFF04120C);
  static const greenDeepest = Color(0xFF061C13);
  static const greenDeep = Color(0xFF0A2A1C);
  static const greenMid = Color(0xFF0F3D28);
  static const green = Color(0xFF14512F);

  /// أخضر متوهج — للتوهج خلف الكروت الزجاجية والإبرازات
  static const greenGlow = Color(0xFF1B7A4B);

  // ── الوضع النهاري ──────────────────────────────────────────
  static const lightBg = Color(0xFFF4F6F3);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightGreenTint = Color(0xFFE8EFE9);

  // ── حالات السداد ───────────────────────────────────────────
  /// مسدد
  static const paid = Color(0xFF2E9E6B);

  /// متأخر — منسجم مع عنابي الشعار
  static const overdue = Color(0xFFC4553F);

  /// معلّق / بانتظار الموافقة
  static const pending = Color(0xFFD79A3C);

  // ── نصوص ───────────────────────────────────────────────────
  static const textOnDark = Color(0xFFF2EFE8);
  static const textOnDarkMuted = Color(0xFF9FB0A6);
  static const textOnLight = Color(0xFF14201A);
  static const textOnLightMuted = Color(0xFF5E6E64);

  // ── تدرّجات ────────────────────────────────────────────────
  /// تدرّج كارت المبلغ الكلي — أخضر داكن متدرّج كما طُلب
  static const totalCardGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [green, greenMid, greenDeep],
  );

  /// تدرّج كروت الأعداد — ألوان مقاربة من نفس العائلة
  static const countCardGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [greenMid, greenDeep],
  );

  /// تدرّج ذهبي للحدود والإبرازات
  static const goldGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [goldBright, gold, bronze],
  );
}
