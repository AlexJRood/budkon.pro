import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/gwarancje_model.dart';
import '../services/gwarancje_api.dart';

class GwarancjeNotifier extends AutoDisposeAsyncNotifier<List<GwarancjaModel>> {
  late int _budowaId;

  @override
  Future<List<GwarancjaModel>> build() async => [];

  void init(int budowaId) {
    _budowaId = budowaId;
    _load();
  }

  Future<void> _load() async {
    state = const AsyncLoading();
    state = AsyncData(await ref.read(gwarancjeApiProvider).fetchGwarancje(_budowaId));
  }

  Future<void> addGwarancja(GwarancjaModel g) async {
    await ref.read(gwarancjeApiProvider).createGwarancja(g);
    await _load();
  }
}

final gwarancjeProvider =
    AsyncNotifierProvider.autoDispose<GwarancjeNotifier, List<GwarancjaModel>>(
  GwarancjeNotifier.new,
);

class ZgloszeniaNotifier
    extends AutoDisposeAsyncNotifier<List<ZgloszenieSerwisowModel>> {
  late int _budowaId;

  @override
  Future<List<ZgloszenieSerwisowModel>> build() async => [];

  void init(int budowaId) {
    _budowaId = budowaId;
    _load();
  }

  Future<void> _load() async {
    state = const AsyncLoading();
    state = AsyncData(await ref.read(gwarancjeApiProvider).fetchZgloszenia(_budowaId));
  }

  Future<void> add(ZgloszenieSerwisowModel z) async {
    await ref.read(gwarancjeApiProvider).addZgloszenie(z);
    await _load();
  }

  Future<void> updateStatus(int id, StatusZgloszenia status, {String? odpowiedz}) async {
    await ref.read(gwarancjeApiProvider).updateZgloszenieStatus(id, status, odpowiedz: odpowiedz);
    await _load();
  }
}

final zgloszeniaProvider =
    AsyncNotifierProvider.autoDispose<ZgloszeniaNotifier, List<ZgloszenieSerwisowModel>>(
  ZgloszeniaNotifier.new,
);
