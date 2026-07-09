part of '../send_message_box.dart';

extension _SendMessageBoxSend on _SendMessageBoxState {
  String _titleFromFirstMessage(String text) {
    final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (normalized.isEmpty) {
      return 'New chat';
    }

    if (normalized.length <= 48) {
      return normalized;
    }

    return '${normalized.substring(0, 48)}...';
  }

  void _showSendFailedSnack(String message) {
    if (!_alive) return;

    final clean = message.trim();
    if (clean.isEmpty) return;

    try {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(clean),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
    } catch (_) {
      if (kDebugMode) {
        debugPrint('Send failed: $clean');
      }
    }
  }

  Future<void> _startTalkFromInput(String input) async {
    if (!_alive) return;
    if (kIsWeb) return;

    final cleanInput = input.trim();
    if (cleanInput.isEmpty) return;

    final draftKeyBeforeSend = _activeDraftKey;

    this._setVoiceTalkActive(true);
    _isSendingCurrentComposer = true;
    _draftSaveDebounce?.cancel();

    final audioNotifier = ref.read(emmaAudioMessageProvider.notifier);
    final chatNotifier = ref.read(chatAiMessageProvider.notifier);

    await audioNotifier.stop();

    if (!_alive) return;

    int? sessionId;

    try {
      _suppressDraftHydrationOnRoomChange = true;

      sessionId = await chatNotifier.ensureActiveSessionForSending(
        title: this._titleFromFirstMessage(cleanInput),
      );

      if (!_alive) return;

      _suppressDraftHydrationOnRoomChange = false;

      if (sessionId == null || sessionId == 0) {
        _isSendingCurrentComposer = false;

        this._saveCurrentDraftNow(
          key: draftKeyBeforeSend,
          force: true,
        );

        if (kDebugMode) {
          debugPrint(
            'Emma: cannot start voice talk because session bootstrap returned null.',
          );
        }

        this._setVoiceTalkActive(false);
        this._requestFocusStable();
        return;
      }

      final sendFuture = chatNotifier.sendMessage(
        cleanInput,
        forceLocalTalk: true,
        autoplayLocalTalk: true,
      );

      if (!_alive) return;

      this._clearComposerAndDraftsAfterSuccessfulSend(
        draftKeyBeforeSend: draftKeyBeforeSend,
        sessionId: sessionId,
      );

      await sendFuture;

      if (!_alive) return;

      await chatNotifier.waitForLocalTalkAudioIdle();

      if (!_alive) return;

      if (_continuousTalkMode) {
        await Future.delayed(const Duration(milliseconds: 350));

        if (!_alive || !_continuousTalkMode) return;

        await this._startVoiceCapture(
          talkMode: true,
          interruptionSource: 'continuous_talk_loop',
          markInterruption: false,
        );

        return;
      }
    } catch (e, stack) {
      _suppressDraftHydrationOnRoomChange = false;

      if (!_isDisposed) {
        this._saveCurrentDraftNow(
          key: draftKeyBeforeSend,
          force: true,
        );
      }

      if (kDebugMode) {
        debugPrint('Emma: voice send failed: $e\n$stack');
      }
    } finally {
      _suppressDraftHydrationOnRoomChange = false;
      _isSendingCurrentComposer = false;

      if (!_continuousTalkMode) {
        this._setVoiceTalkActive(false);
      }

      this._requestFocusStable();
    }
  }

  void _clearComposerAfterSend({
    bool resetVoiceFlags = true,
    bool requestFocus = true,
    bool clearDraft = true,
  }) {
    if (_isDisposed) return;

    _draftSaveDebounce?.cancel();

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

    if (clearDraft) {
      this._clearDraftForCurrentChat();
    }

    if (resetVoiceFlags) {
      this._resetVoiceTurnFlags(
        resetTalkActive: true,
        resetContinuous: true,
      );
    }

    this._syncHasTypedText();

    if (requestFocus) {
      this._requestFocusStable();
    }
  }

  /// Pliki upuszczone z pulpitu (drag&drop) → załączniki.
  Future<void> _handleDroppedFiles(List<XFile> files) async {
    if (!_alive || files.isEmpty) return;
    final attNotifier = ref.read(emmaAttachmentControllerProvider.notifier);
    for (final f in files) {
      try {
        final bytes = await f.readAsBytes();
        final name = f.name.isNotEmpty ? f.name : 'plik';
        await attNotifier.addFileBytes(bytes, name);
      } catch (_) {
        // pojedynczy plik pominięty — nie przerywamy reszty
      }
    }
    if (_alive) this._requestFocusStable();
  }

