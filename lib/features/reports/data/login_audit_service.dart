import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/hive_service.dart';

/// نموذج تسجيل حركة دخول أو زيارة
class LoginAuditItem {
  const LoginAuditItem({
    required this.id,
    required this.accountName,
    required this.emailOrPhone,
    required this.roleName,
    required this.timestamp,
    required this.avatarUrl,
    required this.deviceInfo,
  });

  final String id;
  final String accountName;
  final String emailOrPhone;
  final String roleName;
  final DateTime timestamp;
  final String? avatarUrl;
  final String? deviceInfo;

  Map<String, dynamic> toJson() => {
        'id': id,
        'account_name': accountName,
        'email_or_phone': emailOrPhone,
        'role_name': roleName,
        'timestamp': timestamp.toIso8601String(),
        'avatar_url': avatarUrl,
        'device_info': deviceInfo,
      };

  factory LoginAuditItem.fromJson(Map<String, dynamic> json) => LoginAuditItem(
        id: json['id']?.toString() ?? '',
        accountName: json['account_name']?.toString() ?? 'مستخدم',
        emailOrPhone: json['email_or_phone']?.toString() ?? '',
        roleName: json['role_name']?.toString() ?? 'زائر',
        timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
        avatarUrl: json['avatar_url']?.toString(),
        deviceInfo: json['device_info']?.toString(),
      );
}

final loginAuditProvider = StateNotifierProvider<LoginAuditNotifier, List<LoginAuditItem>>((ref) {
  return LoginAuditNotifier();
});

class LoginAuditNotifier extends StateNotifier<List<LoginAuditItem>> {
  LoginAuditNotifier() : super([]) {
    loadLogs();
  }

  static const _boxKey = 'login_audit_logs_v1';

  void loadLogs() {
    try {
      final raw = HiveService.instance.settings.get(_boxKey);
      if (raw != null) {
        final list = (jsonDecode(raw.toString()) as List)
            .map((e) => LoginAuditItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        state = list;
        return;
      }
    } catch (_) {}

    // بيانات افتراضية أولية عند البدء إذا لم توجد
    state = [
      LoginAuditItem(
        id: '1',
        accountName: 'مدير الموكب الرئيسي',
        emailOrPhone: 'admin@mawkib.org',
        roleName: 'مدير النظام',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        avatarUrl: null,
        deviceInfo: 'تطبيق موكب أمنا الزهراء - جلسة نشطة',
      ),
      LoginAuditItem(
        id: '2',
        accountName: 'خادم الموكب (أمين الصندوق)',
        emailOrPhone: '07701234567',
        roleName: 'أمين الصندوق',
        timestamp: DateTime.now().subtract(const Duration(hours: 3, minutes: 12)),
        avatarUrl: null,
        deviceInfo: 'تسجيل دخول موثّق',
      ),
      LoginAuditItem(
        id: '3',
        accountName: 'زائر الموكب',
        emailOrPhone: 'guest_session',
        roleName: 'زائر / مشاهد',
        timestamp: DateTime.now().subtract(const Duration(hours: 8, minutes: 45)),
        avatarUrl: null,
        deviceInfo: 'تصفح المنشورات والتغطيات',
      ),
      LoginAuditItem(
        id: '4',
        accountName: 'لجنة المشتريات والتجهيز',
        emailOrPhone: 'purchases@mawkib.org',
        roleName: 'مسؤول المشتريات',
        timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
        avatarUrl: null,
        deviceInfo: 'تسجيل دخول موثّق',
      ),
    ];
  }

  Future<void> recordLogin({
    required String accountName,
    required String emailOrPhone,
    required String roleName,
    String? avatarUrl,
    String? deviceInfo,
  }) async {
    final newItem = LoginAuditItem(
      id: 'log_${DateTime.now().millisecondsSinceEpoch}',
      accountName: accountName,
      emailOrPhone: emailOrPhone,
      roleName: roleName,
      timestamp: DateTime.now(),
      avatarUrl: avatarUrl,
      deviceInfo: deviceInfo ?? 'تسجيل دخول موثّق',
    );

    final updated = [newItem, ...state];
    state = updated;

    try {
      final jsonList = updated.take(150).map((e) => e.toJson()).toList();
      await HiveService.instance.settings.put(_boxKey, jsonEncode(jsonList));
    } catch (_) {}
  }

  Future<void> clearLogs() async {
    state = [];
    try {
      await HiveService.instance.settings.delete(_boxKey);
    } catch (_) {}
  }
}
