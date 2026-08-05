import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../storage/hive_service.dart';

/// أساس مشترك لكل مستودعات البيانات.
///
/// النمط المتبع: **اقرأ من الشبكة وخزّن، وإذا فشلت الشبكة اقرأ من المخزن.**
/// هذا يجعل التطبيق يفتح فوراً بلا إنترنت ببيانات آخر مزامنة، ويحدّثها
/// تلقائياً عند توفّر الاتصال، بلا شاشة تحميل بيضاء ولا رسالة خطأ مزعجة.
abstract class SupabaseRepository {
  SupabaseClient get db => Supabase.instance.client;
  HiveService get cache => HiveService.instance;

  /// هل نحن متصلون بمشروع Supabase حقيقي؟
  bool get isLive => AppConfig.isConfigured;

  /// يقرأ من الشبكة ويخزّن النتيجة، ويرتدّ للمخزن المحلي عند الفشل.
  ///
  /// [boxName] صندوق Hive · [idOf] يستخرج معرّف كل عنصر · [fetch] جلب الشبكة
  Future<CachedResult<List<Map<String, dynamic>>>> fetchList({
    required String boxName,
    required String Function(Map<String, dynamic>) idOf,
    required Future<List<Map<String, dynamic>>> Function() fetch,
  }) async {
    try {
      final rows = await fetch();
      await cache.replaceAll(boxName, rows, idOf);
      return CachedResult(data: rows, fromCache: false);
    } catch (e) {
      final local = cache.readAll(boxName);
      if (local.isEmpty) rethrow;
      return CachedResult(data: local, fromCache: true, error: e);
    }
  }

  /// نفس المنطق لعنصر واحد مخزّن كسجل مفرد (مثل الإحصائيات)
  Future<CachedResult<Map<String, dynamic>>> fetchOne({
    required String boxName,
    required String key,
    required Future<Map<String, dynamic>> Function() fetch,
  }) async {
    try {
      final row = await fetch();
      await cache.put(boxName, key, row);
      return CachedResult(data: row, fromCache: false);
    } catch (e) {
      final local = cache.readOne(boxName, key);
      if (local == null) rethrow;
      return CachedResult(data: local, fromCache: true, error: e);
    }
  }
}

/// نتيجة قراءة تحمل معها معلومة **من أين جاءت**، فتستطيع الواجهة إظهار
/// شارة «بيانات مخزّنة — بلا اتصال» بدل الكذب على المستخدم بأنها محدّثة.
class CachedResult<T> {
  const CachedResult({required this.data, required this.fromCache, this.error});

  final T data;
  final bool fromCache;
  final Object? error;

  bool get isStale => fromCache;
}

/// يحوّل رسائل أخطاء Supabase إلى عربية مفهومة.
String arabicError(Object e) {
  if (e is AuthException) {
    final m = e.message.toLowerCase();
    if (m.contains('invalid login')) return 'البريد أو كلمة المرور غير صحيحة';
    if (m.contains('email not confirmed')) return 'يجب تأكيد البريد الإلكتروني أولاً';
    if (m.contains('already registered') || m.contains('already been registered')) {
      return 'هذا البريد مسجّل مسبقاً';
    }
    if (m.contains('password')) return 'كلمة المرور ضعيفة — ٦ أحرف على الأقل';
    if (m.contains('rate limit') || m.contains('too many')) {
      return 'محاولات كثيرة — انتظر قليلاً وأعد المحاولة';
    }
    return e.message;
  }
  if (e is PostgrestException) {
    // 42501 = رفض من سياسة RLS
    if (e.code == '42501') return 'ليست لديك صلاحية لهذا الإجراء';
    if (e.code == 'PGRST116') return 'لا توجد بيانات';
    if (e.message.contains('permission denied')) {
      return 'ليست لديك صلاحية — تأكّد أن حسابك معتمد من المدير';
    }
    return e.message;
  }
  final s = e.toString();
  if (s.contains('SocketException') ||
      s.contains('Failed host lookup') ||
      s.contains('ClientException')) {
    return 'لا يوجد اتصال بالإنترنت';
  }
  if (s.contains('TimeoutException')) return 'انتهت مهلة الاتصال';
  return 'حدث خطأ غير متوقّع';
}

/// مفتاح تخزين الإحصائيات المفرد
const kStatsKey = 'current';

/// يضمن أن كل قيم JSON قابلة للترميز قبل التخزين في Hive
Map<String, dynamic> jsonSafe(Map<String, dynamic> m) =>
    jsonDecode(jsonEncode(m)) as Map<String, dynamic>;
