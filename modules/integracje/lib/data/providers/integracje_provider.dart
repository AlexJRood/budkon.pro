import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/integracje_model.dart';
import '../services/integracje_api.dart';

// GUS search — triggered manually, result kept until cleared
class GusSearchNotifier extends AutoDisposeAsyncNotifier<FirmaGusModel?> {
  @override
  Future<FirmaGusModel?> build() async => null;

  Future<void> szukajNip(String nip) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(integracjeApiProvider).szukajFirmyNIP(nip));
  }

  void clear() => state = const AsyncData(null);
}

final gusSearchProvider =
    AsyncNotifierProvider.autoDispose<GusSearchNotifier, FirmaGusModel?>(
  GusSearchNotifier.new,
);

// KSeF history
final ksefHistoryProvider =
    FutureProvider.autoDispose<List<KsefStatusModel>>(
  (ref) => ref.read(integracjeApiProvider).fetchKsefHistory(),
);

// e-Zamówienia search
class PrzetargiNotifier
    extends AutoDisposeAsyncNotifier<List<PrzetargPublicznyModel>> {
  @override
  Future<List<PrzetargPublicznyModel>> build() async => [];

  Future<void> szukaj({String? fraza, String? cpv}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() =>
        ref.read(integracjeApiProvider).szukajPrzetargow(fraza: fraza, cpv: cpv));
  }
}

final przetargiProvider = AsyncNotifierProvider.autoDispose<PrzetargiNotifier,
    List<PrzetargPublicznyModel>>(PrzetargiNotifier.new);
