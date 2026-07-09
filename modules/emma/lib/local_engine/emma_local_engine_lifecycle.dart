import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../library/emma_local_model_manager_provider.dart';
import '../provider/runtime_provider.dart';
import 'local_engine_manager.dart';

/// Watches [emmaEffectiveRuntimeModeProvider] and automatically starts or
/// stops the local Superbee binary when Emma switches to/from a local mode.
///
/// Also bridges [LocalEngineManager.state.token] into
/// [emmaLocalEngineTokenProvider] so that Emma's API calls always use the
/// real token written by the daemon into config.json.
///
/// Only active on desktop platforms (Windows / macOS / Linux).
/// On mobile or web Emma always uses the cloud.
///
/// Wire up in your app's ProviderScope or top-level widget:
/// ```dart
/// ref.listen(emmaLocalEngineLifecycleProvider, (_, __) {});
/// ```
final emmaLocalEngineLifecycleProvider = Provider<void>((ref) {
  if (kIsWeb) return;
  if (!_isDesktop) return;

  final manager = ref.watch(localEngineManagerProvider);

  // ── runtime mode: start / stop daemon ───────────────────────────────────
  ref.listen<EmmaRuntimeMode>(
    emmaEffectiveRuntimeModeProvider,
    (previous, next) {
      final wasLocal = previous?.config.useLocalEngine ?? false;
      final isLocal  = next.config.useLocalEngine;

      if (isLocal && !wasLocal) {
        manager.start();
      } else if (!isLocal && wasLocal) {
        manager.stop();
      }
    },
    fireImmediately: true,
  );

  // ── token bridge: propagate real token to Emma's API provider ────────────
  // LocalEngineManager reads the token from config.json after the daemon
  // starts; we forward it so that EmmaLocalEngineApi uses it.
  ref.listen<LocalEngineState>(
    localEngineManagerProvider.select((m) => m.state),
    (_, next) {
      final token = next.token;
      if (token != null && token.isNotEmpty) {
        ref.read(emmaLocalEngineTokenProvider.notifier).state = token;
      }
    },
    fireImmediately: true,
  );
});

bool get _isDesktop =>
    Platform.isWindows || Platform.isMacOS || Platform.isLinux;
