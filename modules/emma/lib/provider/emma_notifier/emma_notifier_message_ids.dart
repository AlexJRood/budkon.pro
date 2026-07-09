part of '../emma_notifier.dart';

/// Message ID generation, validation and misrouted assistant-event protection.
///
/// Negative IDs are used for local optimistic messages. Positive IDs are
/// backend-confirmed. This file also protects the UI from backend events that
/// accidentally target user messages with assistant output.
extension EmmaNotifierMessageIds on ChatAiMessagesNotifier {
  int _newOfflineSessionId() {
    return -DateTime.now().microsecondsSinceEpoch;
  }

  int _newOfflineAssistantMessageId() {
    _tempAssistantSeq += 1;
    return -(DateTime.now().microsecondsSinceEpoch + _tempAssistantSeq);
  }

  int _newClientAssistantMessageId() {
    _tempAssistantSeq += 1;
    return -(DateTime.now().microsecondsSinceEpoch + _tempAssistantSeq);
  }

  bool _isValidMessageIdForLocal(int? value) {
    return value != null && value != 0;
  }

  bool _messageIdBelongsToUser(int id) {
    return state.messages.any((m) => m.id == id && m.isUser);
  }

  ChatMessageDto? _messageByIdOrNull(int id) {
    for (final msg in state.messages) {
      if (msg.id == id) return msg;
    }
    return null;
  }

  int _assistantIdForMisroutedUserTarget(int userMessageId) {
    final existingPending = _pendingTurnAssistantId;

    if (existingPending != null &&
        existingPending != 0 &&
        !_messageIdBelongsToUser(existingPending)) {
      return existingPending;
    }

    return _misroutedDeltaAssistantIds.putIfAbsent(
      userMessageId,
      _newClientAssistantMessageId,
    );
  }

  int _safeAssistantMessageIdFromAny({
    required int? candidate,
    required int fallbackAssistantMessageId,
  }) {
    if (candidate != null && candidate != 0) {
      if (!_messageIdBelongsToUser(candidate)) {
        return candidate;
      }

      if (kDebugMode) {
        debugPrint(
          'Emma CRITICAL: assistant event targeted USER message_id=$candidate. '
          'Rerouting to assistant placeholder.',
        );
      }

      return _assistantIdForMisroutedUserTarget(candidate);
    }

    if (!_messageIdBelongsToUser(fallbackAssistantMessageId)) {
      return fallbackAssistantMessageId;
    }

    return _assistantIdForMisroutedUserTarget(fallbackAssistantMessageId);
  }

  int? _resolveSafeAssistantDeltaMessageId(Map<String, dynamic> data) {
    final assistantId = _asInt(data['assistant_message_id']);

    if (assistantId != null && assistantId != 0) {
      if (!_messageIdBelongsToUser(assistantId)) {
        return assistantId;
      }

      return _assistantIdForMisroutedUserTarget(assistantId);
    }

    final rawMessageId = _asInt(data['message_id']);

    if (rawMessageId == null || rawMessageId == 0) {
      return _pendingTurnAssistantId ?? _newClientAssistantMessageId();
    }

    if (!_messageIdBelongsToUser(rawMessageId)) {
      return rawMessageId;
    }

    if (kDebugMode) {
      debugPrint(
        'Emma CRITICAL: ai_delta targeted USER message_id=$rawMessageId. '
        'Rerouting delta to assistant message.',
      );
    }

    return _assistantIdForMisroutedUserTarget(rawMessageId);
  }

  int _findOptimisticUserIndexForIncoming(
    List<ChatMessageDto> messages,
    ChatMessageDto incoming,
  ) {
    final incomingClientId =
        (incoming.meta['client_message_id'] ?? '').toString().trim();

    if (incomingClientId.isNotEmpty) {
      return messages.indexWhere(
        (m) =>
            m.role == 'user' &&
            m.id < 0 &&
            (m.meta['client_message_id'] ?? '').toString().trim() ==
                incomingClientId,
      );
    }

    final incomingContent = _normalizeMessageForMatch(incoming.content);
    if (incomingContent.isEmpty) return -1;

    for (var i = messages.length - 1; i >= 0; i--) {
      final candidate = messages[i];

      if (candidate.role != 'user') continue;
      if (candidate.id >= 0) continue;
      if (candidate.sessionId != incoming.sessionId) continue;

      final candidateContent = _normalizeMessageForMatch(candidate.content);
      if (candidateContent != incomingContent) continue;

      final diff = incoming.createdAt.difference(candidate.createdAt).abs();

      if (diff <= const Duration(minutes: 5)) {
        return i;
      }
    }

    return -1;
  }

  ChatMessageDto _copyAsAssistant(
    ChatMessageDto msg, {
    int? overrideId,
    Map<String, dynamic> extraMeta = const {},
  }) {
    return ChatMessageDto(
      id: overrideId ?? msg.id,
      sessionId: msg.sessionId,
      role: 'assistant',
      kind: msg.kind,
      content: _safeText(msg.content),
      createdAt: msg.createdAt,
      likesCount: msg.likesCount,
      dislikesCount: msg.dislikesCount,
      meta: {
        ...msg.meta,
        ...extraMeta,
      },
      isSeen: msg.isSeen,
      seenAt: msg.seenAt,
    );
  }

  bool _looksLikeGeneratedUserMessage(ChatMessageDto msg) {
    if (!msg.isUser) return false;

    final content = _normalizeMessageForMatch(msg.content);
    if (content.isEmpty) return false;

    final pendingText = _normalizeMessageForMatch(_pendingTurnUserText ?? '');

    final clientId = (msg.meta['client_message_id'] ?? '').toString().trim();
    final pendingClientId = (_pendingTurnClientMessageId ?? '').trim();

    if (clientId.isNotEmpty && clientId == pendingClientId) {
      return false;
    }

    if (pendingText.isNotEmpty && content == pendingText) {
      return false;
    }

    final startedAt = _pendingTurnStartedAt;
    if (startedAt == null) return false;

    final isNearCurrentTurn =
        msg.createdAt.isAfter(startedAt.subtract(const Duration(seconds: 5)));

    if (!isNearCurrentTurn) return false;

    final hasAssistantMeta =
        msg.meta['local_engine'] != null ||
        msg.meta['streaming'] == true ||
        (msg.meta['stream_state'] ?? '').toString().trim().isNotEmpty ||
        (msg.meta['rerouted_from_user_message_id'] ?? '')
            .toString()
            .isNotEmpty ||
        (msg.meta['coerced_from_wrong_user_role'] ?? false) == true;

    if (hasAssistantMeta) return true;

    if (state.isLoading) return true;

    return false;
  }

  ChatMessageDto _coerceSuspiciousUserMessageIfNeeded(ChatMessageDto msg) {
    if (!_looksLikeGeneratedUserMessage(msg)) {
      return msg.copyWith(content: _safeText(msg.content));
    }

    final targetId = _messageIdBelongsToUser(msg.id)
        ? _assistantIdForMisroutedUserTarget(msg.id)
        : msg.id;

    if (kDebugMode) {
      debugPrint(
        'Emma CRITICAL: received generated content as role=user. '
        'Coercing message_id=${msg.id} to assistant_id=$targetId',
      );
    }

    return _copyAsAssistant(
      msg,
      overrideId: targetId,
      extraMeta: {
        'coerced_from_wrong_user_role': true,
        'original_role': 'user',
        if (targetId != msg.id) 'rerouted_from_user_message_id': msg.id,
      },
    );
  }
}
