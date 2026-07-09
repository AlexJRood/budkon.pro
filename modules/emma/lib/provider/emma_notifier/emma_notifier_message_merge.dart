part of '../emma_notifier.dart';

/// Message merging, streaming deltas, assistant placeholders and metadata.
///
/// This is the most sensitive part of the notifier. It merges optimistic local
/// messages, backend-confirmed messages, WebSocket updates and local-engine
/// streaming output without duplicating user messages.
extension EmmaNotifierMessageMerge on ChatAiMessagesNotifier {
  List<ChatMessageDto> _mergeMessagesKeepingLocal({
    required List<ChatMessageDto> current,
    required List<ChatMessageDto> incoming,
  }) {
    final updated = List<ChatMessageDto>.from(current);

    for (final rawIncoming in incoming) {
      final incoming =
          rawIncoming.copyWith(content: _safeText(rawIncoming.content));

      if (incoming.isUser) {
        final optimisticIndex = _findOptimisticUserIndexForIncoming(
          updated,
          incoming,
        );

        if (optimisticIndex != -1) {
          updated[optimisticIndex] = incoming;
          continue;
        }
      }

      final sameIdIndex = updated.indexWhere(
        (m) => m.id == incoming.id && incoming.id != 0,
      );

      if (sameIdIndex != -1) {
        updated[sameIdIndex] = incoming;
      } else {
        updated.add(incoming);
      }
    }

    updated.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return updated;
  }

  bool _assistantMessageFinished(ChatMessageDto msg) {
    if (msg.isUser) return false;

    final streamState = (msg.meta['stream_state'] ?? '').toString();
    final streaming = msg.meta['streaming'] == true;

    if (streaming) return false;

    if (streamState == 'started' ||
        streamState == 'streaming' ||
        streamState == 'waiting_local_engine') {
      return false;
    }

    if (streamState == 'finished' ||
        streamState == 'error' ||
        streamState == 'finished_without_done_event') {
      return true;
    }

    return msg.content.trim().isNotEmpty;
  }

  Map<String, dynamic> _mergeMeta(
    Map<String, dynamic> oldMeta,
    Map<String, dynamic> newMeta,
  ) {
    final merged = <String, dynamic>{
      ...oldMeta,
      ...newMeta,
    };

    final oldBlocks = _extractBlocks(oldMeta['blocks']);
    final newBlocks = _extractBlocks(newMeta['blocks']);

    if (oldBlocks.isNotEmpty || newBlocks.isNotEmpty) {
      merged['blocks'] = _mergeBlocksById(oldBlocks, newBlocks);
    }

    return merged;
  }

