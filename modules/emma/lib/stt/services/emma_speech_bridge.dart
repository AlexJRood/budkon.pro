import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final emmaSpeechBridgeProvider = Provider<EmmaSpeechBridge>((ref) {
  return EmmaSpeechBridge();
});

enum EmmaSpeechEventType {
  availability,
  permission,
  listening,
  partial,
  finalResult,
  error,
}

class EmmaSpeechCapabilities {
  const EmmaSpeechCapabilities({
    required this.available,
    required this.onDeviceAvailable,
    required this.permissionGranted,
    required this.platform,
    required this.locale,
    required this.engine,
    required this.speechAnalyzerAvailable,
    required this.speechAnalyzerLocaleSupported,
    required this.speechAnalyzerLocaleInstalled,
    required this.sfSpeechRecognizerAvailable,
    required this.supportsMeetingMode,
    required this.supportsTemporaryAudioCapture,
    required this.supportsSpeakerDiarization,
  });

  final bool available;
  final bool onDeviceAvailable;
  final bool permissionGranted;
  final String platform;
  final String locale;

  final String engine;
  final bool speechAnalyzerAvailable;
  final bool speechAnalyzerLocaleSupported;
  final bool speechAnalyzerLocaleInstalled;
  final bool sfSpeechRecognizerAvailable;

  final bool supportsMeetingMode;
  final bool supportsTemporaryAudioCapture;
  final bool supportsSpeakerDiarization;

  factory EmmaSpeechCapabilities.fromMap(Map<String, dynamic> map) {
    return EmmaSpeechCapabilities(
      available: map['available'] == true,
      onDeviceAvailable: map['onDeviceAvailable'] == true,
      permissionGranted: map['permissionGranted'] == true,
      platform: (map['platform'] ?? '').toString(),
      locale: (map['locale'] ?? '').toString(),
      engine: (map['engine'] ?? 'sfSpeechRecognizer').toString(),
      speechAnalyzerAvailable: map['speechAnalyzerAvailable'] == true,
      speechAnalyzerLocaleSupported:
          map['speechAnalyzerLocaleSupported'] == true,
      speechAnalyzerLocaleInstalled:
          map['speechAnalyzerLocaleInstalled'] == true,
      sfSpeechRecognizerAvailable:
          map['sfSpeechRecognizerAvailable'] == true,
      supportsMeetingMode: map['supportsMeetingMode'] == true,
      supportsTemporaryAudioCapture:
          map['supportsTemporaryAudioCapture'] == true,
      supportsSpeakerDiarization:
          map['supportsSpeakerDiarization'] == true,
    );
  }
}

class EmmaSpeechEvent {
  const EmmaSpeechEvent({
    required this.type,
    this.text,
    this.message,
    this.code,
    this.available,
    this.granted,
    this.listening,
    this.isFinal,
    this.onDevice,
    this.confidence,
  });

  final EmmaSpeechEventType type;
  final String? text;
  final String? message;
  final String? code;
  final bool? available;
  final bool? granted;
  final bool? listening;
  final bool? isFinal;
  final bool? onDevice;
  final double? confidence;

  factory EmmaSpeechEvent.fromDynamic(dynamic raw) {
    final map = Map<String, dynamic>.from(raw as Map);

    EmmaSpeechEventType parseType(String value) {
      switch (value) {
        case 'availability':
          return EmmaSpeechEventType.availability;
        case 'permission':
          return EmmaSpeechEventType.permission;
        case 'listening':
          return EmmaSpeechEventType.listening;
        case 'partial':
          return EmmaSpeechEventType.partial;
        case 'final':
          return EmmaSpeechEventType.finalResult;
        case 'error':
        default:
          return EmmaSpeechEventType.error;
      }
    }

    return EmmaSpeechEvent(
      type: parseType((map['type'] ?? 'error').toString()),
      text: map['text']?.toString(),
      message: map['message']?.toString(),
      code: map['code']?.toString(),
      available: map['available'] as bool?,
      granted: map['granted'] as bool?,
      listening: map['listening'] as bool?,
      isFinal: map['isFinal'] as bool?,
      onDevice: map['onDevice'] as bool?,
      confidence: map['confidence'] is num
          ? (map['confidence'] as num).toDouble()
          : null,
    );
  }
}

class EmmaSpeechBridge {
  static const MethodChannel _methodChannel =
      MethodChannel('hously/emma_speech/methods');
  static const EventChannel _eventChannel =
      EventChannel('hously/emma_speech/events');

  Stream<EmmaSpeechEvent>? _cachedStream;

  Stream<EmmaSpeechEvent> get events {
    _cachedStream ??= _eventChannel
        .receiveBroadcastStream()
        .map(EmmaSpeechEvent.fromDynamic)
        .asBroadcastStream();
    return _cachedStream!;
  }

  Future<EmmaSpeechCapabilities> getCapabilities({String? locale}) async {
    final raw = await _methodChannel.invokeMapMethod<String, dynamic>(
          'getCapabilities',
          locale == null ? null : {'locale': locale},
        ) ??
        <String, dynamic>{};

    return EmmaSpeechCapabilities.fromMap(raw);
  }

  Future<Map<String, dynamic>> getActiveSessionSnapshot() async {
    final raw = await _methodChannel.invokeMapMethod<String, dynamic>(
          'getActiveSessionSnapshot',
        ) ??
        <String, dynamic>{};

    return Map<String, dynamic>.from(raw);
  }

  Future<bool> requestPermissions() async {
    final raw = await _methodChannel.invokeMapMethod<String, dynamic>(
          'requestPermissions',
        ) ??
        <String, dynamic>{};

    return raw['granted'] == true;
  }

  Future<void> start({
    String locale = 'en-US',
    String mode = 'auto',
    String captureProfile = 'dictation',
    String privacyMode = 'transcriptOnly',
  }) async {
    await _methodChannel.invokeMethod<void>('start', {
      'locale': locale,
      'mode': mode,
      'captureProfile': captureProfile,
      'privacyMode': privacyMode,
    });
  }

  Future<void> stop() async {
    await _methodChannel.invokeMethod<void>('stop');
  }

  Future<void> cancel() async {
    await _methodChannel.invokeMethod<void>('cancel');
  }

  Future<void> dispose() async {
    await _methodChannel.invokeMethod<void>('dispose');
  }
}