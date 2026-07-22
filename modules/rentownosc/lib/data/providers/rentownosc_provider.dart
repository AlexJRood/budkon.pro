import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/rentownosc_model.dart';
import '../services/rentownosc_api.dart';

final analizaProvider = FutureProvider.autoDispose.family<RentownoscBudowyModel, int>(
  (ref, budowaId) => ref.read(rentownoscApiProvider).fetchAnaliza(budowaId),
);

class KosztyNotifier extends AutoDisposeAsyncNotifier<List<KosztModel>> {
  late int _budowaId;

  @override
  Future<List<KosztModel>> build() async => [];

  void init(int budowaId) {
    _budowaId = budowaId;
    _load();
  }

  Future<void> _load() async {
    state = const AsyncLoading();
    state = AsyncData(await ref.read(rentownoscApiProvider).fetchKoszty(_budowaId));
  }

  Future<void> addKoszt(KosztModel k) async {
    await ref.read(rentownoscApiProvider).addKoszt(k);
    await _load();
  }

  Future<void> deleteKoszt(int id) async {
    await ref.read(rentownoscApiProvider).deleteKoszt(id);
    await _load();
  }
}

final kosztyProvider =
    AsyncNotifierProvider.autoDispose<KosztyNotifier, List<KosztModel>>(KosztyNotifier.new);
