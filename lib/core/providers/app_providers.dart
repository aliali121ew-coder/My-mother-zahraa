import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/contributors/data/contributors_repository.dart';
import '../../features/home/data/stats_repository.dart';
import '../../features/posts/data/posts_repository.dart';
import '../../features/posts/data/stories_repository.dart';
import '../../features/purchases/data/purchases_provider.dart';
import '../../features/settings/data/admin_repository.dart';
import '../../shared/models/contributor_model.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/profile_model.dart';
import '../../shared/models/stats_snapshot.dart';
import '../config/app_config.dart';
import '../config/app_permissions_model.dart';
import '../data/supabase_repository.dart';
import '../storage/hive_service.dart';
import '../storage/settings_store.dart';

// ── المستودعات ───────────────────────────────────────────────

final authRepositoryProvider = Provider((_) => AuthRepository());
final statsRepositoryProvider = Provider((_) => StatsRepository());
final contributorsRepositoryProvider = Provider((_) => ContributorsRepository());

// ── الثيم ────────────────────────────────────────────────────

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => SettingsStore.instance.themeMode;

  Future<void> set(ThemeMode m) async {
    state = m;
    await SettingsStore.instance.setThemeMode(m);
  }

  /// تبديل سريع بين الليلي والنهاري
  Future<void> toggle() => set(
        state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
      );
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

// ── صلاحيات التطبيق الديناميكية ──────────────────────────────

class AppPermissionsNotifier extends Notifier<AppPermissionsModel> {
  @override
  AppPermissionsModel build() => SettingsStore.instance.appPermissions;

  Future<void> update(AppPermissionsModel permissions) async {
    state = permissions;
    await SettingsStore.instance.setAppPermissions(permissions);
  }

  Future<void> toggleKey(String key, bool value) async {
    final currentMap = state.toMap();
    currentMap[key] = value;
    final updated = AppPermissionsModel.fromMap(currentMap);
    await update(updated);
  }
}

final appPermissionsProvider =
    NotifierProvider<AppPermissionsNotifier, AppPermissionsModel>(
        AppPermissionsNotifier.new);

// ── الجلسة ───────────────────────────────────────────────────


/// جلسة المستخدم الحالية.
///
/// ثلاث حالات ممكنة:
///  • `loading` — نقرأ الجلسة المخزّنة والملف الشخصي
///  • `profile == null` — **زائر**: يرى المنشورات فقط
///  • `profile != null` — مسجّل، وقد يكون `pending` بانتظار موافقة المدير
@immutable
class AppSession {
  const AppSession({this.profile, this.loading = false, this.error});

  final ProfileModel? profile;
  final bool loading;
  final String? error;

  bool get isGuest => profile == null;
  bool get isApproved => profile?.isActive ?? false;
  bool get isPending => profile?.isPending ?? false;
  bool get isBanned => profile?.isBanned ?? false;
  bool get isAdmin => profile?.role == UserRole.admin;

  /// دور المستخدم — الزائر يُعالَج كعضو بلا صلاحيات
  UserRole get role => profile?.role ?? UserRole.member;

  /// الأرقام والإحصائيات للمعتمدين فقط
  bool get canSeeStats => isApproved;

  AppSession copyWith({bool? loading, String? error, bool clearError = false}) =>
      AppSession(
        profile: profile,
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
      );
}

class SessionNotifier extends Notifier<AppSession> {
  StreamSubscription<AuthState>? _sub;

  /// الملف السابق لمراقبة تغيّر الدور أو الحالة (ثغرة P1: تغيّر صلاحيات
  /// المستخدم دون مسح بيانات جلسة سابقة أعلى صلاحية)
  ProfileModel? _previousProfile;

