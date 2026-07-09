part of '../emma_notifier.dart';

/// User-message send flow.
///
/// The flow always creates and persists an optimistic local user message first,
/// then decides whether to use the cloud WebSocket, local text mode, local voice
/// mode or offline fallback.
extension EmmaNotifierSend on ChatAiMessagesNotifier {
  /// Kończy turę widocznym błędem i zapamiętuje treść do ponowienia.
  ///
  /// Wcześniej porażki tylko czyściły `isLoading` (albo migały etykietą na 3s),
  /// więc wyglądało to, jakby Emma po prostu zignorowała wiadomość.
  void _setSendError(String message, {String? retryText}) {
    if (!_canEmit) return;

    _stopLoadingWatchdog();
    _emitFrom(
      (s) => s.copyWith(
        isLoading: false,
        canCancel: false,
        clearThinking: true,
        clearActivity: true,
        errorText: message,
        retryText: retryText,
      ),
    );
  }

  /// Ponawia ostatnią nieudaną wiadomość (czyści błąd i wysyła jeszcze raz).
  Future<void> retryLastMessage({EmmaDynamicAppContext? ctx}) async {
    final text = (state.retryText ?? '').trim();
    if (text.isEmpty) return;

    _emitFrom((s) => s.copyWith(clearError: true));
    await sendMessage(text, ctx: ctx);
  }

  /// Odrzuca komunikat o błędzie bez ponawiania.
  void dismissSendError() {
    if (!_canEmit) return;
    _emitFrom((s) => s.copyWith(clearError: true));
  }

