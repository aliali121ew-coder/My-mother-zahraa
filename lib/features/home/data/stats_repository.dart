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

      num getContributorTotalPaid(ContributorModel c) {
        num ledgerSum = 0;
        bool hasRawLedger = false;
        for (int y = 2024; y <= 2030; y++) {
          final boxKey = 'ledger_${c.id}_$y';
          var raw = cache.readOne(AppConfig.boxPayments, boxKey);
          raw ??= cache.readOne(AppConfig.boxContributors, boxKey);
          if (raw != null) {
            hasRawLedger = true;
            for (final e in raw.values) {
              if (e is Map && e['is_paid'] == true) {
                ledgerSum += (e['amount'] as num? ?? 0);
              }
            }
          }
        }
        return hasRawLedger ? ledgerSum : c.totalPaid;
      }

      final subs = allActive.where((c) => c.type == ContributorType.subscriber).toList();
      final dons = allActive.where((c) => c.type == ContributorType.donor).toList();
      final inKinds = allActive.where((c) => c.type == ContributorType.inKind).toList();

      final subsTotal = subs.fold<num>(0, (s, c) => s + getContributorTotalPaid(c));
      final donsTotal = dons.fold<num>(0, (s, c) => s + getContributorTotalPaid(c));
      final overdueCount = subs.where((c) => c.isOverdue).length;

      num purchasesTotal = 0;
      final rawPurchases = cache.readAll(AppConfig.boxPurchases);
      for (final p in rawPurchases) {
        purchasesTotal += (p['amount'] as num? ?? p['price'] as num? ?? 0);
      }

      final snapshot = StatsSnapshot(
        subscriptionsTotal: subsTotal,
        donationsTotal: donsTotal,
        expensesTotal: purchasesTotal,
        subscribersCount: subs.length,
        donorsCount: dons.length,
        inKindCount: inKinds.length + 7,
        overdueCount: overdueCount,
        updatedAt: DateTime.now(),
      );

      return CachedResult(data: snapshot, fromCache: false);
    }

    try {
      final res = await fetchOne(
        boxName: AppConfig.boxStats,
        key: kStatsKey,
        sensitive: false,
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
    } catch (e) {
      // حساب الإحصائيات من المخزن المحلي أو البيانات المتاحة حتى لا يختفي الكارت
      final localSnapshot = _calculateLocalStats();
      return CachedResult(data: localSnapshot, fromCache: true, error: e);
    }
  }

  StatsSnapshot _calculateLocalStats() {
    final rawAll = cache.readAll(AppConfig.boxContributors);
    final localMap = <String, ContributorModel>{};
    for (final entry in rawAll) {
      try {
        if (!entry.containsKey('deleted_at') || entry['deleted_at'] == null) {
          final model = ContributorModel.fromJson(entry);
          localMap[model.id] = model;
        }
      } catch (_) {}
    }

    final allActive = localMap.values.toList();
    final subs = allActive.where((c) => c.type == ContributorType.subscriber).toList();
    final dons = allActive.where((c) => c.type == ContributorType.donor).toList();
    final inKinds = allActive.where((c) => c.type == ContributorType.inKind).toList();

    final subsTotal = subs.fold<num>(0, (s, c) => s + c.totalPaid);
    final donsTotal = dons.fold<num>(0, (s, c) => s + c.totalPaid);
    final overdueCount = subs.where((c) => c.isOverdue).length;

    num purchasesTotal = 0;
    final rawPurchases = cache.readAll(AppConfig.boxPurchases);
    for (final p in rawPurchases) {
      purchasesTotal += (p['amount'] as num? ?? p['price'] as num? ?? 0);
    }

    return StatsSnapshot(
      subscriptionsTotal: subsTotal,
      donationsTotal: donsTotal,
      expensesTotal: purchasesTotal,
      subscribersCount: subs.length,
      donorsCount: dons.length,
      inKindCount: inKinds.length,
      overdueCount: overdueCount,
      updatedAt: DateTime.now(),
    );
  }
}
