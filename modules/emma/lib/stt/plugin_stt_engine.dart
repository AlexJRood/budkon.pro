import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'stt_core.dart';

class PluginSttEngine implements SttEngine {
  PluginSttEngine({
    required this.localeFallbackResolver,
  });

  final String Function(String locale) localeFallbackResolver;

  final stt.SpeechToText _stt = stt.SpeechToText();
  final StreamController<SttEngineEvent> _eventsController =
      StreamController<SttEngineEvent>.broadcast();

  bool _initialized = false;
  bool _initAttempted = false;

  @override
  Stream<SttEngineEvent> get events => _eventsController.stream;

  Future<void> _ensureInitialized() async {
    if (_initialized || _initAttempted) return;

    _initAttempted = true;

    try {
      final ok = await _stt.initialize(
        onStatus: _handleStatus,
        onError: _handleError,
      );

      _initialized = ok;

      if (_initialized) {
        _stt.unexpectedPhraseAggregator = _aggregateUnexpectedPhrases;
      }
    } catch (e, stack) {
      _initialized = false;
      if (kDebugMode) {
        debugPrint('PluginSttEngine init failed: $e\n$stack');
      }
    }
  }

  String _aggregateUnexpectedPhrases(List<String> phrases) {
    final cleaned = phrases
        .map(_normalizeSpaces)
        .where((e) => e.isNotEmpty)
        .toList(growable: false);

    if (cleaned.isEmpty) return '';
    if (cleaned.length == 1) return cleaned.first;

    return cleaned.join('. ');
  }

  void _handleStatus(String status) {
    if (kDebugMode) {
      debugPrint('PluginSttEngine status: $status');
    }

    if (status == 'listening') {
      _eventsController.add(
        const SttEngineEvent(
          type: SttEngineEventType.listening,
          listening: true,
        ),
      );
      return;
    }

    if (status == 'done' ||
        status == 'notListening' ||
        status == 'doneNoResult') {
      _eventsController.add(
        const SttEngineEvent(
          type: SttEngineEventType.listening,
          listening: false,
        ),
      );
    }
  }

  void _handleError(SpeechRecognitionError error) {
    _eventsController.add(
      SttEngineEvent(
        type: SttEngineEventType.error,
        error: error.errorMsg,
      ),
    );
  }

  void _handleResult(SpeechRecognitionResult result) {
    final text = _normalizeSpaces(result.recognizedWords);
    if (text.isEmpty) return;

    _eventsController.add(
      SttEngineEvent(
        type: result.finalResult
            ? SttEngineEventType.finalResult
            : SttEngineEventType.partial,
        text: text,
      ),
    );
  }

  String _normalizeSpaces(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _normalizeLocale(String value) {
    return value.replaceAll('_', '-').trim();
  }

  bool _localeMatches(String requested, String candidate) {
    final left = _normalizeLocale(requested).toLowerCase();
    final right = _normalizeLocale(candidate).toLowerCase();

    if (left == right) return true;

    final leftLanguage = left.split('-').first;
    final rightLanguage = right.split('-').first;

    return leftLanguage == rightLanguage;
  }

  Future<bool> _isLocaleSupported(String locale) async {
    if (!_initialized) return false;

    final locales = await _stt.locales();
    return locales.any((item) => _localeMatches(locale, item.localeId));
  }

  @override
  Future<SttCapabilities> getCapabilities({required String locale}) async {
    await _ensureInitialized();

    if (!_initialized) {
      return SttCapabilities(
        available: false,
        onDeviceAvailable: false,
        permissionGranted: false,
        platform: sttPlatformName(),
        locale: _normalizeLocale(locale),
      );
    }

    final localeSupported = await _isLocaleSupported(locale);
    final permissionGranted = await _stt.hasPermission;

    return SttCapabilities(
      available: _stt.isAvailable && localeSupported,
      onDeviceAvailable: localeSupported,
      permissionGranted: permissionGranted,
      platform: sttPlatformName(),
      locale: _normalizeLocale(locale),
    );
  }

  @override
  Future<bool> requestPermissions() async {
    await _ensureInitialized();
    if (!_initialized) return false;
    return await _stt.hasPermission;
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
    if (_canUseCapabilities(primaryCaps, config.mode)) {
      return config.locale;
    }

    final fallback = localeFallbackResolver(config.locale);
    if (_normalizeLocale(fallback).toLowerCase() !=
        _normalizeLocale(config.locale).toLowerCase()) {
      final fallbackCaps = await getCapabilities(locale: fallback);
      if (_canUseCapabilities(fallbackCaps, config.mode)) {
        return fallback;
      }
    }

    if (config.mode == SttMode.requireOnDevice) {
      throw StateError('${'no_supported_on_device_locale'.tr} ${config.locale}.');
    }

    throw StateError('${'no_supported_stt_locale'.tr} ${config.locale}.');
  }

  stt.ListenMode get _listenMode {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return stt.ListenMode.dictation;
    }
    return stt.ListenMode.confirmation;
  }

  @override
  Future<void> start(SttConfig config) async {
    await _ensureInitialized();

    if (!_initialized) {
      throw StateError('stt_unavailable_browser'.tr);
    }

    final resolvedLocale = await _resolveLocale(config);

    final started = await _stt.listen(
      localeId: resolvedLocale,
      listenFor: config.listenFor,
      pauseFor: config.pauseFor,
      onResult: _handleResult,
      listenOptions: stt.SpeechListenOptions(
        listenMode: _listenMode,
        partialResults: config.partialResults,
        cancelOnError: true,
        autoPunctuation: config.autoPunctuation &&
            defaultTargetPlatform == TargetPlatform.iOS,
      ),
    );

    if (!started) {
      throw StateError('failed_to_start_plugin_stt'.tr);
    }

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

  @override
  Future<void> stop() async {
    try {
      await _stt.stop();
    } catch (_) {}
  }

  @override
  Future<void> cancel() async {
    try {
      await _stt.cancel();
    } catch (_) {}
  }

  @override
  Future<void> dispose() async {
    try {
      await _stt.stop();
    } catch (_) {}

    await _eventsController.close();
  }
}