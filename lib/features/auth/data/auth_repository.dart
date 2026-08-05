import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/supabase_repository.dart';
import '../../../shared/models/profile_model.dart';

/// مصادقة Supabase: تسجيل، دخول، خروج، وقراءة الملف الشخصي.
///
/// ملاحظة مهمة: المستخدم الجديد يُنشأ له ملف تلقائياً بمشغّل في قاعدة
/// البيانات بحالة `pending`، فلا يرى أي رقم حتى يوافق المدير. التطبيق
/// لا يستطيع رفع دور نفسه — سياسة RLS على `profiles` تمنع تعديل
/// حقلي `role` و `status` من المستخدم نفسه.
class AuthRepository extends SupabaseRepository {
  Session? get session => isLive ? db.auth.currentSession : null;
  User? get user => isLive ? db.auth.currentUser : null;
  bool get isSignedIn => session != null;

  /// هل الجلسة الحالية مجهولة (للإعجاب بلا حساب)؟
  bool get isAnonymous => user?.isAnonymous ?? false;

  Stream<AuthState> get authChanges => db.auth.onAuthStateChange;

  /// إنشاء حساب. يعيد الملف الشخصي إن أمكن قراءته فوراً.
  Future<ProfileModel?> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final res = await db.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'full_name': fullName.trim()},
    );
    if (res.user == null) return null;
    // المشغّل ينشئ الملف؛ قد يتأخر لحظة فنحاول القراءة بتسامح
    return fetchMyProfile();
  }

  Future<ProfileModel?> signIn({
    required String email,
    required String password,
  }) async {
    await db.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    return fetchMyProfile();
  }

  /// دخول مجهول — يُستخدم فقط لتمكين الزائر من الإعجاب بالمنشورات.
  /// لا يُنشأ له ملف شخصي ولا يستطيع التعليق (سياسة RLS تمنع الجلسات المجهولة).
  Future<void> signInAnonymously() async {
    if (isSignedIn) return;
    await db.auth.signInAnonymously();
  }

  Future<void> signOut() => db.auth.signOut();

  Future<void> resetPassword(String email) =>
      db.auth.resetPasswordForEmail(email.trim());

  Future<void> changePassword(String newPassword) =>
      db.auth.updateUser(UserAttributes(password: newPassword));

  /// يقرأ ملف المستخدم الحالي. يعيد null للجلسات المجهولة أو إن لم يُنشأ بعد.
  Future<ProfileModel?> fetchMyProfile() async {
    final uid = user?.id;
    if (uid == null || isAnonymous) return null;
    try {
      final row = await db
          .from('profiles')
          .select()
          .eq('id', uid)
          .maybeSingle();
      if (row == null) return null;
      return ProfileModel.fromJson(row);
    } on PostgrestException {
      // قد تمنع RLS القراءة لحظة إنشاء الحساب — لا نُسقط التطبيق
      return null;
    }
  }

  /// تحديث الاسم أو الهاتف أو الصورة. لا يمكن تعديل الدور أو الحالة (RLS).
  Future<void> updateMyProfile({
    String? fullName,
    String? phone,
    String? avatarUrl,
  }) async {
    final uid = user?.id;
    if (uid == null) return;
    final patch = <String, dynamic>{};
    if (fullName != null) patch['full_name'] = fullName.trim();
    if (phone != null) patch['phone'] = phone.trim();
    if (avatarUrl != null) patch['avatar_url'] = avatarUrl;
    if (patch.isEmpty) return;
    await db.from('profiles').update(patch).eq('id', uid);
  }
}
