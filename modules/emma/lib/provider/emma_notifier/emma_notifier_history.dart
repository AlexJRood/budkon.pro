part of '../emma_notifier.dart';

/// Session connection, loading watchdog and paginated history loading.
extension EmmaNotifierHistory on ChatAiMessagesNotifier {
  Future<void> waitForWsReady({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final completer = _wsReadyCompleter;
    if (completer == null) return;
    if (completer.isCompleted) return;

    await completer.future.timeout(
      timeout,
      onTimeout: () {
        throw TimeoutException(
          'Emma: WS not ready after ${timeout.inSeconds}s',
        );
      },
    );
  }

  Future<void> connectToSession(int sessionId) async {
    final generation = ++_sessionConnectGeneration;

    await _stopLocalTalkAudio();
    if (!_isActiveGeneration(generation)) return;

    await _disconnectInternal();
    if (!_isActiveGeneration(generation)) return;

    _handledFrontendActionKeys.clear();
    _finishedBlockIds.clear();
    _misroutedDeltaAssistantIds.clear();

    _pendingTurnClientMessageId = null;
    _pendingTurnUserTempId = null;
    _pendingTurnAssistantId = null;
    _pendingTurnStartedAt = null;
    _pendingTurnUserText = null;

    _wsReadyCompleter = Completer<void>();
    _currentSessionId = sessionId;
    _seenSentUpToId = 0;
    _lastWsEventAt = null;
    _lastCloudAssistantProgressAt = null;

    _page = 0;
    _hasMore = true;
    _isFetchingHistory = false;

    _emit(
      state.copyWith(
        messages: const [],
        isLoading: true,
        clearThinking: true,
        clearActivity: true,
        canCancel: false,
      ),
    );

    await _loadLocalMessagesForSession(
      sessionId,
      generation: generation,
    );

    if (!_isActiveSession(generation, sessionId)) return;

    if (sessionId > 0) {
      unawaited(_trySyncNow());

      await _fetchInitialPage(
        sessionId,
        generation: generation,
      );

      if (!_isActiveSession(generation, sessionId)) return;

      await _connectWs(sessionId);

      if (!_isActiveSession(generation, sessionId)) return;

      _autoMarkSeenIfPossible();
      return;
    }

    if (!_isActiveSession(generation, sessionId)) return;

    _emit(
      state.copyWith(
        isLoading: false,
        clearActivity: true,
        canCancel: false,
      ),
    );
  }

  void _startLoadingWatchdog() {
    _loadingWatchdog?.cancel();

    _loadingWatchdog = Timer(const Duration(seconds: 90), () {
      if (_isDisposed) return;
      if (!_canEmit) return;

      if (state.isLoading) {
        if (kDebugMode) {
          debugPrint('Emma: watchdog unstick triggered');
        }

        unawaited(stopGenerating(reconnect: true));
      }
    });
  }

  void _stopLoadingWatchdog() {
    _loadingWatchdog?.cancel();
    _loadingWatchdog = null;
  }

  void _bumpLoadingWatchdog() {
    if (!_canEmit) return;
    if (!state.isLoading) return;

    _startLoadingWatchdog();
  }

  void _setActivity({
    String? title,
    String? detail,
  }) {
    if (!_canEmit) return;

    final normalizedTitle = _safeText(title).trim();
    final normalizedDetail = _safeText(detail).trim();

    if (normalizedTitle.isEmpty && normalizedDetail.isEmpty) return;

    _emit(
      state.copyWith(
        activityTitle: normalizedTitle.isEmpty ? null : normalizedTitle,
        activityDetail: normalizedDetail.isEmpty ? null : normalizedDetail,
      ),
    );
  }

  void _handleActivityStatus(Map<String, dynamic> data) {
    final title = _safeText(data['title'] ?? data['status_title']);
    final detail = _safeText(data['detail'] ?? data['status_detail']);

    _setActivity(title: title, detail: detail);
  }

  Future<void> _fetchInitialPage(
    int sessionId, {
    int? generation,
  }) async {
    if (sessionId <= 0) return;
    if (generation != null && !_isActiveSession(generation, sessionId)) return;

    try {
      _isFetchingHistory = true;

      final page1 = await _fetchMessagesPage(sessionId: sessionId, page: 1);

      if (generation != null && !_isActiveSession(generation, sessionId)) {
        return;
      }

      final messagesAsc = List<ChatMessageDto>.from(page1.messages)
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      final merged = _mergeMessagesKeepingLocal(
        current: state.messages,
        incoming: messagesAsc,
      );

      _emit(
        state.copyWith(
          messages: merged,
          isLoading: false,
          clearActivity: true,
          canCancel: false,
        ),
      );

      await _persistMessagesLocal(messagesAsc, syncStatus: 'synced');

      if (generation != null && !_isActiveSession(generation, sessionId)) {
        return;
      }

      _page = 1;
      _hasMore = page1.hasNext;
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('Emma: error fetching initial messages: $e\n$stack');
      }

      if (generation != null && !_isActiveSession(generation, sessionId)) {
        return;
      }

      _emit(
        state.copyWith(
          isLoading: false,
          clearActivity: true,
          canCancel: false,
        ),
      );
    } finally {
      if (generation == null || _isActiveSession(generation, sessionId)) {
        _isFetchingHistory = false;
      }
    }
  }

