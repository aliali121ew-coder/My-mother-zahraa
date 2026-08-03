import 'package:intl/intl.dart';

import '../config/app_config.dart';

/// تنسيق الأرقام والتواريخ بالعربية.
///
/// العملة دينار عراقي فقط: بفواصل آلاف وبلا كسور عشرية، لأن الدينار
/// العراقي لا يُتعامل به بالفلس عملياً.
abstract final class Fmt {
  static final _money = NumberFormat('#,###', 'ar');
  static final _plain = NumberFormat('#,###', 'ar');

  /// مبلغ مع العملة: «١٢٠,٠٠٠ د.ع»
  static String money(num? v) {
    if (v == null) return '—';
    return '${_money.format(v)} ${AppConfig.currency}';
  }

  /// مبلغ بلا عملة
  static String amount(num? v) => v == null ? '—' : _money.format(v);

  /// عدد صحيح: «١,٢٤٠»
  static String count(num? v) => v == null ? '٠' : _plain.format(v);

  /// مبلغ مختصر للكروت الضيقة: «١٢٠ ألف» / «٢.٤ مليون»
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
    return NumberFormat('#,##0.#', 'ar').format(double.parse(s));
  }

  /// تاريخ: «٣ آب ٢٠٢٦»
  static String date(DateTime? d) =>
      d == null ? '—' : DateFormat('d MMMM y', 'ar').format(d.toLocal());

  /// تاريخ قصير: «٢٠٢٦/٠٨/٠٣»
  static String dateShort(DateTime? d) =>
      d == null ? '—' : DateFormat('yyyy/MM/dd', 'ar').format(d.toLocal());

  /// تاريخ ووقت للطباعة: «٢٠٢٦/٠٨/٠٣ — ١١:٤٥ م»
  static String dateTime(DateTime? d) => d == null
      ? '—'
      : '${DateFormat('yyyy/MM/dd', 'ar').format(d.toLocal())} — '
          '${DateFormat('h:mm a', 'ar').format(d.toLocal())}';

  /// وقت نسبي للمنشورات: «قبل ٣ ساعات»
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