  @override
  AppSession build() {
    if (!AppConfig.isConfigured) return const AppSession();

    final repo = ref.read(authRepositoryProvider);

    // نستمع لتغيّرات المصادقة فتتحدّث الواجهة تلقائياً عند الدخول والخروج
    _sub = repo.authChanges.listen((event) {
      switch (event.event) {
        case AuthChangeEvent.signedOut:
          // الذاكرة الحساسة تُمسح الآن داخل AuthRepository.signOut()
          _previousProfile = null;
          state = const AppSession();
        case AuthChangeEvent.signedIn:
        case AuthChangeEvent.tokenRefreshed:
        case AuthChangeEvent.userUpdated:
          _loadProfile();
        default:
          break;
      }
    });
    ref.onDispose(() => _sub?.cancel());

    // فحص الجلسة المحفوظة محلياً لتبدأ الجلسة فوراً طالما أن مهلة 72 ساعة لم تنتهِ
    ProfileModel? immediateProfile;
    if (!SettingsStore.instance.isSessionExpired) {
      final localRow = HiveService.instance.settings.get('cached_my_profile');
      if (localRow != null) {
        try {
          final map = jsonDecode(localRow.toString()) as Map<String, dynamic>;
          immediateProfile = ProfileModel.fromJson(map);
        } catch (_) {}
      }
    }

    // تحميل الملف الشخصي المحدّث في الخلفية
    _loadProfile();
    return AppSession(profile: immediateProfile, loading: immediateProfile == null);
  }

  Future<void> _loadProfile() async {
    final repo = ref.read(authRepositoryProvider);
    try {
      final p = await repo.fetchMyProfile();
      _purgeOnRoleOrStatusChange(p);
      state = AppSession(profile: p);
    } catch (e) {
      state = AppSession(error: arabicError(e));
    }
  }

  /// إذا تغيّر الدور أو الحالة مقارنة بآخر ملف معروف (ترقية، تخفيض، حظر،
  /// إبطال اعتماد) نمسح البيانات الحساسة المخزّنة محلياً: بيانات جلسة
  /// سابقة بصلاحيات أعلى قد لا تسمح RLS بإعادة قراءتها، فلو بقيت على
  /// الجهاز انكشفت لمالكها غير المخوّل.
  void _purgeOnRoleOrStatusChange(ProfileModel? p) {
    final prev = _previousProfile;
    _previousProfile = p;
    if (prev == null) return;
    final roleChanged = p?.role != prev.role;
    final statusChanged = p?.status != prev.status;
    final identityChanged = p?.id != prev.id;
    if (roleChanged || statusChanged || identityChanged) {
      HiveService.instance.clearSensitiveCache();
    }
  }

  /// إعادة قراءة الملف — تُستخدم بعد تعديل الملف الشخصي أو موافقة المدير
  Future<void> refresh() async {
    state = state.copyWith(loading: true, clearError: true);
    await _loadProfile();
  }

  /// يعيد null عند النجاح، أو رسالة خطأ عربية عند الفشل
  Future<String?> signIn(String email, String password) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final p = await ref
          .read(authRepositoryProvider)
          .signIn(email: email, password: password);
      state = AppSession(profile: p);
      return null;
    } catch (e) {
      state = const AppSession();
      return arabicError(e);
    }
  }

  Future<String?> signUp(
    String email,
    String password,
    String fullName, {
    String? phone,
  }) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final p = await ref.read(authRepositoryProvider).signUp(
            email: email,
            password: password,
            fullName: fullName,
            phone: phone,
          );
      state = AppSession(profile: p);
      return null;
    } catch (e) {
      state = const AppSession();
      return arabicError(e);
    }
  }

  Future<void> signOut() async {
    if (AppConfig.isConfigured) {
      await ref.read(authRepositoryProvider).signOut();
    }
    state = const AppSession();
  }

  /// دخول تجريبي بدور محدّد — يعمل دائماً للتجربة والإدارة السريعة
  void demoSignIn(UserRole role) {
    final demoProfile = ProfileModel(
      id: 'demo-user-${role.name}',
      fullName: switch (role) {
        UserRole.admin => 'المدير العام',
        UserRole.finance => 'المسؤول المالي (أمين الصندوق)',
        UserRole.publisher => 'الناشر الإعلامي',
        UserRole.member => 'عضو موثق',
      },
      phone: '07700000000',
      role: role,
      status: UserStatus.approved,
    );
    state = AppSession(profile: demoProfile);
  }
}

