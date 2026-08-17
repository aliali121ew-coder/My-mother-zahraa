import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/data/auth_repository.dart';
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
  /// [sensitive] هل الصندوق يحوي بيانات حساسة (أسماء ودفعات) لا يجوز عرضها
  /// من مخزّن جلسة سابقة؟ عندئذٍ يُشترط أن تكون الجلسة الحالية **معتمدة**
  /// قبل الارتداد، وإلا رُمي الخطأ (P1).
  Future<CachedResult<List<Map<String, dynamic>>>> fetchList({
    required String boxName,
    required String Function(Map<String, dynamic>) idOf,
    required Future<List<Map<String, dynamic>>> Function() fetch,
    bool sensitive = false,
  }) async {
    try {
      final rows = await fetch();
      await cache.replaceAll(boxName, rows, idOf);
      return CachedResult(data: rows, fromCache: false);
    } catch (e) {
      // الارتداد للمخزن المحلي للصناديق الحساسة فقط إذا كانت الجلسة ما زالت
      // معتمدة — فلا تُعرض بيانات مخزّنة من جلسة سابقة بعد حظر أو إبطال
      // اعتماد (P1). إذا لم يكن Supabase مهيّأً (وضع تجريبي) فالجلسة
      // محلية أصلاً ونسمح بالارتداد.
      if (sensitive && isLive && _sessionNotApproved()) rethrow;
      final local = cache.readAll(boxName);
      if (local.isEmpty) rethrow;
      return CachedResult(data: local, fromCache: true, error: e);
    }
  }

  /// نفس المنطق لعنصر واحد مخزّن كسجل مفرد (مثل الإحصائيات)
  /// انظر [fetchList] لشرح [sensitive]
  Future<CachedResult<Map<String, dynamic>>> fetchOne({
    required String boxName,
    required String key,
    required Future<Map<String, dynamic>> Function() fetch,
    bool sensitive = false,
  }) async {
    try {
      final row = await fetch();
      await cache.put(boxName, key, row);
      return CachedResult(data: row, fromCache: false);
    } catch (e) {
      if (sensitive && isLive && _sessionNotApproved()) rethrow;
      final local = cache.readOne(boxName, key);
      if (local == null) rethrow;
      return CachedResult(data: local, fromCache: true, error: e);
    }
  }

  /// هل جلسة Supabase الحالية **غير معتمدة** (زائر أو موقوف أو مرفوض)؟
  /// نستخدم `isApproved` بدل فحص الملف الشخصي لتجنّب اعتماد كامل الجلسة.
  bool _sessionNotApproved() {
    if (!isLive) return false;
    final repo = AuthRepository();
    return !repo.isSignedIn || repo.isAnonymous;
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

/// يحوّل رسائل أخطاء Supabase والشبكة إلى عربية مفهومة ودقيقة.
String arabicError(Object e) {
  final s = e.toString().toLowerCase();

  // فحص أخطاء الاتصال وانقطاع الإنترنت ومشاكل DNS أولاً
  if (s.contains('socketexception') ||
      s.contains('failed host lookup') ||
      s.contains('no such host') ||
      s.contains('clientexception') ||
      s.contains('networkexception') ||
      s.contains('httpexception') ||
      s.contains('handshakeexception') ||
      s.contains('certificate_verify_failed') ||
      s.contains('connection refused') ||
      s.contains('connection reset') ||
      s.contains('connection closed') ||
      s.contains('connection timed out') ||
      s.contains('timeoutexception') ||
      s.contains('errno = 11001') ||
      s.contains('errno = 7') ||
      s.contains('failed to connect') ||
      s.contains('network is unreachable')) {
    return 'لا يوجد اتصال بالإنترنت أو تعذر الوصول إلى الخادم السحابي';
  }

  if (e is AuthException) {
    final m = e.message.toLowerCase();
    final c = (e.statusCode ?? e.code ?? '').toLowerCase();

    // 1. أخطاء عدم تطابق بيانات الدخول (البريد أو كلمة المرور غير صحيحة)
    if (c == 'invalid_credentials' ||
        c == 'invalid_grant' ||
        c == 'user_not_found' ||
        m.contains('invalid login') ||
        m.contains('invalid credential') ||
        m.contains('invalid_credentials') ||
        m.contains('invalid email or password') ||
        m.contains('invalid grant') ||
        m.contains('invalid password') ||
        m.contains('wrong password') ||
        m.contains('user not found')) {
      return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
    }

    // 2. تأكيد البريد الإلكتروني
    if (m.contains('email not confirmed') || c == 'email_not_confirmed') {
      return 'يجب تأكيد البريد الإلكتروني أولاً عبر الرابط المرسل لبريدك';
    }

    // 3. الحساب مسجل مسبقاً
    if (m.contains('already registered') ||
        m.contains('already been registered') ||
        m.contains('user already exists') ||
        c == 'user_already_exists') {
      return 'هذا البريد الإلكتروني مسجّل مسبقاً';
    }

    // 4. كلمة المرور ضعيفة (فقط عند إنشاء حساب أو تغيير كلمة المرور بكلمة قصيرة)
    if (c == 'weak_password' ||
        m.contains('weak password') ||
        m.contains('should be at least') ||
        m.contains('is too short') ||
        m.contains('signup requires a valid password') ||
        m.contains('password should be') ||
        m.contains('password must be')) {
      return 'كلمة المرور ضعيفة — ٦ أحرف على الأقل';
    }

    // 5. تجاوز معدل الطلبات
    if (m.contains('rate limit') ||
        m.contains('too many') ||
        c == 'over_request_rate_limit' ||
        c.contains('rate_limit')) {
      return 'محاولات كثيرة — يرجى الانتظار قليلاً وإعادة المحاولة';
    }

    // 6. أخطاء اتصال داخلية
    if (m.contains('network') || m.contains('connection') || m.contains('fetch')) {
      return 'لا يوجد اتصال بالإنترنت أو تعذر الوصول إلى الخادم السحابي';
    }

    return e.message;
  }

  if (e is PostgrestException) {
    // 42501 = رفض من سياسة RLS
    if (e.code == '42501' || e.message.contains('permission denied')) {
      return 'ليست لديك صلاحية كافية — تأكّد أن حسابك معتمد بالدور المناسب';
    }
    if (e.code == 'PGRST116') return 'لا توجد بيانات مطابقة';
    if (e.code == '23505') return 'هذا السجل مسجّل مسبقاً ولا يمكن تكراره';
    if (e.code == '23503') return 'تعذّر إتمام الإجراء لارتباط هذا السجل ببيانات أخرى';
    return 'تعذّر إتمام العملية السحابية، يرجى المحاولة لاحقاً';
  }

  return 'حدث خطأ أثناء الاتصال بالخادم، يرجى المحاولة لاحقاً';
}

/// مفتاح تخزين الإحصائيات المفرد
const kStatsKey = 'current';

/// يضمن أن كل قيم JSON قابلة للترميز قبل التخزين في Hive
Map<String, dynamic> jsonSafe(Map<String, dynamic> m) =>
    jsonDecode(jsonEncode(m)) as Map<String, dynamic>;
