part of '../emma_notifier.dart';

class _LocalTalkAudioQueueItem {
  final String audioUrl;
  final int generation;
  final int? messageId;
  final int? chunkIndex;
  final String clientJobId;
  final String sourceMessageId;
  final String source;
  final EmmaActionPolicy actionPolicy;

  const _LocalTalkAudioQueueItem({
    required this.audioUrl,
    required this.generation,
    required this.actionPolicy,
    this.messageId,
    this.chunkIndex,
    this.clientJobId = '',
    this.sourceMessageId = '',
    this.source = '',
  });
}

/// Local voice playback queue, barge-in handling and audio metadata stored
/// on assistant messages.
extension EmmaNotifierAudioMeta on ChatAiMessagesNotifier {
  bool get isLocalTalkAudioBusy {
    return _activeLocalTtsCancelToken != null ||
        _isDrainingLocalTalkAudio ||
        _localTalkAudioQueue.isNotEmpty ||
        _localTalkCurrentAudioUrl != null;
  }

  Future<void> waitForLocalTalkAudioIdle({
    Duration timeout = const Duration(minutes: 3),
    Duration tick = const Duration(milliseconds: 120),
  }) async {
    final startedAt = DateTime.now();

    while (!_isDisposed && isLocalTalkAudioBusy) {
      if (DateTime.now().difference(startedAt) >= timeout) {
        return;
      }

      await Future.delayed(tick);
    }
  }

  Future<void> speakText({
    required String text,
    EmmaActionPolicy actionPolicy = EmmaActionPolicy.queue,
    String clientJobId = '',
    String sourceMessageId = '',
    String source = '',
    String model = 'default-local-tts',
    String voice = 'default',
    String language = 'pl',
    String format = 'wav',
    bool autoLoad = true,
    bool normalize = true,
    String style = 'assistant',
    bool normalizerDebug = false,
    String referenceAudioPath = '',
    int? messageId,
  }) async {
    final clean = _safeText(text).trim();
    if (clean.isEmpty) return;
    if (_isDisposed) return;

    final effectiveJobId = clientJobId.trim().isNotEmpty
        ? clientJobId.trim()
        : 'tts-${DateTime.now().microsecondsSinceEpoch}';

    if (actionPolicy == EmmaActionPolicy.replace) {
      await _stopLocalTalkAudio();
    }

    final generation = _localTalkAudioGeneration;
    final cancelToken = CancelToken();

    _activeLocalTtsCancelToken = cancelToken;
    _activeLocalTtsJobId = effectiveJobId;

    Response<dynamic> response;

    try {
      response = await _localDio.post(
        '${URLsEmma.superbeeBaseUrl}/tts/speech/',
        data: {
          'input': clean,
          'model': model,
          'voice': voice,
          'language': language,
          'format': format,
          'auto_load': autoLoad,
          'normalize': normalize,
          'style': style,
          'normalizer_debug': normalizerDebug,
          'reference_audio_path': referenceAudioPath,
          'action_policy': actionPolicy.apiValue,
          'client_job_id': effectiveJobId,
          'source_message_id': sourceMessageId,
          'source': source,
        },
        cancelToken: cancelToken,
        options: Options(
          responseType: ResponseType.json,
          headers: const {
            'Accept': 'application/json, text/plain, */*',
            'Content-Type': 'application/json; charset=utf-8',
          },
          validateStatus: (status) {
            return status != null && status >= 200 && status < 500;
          },
        ),
      );
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) {
        return;
      }

      rethrow;
    } finally {
      if (identical(_activeLocalTtsCancelToken, cancelToken)) {
        _activeLocalTtsCancelToken = null;
        _activeLocalTtsJobId = null;
      }
    }

    if (_isDisposed) return;
    if (generation != _localTalkAudioGeneration) return;

    final status = response.statusCode ?? 0;
    final data = _localTtsResponseMap(response.data);

    if (status < 200 || status >= 300) {
      final detail = data['detail'] ??
          data['error'] ??
          data['message'] ??
          'Nie udało się wygenerować mowy.';

      throw Exception(detail);
    }