final sessionProvider =
    NotifierProvider<SessionNotifier, AppSession>(SessionNotifier.new);

// ── البيانات ─────────────────────────────────────────────────

// كل مزوّد بيانات مزدوج: مزوّد خام يحمل [CachedResult] (فيه معلومة «من أين
// جاءت البيانات»)، ومزوّد مبسّط تستهلكه الواجهة فتبقى نظيفة. الواجهة تسأل
// مزوّد `‎...IsStale` فقط عندما تريد إظهار شارة «بلا اتصال».

/// إحصائيات الرئيسية. تُعاد قراءتها عند تغيّر الجلسة أو قائمة المساهمين لضمان دقة الأرقام 100%.
final statsRawProvider =
    FutureProvider<CachedResult<StatsSnapshot>>((ref) async {
  ref.watch(sessionProvider);
  return ref.read(statsRepositoryProvider).load();
});

final statsProvider = FutureProvider<StatsSnapshot>((ref) async {
  // مراقبة قائمة المساهمين والمشتريات بحيث إذا أضيف مشترك أو متبرع يتحدث الكارت الرئيسي فوراً
  final allContribs = ref.watch(allContributorsProvider).valueOrNull;
  final purchases = ref.watch(purchasesProvider).valueOrNull;

  final serverStats = (await ref.watch(statsRawProvider.future)).data;

  if (allContribs == null || allContribs.isEmpty) {
    return serverStats;
  }

  final cache = HiveService.instance;

  num getContributorTotal(ContributorModel c) {
    num ledgerSum = 0;
    bool hasLedger = false;
    for (int y = 2024; y <= 2030; y++) {
      final boxKey = 'ledger_${c.id}_$y';
      var raw = cache.readOne(AppConfig.boxPayments, boxKey);
      raw ??= cache.readOne(AppConfig.boxContributors, boxKey);
      if (raw != null) {
        hasLedger = true;
        for (final e in raw.values) {
          if (e is Map && e['is_paid'] == true) {
            ledgerSum += (e['amount'] as num? ?? 0);
          }
        }
      }
    }
    return hasLedger ? ledgerSum : c.totalPaid;
  }

  // حساب دقيق وحي لكافة الحقول
  final subs = allContribs.where((c) => c.isSubscriber).toList();
  final dons = allContribs.where((c) => c.type == ContributorType.donor).toList();
  final inKinds = allContribs.where((c) => c.type == ContributorType.inKind).toList();

  final subsTotal = subs.fold<num>(0, (s, c) => s + getContributorTotal(c));
  final donsTotal = dons.fold<num>(0, (s, c) => s + getContributorTotal(c));
  final overdueCount = subs.where((c) => c.isOverdue).length;

  final purchasesTotal = purchases?.fold<num>(0, (sum, p) => sum + p.amount) ?? serverStats.expensesTotal;

  return StatsSnapshot(
    subscriptionsTotal: subsTotal > 0 ? subsTotal : serverStats.subscriptionsTotal,
    donationsTotal: donsTotal > 0 ? donsTotal : serverStats.donationsTotal,
    expensesTotal: purchasesTotal > 0 ? purchasesTotal : serverStats.expensesTotal,
    subscribersCount: subs.isNotEmpty ? subs.length : serverStats.subscribersCount,
    donorsCount: dons.isNotEmpty ? dons.length : serverStats.donorsCount,
    inKindCount: inKinds.isNotEmpty ? inKinds.length : serverStats.inKindCount,
    overdueCount: overdueCount,
    updatedAt: DateTime.now(),
  );
});

