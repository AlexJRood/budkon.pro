import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/faktury_model.dart';
import '../services/faktury_api.dart';

class FakturyState {
  final List<FakturaListItem> lista;
  final bool loading;
  final String? error;

  const FakturyState({this.lista = const [], this.loading = false, this.error});

  FakturyState copyWith({
    List<FakturaListItem>? lista,
    bool? loading,
    String? error,
  }) =>
      FakturyState(
        lista: lista ?? this.lista,
        loading: loading ?? this.loading,
        error: error,
      );
}

class FakturyNotifier extends StateNotifier<FakturyState> {
  FakturyNotifier() : super(const FakturyState()) {
    load();
  }

  Future<void> load({int? budowaId, String? status}) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final lista = await fakturyApi.lista(budowaId: budowaId, status: status);
      state = state.copyWith(lista: lista, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }
}

final fakturyProvider =
    StateNotifierProvider<FakturyNotifier, FakturyState>(
  (_) => FakturyNotifier(),
);

final fakturaDetailProvider =
    FutureProvider.autoDispose.family<FakturaDetail, int>(
  (ref, id) => fakturyApi.szczegol(id),
);
