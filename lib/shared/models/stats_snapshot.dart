/// لقطة الإحصائيات المعروضة في الرئيسية.
///
/// المبلغ الكلي = الاشتراكات + التبرعات النقدية معاً، والتبرع العيني
/// **مستثنى تماماً** من كل المجاميع النقدية كما تقرّر، ويُعرض عدده فقط.
class StatsSnapshot {
  const StatsSnapshot({
    this.subscriptionsTotal = 0,
    this.donationsTotal = 0,
    this.subscribersCount = 0,
    this.donorsCount = 0,
    this.inKindCount = 0,
    this.overdueCount = 0,
    this.updatedAt,
  });

  /// مجموع ما دفعه المشتركون
  final num subscriptionsTotal;

  /// مجموع التبرعات النقدية فقط
  final num donationsTotal;

  final int subscribersCount;
  final int donorsCount;

  /// عدد التبرعات العينية (بلا مبلغ)
  final int inKindCount;

  /// عدد المشتركين المتأخرين عن السداد
  final int overdueCount;

  final DateTime? updatedAt;

  /// المبلغ الكلي كما طُلب في كارت الرئيسية العريض
  num get totalAmount => subscriptionsTotal + donationsTotal;

  factory StatsSnapshot.fromJson(Map<String, dynamic> j) => StatsSnapshot(
        subscriptionsTotal: (j['subscriptions_total'] as num?) ?? 0,
        donationsTotal: (j['donations_total'] as num?) ?? 0,
        subscribersCount: (j['subscribers_count'] as num?)?.toInt() ?? 0,
        donorsCount: (j['donors_count'] as num?)?.toInt() ?? 0,
        inKindCount: (j['in_kind_count'] as num?)?.toInt() ?? 0,
        overdueCount: (j['overdue_count'] as num?)?.toInt() ?? 0,
        updatedAt: j['updated_at'] == null
            ? null
            : DateTime.tryParse(j['updated_at'].toString()),
      );

  Map<String, dynamic> toJson() => {
        'subscriptions_total': subscriptionsTotal,
        'donations_total': donationsTotal,
        'subscribers_count': subscribersCount,
        'donors_count': donorsCount,
        'in_kind_count': inKindCount,
        'overdue_count': overdueCount,
        'updated_at': (updatedAt ?? DateTime.now()).toIso8601String(),
      };
}
