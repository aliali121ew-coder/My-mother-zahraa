import 'enums.dart';

/// المساهم: مشترك أو متبرع. كلاهما مانح، والتمييز بحقل [type].
///
/// حقول الاشتراك (المبلغ ونوع الاشتراك) تُستخدم للمشتركين فقط،
/// وتبقى فارغة للمتبرعين الذين تُسجَّل تبرعاتهم في جدول التبرعات.
class ContributorModel {
  const ContributorModel({
    required this.id,
    required this.type,
    required this.fullName,
    this.phone,
    this.photoUrl,
    this.notes,
    this.subscriptionAmount,
    this.subscriptionType,
    this.lastPaymentAt,
    this.isLateOverride,
    this.totalPaid = 0,
    this.createdAt,
    this.updatedAt,
    this.pendingSync = false,
  });

  final String id;
  final ContributorType type;
  final String fullName;
  final String? phone;
  final String? photoUrl;
  final String? notes;

  /// مبلغ الاشتراك الدوري — للمشتركين
  final num? subscriptionAmount;

  /// شهري أو سنوي — للمشتركين
  final SubscriptionType? subscriptionType;

  /// تاريخ آخر دفعة — أساس حساب التأخير
  final DateTime? lastPaymentAt;

  /// تجاوز المدير اليدوي لحالة التأخير المحسوبة تلقائياً.
  /// null = اعتمد الحساب التلقائي، true = متأخر، false = مسدد.
  final bool? isLateOverride;

  /// مجموع ما دفعه فعلياً (اشتراكات أو تبرعات نقدية)
  final num totalPaid;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// true إذا أُنشئ أو عُدّل أوفلاين وينتظر المزامنة
  final bool pendingSync;

  bool get isSubscriber => type == ContributorType.subscriber;

  /// حالة السداد: تلقائية من آخر دفعة ونوع الاشتراك، ويتجاوزها المدير يدوياً.
  PaymentStatus get paymentStatus {
    if (isLateOverride != null) {
      return isLateOverride! ? PaymentStatus.overdue : PaymentStatus.paid;
    }
    if (!isSubscriber) return PaymentStatus.paid;
    final t = subscriptionType ?? SubscriptionType.monthly;
    if (lastPaymentAt == null) return PaymentStatus.overdue;
    final elapsed = DateTime.now().difference(lastPaymentAt!).inDays;
    return elapsed > t.days ? PaymentStatus.overdue : PaymentStatus.paid;
  }

  bool get isOverdue => paymentStatus == PaymentStatus.overdue;

  /// كم يوماً تأخّر عن موعد استحقاقه (صفر إن كان مسدداً)
  int get daysOverdue {
    if (!isOverdue || lastPaymentAt == null) return 0;
    final t = subscriptionType ?? SubscriptionType.monthly;
    final elapsed = DateTime.now().difference(lastPaymentAt!).inDays;
    return elapsed - t.days;
  }

  factory ContributorModel.fromJson(Map<String, dynamic> j) => ContributorModel(
        id: j['id'].toString(),
        type: ContributorType.fromValue(j['type'] as String?),
        fullName: (j['full_name'] as String?) ?? 'بلا اسم',
        phone: j['phone'] as String?,
        photoUrl: j['photo_url'] as String?,
        notes: j['notes'] as String?,
        subscriptionAmount: j['subscription_amount'] as num?,
        subscriptionType: j['subscription_type'] == null
            ? null
            : SubscriptionType.fromValue(j['subscription_type'] as String?),
        lastPaymentAt: _date(j['last_payment_at']),
        isLateOverride: j['is_late_override'] as bool?,
        totalPaid: (j['total_paid'] as num?) ?? 0,
        createdAt: _date(j['created_at']),
        updatedAt: _date(j['updated_at']),
        pendingSync: (j['pending_sync'] as bool?) ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.value,
        'full_name': fullName,
        'phone': phone,
        'photo_url': photoUrl,
        'notes': notes,
        'subscription_amount': subscriptionAmount,
        'subscription_type': subscriptionType?.value,
        'last_payment_at': lastPaymentAt?.toIso8601String(),
        'is_late_override': isLateOverride,
        'total_paid': totalPaid,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  /// الحقول القابلة للكتابة في قاعدة البيانات (بلا الحقول المحسوبة)
  Map<String, dynamic> toWriteJson() => {
        'id': id,
        'type': type.value,
        'full_name': fullName,
        'phone': phone,
        'photo_url': photoUrl,
        'notes': notes,
        'subscription_amount': subscriptionAmount,
        'subscription_type': subscriptionType?.value,
        'is_late_override': isLateOverride,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

  ContributorModel copyWith({
    ContributorType? type,
    String? fullName,
    String? phone,
    String? photoUrl,
    String? notes,
    num? subscriptionAmount,
    SubscriptionType? subscriptionType,
    DateTime? lastPaymentAt,
    bool? isLateOverride,
    bool clearOverride = false,
    num? totalPaid,
    bool? pendingSync,
  }) =>
      ContributorModel(
        id: id,
        type: type ?? this.type,
        fullName: fullName ?? this.fullName,
        phone: phone ?? this.phone,
        photoUrl: photoUrl ?? this.photoUrl,
        notes: notes ?? this.notes,
        subscriptionAmount: subscriptionAmount ?? this.subscriptionAmount,
        subscriptionType: subscriptionType ?? this.subscriptionType,
        lastPaymentAt: lastPaymentAt ?? this.lastPaymentAt,
        isLateOverride: clearOverride ? null : (isLateOverride ?? this.isLateOverride),
        totalPaid: totalPaid ?? this.totalPaid,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
        pendingSync: pendingSync ?? this.pendingSync,
      );
}

DateTime? _date(Object? v) =>
    v == null ? null : DateTime.tryParse(v.toString());
