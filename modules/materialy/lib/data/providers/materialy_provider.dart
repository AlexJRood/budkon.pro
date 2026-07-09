import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/materialy_model.dart';
import '../services/materialy_api.dart';

// ---- Lista pozycji zamówień per budowa -------------------------------------

class PozycjeState {
  final List<PozycjaZamowieniaModel> lista;
  final bool loading;
  final String? error;

  const PozycjeState({
    this.lista = const [],
    this.loading = false,
    this.error,
  });

  PozycjeState copyWith({
    List<PozycjaZamowieniaModel>? lista,
    bool? loading,
    String? error,
  }) =>
      PozycjeState(
        lista: lista ?? this.lista,
        loading: loading ?? this.loading,
        error: error,
      );
}

class PozycjeNotifier extends StateNotifier<PozycjeState> {
  final int budowaId;

  PozycjeNotifier(this.budowaId) : super(const PozycjeState()) {
    load();
  }

  Future<void> load({String? status}) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final lista = await materialyApi.listaPozycji(
        budowaId: budowaId,
        status: status,
      );
      state = state.copyWith(lista: lista, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void update(PozycjaZamowieniaModel updated) {
    state = state.copyWith(
      lista: [
        for (final p in state.lista)
          if (p.id == updated.id) updated else p,
      ],
    );
  }
}

final pozycjeProvider = StateNotifierProvider.autoDispose
    .family<PozycjeNotifier, PozycjeState, int>(
  (ref, budowaId) => PozycjeNotifier(budowaId),
);

// ---- Katalog materiałów (wyszukiwarka) ------------------------------------

class MaterialPickerNotifier
    extends StateNotifier<AsyncValue<List<MaterialModel>>> {
  MaterialPickerNotifier() : super(const AsyncValue.data([]));

  Future<void> szukaj(String q) async {
    if (q.trim().isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }
    state = const AsyncValue.loading();
    try {
      final wyniki = await materialyApi.listaMaterialow(q: q);
      state = AsyncValue.data(wyniki);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final materialPickerProvider = StateNotifierProvider.autoDispose<
    MaterialPickerNotifier, AsyncValue<List<MaterialModel>>>(
  (_) => MaterialPickerNotifier(),
);

// ---- Historia cen per materiał ---------------------------------------------

final historiaCenProvider = FutureProvider.autoDispose
    .family<List<HistoriaCenyModel>, int>((ref, materialId) async {
  return materialyApi.historiaCen(materialId, dni: 180);
});

// ---- Trendy ----------------------------------------------------------------

final trendyProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (_) => materialyApi.trendy(),
);
