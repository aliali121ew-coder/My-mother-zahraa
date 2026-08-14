import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import '../storage/hive_service.dart';

/// خدمة البصمة لقفل التطبيق بالبصمة / الوجه.
class BiometricService {
  BiometricService._();
  static final BiometricService instance = BiometricService._();

  final LocalAuthentication _auth = LocalAuthentication();
  static const _keyBiometric = 'biometric_enabled';

  /// هل تفعيل البصمة مُشغّل من المستخدم؟
  bool get isBiometricEnabled {
    final val = HiveService.instance.settings
        .get(_keyBiometric, defaultValue: false);
    return val == true;
  }

  /// تبديل حالة تفعيل البصمة
  Future<bool> setBiometricEnabled(bool enabled) async {
    if (enabled) {
      final available = await isBiometricsAvailable();
      if (!available) return false;
      final authenticated = await authenticate('تأكيد البصمة لتفعيل قفل التطبيق');
      if (!authenticated) return false;
    }
    await HiveService.instance.settings.put(_keyBiometric, enabled);
    return true;
  }

  /// هل الجهاز يدعم البصمة أو التعرف على الوجه؟
  Future<bool> isBiometricsAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck || isSupported;
    } on PlatformException {
      return false;
    }
  }

  /// طلب البصمة من المستخدم
  Future<bool> authenticate([String reason = 'يرجى التبصيم لفتح التطبيق']) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
      );
    } on PlatformException {
      return false;
    }
  }
}
