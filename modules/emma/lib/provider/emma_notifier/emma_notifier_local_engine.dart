part of '../emma_notifier.dart';

/// Local Superbee engine fallback and streaming integration.
///
/// Local execution is used when the cloud is unavailable, stalls, or when the
/// user explicitly uses local voice mode.
///
/// This runtime is manifest-driven:
/// - local LLM receives only tools generated from EmmaToolDefinition manifest,
/// - no hardcoded fallback tools are exposed,
/// - local LLM emits only <emma_tool_result>,
/// - UI blocks are built deterministically from manifest block_schema.
extension EmmaNotifierLocalEngine on ChatAiMessagesNotifier {
  bool _isOfflineLocalJob(Map<String, dynamic> job) {
    return job['offline'] == true || job['local_only'] == true;
  }

  bool _shouldAutoplayLocalTalkAudio(Map<String, dynamic> job) {
    final meta = _extractMap(job['meta'] ?? job['metadata']);
    final talk = _extractMap(job['talk']);

    return meta['autoplay_local_audio'] == true ||
        talk['autoplay'] == true ||
        job['autoplay_local_audio'] == true;
  }

  Future<void> _ensureLocalManifestReadyForEngine() async {
    await _ensureLocalToolManifestLoaded();

    if (kDebugMode) {
      final defs = _uniqueLocalToolDefinitionsFromManifest();

      debugPrint(
        'Emma: local engine manifest ready. '
        'defs=${defs.length}, lookup_keys=${_emmaLocalToolManifestByKey.length}',
      );

      debugPrint(
        'Emma: calendar_create_event exists: '
        '${_localToolDefinition('calendar_create_event') != null}',
      );

      debugPrint(
        'Emma: tms_create_task exists: '
        '${_localToolDefinition('tms_create_task') != null}',
      );
    }
  }

  List<Map<String, dynamic>> _buildLocalFallbackMessages({
    required int sessionId,
    required String userText,
    required int optimisticUserMessageId,
    int limit = 24,
  }) {
    final history = state.messages
        .where((m) {
          if (m.id == optimisticUserMessageId) return false;
          if (m.content.trim().isEmpty) return false;

          // Critical: do not leak messages from another local/cloud thread.
          if (m.sessionId != sessionId) return false;

          final streaming = m.meta['streaming'] == true;
          final streamState = (m.meta['stream_state'] ?? '').toString();

          if (!m.isUser &&
              (streaming ||
                  streamState == 'started' ||
                  streamState == 'streaming' ||
                  streamState == 'waiting_local_engine' ||
                  streamState == 'waiting_local_tool_result')) {
            return false;
          }

          return true;
        })
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final tail =
        history.length > limit ? history.sublist(history.length - limit) : history;

    final messages = tail
        .map(
          (m) => {
            'role': m.isUser ? 'user' : 'assistant',
            'content': _safeText(m.content),
            'session_id': m.sessionId,
          },
        )
        .toList(growable: true);

    messages.add({
      'role': 'user',
      'content': _safeText(userText),
      'session_id': sessionId,
    });

    return messages;
  }

  Map<String, dynamic> _buildOfflineLocalJob({
    required int sessionId,
    required int assistantMessageId,
    required String userText,
    required int optimisticUserMessageId,
    required Map<String, dynamic> backendCtx,
    bool forceTalk = false,
    bool autoplayLocalTalk = false,
  }) {
    final runtimeMode = ref.read(emmaRuntimeModeProvider);
    final selectedVoice = ref.read(emmaSelectedVoiceProvider);

    final useTalk =
        !kIsWeb && (forceTalk || runtimeMode == EmmaRuntimeMode.localVoice);

    final localJobId =
        'offline-local-$sessionId-$assistantMessageId-${DateTime.now().microsecondsSinceEpoch}';

    final fallbackReason =
        (backendCtx['fallback_reason'] ?? 'internet_unavailable').toString();

    final messages = _buildLocalFallbackMessages(
      sessionId: sessionId,
      userText: userText,
      optimisticUserMessageId: optimisticUserMessageId,
    );

    return {
      'event': 'local_llm_job',
      'execution': 'client_local_engine',
      'engine': 'superbee',
      'offline': true,
      'local_only': true,
      'mode': useTalk ? 'talk' : 'text',
      'local_job_id': localJobId,
      'job_id': localJobId,
      'session_id': sessionId,
      'user_message_id': optimisticUserMessageId,
      'assistant_message_id': assistantMessageId,
      'message_id': assistantMessageId,
      'callback_url': '',
      'messages': messages,
      'options': {
        'temperature': 0.7,
        'max_tokens': 1024,
      },
      'tools': _extractLocalToolsForEngineFromJob({
        ...backendCtx,
        'messages': messages,
      }),
      'tool_choice': backendCtx['tool_choice'] ?? 'auto',
      'tool_execute_url':
          backendCtx['tool_execute_url'] ?? URLsEmma.emmaToolExecuteOnly,
      'talk': {
        'enabled': useTalk,
        'autoplay': autoplayLocalTalk,
        'tts_model': selectedVoice.ttsModel,
        'voice': selectedVoice.voice,
        'language': selectedVoice.language,
        'format': 'wav',
        'normalize_tts': selectedVoice.normalize,
        'reference_audio_path': selectedVoice.referenceAudioPath,
        'include_thinking': false,
        'chunk_min_chars': 60,
        'chunk_max_chars': 260,
      },
      'meta': {
        ...backendCtx,
        'offline_fallback': true,
        'fallback_reason': fallbackReason,
        'autoplay_local_audio': autoplayLocalTalk,
      },
    };
  }

  String _localUnavailableMessage(String reason) {
    if (reason == 'internet_unavailable') {
      return 'local_engine_unavailable_cloud_offline'.tr;
    }

    if (reason == 'local_voice_direct') {
      return 'local_voice_start_failed'.tr;
    }

    if (reason == 'ws_unavailable' ||
        reason == 'ws_not_connected' ||
        reason == 'ws_send_error') {
      return 'cloud_not_responding_local_unavailable'.tr;
    }

    if (reason == 'cloud_silent_after_send' ||
        reason == 'cloud_stalled_after_send') {
      return 'cloud_stalled_local_unavailable'.tr;
    }

    return 'local_engine_not_running'.tr;
  }

  Future<bool> _isLocalEngineReachable(
    Map<String, dynamic> job, {
    Duration timeout = const Duration(milliseconds: 900),
  }) async {
    if (!_canUseLocalFallback) return false;

    final baseUrl = _resolveLocalEngineBaseUrl(job);
    final token = _resolveLocalEngineToken(job);

    final mode = (job['mode'] ?? 'text').toString();

    final preferredPaths = mode == 'talk'
        ? <String>[
            '/talk/health/',
            '/llm/health',
            '/stt/health/',
            '/ping',
            '/',
          ]
        : <String>[
            '/llm/health',
            '/talk/health/',
            '/ping',
            '/',
          ];

    Object? lastError;

    for (final path in preferredPaths) {
      if (!_canEmit) return false;

      final url = '$baseUrl$path';

      try {
        final response = await _localDio.get<dynamic>(
          url,
          options: Options(
            sendTimeout: timeout,
            receiveTimeout: timeout,
            headers: {
              'X-Superbee-Token': token,
              'Accept': 'application/json, text/plain, */*',
            },
            validateStatus: (status) {
              if (status == null) return false;
              return status >= 200 && status < 500;
            },
          ),
        );

        if (!_canEmit) return false;

        final status = response.statusCode ?? 0;

        if (status >= 200 && status < 500) {
          return true;
        }
      } catch (e) {
        lastError = e;
      }
    }

    if (kDebugMode) {
      debugPrint('Emma: local engine not reachable. Last error: $lastError');
    }

    return false;
  }

  Future<void> _runOfflineLocalFallback({
    required int sessionId,
    required String userText,
    required int optimisticUserMessageId,
    required Map<String, dynamic> backendCtx,
    String reason = 'internet_unavailable',
    bool forceTalk = false,
    bool autoplayLocalTalk = false,
  }) async {
    if (!_canEmit) return;

    if (!_canUseLocalFallback) {
      _stopLoadingWatchdog();

      _emit(
        state.copyWith(
          isLoading: false,
          canCancel: false,
          clearThinking: true,
          activityTitle: 'no_connection_title'.tr,
          activityDetail: 'local_mode_unavailable_web'.tr,
        ),
      );

      return;
    }

    await _disconnectInternal();

    if (!_canEmit) return;

    await _ensureLocalManifestReadyForEngine();

    if (!_canEmit) return;

    final assistantMessageId = _newOfflineAssistantMessageId();
    _pendingTurnAssistantId = assistantMessageId;

    _setActivity(
      title: 'emma_checking_local_mode'.tr,
      detail: reason == 'local_voice_direct'
          ? 'starting_local_voice_conversation'.tr
          : reason == 'ws_unavailable'
              ? 'backend_connection_failed_checking_local'.tr
              : reason == 'ws_not_connected'
                  ? 'websocket_not_connected_checking_local'.tr
                  : reason == 'ws_send_error'
                      ? 'cloud_send_failed_checking_local'.tr
                      : reason == 'cloud_silent_after_send'
                          ? 'cloud_silent_checking_local'.tr
                          : reason == 'cloud_stalled_after_send'
                              ? 'cloud_stalled_checking_local'.tr
                              : reason == 'offline_session'
                                  ? 'session_local_checking_engine'.tr
                                  : 'no_internet_checking_local_engine'.tr
    );

    final job = _buildOfflineLocalJob(
      sessionId: sessionId,
      assistantMessageId: assistantMessageId,
      userText: userText,
      optimisticUserMessageId: optimisticUserMessageId,
      backendCtx: {
        ...backendCtx,
        'fallback_reason': reason,
      },
      forceTalk: forceTalk,
      autoplayLocalTalk: autoplayLocalTalk,
    );

    final localReady = await _isLocalEngineReachable(job);

    if (!_canEmit) return;

    if (!localReady) {
      _replaceAssistantContent(
        messageId: assistantMessageId,
        content: _localUnavailableMessage(reason),
        finished: true,
        meta: {
          'streaming': false,
          'stream_state': 'error',
          'local_only': true,
          'local_engine': {
            'enabled': false,
            'reachable': false,
            'reason': reason,
            'base_url': _resolveLocalEngineBaseUrl(job),
          },
          'local_engine_error': 'Local engine is not reachable.',
        },
      );

      _stopLoadingWatchdog();

      _emit(
        state.copyWith(
          isLoading: false,
          canCancel: false,
          clearActivity: true,
          clearThinking: true,
        ),
      );

      return;
    }

    _setActivity(
      title: forceTalk ? 'emma_speaking_locally'.tr : 'emma_running_locally'.tr,
      detail: forceTalk
          ? 'local_engine_voice_pipeline'.tr
          : 'local_engine_generating_response'.tr,
    );

    await _handleLocalLlmJob(job);
  }

