import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/live/live.dart';

import 'board_details_provider.dart';
import 'board_provider.dart';

/// Wpięcie tablicy TMS w szynę `live`.
///
/// Aktywne dopóki widoczny jest widok tablicy (CrmToDoBoard go watchuje;
/// autoDispose = po zamknięciu tablicy odsubskrybowuje).
///
/// - subskrybuje grupę `board:<id>` bieżącej tablicy (przełącza przy zmianie
///   boardId),
/// - na sygnał `tms:tasks` / `tms:project` odpala istniejący delta-sync
///   (`fetchBoardDetails`) — czyli tani `taskSyncCheck` + minimalny pull.
///   Live-sygnał zastępuje polling: mówi "sprawdź", a delta-sync robi resztę.
///
/// Echo-safe: `syncBoard` najpierw flushuje lokalne pending ops, więc
/// odświeżenie wywołane echem WŁASNEJ zmiany nie cofa optimistic UI.
final tmsLiveProvider = Provider.autoDispose<void>((ref) {
  Timer? debounce;

  void onSignal(LiveSignal sig) {
    final id = ref.read(boardIdProvider);
    if (id == null || id <= 0) return;
    // Sygnał innej tablicy (gdyby subskrypcji było kilka) — ignoruj.
    if (sig.aud != null && sig.aud != 'board:$id') return;

    // Coalesce bursty (np. drag-reorder emituje wiele zmian).
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 400), () {
      ref
          .read(boardDetailsManagementProvider.notifier)
          .fetchBoardDetails(id.toString());
    });
  }

  liveOn(ref, 'tms:tasks', onSignal);
  liveOn(ref, 'tms:project', onSignal);

  // Subskrybuj grupę bieżącej tablicy; przełączaj przy zmianie boardId.
  ref.listen<int?>(
    boardIdProvider,
    (prev, next) {
      final client = ref.read(liveClientProvider);
      if (prev != null && prev > 0) client.unsubscribe('board:$prev');
      if (next != null && next > 0) client.subscribe('board:$next');
    },
    fireImmediately: true,
  );

  ref.onDispose(() {
    debounce?.cancel();
    final id = ref.read(boardIdProvider);
    if (id != null && id > 0) {
      ref.read(liveClientProvider).unsubscribe('board:$id');
    }
  });
});