  Future<void> sendMessage(
    String text, {
    EmmaDynamicAppContext? ctx,
    bool forceLocalTalk = false,
    bool autoplayLocalTalk = false,
    List<Map<String, dynamic>>? images,
    List<Map<String, dynamic>>? documents,
  }) async {
    final trimmed = _safeText(text).trim();
    final hasAttachments =
        (images != null && images.isNotEmpty) ||
        (documents != null && documents.isNotEmpty);
    // Pozwól wysłać samą wiadomość z załącznikami (bez tekstu).
    if (trimmed.isEmpty && !hasAttachments) return;

    // Nowa wysyłka unieważnia poprzedni błąd.
    if (_canEmit && state.hasError) {
      _emitFrom((s) => s.copyWith(clearError: true));
    }

    var sessionId = _currentSessionId;

    if (sessionId == null) {
      if (forceLocalTalk) {
        sessionId = _newOfflineSessionId();
        _currentSessionId = sessionId;
        await _ensureLocalSessionRow(sessionId);
      } else {
        final shouldUseLocalNow = await _shouldUseLocalImmediatelyAsync();

        if (shouldUseLocalNow) {
          sessionId = _newOfflineSessionId();
          _currentSessionId = sessionId;
          await _ensureLocalSessionRow(sessionId);
        } else {
          if (kDebugMode) {
            debugPrint(
              'Emma: cannot send, session is null and cloud seems available',
            );
          }
          return;
        }
      }
    }

    if (forceLocalTalk || autoplayLocalTalk) {
      await _stopLocalTalkAudio();
    }

    state = state.copyWith(
      clearThinking: true,
      clearActivity: true,
    );

    final baseCtx = ref.read(emmaContextProvider);
    final runtimeMode = ref.read(emmaRuntimeModeProvider);
    final runtimeConfig = ref.read(emmaRuntimeModeConfigProvider);
    final selectedVoice = ref.read(emmaSelectedVoiceProvider);

    final anchorRegistry = ref.read(emmaUiAnchorRegistryProvider.notifier);
    final visibleAnchors = anchorRegistry.getVisibleAnchors();
    final semanticAnchors = anchorRegistry.exportSemanticJson();

    final backendCtx = <String, dynamic>{
      ...baseCtx.toBackendContext(dynamicAppOverride: ctx),
      if (visibleAnchors.isNotEmpty) 'visible_anchors': visibleAnchors,
      if (semanticAnchors.isNotEmpty) 'semantic_anchors': semanticAnchors,
    };

    final useLocal =
        !kIsWeb && (forceLocalTalk || runtimeConfig.useLocalEngine);

    final useTalk =
        !kIsWeb && (forceLocalTalk || runtimeMode == EmmaRuntimeMode.localVoice);

    backendCtx['emma_runtime'] = {
      'mode': kIsWeb ? 'cloud' : runtimeMode.name,
      'is_web': kIsWeb,
      'use_local_engine': useLocal,
      'use_talk': useTalk,
      'voice_enabled': useTalk,
      'tts_model': selectedVoice.ttsModel,
      'voice': selectedVoice.voice,
      'language': selectedVoice.language,
      'preset': selectedVoice.id,
    };

    backendCtx['emma_execution'] = kIsWeb
        ? 'cloud'
        : useTalk
            ? 'local_talk'
            : runtimeMode == EmmaRuntimeMode.localText
                ? 'local_text'
                : 'cloud';

    backendCtx['emma_voice'] = selectedVoice.toBackendJson();

    backendCtx['tts'] = {
      'model': selectedVoice.ttsModel,
      'voice': selectedVoice.voice,
      'language': selectedVoice.language,
      'preset': selectedVoice.id,
      'normalize': selectedVoice.normalize,
      'reference_audio_path': selectedVoice.referenceAudioPath,
    };

    final now = DateTime.now();
    final tempId = now.microsecondsSinceEpoch * -1;
    final clientMessageId = 'emma_${sessionId}_${now.microsecondsSinceEpoch}';

    final optimistic = ChatMessageDto(
      id: tempId,
      sessionId: sessionId,
      role: 'user',
      kind: 'text',
      content: trimmed,
      createdAt: now,
      likesCount: 0,
      dislikesCount: 0,
      meta: {
        'client_message_id': clientMessageId,
        'client_uuid': clientMessageId,
        if (sessionId <= 0) 'local_only': true,
        if (forceLocalTalk) 'voice_turn': true,
        if (forceLocalTalk) 'voice_pipeline': 'talk',
      },
      isSeen: true,
      seenAt: now,
    );

    _pendingTurnClientMessageId = clientMessageId;
    _pendingTurnUserTempId = tempId;
    _pendingTurnStartedAt = now;
    _pendingTurnUserText = trimmed;
    _pendingTurnAssistantId = null;

    final updated = [...state.messages, optimistic]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    state = state.copyWith(
      messages: updated,
      isLoading: true,
      canCancel: true,
      clearThinking: true,
      activityTitle: forceLocalTalk ? 'emma_listening'.tr : 'emma_starting'.tr,
      activityDetail: forceLocalTalk
          ? 'forwarding_to_local_voice_pipeline'.tr
          : 'sending_message_preparing_context'.tr,
    );

    await _persistMessageLocal(
      optimistic,
      explicitClientUuid: clientMessageId,
      syncStatus: 'pending_create',
    );

    _startLoadingWatchdog();

    if (forceLocalTalk) {
      await _runOfflineLocalFallback(
        sessionId: sessionId,
        userText: trimmed,
        optimisticUserMessageId: tempId,
        backendCtx: backendCtx,
        reason: 'local_voice_direct',
        forceTalk: true,
        autoplayLocalTalk: autoplayLocalTalk,
      );
      return;
    }

    // In local modes (_useLocal=true), check internet immediately and fall back.
    // In cloud mode, let the WS attempt proceed — the WS failure path handles
    // the error. This prevents unwanted local routing when cloud is selected.
    if (useLocal) {
      final shouldUseLocalNow = await _shouldUseLocalImmediatelyAsync();

      if (shouldUseLocalNow) {
        await _runOfflineLocalFallback(
          sessionId: sessionId,
          userText: trimmed,
          optimisticUserMessageId: tempId,
          backendCtx: backendCtx,
          reason: 'internet_unavailable',
        );
        return;
      }
    }

    if (sessionId <= 0) {
      if (useLocal) {
        await _runOfflineLocalFallback(
          sessionId: sessionId,
          userText: trimmed,
          optimisticUserMessageId: tempId,
          backendCtx: backendCtx,
          reason: 'offline_session',
        );
        return;
      }

      _setSendError('emma_send_failed_network'.tr, retryText: trimmed);
      return;
    }

    final cloudWsReady = await _ensureCloudWsReady(
      sessionId,
      timeout: const Duration(seconds: 4),
    );

    if (!cloudWsReady) {
      if (_canUseLocalFallback && useLocal) {
        await _runOfflineLocalFallback(
          sessionId: sessionId,
          userText: trimmed,
          optimisticUserMessageId: tempId,
          backendCtx: backendCtx,
          reason: 'ws_unavailable',
        );
        return;
      }

      _setSendError('emma_send_failed_network'.tr, retryText: trimmed);
      return;
    }

    final payload = <String, dynamic>{
      'action': 'send_message',
      'message': trimmed,
      'client_message_id': clientMessageId,
      'message_uuid': clientMessageId,
    };

    if (images != null && images.isNotEmpty) {
      payload['images'] = images;
    }
    if (documents != null && documents.isNotEmpty) {
      payload['documents'] = documents;
    }

    if (backendCtx.isNotEmpty) {
      payload['context'] = backendCtx;
      payload['frontend_context'] = backendCtx;
    }

    try {
      final cloudSendAt = DateTime.now();
      _lastCloudAssistantProgressAt = null;

      _channel!.sink.add(jsonEncode(payload));

      _startCloudResponseGuard(
        sessionId: sessionId,
        userText: trimmed,
        optimisticUserMessageId: tempId,
        backendCtx: backendCtx,
        sentAt: cloudSendAt,
      );
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('Emma: send WS error: $e\n$stack');
      }

      if (_canUseLocalFallback) {
        await _runOfflineLocalFallback(
          sessionId: sessionId,
          userText: trimmed,
          optimisticUserMessageId: tempId,
          backendCtx: backendCtx,
          reason: 'ws_send_error',
        );
        return;
      }

      _setSendError('emma_send_failed'.tr, retryText: trimmed);
    }
  }
}