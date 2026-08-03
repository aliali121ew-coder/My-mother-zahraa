import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/home/data/demo_data.dart';
import '../../shared/models/contributor_model.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/profile_model.dart';
import '../../shared/models/stats_snapshot.dart';
import '../config/app_config.dart';
import '../storage/settings_store.dart';

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

/// جلسة المستخدم الحالية. `profile == null` تعني **زائر** يرى المنشورات فقط.
class AppSession {
  const AppSession({this.profile});

  final ProfileModel? profile;

  bool get isGuest => profile == null;
  bool get isApproved => profile?.isActive ?? false;
  bool get isPending => profile?.isPending ?? false;

  /// دور المستخدم — الزائر يُعالَج كعضو بلا صلاحيات إضافية
  UserRole get role => profile?.role ?? UserRole.member;

  /// هل يُسمح له برؤية الأرقام والإحصائيات؟ الزائر لا، والمعتمد نعم.
  bool get canSeeStats => isApproved;
}

class SessionNotifier extends Notifier<AppSession> {
  @override
  AppSession build() => const AppSession();

  void signIn(ProfileModel p) => state = AppSession(profile: p);
  void signOut() => state = const AppSession();

  /// دخول تجريبي بدور محدّد — يعمل فقط حين لا يكون Supabase مهيّأً،
  /// ليتمكّن المستخدم من تجربة كل الأدوار في الـAPK قبل إعداد قاعدة البيانات.
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

/// إحصائيات الرئيسية. تُقرأ من Supabase عبر RPC مُجمَّع حين يكون مهيّأً،
/// ومن البيانات التجريبية خلاف ذلك.
final statsProvider = FutureProvider<StatsSnapshot>((ref) async {
  if (!AppConfig.isConfigured) {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return DemoData.stats;
  }
  // TODO(supabase): استدعاء RPC get_stats بعد تهيئة المشروع
  return DemoData.stats;
});

/// المتبرعون مرتّبون بالأعلى مبلغاً — كما طُلب في القسم الثاني
final donorsProvider = FutureProvider<List<ContributorModel>>((ref) async {
  if (!AppConfig.isConfigured) {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final list = [...DemoData.donors]
      ..sort((a, b) => b.totalPaid.compareTo(a.totalPaid));
    return list;
  }
  final list = [...DemoData.donors]
    ..sort((a, b) => b.totalPaid.compareTo(a.totalPaid));
  return list;
});

final subscribersProvider = FutureProvider<List<ContributorModel>>((ref) async {
  if (!AppConfig.isConfigured) {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return DemoData.subscribers;
  }
  return DemoData.subscribers;
});
