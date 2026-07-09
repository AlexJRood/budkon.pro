part of '../emma_notifier.dart';

/// Opens an empty draft chat without creating a real cloud/local session.
///
/// A real ChatSession is created only when the user sends the first message
/// through ensureActiveSessionForSending().
extension EmmaNotifierEmptyDraft on ChatAiMessagesNotifier {
  Future<void> openEmptyDraftChat() async {
    ref.read(emmaChatBootstrappingProvider.notifier).state = false;
    ref.read(selectedAiRoomProvider.notifier).state = '';

    _localJobGeneration++;
    _activeLocalJobId = null;
    _pendingTurnAssistantId = null;
    _currentSessionId = null;

    try {
      await stopLocalTalkAudio();
    } catch (_) {}

    try {
      await _disconnectInternal();
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('Emma: empty draft disconnect failed: $e\n$stack');
      }
    }

    _stopLoadingWatchdog();

    state = state.copyWith(
      messages: const [],
      isLoading: false,
      canCancel: false,
      clearActivity: true,
      clearThinking: true,
    );

    try {
      final focusNode = ref.read(emmaChatInputFocusNodeProvider);
      focusNode.requestFocus();
    } catch (_) {}
  }
}