import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/harmonogram_model.dart';
import '../services/harmonogram_api.dart';

// ---- Timeline (główny widok) --------------------------------------------

final timelineProvider = FutureProvider.autoDispose
    .family<TimelineData, int>(
  (ref, budowaId) => harmonogramApi.timeline(budowaId),
);

// ---- Postęp zadania -----------------------------------------------------

class PostepNotifier extends StateNotifier<AsyncValue<ZadanieModel?>> {
  PostepNotifier() : super(const AsyncValue.data(null));

  Future<ZadanieModel?> aktualizuj(
    int zadanieId, {
    required int postepProcent,
    String? status,
  }) async {
    state = const AsyncValue.loading();
    try {
      final updated = await harmonogramApi.aktualizujPostep(
        zadanieId,
        postepProcent: postepProcent,
        status: status,
      );
      state = AsyncValue.data(updated);
      return updated;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final postepProvider =
    StateNotifierProvider.autoDispose<PostepNotifier, AsyncValue<ZadanieModel?>>(
  (ref) => PostepNotifier(),
);

// ---- Formularz zadania --------------------------------------------------

class ZadanieFormNotifier extends StateNotifier<AsyncValue<ZadanieModel?>> {
  ZadanieFormNotifier() : super(const AsyncValue.data(null));

  Future<ZadanieModel?> zapisz({
    required int budowaId,
    int? zadanieId,
    required Map<String, dynamic> payload,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = zadanieId != null
          ? await harmonogramApi.edytujZadanie(zadanieId, payload)
          : await harmonogramApi.utworzZadanie({
              ...payload,
              'budowa_id': budowaId,
            });
      state = AsyncValue.data(result);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final zadanieFormProvider = StateNotifierProvider.autoDispose<
    ZadanieFormNotifier, AsyncValue<ZadanieModel?>>(
  (ref) => ZadanieFormNotifier(),
);
