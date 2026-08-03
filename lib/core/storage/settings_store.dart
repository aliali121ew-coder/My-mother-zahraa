import 'package:flutter/material.dart';

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
      _ => ThemeMode.system,
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
}