    final audioUrl = _safeText(data['audio_url']).trim();

    if (audioUrl.isEmpty) {
      throw Exception('TTS response does not contain audio_url.');
    }

    final resolvedMessageId = messageId ?? int.tryParse(sourceMessageId);

    if (resolvedMessageId != null) {
      _appendAudioChunkToMessage(
        messageId: resolvedMessageId,
        audioChunk: {
          'audio_url': audioUrl,
          'audio_path': data['audio_path'],
          'duration_ms': data['duration_ms'],
          'model': data['model'],
          'voice': data['voice'],
          'format': data['format'],
          'client_job_id': effectiveJobId,
          'source_message_id': sourceMessageId,
          'source': source,
          'action_policy': actionPolicy.apiValue,
          'created_at': DateTime.now().toIso8601String(),
        },
      );
    }

    _enqueueLocalTalkAudioUrl(
      audioUrl,
      generation: generation,
      messageId: resolvedMessageId,
      chunkIndex: 0,
      clientJobId: effectiveJobId,
      sourceMessageId: sourceMessageId,
      source: source,
      actionPolicy: actionPolicy,
    );

    await waitForLocalTalkAudioIdle();
  }

  Map<String, dynamic> _localTtsResponseMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);

    if (data is String && data.trim().isNotEmpty) {
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }

    if (data is List<int> && data.isNotEmpty) {
      final decoded = jsonDecode(utf8.decode(data));
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }

    return <String, dynamic>{};
  }

  Future<void> stopLocalTalkAudio() async {
    await _stopLocalTalkAudio();
  }

  Future<Map<String, dynamic>> beginUserVoiceInterruption({
    String source = 'mic',
  }) async {
    final interruption = _captureUserInterruptionMeta(source: source);

    if (interruption.isNotEmpty) {
      _pendingUserInterruptionMeta = interruption;
    }

    await _stopLocalTalkAudio();

    final wasGenerating = state.isLoading || _activeLocalJobId != null;

    if (wasGenerating) {
      _cloudResponseGuardGeneration++;
      _localJobGeneration++;
      _activeLocalJobId = null;
      _stopLoadingWatchdog();

      try {
        if (_channel != null && _isConnected) {
          _channel!.sink.add(
            jsonEncode({
              'action': 'stop_generation',
              'reason': 'user_interruption',
              'interruption': interruption,
            }),
          );
        }
      } catch (_) {}

      state = state.copyWith(
        isLoading: false,
        canCancel: false,
        clearThinking: true,
        activityTitle: 'Przerwano odpowiedź',
        activityDetail: 'Słucham użytkownika.',
      );
    }

    return interruption;
  }

  Map<String, dynamic> _consumePendingUserInterruptionMeta() {
    final value = _pendingUserInterruptionMeta;
    _pendingUserInterruptionMeta = null;

    if (value == null) return <String, dynamic>{};

    return Map<String, dynamic>.from(value);
  }

  Map<String, dynamic> _captureUserInterruptionMeta({
    required String source,
  }) {
    final now = DateTime.now();

    final assistantId = _latestAssistantMessageId(preferStreaming: true);
    final assistant =
        assistantId == null ? null : _messageByIdOrNull(assistantId);

    final audioStartedAt = _localTalkCurrentAudioStartedAt;
    final audioElapsedMs = audioStartedAt == null
        ? null
        : now.difference(audioStartedAt).inMilliseconds;

    final assistantContent = _safeText(assistant?.content ?? '').trim();

    final hasAnythingToInterrupt = state.isLoading ||
        _activeLocalJobId != null ||
        _activeLocalTtsCancelToken != null ||
        _isDrainingLocalTalkAudio ||
        _localTalkCurrentAudioUrl != null ||
        _localTalkAudioQueue.isNotEmpty ||
        assistantContent.isNotEmpty;

    if (!hasAnythingToInterrupt) {
      return <String, dynamic>{};
    }

    final meta = <String, dynamic>{
      'interrupted': true,
      'source': source,
      'at': now.toIso8601String(),
      'was_generating': state.isLoading,
      'local_job_id': _activeLocalJobId,
      'active_tts_job_id': _activeLocalTtsJobId,
      'queued_audio_count': _localTalkAudioQueue.length,
      if (assistantId != null) 'assistant_message_id': assistantId,
      if (assistantContent.isNotEmpty)
        'assistant_content_chars': assistantContent.length,
      if (assistantContent.isNotEmpty)
        'assistant_content_preview': _previewForInterruption(assistantContent),
      if (_localTalkCurrentAudioUrl != null)
        'audio': {
          'url': _localTalkCurrentAudioUrl,
          'message_id': _localTalkCurrentAudioMessageId,
          'chunk_index': _localTalkCurrentAudioChunkIndex,
          'client_job_id': _localTalkCurrentAudioJobId,
          'source_message_id': _localTalkCurrentAudioSourceMessageId,
          'source': _localTalkCurrentAudioSource,
          'started_at': audioStartedAt?.toIso8601String(),
          if (audioElapsedMs != null) 'elapsed_ms': audioElapsedMs,
        },
    };

    return meta;
  }

  String _previewForInterruption(String value, {int max = 220}) {
    final clean = _safeText(value).replaceAll(RegExp(r'\s+'), ' ').trim();

    if (clean.length <= max) return clean;

    return '${clean.substring(0, max).trimRight()}...';
  }

  Future<void> _stopLocalTalkAudio() async {
    _localTalkAudioGeneration++;
    _localTalkAudioQueue.clear();

    try {
      final cancelToken = _activeLocalTtsCancelToken;

      if (cancelToken != null && !cancelToken.isCancelled) {
        cancelToken.cancel('Local TTS was replaced/cancelled.');
      }
    } catch (_) {}

    _activeLocalTtsCancelToken = null;
    _activeLocalTtsJobId = null;

    try {
      final signal = _localTalkAudioStopSignal;

      if (signal != null && !signal.isCompleted) {
        signal.complete();
      }
    } catch (_) {}

    try {
      await _localTalkPlayer.stop();
    } catch (_) {}

    _localTalkCurrentAudioUrl = null;
    _localTalkCurrentAudioMessageId = null;
    _localTalkCurrentAudioChunkIndex = null;
    _localTalkCurrentAudioJobId = null;
    _localTalkCurrentAudioSourceMessageId = null;
    _localTalkCurrentAudioSource = null;
    _localTalkCurrentAudioStartedAt = null;
    _localTalkAudioStopSignal = null;
    _isDrainingLocalTalkAudio = false;
  }



