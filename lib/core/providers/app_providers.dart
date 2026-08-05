import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/contributors/data/contributors_repository.dart';
import '../../features/home/data/stats_repository.dart';
import '../../shared/models/contributor_model.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/profile_model.dart';
import '../../shared/models/stats_snapshot.dart';
import '../config/app_config.dart';
import '../data/supabase_repository.dart';
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

  @override
  AppSession build() {
    if (!AppConfig.isConfigured) return const AppSession();

    final repo = ref.read(authRepositoryProvider);

    // نستمع لتغيّرات المصادقة فتتحدّث الواجهة تلقائياً عند الدخول والخروج
    _sub = repo.authChanges.listen((event) {
      switch (event.event) {
        case AuthChangeEvent.signedOut:
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

    // جلسة محفوظة من تشغيل سابق؟ نحمّل ملفها
    if (repo.isSignedIn && !repo.isAnonymous) {
      _loadProfile();
      return const AppSession(loading: true);
    }
    return const AppSession();
  }

  Future<void> _loadProfile() async {
    final repo = ref.read(authRepositoryProvider);
    try {
      final p = await repo.fetchMyProfile();
      state = AppSession(profile: p);
    } catch (e) {
      state = AppSession(error: arabicError(e));
    }
  }

  /// إعادة قراءة الملف — تُستخدم بعد موافقة المدير مثلاً
  Future<void> refresh() async {
    if (!AppConfig.isConfigured) return;
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

  Future<String?> signUp(String email, String password, String fullName) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final p = await ref
          .read(authRepositoryProvider)
          .signUp(email: email, password: password, fullName: fullName);
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

  /// دخول تجريبي بدور محدّد — يعمل فقط حين لا يكون Supabase مهيّأً
  void demoSignIn(UserRole role) {
    if (AppConfig.isConfigured) return;
    state = AppSession(
      profile: ProfileModel(
        id: 'demo-user',
        fullName: switch (role) {
          UserRole.admin => 'المدير العام (تجريبي)',
          UserRole.finance => 'المسؤول المالي (تجريبي)',
          UserRole.publisher => 'الناشر (تجريبي)',
          UserRole.member => 'عضو (تجريبي)',
        },
        role: role,
        status: UserStatus.approved,
      ),
    );
  }
}

final sessionProvider =
    NotifierProvider<SessionNotifier, AppSession>(SessionNotifier.new);

// ── البيانات ─────────────────────────────────────────────────

// كل مزوّد بيانات مزدوج: مزوّد خام يحمل [CachedResult] (فيه معلومة «من أين
// جاءت البيانات»)، ومزوّد مبسّط تستهلكه الواجهة فتبقى نظيفة. الواجهة تسأل
// مزوّد `‎...IsStale` فقط عندما تريد إظهار شارة «بلا اتصال».

/// إحصائيات الرئيسية. تُعاد قراءتها عند تغيّر الجلسة لأن الصلاحيات تتغيّر.
final statsRawProvider =
    FutureProvider<CachedResult<StatsSnapshot>>((ref) async {
  ref.watch(sessionProvider);
  return ref.read(statsRepositoryProvider).load();
});

final statsProvider = FutureProvider<StatsSnapshot>(
  (ref) async => (await ref.watch(statsRawProvider.future)).data,
);

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
