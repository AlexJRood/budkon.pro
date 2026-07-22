import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pod_rozliczenia_model.dart';
import '../services/pod_rozliczenia_api.dart';

final podFakturyProvider =
    FutureProvider.autoDispose.family<List<FakturaPodwykonawcyModel>, int>(
  (ref, budowaId) => ref.read(podRozliczeniaApiProvider).fetchFaktury(budowaId),
);

final podStatsProvider =
    FutureProvider.autoDispose.family<List<PodwykonawcaRozliczeniaStats>, int>(
  (ref, budowaId) => ref.read(podRozliczeniaApiProvider).fetchStats(budowaId),
);

final zwrotyProvider =
    FutureProvider.autoDispose.family<List<ZwrotKaucjiModel>, int>(
  (ref, budowaId) => ref.read(podRozliczeniaApiProvider).fetchZwroty(budowaId),
);

class PodFakturaNotifier
    extends AutoDisposeAsyncNotifier<List<FakturaPodwykonawcyModel>> {
  late int _budowaId;

  @override
  Future<List<FakturaPodwykonawcyModel>> build() async => [];

  void init(int budowaId) {
    _budowaId = budowaId;
    _load();
  }

  Future<void> _load() async {
    state = const AsyncLoading();
    state = AsyncData(
        await ref.read(podRozliczeniaApiProvider).fetchFaktury(_budowaId));
  }

  Future<void> setStatus(int id, StatusRozliczeniaPod status) async {
    await ref.read(podRozliczeniaApiProvider).updateStatus(id, status);
    await _load();
  }

  Future<void> zwrocKaucje(int fakturaId, double kwota) async {
    await ref.read(podRozliczeniaApiProvider).zwrocKaucje(fakturaId, kwota);
    await _load();
  }

  Future<void> addFaktura(FakturaPodwykonawcyModel f) async {
    await ref.read(podRozliczeniaApiProvider).createFaktura(f);
    await _load();
  }
}

final podFakturaNotifierProvider =
    AsyncNotifierProvider.autoDispose<PodFakturaNotifier,
        List<FakturaPodwykonawcyModel>>(PodFakturaNotifier.new);
