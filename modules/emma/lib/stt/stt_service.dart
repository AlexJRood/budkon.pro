// emma/stt/stt_service.dart

import 'dart:async';

import 'package:emma/provider/stt_model_provider.dart';
import 'package:emma/stt/local_desktop_stt_engine.dart';
import 'package:emma/stt/services/local_superbee_stt_client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/translate/language_provider.dart';

import 'package:emma/stt/services/emma_speech_bridge.dart';
import 'native_ios_stt_engine.dart';
import 'plugin_stt_engine.dart';
import 'stt_core.dart';

typedef SttEngineBuilder = SttEngine Function();

/// Only relevant on macOS — allows switching from native SFSpeechRecognizer
/// to the local Superbee engine when the user explicitly enables it.
final meetingUseSuperbeeMacOsProvider = StateProvider<bool>((ref) => false);

bool _isDesktopPlatform() {
  if (kIsWeb) return false;

  return defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux;
}

bool _isNativeSpeechPlatform() {
  if (kIsWeb) return false;

  return defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;
}

final sttEngineBuilderProvider = Provider<SttEngineBuilder>((ref) {
  final macOsUseSuperbee = ref.watch(meetingUseSuperbeeMacOsProvider);

  return () {
    if (_isDesktopPlatform()) {
      return LocalDesktopSttEngine(
        client: ref.read(localSuperbeeSttClientProvider),
        selectedPresetResolver: () => ref.read(emmaSelectedSttProvider),
      );
    }

    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.macOS &&
        macOsUseSuperbee) {
      return LocalDesktopSttEngine(
        client: ref.read(localSuperbeeSttClientProvider),
        selectedPresetResolver: () => ref.read(emmaSelectedSttProvider),
      );
    }

    if (_isNativeSpeechPlatform()) {
      return NativeIosSttEngine(
        bridge: ref.read(emmaSpeechBridgeProvider),
        localeFallbackResolver: emmaSpeechLocaleFallback,
      );
    }

    return PluginSttEngine(
      localeFallbackResolver: emmaSpeechLocaleFallback,
    );
  };
});

final sttSessionProvider = StateNotifierProvider.autoDispose
    .family<SttSessionController, SttSessionState, String>((ref, sessionId) {
  final engine = ref.read(sttEngineBuilderProvider)();
  return SttSessionController(engine);
});

class SttSessionController extends StateNotifier<SttSessionState> {
  SttSessionController(this._engine) : super(const SttSessionState()) {
    _eventSubscription = _engine.events.listen(_handleEngineEvent);
  }

  final SttEngine _engine;
  StreamSubscription<SttEngineEvent>? _eventSubscription;

  Future<void> refreshCapabilities(String locale) async {
    try {
      final caps = await _engine.getCapabilities(locale: locale);

      state = state.copyWith(
        capabilities: caps,
        status: state.isBusy ? state.status : SttSessionStatus.ready,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        status: SttSessionStatus.error,
        error: '${'failed_to_read_stt_capabilities'.tr}: $e',
      );
    }
  }

  void seedBaseText(String value) {
    state = state.copyWith(
      committedText: value.trimRight(),
      liveText: '',
      clearError: true,
    );
  }

  void clearText() {
    state = state.copyWith(
      committedText: '',
      liveText: '',
      clearError: true,
    );
  }

  Future<void> start(SttConfig config) async {
    if (state.isBusy) return;

    state = state.copyWith(
      status: SttSessionStatus.initializing,
      liveText: '',
      clearError: true,
    );

    try {
      final granted = await _engine.requestPermissions();
      if (!granted) {
        state = state.copyWith(
          status: SttSessionStatus.error,
          error: 'microphone_permission_not_granted'.tr,
        );
        return;
      }

      final caps = await _engine.getCapabilities(locale: config.locale);
      if (!caps.available) {
        state = state.copyWith(
          capabilities: caps,
          status: SttSessionStatus.error,
          error: '${'stt_not_available_for_locale'.tr} ${config.locale}.',
        );
        return;
      }

      if (config.mode == SttMode.requireOnDevice &&
          !caps.onDeviceAvailable) {
        state = state.copyWith(
          capabilities: caps,
          status: SttSessionStatus.error,
          error: '${'on_device_stt_not_available'.tr} ${config.locale}.',
        );
        return;
      }

      state = state.copyWith(
        capabilities: caps,
        status: SttSessionStatus.initializing,
        clearError: true,
      );

      await _engine.start(config);

      state = state.copyWith(
        status: SttSessionStatus.listening,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        status: SttSessionStatus.error,
        error: '${'failed_to_start_stt'.tr}: $e',
      );
    }
  }

  Future<void> stop() async {
    if (!state.isBusy) return;

    state = state.copyWith(
      status: SttSessionStatus.stopping,
      clearError: true,
    );

    try {
      await _engine.stop();
    } catch (e) {
      state = state.copyWith(
        status: SttSessionStatus.error,
        error: '${'failed_to_stop_stt'.tr}: $e',
      );
    }
  }

  Future<void> cancel({bool clearTextOnCancel = false}) async {
    try {
      await _engine.cancel();

      state = state.copyWith(
        status: SttSessionStatus.idle,
        liveText: '',
        committedText:
            clearTextOnCancel ? '' : state.committedText,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        status: SttSessionStatus.error,
        error: '${'failed_to_cancel_stt'.tr}: $e',
      );
    }
  }

  void _handleEngineEvent(SttEngineEvent event) {
    switch (event.type) {
      case SttEngineEventType.availability:
        if (event.capabilities != null) {
          state = state.copyWith(
            capabilities: event.capabilities,
            clearError: true,
          );
        }
        break;

      case SttEngineEventType.listening:
        state = state.copyWith(
          status: (event.listening ?? false)
              ? SttSessionStatus.listening
              : SttSessionStatus.ready,
          clearError: true,
        );
        break;

      case SttEngineEventType.partial:
        final text = _normalizeSpaces(event.text ?? '');
        if (text.isEmpty) return;

        state = state.copyWith(
          liveText: text,
          status: SttSessionStatus.listening,
          clearError: true,
        );
        break;

      case SttEngineEventType.finalResult:
        final text = _normalizeSpaces(event.text ?? '');

        if (text.isEmpty) {
          state = state.copyWith(
            liveText: '',
            status: SttSessionStatus.ready,
            clearError: true,
          );
          return;
        }

        state = state.copyWith(
          committedText: _appendCommittedChunk(
            state.committedText,
            text,
          ),
          liveText: '',
          status: SttSessionStatus.ready,
          clearError: true,
        );
        break;

      case SttEngineEventType.error:
        state = state.copyWith(
          liveText: '',
          status: SttSessionStatus.error,
          error: event.error ?? 'unknown_stt_error'.tr,
        );
        break;
    }
  }

  String _normalizeSpaces(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _appendCommittedChunk(String base, String chunk) {
    final left = base.trimRight();
    var right = _normalizeSpaces(chunk);

    if (right.isEmpty) return left;

    if (!RegExp(r'[.!?…]$').hasMatch(right)) {
      right = '$right.';
    }

    if (left.isEmpty) return right;

    if (left.endsWith('\n') || left.endsWith(' ')) {
      return '$left$right';
    }

    return '$left $right';
  }

  @override
  void dispose() {
    unawaited(_eventSubscription?.cancel());
    unawaited(_engine.dispose());
    super.dispose();
  }
}