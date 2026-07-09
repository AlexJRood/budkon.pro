part of '../emma_notifier.dart';

/// Ensures that Emma has an active chat session before the first message.
///
/// This fixes sending from EmptyChatState / center SendMessageBox where
/// no session has been selected yet.
extension EmmaNotifierSessionBootstrap on ChatAiMessagesNotifier {
  /// Diagnostic-only: why the last ensureActiveSessionForSending() call
  /// could not obtain a usable cloud session, straight from
  /// ChatAiRoomsProvider.lastCreateRoomError. Surfaced in the UI so a
  /// failure can be root-caused from a device without a debugger attached.
  String? get lastSendBootstrapError =>
      ref.read(chatAiRoomsProvider.notifier).lastCreateRoomError;

  Future<int?> ensureActiveSessionForSending({
    String title = 'New chat',
    bool waitForCloudWs = true,
  }) async {
    final currentId = _currentSessionId;

    if (currentId != null && currentId != 0) {
      return currentId;
    }

    final selectedRaw = ref.read(selectedAiRoomProvider).trim();
    final selectedId = int.tryParse(selectedRaw);

    if (selectedId != null && selectedId != 0) {
      _currentSessionId = selectedId;

      await _ensureLocalSessionRow(selectedId);

      if (selectedId > 0) {
        await _connectWs(selectedId);

        if (waitForCloudWs) {
          await _waitForWsReadySoft();
        }
      } else {
        await _loadLocalMessagesForSession(selectedId);
      }

      return selectedId;
    }

    ref.read(emmaChatBootstrappingProvider.notifier).state = true;

    try {
      final room = await ref
          .read(chatAiRoomsProvider.notifier)
          .createRoomAndReturn(title: title);

      if (room == null || room.id == 0) {
        if (kDebugMode) {
          debugPrint('Emma: cannot bootstrap session for sending.');
        }
        return null;
      }

      final sessionId = room.id;

      // createRoomAndReturn() falls back to a local-only (negative id) room
      // when the cloud POST fails (bad status, timeout, network error). If
      // we're not in local-engine mode there is nothing that can ever send
      // through that room — accepting it here would cache a dead session id
      // forever (every future send would just no-op), leaving the composer
      // permanently stuck for that "chat" even though it shows in the list.
      // Treat it as a bootstrap failure instead so the caller's normal
      // retry/draft-restore path runs.
      final canUseLocalEngine =
          !kIsWeb && ref.read(emmaRuntimeModeConfigProvider).useLocalEngine;

      if (sessionId <= 0 && !canUseLocalEngine) {
        _currentSessionId = null;

        if (kDebugMode) {
          debugPrint(
            'Emma: room creation fell back to an offline-only room while '
            'cloud mode is active; treating bootstrap as failed.',
          );
        }

        return null;
      }

      ref.read(selectedAiRoomProvider.notifier).state = sessionId.toString();

      _currentSessionId = sessionId;

      await _ensureLocalSessionRow(sessionId);

      if (sessionId > 0) {
        await _connectWs(sessionId);

        if (waitForCloudWs) {
          await _waitForWsReadySoft();
        }
      } else {
        await _loadLocalMessagesForSession(sessionId);
      }

      return sessionId;
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('Emma: session bootstrap failed: $e\n$stack');
      }

      return null;
    } finally {
      ref.read(emmaChatBootstrappingProvider.notifier).state = false;
    }
  }

  Future<void> _waitForWsReadySoft() async {
    final completer = _wsReadyCompleter;

    if (completer == null || completer.isCompleted) return;

    try {
      await completer.future.timeout(
        const Duration(seconds: 3),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Emma: WS soft wait skipped/failed: $e');
      }
    }
  }
}