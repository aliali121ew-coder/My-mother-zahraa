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
    this.address,
    this.subscriptionAmount,
    this.subscriptionType,
    this.lastPaymentAt,
    this.isLateOverride,
    this.totalPaid = 0,
    this.createdAt,
    this.updatedAt,
    this.pendingSync = false,
    this.latestDonationDesc,
  });

  final String id;
  final ContributorType type;
  final String fullName;
  final String? phone;
  final String? photoUrl;
  final String? notes;

  /// تفاصيل أحدث تبرع عيني (مثل: مواد غذائية - فواكة عدد 1) ليتم عرضها في الجداول.
  final String? latestDonationDesc;

  /// عنوان السكن أو المنطقة
  final String? address;

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

  /// تاريخ نهاية فترة الاشتراك المدفوعة
  DateTime? get paidPeriodEndDate {
    if (lastPaymentAt == null) return null;
    final lp = lastPaymentAt!;
    final t = subscriptionType ?? SubscriptionType.monthly;
    if (t == SubscriptionType.monthly) {
      return DateTime(lp.year, lp.month + 1, lp.day, 23, 59, 59);
    } else {
      return DateTime(lp.year + 1, lp.month, lp.day, 23, 59, 59);
    }
  }

  /// تاريخ نهاية فترة السماح (يوم 10 من الشهر الجديد للشهري، و30 يوماً للسنوي)
  DateTime? get graceCutoffDate {
    if (lastPaymentAt == null) return null;
    final lp = lastPaymentAt!;
    final t = subscriptionType ?? SubscriptionType.monthly;
    if (t == SubscriptionType.monthly) {
      final paidEnd = DateTime(lp.year, lp.month + 1, lp.day, 23, 59, 59);
      return DateTime(paidEnd.year, paidEnd.month + 1, 10, 23, 59, 59);
    } else {
      final paidEnd = DateTime(lp.year + 1, lp.month, lp.day, 23, 59, 59);
      return paidEnd.add(const Duration(days: 30));
    }
  }

  /// حالة السداد الثلاثية: (🟢 مسدّد - 🟡 في المهلة - 🔴 متأخر)
  PaymentStatus get paymentStatus {
    if (isLateOverride != null) {
      return isLateOverride! ? PaymentStatus.overdue : PaymentStatus.paid;
    }
    if (!isSubscriber) return PaymentStatus.paid;
    if (lastPaymentAt == null) return PaymentStatus.overdue;

    final now = DateTime.now();
    final paidEnd = paidPeriodEndDate!;
    if (now.isBefore(paidEnd) || now.isAtSameMomentAs(paidEnd)) {
      return PaymentStatus.paid;
    }

    final graceCutoff = graceCutoffDate!;
    if (now.isBefore(graceCutoff) || now.isAtSameMomentAs(graceCutoff)) {
      return PaymentStatus.grace;
    }

    return PaymentStatus.overdue;
  }

  bool get isPaid => paymentStatus == PaymentStatus.paid;
  bool get isGrace => paymentStatus == PaymentStatus.grace;
  bool get isOverdue => paymentStatus == PaymentStatus.overdue;

  /// كم يوماً تأخّر عن موعد استحقاقه (صفر إن كان مسدّداً أو في المهلة)
  int get daysOverdue {
    if (!isOverdue || lastPaymentAt == null) return 0;
    final graceCutoff = graceCutoffDate;
    if (graceCutoff == null) return 0;
    final diff = DateTime.now().difference(graceCutoff).inDays;
    return diff > 0 ? diff : 1;
  }

  factory ContributorModel.fromJson(Map<String, dynamic> j) {
    final rawType = j['type'] as String?;
    final notes = j['notes'] as String?;
    final detectedType = (rawType == 'donor' &&
            (notes?.contains('[داعم عيني]') == true ||
                notes?.contains('نوع المساهمة:') == true))
        ? ContributorType.inKind
        : ContributorType.fromValue(rawType);

    return ContributorModel(
      id: j['id'].toString(),
      type: detectedType,
        fullName: (j['full_name'] as String?) ?? 'بلا اسم',
        phone: j['phone'] as String?,
        photoUrl: j['photo_url'] as String?,
        notes: j['notes'] as String?,
        address: j['address'] as String?,
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
        latestDonationDesc: j['latest_donation_desc'] as String?,
      );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.value,
        'full_name': fullName,
        'phone': phone,
        'photo_url': photoUrl,
        'notes': notes,
        'address': address,
        'subscription_amount': subscriptionAmount,
        'subscription_type': subscriptionType?.value,
        'last_payment_at': lastPaymentAt?.toIso8601String(),
        'is_late_override': isLateOverride,
        'total_paid': totalPaid,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'latest_donation_desc': latestDonationDesc,
      };

  /// الحقول القابلة للكتابة في قاعدة البيانات (بلا الحقول المحسوبة)
  Map<String, dynamic> toWriteJson() => {
        'id': id,
        'type': type.value,
        'full_name': fullName,
        'phone': phone,
        'photo_url': photoUrl,
        'notes': notes,
        'address': address,
        'subscription_amount': subscriptionAmount,
        'subscription_type': subscriptionType?.value,
        'is_late_override': isLateOverride,
        'latest_donation_desc': latestDonationDesc,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

  ContributorModel copyWith({
    ContributorType? type,
    String? fullName,
    String? phone,
    String? photoUrl,
    String? notes,
    String? address,
    bool clearAddress = false,
    num? subscriptionAmount,
    SubscriptionType? subscriptionType,
    DateTime? lastPaymentAt,
    DateTime? createdAt,
    bool? isLateOverride,
    bool clearOverride = false,
    num? totalPaid,
    bool? pendingSync,
    String? latestDonationDesc,
  }) =>
      ContributorModel(
        id: id,
        type: type ?? this.type,
        fullName: fullName ?? this.fullName,
        phone: phone ?? this.phone,
        photoUrl: photoUrl ?? this.photoUrl,
        notes: notes ?? this.notes,
        address: clearAddress ? null : (address ?? this.address),
        subscriptionAmount: subscriptionAmount ?? this.subscriptionAmount,
        subscriptionType: subscriptionType ?? this.subscriptionType,
        lastPaymentAt: lastPaymentAt ?? this.lastPaymentAt,
        isLateOverride: clearOverride ? null : (isLateOverride ?? this.isLateOverride),
        totalPaid: totalPaid ?? this.totalPaid,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: DateTime.now(),
        pendingSync: pendingSync ?? this.pendingSync,
        latestDonationDesc: latestDonationDesc ?? this.latestDonationDesc,
      );
}

DateTime? _date(Object? v) =>
    v == null ? null : DateTime.tryParse(v.toString());
