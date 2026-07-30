import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/rozliczenia_model.dart';
import '../services/rozliczenia_api.dart';

final fakturyProvider = FutureProvider.family<List<FakturaModel>, int>(
  (ref, budowaId) => ref.read(rozliczeniaApiProvider).fetchFaktury(budowaId),
);

final rozliczeniaStatsProvider = FutureProvider.family<BudowaRozliczeniaStats, int>(
  (ref, budowaId) => ref.read(rozliczeniaApiProvider).fetchStats(budowaId),
);

class FakturaNotifier extends AutoDisposeFamilyAsyncNotifier<FakturaModel, int> {
  late int _id;

  @override
  Future<FakturaModel> build(int arg) async {
    _id = arg;
    return _load();
  }

  Future<FakturaModel> _load() =>
      ref.read(rozliczeniaApiProvider).fetchFaktura(_id);

  Future<void> setStatus(StatusFaktury status) async {
    await ref.read(rozliczeniaApiProvider).updateStatus(_id, status);
    state = AsyncData(await _load());
  }

  Future<void> oznaczOplacona() async {
    await ref.read(rozliczeniaApiProvider).oznaczOplacona(_id);
    state = AsyncData(await _load());
  }
}

final fakturaProvider =
    AsyncNotifierProvider.autoDispose.family<FakturaNotifier, FakturaModel, int>(
  FakturaNotifier.new,
);
