import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/data/supabase_repository.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/profile_model.dart';

// ─────────────────────────────────────────────────────────────────
// مزوّد قائمت حسابات المستخدمين — للمدير فقط (سياسة profiles_admin_all).
// القراءة من الشبكة وتخزّن محليًا، وترتدّ للمخزن عند انقطاع الاتصال.
// ─────────────────────────────────────────────────────────────────
final adminUsersProvider =
    AsyncNotifierProvider<AdminUsersNotifier, List<ProfileModel>>(
  AdminUsersNotifier.new,
);

class AdminUsersNotifier extends AsyncNotifier<List<ProfileModel>> {
  AdminRepository get _repo => AdminRepository();

  @override
  Future<List<ProfileModel>> build() => _repo.loadAll();

  Future<void> refresh() async {
    final list = await _repo
        .loadAll()
        .onError((error, stackTrace) => state.value ?? []);
    state = AsyncData(list);
  }

  Future<void> approve(String userId) => _act(() => _repo.approve(userId));
  Future<void> reject(String userId) => _act(() => _repo.reject(userId));
  Future<void> ban(String userId) => _act(() => _repo.ban(userId));
  Future<void> unban(String userId) => _act(() => _repo.unban(userId));

  Future<void> changeRole(String userId, UserRole role) =>
      _act(() => _repo.changeRole(userId, role));

  /// ينفّذ الإجراء ثم يحدّث القائمة تلقائيًا — حتى تبقى الواجهة مزامنة
  /// مع السيرفر بعد كل موافقة أو حظر أو تغيير دور.
  Future<void> _act(Future<void> Function() action) async {
    await action();
    await refresh();
  }
}

/// إدارة الحسابات: قائمة الحسابات، الموافقة/الرفض، الأدوار، والحظر.
/// كل العمليات محمية بـ RLS عبر سياسة `profiles_admin_all` — غير المدير
/// سيحصل على 42501 ولن يستطيع تعديل أي صف.
class AdminRepository extends SupabaseRepository {
  static final _box = AppConfig.boxAdminUsers;

  /// جلب كل الحسابات غير المحذوفة مرتبة بالأحدث.
  Future<List<ProfileModel>> loadAll() async {
    if (!isLive) return _loadLocal();

    try {
      final rows = await db
          .from('profiles')
          .select()
          .order('created_at', ascending: false);

      final list = List<Map<String, dynamic>>.from(rows)
          .map(ProfileModel.fromJson)
          .toList();

      await _storeLocal(list);
      return list;
    } catch (e) {
      final local = _loadLocal();
      if (local.isEmpty) rethrow;
      return local;
    }
  }

  /// اعتماد حساب جديد ليمكنه رؤية القوائم والإحصائيات.
  Future<void> approve(String userId) => _patchStatus(userId, UserStatus.approved);

  /// رفض طلب حساب.
  Future<void> reject(String userId) => _patchStatus(userId, UserStatus.rejected);

  /// حظر حساب قائم — يفقد كل صلاحياته.
  Future<void> ban(String userId) => _patchStatus(userId, UserStatus.banned);

  /// رفع الحظر عن حساب.
  Future<void> unban(String userId) => _patchStatus(userId, UserStatus.approved);

  /// تغيير الدور الوظيفي (admin / finance / publisher / member).
  Future<void> changeRole(String userId, UserRole role) async {
    await db
        .from('profiles')
        .update({'role': role.value, 'updated_at': DateTime.now().toUtc()})
        .eq('id', userId);
  }

  Future<void> _patchStatus(String userId, UserStatus status) async {
    await db
        .from('profiles')
        .update({'status': status.value, 'updated_at': DateTime.now().toUtc()})
        .eq('id', userId);
  }

  // ─────────────────────────────────────────────────────────────
  // التخزين المحلي — للقراءة خارج الاتصال فقط
  // ─────────────────────────────────────────────────────────────
  Future<void> _storeLocal(List<ProfileModel> list) async {
    try {
      await cache.replaceAll(
        _box,
        list.map((p) => p.toJson()).toList(),
        (m) => m['id'].toString(),
      );
    } catch (_) {
      // فشل التخزين لا يعطّل القائمة
    }
  }

  List<ProfileModel> _loadLocal() =>
      cache.readAll(_box).map(ProfileModel.fromJson).toList();
}
