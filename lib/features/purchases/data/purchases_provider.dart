import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/purchase_model.dart';
import 'purchases_repository.dart';

final purchasesProvider =
    StateNotifierProvider<PurchasesNotifier, AsyncValue<List<PurchaseModel>>>((ref) {
  return PurchasesNotifier(ref.watch(purchasesRepositoryProvider));
});

class PurchasesNotifier extends StateNotifier<AsyncValue<List<PurchaseModel>>> {
  final PurchasesRepository _repo;

  PurchasesNotifier(this._repo) : super(const AsyncLoading()) {
    load();
  }

  Future<void> load() async {
    try {
      final res = await _repo.loadPurchases();
      state = AsyncData(res.data);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> addPurchase(PurchaseModel purchase) async {
    final oldData = state.valueOrNull ?? [];
    try {
      final p = await _repo.addPurchase(purchase);
      state = AsyncData([p, ...oldData]);
    } catch (e) {
      // Re-throw so UI can handle error
      rethrow;
    }
  }

  Future<void> deletePurchase(String id) async {
    final oldData = state.valueOrNull ?? [];
    try {
      await _repo.deletePurchase(id);
      state = AsyncData(oldData.where((p) => p.id != id).toList());
    } catch (e) {
      rethrow;
    }
  }
}