  Future<void> _handleLocalLlmJob(Map<String, dynamic> job) async {
    if (!_canEmit) return;

    final sessionId = _asInt(job['session_id']) ?? _currentSessionId;
    final assistantMessageId = _asInt(job['assistant_message_id']);
    final localJobId = (job['local_job_id'] ?? job['job_id'] ?? '').toString();

    if (sessionId == null || assistantMessageId == null) {
      if (kDebugMode) {
        debugPrint('Emma: invalid local_llm_job payload: $job');
      }

      return;
    }

    if (_currentSessionId != null && sessionId != _currentSessionId) {
      if (kDebugMode) {
        debugPrint(
          'Emma: local job ignored, session mismatch: job=$sessionId current=$_currentSessionId',
        );
      }

      return;
    }

    final safeAssistantMessageId = _safeAssistantMessageIdFromAny(
      candidate: assistantMessageId,
      fallbackAssistantMessageId: _pendingTurnAssistantId ?? assistantMessageId,
    );

    _pendingTurnAssistantId = safeAssistantMessageId;

    final generation = ++_localJobGeneration;
    _activeLocalJobId = localJobId;

    await _ensureLocalManifestReadyForEngine();

    if (!_canEmit) return;
    if (generation != _localJobGeneration) return;

    final autoplayLocalTalkAudio = _shouldAutoplayLocalTalkAudio(job);

    if (autoplayLocalTalkAudio) {
      _localTalkAudioGeneration++;
      _localTalkAudioQueue.clear();

      try {
        await _localTalkPlayer.stop();
      } catch (_) {}

      if (!_canEmit) return;
      if (generation != _localJobGeneration) return;
    }

    final audioGeneration = _localTalkAudioGeneration;

    final answerBuffer = StringBuffer();
    final thinkingBuffer = StringBuffer();
    final audioChunks = <Map<String, dynamic>>[];
    final skippedAudioChunks = <Map<String, dynamic>>[];

    final shouldBufferLocalToolDeltas = _shouldBufferLocalToolDeltasForJob(job);
    var suppressingLocalToolStream = false;

    _ensureAssistantPlaceholder(
      messageId: safeAssistantMessageId,
      sessionId: sessionId,
      meta: {
        'streaming': true,
        'stream_state': 'waiting_local_engine',
        'local_only': _isOfflineLocalJob(job),
        'local_engine': {
          'enabled': true,
          'job_id': localJobId,
          'mode': (job['mode'] ?? 'text').toString(),
          'engine': (job['engine'] ?? 'superbee').toString(),
          'autoplay_local_audio': autoplayLocalTalkAudio,
        },
      },
    );

  _setActivity(
    title: 'emma_checking_local_engine'.tr,
    detail: 'checking_superbee_local_status'.tr,
  );

    final localReady = await _isLocalEngineReachable(job);

    if (!_canEmit) return;
    if (generation != _localJobGeneration) return;

    if (!localReady) {
      final meta = _extractMap(job['meta']);
      final message = _localUnavailableMessage(
        (meta['fallback_reason'] ?? 'local_engine_unavailable').toString(),
      );

      _replaceAssistantContent(
        messageId: safeAssistantMessageId,
        content: message,
        finished: true,
        meta: {
          'streaming': false,
          'stream_state': 'error',
          'local_only': _isOfflineLocalJob(job),
          'local_engine': {
            'enabled': false,
            'reachable': false,
            'job_id': localJobId,
            'mode': (job['mode'] ?? 'text').toString(),
            'engine': (job['engine'] ?? 'superbee').toString(),
            'base_url': _resolveLocalEngineBaseUrl(job),
          },
          'local_engine_error': 'Local engine is not reachable.',
        },
      );

      await _syncLocalResultToBackend(
        job: job,
        content: message,
        thinking: '',
        audioChunks: const [],
        skippedAudioChunks: const [],
        error: 'Local engine is not reachable.',
      );

      unawaited(_trySyncNow());

      return;
    }

  _setActivity(
    title: autoplayLocalTalkAudio
        ? 'emma_speaking_locally'.tr
        : 'emma_running_locally',
    detail: autoplayLocalTalkAudio
        ? 'processing_response_live_audio'.tr
        : 'processing_response_local_engine'.tr
  );

    try {
      await for (final localEvent in _streamLocalJob(job)) {
        if (!_canEmit) return;
        if (generation != _localJobGeneration) return;

        _bumpLoadingWatchdog();

        final event = localEvent.event;
        final raw = localEvent.raw;
        final delta = _safeText(localEvent.delta);

        final targetAssistantMessageId = _safeAssistantMessageIdFromAny(
          candidate:
              _asInt(raw['assistant_message_id']) ?? _asInt(raw['message_id']),
          fallbackAssistantMessageId: safeAssistantMessageId,
        );

      if (event == 'start') {
        _setActivity(
          title: autoplayLocalTalkAudio
              ? 'emma_speaking_locally'.tr
              : 'emma_running_locally'.tr,
          detail: autoplayLocalTalkAudio
              ? 'local_llm_tts_pipeline_started'.tr
              : 'local_llm_pipeline_started'.tr
        );
        continue;
      }

        if (event == 'answer_delta' ||
            event == 'llm_answer_delta' ||
            event == 'delta') {
          if (delta.isEmpty) continue;

          answerBuffer.write(delta);

          final currentBufferedText = answerBuffer.toString();

          final shouldSuppressDelta = shouldBufferLocalToolDeltas ||
              suppressingLocalToolStream ||
              _looksLikeStreamingLocalToolResult(currentBufferedText);

          if (shouldSuppressDelta) {
            suppressingLocalToolStream = true;

            _mergeAssistantMeta(
              messageId: targetAssistantMessageId,
              meta: {
                'streaming': true,
                'stream_state': 'waiting_local_tool_result',
                'local_llm_tools': {
                  'enabled': true,
                  'detected_stream': true,
                  'internal_stream_hidden': true,
                },
              },
            );

          _setActivity(
            title: 'emma_preparing_action'.tr,
            detail: 'local_tool_detected'.tr,
          );

            continue;
          }

          _applyAiDelta({
            'message_id': targetAssistantMessageId,
            'assistant_message_id': targetAssistantMessageId,
            'session_id': sessionId,
            'delta': delta,
          });

          continue;
        }

        if (event == 'thinking_delta' || event == 'llm_thinking_delta') {
          if (delta.isNotEmpty) {
            thinkingBuffer.write(delta);
          }

          continue;
        }

      if (event == 'tts_chunk_start') {
        _setActivity(
          title: 'emma_generating_voice'.tr,
          detail: _safeText(raw['text']),
        );
        continue;
      }

        if (event == 'tts_chunk_ready') {
          final chunk = Map<String, dynamic>.from(raw);
          audioChunks.add(chunk);

          _appendAudioChunkToMessage(
            messageId: targetAssistantMessageId,
            audioChunk: chunk,
          );

          if (autoplayLocalTalkAudio) {
            final audioUrl = _safeText(chunk['audio_url']).trim();

            if (audioUrl.isNotEmpty) {
              _enqueueLocalTalkAudioUrl(
                audioUrl,
                generation: audioGeneration,
                messageId: targetAssistantMessageId,
                chunkIndex: _asInt(chunk['index']),
              );
            }
          }

        _setActivity(
          title: 'audio_chunk_ready'.tr,
          detail: '${'generated_audio_chunk_count'.tr} ${audioChunks.length}. ${'voice_chunk_label'.tr}',
        );

          continue;
        }

        if (event == 'tts_chunk_skipped') {
          final chunk = Map<String, dynamic>.from(raw);
          skippedAudioChunks.add(chunk);

          _appendSkippedAudioChunkToMessage(
            messageId: targetAssistantMessageId,
            skippedChunk: chunk,
          );

          continue;
        }

      if (event == 'warning') {
        _setActivity(
          title: 'superbee_warning'.tr,
          detail: _safeText(raw['warning']),
        );
        continue;
      }

        if (event == 'error') {
          final error = _safeText(raw['error'] ?? 'Unknown local engine error');

          final currentContent = answerBuffer.toString().trim();

        final fallbackContent = currentContent.isNotEmpty &&
                !suppressingLocalToolStream &&
                !_looksLikeStreamingLocalToolResult(currentContent)
            ? currentContent
            : 'local_engine_error_occurred'.tr;

          _replaceAssistantContent(
            messageId: targetAssistantMessageId,
            content: fallbackContent,
            finished: true,
            meta: {
              'streaming': false,
              'stream_state': 'error',
              'local_engine_error': error,
              'thinking': _safeText(thinkingBuffer.toString().trim()),
              'audio_chunks': audioChunks,
              'audio_chunk_count': audioChunks.length,
              'skipped_audio_chunks': skippedAudioChunks,
              'skipped_audio_chunk_count': skippedAudioChunks.length,
              'has_audio': audioChunks.isNotEmpty,
              'local_only': _isOfflineLocalJob(job),
              'local_llm_tools': {
                'enabled': true,
                'detected_stream': suppressingLocalToolStream,
                'internal_stream_hidden': suppressingLocalToolStream,
                'parse_failed': suppressingLocalToolStream,
              },
            },
          );

          await _syncLocalResultToBackend(
            job: job,
            content: fallbackContent,
            thinking: thinkingBuffer.toString().trim(),
            audioChunks: audioChunks,
            skippedAudioChunks: skippedAudioChunks,
            error: error,
          );

          unawaited(_trySyncNow());

          return;
        }

        if (event == 'done') {
          final finalContentRaw = _safeText(raw['content']).trim();
          final finalThinkingRaw = _safeText(raw['thinking']).trim();

          final finalContent = _safeText(
            finalContentRaw.isNotEmpty
                ? finalContentRaw
                : answerBuffer.toString().trim(),
          );

          final repairedFinalContent =
              _repairCommonMalformedLocalToolContent(finalContent);

          final finalThinking = _safeText(
            finalThinkingRaw.isNotEmpty
                ? finalThinkingRaw
                : thinkingBuffer.toString().trim(),
          );

          final doneAudioChunks = _extractListOfMaps(raw['audio_chunks']);

          if (doneAudioChunks.isNotEmpty) {
            audioChunks
              ..clear()
              ..addAll(doneAudioChunks);
          }

          final localToolRun = await _handleLocalToolResultFromContent(
            job: job,
            sessionId: sessionId,
            assistantMessageId: targetAssistantMessageId,
            content: repairedFinalContent,
          );

          if (!_canEmit) return;
          if (generation != _localJobGeneration) return;

          if (localToolRun != null) {
            _replaceAssistantContent(
              messageId: targetAssistantMessageId,
              content: localToolRun.visibleContent,
              finished: true,
              meta: {
                'streaming': false,
                'stream_state': 'finished',
                'thinking': finalThinking,
                'audio_chunks': audioChunks,
                'audio_chunk_count': audioChunks.length,
                'skipped_audio_chunks': skippedAudioChunks,
                'skipped_audio_chunk_count': skippedAudioChunks.length,
                'has_audio': audioChunks.isNotEmpty,
                'blocks': localToolRun.blocks,
                'tools': localToolRun.toolResults,
                'local_only': _isOfflineLocalJob(job),
                'local_llm_tools': {
                  'enabled': true,
                  'detected': true,
                  'tool_name': localToolRun.toolName,
                  'client_action_id': localToolRun.clientActionId,
                  'local_entity_id': localToolRun.localEntityId,
                  'sync_status': localToolRun.syncStatus,
                  'internal_stream_hidden': suppressingLocalToolStream,
                  'blocks': localToolRun.blocks,
                },
                'local_engine': {
                  'enabled': true,
                  'synced': false,
                  'job_id': localJobId,
                  'mode': (job['mode'] ?? 'text').toString(),
                  'engine': (job['engine'] ?? 'superbee').toString(),
                  'autoplay_local_audio': autoplayLocalTalkAudio,
                },
              },
            );

            await _syncLocalResultToBackend(
              job: job,
              content: localToolRun.visibleContent,
              thinking: finalThinking,
              audioChunks: audioChunks,
              skippedAudioChunks: skippedAudioChunks,
              extraMeta: {
                'blocks': localToolRun.blocks,
                'tools': localToolRun.toolResults,
                'local_llm_tools': {
                  'enabled': true,
                  'detected': true,
                  'tool_name': localToolRun.toolName,
                  'client_action_id': localToolRun.clientActionId,
                  'local_entity_id': localToolRun.localEntityId,
                  'sync_status': localToolRun.syncStatus,
                  'internal_stream_hidden': suppressingLocalToolStream,
                  'blocks': localToolRun.blocks,
                },
              },
            );

            if (!_canEmit) return;
            if (generation != _localJobGeneration) return;

            _mergeAssistantMeta(
              messageId: targetAssistantMessageId,
              meta: {
                'local_only': _isOfflineLocalJob(job),
                'local_engine': {
                  'enabled': true,
                  'synced': !_isOfflineLocalJob(job),
                  'job_id': localJobId,
                  'mode': (job['mode'] ?? 'text').toString(),
                  'engine': (job['engine'] ?? 'superbee').toString(),
                  'autoplay_local_audio': autoplayLocalTalkAudio,
                },
              },
            );

            _stopLoadingWatchdog();

            _emit(
              state.copyWith(
                isLoading: false,
                canCancel: false,
                clearActivity: true,
                clearThinking: true,
              ),
            );

            unawaited(_trySyncNow());

            return;
          }

          final looksLikeUnparsedToolResult =
              suppressingLocalToolStream ||
                  _looksLikeStreamingLocalToolResult(finalContent) ||
                  _looksLikeStreamingLocalToolResult(repairedFinalContent);

        final visibleFinalContent = looksLikeUnparsedToolResult
            ? 'local_action_parse_failed'.tr
            : finalContent;

          _replaceAssistantContent(
            messageId: targetAssistantMessageId,
            content: visibleFinalContent,
            finished: true,
            meta: {
              'streaming': false,
              'stream_state': looksLikeUnparsedToolResult ? 'error' : 'finished',
              'thinking': finalThinking,
              'audio_chunks': audioChunks,
              'audio_chunk_count': audioChunks.length,
              'skipped_audio_chunks': skippedAudioChunks,
              'skipped_audio_chunk_count': skippedAudioChunks.length,
              'has_audio': audioChunks.isNotEmpty,
              'local_only': _isOfflineLocalJob(job),
              'local_llm_tools': {
                'enabled': true,
                'detected': false,
                'detected_stream': suppressingLocalToolStream,
                'internal_stream_hidden': suppressingLocalToolStream,
                'parse_failed': looksLikeUnparsedToolResult,
                if (looksLikeUnparsedToolResult)
                  'raw_hidden_reason': 'local_tool_result_parse_failed',
              },
              'local_engine': {
                'enabled': true,
                'synced': false,
                'job_id': localJobId,
                'mode': (job['mode'] ?? 'text').toString(),
                'engine': (job['engine'] ?? 'superbee').toString(),
                'autoplay_local_audio': autoplayLocalTalkAudio,
              },
            },
          );

          await _syncLocalResultToBackend(
            job: job,
            content: visibleFinalContent,
            thinking: finalThinking,
            audioChunks: audioChunks,
            skippedAudioChunks: skippedAudioChunks,
            warning: looksLikeUnparsedToolResult
                ? 'Local tool result looked valid but could not be parsed. Raw content was hidden from UI.'
                : null,
          );

          if (!_canEmit) return;
          if (generation != _localJobGeneration) return;

          _mergeAssistantMeta(
            messageId: targetAssistantMessageId,
            meta: {
              'local_only': _isOfflineLocalJob(job),
              'local_engine': {
                'enabled': true,
                'synced': !_isOfflineLocalJob(job),
                'job_id': localJobId,
                'mode': (job['mode'] ?? 'text').toString(),
                'engine': (job['engine'] ?? 'superbee').toString(),
                'autoplay_local_audio': autoplayLocalTalkAudio,
              },
            },
          );

          _stopLoadingWatchdog();

          _emit(
            state.copyWith(
              isLoading: false,
              canCancel: false,
              clearActivity: true,
              clearThinking: true,
            ),
          );

          unawaited(_trySyncNow());

          return;
        }
      }

      final fallbackContent = _safeText(answerBuffer.toString().trim());

      if (fallbackContent.isNotEmpty) {
        if (!_canEmit) return;
        if (generation != _localJobGeneration) return;

        final repairedFallbackContent =
            _repairCommonMalformedLocalToolContent(fallbackContent);

        final localToolRun = await _handleLocalToolResultFromContent(
          job: job,
          sessionId: sessionId,
          assistantMessageId: safeAssistantMessageId,
          content: repairedFallbackContent,
        );

        if (!_canEmit) return;
        if (generation != _localJobGeneration) return;

        if (localToolRun != null) {
          _replaceAssistantContent(
            messageId: safeAssistantMessageId,
            content: localToolRun.visibleContent,
            finished: true,
            meta: {
              'streaming': false,
              'stream_state': 'finished_without_done_event',
              'thinking': _safeText(thinkingBuffer.toString().trim()),
              'audio_chunks': audioChunks,
              'audio_chunk_count': audioChunks.length,
              'skipped_audio_chunks': skippedAudioChunks,
              'skipped_audio_chunk_count': skippedAudioChunks.length,
              'has_audio': audioChunks.isNotEmpty,
              'blocks': localToolRun.blocks,
              'tools': localToolRun.toolResults,
              'local_only': _isOfflineLocalJob(job),
              'local_llm_tools': {
                'enabled': true,
                'detected': true,
                'tool_name': localToolRun.toolName,
                'client_action_id': localToolRun.clientActionId,
                'local_entity_id': localToolRun.localEntityId,
                'sync_status': localToolRun.syncStatus,
                'internal_stream_hidden': suppressingLocalToolStream,
                'blocks': localToolRun.blocks,
              },
            },
          );

          await _syncLocalResultToBackend(
            job: job,
            content: localToolRun.visibleContent,
            thinking: thinkingBuffer.toString().trim(),
            audioChunks: audioChunks,
            skippedAudioChunks: skippedAudioChunks,
            warning: 'Local stream ended without done event.',
            extraMeta: {
              'blocks': localToolRun.blocks,
              'tools': localToolRun.toolResults,
              'local_llm_tools': {
                'enabled': true,
                'detected': true,
                'tool_name': localToolRun.toolName,
                'client_action_id': localToolRun.clientActionId,
                'local_entity_id': localToolRun.localEntityId,
                'sync_status': localToolRun.syncStatus,
                'internal_stream_hidden': suppressingLocalToolStream,
                'blocks': localToolRun.blocks,
              },
            },
          );
        } else {
          final looksLikeUnparsedToolResult =
              suppressingLocalToolStream ||
                  _looksLikeStreamingLocalToolResult(fallbackContent) ||
                  _looksLikeStreamingLocalToolResult(repairedFallbackContent);

        final visibleFallbackContent = looksLikeUnparsedToolResult
            ? 'local_action_parse_failed'.tr
            : fallbackContent;

          _replaceAssistantContent(
            messageId: safeAssistantMessageId,
            content: visibleFallbackContent,
            finished: true,
            meta: {
              'streaming': false,
              'stream_state': looksLikeUnparsedToolResult
                  ? 'error'
                  : 'finished_without_done_event',
              'thinking': _safeText(thinkingBuffer.toString().trim()),
              'audio_chunks': audioChunks,
              'audio_chunk_count': audioChunks.length,
              'skipped_audio_chunks': skippedAudioChunks,
              'skipped_audio_chunk_count': skippedAudioChunks.length,
              'has_audio': audioChunks.isNotEmpty,
              'local_only': _isOfflineLocalJob(job),
              'local_llm_tools': {
                'enabled': true,
                'detected': false,
                'detected_stream': suppressingLocalToolStream,
                'internal_stream_hidden': suppressingLocalToolStream,
                'parse_failed': looksLikeUnparsedToolResult,
                if (looksLikeUnparsedToolResult)
                  'raw_hidden_reason': 'local_tool_result_parse_failed',
              },
            },
          );

          await _syncLocalResultToBackend(
            job: job,
            content: visibleFallbackContent,
            thinking: thinkingBuffer.toString().trim(),
            audioChunks: audioChunks,
            skippedAudioChunks: skippedAudioChunks,
            warning: looksLikeUnparsedToolResult
                ? 'Local stream ended without done event and local tool result could not be parsed. Raw content was hidden from UI.'
                : 'Local stream ended without done event.',
          );
        }

        unawaited(_trySyncNow());
      }
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('Emma: local engine job failed: $e\n$stack');
      }

      if (!_canEmit) return;
      if (generation != _localJobGeneration) return;

      final rawFallbackContent = answerBuffer.toString().trim();

    final fallbackContent = rawFallbackContent.isNotEmpty &&
            !suppressingLocalToolStream &&
            !_looksLikeStreamingLocalToolResult(rawFallbackContent)
        ? _safeText(rawFallbackContent)
        : 'local_engine_connection_failed'.tr;

      _replaceAssistantContent(
        messageId: safeAssistantMessageId,
        content: fallbackContent,
        finished: true,
        meta: {
          'streaming': false,
          'stream_state': 'error',
          'local_engine_error': e.toString(),
          'thinking': _safeText(thinkingBuffer.toString().trim()),
          'audio_chunks': audioChunks,
          'audio_chunk_count': audioChunks.length,
          'skipped_audio_chunks': skippedAudioChunks,
          'skipped_audio_chunk_count': skippedAudioChunks.length,
          'has_audio': audioChunks.isNotEmpty,
          'local_only': _isOfflineLocalJob(job),
          'local_llm_tools': {
            'enabled': true,
            'detected_stream': suppressingLocalToolStream,
            'internal_stream_hidden': suppressingLocalToolStream,
            'parse_failed': suppressingLocalToolStream,
          },
        },
      );

      await _syncLocalResultToBackend(
        job: job,
        content: fallbackContent,
        thinking: thinkingBuffer.toString().trim(),
        audioChunks: audioChunks,
        skippedAudioChunks: skippedAudioChunks,
        error: e.toString(),
      );

      unawaited(_trySyncNow());
    } finally {
      if (_canEmit && generation == _localJobGeneration) {
        _activeLocalJobId = null;
        _stopLoadingWatchdog();

        _emit(
          state.copyWith(
            isLoading: false,
            canCancel: false,
            clearActivity: true,
          ),
        );
      }
    }
  }

  Stream<_LocalEngineStreamEvent> _streamLocalJob(
    Map<String, dynamic> job,
  ) async* {
    final mode = (job['mode'] ?? 'text').toString();

    await _ensureLocalManifestReadyForEngine();

    final rawMessages = _extractListOfMaps(job['messages']);

    final rawOptions = _extractMap(job['options']);
    final rawMetadata = _extractMap(job['meta'] ?? job['metadata']);
    final metadata = _stripHeavyLocalLlmMetadata(rawMetadata);
    final talk = _extractMap(job['talk']);

    final latestUserText = _safeText(
      job['input'] ?? _lastUserContent(rawMessages),
    ).trim();

    final localTools = _extractLocalToolsForEngineFromJob({
      ...job,
      'messages': rawMessages,
    });

    final localLlmRequest = _buildLocalLlmRequestMessages(
      sourceMessages: rawMessages,
      latestUserText: latestUserText,
      options: rawOptions,
      tools: localTools,
      sessionId: _asInt(job['session_id']) ?? _currentSessionId,
    );

    final messages = localLlmRequest.messages;
    final options = localLlmRequest.options;

    final scopedMessages = _scopeLocalMessagesToSession(
      rawMessages,
      sessionId: _asInt(job['session_id']) ?? _currentSessionId,
    );

    final selectedTools = localLlmRequest.isToolMode
        ? _selectRelevantLocalToolsForPrompt(
            latestUserText: latestUserText,
            scopedMessages: scopedMessages,
            tools: localTools,
          )
        : <Map<String, dynamic>>[];

    final selectedToolNames = selectedTools
        .map(_toolNameFromLocalToolSchema)
        .where((name) => name.trim().isNotEmpty)
        .toList(growable: false);

    final requestMetadata = {
      ...metadata,
      'local_job_id': job['local_job_id'] ?? job['job_id'],
      'job_id': job['job_id'] ?? job['local_job_id'],
      'session_id': job['session_id'],
      'assistant_message_id': job['assistant_message_id'],
      'message_id': job['assistant_message_id'],
      'user_message_id': job['user_message_id'],
      'role': 'assistant',
      'tools_available': selectedTools.isNotEmpty,
      'local_tool_mode': localLlmRequest.isToolMode,
      'selected_tools': selectedToolNames,
      'selected_tools_count': selectedToolNames.length,
      'tool_execute_url':
          job['tool_execute_url'] ?? metadata['tool_execute_url'],
    };

    if (kDebugMode) {
      debugPrint(
        'Emma: local LLM mode=${localLlmRequest.isToolMode ? 'tool' : 'chat'} '
        'messages=${messages.length} tools=${selectedTools.length} '
        'selected=$selectedToolNames',
      );
    }

    // Important:
    // We do NOT pass native OpenAI tools to the local runtime here.
    // The local model is instructed via system prompt to emit <emma_tool_result>.
    // Passing both native tools and tag instructions duplicates context and
    // increases malformed output risk.
    final nativeRuntimeTools = <Map<String, dynamic>>[];

    if (mode == 'talk') {
      final input = (job['input'] ?? _lastUserContent(messages)).toString();

      yield* _postLocalNdjson(
        job: job,
        path: '/talk/stream/',
        payload: {
          'input': input,
          'messages': messages,
          'tools': nativeRuntimeTools,
          'tool_choice': 'none',
          'include_thinking': talk['include_thinking'] == true,
          'tts_model': (talk['tts_model'] ?? 'piper-pl-female').toString(),
          'voice': (talk['voice'] ?? 'default').toString(),
          'language': (talk['language'] ?? 'pl').toString(),
          'format': (talk['format'] ?? 'wav').toString(),
          'auto_load_tts': talk['auto_load_tts'] != false,
          'normalize_tts': talk['normalize_tts'] != false,
          'reference_audio_path':
              (talk['reference_audio_path'] ?? '').toString(),
          'chunk_min_chars': _asInt(talk['chunk_min_chars']) ?? 60,
          'chunk_max_chars': _asInt(talk['chunk_max_chars']) ?? 260,
          'llm_options': options,
          'metadata': requestMetadata,
        },
      );

      return;
    }

    yield* _postLocalNdjson(
      job: job,
      path: '/llm/chat/stream',
      payload: {
        'messages': messages,
        'tools': nativeRuntimeTools,
        'tool_choice': 'none',
        'options': options,
        'metadata': requestMetadata,
      },
    );
  }

  _EmmaLocalLlmRequestMessagesResult _buildLocalLlmRequestMessages({
    required List<Map<String, dynamic>> sourceMessages,
    required String latestUserText,
    required Map<String, dynamic> options,
    required List<Map<String, dynamic>> tools,
    required int? sessionId,
  }) {
    final scopedMessages = _scopeLocalMessagesToSession(
      sourceMessages,
      sessionId: sessionId,
    );

    final selectedTools = _selectRelevantLocalToolsForPrompt(
      latestUserText: latestUserText,
      scopedMessages: scopedMessages,
      tools: tools,
    );

    final isToolMode = selectedTools.isNotEmpty &&
        _looksLikeLocalToolIntent(
          latestUserText,
          scopedMessages: scopedMessages,
          tools: selectedTools,
        );

    if (!isToolMode) {
      return _EmmaLocalLlmRequestMessagesResult(
        isToolMode: false,
        messages: _buildCasualLocalMessages(scopedMessages),
        options: {
          ...options,
          'temperature': options['temperature'] ?? 0.7,
          'max_tokens': options['max_tokens'] ?? 700,
        },
      );
    }

    return _EmmaLocalLlmRequestMessagesResult(
      isToolMode: true,
      messages: _buildToolLocalMessages(
        scopedMessages: scopedMessages,
        latestUserText: latestUserText,
        tools: selectedTools,
      ),
      options: {
        ...options,
        'temperature': 0.1,
        'max_tokens': options['max_tokens'] ?? 900,
      },
    );
  }

  List<Map<String, dynamic>> _scopeLocalMessagesToSession(
    List<Map<String, dynamic>> messages, {
    required int? sessionId,
  }) {
    final normalized = <Map<String, dynamic>>[];

    for (final raw in messages) {
      if (sessionId != null) {
        final rawSessionId = raw['session_id'] ??
            raw['sessionId'] ??
            raw['chat_session_id'] ??
            raw['chatSessionId'];

        if (rawSessionId != null &&
            rawSessionId.toString() != sessionId.toString()) {
          continue;
        }
      }

      final message = _normalizeLocalChatMessage(raw);
      if (message == null) continue;

      normalized.add(message);
    }

    return normalized;
  }

  Map<String, dynamic>? _normalizeLocalChatMessage(Map<String, dynamic> raw) {
    var role =
        (raw['role'] ?? raw['sender'] ?? '').toString().trim().toLowerCase();

    if (role == 'ai' || role == 'bot' || role == 'emma') {
      role = 'assistant';
    }

    if (role == 'human') {
      role = 'user';
    }

    if (role != 'user' &&
        role != 'assistant' &&
        role != 'system' &&
        role != 'tool') {
      return null;
    }

    final content =
        (raw['content'] ?? raw['text'] ?? raw['message'] ?? raw['body'] ?? '')
            .toString();

    if (content.trim().isEmpty) return null;

    return {
      'role': role,
      'content': content,
    };
  }

  List<Map<String, dynamic>> _buildCasualLocalMessages(
    List<Map<String, dynamic>> scopedMessages,
  ) {
    final conversation = scopedMessages
        .where((message) {
          final role = message['role']?.toString();
          return role == 'user' || role == 'assistant';
        })
        .map<Map<String, dynamic>>(
          (message) => {
            'role': message['role']?.toString() ?? 'user',
            'content': _safeText(message['content']),
          },
        )
        .toList(growable: false);

    final limitedConversation = conversation.length > 12
        ? conversation.sublist(conversation.length - 12)
        : conversation;

    return [
      {
        'role': 'system',
        'content': _buildLocalCasualSystemPrompt(),
      },
      ...limitedConversation,
    ];
  }

  List<Map<String, dynamic>> _buildToolLocalMessages({
    required List<Map<String, dynamic>> scopedMessages,
    required String latestUserText,
    required List<Map<String, dynamic>> tools,
  }) {
    final userMessages = scopedMessages
        .where((message) => message['role']?.toString() == 'user')
        .map<Map<String, dynamic>>(
          (message) => {
            'role': 'user',
            'content': _safeText(message['content']),
          },
        )
        .where((message) => _safeText(message['content']).trim().isNotEmpty)
        .toList(growable: true);

    final latest = latestUserText.trim();

    if (latest.isNotEmpty) {
      final hasLatestAlready = userMessages.isNotEmpty &&
          _safeText(userMessages.last['content']).trim() == latest;

      if (!hasLatestAlready) {
        userMessages.add({
          'role': 'user',
          'content': latest,
        });
      }
    }

    final limitedUserMessages = userMessages.length > 4
        ? userMessages.sublist(userMessages.length - 4)
        : userMessages;

    return [
      {
        'role': 'system',
        'content': _buildLocalToolRouterSystemPrompt(tools),
      },
      ...limitedUserMessages,
    ];
  }





