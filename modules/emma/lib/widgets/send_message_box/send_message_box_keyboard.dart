part of '../send_message_box.dart';

extension _SendMessageBoxKeyboard on _SendMessageBoxState {
  bool _handleHardwareKeyEvent(KeyEvent event) {
    if (!_alive) return false;
    if (event is! KeyDownEvent) return false;

    final key = event.logicalKey;

    final isEnter =
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter;

    final isBackspace = key == LogicalKeyboardKey.backspace;
    final isEscape = key == LogicalKeyboardKey.escape;

    final hasShift = HardwareKeyboard.instance.isShiftPressed;
    final hasControl = HardwareKeyboard.instance.isControlPressed;
    final hasMeta = HardwareKeyboard.instance.isMetaPressed;
    final hasAlt = HardwareKeyboard.instance.isAltPressed;

    final hasCommandModifier = hasControl || hasMeta || hasAlt;

    if (isEscape) {
      final uiState = ref.read(sendMessageBoxUiProvider);

      if (uiState.showMentions) {
        this._hideMentions();
        this._requestFocusStable();
        return true;
      }

      unawaited(this._closeTopOverlayOrRoute());
      return true;
    }

    if (!_focusNode.hasFocus) return false;

    if (hasCommandModifier) {
      return false;
    }

    if (isEnter && hasShift) {
      return false;
    }

    if (isEnter) {
      final busy = this._isKeyboardSendBusy();
      final hasText = _controller.text.trim().isNotEmpty;

      if (!busy && hasText) {
        unawaited(this._sendCurrentMessage());
      } else {
        this._requestFocusStable();
      }

      return true;
    }

    if (isBackspace) {
      return this._handleBackspaceOnMention();
    }

    return false;
  }

  Future<void> _closeTopOverlayOrRoute() async {
    if (!_alive) return;

    try {
      final localNavigator = Navigator.of(context);

      if (localNavigator.canPop()) {
        await localNavigator.maybePop();
        return;
      }

      if (!_alive) return;

      final rootNavigator = Navigator.of(context, rootNavigator: true);

      if (rootNavigator.canPop()) {
        await rootNavigator.maybePop();
        return;
      }
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('Emma: Escape close overlay failed: $e\n$stack');
      }
    }
  }

  bool _isKeyboardSendBusy() {
    if (!_alive) return true;

    final uiState = ref.read(sendMessageBoxUiProvider);
    final boot = ref.read(emmaChatBootstrappingProvider);

    final chatState = ref.read(chatAiMessageProvider);
    final messages = chatState.messages;
    final chatNotifier = ref.read(chatAiMessageProvider.notifier);

    final isBlockedSending =
        chatState.isLoading && messages.isNotEmpty && messages.last.isUser;

    final talkButtonActive = _continuousTalkMode ||
        _talkAfterStt ||
        _voiceTalkActive ||
        chatNotifier.isLocalTalkAudioBusy ||
        (chatState.isLoading && chatState.canCancel);

    return uiState.sendingNow || boot || isBlockedSending || talkButtonActive;
  }
}