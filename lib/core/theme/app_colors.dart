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
  static const greenAbyss = Color(0xFF030D08);
  static const greenDeepest = Color(0xFF05160E);
  static const greenDeep = Color(0xFF082216);
  static const greenMid = Color(0xFF0E3321);
  static const green = Color(0xFF13482C);
  static const greenRich = Color(0xFF1B633C);

  /// أخضر متوهج — للتوهج خلف الكروت الزجاجية والإبرازات
  static const greenGlow = Color(0xFF229357);

  // ── الوضع النهاري ──────────────────────────────────────────
  static const lightBg = Color(0xFFF3F6F3);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightGreenTint = Color(0xFFE5ECE7);

  // ── حالات السداد ───────────────────────────────────────────
  /// مسدد
  static const paid = Color(0xFF2E9E6B);

  /// متأخر — منسجم مع عنابي الشعار
  static const overdue = Color(0xFFE54D42);

  /// معلّق / بانتظار الموافقة
  static const pending = Color(0xFFE5A137);

  // ── منصّات المراكز والأوسمة ─────────────────────────────────
  static const goldMedal = Color(0xFFFFD700);
  static const silverMedal = Color(0xFFC0C0C0);
  static const bronzeMedal = Color(0xFFCD7F32);

  // ── نصوص ───────────────────────────────────────────────────
  static const textOnDark = Color(0xFFF6F4EE);
  static const textOnDarkMuted = Color(0xFFA5B8AC);
  static const textOnLight = Color(0xFF101C16);
  static const textOnLightMuted = Color(0xFF53665B);

  // ── تدرّجات ────────────────────────────────────────────────
  /// تدرّج كارت المبلغ الكلي — أخضر ملكي متدرّج بعمق رائع
  static const totalCardGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [
      Color(0xFF1B5938),
      Color(0xFF103A24),
      Color(0xFF082215),
    ],
  );

  /// تدرّج كروت الأعداد — ألوان مقاربة من نفس العائلة
  static const countCardGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [
      Color(0xFF123D27),
      Color(0xFF092417),
    ],
  );

  /// تدرّج ذهبي ملكي للحدود والإبرازات
  static const goldGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [
      Color(0xFFFFF3D1),
      Color(0xFFD4AF37),
      Color(0xFF9E7B1D),
    ],
  );

  /// تدرّج الوسام الذهبي (المركز الأول)
  static const rank1Gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFF7D6),
      Color(0xFFE5C158),
      Color(0xFFB88E28),
    ],
  );

  /// تدرّج الوسام الفضي (المركز الثاني)
  static const rank2Gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFCBD5E1),
      Color(0xFF64748B),
    ],
  );

  /// تدرّج الوسام البرونزي (المركز الثالث)
  static const rank3Gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFEDD5),
      Color(0xFFF97316),
      Color(0xFF9A3412),
    ],
  );
}
