import 'package:flutter/material.dart';

import '../config/app_permissions_model.dart';
import 'hive_service.dart';

/// الإعدادات المحلية البسيطة: الثيم وقفل البصمة.
/// تُقرأ من صندوق Hive غير المشفّر لأنها لا تحوي بيانات حساسة.
class SettingsStore {
  SettingsStore._();
  static final instance = SettingsStore._();

  static const _kThemeMode = 'theme_mode';
  static const _kBiometricLock = 'biometric_lock';
  static const _kGuestSeen = 'guest_seen';

  ThemeMode get themeMode {
    final v = HiveService.instance.settings.get(_kThemeMode) as String?;
    return switch (v) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.light, // افتراضي: وضع النهاري عند أول تشغيل
    };
  }

  Future<void> setThemeMode(ThemeMode m) =>
      HiveService.instance.settings.put(_kThemeMode, m.name);

  bool get biometricLock =>
      (HiveService.instance.settings.get(_kBiometricLock) as bool?) ?? false;

  Future<void> setBiometricLock(bool v) =>
      HiveService.instance.settings.put(_kBiometricLock, v);

  bool get guestSeen =>
      (HiveService.instance.settings.get(_kGuestSeen) as bool?) ?? false;

  Future<void> setGuestSeen(bool v) =>
      HiveService.instance.settings.put(_kGuestSeen, v);

  static const _kLastLoginTime = 'last_login_time';

  DateTime? get lastLoginTime {
    final v = HiveService.instance.settings.get(_kLastLoginTime) as String?;
    if (v == null) return null;
    return DateTime.tryParse(v);
  }

  Future<void> setLastLoginTime([DateTime? time]) =>
      HiveService.instance.settings.put(
        _kLastLoginTime,
        (time ?? DateTime.now()).toIso8601String(),
      );

  Future<void> clearLastLoginTime() =>
      HiveService.instance.settings.delete(_kLastLoginTime);

  static const _kAppPermissions = 'app_permissions_config';

  AppPermissionsModel get appPermissions {
    final raw = HiveService.instance.settings.get(_kAppPermissions) as String?;
    if (raw == null || raw.isEmpty) return const AppPermissionsModel();
    try {
      return AppPermissionsModel.fromJson(raw);
    } catch (_) {
      return const AppPermissionsModel();
    }
  }

  Future<void> setAppPermissions(AppPermissionsModel permissions) =>
      HiveService.instance.settings.put(_kAppPermissions, permissions.toJson());

  /// هل انتهت صلاحية الجلسة (أكثر من 72 ساعة)؟
  bool get isSessionExpired {
    final t = lastLoginTime;
    if (t == null) return false;
    return DateTime.now().difference(t).inHours >= 72;
  }
}

