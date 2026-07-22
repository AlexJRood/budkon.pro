import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ai_asystent_model.dart';
import '../services/ai_asystent_api.dart';

// ---- Dziennik głosowy ----

final dzienniknProvider = FutureProvider.autoDispose
    .family<List<WpisDziennikModel>, int>((ref, budowaId) {
  return ref.read(aiAsystentApiProvider).fetchWpisy(budowaId);
});

class DziennikNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<WpisDziennikModel>, int> {
  @override
  Future<List<WpisDziennikModel>> build(int arg) async {
    return ref.read(aiAsystentApiProvider).fetchWpisy(arg);
  }

  Future<void> wyslijAudio(File audio) async {
    state = const AsyncLoading();
    final api = ref.read(aiAsystentApiProvider);
    final wpis = await api.wyslijAudio(arg, audio);
    state = AsyncData([wpis, ...state.valueOrNull ?? []]);
  }
}

final dziennikNotifierProvider = AsyncNotifierProvider.autoDispose
    .family<DziennikNotifier, List<WpisDziennikModel>, int>(
  DziennikNotifier.new,
);

// ---- Analiza zdjęć ----

final analizyProvider = FutureProvider.autoDispose
    .family<List<AnalizaZdjeciaModel>, int>((ref, budowaId) {
  return ref.read(aiAsystentApiProvider).fetchAnalizy(budowaId);
});

class AnalizaNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<AnalizaZdjeciaModel>, int> {
  @override
  Future<List<AnalizaZdjeciaModel>> build(int arg) async {
    return ref.read(aiAsystentApiProvider).fetchAnalizy(arg);
  }

  Future<void> analizuj(File zdjecie, TypAnalizy typ) async {
    state = const AsyncLoading();
    final api = ref.read(aiAsystentApiProvider);
    final analiza = await api.analizujZdjecie(arg, zdjecie, typ);
    state = AsyncData([analiza, ...state.valueOrNull ?? []]);
  }
}

final analizaNotifierProvider = AsyncNotifierProvider.autoDispose
    .family<AnalizaNotifier, List<AnalizaZdjeciaModel>, int>(
  AnalizaNotifier.new,
);

// ---- Predykcja kosztów ----

class PredykcjaNotifier
    extends AutoDisposeFamilyAsyncNotifier<PredykcjaKosztowModel?, int> {
  @override
  Future<PredykcjaKosztowModel?> build(int arg) async {
    return ref.read(aiAsystentApiProvider).fetchPredykcja(arg);
  }

  Future<void> odswiez() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(aiAsystentApiProvider).odswiezPredykcje(arg));
  }
}

final predykcjaProvider = AsyncNotifierProvider.autoDispose
    .family<PredykcjaNotifier, PredykcjaKosztowModel?, int>(
  PredykcjaNotifier.new,
);

// ---- Chat ----

class CzatState {
  final List<WiadomoscCzatModel> historia;
  final bool ladowanie;

  const CzatState({this.historia = const [], this.ladowanie = false});

  CzatState copyWith({List<WiadomoscCzatModel>? historia, bool? ladowanie}) =>
      CzatState(
        historia: historia ?? this.historia,
        ladowanie: ladowanie ?? this.ladowanie,
      );
}

class CzatNotifier extends AutoDisposeFamilyNotifier<CzatState, int> {
  @override
  CzatState build(int arg) => const CzatState();

  Future<void> wyslij(String pytanie) async {
    final wiadomoscUser = WiadomoscCzatModel(
      tresc: pytanie,
      rola: RolaCzat.user,
      czas: DateTime.now(),
    );
    final nowaHistoria = [...state.historia, wiadomoscUser];
    state = state.copyWith(historia: nowaHistoria, ladowanie: true);

    try {
      final odpowiedz = await ref
          .read(aiAsystentApiProvider)
          .zapytaj(arg, pytanie, state.historia);
      final wiadomoscAi = WiadomoscCzatModel(
        tresc: odpowiedz,
        rola: RolaCzat.assistant,
        czas: DateTime.now(),
      );
      state = state.copyWith(
          historia: [...nowaHistoria, wiadomoscAi], ladowanie: false);
    } catch (_) {
      state = state.copyWith(ladowanie: false);
    }
  }

  void wyczysc() => state = const CzatState();
}

final czatProvider =
    NotifierProvider.autoDispose.family<CzatNotifier, CzatState, int>(
  CzatNotifier.new,
);
