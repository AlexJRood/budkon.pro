// emma/stt/local_desktop_stt_engine.dart

import 'dart:async';
import 'dart:io';

import 'package:emma/provider/stt_model_provider.dart';
import 'package:emma/stt/services/local_superbee_stt_client.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'stt_core.dart';

class LocalDesktopSttEngine implements SttEngine {
  LocalDesktopSttEngine({
    required this.client,
    required this.selectedPresetResolver,
    this.chunkDuration = const Duration(seconds: 5),
  });

  final LocalSuperbeeSttClient client;
  final EmmaSttPreset Function() selectedPresetResolver;
  final Duration chunkDuration;

  final AudioRecorder _recorder = AudioRecorder();
  final StreamController<SttEngineEvent> _eventsController =
      StreamController<SttEngineEvent>.broadcast();

  Future<void>? _loopFuture;
  Completer<void>? _stopSignal;

  bool _running = false;
  bool _cancelRequested = false;
  bool _stopRequested = false;

  String _accumulatedText = '';
  String _lastChunkText = '';
  String? _currentAudioPath;

  @override
  Stream<SttEngineEvent> get events => _eventsController.stream;

  @override
  Future<SttCapabilities> getCapabilities({required String locale}) async {
    try {
      await client.health();

      final permissionGranted = await _recorder.hasPermission();

      return SttCapabilities(
        available: true,
        onDeviceAvailable: true,
        permissionGranted: permissionGranted,
        platform: sttPlatformName(),
        locale: _normalizeLocale(locale),
        engine: SttEngineKind.superbeeLocal,
        supportsMeetingMode: true,
        supportsTemporaryAudioCapture: true,
        supportsSpeakerDiarization: false,
      );
    } catch (_) {
      return SttCapabilities(
        available: false,
        onDeviceAvailable: false,
        permissionGranted: false,
        platform: sttPlatformName(),
        locale: _normalizeLocale(locale),
        engine: SttEngineKind.superbeeLocal,
      );
    }
  }

  @override
  Future<bool> requestPermissions() async {
    return _recorder.hasPermission();
  }

  @override
  Future<void> start(SttConfig config) async {
    if (_running) {
      throw StateError('Local desktop STT is already running.');
    }

    final preset = selectedPresetResolver();

    final selectedModel = _firstNotEmpty([
      config.localModel,
      preset.sttModel,
    ]);

    final selectedLanguage = _firstNotEmpty([
      config.localLanguage,
      preset.language,
      _languageFromLocale(config.locale),
    ]);

    if (selectedModel.isEmpty) {
      throw StateError('No local STT model selected.');
    }

    await client.loadModel(selectedModel);

    _running = true;
    _cancelRequested = false;
    _stopRequested = false;
    _accumulatedText = '';
    _lastChunkText = '';
    _stopSignal = Completer<void>();

    final caps = await getCapabilities(locale: config.locale);

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

    _loopFuture = _runChunkLoop(
      config: config,
      model: selectedModel,
      language: selectedLanguage,
    );
  }

  Future<void> _runChunkLoop({
    required SttConfig config,
    required String model,
    required String language,
  }) async {
    final startedAt = DateTime.now();
    final deadline = startedAt.add(config.listenFor);

    try {
      while (!_stopRequested && !_cancelRequested) {
        final remaining = deadline.difference(DateTime.now());

        if (remaining <= Duration.zero) {
          break;
        }

        final slice = remaining < chunkDuration ? remaining : chunkDuration;

        final audioPath = await _createChunkPath();
        _currentAudioPath = audioPath;

        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.wav,
            sampleRate: 16000,
            numChannels: 1,
          ),
          path: audioPath,
        );

        await _waitForStopOrTimeout(slice);

        final stoppedPath = await _safeStopRecorder();
        final chunkPath = (stoppedPath ?? audioPath).trim();

        if (_cancelRequested) {
          break;
        }

        if (chunkPath.isEmpty) {
          continue;
        }

        final file = File(chunkPath);

        if (!await file.exists()) {
          continue;
        }

        final size = await file.length();

        if (size <= 64) {
          continue;
        }

        final text = await _transcribeChunk(
          filePath: chunkPath,
          model: model,
          language: language,
        );

        final normalized = _normalizeSpaces(text);

        if (normalized.isEmpty) {
          continue;
        }

        _accumulatedText = _appendChunk(
          base: _accumulatedText,
          chunk: normalized,
        );

        if (_accumulatedText.trim().isNotEmpty) {
          _eventsController.add(
            SttEngineEvent(
              type: SttEngineEventType.partial,
              text: _accumulatedText,
            ),
          );
        }
      }

