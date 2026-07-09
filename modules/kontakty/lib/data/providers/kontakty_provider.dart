import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/kontakty_model.dart';
import '../services/kontakty_api.dart';

class KontaktyState {
  final List<KontrahentListItem> lista;
  final bool loading;
  final String? error;

  const KontaktyState({this.lista = const [], this.loading = false, this.error});

  KontaktyState copyWith({
    List<KontrahentListItem>? lista,
    bool? loading,
    String? error,
  }) =>
      KontaktyState(
        lista: lista ?? this.lista,
        loading: loading ?? this.loading,
        error: error,
      );
}

class KontaktyNotifier extends StateNotifier<KontaktyState> {
  KontaktyNotifier() : super(const KontaktyState()) {
    load();
  }

  Future<void> load({String? q, String? branza}) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final lista = await kontaktyApi.lista(q: q, branza: branza);
      state = state.copyWith(lista: lista, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }
}

final kontaktyProvider =
    StateNotifierProvider<KontaktyNotifier, KontaktyState>(
  (_) => KontaktyNotifier(),
);

final kontrahentDetailProvider =
    FutureProvider.autoDispose.family<KontrahentDetail, int>(
  (ref, id) => kontaktyApi.szczegol(id),
);
