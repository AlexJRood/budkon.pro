import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sprzet_model.dart';
import '../services/sprzet_api.dart';

final sprzetListProvider = FutureProvider.family<List<SprzetModel>, int?>(
  (ref, budowaId) => ref.read(sprzetApiProvider).fetchSprzet(budowaId: budowaId),
);

// Sprzęt wymagający przeglądu
final przegladAlertyProvider = Provider.family<List<SprzetModel>, List<SprzetModel>>(
  (ref, all) => all
      .where((s) => s.przegladWygasl || s.przegladWygasa)
      .toList()
    ..sort((a, b) {
      if (a.dataKoncaPrzegladu == null) return 1;
      if (b.dataKoncaPrzegladu == null) return -1;
      return a.dataKoncaPrzegladu!.compareTo(b.dataKoncaPrzegladu!);
    }),
);

class SprzetNotifier extends AutoDisposeAsyncNotifier<SprzetModel> {
  late int _id;

  @override
  Future<SprzetModel> build() async => _load();

  void init(int id) => _id = id;

  Future<SprzetModel> _load() => ref.read(sprzetApiProvider).fetchSprzetOne(_id);

  Future<void> setStatus(StatusSprzetu status) async {
    await ref.read(sprzetApiProvider).updateStatus(_id, status);
    state = AsyncData(await _load());
  }

  Future<void> update(SprzetModel s) async {
    await ref.read(sprzetApiProvider).updateSprzet(s);
    state = AsyncData(await _load());
  }
}

final sprzetProvider =
    AsyncNotifierProvider.autoDispose.family<SprzetNotifier, SprzetModel, int>(
  SprzetNotifier.new,
);

final wypozyczenieProvider =
    FutureProvider.autoDispose.family<List<WypozyczenieModel>, int>(
  (ref, sprzetId) =>
      ref.read(sprzetApiProvider).fetchWypozyczenia(sprzetId: sprzetId),
);
