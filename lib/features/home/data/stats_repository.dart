import '../../../core/config/app_config.dart';
import '../../../core/data/supabase_repository.dart';
import '../../../shared/models/stats_snapshot.dart';
import 'demo_data.dart';

/// إحصائيات الرئيسية.
///
/// تُقرأ عبر دالة `get_stats()` في قاعدة البيانات وليس من الجداول مباشرة.
/// هذا هو ما يسمح لدور «العضو» برؤية **المجاميع دون الأسماء**: الدالة
/// SECURITY DEFINER تتجاوز RLS داخلياً وتعيد أرقاماً مجمّعة فقط، فلا يصل
/// العضو لأي صف باسم مهما فعل.
class StatsRepository extends SupabaseRepository {
  Future<CachedResult<StatsSnapshot>> load() async {
    if (!isLive) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return CachedResult(data: DemoData.stats, fromCache: false);
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
