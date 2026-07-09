import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dziennik_model.dart';
import '../services/dziennik_api.dart';

// ---- Lista wpisów -----------------------------------------------------------

class DziennikListState {
  final List<WpisListItem> wpisy;
  final bool loading;
  final String? error;

  const DziennikListState({
    this.wpisy = const [],
    this.loading = false,
    this.error,
  });

  DziennikListState copyWith({
    List<WpisListItem>? wpisy,
    bool? loading,
    String? error,
  }) =>
      DziennikListState(
        wpisy: wpisy ?? this.wpisy,
        loading: loading ?? this.loading,
        error: error,
      );
}

class DziennikListNotifier
    extends StateNotifier<DziennikListState> {
  DziennikListNotifier(this._budowaId) : super(const DziennikListState()) {
    load();
  }

  final int _budowaId;

  Future<void> load({int? rok, int? miesiac}) async {
    state = state.copyWith(loading: true);
    try {
      final wpisy = await dziennikApi.lista(
        budowaId: _budowaId,
        rok: rok,
        miesiac: miesiac,
      );
      state = DziennikListState(wpisy: wpisy);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void remove(int id) {
    state = state.copyWith(
      wpisy: state.wpisy.where((w) => w.id != id).toList(),
    );
  }
}

final dziennikListProvider = StateNotifierProvider.autoDispose
    .family<DziennikListNotifier, DziennikListState, int>(
  (ref, budowaId) => DziennikListNotifier(budowaId),
);

// ---- Szczegół wpisu ---------------------------------------------------------

final wpisDetailProvider = FutureProvider.autoDispose
    .family<WpisDetail, int>((ref, id) => dziennikApi.szczegol(id));

// ---- Auto-uzupełnianie ------------------------------------------------------

class AutoUzupelnijParams {
  final int budowaId;
  final String? data;

  const AutoUzupelnijParams({required this.budowaId, this.data});

  @override
  bool operator ==(Object other) =>
      other is AutoUzupelnijParams &&
      other.budowaId == budowaId &&
      other.data == data;

  @override
  int get hashCode => Object.hash(budowaId, data);
}

final autoUzupelnijProvider = FutureProvider.autoDispose
    .family<AutoUzupelnijData, AutoUzupelnijParams>(
  (ref, params) => dziennikApi.autoUzupelnij(
    budowaId: params.budowaId,
    data: params.data,
  ),
);

// ---- Markety budowlane ------------------------------------------------------

final marketyProvider = FutureProvider.autoDispose
    .family<
        ({double budowaLat, double budowaLon, List<MarketBudowlany> markety}),
        int>(
  (ref, budowaId) => dziennikApi.marketyBudowlane(budowaId: budowaId),
);

// ---- Formularz (save/create) ------------------------------------------------

class WpisFormNotifier extends StateNotifier<AsyncValue<WpisDetail?>> {
  WpisFormNotifier() : super(const AsyncValue.data(null));

  Future<WpisDetail?> zapisz({
    required int budowaId,
    int? wpisId,
    required Map<String, dynamic> payload,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = wpisId != null
          ? await dziennikApi.edytuj(wpisId, payload)
          : await dziennikApi.utwoz({...payload, 'budowa_id': budowaId});
      state = AsyncValue.data(result);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final wpisFormProvider =
    StateNotifierProvider.autoDispose<WpisFormNotifier, AsyncValue<WpisDetail?>>(
  (ref) => WpisFormNotifier(),
);