  /// Ctrl/Cmd+V: jeśli w schowku jest obraz → dodaj jako załącznik; w przeciwnym
  /// razie wykonaj zwykłe wklejenie tekstu (CallbackShortcuts przechwycił zdarzenie).
  Future<void> _handlePaste() async {
    if (!_alive) return;

    bool hadImage = false;
    try {
      hadImage = await ref
          .read(emmaAttachmentControllerProvider.notifier)
          .pasteFromClipboard();
    } catch (_) {
      hadImage = false;
    }

    if (hadImage) {
      this._requestFocusStable();
      return;
    }

    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final pasteText = data?.text ?? '';
    if (pasteText.isEmpty) return;

    final sel = _controller.selection;
    final full = _controller.text;
    final start = (sel.start >= 0) ? sel.start : full.length;
    final end = (sel.end >= 0) ? sel.end : full.length;
    final newText = full.replaceRange(start, end, pasteText);
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + pasteText.length),
    );
  }

  Future<void> _sendCurrentMessage() async {
    if (!_alive) return;

    this._resetVoiceTurnFlags(
      resetTalkActive: true,
      resetContinuous: true,
    );

    await this._stopSttIfListening();

    if (!_alive) return;

    final textBeforeSend = _controller.text;
    final trimmed = textBeforeSend.trim();
    final draftKeyBeforeSend = _activeDraftKey;

    final attNotifier = ref.read(emmaAttachmentControllerProvider.notifier);
    final imagesPayload = attNotifier.imagesPayload();
    final documentsPayload = attNotifier.documentsPayload();
    final hasAttachments =
        imagesPayload.isNotEmpty || documentsPayload.isNotEmpty;

    // Nie wysyłaj, gdy załączniki wciąż się wgrywają.
    if (attNotifier.isBusy) {
      this._showSendFailedSnack('emma_attachments_uploading'.tr);
      this._requestFocusStable();
      return;
    }

    if (trimmed.isEmpty && !hasAttachments) {
      this._requestFocusStable();
      return;
    }

    final uiNotifier = ref.read(sendMessageBoxUiProvider.notifier);
    final uiState = ref.read(sendMessageBoxUiProvider);
    final chatNotifier = ref.read(chatAiMessageProvider.notifier);

    if (uiState.sendingNow) {
      this._requestFocusStable();
      return;
    }

    final chatState = ref.read(chatAiMessageProvider);
    final messages = chatState.messages;

    final isBlocked =
        chatState.isLoading && messages.isNotEmpty && messages.last.isUser;

    if (isBlocked) {
      this._requestFocusStable();
      return;
    }

    uiNotifier.setSendingNow(true);
    _isSendingCurrentComposer = true;
    _draftSaveDebounce?.cancel();

    try {
      if (!kIsWeb) {
        final audioNotifier = ref.read(emmaAudioMessageProvider.notifier);

        await audioNotifier.stop();

        if (!_alive && _isDisposed) {
          // Composer disappeared, but sending can still continue below.
        }

        await chatNotifier.stopLocalTalkAudio();
      }

      _suppressDraftHydrationOnRoomChange = true;

      final sessionId = await chatNotifier.ensureActiveSessionForSending(
        title: this._titleFromFirstMessage(
          trimmed.isEmpty ? 'Załącznik' : trimmed,
        ),
      );

      // Important:
      // Do NOT return here when !_alive.
      // First-message bootstrap can rebuild/dispose this widget after creating
      // the new session, but the original message still has to be sent.

      _suppressDraftHydrationOnRoomChange = false;

      if (sessionId == null || sessionId == 0) {
        _isSendingCurrentComposer = false;

        if (_isDisposed) {
          this._saveDraftSnapshotLater(
            key: draftKeyBeforeSend,
            text: textBeforeSend,
          );
        } else {
          this._saveCurrentDraftNow(
            key: draftKeyBeforeSend,
            force: true,
          );
        }

        final bootstrapError = chatNotifier.lastSendBootstrapError;

        if (kDebugMode) {
          debugPrint(
            'Emma: cannot send because session bootstrap returned null. '
            'Reason: $bootstrapError',
          );
        }

        if (_alive) {
          final reason = (bootstrapError ?? '').trim();
          this._showSendFailedSnack(
            reason.isEmpty
                ? 'network_error_try_again'.tr
                : '${'network_error_try_again'.tr} ($reason)',
          );
          this._requestFocusStable();
        }

        return;
      }

      await chatNotifier.sendMessage(
        trimmed,
        images: imagesPayload.isEmpty ? null : imagesPayload,
        documents: documentsPayload.isEmpty ? null : documentsPayload,
      );
      // Wysłane — czyścimy załączniki pola.
      attNotifier.clear();

      final serverDraftKey = EmmaChatDraftsNotifier.keyForSelectedRoom(
        sessionId.toString(),
      );

      final keysToClear = <String>{
        draftKeyBeforeSend,
        _activeDraftKey,
        serverDraftKey,
        EmmaChatDraftsNotifier.emptyDraftKey,
      };

      if (_alive) {
        this._clearComposerAndDraftsAfterSuccessfulSend(
          draftKeyBeforeSend: draftKeyBeforeSend,
          sessionId: sessionId,
        );
      } else {
        this._clearDraftsSnapshotLater(keysToClear);
      }
    } catch (e, st) {
      _suppressDraftHydrationOnRoomChange = false;
      _isSendingCurrentComposer = false;

      if (_isDisposed) {
        this._saveDraftSnapshotLater(
          key: draftKeyBeforeSend,
          text: textBeforeSend,
        );
      } else {
        if (_controller.text.trim().isEmpty &&
            textBeforeSend.trim().isNotEmpty) {
          _isApplyingDraft = true;
          _controller.value = TextEditingValue(
            text: textBeforeSend,
            selection: TextSelection.collapsed(offset: textBeforeSend.length),
            composing: TextRange.empty,
          );
          _isApplyingDraft = false;
        }

        this._saveCurrentDraftNow(
          key: draftKeyBeforeSend,
          force: true,
        );

        this._syncHasTypedText();
        this._requestFocusStable();
      }

      if (kDebugMode) {
        debugPrint('SendMessageBox send failed: $e');
        debugPrint('$st');
      }
    } finally {
      _suppressDraftHydrationOnRoomChange = false;
      _isSendingCurrentComposer = false;

      if (_alive) {
        try {
          uiNotifier.setSendingNow(false);
        } catch (_) {}

        this._requestFocusStable();
      } else {
        Future<void>.delayed(Duration.zero, () {
          try {
            uiNotifier.setSendingNow(false);
          } catch (_) {}
        });
      }
    }
  }
}