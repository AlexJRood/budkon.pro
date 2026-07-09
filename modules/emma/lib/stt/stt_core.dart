import 'package:flutter/foundation.dart';

enum SttMode {
  auto,
  preferOnDevice,
  requireOnDevice,
}

enum SttEngineKind {
  auto,
  speechAnalyzer,
  sfSpeechRecognizer,
  superbeeLocal,
  unknown,
}

extension SttModeX on SttMode {
  String get bridgeValue {
    switch (this) {
      case SttMode.auto:
        return 'auto';
      case SttMode.preferOnDevice:
        return 'preferOnDevice';
      case SttMode.requireOnDevice:
        return 'requireOnDevice';
    }
  }
}


enum SttCaptureProfile {
  dictation,
  meeting,
}

extension SttCaptureProfileX on SttCaptureProfile {
  String get bridgeValue {
    switch (this) {
      case SttCaptureProfile.dictation:
        return 'dictation';
      case SttCaptureProfile.meeting:
        return 'meeting';
    }
  }
}

enum SttPrivacyMode {
  transcriptOnly,
  temporaryAudioForSpeakerSeparation,
  retainedAudioArchive,
}

extension SttPrivacyModeX on SttPrivacyMode {
  String get bridgeValue {
    switch (this) {
      case SttPrivacyMode.transcriptOnly:
        return 'transcriptOnly';
      case SttPrivacyMode.temporaryAudioForSpeakerSeparation:
        return 'temporaryAudioForSpeakerSeparation';
      case SttPrivacyMode.retainedAudioArchive:
        return 'retainedAudioArchive';
    }
  }
}

enum SttSessionStatus {
  idle,
  initializing,
  ready,
  listening,
  stopping,
  error,
}

class SttCapabilities {
  const SttCapabilities({
    required this.available,
    required this.onDeviceAvailable,
    required this.permissionGranted,
    required this.platform,
    required this.locale,
    this.engine = SttEngineKind.unknown,
    this.supportsMeetingMode = false,
    this.supportsTemporaryAudioCapture = false,
    this.supportsSpeakerDiarization = false,
  });

  final bool available;
  final bool onDeviceAvailable;
  final bool permissionGranted;
  final String platform;
  final String locale;

  final SttEngineKind engine;
  final bool supportsMeetingMode;
  final bool supportsTemporaryAudioCapture;
  final bool supportsSpeakerDiarization;

  SttCapabilities copyWith({
    bool? available,
    bool? onDeviceAvailable,
    bool? permissionGranted,
    String? platform,
    String? locale,
    SttEngineKind? engine,
    bool? supportsMeetingMode,
    bool? supportsTemporaryAudioCapture,
    bool? supportsSpeakerDiarization,
  }) {
    return SttCapabilities(
      available: available ?? this.available,
      onDeviceAvailable: onDeviceAvailable ?? this.onDeviceAvailable,
      permissionGranted: permissionGranted ?? this.permissionGranted,
      platform: platform ?? this.platform,
      locale: locale ?? this.locale,
      engine: engine ?? this.engine,
      supportsMeetingMode: supportsMeetingMode ?? this.supportsMeetingMode,
      supportsTemporaryAudioCapture:
          supportsTemporaryAudioCapture ?? this.supportsTemporaryAudioCapture,
      supportsSpeakerDiarization:
          supportsSpeakerDiarization ?? this.supportsSpeakerDiarization,
    );
  }
}


class SttConfig {
  const SttConfig({
    required this.locale,
    this.mode = SttMode.auto,
    this.partialResults = true,
    this.autoPunctuation = true,
    this.listenFor = const Duration(minutes: 2),
    this.pauseFor = const Duration(seconds: 2),
    this.captureProfile = SttCaptureProfile.dictation,
    this.privacyMode = SttPrivacyMode.transcriptOnly,
    this.localModel,
    this.localLanguage,
  });

  final String locale;
  final SttMode mode;
  final bool partialResults;
  final bool autoPunctuation;
  final Duration listenFor;
  final Duration pauseFor;
  final SttCaptureProfile captureProfile;
  final SttPrivacyMode privacyMode;

  /// Optional override used by LocalDesktopSttEngine.
  /// Native/mobile engines ignore this.
  final String? localModel;

  /// Optional override used by LocalDesktopSttEngine.
  /// Example: "pl", "en", "de".
  /// Native/mobile engines ignore this.
  final String? localLanguage;
}




enum SttEngineEventType {
  availability,
  listening,
  partial,
  finalResult,
  error,
}

class SttEngineEvent {
  const SttEngineEvent({
    required this.type,
    this.text,
    this.error,
    this.listening,
    this.capabilities,
  });

  final SttEngineEventType type;
  final String? text;
  final String? error;
  final bool? listening;
  final SttCapabilities? capabilities;
}

abstract class SttEngine {
  Stream<SttEngineEvent> get events;

  Future<SttCapabilities> getCapabilities({required String locale});

  Future<bool> requestPermissions();

  Future<void> start(SttConfig config);

  Future<void> stop();

  Future<void> cancel();

  Future<void> dispose();
}

class SttSessionState {
  const SttSessionState({
    this.status = SttSessionStatus.idle,
    this.capabilities,
    this.committedText = '',
    this.liveText = '',
    this.error,
  });

  final SttSessionStatus status;
  final SttCapabilities? capabilities;
  final String committedText;
  final String liveText;
  final String? error;

  bool get isListening => status == SttSessionStatus.listening;
  bool get isStarting => status == SttSessionStatus.initializing;
  bool get isStopping => status == SttSessionStatus.stopping;
  bool get isBusy => isStarting || isListening || isStopping;

  String get displayText {
    final left = committedText.trimRight();
    final right = liveText.trimLeft();

    if (left.isEmpty) return right;
    if (right.isEmpty) return left;

    if (left.endsWith('\n') || left.endsWith(' ')) {
      return '$left$right';
    }

    return '$left $right';
  }

  SttSessionState copyWith({
    SttSessionStatus? status,
    SttCapabilities? capabilities,
    String? committedText,
    String? liveText,
    String? error,
    bool clearError = false,
  }) {
    return SttSessionState(
      status: status ?? this.status,
      capabilities: capabilities ?? this.capabilities,
      committedText: committedText ?? this.committedText,
      liveText: liveText ?? this.liveText,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

String sttPlatformName() {
  if (kIsWeb) return 'web';

  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return 'android';
    case TargetPlatform.iOS:
      return 'ios';
    case TargetPlatform.macOS:
      return 'macos';
    case TargetPlatform.windows:
      return 'windows';
    case TargetPlatform.linux:
      return 'linux';
    case TargetPlatform.fuchsia:
      return 'fuchsia';
  }
}