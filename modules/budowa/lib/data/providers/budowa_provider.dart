import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/budowa_model.dart';
import '../services/budowa_api.dart';

// List provider
final budowaListProvider =
    StateNotifierProvider<BudowaListNotifier, AsyncValue<List<BudowaModel>>>(
  (ref) => BudowaListNotifier(ref.watch(budowaApiProvider)),
);

class BudowaListNotifier extends StateNotifier<AsyncValue<List<BudowaModel>>> {
  BudowaListNotifier(this._api) : super(const AsyncValue.loading()) {
    fetch();
  }

  final BudowaApi _api;

  Future<void> fetch() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_api.fetchList);
  }

  void addLocal(BudowaModel b) {
    state.whenData((list) => state = AsyncValue.data([b, ...list]));
  }

  void updateLocal(BudowaModel updated) {
    state.whenData((list) => state = AsyncValue.data(
          list.map((b) => b.id == updated.id ? updated : b).toList(),
        ));
  }

  void removeLocal(int id) {
    state.whenData(
      (list) => state = AsyncValue.data(list.where((b) => b.id != id).toList()),
    );
  }
}

// Single budowa provider (detail view)
final budowaDetailProvider =
    FutureProvider.autoDispose.family<BudowaModel, int>((ref, id) async {
  return ref.watch(budowaApiProvider).fetchOne(id);
});

// Form / mutation helper
final budowaFormProvider =
    StateNotifierProvider.autoDispose<BudowaFormNotifier, AsyncValue<void>>(
  (ref) => BudowaFormNotifier(ref),
);

class BudowaFormNotifier extends StateNotifier<AsyncValue<void>> {
  BudowaFormNotifier(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  Future<BudowaModel?> save(BudowaModel budowa) async {
    state = const AsyncValue.loading();
    try {
      final api = _ref.read(budowaApiProvider);
      final result = budowa.id == 0
          ? await api.create(budowa)
          : await api.update(budowa.id, budowa.toJson());
      _ref.read(budowaListProvider.notifier).updateLocal(result);
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<void> delete(int id) async {
    state = const AsyncValue.loading();
    try {
      await _ref.read(budowaApiProvider).delete(id);
      _ref.read(budowaListProvider.notifier).removeLocal(id);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<EtapBudowyModel?> updateEtapStatus(
    int etapId,
    StatusEtapu nowyStatus,
  ) async {
    try {
      return await _ref
          .read(budowaApiProvider)
          .updateEtap(etapId, {'status': nowyStatus.apiValue});
    } catch (_) {
      return null;
    }
  }
}
