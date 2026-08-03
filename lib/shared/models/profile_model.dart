import 'enums.dart';

/// ملف المستخدم — مرتبط بـ auth.users في Supabase عبر نفس المعرّف.
class ProfileModel {
  const ProfileModel({
    required this.id,
    required this.fullName,
    this.phone,
    this.avatarUrl,
    this.role = UserRole.member,
    this.status = UserStatus.pending,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String fullName;
  final String? phone;
  final String? avatarUrl;
  final UserRole role;
  final UserStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// هل يستطيع هذا المستخدم استخدام التطبيق فعلياً؟
  bool get isActive => status == UserStatus.approved;
  bool get isPending => status == UserStatus.pending;
  bool get isBanned => status == UserStatus.banned;

  factory ProfileModel.fromJson(Map<String, dynamic> j) => ProfileModel(
        id: j['id'] as String,
        fullName: (j['full_name'] as String?)?.trim().isNotEmpty == true
            ? j['full_name'] as String
            : 'مستخدم',
        phone: j['phone'] as String?,
        avatarUrl: j['avatar_url'] as String?,
        role: UserRole.fromValue(j['role'] as String?),
        status: UserStatus.fromValue(j['status'] as String?),
        createdAt: _date(j['created_at']),
        updatedAt: _date(j['updated_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'phone': phone,
        'avatar_url': avatarUrl,
        'role': role.value,
        'status': status.value,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  ProfileModel copyWith({
    String? fullName,
    String? phone,
    String? avatarUrl,
    UserRole? role,
    UserStatus? status,
  }) =>
      ProfileModel(
        id: id,
        fullName: fullName ?? this.fullName,
        phone: phone ?? this.phone,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        role: role ?? this.role,
        status: status ?? this.status,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

DateTime? _date(Object? v) =>
    v == null ? null : DateTime.tryParse(v.toString());