bool _looksLikeLocalToolIntent(
  String latestUserText, {
  required List<Map<String, dynamic>> scopedMessages,
  required List<Map<String, dynamic>> tools,
}) {
  if (tools.isEmpty) return false;

  final query = _buildLocalToolSearchQuery(
    latestUserText: latestUserText,
    scopedMessages: scopedMessages,
  );

  if (query.trim().isEmpty) return false;

  var bestScore = 0;
  String bestTool = '';

  for (final tool in tools) {
    final name = _toolNameFromLocalToolSchema(tool);
    if (name.isEmpty) continue;

    final def = _localToolDefinition(name);
    if (def == null) continue;

    final score = _scoreLocalToolByManifest(
      query: query,
      tool: tool,
      def: def,
    );

    if (score > bestScore) {
      bestScore = score;
      bestTool = def.key;
    }
  }

  final threshold = _localToolIntentThresholdForTools(tools);

  if (kDebugMode) {
    debugPrint(
      'Emma: local tool intent score=$bestScore threshold=$threshold best=$bestTool',
    );
  }

  return bestScore >= threshold;
}

  bool _shouldBufferLocalToolDeltasForJob(Map<String, dynamic> job) {
    final rawMessages = _extractListOfMaps(job['messages']);
    final tools = _extractLocalToolsForEngineFromJob(job);

    if (tools.isEmpty) return false;

    final sessionId = _asInt(job['session_id']) ?? _currentSessionId;

    final scopedMessages = _scopeLocalMessagesToSession(
      rawMessages,
      sessionId: sessionId,
    );

    final latestUserText = _safeText(
      job['input'] ?? _lastUserContent(rawMessages),
    ).trim();

    return _looksLikeLocalToolIntent(
      latestUserText,
      scopedMessages: scopedMessages,
      tools: tools,
    );
  }

  bool _looksLikeStreamingLocalToolResult(String text) {
    final value = _safeText(text).trimLeft().toLowerCase();

    if (value.isEmpty) return false;

    return value.startsWith('<') ||
        value.startsWith('<emma') ||
        value.startsWith('<emma_tool_result') ||
        (value.startsWith('{') &&
            (value.contains('"tool_name"') ||
                value.contains('"arguments"') ||
                value.contains('"assistant_message"')));
  }




