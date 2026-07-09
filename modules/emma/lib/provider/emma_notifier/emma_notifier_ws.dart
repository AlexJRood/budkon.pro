part of '../emma_notifier.dart';

/// Cloud WebSocket connection and event routing.
///
/// This layer parses incoming WebSocket events and delegates actual state
/// changes to focused helpers such as message merge, blocks, reactions and the
/// local-engine handler.
extension EmmaNotifierWs on ChatAiMessagesNotifier {
  EmmaThinkingPublic? _parseThinkingPublic(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return EmmaThinkingPublic.fromJson(raw);
    }

    if (raw is Map) {
      return EmmaThinkingPublic.fromJson(Map<String, dynamic>.from(raw));
    }

    return null;
  }

  void _handleThinking(Map<String, dynamic> data) {
    final raw = data['thinking_public'] ?? data['thinking'];
    final thinking = _parseThinkingPublic(raw);
    if (thinking == null) return;

    state = state.copyWith(thinking: thinking);
  }

  Future<void> _connectWs(int sessionId) async {
    if (sessionId <= 0) return;

    _wsReadyCompleter ??= Completer<void>();

    final token = ApiServices.token.toString();
    final wsUrl = URLsEmma.emmaWebSocketChat(sessionId.toString(), token);

    if (kDebugMode) {
      debugPrint('Emma: connecting WS $wsUrl');
    }

    try {
      _isConnected = false;
      // Mirror the proven chat-module connector: the generic
      // WebSocketChannel.connect routes through package:web_socket on native
      // and fails to establish the /ws/emma/ connection on iOS, whereas
      // IOWebSocketChannel works reliably (same path the chat module uses).
      _channel = connectWebSocket(wsUrl);

      _wsSubscription = _channel!.stream.listen(
        (event) {
          if (event == null) return;

          _lastWsEventAt = DateTime.now();

          try {
            final data = jsonDecode(event as String) as Map<String, dynamic>;
            _handleWsEvent(data);
          } catch (e, stack) {
            if (kDebugMode) {
              debugPrint('Emma: WS parse error: $e\n$stack');
            }
          }
        },
        onError: (error) {
          if (kDebugMode) debugPrint('Emma: WS error: $error');

          _isConnected = false;

          final completer = _wsReadyCompleter;
          if (completer != null && !completer.isCompleted) {
            completer.completeError(error);
          }
        },
        onDone: () {
          if (kDebugMode) debugPrint('Emma: WS connection closed');

          _isConnected = false;

          final completer = _wsReadyCompleter;
          if (completer != null && !completer.isCompleted) {
            completer.completeError(StateError('WS closed before ready'));
          }
        },
        cancelOnError: false,
      );
    } catch (e, stack) {
      _isConnected = false;

      if (kDebugMode) {
        debugPrint('Emma: WS connect error: $e\n$stack');
      }

      final completer = _wsReadyCompleter;
      if (completer != null && !completer.isCompleted) {
        completer.completeError(e);
      }
    }
  }

  void _handleWsEvent(Map<String, dynamic> data) {
    _lastWsEventAt = DateTime.now();
    _bumpLoadingWatchdog();

    final eventRaw = (data['event'] ?? '').toString();
    final kindRaw = (data['kind'] ?? '').toString();
    final event = eventRaw.trim().isNotEmpty ? eventRaw : kindRaw;

    if (ChatAiMessagesNotifier._cloudAssistantProgressEvents.contains(event)) {
      _markCloudAssistantProgress();
    }

    if (event == 'connected') {
      _isConnected = true;

      if (kDebugMode) {
        debugPrint('Emma: WS connected event: $data');
      }

      final completer = _wsReadyCompleter;
      if (completer != null && !completer.isCompleted) {
        completer.complete();
      }

      return;
    }

    if (event == 'assistant_tool_plan' || event == 'tool_plan') {
      _handleAssistantToolPlan(data);
      return;
    }

    if (event == 'assistant_tool_call_started' ||
        event == 'tool_call_started') {
      _handleAssistantToolCallStarted(data);
      return;
    }

    if (event == 'assistant_tool_call_finished' ||
        event == 'tool_call_finished') {
      _handleAssistantToolCallFinished(data);
      return;
    }

    if (event == 'assistant_block_pending' || event == 'block_pending') {
      _handleAssistantBlockPending(data);
      return;
    }

    if (event == 'assistant_block_ready' || event == 'block_ready') {
      _handleAssistantBlockReady(data);
      return;
    }

    if (event == 'assistant_block_error' || event == 'block_error') {
      _handleAssistantBlockError(data);
      return;
    }

    if (event == 'local_llm_job') {
      _handleActivityStatus(data);

      state = state.copyWith(
        isLoading: true,
        canCancel: true,
        activityTitle: 'emma_running_locally'.tr,
        activityDetail: 'starting_local_superbee_engine'.tr,
      );

      _startLoadingWatchdog();
      unawaited(_handleLocalLlmJob(data));
      return;
    }

    if (event == 'read_state') {
      _applySeenUpToFromWs(data);
      return;
    }

    if (event == 'ai_thinking' || event == 'thinking') {
      _handleActivityStatus(data);
      _handleThinking(data);
      return;
    }

    if (event == 'ai_status') {
      _handleActivityStatus(data);

      if (data.containsKey('thinking_public') || data.containsKey('thinking')) {
        _handleThinking(data);
      }

      final statusState = data['state'] as String?;

      if (statusState == 'started' || statusState == 'running') {
        state = state.copyWith(isLoading: true, canCancel: true);
        _startLoadingWatchdog();
      } else if (statusState == 'finished') {
        _stopLoadingWatchdog();

        state = state.copyWith(
          isLoading: false,
          clearThinking: true,
          clearActivity: true,
          canCancel: false,
        );
      } else if (statusState == 'error') {
        _stopLoadingWatchdog();

        state = state.copyWith(
          isLoading: false,
          clearThinking: true,
          clearActivity: true,
          canCancel: false,
        );
      }

      return;
    }

    if (event == 'ai_delta') {
      _handleActivityStatus(data);
      _applyAiDelta(data);
      return;
    }

    if (event == 'message' || event == 'message_updated') {
      final msg = _dtoFromWsMessage(data);

      if (!msg.isUser) {
        _markCloudAssistantProgress();
      }

      _upsertMessage(msg);
      _autoMarkSeenIfPossible();
      return;
    }

    if (event == 'message_reaction_updated') {
      final msgId = _asInt(data['message_id']);
      if (msgId == null) return;

      final likes = _asInt(data['likes_count']) ?? 0;
      final dislikes = _asInt(data['dislikes_count']) ?? 0;

      final updated = state.messages
          .map(
            (m) => m.id == msgId
                ? m.copyWith(
                    likesCount: likes,
                    dislikesCount: dislikes,
                  )
                : m,
          )
          .toList();

      state = state.copyWith(messages: updated);

      final changed = updated.where((m) => m.id == msgId);
      if (changed.isNotEmpty) {
        unawaited(_persistMessageLocal(changed.first));
      }

      return;
    }

    if (event == 'seen_updated' ||
        event == 'messages_seen' ||
        event == 'message_seen_updated') {
      _applySeenUpToFromWs(data);
      return;
    }

    if (event == 'session_updated') {
      final sessionId = _asInt(data['session_id']);
      final title = data['title'] as String?;

      if (sessionId != null && title != null && title.trim().isNotEmpty) {
        try {
          ref
              .read(chatAiRoomsProvider.notifier)
              .updateSessionTitle(sessionId, title);
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Emma: failed to update session title: $e');
          }
        }
      }

      return;
    }

    if (event == 'message_retracted') {
      final msgId = _asInt(data['message_id']);
      if (msgId != null && msgId > 0 && _canEmit) {
        final updated =
            state.messages.where((m) => m.id != msgId).toList();
        _emit(state.copyWith(messages: updated));
      }
      return;
    }

    if (kDebugMode) {
      debugPrint('Emma: unhandled WS event: $data');
    }
  }
}
