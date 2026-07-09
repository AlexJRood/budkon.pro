part of '../send_message_box.dart';

extension _SendMessageBoxDrafts on _SendMessageBoxState {
  void _handleSelectedRoomChanged(String nextSelectedRoom) {
    if (_isDisposed) return;

    final previousDraftKey = _activeDraftKey;

    if (!_isSendingCurrentComposer && !_suppressDraftHydrationOnRoomChange) {
      this._saveCurrentDraftNow(key: previousDraftKey);
    }

    final nextDraftKey = EmmaChatDraftsNotifier.keyForSelectedRoom(
      nextSelectedRoom,
    );

    _activeDraftKey = nextDraftKey;

    // During first-message bootstrap we do not copy/hydrate the empty chat draft
    // into the newly created server session.
    if (_suppressDraftHydrationOnRoomChange) {
      this._clearDraftForKey(nextDraftKey);
      return;
    }

    if (_isSendingCurrentComposer) {
      return;
    }

    this._applyDraftForKey(nextDraftKey);
    this._requestFocusStable();
  }

  void _queueDraftSave() {
    if (_isDisposed) return;
    if (_isApplyingDraft || _isSendingCurrentComposer) return;

    _draftSaveDebounce?.cancel();

    _draftSaveDebounce = Timer(const Duration(milliseconds: 160), () {
      if (_isDisposed) return;
      this._saveCurrentDraftNow();
    });
  }

  void _saveDraftSnapshotLater({
    required String key,
    required String text,
  }) {
    final draftsNotifier = _draftsNotifier;

    Future<void>.delayed(Duration.zero, () {
      try {
        draftsNotifier.setDraftForKey(key, text);
      } catch (e, stack) {
        if (kDebugMode) {
          debugPrint('SendMessageBox deferred save draft failed: $e\n$stack');
        }
      }
    });
  }

  void _saveCurrentDraftNow({
    String? key,
    bool force = false,
  }) {
    if (_isApplyingDraft) return;
    if (_isSendingCurrentComposer && !force) return;

    final targetKey = key ?? _activeDraftKey;
    final text = _controller.text;

    if (_isDisposed) {
      this._saveDraftSnapshotLater(
        key: targetKey,
        text: text,
      );
      return;
    }

    try {
      _draftsNotifier.setDraftForKey(
        targetKey,
        text,
      );
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('SendMessageBox save draft failed: $e\n$stack');
      }
    }
  }

  void _clearDraftForCurrentChat() {
    _draftsNotifier.clearDraftForKey(_activeDraftKey);
  }

  void _clearDraftForKey(String key) {
    _draftsNotifier.clearDraftForKey(key);
  }

  void _applyDraftForKey(String key) {
    if (_isDisposed) return;

    final draft = _draftsNotifier.draftForKey(key);

    if (_controller.text == draft) {
      this._syncHasTypedText();
      return;
    }

    _isApplyingDraft = true;

    _controller.value = TextEditingValue(
      text: draft,
      selection: TextSelection.collapsed(offset: draft.length),
      composing: TextRange.empty,
    );

    _isApplyingDraft = false;

    this._hideMentions();
    this._syncHasTypedText();
  }

  void _clearDraftsSnapshotLater(Set<String> keys) {
    final draftsNotifier = _draftsNotifier;

    Future<void>.delayed(Duration.zero, () {
      try {
        for (final key in keys) {
          draftsNotifier.clearDraftForKey(key);
        }
      } catch (e, stack) {
        if (kDebugMode) {
          debugPrint('SendMessageBox deferred clear drafts failed: $e\n$stack');
        }
      }
    });
  }

  void _clearComposerAndDraftsAfterSuccessfulSend({
    required String draftKeyBeforeSend,
    required int sessionId,
  }) {
    if (_isDisposed) return;

    _draftSaveDebounce?.cancel();

    final selectedDraftKey = _alive
        ? EmmaChatDraftsNotifier.keyForSelectedRoom(
            ref.read(selectedAiRoomProvider),
          )
        : _activeDraftKey;

    final serverDraftKey = EmmaChatDraftsNotifier.keyForSelectedRoom(
      sessionId.toString(),
    );

    final keysToClear = <String>{
      draftKeyBeforeSend,
      _activeDraftKey,
      selectedDraftKey,
      serverDraftKey,
      EmmaChatDraftsNotifier.emptyDraftKey,
    };

    for (final key in keysToClear) {
      this._clearDraftForKey(key);
    }

    _activeDraftKey = serverDraftKey;

    _isApplyingDraft = true;
    _controller.value = const TextEditingValue(
      text: '',
      selection: TextSelection.collapsed(offset: 0),
      composing: TextRange.empty,
    );
    _isApplyingDraft = false;

    this._hideMentions();

    if (_alive) {
      ref
          .read(sttSessionProvider(_sendMessageBoxSttSessionId).notifier)
          .clearText();
    }

    this._resetVoiceTurnFlags(
      resetTalkActive: true,
      resetContinuous: true,
    );

    this._syncHasTypedText();
    this._requestFocusStable();
  }
}