final statsIsStaleProvider = Provider<bool>(
  (ref) => ref.watch(statsRawProvider).valueOrNull?.isStale ?? false,
);

final donorsRawProvider =
    FutureProvider<CachedResult<List<ContributorModel>>>((ref) async {
  ref.watch(sessionProvider);
  return ref.read(contributorsRepositoryProvider).load(ContributorType.donor);
});

final donorsProvider = FutureProvider<List<ContributorModel>>(
  (ref) async => (await ref.watch(donorsRawProvider.future)).data,
);

final subscribersRawProvider =
    FutureProvider<CachedResult<List<ContributorModel>>>((ref) async {
  ref.watch(sessionProvider);
  return ref
      .read(contributorsRepositoryProvider)
      .load(ContributorType.subscriber);
});

final subscribersProvider = FutureProvider<List<ContributorModel>>(
  (ref) async => (await ref.watch(subscribersRawProvider.future)).data,
);

final allContributorsRawProvider =
    FutureProvider<CachedResult<List<ContributorModel>>>((ref) async {
  ref.watch(sessionProvider);
  return ref.read(contributorsRepositoryProvider).load(null);
});

final allContributorsProvider = FutureProvider<List<ContributorModel>>(
  (ref) async => (await ref.watch(allContributorsRawProvider.future)).data,
);

/// هل أي من القوائم معروضة من المخزن المحلي بلا اتصال؟
final dataIsStaleProvider = Provider<bool>((ref) {
  final s = ref.watch(statsRawProvider).valueOrNull?.isStale ?? false;
  final d = ref.watch(donorsRawProvider).valueOrNull?.isStale ?? false;
  final b = ref.watch(subscribersRawProvider).valueOrNull?.isStale ?? false;
  return s || d || b;
});

/// تقدم إخفاء/إظهار أشرطة التنقل بنسبة متصلة من 0.0 (ظاهر 100%) إلى 1.0 (مخفي 10% شفافية) حسب حركة اللمس
final scrollProgressProvider = StateProvider<double>((ref) => 0.0);

/// التوافقية مع الحالة البولينية
final scrollBarsVisibleProvider = StateProvider<bool>((ref) => true);

/// تحديث شامل لكافة بيانات التطبيق من الخادم وقاعدة البيانات بمجرد فتح التطبيق أو العودة إليه
Future<void> refreshAllAppData(WidgetRef ref) async {
  try {
    ref.invalidate(statsRawProvider);
    ref.invalidate(allContributorsRawProvider);
    ref.invalidate(subscribersRawProvider);
    ref.invalidate(donorsRawProvider);
    try {
      ref.read(purchasesProvider.notifier).load();
    } catch (_) {}
    try {
      ref.read(postsProvider.notifier).refresh();
    } catch (_) {}
    try {
      ref.read(storiesProvider.notifier).refresh();
    } catch (_) {}
    try {
      ref.read(adminUsersProvider.notifier).refresh();
    } catch (_) {}
    await ref.read(sessionProvider.notifier).refresh();
  } catch (_) {}
}

/// تحديث شامل باستخدام حاوية الـ ProviderContainer
Future<void> refreshAllAppDataWithContainer(ProviderContainer container) async {
  try {
    container.invalidate(statsRawProvider);
    container.invalidate(allContributorsRawProvider);
    container.invalidate(subscribersRawProvider);
    container.invalidate(donorsRawProvider);
    try {
      container.read(purchasesProvider.notifier).load();
    } catch (_) {}
    try {
      container.read(postsProvider.notifier).refresh();
    } catch (_) {}
    try {
      container.read(storiesProvider.notifier).refresh();
    } catch (_) {}
    try {
      container.read(adminUsersProvider.notifier).refresh();
    } catch (_) {}
    await container.read(sessionProvider.notifier).refresh();
  } catch (_) {}
}


