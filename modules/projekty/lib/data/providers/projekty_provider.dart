import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/projekt_budowlany_model.dart';
import '../services/projekty_api.dart';

// ── Lista projektów ────────────────────────────────────────────────────────────

final projektyListProvider = StateNotifierProvider.autoDispose<
    ProjektyListNotifier, AsyncValue<List<ProjektBudowlanyListModel>>>(
  (ref) => ProjektyListNotifier(ref.watch(projektyApiProvider)),
);

class ProjektyListNotifier
    extends StateNotifier<AsyncValue<List<ProjektBudowlanyListModel>>> {
  ProjektyListNotifier(this._api) : super(const AsyncValue.loading()) {
    fetch();
  }

  final ProjektyApi _api;

  Future<void> fetch() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _api.fetchList());
  }
}

// ── Szczegóły projektu ─────────────────────────────────────────────────────────

final projektDetailProvider = StateNotifierProvider.autoDispose
    .family<ProjektDetailNotifier, AsyncValue<ProjektBudowlanyDetailModel>, String>(
  (ref, projektId) =>
      ProjektDetailNotifier(ref.watch(projektyApiProvider), projektId),
);

class ProjektDetailNotifier
    extends StateNotifier<AsyncValue<ProjektBudowlanyDetailModel>> {
  ProjektDetailNotifier(this._api, this._id) : super(const AsyncValue.loading()) {
    fetch();
  }

  final ProjektyApi _api;
  final String _id;

  Future<void> fetch() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _api.fetchDetail(_id));
  }
}

// ── Kosztorys ─────────────────────────────────────────────────────────────────

final kosztorysApiProvider = StateNotifierProvider.autoDispose
    .family<KosztorysApiNotifier, AsyncValue<KosztorysApiModel>, String>(
  (ref, projektId) =>
      KosztorysApiNotifier(ref.watch(projektyApiProvider), projektId),
);

class KosztorysApiNotifier
    extends StateNotifier<AsyncValue<KosztorysApiModel>> {
  KosztorysApiNotifier(this._api, this._projektId)
      : super(const AsyncValue.loading()) {
    fetch();
  }

  final ProjektyApi _api;
  final String _projektId;

  Future<void> fetch() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _api.fetchKosztorys(_projektId));
  }

  // Optymistyczna aktualizacja ceny pozycji (lp)
  void updateCenaOptimistic(int lp, double newCena) {
    state.whenData((k) {
      final updated = k.pozycje
          .map((p) => p.lp == lp ? p.copyWithCena(newCena) : p)
          .toList();
      // Przelicz podsumowanie lokalnie
      final sumaNetto = updated.fold(0.0, (s, p) => s + p.wartoscNetto);
      final vat = sumaNetto * 0.23;
      final dzialy = <String, double>{};
      for (final p in updated) {
        dzialy[p.dzial] = (dzialy[p.dzial] ?? 0) + p.wartoscNetto;
      }
      state = AsyncValue.data(KosztorysApiModel(
        pozycje: updated,
        podsumowanie: KosztorysPodsumowanieModel(
          sumaNetto: sumaNetto,
          vat23: vat,
          brutto: sumaNetto + vat,
          dzialy: dzialy,
          uwaga: 'Ceny zaktualizowane ręcznie.',
        ),
      ));
    });
  }
}

// ── Aktualizacja cen (PATCH /ceny/) ───────────────────────────────────────────

final cenyFormProvider = StateNotifierProvider.autoDispose
    .family<CenyFormNotifier, AsyncValue<void>, String>(
  (ref, projektId) => CenyFormNotifier(ref, projektId),
);

class CenyFormNotifier extends StateNotifier<AsyncValue<void>> {
  CenyFormNotifier(this._ref, this._projektId)
      : super(const AsyncValue.data(null));

  final Ref _ref;
  final String _projektId;

  Future<void> saveCeny(Map<String, Map<String, double>> ceny) async {
    state = const AsyncValue.loading();
    try {
      await _ref.read(projektyApiProvider).patchCeny(_projektId, ceny);
      // Odśwież kosztorys
      await _ref
          .read(kosztorysApiProvider(_projektId).notifier)
          .fetch();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
