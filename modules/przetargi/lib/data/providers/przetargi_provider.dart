import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/przetarg_model.dart';
import '../services/przetargi_api.dart';

final _api = PrzetargiApi();

// ------------------------------------------------------------------ //
// Filtry                                                               //
// ------------------------------------------------------------------ //

class PrzetargiFilter {
  final String? status;
  final bool? czyWarto;
  final String? q;

  const PrzetargiFilter({this.status, this.czyWarto, this.q});

  PrzetargiFilter copyWith({
    Object? status = _sentinel,
    Object? czyWarto = _sentinel,
    Object? q = _sentinel,
  }) =>
      PrzetargiFilter(
        status: status == _sentinel ? this.status : status as String?,
        czyWarto: czyWarto == _sentinel ? this.czyWarto : czyWarto as bool?,
        q: q == _sentinel ? this.q : q as String?,
      );
}

const _sentinel = Object();

final przetargiFilterProvider =
    StateProvider<PrzetargiFilter>((_) => const PrzetargiFilter());

// ------------------------------------------------------------------ //
// Lista przetargów                                                     //
// ------------------------------------------------------------------ //

class PrzetargiListNotifier
    extends StateNotifier<AsyncValue<List<PrzetargListItem>>> {
  PrzetargiListNotifier() : super(const AsyncValue.loading()) {
    load();
  }

  PrzetargiFilter _filter = const PrzetargiFilter();

  Future<void> load({PrzetargiFilter? filter}) async {
    if (filter != null) _filter = filter;
    state = const AsyncValue.loading();
    try {
      final raw = await _api.listPrzetargi(
        status: _filter.status,
        czyWarto: _filter.czyWarto,
        q: _filter.q,
      );
      state = AsyncValue.data(raw.map(PrzetargListItem.fromJson).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> fetch() async {
    await _api.fetch();
    await load();
  }

  void optimisticStatusChange(int id, StatusPrzetargu newStatus) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data([
      for (final p in current)
        if (p.id == id)
          PrzetargListItem(
            id: p.id,
            tytul: p.tytul,
            zamawiajacy: p.zamawiajacy,
            wartoscSzacunkowa: p.wartoscSzacunkowa,
            waluta: p.waluta,
            terminSkladania: p.terminSkladania,
            lokalizacja: p.lokalizacja,
            cpvKody: p.cpvKody,
            status: newStatus,
            aiScore: p.aiScore,
            aiCzyWarto: p.aiCzyWarto,
            aiUwagi: p.aiUwagi,
            zrodlo: p.zrodlo,
            zrodloUrl: p.zrodloUrl,
            kosztorysId: p.kosztorysId,
            dniDoTerminu: p.dniDoTerminu,
            createdAt: p.createdAt,
          )
        else
          p,
    ]);
  }
}

final przetargiListProvider =
    StateNotifierProvider.autoDispose<PrzetargiListNotifier,
        AsyncValue<List<PrzetargListItem>>>(
  (_) => PrzetargiListNotifier(),
);

// ------------------------------------------------------------------ //
// Detail                                                              //
// ------------------------------------------------------------------ //

class PrzetargDetailNotifier
    extends StateNotifier<AsyncValue<PrzetargDetail>> {
  final int id;
  PrzetargDetailNotifier(this.id) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final raw = await _api.getPrzetarg(id);
      state = AsyncValue.data(PrzetargDetail.fromJson(raw));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Map<String, dynamic>> analizuj() async {
    final result = await _api.analizuj(id);
    await load();
    return result;
  }

  Future<int?> generujKosztorys() async {
    final result = await _api.generujKosztorys(id);
    await load();
    return result['kosztorys_id'] as int?;
  }

  Future<void> zmienStatus(StatusPrzetargu status) async {
    await _api.zmienStatus(id, status.apiValue);
    await load();
  }
}

final przetargDetailProvider = StateNotifierProvider.autoDispose
    .family<PrzetargDetailNotifier, AsyncValue<PrzetargDetail>, int>(
  (_, id) => PrzetargDetailNotifier(id),
);

// ------------------------------------------------------------------ //
// Subskrypcje                                                         //
// ------------------------------------------------------------------ //

final subskrypcjeProvider = FutureProvider.autoDispose<
    List<SubskrypcjaPrzetargow>>((_) async {
  final raw = await _api.listSubskrypcje();
  return raw.map(SubskrypcjaPrzetargow.fromJson).toList();
});

// ------------------------------------------------------------------ //
// Akcje (generuj kosztorys, fetch) — osobny provider żeby śledzić stan //
// ------------------------------------------------------------------ //

class FetchNotifier extends StateNotifier<AsyncValue<int?>> {
  FetchNotifier() : super(const AsyncValue.data(null));

  Future<void> fetch(PrzetargiListNotifier listNotifier) async {
    state = const AsyncValue.loading();
    try {
      final result = await _api.fetch();
      final nowych = result['nowych'] as int? ?? 0;
      state = AsyncValue.data(nowych);
      await listNotifier.load();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final fetchProvider =
    StateNotifierProvider.autoDispose<FetchNotifier, AsyncValue<int?>>(
  (_) => FetchNotifier(),
);
