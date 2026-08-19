import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/data/supabase_repository.dart';
import '../../../core/storage/hive_service.dart';
import '../../../core/storage/settings_store.dart';
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
    final cleanEmail = email.trim().toLowerCase();
    await db.auth.signUp(
      email: cleanEmail,
      password: password,
      data: {
        'full_name': fullName.trim(),
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      },
    );
    await SettingsStore.instance.setLastLoginTime();
    return fetchMyProfile(fallbackEmail: cleanEmail);
  }

  Future<ProfileModel?> signIn({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    await db.auth.signInWithPassword(
      email: cleanEmail,
      password: password,
    );
    await SettingsStore.instance.setLastLoginTime();
    return fetchMyProfile(fallbackEmail: cleanEmail);
  }

  /// دخول مجهول — يُستخدم فقط لتمكين الزائر من الإعجاب بالمنشورات.
  /// لا يُنشأ له ملف شخصي ولا يستطيع التعليق (سياسة RLS تمنع الجلسات المجهولة).
  Future<void> signInAnonymously() async {
    if (isSignedIn) return;
    await db.auth.signInAnonymously();
  }

  /// تسجيل الخروج مع **مسح البيانات الحساسة والملف الشخصي محلياً ومشفراً** أولاً
  Future<void> signOut() async {
    await cache.clearSensitiveCache();
    try {
      if (HiveService.instance.isReady) {
        final encryptedBox = HiveService.instance.box(AppConfig.boxAdminUsers);
        await encryptedBox.delete('cached_my_profile');
      }
    } catch (_) {}
    await HiveService.instance.settings.delete('cached_my_profile');
    await SettingsStore.instance.clearLastLoginTime();
    return db.auth.signOut();
  }

  /// حفظ الملف الشخصي محلياً بالتخزين المشفر AES-256
  Future<void> _cacheMyProfile(ProfileModel p) async {
    final encoded = jsonEncode(p.toJson());
    try {
      if (HiveService.instance.isReady) {
        final encryptedBox = HiveService.instance.box(AppConfig.boxAdminUsers);
        await encryptedBox.put('cached_my_profile', encoded);
      }
    } catch (_) {}
    await HiveService.instance.settings.put('cached_my_profile', encoded);
  }

  /// قراءة الملف الشخصي من التخزين المشفر أولاً ثم التخزين الاحتياطي
  ProfileModel? _readCachedMyProfile(String? currentEmail) {
    try {
      if (HiveService.instance.isReady) {
        final encryptedBox = HiveService.instance.box(AppConfig.boxAdminUsers);
        final encryptedRow = encryptedBox.get('cached_my_profile');
        if (encryptedRow != null && encryptedRow.trim().isNotEmpty) {
          final map = jsonDecode(encryptedRow) as Map<String, dynamic>;
          return ProfileModel.fromJson(map, email: currentEmail);
        }
      }
      final fallbackRow = HiveService.instance.settings.get('cached_my_profile');
      if (fallbackRow != null) {
        final map = jsonDecode(fallbackRow.toString()) as Map<String, dynamic>;
        return ProfileModel.fromJson(map, email: currentEmail);
      }
    } catch (_) {}
    return null;
  }

  Future<void> resetPassword(String email) =>
      db.auth.resetPasswordForEmail(email.trim().toLowerCase());

  Future<void> changePassword(String newPassword) =>
      db.auth.updateUser(UserAttributes(password: newPassword));

  /// يقرأ ملف المستخدم الحالي. يعيد null للجلسات المجهولة أو إن لم يُنشأ بعد.
  Future<ProfileModel?> fetchMyProfile({String? fallbackEmail}) async {
    // 0. التحقق من انتهاء صلاحية الـ 72 ساعة
    if (SettingsStore.instance.isSessionExpired) {
      await signOut();
      return null;
    }

    final currentEmail = user?.email ?? fallbackEmail;

    // 1. فحص المخزن المحلي المشفّر أولاً لضمان عدم تسجيل الخروج عند انقطاع الاتصال أو بطء الشبكة
    ProfileModel? localProfile = _readCachedMyProfile(currentEmail);

    if (localProfile != null && SettingsStore.instance.lastLoginTime == null) {
      await SettingsStore.instance.setLastLoginTime();
    }

    final uid = user?.id;
    if (uid == null || isAnonymous) {
      return localProfile;
    }

    try {
      final row = await db
          .from('profiles')
          .select()
          .eq('id', uid)
          .maybeSingle();

      if (row == null) {
        return localProfile;
      }

      final profile = ProfileModel.fromJson(row, email: currentEmail);

      // حفظ في المخزن المحلي المشفّر
      await _cacheMyProfile(profile);
      return profile;
    } catch (_) {
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

    // حفظ فوري في المخزن المحلي المشفّر
    await _cacheMyProfile(updated);

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
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 3));
      final remoteList = (rows as List)
          .map((r) => ProfileModel.fromJson(r as Map<String, dynamic>))
          .toList();
      
      // دمج الذكي بين المحلي والسحابي لضمان عدم ضياع البريد والهاتف
      final merged = <String, ProfileModel>{};
      for (final p in localList) {
        merged[p.id] = p;
      }
      for (final p in remoteList) {
        // البحث عن بيانات محلية بنفس المعرف أو بنفس الاسم
        ProfileModel? local = merged[p.id];
        if (local == null) {
          try {
            local = localList.firstWhere((lp) => lp.fullName.trim() == p.fullName.trim());
          } catch (_) {}
        }

        final combinedEmail = (p.email != null && p.email!.isNotEmpty)
            ? p.email
            : local?.email;
        final combinedPhone = (p.phone != null && p.phone!.isNotEmpty)
            ? p.phone
            : local?.phone;

        merged[p.id] = p.copyWith(
          email: combinedEmail,
          phone: combinedPhone,
        );
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
        'email': p.email,
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
    String? id,
    String? phone,
    String? email,
  }) async {
    final current = await fetchPendingProfiles();
    final reqId = id ?? 'req_${DateTime.now().millisecondsSinceEpoch}';
    final newReq = ProfileModel(
      id: reqId,
      fullName: fullName,
      phone: phone,
      email: email,
      role: UserRole.member,
      status: UserStatus.pending,
      createdAt: DateTime.now(),
    );
    final updated = [
      newReq,
      ...current.where((p) => p.id != reqId && p.fullName != fullName),
    ];
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
            email: 'ahmed@gmail.com',
            role: UserRole.member,
            status: UserStatus.banned,
            createdAt: DateTime.now().subtract(const Duration(days: 3)),
          ),
          ProfileModel(
            id: 'user_1',
            fullName: 'مدير الموكب',
            phone: '07700000000',
            email: 'admin@mawkib.org',
            role: UserRole.admin,
            status: UserStatus.approved,
            createdAt: DateTime.now().subtract(const Duration(days: 30)),
          ),
          ProfileModel(
            id: 'user_2',
            fullName: 'حسين عادل الخفاجي',
            phone: '07819988776',
            email: 'hussein@gmail.com',
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
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 3));
      final remoteList = (rows as List)
          .map((r) => ProfileModel.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();
      
      // دمج الذكي مع البيانات المحلية لضمان عدم ضياع التعديلات المحلية
      final merged = <String, ProfileModel>{};
      for (final p in localList) {
        merged[p.id] = p;
      }
      for (final p in remoteList) {
        merged[p.id] = p;
      }
      final result = merged.values.toList();
      if (result.isNotEmpty) {
        await _saveAllProfilesLocal(result);
        return result;
      }
    } catch (_) {}

    if (localList.isEmpty) {
      localList = [
        ProfileModel(
          id: 'ban_1',
          fullName: 'أحمد جاسم الكعبي',
          phone: '07712348899',
          email: 'ahmed@gmail.com',
          role: UserRole.member,
          status: UserStatus.banned,
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
        ProfileModel(
          id: 'user_1',
          fullName: 'مدير الموكب',
          phone: '07700000000',
          email: 'admin@mawkib.org',
          role: UserRole.admin,
          status: UserStatus.approved,
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
        ),
        ProfileModel(
          id: 'user_2',
          fullName: 'حسين عادل الخفاجي',
          phone: '07819988776',
          email: 'hussein@gmail.com',
          role: UserRole.member,
          status: UserStatus.approved,
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
        ),
      ];
      await _saveAllProfilesLocal(localList);
    }
    return localList;
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
    // 1. تحديث فوري في قائمة الطلبات المعلقة
    final currentPending = await fetchPendingProfiles();
    final updatedPending = currentPending.where((p) => p.id != uid).toList();
    await _savePendingLocal(updatedPending);

    // 2. تحديث فوري في قائمة كل الحسابات (للحظر وفك الحظر)
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
      await db
          .from('profiles')
          .update({'status': status.value})
          .eq('id', uid)
          .timeout(const Duration(seconds: 3));
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
      await db
          .from('profiles')
          .update({'role': role.value})
          .eq('id', uid)
          .timeout(const Duration(seconds: 3));
    } catch (_) {}
  }

  /// أقسام الستوريز
  Future<List<Map<String, dynamic>>> fetchStoryCategories() async {
    if (!isLive) return [];
    try {
      final rows = await db
          .from('story_categories')
          .select()
          .order('position', ascending: true)
          .timeout(const Duration(seconds: 3));
      return List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      return [];
    }
  }

  Future<void> createStoryCategory(String name, String? coverUrl) async {
    if (!isLive) return;
    try {
      await db.from('story_categories').insert({
        'name': name.trim(),
        if (coverUrl != null && coverUrl.isNotEmpty) 'cover_url': coverUrl.trim(),
        'created_by': user?.id,
      }).timeout(const Duration(seconds: 3));
    } catch (_) {}
  }

  Future<void> updateStoryCategory(
      String id, String name, String? coverUrl) async {
    if (!isLive) return;
    try {
      await db.from('story_categories').update({
        'name': name.trim(),
        'cover_url': coverUrl?.trim(),
      }).eq('id', id).timeout(const Duration(seconds: 3));
    } catch (_) {}
  }

  Future<void> deleteStoryCategory(String id) async {
    if (!isLive) return;
    try {
      await db.from('story_categories').delete().eq('id', id).timeout(const Duration(seconds: 3));
    } catch (_) {}
  }
}

