import '../../../shared/models/contributor_model.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/stats_snapshot.dart';

/// بيانات تجريبية تعمل **بلا Supabase**.
///
/// الغرض: يستطيع المستخدم تثبيت الـAPK وتجربة كل الواجهات فوراً قبل إعداد
/// قاعدة البيانات. بمجرد تمرير SUPABASE_URL و SUPABASE_ANON_KEY وقت البناء
/// يتحوّل التطبيق تلقائياً للبيانات الحقيقية ولا يُستخدم هذا الملف إطلاقاً.
abstract final class DemoData {
  static final _now = DateTime.now();

  static final donors = <ContributorModel>[
    _d('حاج عبد الكريم الموسوي', 2500000, 3),
    _d('الحاجة أم حسين الربيعي', 1800000, 5),
    _d('شركة النور للمقاولات', 1500000, 8),
    _d('حاج جعفر الأسدي', 1200000, 11),
    _d('سيد محمد الحسيني', 950000, 14),
    _d('حاج علي الجبوري', 800000, 18),
    _d('الحاجة زينب الطائي', 750000, 22),
    _d('أبو فاطمة الخفاجي', 600000, 26),
    _d('حاج كاظم الشمري', 500000, 31),
    _d('مؤمن لا يريد ذكر اسمه', 450000, 35),
    _d('حاج صادق العبودي', 400000, 40),
    _d('أم علي الزبيدي', 350000, 44),
  ];

  static final subscribers = <ContributorModel>[
    _s('حاج حسن الدليمي', 100000, SubscriptionType.monthly, 12),
    _s('سيد عباس الغريفي', 250000, SubscriptionType.monthly, 5),
    _s('حاج مهدي الساعدي', 50000, SubscriptionType.monthly, 48),
    _s('الحاجة أم زهراء البهادلي', 150000, SubscriptionType.monthly, 20),
    _s('حاج رضا التميمي', 1200000, SubscriptionType.yearly, 120),
    _s('أبو محمد الحلفي', 75000, SubscriptionType.monthly, 65),
    _s('حاج ياسر العامري', 200000, SubscriptionType.monthly, 8),
    _s('سيد حيدر الموسوي', 600000, SubscriptionType.yearly, 400),
    _s('الحاجة أم كرار المياحي', 80000, SubscriptionType.monthly, 15),
    _s('حاج نعيم الكعبي', 120000, SubscriptionType.monthly, 38),
  ];

  static ContributorModel _d(String name, num amount, int daysAgo) =>
      ContributorModel(
        id: 'demo-d-${name.hashCode}',
        type: ContributorType.donor,
        fullName: name,
        phone: '0770${(name.hashCode.abs() % 9000000 + 1000000)}',
        totalPaid: amount,
        lastPaymentAt: _now.subtract(Duration(days: daysAgo)),
        createdAt: _now.subtract(Duration(days: daysAgo)),
      );

  static ContributorModel _s(
    String name,
    num amount,
    SubscriptionType type,
    int daysSincePayment,
  ) =>
      ContributorModel(
        id: 'demo-s-${name.hashCode}',
        type: ContributorType.subscriber,
        fullName: name,
        phone: '0781${(name.hashCode.abs() % 9000000 + 1000000)}',
        subscriptionAmount: amount,
        subscriptionType: type,
        lastPaymentAt: _now.subtract(Duration(days: daysSincePayment)),
        totalPaid: amount * (daysSincePayment ~/ 30 + 1),
        createdAt: _now.subtract(const Duration(days: 400)),
      );

  static StatsSnapshot get stats {
    final subsTotal = subscribers.fold<num>(0, (s, c) => s + c.totalPaid);
    final donsTotal = donors.fold<num>(0, (s, c) => s + c.totalPaid);
    return StatsSnapshot(
      subscriptionsTotal: subsTotal,
      donationsTotal: donsTotal,
      subscribersCount: subscribers.length,
      donorsCount: donors.length,
      inKindCount: 7,
      overdueCount: subscribers.where((s) => s.isOverdue).length,
      updatedAt: _now,
    );
  }
}
