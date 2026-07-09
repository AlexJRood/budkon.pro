part of '../emma_notifier.dart';

/// Disconnection, generation cancellation and WebSocket-only reconnect helpers.
extension EmmaNotifierLifecycle on ChatAiMessagesNotifier {
  Future<void> _disconnectInternal() async {
    _cloudResponseGuardGeneration++;
    _localJobGeneration++;
    _activeLocalJobId = null;

    try {
      await _wsSubscription?.cancel().timeout(const Duration(seconds: 2));
    } catch (_) {}
    _wsSubscription = null;

    try {
      // A brand-new WS connection may still be mid-handshake (the socket's
      // connect future never resolves, e.g. server not yet ready right after
      // session creation, or a stalled mobile network). IOWebSocketChannel's
      // sink.close() awaits that same connect future internally, so without a
      // timeout here this can hang forever and wedge every caller of
      // _disconnectInternal (sendMessage's WS health check included), leaving
      // the compose box stuck in a busy state for new chats.
      await _channel?.sink.close().timeout(const Duration(seconds: 2));
    } catch (_) {}
    _channel = null;

    _isConnected = false;
  }

  Future<void> disconnect() async {
    await _stopLocalTalkAudio();
    await _disconnectInternal();
  }

  Future<void> stopGenerating({bool reconnect = true}) async {
    final sessionId = _currentSessionId;

    _cloudResponseGuardGeneration++;
    _localJobGeneration++;
    _activeLocalJobId = null;

    await _stopLocalTalkAudio();

    _stopLoadingWatchdog();

    state = state.copyWith(
      isLoading: false,
      clearThinking: true,
      clearActivity: true,
      canCancel: false,
    );

    if (reconnect && sessionId != null && sessionId > 0) {
      await _disconnectInternal();
      await _reconnectWsOnly(sessionId);
    }

    if (sessionId != null && sessionId > 0) {
      await refreshLatestMessages();
    }

    unawaited(_trySyncNow());
  }

  Future<void> _reconnectWsOnly(int sessionId) async {
    if (sessionId <= 0) return;

    _wsReadyCompleter = Completer<void>();
    await _connectWs(sessionId);
  }
}