void _enqueueLocalTalkAudioUrl(
  String audioUrl, {
  required int generation,
  EmmaActionPolicy actionPolicy = EmmaActionPolicy.queue,
  int? messageId,
  int? chunkIndex,
  String clientJobId = '',
  String sourceMessageId = '',
  String source = '',
}) {
  final cleanUrl = audioUrl.trim();

  if (cleanUrl.isEmpty) return;

  _localTalkAudioQueue.add(
    _LocalTalkAudioQueueItem(
      audioUrl: cleanUrl,
      generation: generation,
      actionPolicy: actionPolicy,
      messageId: messageId,
      chunkIndex: chunkIndex,
      clientJobId: clientJobId,
      sourceMessageId: sourceMessageId,
      source: source,
    ),
  );

  if (!_isDrainingLocalTalkAudio) {
    unawaited(
      _drainLocalTalkAudioQueue(
        generation: generation,
      ),
    );
  }
}



  Future<void> _drainLocalTalkAudioQueue({
    required int generation,
  }) async {
    if (_isDrainingLocalTalkAudio) return;

    _isDrainingLocalTalkAudio = true;

    try {
      while (!_isDisposed &&
          generation == _localTalkAudioGeneration &&
          _localTalkAudioQueue.isNotEmpty) {
        final item = _localTalkAudioQueue.removeAt(0);
        final audioUrl = item.audioUrl.trim();

        if (audioUrl.isEmpty) continue;
        if (item.generation != _localTalkAudioGeneration) continue;

        _localTalkCurrentAudioUrl = audioUrl;
        _localTalkCurrentAudioMessageId = item.messageId;
        _localTalkCurrentAudioChunkIndex = item.chunkIndex;
        _localTalkCurrentAudioJobId = item.clientJobId;
        _localTalkCurrentAudioSourceMessageId = item.sourceMessageId;
        _localTalkCurrentAudioSource = item.source;
        _localTalkCurrentAudioStartedAt = DateTime.now();

        _localTalkAudioStopSignal = Completer<void>();

        try {
          await _localTalkPlayer.stop();
          await _localTalkPlayer.play(UrlSource(audioUrl));

          await Future.any([
            _localTalkPlayer.onPlayerComplete.first,
            _localTalkAudioStopSignal!.future,
          ]);
        } catch (e, stack) {
          if (kDebugMode) {
            debugPrint('Emma: local talk audio playback failed: $e\n$stack');
          }
        } finally {
          _localTalkCurrentAudioUrl = null;
          _localTalkCurrentAudioMessageId = null;
          _localTalkCurrentAudioChunkIndex = null;
          _localTalkCurrentAudioJobId = null;
          _localTalkCurrentAudioSourceMessageId = null;
          _localTalkCurrentAudioSource = null;
          _localTalkCurrentAudioStartedAt = null;
          _localTalkAudioStopSignal = null;
        }
      }
    } finally {
      _isDrainingLocalTalkAudio = false;
    }
  }

  void _appendAudioChunkToMessage({
    required int messageId,
    required Map<String, dynamic> audioChunk,
  }) {
    if (!_isValidMessageIdForLocal(messageId)) return;

    final safeMessageId = _safeAssistantMessageIdFromAny(
      candidate: messageId,
      fallbackAssistantMessageId: _pendingTurnAssistantId ?? messageId,
    );

    final updated = List<ChatMessageDto>.from(state.messages);
    final idx = updated.indexWhere((m) => m.id == safeMessageId);

    if (idx == -1) return;

    final current = updated[idx];
    if (current.isUser) return;

    final meta = Map<String, dynamic>.from(current.meta);

    final existingRaw = meta['audio_chunks'];
    final audioChunks = existingRaw is List
        ? existingRaw
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : <Map<String, dynamic>>[];

    audioChunks.add(audioChunk);

    meta['audio_chunks'] = audioChunks;
    meta['audio_chunk_count'] = audioChunks.length;
    meta['has_audio'] = audioChunks.isNotEmpty;

    final merged = current.copyWith(meta: meta);
    updated[idx] = merged;

    state = state.copyWith(messages: updated);

    unawaited(_persistMessageLocal(merged));
  }

  void _appendSkippedAudioChunkToMessage({
    required int messageId,
    required Map<String, dynamic> skippedChunk,
  }) {
    if (!_isValidMessageIdForLocal(messageId)) return;

    final safeMessageId = _safeAssistantMessageIdFromAny(
      candidate: messageId,
      fallbackAssistantMessageId: _pendingTurnAssistantId ?? messageId,
    );

    final updated = List<ChatMessageDto>.from(state.messages);
    final idx = updated.indexWhere((m) => m.id == safeMessageId);

    if (idx == -1) return;

    final current = updated[idx];
    if (current.isUser) return;

    final meta = Map<String, dynamic>.from(current.meta);

    final existingRaw = meta['skipped_audio_chunks'];
    final skippedChunks = existingRaw is List
        ? existingRaw
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : <Map<String, dynamic>>[];

    skippedChunks.add(skippedChunk);

    meta['skipped_audio_chunks'] = skippedChunks;
    meta['skipped_audio_chunk_count'] = skippedChunks.length;

    final merged = current.copyWith(meta: meta);
    updated[idx] = merged;

    state = state.copyWith(messages: updated);

    unawaited(_persistMessageLocal(merged));
  }
}