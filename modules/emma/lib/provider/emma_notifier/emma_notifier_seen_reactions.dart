part of '../emma_notifier.dart';

/// Message reactions and assistant-message read-state handling.
extension EmmaNotifierSeenReactions on ChatAiMessagesNotifier {
  Future<void> reactMessage({
    required int messageId,
    required String value,
    String note = '',
  }) async {
    if (!_canEmit) return;
    if (messageId <= 0) return;
    if (value != 'up' && value != 'down') return;

    try {
      if (_channel != null && _isConnected) {
        _channel!.sink.add(
          jsonEncode({
            'action': 'react_message',
            'message_id': messageId,
            'value': value,
            'note': note,
          }),
        );
        return;
      }

      final sessionId = _currentSessionId;
      if (sessionId != null && sessionId > 0) {
        await _reconnectWsOnly(sessionId);

        if (!_canEmit) return;
        if (_currentSessionId != sessionId) return;

        await waitForWsReady(timeout: const Duration(seconds: 4));

        if (!_canEmit) return;
        if (_currentSessionId != sessionId) return;

        _channel?.sink.add(
          jsonEncode({
            'action': 'react_message',
            'message_id': messageId,
            'value': value,
            'note': note,
          }),
        );
      }
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('Emma: reactMessage error: $e\n$stack');
      }
    }
  }

  void _applySeenUpToFromWs(Map<String, dynamic> data) {
    if (!_canEmit) return;

    final seenUpTo =
        _asInt(data['seen_up_to_message_id']) ?? _asInt(data['last_seen_id']);

    if (seenUpTo == null || seenUpTo <= 0) return;

    _applyLocalSeenUpTo(seenUpTo);
  }

  Future<void> markSeenUpTo(int lastSeenId) async {
    if (!_canEmit) return;

    final sessionId = _currentSessionId;
    if (sessionId == null || sessionId <= 0) return;
    if (lastSeenId <= 0) return;
    if (lastSeenId <= _seenSentUpToId) return;

    _seenSentUpToId = lastSeenId;
    _applyLocalSeenUpTo(lastSeenId);

    try {
      if (_channel != null && _isConnected) {
        _channel!.sink.add(
          jsonEncode({
            'action': 'mark_seen',
            'up_to_message_id': lastSeenId,
          }),
        );
        return;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Emma: markSeen WS error: $e');
      }
    }

    try {
      await ApiServices.post(
        URLsEmma.emmaMessagesSeen,
        hasToken: true,
        ref: ref,
        data: {
          'session': sessionId,
          'up_to_message_id': lastSeenId,
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Emma: markSeen REST error: $e');
      }
    }
  }

  void _applyLocalSeenUpTo(int lastSeenId) {
    if (!_canEmit) return;
    if (lastSeenId <= 0) return;

    final now = DateTime.now();
    var changed = false;
    final changedMessages = <ChatMessageDto>[];

    final updated = state.messages.map((m) {
      if (!m.isUser && m.id > 0 && m.id <= lastSeenId && !m.isSeen) {
        changed = true;

        final updatedMessage = m.copyWith(
          isSeen: true,
          seenAt: now,
        );

        changedMessages.add(updatedMessage);
        return updatedMessage;
      }

      return m;
    }).toList();

    if (!changed) return;
    if (!_canEmit) return;

    _emit(
      state.copyWith(
        messages: updated,
      ),
    );

    for (final msg in changedMessages) {
      unawaited(_persistMessageLocal(msg));
    }
  }

  Future<bool> retractMessage(int messageId) async {
    if (!_canEmit) return false;
    if (messageId <= 0) return false;

    try {
      final url = '${URLsEmma.baseUrl}chat/messages/$messageId/retract/';
      final response = await ApiServices.post(
        url,
        hasToken: true,
        ref: ref,
        data: {},
      );

      if (response != null && response.statusCode == 200) {
        final updated = state.messages
            .where((m) => m.id != messageId)
            .toList();
        if (!_canEmit) return false;
        _emit(state.copyWith(messages: updated));
        return true;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Emma: retractMessage error: $e');
      }
    }
    return false;
  }

  void _autoMarkSeenIfPossible() {
    if (!_canEmit) return;

    final assistantMessages =
        state.messages.where((m) => !m.isUser && m.id > 0).toList();

    if (assistantMessages.isEmpty) return;

    assistantMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final lastNonUser = assistantMessages.last;

    unawaited(markSeenUpTo(lastNonUser.id));
  }
}