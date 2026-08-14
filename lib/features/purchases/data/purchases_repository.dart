import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_config.dart';
import '../../../core/data/supabase_repository.dart';
import '../../../shared/models/purchase_model.dart';

final purchasesRepositoryProvider = Provider<PurchasesRepository>((ref) {
  return PurchasesRepository();
});

class PurchasesRepository extends SupabaseRepository {
  static const _box = AppConfig.boxPurchases;

  Future<CachedResult<List<PurchaseModel>>> loadPurchases() async {
    if (!isLive) {
      await Future<void>.delayed(const Duration(milliseconds: 150));
      final rawAll = cache.readAll(_box);
      
      final list = rawAll.map((e) => PurchaseModel.fromJson(e)).toList();
      list.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));
      
      return CachedResult(data: list, fromCache: true);
    }

    try {
      final res = await fetchList(
        boxName: _box,
        idOf: (row) => row['id'].toString(),
        fetch: () => db
            .from('purchases')
            .select()
            .order('purchase_date', ascending: false),
      );
      
      final list = res.data.map((e) => PurchaseModel.fromJson(e)).toList();
      return CachedResult(data: list, fromCache: res.fromCache, error: res.error);
    } catch (e) {
      final local = cache.readAll(_box);
      final list = local.map((x) => PurchaseModel.fromJson(x)).toList();
      list.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));
      return CachedResult(data: list, fromCache: true, error: e);
    }
  }

  Future<PurchaseModel> addPurchase(PurchaseModel purchase) async {
    final map = purchase.toJson();

    if (!isLive) {
      await cache.put(_box, purchase.id, map);
      return purchase;
    }

    try {
      final updated = map..remove('pendingSync');
      final res = await db.from('purchases').insert(updated).select().single();
      final p = PurchaseModel.fromJson(res);
      await cache.put(_box, p.id, p.toJson());
      return p;
    } catch (e) {
      final p = purchase.copyWith(pendingSync: true);
      await cache.put(_box, p.id, p.toJson());
      await cache.put(AppConfig.boxOutbox, 'purchase_add_${p.id}', {
        'type': 'add_purchase',
        'data': p.toJson(),
        'queued_at': DateTime.now().toUtc().toIso8601String(),
      });
      return p;
    }
  }

  Future<void> deletePurchase(String id) async {
    if (!isLive) {
      await cache.delete(_box, id);
      return;
    }
    try {
      await db.from('purchases').delete().eq('id', id);
      await cache.delete(_box, id);
    } catch (e) {
      await cache.delete(_box, id);
      await cache.put(AppConfig.boxOutbox, 'purchase_del_$id', {
        'type': 'delete_purchase',
        'id': id,
        'queued_at': DateTime.now().toUtc().toIso8601String(),
      });
      rethrow;
    }
  }
}
