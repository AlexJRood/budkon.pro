import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/bzp_wynik_model.dart';
import '../services/przetargi_api.dart';

// ------------------------------------------------------------------ //
// State                                                               //
// ------------------------------------------------------------------ //

class BzpSzukajState {
  final List<BzpWynikModel> wyniki;
  final int total;
  final bool isLoading;
  final String? error;
  final String fraza;
  final String cpv;
  final int dniWstecz;
  final int strona;

  const BzpSzukajState({
    this.wyniki = const [],
    this.total = 0,
    this.isLoading = false,
    this.error,
    this.fraza = '',
    this.cpv = '',
    this.dniWstecz = 30,
    this.strona = 1,
  });

  BzpSzukajState copyWith({
    List<BzpWynikModel>? wyniki,
    int? total,
    bool? isLoading,
    String? error,
    String? fraza,
    String? cpv,
    int? dniWstecz,
    int? strona,
    bool clearError = false,
  }) =>
      BzpSzukajState(
        wyniki: wyniki ?? this.wyniki,
        total: total ?? this.total,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
        fraza: fraza ?? this.fraza,
        cpv: cpv ?? this.cpv,
        dniWstecz: dniWstecz ?? this.dniWstecz,
        strona: strona ?? this.strona,
      );

  bool get hasMore => wyniki.length < total;
}

// ------------------------------------------------------------------ //
// Notifier                                                            //
// ------------------------------------------------------------------ //

class BzpSzukajNotifier extends StateNotifier<BzpSzukajState> {
  BzpSzukajNotifier(this._api) : super(const BzpSzukajState());

  final PrzetargiApi _api;

  static const _naStronie = 20;

  Future<void> szukaj({
    String? fraza,
    String? cpv,
    int? dniWstecz,
    bool nextPage = false,
  }) async {
    final nFraza = fraza ?? state.fraza;
    final nCpv = cpv ?? state.cpv;
    final nDni = dniWstecz ?? state.dniWstecz;
    final nStrona = nextPage ? state.strona + 1 : 1;

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      fraza: nFraza,
      cpv: nCpv,
      dniWstecz: nDni,
      strona: nStrona,
    );

    try {
      final result = await _api.szukajBzp(
        fraza: nFraza.isEmpty ? null : nFraza,
        cpv: nCpv.isEmpty ? null : nCpv,
        dniWstecz: nDni,
        strona: nStrona,
        naStronie: _naStronie,
      );

      final noweWyniki = result.$1;
      final total = result.$2;

      state = state.copyWith(
        wyniki: nextPage ? [...state.wyniki, ...noweWyniki] : noweWyniki,
        total: total,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void reset() => state = const BzpSzukajState();
}

// ------------------------------------------------------------------ //
// Provider                                                            //
// ------------------------------------------------------------------ //

final bzpSzukajProvider =
    StateNotifierProvider.autoDispose<BzpSzukajNotifier, BzpSzukajState>(
  (ref) => BzpSzukajNotifier(PrzetargiApi()),
);
