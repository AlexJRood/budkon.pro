import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pracownicy_model.dart';
import '../services/pracownicy_api.dart';

class PracownicyState {
  final List<PracownikListItem> lista;
  final bool loading;
  final String? error;
  const PracownicyState({
    this.lista = const [],
    this.loading = false,
    this.error,
  });
  PracownicyState copyWith({
    List<PracownikListItem>? lista,
    bool? loading,
    String? error,
  }) =>
      PracownicyState(
        lista: lista ?? this.lista,
        loading: loading ?? this.loading,
        error: error,
      );
}

class PracownicyNotifier extends StateNotifier<PracownicyState> {
  PracownicyNotifier() : super(const PracownicyState()) {
    load();
  }

  Future<void> load({String? specjalizacja}) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final lista =
          await pracownicyApi.lista(specjalizacja: specjalizacja);
      state = state.copyWith(lista: lista, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }
}

final pracownicyProvider =
    StateNotifierProvider<PracownicyNotifier, PracownicyState>(
  (_) => PracownicyNotifier(),
);

final pracownikDetailProvider =
    FutureProvider.autoDispose.family<PracownikDetail, int>(
  (ref, id) => pracownicyApi.szczegol(id),
);

final pracownicyNaBudowieProvider =
    FutureProvider.autoDispose.family<List<PracownikDetail>, int>(
  (ref, budowaId) => pracownicyApi.doBudowy(budowaId),
);
