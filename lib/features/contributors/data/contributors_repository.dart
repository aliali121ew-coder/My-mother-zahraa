import '../../../core/config/app_config.dart';
import '../../../core/data/supabase_repository.dart';
import '../../../shared/models/contributor_model.dart';
import '../../../shared/models/enums.dart';
import '../../home/data/demo_data.dart';

/// قوائم المتبرعين والمشتركين والدفعات.
///
/// القراءة متاحة للمدير والمسؤول المالي فقط (سياسة RLS)، ودور العضو سيحصل
/// على قائمة فارغة — وهذا **سلوك صحيح مقصود** لا خطأ، لأنه لا يُصرَّح له
/// برؤية الأسماء. الواجهة تُظهر له الإحصائيات المجمّعة بدلاً منها.
class ContributorsRepository extends SupabaseRepository {
  /// جلب كل المساهمين من نوع محدّد، مرتّبين بالأعلى مبلغاً
  Future<CachedResult<List<ContributorModel>>> load(ContributorType? type) async {
    if (!isLive) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      final demo = type == ContributorType.donor
          ? [...DemoData.donors]
          : [...DemoData.subscribers];
      if (type == ContributorType.donor) {
        demo.sort((a, b) => b.totalPaid.compareTo(a.totalPaid));
      }
      return CachedResult(data: demo, fromCache: false);
    }

    // نخزّن كل نوع في مفتاح مستقل داخل نفس الصندوق
    final res = await fetchList(
      boxName: AppConfig.boxContributors,
      idOf: (m) => m['id'].toString(),
      fetch: () async {
        var query = db.from('contributors').select();
        if (type != null) {
          query = query.eq('type', type.value);
        }
        final rows = await query
            .isFilter('deleted_at', null)
            .order('total_paid', ascending: false);
        return List<Map<String, dynamic>>.from(rows);
      },
    );

    final list = res.data
        .map(ContributorModel.fromJson)
        .where((c) => type == null || c.type == type)
        .toList();

    return CachedResult(
      data: list,
      fromCache: res.fromCache,
      error: res.error,
    );
  }

  /// إضافة مساهم — المدير فقط (تفرضه RLS، والواجهة تخفي الزر أصلاً)
  Future<ContributorModel> create(ContributorModel c) async {
    final row = await db
        .from('contributors')
        .insert(c.toWriteJson()..remove('id'))
        .select()
        .single();
    return ContributorModel.fromJson(row);
  }

  Future<ContributorModel> update(ContributorModel c) async {
    final row = await db
        .from('contributors')
        .update(c.toWriteJson()..remove('id'))
        .eq('id', c.id)
        .select()
        .single();
    return ContributorModel.fromJson(row);
  }

  /// حذف ناعم: نحفظ السجل ونخفيه، فلا تُفقد الدفعات المرتبطة به
  Future<void> softDelete(String id) => db
      .from('contributors')
      .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
      .eq('id', id);

  /// تجاوز المدير اليدوي لحالة السداد. null = عُد للحساب التلقائي.
  Future<void> setLateOverride(String id, bool? isLate) =>
      db.from('contributors').update({'is_late_override': isLate}).eq('id', id);

  /// سجل دفعات مشترك، الأحدث أولاً
  Future<List<Map<String, dynamic>>> payments(String contributorId) async {
    final rows = await db
        .from('payments')
        .select()
        .eq('contributor_id', contributorId)
        .order('paid_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// تسجيل دفعة. المشغّل في قاعدة البيانات يحدّث تلقائياً آخر دفعة
  /// والمجموع ويلغي أي تجاوز يدوي سابق.
  Future<Map<String, dynamic>> addPayment({
    required String contributorId,
    required num amount,
    DateTime? paidAt,
    String? note,
  }) async {
    final row = await db
        .from('payments')
        .insert({
          'contributor_id': contributorId,
          'amount': amount,
          'paid_at': (paidAt ?? DateTime.now()).toUtc().toIso8601String(),
          if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
        })
        .select()
        .single();
    return row;
  }
}
