import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bhp_model.dart';
import '../services/bhp_api.dart';

class BhpSzkoleniaNotifier extends AutoDisposeAsyncNotifier<List<SzkolenieBhpModel>> {
  late int _budowaId;

  @override
  Future<List<SzkolenieBhpModel>> build() async => [];

  void init(int budowaId) {
    _budowaId = budowaId;
    _load();
  }

  Future<void> _load() async {
    state = const AsyncLoading();
    state = AsyncData(await ref.read(bhpApiProvider).fetchSzkolenia(_budowaId));
  }

  Future<void> add(SzkolenieBhpModel s) async {
    await ref.read(bhpApiProvider).addSzkolenie(s);
    await _load();
  }
}

final bhpSzkoleniaProvider =
    AsyncNotifierProvider.autoDispose<BhpSzkoleniaNotifier, List<SzkolenieBhpModel>>(
  BhpSzkoleniaNotifier.new,
);

class BhpWypadkiNotifier extends AutoDisposeAsyncNotifier<List<WypadekModel>> {
  late int _budowaId;

  @override
  Future<List<WypadekModel>> build() async => [];

  void init(int budowaId) {
    _budowaId = budowaId;
    _load();
  }

  Future<void> _load() async {
    state = const AsyncLoading();
    state = AsyncData(await ref.read(bhpApiProvider).fetchWypadki(_budowaId));
  }

  Future<void> add(WypadekModel w) async {
    await ref.read(bhpApiProvider).addWypadek(w);
    await _load();
  }

  Future<void> updateStatus(int id, StatusWypadku status) async {
    await ref.read(bhpApiProvider).updateWypadekStatus(id, status);
    await _load();
  }
}

final bhpWypadkiProvider =
    AsyncNotifierProvider.autoDispose<BhpWypadkiNotifier, List<WypadekModel>>(
  BhpWypadkiNotifier.new,
);

final bhpInstrukcjeProvider =
    FutureProvider.autoDispose.family<List<InstrukcjaBhpModel>, int>(
  (ref, budowaId) => ref.read(bhpApiProvider).fetchInstrukcje(budowaId),
);
