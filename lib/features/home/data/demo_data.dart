import '../../../shared/models/contributor_model.dart';
import '../../../shared/models/stats_snapshot.dart';

/// بيانات تجريبية تعمل **بلا Supabase**.
///
/// الغرض: يستطيع المستخدم تثبيت الـAPK وتجربة كل الواجهات فوراً قبل إعداد
/// قاعدة البيانات. بمجرد تمرير SUPABASE_URL و SUPABASE_ANON_KEY وقت البناء
/// يتحوّل التطبيق تلقائياً للبيانات الحقيقية ولا يُستخدم هذا الملف إطلاقاً.
abstract final class DemoData {
  static final _now = DateTime.now();

  /// البيانات التجريبية فارغة لتبدأ السجلات نظيفة وحقيقية 100%
  static final donors = <ContributorModel>[];

  static final subscribers = <ContributorModel>[];



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
