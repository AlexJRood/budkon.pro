import 'dart:async';

import 'package:emma/stt/services/emma_speech_bridge.dart';
import 'package:get/get_utils/get_utils.dart';

import 'stt_core.dart';

class NativeIosSttEngine implements SttEngine {
  NativeIosSttEngine({
    required EmmaSpeechBridge bridge,
    required this.localeFallbackResolver,
  }) : _bridge = bridge {
    _bridgeSubscription = _bridge.events.listen(_handleBridgeEvent);
  }

  final EmmaSpeechBridge _bridge;
  final String Function(String locale) localeFallbackResolver;

  final StreamController<SttEngineEvent> _eventsController =
      StreamController<SttEngineEvent>.broadcast();

  StreamSubscription<EmmaSpeechEvent>? _bridgeSubscription;
  SttCapabilities? _lastCapabilities;

  @override
  Stream<SttEngineEvent> get events => _eventsController.stream;

  SttEngineKind _parseEngineKind(String raw) {
    switch (raw) {
      case 'speechAnalyzer':
        return SttEngineKind.speechAnalyzer;
      case 'sfSpeechRecognizer':
        return SttEngineKind.sfSpeechRecognizer;
      case 'auto':
        return SttEngineKind.auto;
      default:
        return SttEngineKind.unknown;
    }
  }

  @override
  Future<SttCapabilities> getCapabilities({required String locale}) async {
    final raw = await _bridge.getCapabilities(locale: locale);

    final caps = SttCapabilities(
      available: raw.available,
      onDeviceAvailable: raw.onDeviceAvailable,
      permissionGranted: raw.permissionGranted,
      platform: raw.platform,
      locale: raw.locale,
      engine: _parseEngineKind(raw.engine),
      supportsMeetingMode: raw.supportsMeetingMode,
      supportsTemporaryAudioCapture: raw.supportsTemporaryAudioCapture,
      supportsSpeakerDiarization: raw.supportsSpeakerDiarization,
    );

    _lastCapabilities = caps;
    return caps;
  }

  @override
  Future<bool> requestPermissions() async {
    return _bridge.requestPermissions();
  }

  bool _canUseCapabilities(SttCapabilities caps, SttMode mode) {
    if (!caps.available) return false;

    if (mode == SttMode.requireOnDevice) {
      return caps.onDeviceAvailable;
    }

    return true;
  }

  Future<String> _resolveLocale(SttConfig config) async {
    final primaryCaps = await getCapabilities(locale: config.locale);
    final fallbackLocale = localeFallbackResolver(config.locale);

    final hasDifferentFallback =
        fallbackLocale.replaceAll('_', '-').toLowerCase() !=
            config.locale.replaceAll('_', '-').toLowerCase();

    if (config.mode == SttMode.requireOnDevice) {
      if (_canUseCapabilities(primaryCaps, config.mode)) {
        return config.locale;
      }

      if (hasDifferentFallback) {
        final fallbackCaps = await getCapabilities(locale: fallbackLocale);
        if (_canUseCapabilities(fallbackCaps, config.mode)) {
          return fallbackLocale;
        }
      }

      throw StateError('${'no_on_device_stt_locale'.tr} ${config.locale}.');
    }

    if (config.mode == SttMode.preferOnDevice) {
      if (primaryCaps.available && primaryCaps.onDeviceAvailable) {
        return config.locale;
      }

      if (hasDifferentFallback) {
        final fallbackCaps = await getCapabilities(locale: fallbackLocale);
        if (fallbackCaps.available && fallbackCaps.onDeviceAvailable) {
          return fallbackLocale;
        }
      }

      if (primaryCaps.available) {
        return config.locale;
      }

      if (hasDifferentFallback) {
        final fallbackCaps = await getCapabilities(locale: fallbackLocale);
        if (fallbackCaps.available) {
          return fallbackLocale;
        }
      }

      throw StateError('${'no_available_stt_locale'.tr} ${config.locale}.');
    }

    if (primaryCaps.available) {
      return config.locale;
    }

    if (hasDifferentFallback) {
      final fallbackCaps = await getCapabilities(locale: fallbackLocale);
      if (fallbackCaps.available) {
        return fallbackLocale;
      }
    }

    throw StateError('${'no_available_stt_locale'.tr} ${config.locale}.');
  }

  @override
  Future<void> start(SttConfig config) async {
    final resolvedLocale = await _resolveLocale(config);

    await _bridge.start(
      locale: resolvedLocale,
      mode: config.mode.bridgeValue,
      captureProfile: config.captureProfile.bridgeValue,
      privacyMode: config.privacyMode.bridgeValue,
    );

    final caps = await getCapabilities(locale: resolvedLocale);

    _eventsController.add(
      SttEngineEvent(
        type: SttEngineEventType.availability,
        capabilities: caps,
      ),
    );

    _eventsController.add(
      const SttEngineEvent(
        type: SttEngineEventType.listening,
        listening: true,
      ),
    );
  }

  void _handleBridgeEvent(EmmaSpeechEvent event) {
    switch (event.type) {
      case EmmaSpeechEventType.availability:
        final nextCapabilities = (_lastCapabilities ??
                const SttCapabilities(
                  available: false,
                  onDeviceAvailable: false,
                  permissionGranted: false,
                  platform: 'ios',
                  locale: '',
                  engine: SttEngineKind.unknown,
                  supportsMeetingMode: false,
                  supportsTemporaryAudioCapture: false,
                  supportsSpeakerDiarization: false,
                ))
            .copyWith(
          available: event.available,
          onDeviceAvailable: event.onDevice,
        );

        _lastCapabilities = nextCapabilities;

        _eventsController.add(
          SttEngineEvent(
            type: SttEngineEventType.availability,
            capabilities: nextCapabilities,
          ),
        );
        break;

      case EmmaSpeechEventType.listening:
        _eventsController.add(
          SttEngineEvent(
            type: SttEngineEventType.listening,
            listening: event.listening,
          ),
        );
        break;

      case EmmaSpeechEventType.partial:
        _eventsController.add(
          SttEngineEvent(
            type: SttEngineEventType.partial,
            text: event.text,
          ),
        );
        break;

      case EmmaSpeechEventType.finalResult:
        _eventsController.add(
          SttEngineEvent(
            type: SttEngineEventType.finalResult,
            text: event.text,
          ),
        );
        break;

      case EmmaSpeechEventType.permission:
        if (_lastCapabilities != null) {
          _lastCapabilities = _lastCapabilities!.copyWith(
            permissionGranted: event.granted,
          );

          _eventsController.add(
            SttEngineEvent(
              type: SttEngineEventType.availability,
              capabilities: _lastCapabilities,
            ),
          );
        }
        break;

      case EmmaSpeechEventType.error:
        _eventsController.add(
          SttEngineEvent(
            type: SttEngineEventType.error,
            error: event.message ??  'unknown_native_ios_stt_error'.tr,
          ),
        );
        break;
    }
  }

  @override
  Future<void> stop() async {
    await _bridge.stop();
  }

  @override
  Future<void> cancel() async {
    await _bridge.cancel();
  }

  @override
  Future<void> dispose() async {
    await _bridgeSubscription?.cancel();
    await _bridge.dispose();
    await _eventsController.close();
  }
}