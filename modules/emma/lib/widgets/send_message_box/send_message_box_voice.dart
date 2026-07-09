part of '../send_message_box.dart';

extension _SendMessageBoxVoice on _SendMessageBoxState {
  bool _isVoiceModelReady(EmmaLocalVoiceModelUiState? state) {
    if (state == null) return false;
    if (!state.available) return false;
    if (state.loading) return false;
    return state.loaded;
  }

  String _voiceUnavailableTooltip({
    required String label,
    required EmmaLocalVoiceModelUiState? state,
    required bool requireLocalVoiceMode,
    required bool localVoiceMode,
  }) {
    if (kIsWeb) {
      return '$label  ${'feature_unavailable_web_suffix'.tr}';
    }

    if (requireLocalVoiceMode && !localVoiceMode) {
      return '$label ${'feature_requires_local_voice_suffix'.tr}';
    }

    if (state == null) {
      return '${'checking_status_prefix'.tr} $label...';
    }

    if (!state.available) {
      final error = (state.error ?? '').trim();

      if (error.isNotEmpty) {
        return '$label ${'feature_unavailable_with_error_prefix'.tr}\n$error';
      }

      return '$label ${'feature_unavailable_suffix'.tr}';
    }

    if (state.loading) {
      return '$label ${'feature_loading_model_suffix'.tr}';
    }

    if (!state.loaded) {
      return '$label ${'feature_no_model_loaded_suffix'.tr}';
    }

    return '$label  ${'feature_ready_suffix'.tr}';
  }