  List<Map<String, dynamic>> _extractBlocks(dynamic raw) {
    if (raw is! List) return <Map<String, dynamic>>[];

    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  List<Map<String, dynamic>> _mergeBlocksById(
    List<Map<String, dynamic>> oldBlocks,
    List<Map<String, dynamic>> newBlocks,
  ) {
    final out = <Map<String, dynamic>>[];

    for (final block in oldBlocks) {
      final blockId = (block['block_id'] ?? block['id'] ?? '').toString();
      if (blockId.isNotEmpty && _finishedBlockIds.contains(blockId)) {
        continue;
      }

      out.add(Map<String, dynamic>.from(block));
    }

    for (final block in newBlocks) {
      final normalized = Map<String, dynamic>.from(block);
      final blockId =
          (normalized['block_id'] ?? normalized['id'] ?? '').toString();

      // Wygenerowany obraz ZASTĘPUJE kafelek ładowania generacji w tym samym
      // miejscu (przejmuje jego block_id), zamiast dokładać się jako osobny blok
      // i zostawiać wiszący shimmer. Dzięki temu shimmer płynnie „staje się"
      // obrazem (blok obrazu ma własną animację reveal).
      if (_isGeneratedImageBlock(normalized)) {
        final loadingIdx = out.indexWhere(_isImageLoadingBlock);
        if (loadingIdx != -1) {
          final reuseId =
              (out[loadingIdx]['block_id'] ?? out[loadingIdx]['id'] ?? '')
                  .toString();
          if (reuseId.isNotEmpty) {
            normalized['block_id'] = reuseId;
          }
          out[loadingIdx] = normalized;
          continue;
        }
      }

      if (blockId.isEmpty) {
        out.add(normalized);
        continue;
      }

      final idx = out.indexWhere((b) {
        final id = (b['block_id'] ?? b['id'] ?? '').toString();
        return id == blockId;
      });

      if (idx == -1) {
        out.add(normalized);
      } else {
        out[idx] = {
          ...out[idx],
          ...normalized,
        };
      }
    }

    return out;
  }

  /// Czy blok to gotowy wygenerowany obraz (nie placeholder ładowania).
  bool _isGeneratedImageBlock(Map<String, dynamic> b) {
    final type = (b['type'] ?? b['block_type'] ?? '').toString().toLowerCase();
    if (type == 'generated_image') return true;
    if (type == 'image') {
      final url = (b['url'] ?? b['image_url'] ?? '').toString();
      return url.trim().isNotEmpty ||
          b['cloud_file_id'] != null ||
          b['saved_to_cloud'] != null;
    }
    return false;
  }

  /// Czy blok to kafelek ładowania generacji obrazu (shimmer).
  bool _isImageLoadingBlock(Map<String, dynamic> b) {
    final type = (b['type'] ?? '').toString().toLowerCase();
    if (type != 'loading') return false;
    final bt = (b['block_type'] ?? '').toString().toLowerCase();
    return bt.contains('generate_image');
  }

  void _upsertMessage(ChatMessageDto rawMsg) {
    if (!rawMsg.isVisible) {
      final updated =
          state.messages.where((m) => m.id != rawMsg.id).toList();
      if (updated.length != state.messages.length && _canEmit) {
        _emit(state.copyWith(messages: updated));
      }
      return;
    }
    final msg = _coerceSuspiciousUserMessageIfNeeded(rawMsg);
    final updated = List<ChatMessageDto>.from(state.messages);
    ChatMessageDto? messageToPersist;

    if (msg.role == 'user') {
      final optimisticIndex = _findOptimisticUserIndexForIncoming(updated, msg);

      if (optimisticIndex != -1) {
        updated[optimisticIndex] = msg;
        messageToPersist = msg;
      } else {
        final existingIndex =
            updated.indexWhere((m) => m.id == msg.id && msg.id > 0);

        if (existingIndex != -1) {
          updated[existingIndex] = msg;
          messageToPersist = msg;
        } else {
          updated.add(msg);
          messageToPersist = msg;
        }
      }
    } else {
      final idx = updated.indexWhere((m) => m.id == msg.id && msg.id != 0);

      if (idx != -1) {
        final current = updated[idx];

        if (current.isUser) {
          final reroutedId = _assistantIdForMisroutedUserTarget(current.id);

          final rerouted = msg.copyWith(
            id: reroutedId,
            role: 'assistant',
            content: _safeText(msg.content),
            meta: {
              ...msg.meta,
              'rerouted_from_user_message_id': current.id,
            },
          );

          updated.add(rerouted);
          messageToPersist = rerouted;
        } else {
          final incomingContent = _safeText(msg.content);
          final shouldKeepCurrentContent =
              incomingContent.trim().isEmpty &&
                  current.content.trim().isNotEmpty;

          final mergedMessage = msg.copyWith(
            content:
                shouldKeepCurrentContent ? current.content : incomingContent,
            meta: _mergeMeta(current.meta, msg.meta),
            likesCount: msg.likesCount,
            dislikesCount: msg.dislikesCount,
            isSeen: msg.isSeen,
            seenAt: msg.seenAt,
          );

          updated[idx] = mergedMessage;
          messageToPersist = mergedMessage;
        }
      } else {
        final inserted = msg.copyWith(content: _safeText(msg.content));
        updated.add(inserted);
        messageToPersist = inserted;
      }
    }

    updated.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final isAssistant = msg.role == 'assistant';
    final assistantFinished = isAssistant && _assistantMessageFinished(msg);

    state = state.copyWith(
      messages: updated,
      isLoading: assistantFinished ? false : state.isLoading,
      canCancel: assistantFinished ? false : state.canCancel,
      clearThinking: assistantFinished,
      clearActivity: assistantFinished,
    );

    if (messageToPersist != null) {
      unawaited(
        _persistMessageLocal(
          messageToPersist,
          explicitClientUuid:
              (messageToPersist.meta['client_message_id'] ??
                      messageToPersist.meta['client_uuid'] ??
                      '')
                  .toString(),
          syncStatus: messageToPersist.id > 0 ? 'synced' : null,
        ),
      );
    }

    if (assistantFinished) {
      _stopLoadingWatchdog();
      _handleFrontendToolsForMessage(msg);
    }
  }

  void _applyAiDelta(Map<String, dynamic> data) {
    final messageId = _resolveSafeAssistantDeltaMessageId(data);
    final delta = _safeText(data['delta']);

    if (!_isValidMessageIdForLocal(messageId) || delta.isEmpty) return;

    final sessionId = _asInt(data['session_id']) ?? (_currentSessionId ?? 0);

    final updated = List<ChatMessageDto>.from(state.messages);
    final idx = updated.indexWhere((m) => m.id == messageId);

    final rawMessageId = _asInt(data['message_id']);
    final wasRerouted = rawMessageId != null && rawMessageId != messageId;

    if (idx == -1) {
      updated.add(
        ChatMessageDto(
          id: messageId!,
          sessionId: sessionId,
          role: 'assistant',
          kind: 'text',
          content: delta,
          createdAt: DateTime.now(),
          likesCount: 0,
          dislikesCount: 0,
          meta: {
            'streaming': true,
            'stream_state': 'streaming',
            if (wasRerouted) 'rerouted_from_user_message_id': rawMessageId,
          },
          isSeen: false,
          seenAt: null,
        ),
      );
    } else {
      final current = updated[idx];

      if (current.isUser) {
        final safeAssistantId = _assistantIdForMisroutedUserTarget(current.id);

        updated.add(
          ChatMessageDto(
            id: safeAssistantId,
            sessionId: sessionId,
            role: 'assistant',
            kind: 'text',
            content: delta,
            createdAt: DateTime.now(),
            likesCount: 0,
            dislikesCount: 0,
            meta: {
              'streaming': true,
              'stream_state': 'streaming',
              'rerouted_from_user_message_id': current.id,
            },
            isSeen: false,
            seenAt: null,
          ),
        );
      } else {
        updated[idx] = current.copyWith(
          content: _sanitizeFlutterText('${current.content}$delta'),
          meta: {
            ...current.meta,
            'streaming': true,
            'stream_state': 'streaming',
            if (wasRerouted) 'rerouted_from_user_message_id': rawMessageId,
          },
        );
      }
    }

    updated.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    state = state.copyWith(
      messages: updated,
      isLoading: true,
      canCancel: true,
    );

    _startLoadingWatchdog();
  }

  int? _latestAssistantMessageId({bool preferStreaming = true}) {
    final assistants = state.messages.where((m) => !m.isUser && m.id != 0).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (assistants.isEmpty) return null;

    if (preferStreaming) {
      for (final msg in assistants) {
        final streamState = (msg.meta['stream_state'] ?? '').toString();
        final streaming = msg.meta['streaming'] == true;

        if (streaming ||
            streamState == 'started' ||
            streamState == 'streaming' ||
            streamState == 'waiting_local_engine') {
          return msg.id;
        }
      }
    }

    return assistants.first.id;
  }

  int? _resolveAssistantMessageId(Map<String, dynamic> data) {
    return _asInt(data['assistant_message_id']) ??
        _asInt(data['message_id']) ??
        _latestAssistantMessageId();
  }

  void _ensureAssistantPlaceholder({
    required int messageId,
    required int sessionId,
    Map<String, dynamic> meta = const {},
  }) {
    if (!_isValidMessageIdForLocal(messageId)) return;

    final safeMessageId = _safeAssistantMessageIdFromAny(
      candidate: messageId,
      fallbackAssistantMessageId: _pendingTurnAssistantId ?? messageId,
    );

    final updated = List<ChatMessageDto>.from(state.messages);
    final idx = updated.indexWhere((m) => m.id == safeMessageId);

    final mergedMeta = <String, dynamic>{
      'streaming': true,
      'stream_state': 'streaming',
      ...meta,
      if (safeMessageId != messageId) 'rerouted_from_user_message_id': messageId,
    };

    ChatMessageDto? placeholderToPersist;

    if (idx == -1) {
      final placeholder = ChatMessageDto(
        id: safeMessageId,
        sessionId: sessionId,
        role: 'assistant',
        kind: 'text',
        content: '',
        createdAt: DateTime.now(),
        likesCount: 0,
        dislikesCount: 0,
        meta: mergedMeta,
        isSeen: false,
        seenAt: null,
      );

      updated.add(placeholder);
      placeholderToPersist = placeholder;
    } else {
      final current = updated[idx];

      if (current.isUser) {
        final reroutedId = _assistantIdForMisroutedUserTarget(current.id);

        final placeholder = ChatMessageDto(
          id: reroutedId,
          sessionId: sessionId,
          role: 'assistant',
          kind: 'text',
          content: '',
          createdAt: DateTime.now(),
          likesCount: 0,
          dislikesCount: 0,
          meta: {
            ...mergedMeta,
            'rerouted_from_user_message_id': current.id,
          },
          isSeen: false,
          seenAt: null,
        );

        updated.add(placeholder);
        placeholderToPersist = placeholder;
      } else {
        final merged = current.copyWith(
          meta: _mergeMeta(
            current.meta,
            mergedMeta,
          ),
        );

        updated[idx] = merged;
        placeholderToPersist = merged;
      }
    }

    updated.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    state = state.copyWith(
      messages: updated,
      isLoading: true,
      canCancel: true,
    );

    if (placeholderToPersist != null) {
      unawaited(_persistMessageLocal(placeholderToPersist));
    }

    _startLoadingWatchdog();
  }

  void _replaceAssistantContent({
    required int messageId,
    required String content,
    Map<String, dynamic> meta = const {},
    bool finished = true,
  }) {
    if (!_isValidMessageIdForLocal(messageId)) return;

    final safeMessageId = _safeAssistantMessageIdFromAny(
      candidate: messageId,
      fallbackAssistantMessageId: _pendingTurnAssistantId ?? messageId,
    );

    final safeContent = _safeText(content);

    final updated = List<ChatMessageDto>.from(state.messages);
    final idx = updated.indexWhere((m) => m.id == safeMessageId);

    final mergedMeta = <String, dynamic>{
      'streaming': !finished,
      'stream_state': finished ? 'finished' : 'streaming',
      ...meta,
      if (safeMessageId != messageId) 'rerouted_from_user_message_id': messageId,
    };

    ChatMessageDto finalMsg;

    if (idx == -1) {
      finalMsg = ChatMessageDto(
        id: safeMessageId,
        sessionId: _currentSessionId ?? 0,
        role: 'assistant',
        kind: 'text',
        content: safeContent,
        createdAt: DateTime.now(),
        likesCount: 0,
        dislikesCount: 0,
        meta: mergedMeta,
        isSeen: false,
        seenAt: null,
      );

      updated.add(finalMsg);
    } else {
      final current = updated[idx];

      if (current.isUser) {
        final reroutedId = _assistantIdForMisroutedUserTarget(current.id);

        finalMsg = ChatMessageDto(
          id: reroutedId,
          sessionId: current.sessionId,
          role: 'assistant',
          kind: 'text',
          content: safeContent,
          createdAt: DateTime.now(),
          likesCount: 0,
          dislikesCount: 0,
          meta: {
            ...mergedMeta,
            'rerouted_from_user_message_id': current.id,
          },
          isSeen: false,
          seenAt: null,
        );

        updated.add(finalMsg);
      } else {
        finalMsg = current.copyWith(
          content: safeContent,
          meta: _mergeMeta(
            current.meta,
            mergedMeta,
          ),
        );

        updated[idx] = finalMsg;
      }
    }

    updated.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    state = state.copyWith(
      messages: updated,
      isLoading: !finished,
      canCancel: !finished,
      clearActivity: finished,
      clearThinking: finished,
    );

    unawaited(
      _persistMessageLocal(
        finalMsg,
        syncStatus: finalMsg.id > 0 && finalMsg.meta['local_only'] != true
            ? 'synced'
            : 'pending_create',
      ),
    );

    if (finished) {
      _stopLoadingWatchdog();
      _autoMarkSeenIfPossible();
      _handleFrontendToolsForMessage(finalMsg);
    }
  }

  void _mergeAssistantMeta({
    required int messageId,
    required Map<String, dynamic> meta,
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

    final merged = current.copyWith(
      meta: _mergeMeta(current.meta, meta),
    );

    updated[idx] = merged;

    state = state.copyWith(messages: updated);

    unawaited(_persistMessageLocal(merged));
  }

  void _upsertAssistantBlock({
    required int messageId,
    required Map<String, dynamic> block,
    bool keepLoading = true,
  }) {
    if (!_isValidMessageIdForLocal(messageId)) return;

    final sessionId = _currentSessionId ?? 0;

    final safeMessageId = _safeAssistantMessageIdFromAny(
      candidate: messageId,
      fallbackAssistantMessageId: _pendingTurnAssistantId ?? messageId,
    );

    _ensureAssistantPlaceholder(
      messageId: safeMessageId,
      sessionId: sessionId,
      meta: {
        'streaming': true,
        'stream_state': 'streaming',
        if (safeMessageId != messageId)
          'rerouted_from_user_message_id': messageId,
      },
    );

    final updated = List<ChatMessageDto>.from(state.messages);
    final idx = updated.indexWhere((m) => m.id == safeMessageId);

    if (idx == -1) return;

    final current = updated[idx];
    if (current.isUser) return;

    final meta = Map<String, dynamic>.from(current.meta);
    final oldBlocks = _extractBlocks(meta['blocks']);

    final normalizedBlock = Map<String, dynamic>.from(block);
    final blockId =
        (normalizedBlock['block_id'] ?? normalizedBlock['id'] ?? '').toString();

    List<Map<String, dynamic>> blocks;

    if (blockId.isEmpty) {
      blocks = [...oldBlocks, normalizedBlock];
    } else {
      blocks = _mergeBlocksById(oldBlocks, [normalizedBlock]);
    }

    meta['blocks'] = blocks;
    meta['streaming'] = keepLoading;
    meta['stream_state'] = keepLoading ? 'streaming' : 'finished';

    final merged = current.copyWith(meta: meta);
    updated[idx] = merged;

    state = state.copyWith(
      messages: updated,
      isLoading: keepLoading,
      canCancel: keepLoading,
    );

    unawaited(_persistMessageLocal(merged));

    if (keepLoading) {
      _startLoadingWatchdog();
    }
  }

  void _removeAssistantBlock({
    required int messageId,
    required String blockId,
  }) {
    if (!_isValidMessageIdForLocal(messageId) || blockId.trim().isEmpty) {
      return;
    }

    final safeMessageId = _safeAssistantMessageIdFromAny(
      candidate: messageId,
      fallbackAssistantMessageId: _pendingTurnAssistantId ?? messageId,
    );

    _finishedBlockIds.add(blockId);

    final updated = List<ChatMessageDto>.from(state.messages);
    final idx = updated.indexWhere((m) => m.id == safeMessageId);

    if (idx == -1) return;

    final current = updated[idx];
    if (current.isUser) return;

    final meta = Map<String, dynamic>.from(current.meta);
    final blocks = _extractBlocks(meta['blocks'])
        .where((b) => (b['block_id'] ?? b['id'] ?? '').toString() != blockId)
        .toList();

    if (blocks.isEmpty) {
      meta.remove('blocks');
    } else {
      meta['blocks'] = blocks;
    }

    final merged = current.copyWith(meta: meta);
    updated[idx] = merged;
    state = state.copyWith(messages: updated);

    unawaited(_persistMessageLocal(merged));
  }

  ChatMessageDto _dtoFromWsMessage(Map<String, dynamic> data) {
    final metaRaw = data['meta'];
    final meta =
        metaRaw is Map ? Map<String, dynamic>.from(metaRaw) : <String, dynamic>{};

    final seenAtRaw = data['seen_at'];
    DateTime? seenAt;

    if (seenAtRaw is String) {
      seenAt = DateTime.tryParse(seenAtRaw);
    }

    return ChatMessageDto(
      id: _asInt(data['message_id']) ?? 0,
      sessionId: _asInt(data['session_id']) ?? (_currentSessionId ?? 0),
      role: (data['role'] as String?) ?? 'assistant',
      kind: (data['kind'] as String?) ?? 'text',
      content: _safeText(data['content']),
      createdAt: _parseDateTimeSafe(data['created_at']),
      likesCount: _asInt(data['likes_count']) ?? 0,
      dislikesCount: _asInt(data['dislikes_count']) ?? 0,
      meta: meta,
      isSeen: (data['is_seen'] as bool?) ?? false,
      seenAt: seenAt,
    );
  }
}
