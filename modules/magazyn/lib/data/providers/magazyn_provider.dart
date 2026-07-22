import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/magazyn_model.dart';
import '../services/magazyn_api.dart';

// ---- Lista pozycji per budowa ----

final pozycjeProvider = FutureProvider.family<List<MagazynPozycjaModel>, int>(
  (ref, budowaId) => ref.read(magazynApiProvider).fetchPozycje(budowaId),
);

// ---- Notifier dla pojedynczej pozycji (z ruchami) ----

class PozycjaState {
  final MagazynPozycjaModel pozycja;
  final List<MagazynRuchModel> ruchy;
  const PozycjaState({required this.pozycja, required this.ruchy});
}

class PozycjaNotifier extends AutoDisposeAsyncNotifier<PozycjaState> {
  late int _id;

  @override
  Future<PozycjaState> build() async => _load();

  void init(int id) => _id = id;

  Future<PozycjaState> _load() async {
    final api = ref.read(magazynApiProvider);
    final results = await Future.wait([
      api.fetchPozycja(_id),
      api.fetchRuchy(_id),
    ]);
    return PozycjaState(
      pozycja: results[0] as MagazynPozycjaModel,
      ruchy: results[1] as List<MagazynRuchModel>,
    );
  }

  Future<void> addRuch(MagazynRuchModel ruch) async {
    await ref.read(magazynApiProvider).addRuch(ruch);
    state = AsyncData(await _load());
  }

  Future<void> updatePozycja(MagazynPozycjaModel p) async {
    await ref.read(magazynApiProvider).updatePozycja(p);
    state = AsyncData(await _load());
  }
}

final pozycjaProvider = AsyncNotifierProvider.autoDispose
    .family<PozycjaNotifier, PozycjaState, int>(PozycjaNotifier.new);

// ---- Niska stany — lista alertów ----

final niskiStanProvider = Provider.family<List<MagazynPozycjaModel>, List<MagazynPozycjaModel>>(
  (ref, all) => all.where((p) => p.niski || p.pusty).toList(),
);