  Future<void> loadOlderMessages() async {
    final sessionId = _currentSessionId;
    if (sessionId == null || sessionId <= 0) return;
    if (_isFetchingHistory) return;
    if (!_hasMore) return;

    _isFetchingHistory = true;

    try {
      final nextPage = (_page <= 0) ? 1 : (_page + 1);

      final res = await _fetchMessagesPage(
        sessionId: sessionId,
        page: nextPage,
      );

      if (!_canEmit) return;
      if (_currentSessionId != sessionId) return;

      if (res.messages.isEmpty) {
        _hasMore = false;
        return;
      }

      final mergedList = _mergeMessagesKeepingLocal(
        current: state.messages,
        incoming: res.messages,
      );

      _emit(state.copyWith(messages: mergedList));

      await _persistMessagesLocal(res.messages, syncStatus: 'synced');

      if (!_canEmit) return;
      if (_currentSessionId != sessionId) return;

      _page = nextPage;
      _hasMore = res.hasNext;
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('Emma: loadOlderMessages error: $e\n$stack');
      }
    } finally {
      if (_currentSessionId == sessionId) {
        _isFetchingHistory = false;
      }
    }
  }

  String _withQuery(String baseUrl, Map<String, String> params) {
    if (params.isEmpty) return baseUrl;

    final hasQuery = baseUrl.contains('?');
    final sb = StringBuffer(baseUrl);
    sb.write(hasQuery ? '&' : '?');
    sb.write(
      params.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&'),
    );

    return sb.toString();
  }

  _MessagesPageResult _parsePageResponse(Map<String, dynamic> decoded) {
    final list = MessageListResponse.fromJson(decoded);
    final messages = List<ChatMessageDto>.from(list.results);

    final sanitizedMessages = messages.map((m) {
      return m.copyWith(content: _safeText(m.content));
    }).toList();

    final nextRaw = decoded['next'];
    final hasNext = nextRaw != null && nextRaw.toString().trim().isNotEmpty;

    return _MessagesPageResult(messages: sanitizedMessages, hasNext: hasNext);
  }

  Future<_MessagesPageResult> _fetchMessagesPage({
    required int sessionId,
    required int page,
  }) async {
    if (sessionId <= 0) {
      return const _MessagesPageResult(messages: [], hasNext: false);
    }

    final base = URLsEmma.emmaMessagesId(sessionId.toString());

    final url = _withQuery(base, {
      'page': page.toString(),
      'page_size': _pageSize.toString(),
    });

    final response = await ApiServices.get(url, hasToken: true, ref: ref);

    if (response != null && response.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(response.data));

      if (decoded is Map<String, dynamic>) return _parsePageResponse(decoded);
      if (decoded is Map) {
        return _parsePageResponse(Map<String, dynamic>.from(decoded));
      }
    }

    if (kDebugMode) {
      debugPrint(
        'Emma: Get message page failed: ${response?.statusCode} ${response?.data}',
      );
    }

    return const _MessagesPageResult(messages: [], hasNext: false);
  }

  Future<void> refreshLatestMessages() async {
    final sessionId = _currentSessionId;
    if (sessionId == null || sessionId <= 0) return;

    try {
      final existingIds =
          state.messages.where((m) => m.id > 0).map((m) => m.id).toSet();

      final page1 = await _fetchMessagesPage(sessionId: sessionId, page: 1);

      if (!_canEmit) return;
      if (_currentSessionId != sessionId) return;
      if (page1.messages.isEmpty) return;

      final mergedList = _mergeMessagesKeepingLocal(
        current: state.messages,
        incoming: page1.messages,
      );

      _emit(
        state.copyWith(
          messages: mergedList,
          isLoading: false,
          clearThinking: true,
          clearActivity: true,
          canCancel: false,
        ),
      );

      await _persistMessagesLocal(page1.messages, syncStatus: 'synced');

      if (!_canEmit) return;
      if (_currentSessionId != sessionId) return;

      for (final msg in page1.messages) {
        if (msg.id > 0 && !existingIds.contains(msg.id)) {
          _handleFrontendToolsForMessage(msg);
        }
      }

      _autoMarkSeenIfPossible();
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('Emma: refreshLatestMessages error: $e\n$stack');
      }
    }
  }
}