List<Map<String, dynamic>> _selectRelevantLocalToolsForPrompt({
  required String latestUserText,
  required List<Map<String, dynamic>> scopedMessages,
  required List<Map<String, dynamic>> tools,
  int maxTools = 12,
}) {
  if (tools.isEmpty) return const <Map<String, dynamic>>[];

  final query = _buildLocalToolSearchQuery(
    latestUserText: latestUserText,
    scopedMessages: scopedMessages,
  );

  if (query.trim().isEmpty) {
    return const <Map<String, dynamic>>[];
  }

  final scored = <MapEntry<int, Map<String, dynamic>>>[];

  for (final tool in tools) {
    final name = _toolNameFromLocalToolSchema(tool);
    if (name.isEmpty) continue;

    final def = _localToolDefinition(name);
    if (def == null) continue;

    final score = _scoreLocalToolByManifest(
      query: query,
      tool: tool,
      def: def,
    );

    if (score > 0) {
      scored.add(MapEntry(score, tool));
    }
  }

  scored.sort((a, b) => b.key.compareTo(a.key));

  final selected = scored
      .take(maxTools)
      .map((entry) => entry.value)
      .toList(growable: false);

  if (kDebugMode) {
    debugPrint(
      'Emma: selected local tools by manifest keywords: '
      '${selected.map(_toolNameFromLocalToolSchema).toList()}',
    );
  }

  return selected;
}


  

  List<String> _extractStringList(dynamic raw) {
    if (raw is! List) return const <String>[];

    return raw
        .map((e) => e?.toString().trim() ?? '')
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }

  String _toolNameFromLocalToolSchema(Map<String, dynamic> tool) {
    final fn = _extractMap(tool['function']);

    return (fn['name'] ?? tool['key'] ?? tool['name'] ?? '').toString().trim();
  }

  String _buildLocalCasualSystemPrompt() {
    return '''
Jesteś Emmą. Odpowiadasz naturalnie, krótko i po polsku.
Nie sugeruj narzędzi, jeśli użytkownik nie prosi o akcję w systemie.
Nie udawaj wykonania akcji systemowej, jeśli nie zwracasz wyniku narzędzia.
''';
  }




  String _buildLocalToolRouterSystemPrompt(
    List<Map<String, dynamic>> tools,
  ) {
    final now = DateTime.now();
    final today = _localDateOnly(now);
    final tomorrow = _localDateOnly(now.add(const Duration(days: 1)));
    final dayAfterTomorrow = _localDateOnly(now.add(const Duration(days: 2)));
    final timezoneOffset = _localTimezoneOffsetIso();


      final compactTools = tools.take(30).map((tool) {
        final fnRaw = tool['function'];
        final fn = fnRaw is Map ? Map<String, dynamic>.from(fnRaw) : tool;

        final name = (fn['name'] ?? tool['key'] ?? '').toString();
        final def = _localToolDefinition(name);

        return {
          'name': name,
          'description': fn['description'] ?? tool['description'] ?? '',
          'parameters_schema': fn['parameters'] ?? tool['parameters_schema'] ?? {},
          'keywords': def?.keywords.take(40).toList(growable: false) ?? [],
          'aliases': def?.aliases.take(20).toList(growable: false) ?? [],
          'examples': tool['examples'] ?? [],
        };
      }).toList(growable: false);

    return '''
Jesteś lokalnym routerem narzędzi Emmy.

Aktualny lokalny czas użytkownika:
- now: ${_formatLocalIso8601WithOffset(now)}
- today: $today
- tomorrow: $tomorrow
- day_after_tomorrow: $dayAfterTomorrow
- timezone_offset: $timezoneOffset

Jeżeli użytkownik prosi o wykonanie akcji pasującej do narzędzia, zwróć WYŁĄCZNIE:

<emma_tool_result>
{
  "tool_name": "...",
  "arguments": {},
  "assistant_message": "Krótka wiadomość dla użytkownika.",
  "optimistic_block": {}
}
</emma_tool_result>

BARDZO WAŻNE:
- Nie pisz zwykłej odpowiedzi, jeśli trzeba użyć narzędzia.
- Nie mów, że akcja została wykonana, jeśli nie zwracasz <emma_tool_result>.
- Nie zwracaj markdown.
- Nie dodawaj tekstu przed tagiem.
- Nie dodawaj tekstu po tagu.
- Nie wymyślaj nazw narzędzi.
- Używaj wyłącznie nazw narzędzi z listy.
- arguments muszą pasować do parameters_schema.
- optimistic_block zostaw jako pusty obiekt {}.
- Bloki UI tworzy aplikacja z manifestu, nie model.
- Daty względne typu "jutro", "dzisiaj", "dziś", "pojutrze", "w poniedziałek" licz od aktualnego lokalnego czasu użytkownika.
- "jutro" oznacza dokładnie $tomorrow.
- Daty zwracaj jako ISO 8601 z timezone, np. ${tomorrow}T12:00:00$timezoneOffset.
- Jeśli użytkownik poda godzinę bez czasu trwania, przyjmij 1 godzinę.
- Jeśli użytkownik doprecyzowuje poprzednią prośbę, użyj kontekstu ostatnich wiadomości użytkownika.
- Jeśli nie trzeba używać narzędzia, odpowiedz normalnym tekstem.
- Nigdy nie zwracaj podwójnych klamerek typu {{ ... }}.

Dostępne narzędzia:
${const JsonEncoder.withIndent('  ').convert(compactTools)}
''';
  }

  String _localDateOnly(DateTime value) {
    final local = value.toLocal();

    String two(int v) => v.toString().padLeft(2, '0');

    return '${local.year}-${two(local.month)}-${two(local.day)}';
  }

  String _localTimezoneOffsetIso() {
    final offset = DateTime.now().timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final absOffset = offset.abs();

    String two(int v) => v.toString().padLeft(2, '0');

    final offsetHours = two(absOffset.inHours);
    final offsetMinutes = two(absOffset.inMinutes.remainder(60));

    return '$sign$offsetHours:$offsetMinutes';
  }

  List<Map<String, dynamic>> _extractLocalToolsForEngineFromJob(
    Map<String, dynamic> job,
  ) {
    final rawMessages = _extractListOfMaps(job['messages']);

    final manifestTools = _getLocalToolSchemasForEngineFromManifest(
      job: job,
      messages: rawMessages,
    );

    final safeManifestTools = manifestTools.where((tool) {
      final name = _toolNameFromLocalToolSchema(tool);
      final def = _localToolDefinition(name);

      if (def == null && kDebugMode) {
        debugPrint(
          'Emma: manifest tool schema rejected because runtime def is missing: $name',
        );
      }

      return def != null;
    }).toList(growable: false);

    if (kDebugMode) {
      debugPrint(
        'Emma: local tools for engine: '
        '${safeManifestTools.map(_toolNameFromLocalToolSchema).toList()}',
      );
    }

    return safeManifestTools;
  }

  List<Map<String, dynamic>> _getLocalToolSchemasForEngineFromManifest({
    required Map<String, dynamic> job,
    required List<Map<String, dynamic>> messages,
  }) {
    final defs = _uniqueLocalToolDefinitionsFromManifest();

    if (defs.isEmpty) {
      if (kDebugMode) {
        debugPrint('Emma: local manifest empty. No local tools exposed.');
      }

      return const <Map<String, dynamic>>[];
    }

    final isOfflineJob = _isOfflineLocalJob(job);
    final out = <Map<String, dynamic>>[];

    for (final def in defs) {
      if (!_canExposeLocalToolDefToEngine(
        def,
        isOfflineJob: isOfflineJob,
      )) {
        continue;
      }

      final schema = _localEngineToolSchemaFromManifestDef(def);
      final name = _toolNameFromLocalToolSchema(schema);

      if (_localToolDefinition(name) == null) {
        if (kDebugMode) {
          debugPrint(
            'Emma: local manifest invariant broken. '
            'Generated schema name=$name but def lookup failed.',
          );
        }

        continue;
      }

      out.add(schema);
    }

    return out;
  }

  bool _canExposeLocalToolDefToEngine(
    _EmmaLocalToolDefinition def, {
    required bool isOfflineJob,
  }) {
    final frontendMode = def.frontendMode.trim().toLowerCase();

    if (frontendMode == 'disabled' ||
        frontendMode == 'hidden' ||
        frontendMode == 'off') {
      return false;
    }

    if (def.executionMode == 'backendOnly' && isOfflineJob) {
      return false;
    }

    if (isOfflineJob && def.requiresOnline && !def.offlineQueueable) {
      return false;
    }

    return true;
  }



  String _formatLocalIso8601WithOffset(DateTime value) {
    final local = value.toLocal();
    final offset = local.timeZoneOffset;

    final sign = offset.isNegative ? '-' : '+';
    final absOffset = offset.abs();

    String two(int v) => v.toString().padLeft(2, '0');
    String four(int v) => v.toString().padLeft(4, '0');

    final offsetHours = two(absOffset.inHours);
    final offsetMinutes = two(absOffset.inMinutes.remainder(60));

    return '${four(local.year)}-'
        '${two(local.month)}-'
        '${two(local.day)}T'
        '${two(local.hour)}:'
        '${two(local.minute)}:'
        '${two(local.second)}'
        '$sign$offsetHours:$offsetMinutes';
  }

  String _repairCommonMalformedLocalToolContent(String raw) {
    var text = _safeText(raw).trim();

    if (text.isEmpty) return text;

    const openTag = '<emma_tool_result>';
    const closeTag = '</emma_tool_result>';

    final lower = text.toLowerCase();
    final openIndex = lower.indexOf(openTag);
    final closeIndex = lower.indexOf(closeTag);

    if (openIndex != -1 && closeIndex != -1 && closeIndex > openIndex) {
      final before = text.substring(0, openIndex + openTag.length);
      final inner = text.substring(openIndex + openTag.length, closeIndex);
      final after = text.substring(closeIndex);

      return '$before\n${_repairMalformedJsonEnvelope(inner)}\n$after'.trim();
    }

    return _repairMalformedJsonEnvelope(text);
  }

  String _repairMalformedJsonEnvelope(String raw) {
    var text = _safeText(raw).trim();

    while (text.startsWith('{{') && text.endsWith('}}') && text.length >= 4) {
      text = text.substring(1, text.length - 1).trim();
    }

    text = text
        .replaceAll(RegExp(r',\s*}'), '}')
        .replaceAll(RegExp(r',\s*]'), ']');

    return text.trim();
  }

  Map<String, dynamic> _stripHeavyLocalLlmMetadata(
    Map<String, dynamic> metadata,
  ) {
    final clean = Map<String, dynamic>.from(metadata);

    clean.remove('tools');
    clean.remove('available_tools');
    clean.remove('tool_definitions');
    clean.remove('messages');
    clean.remove('conversation');
    clean.remove('history');
    clean.remove('raw_context');
    clean.remove('prompt_messages');

    final modelSelectionRaw = clean['model_selection'];

    if (modelSelectionRaw is Map) {
      final modelSelection = Map<String, dynamic>.from(modelSelectionRaw);
      modelSelection.remove('tools');
      modelSelection.remove('tool_definitions');
      clean['model_selection'] = modelSelection;
    }

    final routingRaw = clean['routing'];

    if (routingRaw is Map) {
      final routing = Map<String, dynamic>.from(routingRaw);
      routing.remove('tools');
      routing.remove('tool_definitions');
      clean['routing'] = routing;
    }

    return clean;
  }

  Stream<_LocalEngineStreamEvent> _postLocalNdjson({
    required Map<String, dynamic> job,
    required String path,
    required Map<String, dynamic> payload,
  }) async* {
    final baseUrl = _resolveLocalEngineBaseUrl(job);
    final token = _resolveLocalEngineToken(job);

    final url = '$baseUrl$path';

    if (kDebugMode) {
      debugPrint('Emma: local engine request $url');
    }

    _debugLocalLlmRequest(
      url: url,
      path: path,
      payload: payload,
    );

    final response = await _localDio.post<ResponseBody>(
      url,
      data: payload,
      options: Options(
        responseType: ResponseType.stream,
        receiveTimeout: Duration.zero,
        headers: {
          'X-Superbee-Token': token,
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/x-ndjson, application/json, text/plain, */*',
        },
        validateStatus: (status) {
          if (status == null) return false;
          return status >= 200 && status < 500;
        },
      ),
    );

    final statusCode = response.statusCode ?? 0;

    _debugLocalLlmHttpResponse(
      url: url,
      statusCode: statusCode,
    );

    if (statusCode >= 400) {
      var errorBody = '';

      try {
        errorBody = await response.data?.stream
                .cast<List<int>>()
                .transform(utf8.decoder)
                .join() ??
            '';
      } catch (_) {}

      _debugPrintLocalLlmLong(
        'EMMA LOCAL LLM ERROR BODY <- HTTP $statusCode',
        errorBody,
      );

      throw StateError(
        'Local engine HTTP $statusCode.${errorBody.trim().isNotEmpty ? ' $errorBody' : ''}',
      );
    }

    final bodyStream = response.data?.stream;

    if (bodyStream == null) {
      throw StateError('Local engine returned empty stream.');
    }

    final lines = bodyStream
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    await for (final line in lines) {
      if (!_canEmit) return;

      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      try {
        final decoded = jsonDecode(trimmed);

        if (decoded is Map<String, dynamic>) {
          _debugLocalLlmEvent(decoded);
          yield _LocalEngineStreamEvent(decoded);
        } else if (decoded is Map) {
          final event = Map<String, dynamic>.from(decoded);
          _debugLocalLlmEvent(event);
          yield _LocalEngineStreamEvent(event);
        } else {
          _debugLocalLlmRawLine(trimmed);
        }
      } catch (_) {
        _debugLocalLlmRawLine(trimmed);

        yield _LocalEngineStreamEvent({
          'event': 'answer_delta',
          'delta': _safeText(trimmed),
        });
      }
    }
  }

  Future<void> _syncLocalResultToBackend({
    required Map<String, dynamic> job,
    required String content,
    required String thinking,
    required List<Map<String, dynamic>> audioChunks,
    required List<Map<String, dynamic>> skippedAudioChunks,
    Map<String, dynamic> extraMeta = const <String, dynamic>{},
    String? error,
    String? warning,
  }) async {
    if (_isOfflineLocalJob(job)) {
      if (kDebugMode) {
        debugPrint('Emma: offline local result sync skipped.');
      }

      return;
    }

    final callbackUrl =
        (job['callback_url'] ?? URLsEmma.emmaLocalResoult).toString();

    if (callbackUrl.trim().isEmpty) return;

    if (callbackUrl.startsWith('/')) {
      if (kDebugMode) {
        debugPrint(
          'Emma: local result sync skipped because callback_url is relative: $callbackUrl',
        );
      }

      return;
    }

    final sessionId = _asInt(job['session_id']) ?? _currentSessionId;
    final assistantMessageId = _asInt(job['assistant_message_id']);

    if (sessionId == null || assistantMessageId == null) return;
    if (sessionId <= 0 || assistantMessageId <= 0) return;

    final payload = {
      'session_id': sessionId,
      'assistant_message_id': assistantMessageId,
      'content': _safeText(content),
      'thinking': _safeText(thinking),
      'audio_chunks': audioChunks,
      'local_job_id': (job['local_job_id'] ?? job['job_id'] ?? '').toString(),
      'engine': (job['engine'] ?? 'superbee').toString(),
      'mode': (job['mode'] ?? 'text').toString(),
      'meta': {
        'local_engine_synced_from_frontend': true,
        'skipped_audio_chunks': skippedAudioChunks,
        'skipped_audio_chunk_count': skippedAudioChunks.length,
        ...extraMeta,
        if (error != null && error.trim().isNotEmpty)
          'local_engine_error': error,
        if (warning != null && warning.trim().isNotEmpty)
          'local_engine_warning': warning,
      },
    };

    try {
      await ApiServices.post(
        callbackUrl,
        hasToken: true,
        ref: ref,
        data: payload,
      );
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('Emma: local result sync failed: $e\n$stack');
      }
    }
  }

  bool get _debugLocalLlmIo {
    return kDebugMode ||
        const bool.fromEnvironment(
          'EMMA_DEBUG_LOCAL_LLM_IO',
          defaultValue: false,
        );
  }

  int get _debugLocalLlmMaxChars {
    return const int.fromEnvironment(
      'EMMA_DEBUG_LOCAL_LLM_IO_MAX_CHARS',
      defaultValue: 60000,
    );
  }

  dynamic _redactLocalLlmDebugValue(dynamic value, {String? key}) {
    if (key != null && _isSensitiveLocalLlmDebugKey(key)) {
      return '<redacted>';
    }

    if (value is Map) {
      final out = <String, dynamic>{};

      value.forEach((rawKey, rawValue) {
        final keyText = rawKey.toString();

        out[keyText] = _redactLocalLlmDebugValue(
          rawValue,
          key: keyText,
        );
      });

      return out;
    }

    if (value is List) {
      return value
          .map((item) => _redactLocalLlmDebugValue(item))
          .toList(growable: false);
    }

    return value;
  }

  bool _isSensitiveLocalLlmDebugKey(String key) {
    final lower = key.toLowerCase().trim();

    const safeKeys = <String>{
      'max_tokens',
      'tokens',
      'token_count',
      'prompt_tokens',
      'completion_tokens',
      'total_tokens',
      'n_tokens',
    };

    if (safeKeys.contains(lower)) return false;

    return lower == 'token' ||
        lower.endsWith('_token') ||
        lower.contains('auth_token') ||
        lower.contains('access_token') ||
        lower.contains('refresh_token') ||
        lower.contains('password') ||
        lower.contains('secret') ||
        lower.contains('authorization') ||
        lower.contains('access_key') ||
        lower.contains('refresh_key');
  }

  String _prettyLocalLlmDebugJson(dynamic value) {
    try {
      return const JsonEncoder.withIndent('  ').convert(
        _redactLocalLlmDebugValue(value),
      );
    } catch (_) {
      return _safeText(value);
    }
  }

  void _debugPrintLocalLlmLong(
    String title,
    String value, {
    int chunkSize = 3500,
  }) {
    if (!_debugLocalLlmIo) return;

    final maxChars = _debugLocalLlmMaxChars;

    final text = value.length > maxChars
        ? '${value.substring(0, maxChars)}\n... <truncated ${value.length - maxChars} chars>'
        : value;

    debugPrint('\n==================== $title ====================');

    if (text.isEmpty) {
      debugPrint('<empty>');
      debugPrint('================== END $title ==================\n');
      return;
    }

    var index = 0;
    var chunkIndex = 1;
    final totalChunks = (text.length / chunkSize).ceil();

    while (index < text.length) {
      final end =
          (index + chunkSize > text.length) ? text.length : index + chunkSize;

      debugPrint(
        '[$chunkIndex/$totalChunks] ${text.substring(index, end)}',
      );

      index = end;
      chunkIndex++;
    }

    debugPrint('================== END $title ==================\n');
  }

  void _debugLocalLlmRequest({
    required String url,
    required String path,
    required Map<String, dynamic> payload,
  }) {
    if (!_debugLocalLlmIo) return;

    _debugPrintLocalLlmLong(
      'EMMA LOCAL LLM REQUEST -> $path',
      _prettyLocalLlmDebugJson({
        'url': url,
        'path': path,
        'payload': payload,
      }),
    );
  }

  void _debugLocalLlmHttpResponse({
    required String url,
    required int statusCode,
  }) {
    if (!_debugLocalLlmIo) return;

    debugPrint(
      '\n[EMMA LOCAL LLM HTTP] <- $statusCode $url\n',
    );
  }

  void _debugLocalLlmEvent(Map<String, dynamic> event) {
    if (!_debugLocalLlmIo) return;

    final eventName = (event['event'] ?? event['type'] ?? 'unknown').toString();

    _debugPrintLocalLlmLong(
      'EMMA LOCAL LLM EVENT <- $eventName',
      _prettyLocalLlmDebugJson(event),
      chunkSize: 3500,
    );
  }

  void _debugLocalLlmRawLine(String line) {
    if (!_debugLocalLlmIo) return;

    _debugPrintLocalLlmLong(
      'EMMA LOCAL LLM RAW <-',
      line,
      chunkSize: 3500,
    );
  }

  String _resolveLocalEngineBaseUrl(Map<String, dynamic> job) {
    final fromJob = (job['base_url'] ??
            job['local_base_url'] ??
            job['engine_url'] ??
            job['local_engine_url'])
        ?.toString()
        .trim();

    if (fromJob != null && fromJob.isNotEmpty) {
      return fromJob.endsWith('/')
          ? fromJob.substring(0, fromJob.length - 1)
          : fromJob;
    }

    const fromEnv = String.fromEnvironment(
      'SUPERBEE_LOCAL_ENGINE_URL',
      defaultValue: 'http://127.0.0.1:43890',
    );

    return fromEnv.endsWith('/')
        ? fromEnv.substring(0, fromEnv.length - 1)
        : fromEnv;
  }

  String _resolveLocalEngineToken(Map<String, dynamic> job) {
    final fromJob = (job['token'] ?? job['local_token'] ?? job['engine_token'])
        ?.toString()
        .trim();

    if (fromJob != null && fromJob.isNotEmpty) return fromJob;

    // Use the live provider value — it's updated by emmaLocalEngineLifecycleProvider
    // once LocalEngineManager reads the real token from config.json.
    final fromProvider = ref.read(emmaLocalEngineTokenProvider).trim();
    if (fromProvider.isNotEmpty && fromProvider != 'dev-superbee-token') {
      return fromProvider;
    }

    const fromEnv = String.fromEnvironment(
      'SUPERBEE_LOCAL_ENGINE_TOKEN',
      defaultValue: 'dev-superbee-token',
    );

    return fromEnv;
  }




  String _buildLocalToolSearchQuery({
  required String latestUserText,
  required List<Map<String, dynamic>> scopedMessages,
}) {
  final recentUserText = scopedMessages
      .where((message) => message['role']?.toString() == 'user')
      .map((message) => _safeText(message['content']))
      .where((text) => text.trim().isNotEmpty)
      .toList(growable: false);

  final limitedRecent = recentUserText.length > 4
      ? recentUserText.sublist(recentUserText.length - 4)
      : recentUserText;

  return [
    ...limitedRecent,
    latestUserText,
  ].join('\n');
}

int _localToolIntentThresholdForTools(List<Map<String, dynamic>> tools) {
  var threshold = 8;

  for (final tool in tools) {
    final name = _toolNameFromLocalToolSchema(tool);
    final def = _localToolDefinition(name);
    if (def == null) continue;

    final uiHints = _extractMap(def.uiHints);

    final rawThreshold = uiHints['local_intent_threshold'] ??
        uiHints['intent_threshold'] ??
        uiHints['routing_threshold'];

    final parsed = _asInt(rawThreshold);

    if (parsed != null && parsed > 0) {
      threshold = parsed < threshold ? parsed : threshold;
    }
  }

  return threshold;
}

int _scoreLocalToolByManifest({
  required String query,
  required Map<String, dynamic> tool,
  required _EmmaLocalToolDefinition def,
}) {
  final normalizedQuery = _normalizeLocalToolSearchText(query);
  if (normalizedQuery.isEmpty) return 0;

  final queryTokens = _tokenizeLocalToolSearchText(normalizedQuery);
  if (queryTokens.isEmpty) return 0;

  var score = 0;

  final keywordScore = _scoreManifestPhrases(
    normalizedQuery: normalizedQuery,
    queryTokens: queryTokens,
    phrases: def.keywords,
    exactPhraseScore: 12,
    partialPhraseScore: 6,
    tokenScore: 2,
  );

  score += keywordScore;

  final aliasScore = _scoreManifestPhrases(
    normalizedQuery: normalizedQuery,
    queryTokens: queryTokens,
    phrases: def.aliases,
    exactPhraseScore: 14,
    partialPhraseScore: 7,
    tokenScore: 2,
  );

  score += aliasScore;

  final fn = _extractMap(tool['function']);

  final softText = [
    def.key,
    def.title,
    def.description,
    def.moduleKey,
    _safeText(tool['description']),
    _safeText(fn['description']),
    _parametersSchemaSearchText(def.parametersSchema),
    _parametersSchemaSearchText(_extractMap(fn['parameters'])),
  ].join(' ');

  score += _scoreSoftManifestText(
    normalizedQuery: normalizedQuery,
    queryTokens: queryTokens,
    rawText: softText,
  );

  final examples = def.examples;
  if (examples.isNotEmpty) {
    score += _scoreManifestExamples(
      normalizedQuery: normalizedQuery,
      queryTokens: queryTokens,
      examples: examples,
    );
  }

  final uiHints = _extractMap(def.uiHints);
  final extraKeywords = _extractStringList(
    uiHints['keywords'] ??
        uiHints['local_keywords'] ??
        uiHints['routing_keywords'] ??
        uiHints['intent_keywords'],
  );

  if (extraKeywords.isNotEmpty) {
    score += _scoreManifestPhrases(
      normalizedQuery: normalizedQuery,
      queryTokens: queryTokens,
      phrases: extraKeywords,
      exactPhraseScore: 12,
      partialPhraseScore: 6,
      tokenScore: 2,
    );
  }

  final negativeKeywords = _extractStringList(
    uiHints['negative_keywords'] ??
        uiHints['exclude_keywords'] ??
        uiHints['local_negative_keywords'],
  );

  if (negativeKeywords.isNotEmpty) {
    final negativeScore = _scoreManifestPhrases(
      normalizedQuery: normalizedQuery,
      queryTokens: queryTokens,
      phrases: negativeKeywords,
      exactPhraseScore: 20,
      partialPhraseScore: 10,
      tokenScore: 3,
    );

    score -= negativeScore;
  }

  return score < 0 ? 0 : score;
}

int _scoreManifestPhrases({
  required String normalizedQuery,
  required Set<String> queryTokens,
  required List<String> phrases,
  required int exactPhraseScore,
  required int partialPhraseScore,
  required int tokenScore,
}) {
  var score = 0;

  for (final rawPhrase in phrases) {
    final phrase = _normalizeLocalToolSearchText(rawPhrase);
    if (phrase.isEmpty) continue;

    final phraseTokens = _tokenizeLocalToolSearchText(phrase);
    if (phraseTokens.isEmpty) continue;

    if (normalizedQuery == phrase) {
      score += exactPhraseScore * 2;
      continue;
    }

    if (normalizedQuery.contains(phrase)) {
      score += exactPhraseScore;
      continue;
    }

    if (phrase.contains(normalizedQuery) && normalizedQuery.length >= 4) {
      score += partialPhraseScore;
      continue;
    }

    final matchingTokens = phraseTokens.intersection(queryTokens).length;

    if (matchingTokens > 0) {
      final ratio = matchingTokens / phraseTokens.length;

      if (ratio >= 0.75) {
        score += partialPhraseScore;
      } else {
        score += matchingTokens * tokenScore;
      }
    }
  }

  return score;
}

int _scoreSoftManifestText({
  required String normalizedQuery,
  required Set<String> queryTokens,
  required String rawText,
}) {
  final text = _normalizeLocalToolSearchText(rawText);
  if (text.isEmpty) return 0;

  var score = 0;

  for (final token in queryTokens) {
    if (token.length < 3) continue;

    if (text.split(' ').contains(token)) {
      score += 1;
      continue;
    }

    if (token.length >= 5 && text.contains(token)) {
      score += 1;
    }
  }

  return score;
}

int _scoreManifestExamples({
  required String normalizedQuery,
  required Set<String> queryTokens,
  required List<dynamic> examples,
}) {
  var score = 0;

  for (final example in examples) {
    if (example is Map) {
      final userText = _safeText(
        example['user'] ??
            example['input'] ??
            example['message'] ??
            example['prompt'] ??
            '',
      );

      if (userText.trim().isEmpty) continue;

      score += _scoreManifestPhrases(
        normalizedQuery: normalizedQuery,
        queryTokens: queryTokens,
        phrases: [userText],
        exactPhraseScore: 10,
        partialPhraseScore: 5,
        tokenScore: 1,
      );

      continue;
    }

    final text = _safeText(example);
    if (text.trim().isEmpty) continue;

    score += _scoreManifestPhrases(
      normalizedQuery: normalizedQuery,
      queryTokens: queryTokens,
      phrases: [text],
      exactPhraseScore: 10,
      partialPhraseScore: 5,
      tokenScore: 1,
    );
  }

  return score;
}

String _parametersSchemaSearchText(Map<String, dynamic> schema) {
  final buffer = StringBuffer();

  void walk(dynamic value) {
    if (value is Map) {
      final title = value['title'];
      final description = value['description'];
      final enumValues = value['enum'];

      if (title != null) {
        buffer.write(' ');
        buffer.write(title);
      }

      if (description != null) {
        buffer.write(' ');
        buffer.write(description);
      }

      if (enumValues is List) {
        buffer.write(' ');
        buffer.write(enumValues.join(' '));
      }

      for (final child in value.values) {
        walk(child);
      }

      return;
    }

    if (value is List) {
      for (final item in value) {
        walk(item);
      }
    }
  }

  walk(schema);

  return buffer.toString();
}

String _normalizeLocalToolSearchText(dynamic value) {
  var text = _safeText(value).trim().toLowerCase();

  if (text.isEmpty) return '';

  const replacements = {
    'ą': 'a',
    'ć': 'c',
    'ę': 'e',
    'ł': 'l',
    'ń': 'n',
    'ó': 'o',
    'ś': 's',
    'ź': 'z',
    'ż': 'z',
  };

  replacements.forEach((from, to) {
    text = text.replaceAll(from, to);
  });

  text = text
      .replaceAll(RegExp(r'[_\-/.]+'), ' ')
      .replaceAll(RegExp(r'[^a-z0-9\s]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  return text;
}

Set<String> _tokenizeLocalToolSearchText(String normalizedText) {
  if (normalizedText.trim().isEmpty) return <String>{};

  return normalizedText
      .split(' ')
      .map((token) => token.trim())
      .where((token) => token.length >= 2)
      .toSet();
}
}











