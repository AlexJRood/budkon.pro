part of '../emma_notifier.dart';

/// Internet checks, cloud readiness checks and cloud-to-local fallback guards.
extension EmmaNotifierHealth on ChatAiMessagesNotifier {
  bool get _canUseLocalFallback => !kIsWeb;

  Future<bool> _hasInternetRightNowFast() async {
    final netNotifier = ref.read(internet_status.internetProvider.notifier);

    try {
      return await netNotifier.checkNow(
        timeout: const Duration(milliseconds: 900),
      );
    } catch (_) {
      return false;
    }
  }

  Future<bool> _shouldUseLocalImmediatelyAsync() async {
    if (!_canUseLocalFallback) return false;

    try {
      if (ref.read(internet_status.internetProvider) == false) {
        return true;
      }
    } catch (_) {}

    final hasInternet = await _hasInternetRightNowFast();
    return !hasInternet;
  }

  Future<bool> _ensureCloudWsReady(
    int sessionId, {
    Duration timeout = const Duration(seconds: 4),
  }) async {
    if (sessionId <= 0) return false;

    if (_channel != null && _isConnected) {
      return true;
    }

    try {
      if (kDebugMode) {
        debugPrint('Emma: WS not ready, trying reconnect before cloud send...');
      }

      await _disconnectInternal();
      await _reconnectWsOnly(sessionId);
      await waitForWsReady(timeout: timeout);

      return _channel != null && _isConnected;
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('Emma: WS reconnect healthcheck failed: $e\n$stack');
      }

      return false;
    }
  }

  void _markCloudAssistantProgress() {
    _lastCloudAssistantProgressAt = DateTime.now();
  }

  bool _hasAssistantProgressSince(DateTime sentAt) {
    final progressAt = _lastCloudAssistantProgressAt;

    if (progressAt != null && !progressAt.isBefore(sentAt)) {
      return true;
    }

    final minAt = sentAt.subtract(const Duration(seconds: 3));

    return state.messages.any((m) {
      if (m.isUser) return false;
      if (m.createdAt.isBefore(minAt)) return false;

      final content = m.content.trim();
      if (content.isNotEmpty) return true;

      final streaming = m.meta['streaming'] == true;
      final streamState = (m.meta['stream_state'] ?? '').toString();

      if (streaming ||
          streamState == 'started' ||
          streamState == 'streaming' ||
          streamState == 'waiting_local_engine') {
        return true;
      }

      final blocks = m.meta['blocks'];
      if (blocks is List && blocks.isNotEmpty) return true;

      return false;
    });
  }

  void _startCloudResponseGuard({
    required int sessionId,
    required String userText,
    required int optimisticUserMessageId,
    required Map<String, dynamic> backendCtx,
    required DateTime sentAt,
    // Podniesione: długie operacje (generacja obrazu 15s+, wolny initial LLM) nie mogą
    // wywoływać fałszywej „ciszy" i czyścić wskaźnika ładowania. Genuine hang i tak
    // wykryjemy — user wybrał cloud (brak fallbacku), więc lepiej pokazać, że pracuje.
    Duration initialTimeout = const Duration(seconds: 25),
    Duration stalledTimeout = const Duration(seconds: 45),
  }) {
    if (!_canUseLocalFallback) return;
    if (sessionId <= 0) return;

    final generation = ++_cloudResponseGuardGeneration;

    unawaited(
      _runCloudResponseGuard(
        generation: generation,
        sessionId: sessionId,
        userText: userText,
        optimisticUserMessageId: optimisticUserMessageId,
        backendCtx: backendCtx,
        sentAt: sentAt,
        initialTimeout: initialTimeout,
        stalledTimeout: stalledTimeout,
      ),
    );
  }

  Future<void> _runCloudResponseGuard({
    required int generation,
    required int sessionId,
    required String userText,
    required int optimisticUserMessageId,
    required Map<String, dynamic> backendCtx,
    required DateTime sentAt,
    required Duration initialTimeout,
    required Duration stalledTimeout,
  }) async {
    await Future.delayed(initialTimeout);

    if (_isDisposed) return;
    if (generation != _cloudResponseGuardGeneration) return;
    if (!state.isLoading) return;

    if (!_hasAssistantProgressSince(sentAt)) {
      final runtimeMode = ref.read(emmaRuntimeModeProvider);

      if (runtimeMode == EmmaRuntimeMode.cloud) {
        // User explicitly chose cloud — don't fall back to local on silence.
        // Cancel loading so UI doesn't hang; the user can retry.
        if (kDebugMode) {
          debugPrint(
            'Emma: cloud silent after send (cloud mode selected) — aborting, not falling back.',
          );
        }

        // Cisza backendu musi być WIDOCZNA — wcześniej stan był tylko czyszczony,
        // więc wyglądało to, jakby Emma zignorowała wiadomość.
        _setSendError('emma_no_response'.tr, retryText: userText);

        return;
      }

      if (kDebugMode) {
        debugPrint(
          'Emma: cloud silent after send, switching to local fallback.',
        );
      }

      await _runOfflineLocalFallback(
        sessionId: sessionId,
        userText: userText,
        optimisticUserMessageId: optimisticUserMessageId,
        backendCtx: backendCtx,
        reason: 'cloud_silent_after_send',
      );

      return;
    }

    await Future.delayed(stalledTimeout);

    if (_isDisposed) return;
    if (generation != _cloudResponseGuardGeneration) return;
    if (!state.isLoading) return;

    final progressAt = _lastCloudAssistantProgressAt;
    final now = DateTime.now();

    final cloudStalled =
        progressAt == null || now.difference(progressAt) >= stalledTimeout;

    final hasVisibleAssistantProgress = state.messages.any((m) {
      if (m.isUser) return false;

      final minAt = sentAt.subtract(const Duration(seconds: 3));
      if (m.createdAt.isBefore(minAt)) return false;

      final content = m.content.trim();
      if (content.isNotEmpty) return true;

      final blocks = m.meta['blocks'];
      if (blocks is List && blocks.isNotEmpty) return true;

      return false;
    });

    if (cloudStalled && !hasVisibleAssistantProgress) {
      final runtimeMode = ref.read(emmaRuntimeModeProvider);

      if (runtimeMode == EmmaRuntimeMode.cloud) {
        if (kDebugMode) {
          debugPrint(
            'Emma: cloud stalled (cloud mode selected) — aborting, not falling back.',
          );
        }

        _stopLoadingWatchdog();

        _emitFrom(
          (s) => s.copyWith(
            isLoading: false,
            canCancel: false,
            clearThinking: true,
            clearActivity: true,
          ),
        );

        return;
      }

      if (kDebugMode) {
        debugPrint(
          'Emma: cloud started but stalled before visible response, switching local.',
        );
      }

      await _runOfflineLocalFallback(
        sessionId: sessionId,
        userText: userText,
        optimisticUserMessageId: optimisticUserMessageId,
        backendCtx: backendCtx,
        reason: 'cloud_stalled_after_send',
      );
    }
  }
}
