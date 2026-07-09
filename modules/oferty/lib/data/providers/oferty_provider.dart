import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/oferty_model.dart';
import '../services/oferty_api.dart';

class OfertyState {
  final List<OfertyListItem> lista;
  final bool loading;
  final String? error;

  const OfertyState({
    this.lista = const [],
    this.loading = false,
    this.error,
  });

  OfertyState copyWith({
    List<OfertyListItem>? lista,
    bool? loading,
    String? error,
  }) =>
      OfertyState(
        lista: lista ?? this.lista,
        loading: loading ?? this.loading,
        error: error,
      );
}

class OfertyNotifier extends StateNotifier<OfertyState> {
  final int? budowaId;

  OfertyNotifier(this.budowaId) : super(const OfertyState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final lista = await ofertyApi.lista(budowaId: budowaId);
      state = state.copyWith(lista: lista, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void add(OfertyListItem oferta) {
    state = state.copyWith(lista: [oferta, ...state.lista]);
  }

  void remove(int id) {
    state = state.copyWith(
        lista: state.lista.where((o) => o.id != id).toList());
  }

  void updateStatus(int id, StatusOferty status) {
    // Odśwież listę po zmianie statusu
    load();
  }
}

final ofertyProvider = StateNotifierProvider.autoDispose
    .family<OfertyNotifier, OfertyState, int?>(
  (ref, budowaId) => OfertyNotifier(budowaId),
);

final ofertaDetailProvider = FutureProvider.autoDispose
    .family<OfertyDetail, int>((ref, id) => ofertyApi.szczegol(id));
