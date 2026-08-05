import 'package:intl/intl.dart';

import '../config/app_config.dart';

/// تنسيق الأرقام والتواريخ بالعربية.
///
/// العملة دينار عراقي فقط: بفواصل آلاف وبلا كسور عشرية، لأن الدينار
/// العراقي لا يُتعامل به بالفلس عملياً.
abstract final class Fmt {
  static final _money = NumberFormat('#,###', 'ar');
  static final _plain = NumberFormat('#,###', 'ar');

  /// يوحّد نظام الأرقام إلى اللاتيني (0-9).
  ///
  /// **لماذا هذا ضروري:** حزمة intl تشتق نظام الأرقام من بيانات اللغة، فتظهر
  /// المبالغ بأرقام لاتينية والتواريخ بأرقام عربية-هندية على الشاشة نفسها،
  /// وتختلف النتيجة بين أندرويد وويندوز. فرض نظام واحد صراحةً يجعل العرض
  /// متطابقاً على كل جهاز بدل أن يكون رهن إعدادات المنصّة.
  ///
  /// للتحويل إلى الأرقام العربية-الهندية (٠١٢٣): اعكس اتجاه الاستبدال هنا،
  /// وهو التغيير الوحيد المطلوب في التطبيق كله.
  static String _digits(String s) {
    const arabicIndic = '٠١٢٣٤٥٦٧٨٩';
    var out = s;
    for (var i = 0; i < 10; i++) {
      out = out.replaceAll(arabicIndic[i], '$i');
    }
    // الفاصلة العربية للآلاف والفاصلة العشرية العربية
    return out.replaceAll('٬', ',').replaceAll('٫', '.');
  }

  /// مبلغ مع العملة: «120,000 د.ع»
  static String money(num? v) {
    if (v == null) return '—';
    return '${_digits(_money.format(v))} ${AppConfig.currency}';
  }

  /// مبلغ بلا عملة
  static String amount(num? v) => v == null ? '—' : _digits(_money.format(v));

  /// عدد صحيح: «1,240»
  static String count(num? v) => v == null ? '0' : _digits(_plain.format(v));

  /// مبلغ مختصر للكروت الضيقة: «120 ألف» / «2.4 مليون»
  static String moneyShort(num? v) {
    if (v == null) return '—';
    final n = v.abs();
    if (n >= 1000000) {
      final m = v / 1000000;
      return '${_trim(m)} مليون ${AppConfig.currency}';
    }
    if (n >= 1000) {
      final k = v / 1000;
      return '${_trim(k)} ألف ${AppConfig.currency}';
    }
    return money(v);
  }

  static String _trim(double d) {
    final s = d.toStringAsFixed(1);
    return _digits(NumberFormat('#,##0.#', 'ar').format(double.parse(s)));
  }

  /// تاريخ: «3 آب 2026»
  static String date(DateTime? d) => d == null
      ? '—'
      : _digits(DateFormat('d MMMM y', 'ar').format(d.toLocal()));

  /// تاريخ قصير: «2026/08/03»
  static String dateShort(DateTime? d) => d == null
      ? '—'
      : _digits(DateFormat('yyyy/MM/dd', 'ar').format(d.toLocal()));

  /// تاريخ ووقت للطباعة: «2026/08/03 — 11:45 م»
  static String dateTime(DateTime? d) => d == null
      ? '—'
      : '${_digits(DateFormat('yyyy/MM/dd', 'ar').format(d.toLocal()))} — '
            '${_digits(DateFormat('h:mm a', 'ar').format(d.toLocal()))}';

  /// وقت نسبي للمنشورات: «قبل 3 ساعات»
  static String relative(DateTime? d) {
    if (d == null) return '—';
    final diff = DateTime.now().difference(d.toLocal());
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'قبل ${count(diff.inMinutes)} دقيقة';
    if (diff.inHours < 24) return 'قبل ${count(diff.inHours)} ساعة';
    if (diff.inDays < 7) return 'قبل ${count(diff.inDays)} يوم';
    if (diff.inDays < 30) return 'قبل ${count(diff.inDays ~/ 7)} أسبوع';
    if (diff.inDays < 365) return 'قبل ${count(diff.inDays ~/ 30)} شهر';
    return date(d);
  }
}