  void _showVoiceBlockedSnack(String message) {
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
        debugPrint('Voice action blocked: $clean');
      }
    }
  }

  Future<bool> _ensureLocalVoiceRuntimeReady({
    required bool requireTts,
    required String actionLabel,
  }) async {
    if (!_alive) return false;

    if (kIsWeb) {
      this._showVoiceBlockedSnack(
        '$actionLabel ${'action_unavailable_web_suffix'.tr}',
      );
      return false;
    }

    final mode = ref.read(emmaEffectiveRuntimeModeProvider);

    if (mode != EmmaRuntimeMode.localVoice) {
      this._showVoiceBlockedSnack(
        '$actionLabel ${'action_requires_local_voice_suffix'.tr}',
      );
      return false;
    }

    EmmaLocalVoiceModelUiState sttState;

    try {
      sttState = await ref.read(emmaLocalSttModelStatusProvider.future);
    } catch (error) {
      this._showVoiceBlockedSnack(
        '${'failed_to_check_stt_prefix'.tr}\n$error',
      );
      return false;
    }

    if (!this._isVoiceModelReady(sttState)) {
      this._showVoiceBlockedSnack(
        this._voiceUnavailableTooltip(
          label: 'STT',
          state: sttState,
          requireLocalVoiceMode: true,
          localVoiceMode: true,
        ),
      );
      return false;
    }

    if (!requireTts) {
      return true;
    }

    EmmaLocalVoiceModelUiState ttsState;

    try {
      ttsState = await ref.read(emmaLocalTtsModelStatusProvider.future);
    } catch (error) {
      this._showVoiceBlockedSnack(
        '${'failed_to_check_tts_prefix'.tr}\n$error',
      );
      return false;
    }

    if (!this._isVoiceModelReady(ttsState)) {
      this._showVoiceBlockedSnack(
        this._voiceUnavailableTooltip(
          label: 'TTS',
          state: ttsState,
          requireLocalVoiceMode: true,
          localVoiceMode: true,
        ),
      );
      return false;
    }

    return true;
  }

  void _setTalkAfterStt(bool value) {
    if (_talkAfterStt == value) return;

    if (!_alive) {
      _talkAfterStt = value;
      return;
    }

    setState(() {
      _talkAfterStt = value;
    });
  }

  void _setVoiceTalkActive(bool value) {
    if (_voiceTalkActive == value) return;

    if (!_alive) {
      _voiceTalkActive = value;
      return;
    }

    setState(() {
      _voiceTalkActive = value;
    });
  }

  void _setContinuousTalkMode(bool value) {
    if (_continuousTalkMode == value) return;

    if (!_alive) {
      _continuousTalkMode = value;
      return;
    }

    setState(() {
      _continuousTalkMode = value;
    });
  }

  void _resetVoiceTurnFlags({
    bool resetTalkActive = true,
    bool resetContinuous = false,
  }) {
    _voiceSilenceTimer?.cancel();
    _lastVoiceTextForSilence = '';

    this._setTalkAfterStt(false);

    if (resetTalkActive) {
      this._setVoiceTalkActive(false);
    }

    if (resetContinuous) {
      this._setContinuousTalkMode(false);
    }
  }

  void _syncControllerFromStt({
    required SttSessionState? previous,
    required SttSessionState next,
  }) {
    if (_isDisposed) return;

    final previousText = previous?.displayText ?? '';
    final nextText = next.displayText;

    final shouldSync =
        next.isBusy || previous?.isBusy == true || previousText != nextText;

    if (!shouldSync) return;
    if (_controller.text == nextText) return;

    _controller.value = _controller.value.copyWith(
      text: nextText,
      selection: TextSelection.collapsed(offset: nextText.length),
      composing: TextRange.empty,
    );

    this._onTextChanged();
  }

  void _scheduleVoiceSilenceStop(SttSessionState next) {
    if (_isDisposed) return;

    if (!_talkAfterStt) {
      _voiceSilenceTimer?.cancel();
      _lastVoiceTextForSilence = '';
      return;
    }

    if (!next.isListening) {
      _voiceSilenceTimer?.cancel();
      return;
    }

    final text = next.displayText.trim();

    if (text.isEmpty) return;

    if (text == _lastVoiceTextForSilence &&
        _voiceSilenceTimer?.isActive == true) {
      return;
    }

    _lastVoiceTextForSilence = text;
    _voiceSilenceTimer?.cancel();

    _voiceSilenceTimer = Timer(const Duration(milliseconds: 1150), () async {
      if (!_alive) return;

      final current = ref.read(
        sttSessionProvider(_sendMessageBoxSttSessionId),
      );

      if (!current.isListening) return;

      final currentText = current.displayText.trim();
      if (currentText.isEmpty) return;

      try {
        await ref
            .read(sttSessionProvider(_sendMessageBoxSttSessionId).notifier)
            .stop();
      } catch (e, stack) {
        if (kDebugMode) {
          debugPrint('SendMessageBox voice silence stop failed: $e\n$stack');
        }
      }
    });
  }

  void _maybeStartTalkAfterStt({
    required SttSessionState? previous,
    required SttSessionState next,
  }) {
    if (_isDisposed) return;
    if (!_talkAfterStt) return;

    final wasBusy = previous?.isBusy ?? false;
    final ended = wasBusy && !next.isBusy;

    if (!ended) return;

    _voiceSilenceTimer?.cancel();
    _lastVoiceTextForSilence = '';

    this._setTalkAfterStt(false);

    final error = (next.error ?? '').trim();

    if (error.isNotEmpty) {
      if (!_continuousTalkMode) {
        this._setVoiceTalkActive(false);
      }
      return;
    }

    final input = next.displayText.trim();

    if (input.isEmpty) {
      if (_continuousTalkMode) {
        unawaited(this._restartContinuousListeningAfterEmptyTurn());
      } else {
        this._setVoiceTalkActive(false);
      }
      return;
    }

    unawaited(this._startTalkFromInput(input));
  }

  Future<void> _restartContinuousListeningAfterEmptyTurn() async {
    await Future.delayed(const Duration(milliseconds: 450));

    if (!_alive || !_continuousTalkMode) return;

    await this._startVoiceCapture(
      talkMode: true,
      interruptionSource: 'continuous_talk_empty_turn',
      markInterruption: false,
    );
  }

  Future<void> _startVoiceCapture({
    required bool talkMode,
    required String interruptionSource,
    bool markInterruption = false,
  }) async {
    if (!_alive) return;

    final ready = await this._ensureLocalVoiceRuntimeReady(
      requireTts: talkMode,
      actionLabel: talkMode ? 'voice_talk_label'.tr : 'dictation_label'.tr,
    );

    if (!ready || !_alive) return;

    final sttNotifier =
        ref.read(sttSessionProvider(_sendMessageBoxSttSessionId).notifier);

    final speechLocale = ref.read(emmaSpeechLocaleProvider);

    await ref.read(emmaAudioMessageProvider.notifier).stop();

    if (!_alive) return;

    if (markInterruption) {
      final chatNotifier = ref.read(chatAiMessageProvider.notifier);

      await chatNotifier.beginUserVoiceInterruption(
        source: interruptionSource,
      );

      if (!_alive) return;
    }

    _voiceSilenceTimer?.cancel();
    _lastVoiceTextForSilence = '';

    this._setTalkAfterStt(talkMode);

    if (talkMode) {
      this._setVoiceTalkActive(true);
    }

    sttNotifier.seedBaseText(_controller.text);

    await sttNotifier.start(
      SttConfig(
        locale: speechLocale,
        mode: SttMode.auto,
        autoPunctuation: true,
        partialResults: true,
        listenFor: const Duration(minutes: 2),
        pauseFor: const Duration(milliseconds: 900),
        captureProfile: SttCaptureProfile.dictation,
        privacyMode: SttPrivacyMode.transcriptOnly,
      ),
    );

    if (!_alive) return;

    this._requestFocusStable();
  }

  Future<void> _toggleStt({required bool busy}) async {
    if (!_alive) return;

    this._resetVoiceTurnFlags(
      resetTalkActive: false,
      resetContinuous: false,
    );

    if (busy) return;

    final sttNotifier =
        ref.read(sttSessionProvider(_sendMessageBoxSttSessionId).notifier);
    final sttState = ref.read(sttSessionProvider(_sendMessageBoxSttSessionId));

    if (sttState.isBusy) {
      await sttNotifier.stop();

      if (!_alive) return;

      this._requestFocusStable();
      return;
    }

    final ready = await this._ensureLocalVoiceRuntimeReady(
      requireTts: false,
      actionLabel: 'dictation_label'.tr,
    );

    if (!ready || !_alive) return;

    await ref.read(emmaAudioMessageProvider.notifier).stop();

    if (!_alive) return;

    final speechLocale = ref.read(emmaSpeechLocaleProvider);

    sttNotifier.seedBaseText(_controller.text);

    await sttNotifier.start(
      SttConfig(
        locale: speechLocale,
        mode: SttMode.auto,
        autoPunctuation: true,
        partialResults: true,
        listenFor: const Duration(minutes: 2),
        pauseFor: const Duration(seconds: 2),
        captureProfile: SttCaptureProfile.dictation,
        privacyMode: SttPrivacyMode.transcriptOnly,
      ),
    );

    if (!_alive) return;

    this._requestFocusStable();
  }

  Future<void> _toggleVoiceTalk({
    required bool baseBusy,
  }) async {
    if (!_alive) return;

    if (kIsWeb) {
      this._showVoiceBlockedSnack(
        'talk_unavailable_web'.tr,
      );
      return;
    }

    final chatNotifier = ref.read(chatAiMessageProvider.notifier);
    final chatState = ref.read(chatAiMessageProvider);

    final sttNotifier =
        ref.read(sttSessionProvider(_sendMessageBoxSttSessionId).notifier);
    final sttState = ref.read(sttSessionProvider(_sendMessageBoxSttSessionId));

    if (sttState.isBusy) {
      this._setContinuousTalkMode(true);
      this._setTalkAfterStt(true);
      this._setVoiceTalkActive(true);

      await sttNotifier.stop();

      if (!_alive) return;

      this._requestFocusStable();
      return;
    }

    final canInterruptCurrentAnswer = _voiceTalkActive ||
        chatNotifier.isLocalTalkAudioBusy ||
        (chatState.isLoading && chatState.canCancel);

    if (canInterruptCurrentAnswer) {
      final ready = await this._ensureLocalVoiceRuntimeReady(
        requireTts: true,
        actionLabel: 'voice_talk_label'.tr,
      );

      if (!ready || !_alive) return;

      this._setContinuousTalkMode(true);
      this._setVoiceTalkActive(true);

      await chatNotifier.stopLocalTalkAudio();

      if (!_alive) return;

      if (chatState.isLoading && chatState.canCancel) {
        await chatNotifier.stopGenerating(reconnect: false);

        if (!_alive) return;
      }

      await this._startVoiceCapture(
        talkMode: true,
        interruptionSource: 'send_message_box_talk_barge_in',
        markInterruption: true,
      );

      return;
    }

    if (_continuousTalkMode && !_voiceTalkActive && !chatState.isLoading) {
      this._setContinuousTalkMode(false);

      this._resetVoiceTurnFlags(
        resetTalkActive: true,
        resetContinuous: true,
      );

      await chatNotifier.stopLocalTalkAudio();

      if (!_alive) return;

      this._requestFocusStable();
      return;
    }

    if (baseBusy) return;

    final ready = await this._ensureLocalVoiceRuntimeReady(
      requireTts: true,
      actionLabel: 'voice_talk_label'.tr,
    );

    if (!ready || !_alive) return;

    this._setContinuousTalkMode(true);
    this._setVoiceTalkActive(true);

    await this._startVoiceCapture(
      talkMode: true,
      interruptionSource: 'send_message_box_talk',
      markInterruption: false,
    );
  }

  Future<void> _stopSttIfListening() async {
    if (!_alive) return;

    final sttNotifier =
        ref.read(sttSessionProvider(_sendMessageBoxSttSessionId).notifier);
    final sttState = ref.read(sttSessionProvider(_sendMessageBoxSttSessionId));

    if (!sttState.isBusy) return;

    this._resetVoiceTurnFlags(
      resetTalkActive: false,
      resetContinuous: false,
    );

    await sttNotifier.stop();
  }

  void _toggleAutoRead() {
    if (!_alive) return;

    if (kIsWeb) {
      this._showVoiceBlockedSnack(
        'local_reading_unavailable_web'.tr,
      );
      return;
    }

    final mode = ref.read(emmaEffectiveRuntimeModeProvider);

    if (mode != EmmaRuntimeMode.localVoice) {
      this._showVoiceBlockedSnack(
        'auto_read_requires_local_voice'.tr,
      );
      return;
    }

    final ttsState = ref.read(emmaLocalTtsModelStatusProvider).valueOrNull;

    if (!this._isVoiceModelReady(ttsState)) {
      this._showVoiceBlockedSnack(
        this._voiceUnavailableTooltip(
          label: 'TTS',
          state: ttsState,
          requireLocalVoiceMode: true,
          localVoiceMode: true,
        ),
      );
      return;
    }

    final current = ref.read(emmaAutoReadMessagesProvider);
    ref.read(emmaAutoReadMessagesProvider.notifier).state = !current;

    this._requestFocusStable();
  }
}