import '../../../core/config/app_config.dart';
import '../../../core/data/supabase_repository.dart';
import '../../../shared/models/contributor_model.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/stats_snapshot.dart';
import 'demo_data.dart';

/// إحصائيات الرئيسية.
///
/// تُقرأ عبر دالة `get_stats()` في قاعدة البيانات وليس من الجداول مباشرة.
/// هذا هو ما يسمح لدور «العضو» برؤية **المجاميع دون الأسماء**: الدالة
/// SECURITY DEFINER تتجاوز RLS داخلياً وتعيد أرقاماً مجمّعة فقط.
class StatsRepository extends SupabaseRepository {
  Future<CachedResult<StatsSnapshot>> load() async {
    if (!isLive) {
      await Future<void>.delayed(const Duration(milliseconds: 150));

      final rawAll = cache.readAll(AppConfig.boxContributors);
      final deletedIds = <String>{};
      final localMap = <String, ContributorModel>{};

      for (final entry in rawAll) {
        try {
          final id = entry['id']?.toString();
          if (entry.containsKey('deleted_at') && entry['deleted_at'] != null) {
            if (id != null) deletedIds.add(id);
          } else {
            final model = ContributorModel.fromJson(entry);
            localMap[model.id] = model;
          }
        } catch (_) {}
      }

      final baseDonors = DemoData.donors
          .where((c) => !deletedIds.contains(c.id))
          .map((c) => localMap[c.id] ?? c)
          .toList();
      final baseSubscribers = DemoData.subscribers
          .where((c) => !deletedIds.contains(c.id))
          .map((c) => localMap[c.id] ?? c)
          .toList();
      final newLocals = localMap.values
          .where((c) =>
              !c.id.startsWith('demo-d-') &&
              !c.id.startsWith('demo-s-') &&
              !deletedIds.contains(c.id))
          .toList();

      final allActive = [...baseDonors, ...baseSubscribers, ...newLocals];

      final subs = allActive.where((c) => c.type == ContributorType.subscriber).toList();
      final dons = allActive.where((c) => c.type == ContributorType.donor).toList();
      final inKinds = allActive.where((c) => c.type == ContributorType.inKind).toList();

      final subsTotal = subs.fold<num>(0, (s, c) => s + c.totalPaid);
      final donsTotal = dons.fold<num>(0, (s, c) => s + c.totalPaid);
      final overdueCount = subs.where((c) => c.isOverdue).length;

      final snapshot = StatsSnapshot(
        subscriptionsTotal: subsTotal,
        donationsTotal: donsTotal,
        subscribersCount: subs.length,
        donorsCount: dons.length,
        inKindCount: inKinds.length + 7,
        overdueCount: overdueCount,
        updatedAt: DateTime.now(),
      );

      return CachedResult(data: snapshot, fromCache: false);
    }

    final res = await fetchOne(
      boxName: AppConfig.boxStats,
      key: kStatsKey,
      fetch: () async {
        final raw = await db.rpc<dynamic>('get_stats');
        return jsonSafe(Map<String, dynamic>.from(raw as Map));
      },
    );

    return CachedResult(
      data: StatsSnapshot.fromJson(res.data),
      fromCache: res.fromCache,
      error: res.error,
    );
  }
}
