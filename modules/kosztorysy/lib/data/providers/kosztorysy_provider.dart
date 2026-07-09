import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/kosztorys_model.dart';
import '../services/kosztorysy_api.dart';

// ── Lista ──────────────────────────────────────────────────────────────────────

final kosztorysyListProvider = StateNotifierProvider.autoDispose
    .family<KosztorysyListNotifier, AsyncValue<List<KosztorysListItemModel>>, int?>(
  (ref, budowaId) => KosztorysyListNotifier(ref.watch(kosztorysyApiProvider), budowaId),
);

class KosztorysyListNotifier
    extends StateNotifier<AsyncValue<List<KosztorysListItemModel>>> {
  KosztorysyListNotifier(this._api, this._budowaId)
      : super(const AsyncValue.loading()) {
    fetch();
  }

  final KosztorysyApi _api;
  final int? _budowaId;

  Future<void> fetch() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => _api.fetchList(budowaId: _budowaId));
  }

  void addLocal(KosztorysListItemModel k) {
    state.whenData((list) => state = AsyncValue.data([k, ...list]));
  }

  void removeLocal(int id) {
    state.whenData(
        (list) => state = AsyncValue.data(list.where((k) => k.id != id).toList()));
  }

  void updateLocal(KosztorysListItemModel updated) {
    state.whenData((list) => state = AsyncValue.data(
          list.map((k) => k.id == updated.id ? updated : k).toList(),
        ));
  }
}

// ── Szczegóły ─────────────────────────────────────────────────────────────────

final kosztorysDetailProvider =
    StateNotifierProvider.autoDispose.family<KosztorysDetailNotifier,
        AsyncValue<KosztorysModel>, int>(
  (ref, id) => KosztorysDetailNotifier(ref.watch(kosztorysyApiProvider), id),
);

class KosztorysDetailNotifier
    extends StateNotifier<AsyncValue<KosztorysModel>> {
  KosztorysDetailNotifier(this._api, this._id)
      : super(const AsyncValue.loading()) {
    fetch();
  }

  final KosztorysyApi _api;
  final int _id;

  Future<void> fetch() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _api.fetchOne(_id));
  }

  void updateData(KosztorysModel updated) {
    state = AsyncValue.data(updated);
  }
}

// ── AI generate ───────────────────────────────────────────────────────────────

final aiGenerateProvider =
    StateNotifierProvider.autoDispose<AiGenerateNotifier, AsyncValue<void>>(
  (ref) => AiGenerateNotifier(ref),
);

class AiGenerateNotifier extends StateNotifier<AsyncValue<void>> {
  AiGenerateNotifier(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  Future<KosztorysModel?> generate(
    int kosztorysId, {
    required String opis,
    Map<String, dynamic>? obmiar,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _ref
          .read(kosztorysyApiProvider)
          .aiGenerate(kosztorysId, opis: opis, obmiar: obmiar);
      // odśwież detail
      _ref
          .read(kosztorysDetailProvider(kosztorysId).notifier)
          .updateData(result);
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

// ── Form (create / update / delete) ───────────────────────────────────────────

final kosztorysFormProvider =
    StateNotifierProvider.autoDispose<KosztorysFormNotifier, AsyncValue<void>>(
  (ref) => KosztorysFormNotifier(ref),
);

class KosztorysFormNotifier extends StateNotifier<AsyncValue<void>> {
  KosztorysFormNotifier(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;
  final _api = (Ref r) => r.read(kosztorysyApiProvider);

  Future<KosztorysModel?> save(Map<String, dynamic> data,
      {int? existingId}) async {
    state = const AsyncValue.loading();
    try {
      final result = existingId == null
          ? await _api(_ref).create(data)
          : await _api(_ref).update(existingId, data);
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
      await _api(_ref).delete(id);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<KosztorysPozycjaModel?> updatePozycja(
      int pozycjaId, Map<String, dynamic> patch) async {
    try {
      return await _api(_ref).updatePozycja(pozycjaId, patch);
    } catch (_) {
      return null;
    }
  }

  Future<void> deletePozycja(int pozycjaId) async {
    try {
      await _api(_ref).deletePozycja(pozycjaId);
    } catch (_) {}
  }
}

// ── KNR search ────────────────────────────────────────────────────────────────

final knrSearchProvider =
    StateNotifierProvider.autoDispose<KnrSearchNotifier,
        AsyncValue<List<KnrPozycjaModel>>>(
  (ref) => KnrSearchNotifier(ref.watch(kosztorysyApiProvider)),
);

class KnrSearchNotifier
    extends StateNotifier<AsyncValue<List<KnrPozycjaModel>>> {
  KnrSearchNotifier(this._api) : super(const AsyncValue.data([]));

  final KosztorysyApi _api;

  Future<void> search(String q) async {
    if (q.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _api.searchKnr(q));
  }
}
