import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// شعار الموكب — يُعرض بخلفيته البيضاء كما هو، داخل **لوحة** بحواف ناعمة.
///
/// سبب اللوحة: الشعار خلفيته بيضاء غير شفافة، فلو وُضع مباشرة على خلفية
/// التطبيق الداكنة لظهر كمستطيل أبيض حادّ يبدو خطأً. تأطيره بلوحة بيضاء
/// بحواف ناعمة وحدّ ذهبي رقيق يجعل البياض عنصر تصميم مقصوداً — تماماً
/// كلوحة معدنية مثبّتة. وفي التقارير المطبوعة على ورق أبيض لا حاجة للوحة
/// إطلاقاً، فيُستخدم `plain: true`.
class MawkibLogo extends StatelessWidget {
  const MawkibLogo({
    super.key,
    this.height,
    this.width,
    this.plain = false,
    this.padding,
    this.radius = 20,
    this.small = false,
  });

  /// ارتفاع الشعار نفسه (بلا اللوحة)
  final double? height;
  final double? width;

  /// بلا لوحة — للاستخدام على خلفية بيضاء أصلاً (التقارير، الطباعة)
  final bool plain;

  final EdgeInsetsGeometry? padding;
  final double radius;

  /// يستخدم النسخة الأصغر (٢٥٦ بكسل) — للأيقونات في الشريط العلوي
  final bool small;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      small ? 'assets/logo/logo_small.png' : 'assets/logo/logo.png',
      height: height,
      width: width,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    );

    if (plain) return image;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.55),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.16),
            blurRadius: 22,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(10),
        child: image,
      ),
    );
  }
}
