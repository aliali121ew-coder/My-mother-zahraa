import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/data/supabase_repository.dart';
import '../../../core/storage/hive_service.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/profile_model.dart';

/// مصادقة Supabase: تسجيل، دخول، خروج، وقراءة الملف الشخصي.
///
/// ملاحظة مهمة: المستخدم الجديد يُنشأ له ملف تلقائياً بمشغّل في قاعدة
/// البيانات بحالة `pending`، فلا يرى أي رقم حتى يوافق المدير. التطبيق
/// لا يستطيع رفع دور نفسه — سياسة RLS على `profiles` تمنع تعديل
/// حقلي `role` و `status` من المستخدم نفسه، باستثناء البريد الأساسي لمدير النظام.
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
    String? phone,
  }) async {
    final cleanEmail = email.trim();
    final res = await db.auth.signUp(
      email: cleanEmail,
      password: password,
      data: {
        'full_name': fullName.trim(),
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      },
    );
    final isMaster = AppConfig.isMasterAdmin(cleanEmail);
    final uid = res.user?.id ?? user?.id;

    if (isMaster && uid != null) {
      try {
        await db.from('profiles').update({'role': 'admin', 'status': 'approved'}).eq('id', uid);
      } catch (_) {}
    }

    final p = await fetchMyProfile(fallbackEmail: cleanEmail);
    if (isMaster) {
      final elevated = (p ?? ProfileModel(
        id: uid ?? 'master_admin',
        fullName: fullName.isNotEmpty ? fullName : 'مدير النظام',
        email: cleanEmail,
        phone: phone,
        role: UserRole.admin,
        status: UserStatus.approved,
      )).copyWith(
        role: UserRole.admin,
        status: UserStatus.approved,
        email: cleanEmail,
      );
      await HiveService.instance.settings.put(
        'cached_my_profile',
        jsonEncode(elevated.toJson()),
      );
      return elevated;
    }
    return p;
  }

  Future<ProfileModel?> signIn({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim();
    final res = await db.auth.signInWithPassword(
      email: cleanEmail,
      password: password,
    );
    final isMaster = AppConfig.isMasterAdmin(cleanEmail);
    final uid = res.user?.id ?? user?.id;
    if (isMaster && uid != null) {
      try {
        await db.from('profiles').update({'role': 'admin', 'status': 'approved'}).eq('id', uid);
      } catch (_) {}
    }
    final p = await fetchMyProfile(fallbackEmail: cleanEmail);
    if (isMaster) {
      final elevated = (p ?? ProfileModel(
        id: uid ?? 'master_admin',
        fullName: 'مدير النظام',
        email: cleanEmail,
        role: UserRole.admin,
        status: UserStatus.approved,
      )).copyWith(
        role: UserRole.admin,
        status: UserStatus.approved,
        email: cleanEmail,
      );
      await HiveService.instance.settings.put(
        'cached_my_profile',
        jsonEncode(elevated.toJson()),
      );
      return elevated;
    }
    return p;
  }

  /// دخول مجهول — يُستخدم فقط لتمكين الزائر من الإعجاب بالمنشورات.
  /// لا يُنشأ له ملف شخصي ولا يستطيع التعليق (سياسة RLS تمنع الجلسات المجهولة).
  Future<void> signInAnonymously() async {
    if (isSignedIn) return;
    await db.auth.signInAnonymously();
  }

  /// تسجيل الخروج مع **مسح البيانات الحساسة والملف الشخصي محلياً** أولاً
  Future<void> signOut() async {
    await cache.clearSensitiveCache();
    await HiveService.instance.settings.delete('cached_my_profile');
    return db.auth.signOut();
  }

  Future<void> resetPassword(String email) =>
      db.auth.resetPasswordForEmail(email.trim());

  Future<void> changePassword(String newPassword) =>
      db.auth.updateUser(UserAttributes(password: newPassword));

  /// يقرأ ملف المستخدم الحالي. يعيد null للجلسات المجهولة أو إن لم يُنشأ بعد.
  Future<ProfileModel?> fetchMyProfile({String? fallbackEmail}) async {
    final currentEmail = user?.email ?? fallbackEmail;
    final isMaster = AppConfig.isMasterAdmin(currentEmail);

    // 1. فحص المخزن المحلي أولاً
    final localRow = HiveService.instance.settings.get('cached_my_profile');
    ProfileModel? localProfile;
    if (localRow != null) {
      try {
        final map = jsonDecode(localRow.toString()) as Map<String, dynamic>;
        localProfile = ProfileModel.fromJson(map, email: currentEmail);
      } catch (_) {}
    }

    if (isMaster && localProfile != null && (localProfile.role != UserRole.admin || localProfile.status != UserStatus.approved)) {
      localProfile = localProfile.copyWith(
        role: UserRole.admin,
        status: UserStatus.approved,
        email: currentEmail,
      );
    }

    final uid = user?.id;
    if (uid == null || isAnonymous) {
      if (isMaster) {
        return (localProfile ?? ProfileModel(
          id: 'master_admin',
          fullName: 'مدير النظام',
          email: currentEmail,
          role: UserRole.admin,
          status: UserStatus.approved,
        )).copyWith(
          role: UserRole.admin,
          status: UserStatus.approved,
          email: currentEmail,
        );
      }
      return localProfile;
    }

    try {
      final row = await db
          .from('profiles')
          .select()
          .eq('id', uid)
          .maybeSingle();

      if (row == null) {
        if (isMaster) {
          final p = ProfileModel(
            id: uid,
            fullName: 'مدير النظام',
            email: currentEmail,
            role: UserRole.admin,
            status: UserStatus.approved,
          );
          await HiveService.instance.settings.put(
            'cached_my_profile',
            jsonEncode(p.toJson()),
          );
          return p;
        }
        return localProfile;
      }

      var profile = ProfileModel.fromJson(row, email: currentEmail);
      if (isMaster) {
        profile = profile.copyWith(
          role: UserRole.admin,
          status: UserStatus.approved,
          email: currentEmail,
        );
        try {
          await db.from('profiles').update({'role': 'admin', 'status': 'approved'}).eq('id', uid);
        } catch (_) {}
      }

      // حفظ في المخزن المحلي
      await HiveService.instance.settings.put(
        'cached_my_profile',
        jsonEncode(profile.toJson()),
      );
      return profile;
    } catch (_) {
      if (isMaster) {
        return (localProfile ?? ProfileModel(
          id: uid,
          fullName: 'مدير النظام',
          email: currentEmail,
          role: UserRole.admin,
          status: UserStatus.approved,
        )).copyWith(
          role: UserRole.admin,
          status: UserStatus.approved,
          email: currentEmail,
        );
      }
      return localProfile;
    }
  }

  /// تحديث الاسم أو الهاتف أو الصورة. لا يمكن تعديل الدور أو الحالة (RLS).
  Future<void> updateMyProfile({
    String? fullName,
    String? phone,
    String? avatarUrl,
  }) async {
    final current = await fetchMyProfile();
    final updated = ProfileModel(
      id: current?.id ?? user?.id ?? 'local_user',
      fullName: fullName ?? current?.fullName ?? 'مستخدم',
      phone: phone ?? current?.phone,
      avatarUrl: avatarUrl ?? current?.avatarUrl,
      role: current?.role ?? UserRole.member,
      status: current?.status ?? UserStatus.approved,
    );

    // حفظ فوري في المخزن المحلي
    await HiveService.instance.settings.put(
      'cached_my_profile',
      jsonEncode({
        'id': updated.id,
        'full_name': updated.fullName,
        'phone': updated.phone,
        'avatar_url': updated.avatarUrl,
        'role': updated.role.name,
        'status': updated.status.name,
      }),
    );

    final uid = user?.id;
    if (uid == null) return;
    final patch = <String, dynamic>{};
    if (fullName != null) patch['full_name'] = fullName.trim();
    if (phone != null) patch['phone'] = phone.trim();
    if (avatarUrl != null) patch['avatar_url'] = avatarUrl;
    if (patch.isEmpty) return;
    try {
      await db.from('profiles').update(patch).eq('id', uid);
    } catch (_) {}
  }

  static const _boxPendingKey = 'cached_pending_profiles_v1';

  /// جلب الحسابات المعلقة بانتظار الموافقة (للمدير)
  Future<List<ProfileModel>> fetchPendingProfiles() async {
    // 1. قراءة المحفوظ محلياً أولاً
    final localRaw = HiveService.instance.settings.get(_boxPendingKey);
    List<ProfileModel> localList = [];
    if (localRaw != null) {
      try {
        final list = (jsonDecode(localRaw.toString()) as List)
            .map((e) => ProfileModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        localList = list;
      } catch (_) {}
    }

    if (!isLive) {
      if (localList.isEmpty) {
        // بيانات تجريبية أولية للطلبات
        localList = [
          ProfileModel(
            id: 'req_1',
            fullName: 'سجاد علي الموسوي',
            phone: '07705544332',
            role: UserRole.member,
            status: UserStatus.pending,
            createdAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 15)),
          ),
          ProfileModel(
            id: 'req_2',
            fullName: 'حيدر كريم الشمري',
            phone: '07801122334',
            role: UserRole.member,
            status: UserStatus.pending,
            createdAt: DateTime.now().subtract(const Duration(hours: 5, minutes: 40)),
          ),
        ];
        await _savePendingLocal(localList);
      }
      return localList;
    }

    try {
      final rows = await db
          .from('profiles')
          .select()
          .eq('status', 'pending')
          .order('created_at', ascending: false);
      final remoteList = (rows as List)
          .map((r) => ProfileModel.fromJson(r as Map<String, dynamic>))
          .toList();
      
      // دمج المحلي مع السحابي
      final merged = <String, ProfileModel>{};
      for (final p in localList) {
        merged[p.id] = p;
      }
      for (final p in remoteList) {
        merged[p.id] = p;
      }
      final result = merged.values.where((p) => p.status == UserStatus.pending).toList();
      await _savePendingLocal(result);
      return result;
    } catch (_) {
      return localList;
    }
  }

  Future<void> _savePendingLocal(List<ProfileModel> list) async {
    try {
      final jsonList = list.map((p) => {
        'id': p.id,
        'full_name': p.fullName,
        'phone': p.phone,
        'avatar_url': p.avatarUrl,
        'role': p.role.name,
        'status': p.status.name,
        'created_at': p.createdAt?.toIso8601String(),
      }).toList();
      await HiveService.instance.settings.put(_boxPendingKey, jsonEncode(jsonList));
    } catch (_) {}
  }

  /// تسجيل طلب حساب معلق جديد
  Future<void> recordPendingRegistration({
    required String fullName,
    String? phone,
    String? email,
  }) async {
    final current = await fetchPendingProfiles();
    final newReq = ProfileModel(
      id: 'req_${DateTime.now().millisecondsSinceEpoch}',
      fullName: fullName,
      phone: phone ?? email,
      role: UserRole.member,
      status: UserStatus.pending,
      createdAt: DateTime.now(),
    );
    final updated = [newReq, ...current];
    await _savePendingLocal(updated);
  }

  static const _boxAllProfilesKey = 'cached_all_profiles_v1';

  /// جلب جميع الحسابات (لإدارة الحظر)
  Future<List<ProfileModel>> fetchAllProfiles() async {
    final localRaw = HiveService.instance.settings.get(_boxAllProfilesKey);
    List<ProfileModel> localList = [];
    if (localRaw != null) {
      try {
        final list = (jsonDecode(localRaw.toString()) as List)
            .map((e) => ProfileModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        localList = list;
      } catch (_) {}
    }

    if (!isLive) {
      if (localList.isEmpty) {
        localList = [
          ProfileModel(
            id: 'ban_1',
            fullName: 'أحمد جاسم الكعبي',
            phone: '07712348899',
            role: UserRole.member,
            status: UserStatus.banned,
            createdAt: DateTime.now().subtract(const Duration(days: 3)),
          ),
          ProfileModel(
            id: 'user_1',
            fullName: 'مدير الموكب',
            phone: 'admin@mawkib.org',
            role: UserRole.admin,
            status: UserStatus.approved,
            createdAt: DateTime.now().subtract(const Duration(days: 30)),
          ),
          ProfileModel(
            id: 'user_2',
            fullName: 'حسين عادل الخفاجي',
            phone: '07819988776',
            role: UserRole.member,
            status: UserStatus.approved,
            createdAt: DateTime.now().subtract(const Duration(days: 10)),
          ),
        ];
        await _saveAllProfilesLocal(localList);
      }
      return localList;
    }

    try {
      final rows = await db
          .from('profiles')
          .select()
          .order('created_at', ascending: false);
      final remoteList = (rows as List)
          .map((r) => ProfileModel.fromJson(r as Map<String, dynamic>))
          .toList();
      await _saveAllProfilesLocal(remoteList);
      return remoteList;
    } catch (_) {
      return localList;
    }
  }

  Future<void> _saveAllProfilesLocal(List<ProfileModel> list) async {
    try {
      final jsonList = list.map((p) => {
        'id': p.id,
        'full_name': p.fullName,
        'phone': p.phone,
        'avatar_url': p.avatarUrl,
        'role': p.role.name,
        'status': p.status.name,
        'created_at': p.createdAt?.toIso8601String(),
      }).toList();
      await HiveService.instance.settings.put(_boxAllProfilesKey, jsonEncode(jsonList));
    } catch (_) {}
  }

  /// تحديث حالة الحساب (موافقة / رفض / حظر / إلغاء حظر)
  Future<void> updateProfileStatus(String uid, UserStatus status) async {
    // 1. تحديث في قائمة الطلبات المعلقة
    final currentPending = await fetchPendingProfiles();
    final updatedPending = currentPending.where((p) => p.id != uid).toList();
    await _savePendingLocal(updatedPending);

    // 2. تحديث في قائمة كل الحسابات (للحظر وفك الحظر)
    final currentAll = await fetchAllProfiles();
    final updatedAll = currentAll.map((p) {
      if (p.id == uid) {
        return p.copyWith(status: status);
      }
      return p;
    }).toList();
    await _saveAllProfilesLocal(updatedAll);

    if (!isLive) return;
    try {
      await db.from('profiles').update({'status': status.value}).eq('id', uid);
    } catch (_) {}
  }

  /// جلب الحسابات المعتمدة (للمدير لتغيير الأدوار)
  Future<List<ProfileModel>> fetchApprovedProfiles() async {
    final all = await fetchAllProfiles();
    return all.where((p) => p.status == UserStatus.approved).toList();
  }

  /// تحديث دور الحساب
  Future<void> updateProfileRole(String uid, UserRole role) async {
    final all = await fetchAllProfiles();
    final updated = all.map((p) => p.id == uid ? p.copyWith(role: role) : p).toList();
    await _saveAllProfilesLocal(updated);

    if (!isLive) return;
    try {
      await db.from('profiles').update({'role': role.value}).eq('id', uid);
    } catch (_) {}
  }

  /// أقسام الستوريز
  Future<List<Map<String, dynamic>>> fetchStoryCategories() async {
    if (!isLive) return [];
    final rows = await db
        .from('story_categories')
        .select()
        .order('position', ascending: true);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> createStoryCategory(String name, String? coverUrl) async {
    if (!isLive) return;
    await db.from('story_categories').insert({
      'name': name.trim(),
      if (coverUrl != null && coverUrl.isNotEmpty) 'cover_url': coverUrl.trim(),
      'created_by': user?.id,
    });
  }

  Future<void> updateStoryCategory(
      String id, String name, String? coverUrl) async {
    if (!isLive) return;
    await db.from('story_categories').update({
      'name': name.trim(),
      'cover_url': coverUrl?.trim(),
    }).eq('id', id);
  }

  Future<void> deleteStoryCategory(String id) async {
    if (!isLive) return;
    await db.from('story_categories').delete().eq('id', id);
  }
}