      if (_cancelRequested) {
        _eventsController.add(
          const SttEngineEvent(
            type: SttEngineEventType.listening,
            listening: false,
          ),
        );
        return;
      }

      final finalText = _normalizeSpaces(_accumulatedText);

      if (finalText.isNotEmpty) {
        _eventsController.add(
          SttEngineEvent(
            type: SttEngineEventType.finalResult,
            text: finalText,
          ),
        );
      }

      _eventsController.add(
        const SttEngineEvent(
          type: SttEngineEventType.listening,
          listening: false,
        ),
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('LocalDesktopSttEngine loop failed: $e');
        debugPrint('$st');
      }

      _eventsController.add(
        SttEngineEvent(
          type: SttEngineEventType.error,
          error: e.toString(),
        ),
      );
    } finally {
      try {
        await _safeStopRecorder();
      } catch (_) {}

      _running = false;
      _currentAudioPath = null;
      _stopSignal = null;
      _loopFuture = null;
    }
  }

  Future<String> _transcribeChunk({
    required String filePath,
    required String model,
    required String language,
  }) async {
    final prompt = _lastPrompt();

    final result = await client.transcribeFile(
      filePath: filePath,
      model: model,
      language: language,
      task: 'transcribe',
      autoLoad: true,
      vadFilter: true,
      wordTimestamps: false,
      returnSegments: false,
      beamSize: 5,
      initialPrompt: prompt,
    );

    return result.text;
  }

  String _lastPrompt() {
    final clean = _normalizeSpaces(_accumulatedText);

    if (clean.length <= 400) {
      return clean;
    }

    return clean.substring(clean.length - 400);
  }

  Future<void> _waitForStopOrTimeout(Duration duration) async {
    final signal = _stopSignal;

    if (signal == null) {
      await Future.delayed(duration);
      return;
    }

    await Future.any([
      Future.delayed(duration),
      signal.future,
    ]);
  }

  Future<String?> _safeStopRecorder() async {
    try {
      final recording = await _recorder.isRecording();

      if (!recording) {
        return _currentAudioPath;
      }

      return await _recorder.stop();
    } catch (_) {
      return _currentAudioPath;
    }
  }

  String _appendChunk({
    required String base,
    required String chunk,
  }) {
    final cleanBase = _normalizeSpaces(base);
    final cleanChunk = _normalizeSpaces(chunk);

    if (cleanChunk.isEmpty) return cleanBase;

    if (cleanChunk == _lastChunkText) {
      return cleanBase;
    }

    _lastChunkText = cleanChunk;

    if (cleanBase.isEmpty) {
      return cleanChunk;
    }

    if (cleanBase.endsWith(cleanChunk)) {
      return cleanBase;
    }

    return '$cleanBase $cleanChunk'.trim();
  }

  Future<String> _createChunkPath() async {
    final dir = await getTemporaryDirectory();
    final sttDir = Directory(p.join(dir.path, 'superbee_stt_chunks'));

    if (!await sttDir.exists()) {
      await sttDir.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;

    return p.join(
      sttDir.path,
      'superbee_stt_$timestamp.wav',
    );
  }

  String _normalizeLocale(String value) {
    return value.replaceAll('_', '-').trim();
  }

  String _languageFromLocale(String value) {
    final normalized = _normalizeLocale(value);
    if (normalized.isEmpty) return 'pl';
    return normalized.split('-').first.toLowerCase();
  }

  String _firstNotEmpty(List<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        return trimmed;
      }
    }

    return '';
  }

  String _normalizeSpaces(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  void _requestStop() {
    _stopRequested = true;

    final signal = _stopSignal;

    if (signal != null && !signal.isCompleted) {
      signal.complete();
    }
  }

  @override
  Future<void> stop() async {
    if (!_running) {
      _eventsController.add(
        const SttEngineEvent(
          type: SttEngineEventType.listening,
          listening: false,
        ),
      );
      return;
    }

    _requestStop();

    await _loopFuture;
  }

  @override
  Future<void> cancel() async {
    if (!_running) {
      return;
    }

    _cancelRequested = true;
    _requestStop();

    try {
      await _safeStopRecorder();
    } catch (_) {}

    await _loopFuture;
  }

  @override
  Future<void> dispose() async {
    try {
      await cancel();
    } catch (_) {}

    try {
      await _recorder.dispose();
    } catch (_) {}

    await _eventsController.close();
  }
}