import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/podwykonawcy_model.dart';
import '../services/podwykonawcy_api.dart';

// ---- Lista powiązań dla budowy ------------------------------------------

class PowiazaniaState {
  final List<PowiazanieModel> lista;
  final bool loading;
  final String? error;

  const PowiazaniaState({
    this.lista = const [],
    this.loading = false,
    this.error,
  });

  PowiazaniaState copyWith({
    List<PowiazanieModel>? lista,
    bool? loading,
    String? error,
  }) =>
      PowiazaniaState(
        lista: lista ?? this.lista,
        loading: loading ?? this.loading,
        error: error,
      );
}

class PowiazaniaNotifier extends StateNotifier<PowiazaniaState> {
  PowiazaniaNotifier(this._budowaId) : super(const PowiazaniaState()) {
    load();
  }

  final int _budowaId;

  Future<void> load() async {
    state = state.copyWith(loading: true);
    try {
      final lista = await podwykonawcyApi.listaPowiazanBudowy(_budowaId);
      state = PowiazaniaState(lista: lista);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void add(PowiazanieModel p) =>
      state = state.copyWith(lista: [...state.lista, p]);

  void update(PowiazanieModel p) => state = state.copyWith(
        lista: state.lista.map((e) => e.id == p.id ? p : e).toList(),
      );

  void remove(int id) => state = state.copyWith(
        lista: state.lista.where((e) => e.id != id).toList(),
      );
}

final powiazaniaProvider = StateNotifierProvider.autoDispose
    .family<PowiazaniaNotifier, PowiazaniaState, int>(
  (ref, budowaId) => PowiazaniaNotifier(budowaId),
);

// ---- Contact picker (wyszukiwanie kontrahentów) -------------------------

class KontrahentPickerNotifier
    extends StateNotifier<AsyncValue<List<KontrahentModel>>> {
  KontrahentPickerNotifier() : super(const AsyncValue.data([]));

  Future<void> szukaj(String q) async {
    if (q.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }
    state = const AsyncValue.loading();
    try {
      final wyniki = await podwykonawcyApi.szukajKontrahentow(q);
      state = AsyncValue.data(wyniki);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void clear() => state = const AsyncValue.data([]);
}

final kontrahentPickerProvider = StateNotifierProvider.autoDispose<
    KontrahentPickerNotifier, AsyncValue<List<KontrahentModel>>>(
  (ref) => KontrahentPickerNotifier(),
);
