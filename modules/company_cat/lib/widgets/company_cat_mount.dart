import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/live/live.dart';

import '../provider/cat_gift_provider.dart';
import '../provider/company_cat_provider.dart';
import 'cat_roam_layer.dart';

/// Montowany APP-WIDE (dodaj do Stacka w shellu, obok bannera łączności).
///
/// Robi dwie rzeczy:
///  1. **Presence heartbeat** co 45s (`reportPresence`) — KRYTYCZNE: bez tego
///     backend nie wie kto jest online i kot nie ma dokąd wędrować.
///  2. Renderuje [CompanyCatOverlay] w rogu, gdy kot jest u mnie
///     (`onMyScreen`) i ekran nie jest wyciszony (`catSuppressedProvider`).
class CompanyCatMount extends ConsumerStatefulWidget {
  const CompanyCatMount({super.key});

  @override
  ConsumerState<CompanyCatMount> createState() => _CompanyCatMountState();
}

class _CompanyCatMountState extends ConsumerState<CompanyCatMount>
    with WidgetsBindingObserver {
  Timer? _heartbeat;
  bool _idle = false;

  static const Duration _interval = Duration(seconds: 45);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _sendPresence();
      _heartbeat = Timer.periodic(_interval, (_) => _sendPresence());
      // wstan startowy kota (endpoint) — reconnect i tak odświeży
      ref.read(companyCatProvider.notifier).refresh();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // idle = apka nie na pierwszym planie -> user nie patrzy, kot może iść dalej
    final idle = state != AppLifecycleState.resumed;
    if (idle != _idle) {
      _idle = idle;
      _sendPresence();
    }
  }

  void _sendPresence() {
    if (kDebugMode) debugPrint('[cat] mount _sendPresence idle=$_idle');
    try {
      ref.read(liveClientProvider).reportPresence(surface: null, idle: _idle);
    } catch (e) {
      if (kDebugMode) debugPrint('[cat] _sendPresence error: $e');
    }
  }

  @override
  void dispose() {
    _heartbeat?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // gdy kot wskoczy na mój ekran -> zapytaj co przyniósł; gdy odejdzie -> wyczyść
    ref.listen<bool>(
      companyCatProvider.select((s) => s.onMyScreen),
      (prev, next) {
        if (next && prev != true) {
          ref.read(catGiftProvider.notifier).fetch();
          ref.read(companyCatProvider.notifier).fetchPats();
        } else if (!next) {
          ref.read(catGiftProvider.notifier).clear();
        }
      },
    );

    final onMyScreen = ref.watch(companyCatProvider).onMyScreen;
    final suppressed = ref.watch(catSuppressedProvider);

    if (!onMyScreen || suppressed) return const SizedBox.shrink();

    return const CatRoamLayer();
  }
}
