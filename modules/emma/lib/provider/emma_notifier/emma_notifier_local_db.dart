part of '../emma_notifier.dart';

/// Local persistence and opportunistic offline synchronization.
///
/// Local DB is used to keep chats visible during reconnects, app restarts and
/// temporary offline usage. It is disabled on web.
extension EmmaNotifierLocalDb on ChatAiMessagesNotifier {
  bool get _canUseLocalDb => !kIsWeb;

  String _sessionClientUuidForId(int sessionId) {
    if (sessionId < 0) {
      return EmmaLocalIds.sessionUuid(sessionId);
    }

    return 'server_session_$sessionId';
  }

  String _messageClientUuidForMessage(
    ChatMessageDto msg, {
    String? explicitClientUuid,
  }) {
    final explicit = (explicitClientUuid ?? '').trim();
    if (explicit.isNotEmpty) return explicit;

    final metaClientUuid = (msg.meta['client_uuid'] ??
            msg.meta['client_message_id'] ??
            msg.meta['message_uuid'] ??
            '')
        .toString()
        .trim();

    if (metaClientUuid.isNotEmpty) return metaClientUuid;

    if (msg.id < 0) {
      return EmmaLocalIds.messageUuid(msg.id);
    }

    return 'server_message_${msg.id}';
  }

  String _syncStatusForMessage(ChatMessageDto msg, String? override) {
    final explicit = (override ?? '').trim();
    if (explicit.isNotEmpty) return explicit;

    final metaSyncStatus = (msg.meta['sync_status'] ?? '').toString().trim();
    if (metaSyncStatus.isNotEmpty) return metaSyncStatus;

    if (msg.id < 0) return 'pending_create';
    if (msg.sessionId < 0) return 'pending_create';
    if (msg.meta['local_only'] == true) return 'pending_create';

    return 'synced';
  }

  Future<void> _ensureLocalSessionRow(int sessionId) async {
    if (!_canUseLocalDb) return;
    if (sessionId == 0) return;

    try {
      final localDb = EmmaLocalDb.instance;
      final rooms = await localDb.getRooms();

      final exists = rooms.any((room) => room.id == sessionId);
      if (exists) return;

      final now = DateTime.now().toIso8601String();
      final clientUuid = _sessionClientUuidForId(sessionId);

      final room = ChatRoom.fromJson({
        'id': sessionId,
        'client_uuid': clientUuid,
        'title': 'New chat',
        'created_at': now,
        'last_activity_at': now,
        'meta': {
          if (sessionId < 0) 'local_only': true,
          if (sessionId < 0) 'sync_status': 'pending_create',
        },
      });

      await localDb.upsertRoom(
        room,
        clientUuid: clientUuid,
        syncStatus: sessionId < 0 ? 'pending_create' : 'synced',
      );
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('Emma: ensure local session row failed: $e\n$stack');
      }
    }
  }

  Future<void> _loadLocalMessagesForSession(
    int sessionId, {
    int? generation,
  }) async {
    if (!_canUseLocalDb) return;
    if (sessionId == 0) return;

    try {
      final localMessages =
          await EmmaLocalDb.instance.getMessagesForSession(sessionId);

      if (!_canEmit) return;

      if (generation != null) {
        if (!_isActiveSession(generation, sessionId)) return;
      } else {
        if (_currentSessionId != sessionId) return;
      }

      if (localMessages.isEmpty) return;

      final messagesAsc = List<ChatMessageDto>.from(localMessages)
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      _emit(
        state.copyWith(
          messages: messagesAsc,
          isLoading: false,
          clearActivity: true,
          canCancel: false,
        ),
      );
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('Emma: local messages load error: $e\n$stack');
      }
    }
  }

  Future<void> _persistMessageLocal(
    ChatMessageDto msg, {
    String? explicitClientUuid,
    String? syncStatus,
  }) async {
    if (!_canUseLocalDb) return;
    if (msg.id == 0) return;

    final sessionId = msg.sessionId != 0 ? msg.sessionId : _currentSessionId;
    if (sessionId == null || sessionId == 0) return;

    try {
      await _ensureLocalSessionRow(sessionId);

      final clientUuid = _messageClientUuidForMessage(
        msg,
        explicitClientUuid: explicitClientUuid,
      );

      final sessionClientUuid = _sessionClientUuidForId(sessionId);
      final messageWithSession = msg.copyWith(sessionId: sessionId);

      await EmmaLocalDb.instance.upsertMessage(
        messageWithSession,
        clientUuid: clientUuid,
        sessionLocalId: sessionId,
        sessionClientUuid: sessionClientUuid,
        syncStatus: _syncStatusForMessage(
          messageWithSession,
          syncStatus,
        ),
      );
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('Emma: persist local message failed: $e\n$stack');
      }
    }
  }

  Future<void> _persistMessagesLocal(
    List<ChatMessageDto> messages, {
    String? syncStatus,
  }) async {
    if (!_canUseLocalDb) return;
    if (messages.isEmpty) return;

    for (final msg in messages) {
      await _persistMessageLocal(
        msg,
        syncStatus: syncStatus,
      );
    }
  }

  Future<void> _trySyncNow({
    bool reloadCurrentSessionFromLocal = false,
  }) async {
    if (!_canUseLocalDb) return;

    try {
      final hasInternet = await _hasInternetRightNowFast();
      if (!hasInternet) return;

      await ref.read(emmaSyncServiceProvider).syncNow();

      if (reloadCurrentSessionFromLocal) {
        final sessionId = _currentSessionId;

        if (sessionId != null && sessionId != 0 && !state.isLoading) {
          await _loadLocalMessagesForSession(sessionId);
        }
      }
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('Emma: opportunistic sync failed: $e\n$stack');
      }
    }
  }
}