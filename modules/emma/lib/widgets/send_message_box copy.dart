import 'dart:async';

import 'package:emma/model/mention_models.dart';
import 'package:emma/provider/audio_provider.dart';
import 'package:emma/provider/emma_notifier.dart';
import 'package:emma/provider/emma_provider.dart';
import 'package:emma/provider/mention_provider.dart';
import 'package:emma/provider/send_message_box_provider.dart';
import 'package:emma/provider/stt_model_provider.dart';
import 'package:emma/provider/voice_provider.dart';
import 'package:emma/stt/services/local_superbee_stt_client.dart';
import 'package:emma/stt/stt_core.dart';
import 'package:emma/stt/stt_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/icons.dart';
import 'package:core/theme/lottie.dart';
import 'package:core/translate/language_provider.dart';

const String _sendMessageBoxSttSessionId = 'send_message_box';

class SendMessageBox extends ConsumerStatefulWidget {
  final bool centerMode;
  final bool isMobile;

  const SendMessageBox({
    super.key,
    this.centerMode = false,
    this.isMobile = false,
  });

  @override
  ConsumerState<SendMessageBox> createState() => _SendMessageBoxState();
}

class _SendMessageBoxState extends ConsumerState<SendMessageBox> {
  late final MentionTextController _controller;
  late final FocusNode _focusNode;
  late final EmmaChatDraftsNotifier _draftsNotifier;

  ProviderSubscription<String>? _selectedRoomSubscription;

  Timer? _draftSaveDebounce;
  String _activeDraftKey = EmmaChatDraftsNotifier.emptyDraftKey;

  bool _isDisposed = false;
  bool _isApplyingDraft = false;
  bool _suppressDraftHydrationOnRoomChange = false;
  bool _isSendingCurrentComposer = false;

  bool _hasTypedText = false;

  bool _talkAfterStt = false;
  bool _voiceTalkActive = false;
  bool _continuousTalkMode = false;

  Timer? _voiceSilenceTimer;
  String _lastVoiceTextForSilence = '';

  bool get _alive => mounted && !_isDisposed;

  @override
  void initState() {
    super.initState();

    _draftsNotifier = ref.read(emmaChatDraftsProvider.notifier);

    _activeDraftKey = EmmaChatDraftsNotifier.keyForSelectedRoom(
      ref.read(selectedAiRoomProvider),
    );

    final initialDraft = _draftsNotifier.draftForKey(_activeDraftKey);

    _controller = MentionTextController(text: initialDraft);
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
    _controller.addListener(_onTextChanged);

    _hasTypedText = _controller.text.trim().isNotEmpty;

    _focusNode = ref.read(emmaChatInputFocusNodeProvider);

    _selectedRoomSubscription = ref.listenManual<String>(
      selectedAiRoomProvider,
      (previous, next) {
        if (!_alive) return;
        _handleSelectedRoomChanged(next);
      },
    );

    HardwareKeyboard.instance.addHandler(_handleHardwareKeyEvent);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_alive) return;

      _requestFocus();

      final speechLocale = ref.read(emmaSpeechLocaleProvider);

      unawaited(
        ref
            .read(sttSessionProvider(_sendMessageBoxSttSessionId).notifier)
            .refreshCapabilities(speechLocale),
      );
    });
  }

  @override
  void dispose() {
    final shouldSaveDraftOnDispose =
        !_isApplyingDraft && !_isSendingCurrentComposer;

    final draftKeyBeforeDispose = _activeDraftKey;
    final draftTextBeforeDispose = _controller.text;

    _isDisposed = true;

    _draftSaveDebounce?.cancel();
    _voiceSilenceTimer?.cancel();

    // Riverpod does not allow provider mutations directly inside dispose().
    // We snapshot the key/text now and write after the current widget tree frame.
    if (shouldSaveDraftOnDispose) {
      _saveDraftSnapshotLater(
        key: draftKeyBeforeDispose,
        text: draftTextBeforeDispose,
      );
    }

    _selectedRoomSubscription?.close();

    HardwareKeyboard.instance.removeHandler(_handleHardwareKeyEvent);

    _controller.removeListener(_onTextChanged);
    _controller.dispose();

    super.dispose();
  }


  void _requestFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_alive) return;
      FocusScope.of(context).requestFocus(_focusNode);
      _focusNode.requestFocus();
    });
  }

  void _requestFocusStable() {
    void focus() {
      if (!_alive) return;

      if (!_focusNode.canRequestFocus) {
        return;
      }

      FocusScope.of(context).requestFocus(_focusNode);
      _focusNode.requestFocus();
    }

    focus();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      focus();
    });

    Future.delayed(const Duration(milliseconds: 60), focus);
    Future.delayed(const Duration(milliseconds: 160), focus);
  }

  void _handleSelectedRoomChanged(String nextSelectedRoom) {
    if (_isDisposed) return;

    final previousDraftKey = _activeDraftKey;

    if (!_isSendingCurrentComposer && !_suppressDraftHydrationOnRoomChange) {
      _saveCurrentDraftNow(key: previousDraftKey);
    }

    final nextDraftKey = EmmaChatDraftsNotifier.keyForSelectedRoom(
      nextSelectedRoom,
    );

    _activeDraftKey = nextDraftKey;

    // During first-message bootstrap we do not copy/hydrate the empty chat draft
    // into the newly created server session.
    if (_suppressDraftHydrationOnRoomChange) {
      _clearDraftForKey(nextDraftKey);
      return;
    }

    if (_isSendingCurrentComposer) {
      return;
    }

    _applyDraftForKey(nextDraftKey);
    _requestFocusStable();
  }

  void _queueDraftSave() {
    if (_isDisposed) return;
    if (_isApplyingDraft || _isSendingCurrentComposer) return;

    _draftSaveDebounce?.cancel();

    _draftSaveDebounce = Timer(const Duration(milliseconds: 160), () {
      if (_isDisposed) return;
      _saveCurrentDraftNow();
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
      _saveDraftSnapshotLater(
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
      _syncHasTypedText();
      return;
    }

    _isApplyingDraft = true;

    _controller.value = TextEditingValue(
      text: draft,
      selection: TextSelection.collapsed(offset: draft.length),
      composing: TextRange.empty,
    );

    _isApplyingDraft = false;

    _hideMentions();
    _syncHasTypedText();
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
      _clearDraftForKey(key);
    }

    _activeDraftKey = serverDraftKey;

    _isApplyingDraft = true;
    _controller.value = const TextEditingValue(
      text: '',
      selection: TextSelection.collapsed(offset: 0),
      composing: TextRange.empty,
    );
    _isApplyingDraft = false;

    _hideMentions();

    if (_alive) {
      ref
          .read(sttSessionProvider(_sendMessageBoxSttSessionId).notifier)
          .clearText();
    }

    _resetVoiceTurnFlags(
      resetTalkActive: true,
      resetContinuous: true,
    );

    _syncHasTypedText();
    _requestFocusStable();
  }

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
        _hideMentions();
        _requestFocusStable();
        return true;
      }

      unawaited(_closeTopOverlayOrRoute());
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
      final busy = _isKeyboardSendBusy();
      final hasText = _controller.text.trim().isNotEmpty;

      if (!busy && hasText) {
        unawaited(_sendCurrentMessage());
      } else {
        _requestFocusStable();
      }

      return true;
    }

    if (isBackspace) {
      return _handleBackspaceOnMention();
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
    _setTalkAfterStt(false);

    if (resetTalkActive) {
      _setVoiceTalkActive(false);
    }

    if (resetContinuous) {
      _setContinuousTalkMode(false);
    }
  }

  void _syncHasTypedText() {
    final hasText = _controller.text.trim().isNotEmpty;

    if (_hasTypedText == hasText) return;

    if (!_alive) {
      _hasTypedText = hasText;
      return;
    }

    setState(() {
      _hasTypedText = hasText;
    });
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

    _onTextChanged();
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
    _setTalkAfterStt(false);

    final error = (next.error ?? '').trim();

    if (error.isNotEmpty) {
      if (!_continuousTalkMode) {
        _setVoiceTalkActive(false);
      }
      return;
    }

    final input = next.displayText.trim();

    if (input.isEmpty) {
      if (_continuousTalkMode) {
        unawaited(_restartContinuousListeningAfterEmptyTurn());
      } else {
        _setVoiceTalkActive(false);
      }
      return;
    }

    unawaited(_startTalkFromInput(input));
  }

  Future<void> _restartContinuousListeningAfterEmptyTurn() async {
    await Future.delayed(const Duration(milliseconds: 450));

    if (!_alive || !_continuousTalkMode) return;

    await _startVoiceCapture(
      talkMode: true,
      interruptionSource: 'continuous_talk_empty_turn',
      markInterruption: false,
    );
  }

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

  Future<void> _startTalkFromInput(String input) async {
    if (!_alive) return;
    if (kIsWeb) return;

    final cleanInput = input.trim();
    if (cleanInput.isEmpty) return;

    final draftKeyBeforeSend = _activeDraftKey;

    _setVoiceTalkActive(true);
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
        title: _titleFromFirstMessage(cleanInput),
      );

      if (!_alive) return;

      _suppressDraftHydrationOnRoomChange = false;

      if (sessionId == null || sessionId == 0) {
        _isSendingCurrentComposer = false;

        _saveCurrentDraftNow(
          key: draftKeyBeforeSend,
          force: true,
        );

        if (kDebugMode) {
          debugPrint(
            'Emma: cannot start voice talk because session bootstrap returned null.',
          );
        }

        _setVoiceTalkActive(false);
        _requestFocusStable();
        return;
      }

      final sendFuture = chatNotifier.sendMessage(
        cleanInput,
        forceLocalTalk: true,
        autoplayLocalTalk: true,
      );

      if (!_alive) return;

      _clearComposerAndDraftsAfterSuccessfulSend(
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

        await _startVoiceCapture(
          talkMode: true,
          interruptionSource: 'continuous_talk_loop',
          markInterruption: false,
        );

        return;
      }
    } catch (e, stack) {
      _suppressDraftHydrationOnRoomChange = false;

      if (!_isDisposed) {
        _saveCurrentDraftNow(
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
        _setVoiceTalkActive(false);
      }

      _requestFocusStable();
    }
  }

  Future<void> _startVoiceCapture({
    required bool talkMode,
    required String interruptionSource,
    bool markInterruption = false,
  }) async {
    if (!_alive) return;
    if (kIsWeb) return;

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

    _setTalkAfterStt(talkMode);

    if (talkMode) {
      _setVoiceTalkActive(true);
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

    _requestFocusStable();
  }

  void _onTextChanged() {
    if (_isDisposed) return;

    _queueDraftSave();
    _syncHasTypedText();

    final text = _controller.text;
    final cursorPos = _controller.selection.baseOffset;

    if (cursorPos <= 0 || cursorPos > text.length) {
      _hideMentions();
      return;
    }

    var start = cursorPos - 1;

    while (start > 0) {
      final ch = text[start];

      if (ch == ' ' || ch == '\n' || ch == '\t') {
        start += 1;
        break;
      }

      start -= 1;
    }

    if (start < 0) start = 0;

    final currentWord = text.substring(start, cursorPos);

    if (currentWord.isEmpty) {
      _hideMentions();
      return;
    }

    final firstChar = currentWord[0];

    if (firstChar != '@' && firstChar != '#') {
      _hideMentions();
      return;
    }

    final query = currentWord.substring(1);

    if (!_alive) return;

    ref.read(sendMessageBoxUiProvider.notifier).setMentionState(
          mentionStartIndex: start,
          mentionQuery: query,
          showMentions: true,
          currentTriggerChar: firstChar,
        );
  }

  void _hideMentions() {
    if (!_alive) return;

    ref.read(sendMessageBoxUiProvider.notifier).hideMentions();
  }

  Future<void> _toggleStt({required bool busy}) async {
    if (!_alive) return;

    _resetVoiceTurnFlags(
      resetTalkActive: false,
      resetContinuous: false,
    );

    if (busy) return;

    final sttNotifier =
        ref.read(sttSessionProvider(_sendMessageBoxSttSessionId).notifier);
    final sttState = ref.read(sttSessionProvider(_sendMessageBoxSttSessionId));
    final speechLocale = ref.read(emmaSpeechLocaleProvider);

    if (sttState.isBusy) {
      await sttNotifier.stop();

      if (!_alive) return;

      _requestFocusStable();
      return;
    }

    if (!kIsWeb) {
      await ref.read(emmaAudioMessageProvider.notifier).stop();

      if (!_alive) return;
    }

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

    _requestFocusStable();
  }

  Future<void> _toggleVoiceTalk({
    required bool baseBusy,
  }) async {
    if (!_alive) return;
    if (kIsWeb) return;

    final chatNotifier = ref.read(chatAiMessageProvider.notifier);
    final chatState = ref.read(chatAiMessageProvider);

    final sttNotifier =
        ref.read(sttSessionProvider(_sendMessageBoxSttSessionId).notifier);
    final sttState = ref.read(sttSessionProvider(_sendMessageBoxSttSessionId));

    if (sttState.isBusy) {
      _setContinuousTalkMode(true);
      _setTalkAfterStt(true);
      _setVoiceTalkActive(true);

      await sttNotifier.stop();

      if (!_alive) return;

      _requestFocusStable();
      return;
    }

    final canInterruptCurrentAnswer = _voiceTalkActive ||
        chatNotifier.isLocalTalkAudioBusy ||
        (chatState.isLoading && chatState.canCancel);

    if (canInterruptCurrentAnswer) {
      _setContinuousTalkMode(true);
      _setVoiceTalkActive(true);

      await chatNotifier.stopLocalTalkAudio();

      if (!_alive) return;

      if (chatState.isLoading && chatState.canCancel) {
        await chatNotifier.stopGenerating(reconnect: false);

        if (!_alive) return;
      }

      await _startVoiceCapture(
        talkMode: true,
        interruptionSource: 'send_message_box_talk_barge_in',
        markInterruption: true,
      );

      return;
    }

    if (_continuousTalkMode && !_voiceTalkActive && !chatState.isLoading) {
      _setContinuousTalkMode(false);
      _resetVoiceTurnFlags(
        resetTalkActive: true,
        resetContinuous: true,
      );

      await chatNotifier.stopLocalTalkAudio();

      if (!_alive) return;

      _requestFocusStable();
      return;
    }

    if (baseBusy) return;

    _setContinuousTalkMode(true);
    _setVoiceTalkActive(true);

    await _startVoiceCapture(
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

    _resetVoiceTurnFlags(
      resetTalkActive: false,
      resetContinuous: false,
    );

    await sttNotifier.stop();
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

    _hideMentions();

    if (_alive) {
      ref
          .read(sttSessionProvider(_sendMessageBoxSttSessionId).notifier)
          .clearText();
    }

    if (clearDraft) {
      _clearDraftForCurrentChat();
    }

    if (resetVoiceFlags) {
      _resetVoiceTurnFlags(
        resetTalkActive: true,
        resetContinuous: true,
      );
    }

    _syncHasTypedText();

    if (requestFocus) {
      _requestFocusStable();
    }
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


  Future<void> _sendCurrentMessage() async {
    if (!_alive) return;

    _resetVoiceTurnFlags(
      resetTalkActive: true,
      resetContinuous: true,
    );

    await _stopSttIfListening();

    if (!_alive) return;

    final textBeforeSend = _controller.text;
    final trimmed = textBeforeSend.trim();
    final draftKeyBeforeSend = _activeDraftKey;

    if (trimmed.isEmpty) {
      _requestFocusStable();
      return;
    }

    final uiNotifier = ref.read(sendMessageBoxUiProvider.notifier);
    final uiState = ref.read(sendMessageBoxUiProvider);
    final chatNotifier = ref.read(chatAiMessageProvider.notifier);

    if (uiState.sendingNow) {
      _requestFocusStable();
      return;
    }

    final chatState = ref.read(chatAiMessageProvider);
    final messages = chatState.messages;

    final isBlocked =
        chatState.isLoading && messages.isNotEmpty && messages.last.isUser;

    if (isBlocked) {
      _requestFocusStable();
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
        title: _titleFromFirstMessage(trimmed),
      );

      // Important:
      // Do NOT return here when !_alive.
      // First-message bootstrap can rebuild/dispose this widget after creating
      // the new session, but the original message still has to be sent.

      _suppressDraftHydrationOnRoomChange = false;

      if (sessionId == null || sessionId == 0) {
        _isSendingCurrentComposer = false;

        if (_isDisposed) {
          _saveDraftSnapshotLater(
            key: draftKeyBeforeSend,
            text: textBeforeSend,
          );
        } else {
          _saveCurrentDraftNow(
            key: draftKeyBeforeSend,
            force: true,
          );
        }

        if (kDebugMode) {
          debugPrint(
            'Emma: cannot send because session bootstrap returned null.',
          );
        }

        if (_alive) {
          _requestFocusStable();
        }

        return;
      }

      await chatNotifier.sendMessage(trimmed);

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
        _clearComposerAndDraftsAfterSuccessfulSend(
          draftKeyBeforeSend: draftKeyBeforeSend,
          sessionId: sessionId,
        );
      } else {
        _clearDraftsSnapshotLater(keysToClear);
      }
    } catch (e, st) {
      _suppressDraftHydrationOnRoomChange = false;
      _isSendingCurrentComposer = false;

      if (_isDisposed) {
        _saveDraftSnapshotLater(
          key: draftKeyBeforeSend,
          text: textBeforeSend,
        );
      } else {
        if (_controller.text.trim().isEmpty && textBeforeSend.trim().isNotEmpty) {
          _isApplyingDraft = true;
          _controller.value = TextEditingValue(
            text: textBeforeSend,
            selection: TextSelection.collapsed(offset: textBeforeSend.length),
            composing: TextRange.empty,
          );
          _isApplyingDraft = false;
        }

        _saveCurrentDraftNow(
          key: draftKeyBeforeSend,
          force: true,
        );

        _syncHasTypedText();
        _requestFocusStable();
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

        _requestFocusStable();
      } else {
        Future<void>.delayed(Duration.zero, () {
          try {
            uiNotifier.setSendingNow(false);
          } catch (_) {}
        });
      }
    }
  }





  void _insertMention(MentionItem item) {
    if (!_alive) return;

    final uiState = ref.read(sendMessageBoxUiProvider);

    final text = _controller.text;
    final cursorPos = _controller.selection.baseOffset;

    if (uiState.mentionStartIndex < 0 ||
        uiState.mentionStartIndex > text.length ||
        cursorPos < uiState.mentionStartIndex) {
      return;
    }

    final before = text.substring(0, uiState.mentionStartIndex);
    final after = text.substring(cursorPos);

    final prefix =
        uiState.currentTriggerChar.isEmpty ? '@' : uiState.currentTriggerChar;

    final tag = item.tag.isNotEmpty ? item.tag : '$prefix${item.displayName}';
    final mentionText = '$tag ';

    final newText = '$before$mentionText$after';
    final newCursorPos = (before + mentionText).length;

    _controller.text = newText;
    _controller.selection = TextSelection.collapsed(offset: newCursorPos);

    ref.read(sendMessageBoxUiProvider.notifier).hideMentions();
    _syncHasTypedText();
    _requestFocusStable();
  }

  bool _handleBackspaceOnMention() {
    if (_isDisposed) return false;

    final text = _controller.text;

    if (text.isEmpty) return false;

    final selection = _controller.selection;

    if (!selection.isCollapsed) return false;

    final cursorPos = selection.baseOffset;

    if (cursorPos <= 0) return false;

    final matches = mentionRe.allMatches(text).toList();

    for (final match in matches) {
      final start = match.start;
      final end = match.end;

      if (cursorPos > start && cursorPos <= end) {
        final kind = match.group(1);

        final deleteStart = start;
        var deleteEnd = end;

        if (kind == 'tx' && deleteEnd < text.length && text[deleteEnd] == ' ') {
          deleteEnd += 1;
        }

        final newText = text.replaceRange(deleteStart, deleteEnd, '');

        _controller.text = newText;
        _controller.selection = TextSelection.collapsed(offset: deleteStart);

        _syncHasTypedText();

        return true;
      }
    }

    return false;
  }

  void _toggleAutoRead() {
    if (!_alive) return;
    if (kIsWeb) return;

    final current = ref.read(emmaAutoReadMessagesProvider);
    ref.read(emmaAutoReadMessagesProvider.notifier).state = !current;

    _requestFocusStable();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<SttSessionState>(
      sttSessionProvider(_sendMessageBoxSttSessionId),
      (previous, next) {
        if (!_alive) return;

        _syncControllerFromStt(previous: previous, next: next);
        _scheduleVoiceSilenceStop(next);
        _maybeStartTalkAfterStt(previous: previous, next: next);
      },
    );

    ref.listen<ChatAiMessagesState>(
      chatAiMessageProvider,
      (previous, next) {
        if (!_alive) return;

        final wasLoading = previous?.isLoading ?? false;
        final finished = wasLoading && !next.isLoading;

        if (finished && _voiceTalkActive && !_continuousTalkMode) {
          _setVoiceTalkActive(false);
        }
      },
    );

    final theme = ref.watch(themeColorsProvider);
    final ui = ref.watch(sendMessageBoxUiProvider);
    final sttState = ref.watch(sttSessionProvider(_sendMessageBoxSttSessionId));
    final autoRead = ref.watch(emmaAutoReadMessagesProvider);

    final chatState = ref.watch(chatAiMessageProvider);
    final messages = chatState.messages;
    final chatNotifier = ref.read(chatAiMessageProvider.notifier);
    final isLocalTalkAudioBusy = chatNotifier.isLocalTalkAudioBusy;

    final isBlockedSending =
        chatState.isLoading && messages.isNotEmpty && messages.last.isUser;

    final mentionAsync = ui.showMentions && !sttState.isListening
        ? ref.watch(
            mentionSearchProvider(
              (
                query: ui.mentionQuery,
                trigger:
                    ui.currentTriggerChar.isEmpty ? '@' : ui.currentTriggerChar,
              ),
            ),
          )
        : const AsyncValue<List<MentionItem>>.data([]);

    final boot = ref.watch(emmaChatBootstrappingProvider);

    final baseBusy = ui.sendingNow || boot || isBlockedSending;

    final talkButtonActive = _continuousTalkMode ||
        _talkAfterStt ||
        _voiceTalkActive ||
        isLocalTalkAudioBusy ||
        (chatState.isLoading && chatState.canCancel);

    final busy = baseBusy || talkButtonActive;

    final sttControlsBusy = sttState.isStarting || sttState.isStopping;

    final textInputReadOnly =
        sttState.isListening || sttState.isStopping || talkButtonActive;

    final showUtilityButtons =
        !_hasTypedText || sttState.isBusy || talkButtonActive;

    final canSend = !busy && _controller.text.trim().isNotEmpty;

    return Padding(
      padding: widget.centerMode
          ? const EdgeInsets.symmetric(horizontal: 24, vertical: 0)
          : const EdgeInsets.only(right: 25, left: 25, bottom: 20),
      child: Container(
        constraints: const BoxConstraints(minHeight: 50, maxHeight: 500),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6.0),
          color: theme.textFieldColor.withAlpha((255 * 0.55).toInt()),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (ui.showMentions && !busy && !sttState.isListening)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 150),
                child: mentionAsync.when(
                  data: (items) {
                    if (items.isEmpty) return const SizedBox.shrink();

                    return ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.only(
                        left: 8,
                        right: 8,
                        top: 6,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final isUser = item.kind == MentionKind.user;

                        return InkWell(
                          onTap: () => _insertMention(item),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 4,
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  child: Text(
                                    item.displayName.isNotEmpty
                                        ? item.displayName[0].toUpperCase()
                                        : '?',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.displayName,
                                        style: TextStyle(
                                          color: theme.textColor,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (item.subtitle != null &&
                                          item.subtitle!.isNotEmpty)
                                        Text(
                                          item.subtitle!,
                                          style: TextStyle(
                                            color:
                                                theme.textColor.withAlpha(150),
                                            fontSize: 11,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isUser ? 'User'.tr : 'Contact'.tr,
                                  style: TextStyle(
                                    color: theme.textColor.withAlpha(140),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: SizedBox(
                      height: 18,
                      width: 18,
                      child: AppLottie.loading(),
                    ),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: showUtilityButtons
                      ? Row(
                          key: const ValueKey('emma-input-tools-visible'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: 50,
                              width: 50,
                              child: ElevatedButton(
                                style: elevatedButtonStyleRounded10,
                                onPressed: busy
                                    ? null
                                    : () async {
                                        _requestFocusStable();
                                      },
                                child: AppIcons.document(color: theme.textColor),
                              ),
                            ),
                            SizedBox(
                              height: 50,
                              width: 50,
                              child: ElevatedButton(
                                style: elevatedButtonStyleRounded10,
                                onPressed: baseBusy || sttControlsBusy
                                    ? null
                                    : () => unawaited(
                                          _toggleStt(busy: baseBusy),
                                        ),
                                child: Icon(
                                  sttState.isListening && !_talkAfterStt
                                      ? Icons.stop
                                      : Icons.mic,
                                  color: theme.textColor,
                                  size: 20,
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 50,
                              width: 50,
                              child: Tooltip(
                                message: kIsWeb
                                    ? 'talk_unavailable_web'.tr
                                    : sttState.isListening
                                        ? 'finish_speech_and_send'.tr
                                        : _continuousTalkMode &&
                                                !chatState.isLoading &&
                                                !_voiceTalkActive
                                            ? 'end_talk_mode'.tr
                                            : talkButtonActive
                                                ? 'interrupt_emma_and_speak'.tr
                                                : 'talk_with_emma_voice'.tr,
                                child: ElevatedButton(
                                  style: elevatedButtonStyleRounded10,
                                  onPressed: kIsWeb
                                      ? null
                                      : () => unawaited(
                                            _toggleVoiceTalk(
                                              baseBusy: baseBusy,
                                            ),
                                          ),
                                  child: Icon(
                                    sttState.isListening
                                        ? Icons.stop_circle_rounded
                                        : _continuousTalkMode
                                            ? Icons.forum_rounded
                                            : Icons.hearing_rounded,
                                    color: talkButtonActive
                                        ? theme.themeColor
                                        : theme.textColor,
                                    size: 21,
                                  ),
                                ),
                              ),
                            ),
                            _EmmaSttSelectorButton(
                              theme: theme,
                              onSelected: _requestFocusStable,
                            ),
                            Tooltip(
                              message: kIsWeb
                                  ? 'local_reading_unavailable_web'.tr
                                  : autoRead
                                      ? 'auto_read_on'.tr
                                      : 'auto_read_off'.tr,
                              child: SizedBox(
                                height: 50,
                                width: 50,
                                child: ElevatedButton(
                                  style: elevatedButtonStyleRounded10,
                                  onPressed: kIsWeb ? null : _toggleAutoRead,
                                  child: Icon(
                                    kIsWeb
                                        ? Icons.volume_off_rounded
                                        : autoRead
                                            ? Icons.volume_up_rounded
                                            : Icons.volume_off_rounded,
                                    color: autoRead && !kIsWeb
                                        ? theme.themeColor
                                        : theme.textColor,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                            _EmmaVoiceSelectorButton(
                              theme: theme,
                              onSelected: _requestFocusStable,
                            ),
                          ],
                        )
                      : const SizedBox(
                          key: ValueKey('emma-input-tools-hidden'),
                          width: 0,
                          height: 50,
                        ),
                ),
                Expanded(
                  child: TextField(
                    focusNode: _focusNode,
                    controller: _controller,
                    cursorColor: theme.textColor,
                    style: TextStyle(color: theme.textColor),
                    keyboardType: TextInputType.multiline,
                    minLines: 1,
                    maxLines: 15,
                    enabled: true,
                    readOnly: textInputReadOnly,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: sttState.isListening
                          ? (_talkAfterStt
                              ? 'speak_to_emma'.tr
                              : 'listening'.tr)
                          : sttState.isStarting
                              ? 'starting_stt'.tr
                              : sttState.isStopping
                                  ? 'transcribing_audio'.tr
                                  : _voiceTalkActive && chatState.isLoading
                                      ? 'emma_replying_voice'.tr
                                      : _continuousTalkMode
                                          ? 'talk_mode_active'.tr
                                          : busy
                                              ? (boot
                                                  ? 'creating_chat'.tr
                                                  : 'emma_thinking'.tr
                                                      .tr)
                                              : 'write_message'.tr,
                      hintStyle: TextStyle(
                        fontSize: widget.isMobile ? 13 : null,
                        color: theme.textColor.withAlpha(120),
                      ),
                      floatingLabelStyle: TextStyle(
                        color: theme.textColor.withAlpha(120),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                    ),
                  ),
                ),
                SizedBox(
                  height: 50,
                  width: 50,
                  child: ElevatedButton(
                    style: elevatedButtonStyleRounded10,
                    onPressed:
                        canSend ? () => unawaited(_sendCurrentMessage()) : null,
                    child: busy
                        ? SizedBox(
                            height: 18,
                            width: 18,
                            child: AppLottie.loading(),
                          )
                        : AppIcons.sendAbove(color: theme.textColor),
                  ),
                ),
              ],
            ),
            if ((sttState.error ?? '').trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    sttState.error!,
                    style: TextStyle(
                      color: Colors.redAccent.shade200,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            if ((chatState.activityDetail ?? '').trim().isNotEmpty &&
                (_voiceTalkActive || _continuousTalkMode))
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    chatState.activityDetail!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.textColor.withAlpha(130),
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmmaVoiceSelectorButton extends ConsumerWidget {
  const _EmmaVoiceSelectorButton({
    required this.theme,
    required this.onSelected,
  });

  final ThemeColors theme;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(emmaSelectedVoiceProvider);

    return Tooltip(
      message: kIsWeb
          ? 'voice_selection_unavailable_web'.tr
          : '${'emma_voice_tooltip'.tr} ${selected.label}',
      child: PopupMenuButton<EmmaVoicePreset>(
        enabled: !kIsWeb,
        tooltip: 'select_emma_voice'.tr,
        color: theme.adPopBackground,
        initialValue: selected,
        onSelected: (voice) {
          final current = ref.read(emmaSelectedVoiceProvider);

          if (current.id == voice.id) {
            onSelected();
            return;
          }

          ref.read(emmaSelectedVoiceProvider.notifier).state = voice;

          unawaited(
            ref.read(emmaAudioMessageProvider.notifier).stop(),
          );

          final chatNotifier = ref.read(chatAiMessageProvider.notifier);

          unawaited(
            chatNotifier.stopLocalTalkAudio(),
          );

          onSelected();
        },
        itemBuilder: (context) {
          return emmaVoicePresets.map((voice) {
            final isSelected = voice.id == selected.id;

            return PopupMenuItem<EmmaVoicePreset>(
              value: voice,
              child: Row(
                children: [
                  Icon(
                    Icons.record_voice_over_rounded,
                    size: 19,
                    color: isSelected ? theme.themeColor : theme.textColor,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          voice.label,
                          style: TextStyle(
                            color: theme.textColor,
                            fontWeight:
                                isSelected ? FontWeight.w800 : FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          voice.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: theme.textColor.withAlpha(145),
                            fontSize: 11,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${voice.ttsModel} / ${voice.voice}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: theme.textColor.withAlpha(95),
                            fontSize: 10,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.check_rounded,
                      size: 19,
                      color: theme.themeColor,
                    ),
                  ],
                ],
              ),
            );
          }).toList();
        },
        child: SizedBox(
          height: 50,
          width: 50,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.transparent,
            ),
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    kIsWeb
                        ? Icons.voice_over_off_rounded
                        : Icons.record_voice_over_rounded,
                    color: kIsWeb
                        ? theme.textColor.withAlpha(95)
                        : theme.textColor,
                    size: 20,
                  ),
                  if (!kIsWeb)
                    Positioned(
                      right: 3,
                      bottom: 4,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 13),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 3,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: theme.themeColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          selected.shortLabel.isNotEmpty
                              ? selected.shortLabel.characters.first
                                  .toUpperCase()
                              : 'V',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmmaSttSelectorButton extends ConsumerWidget {
  const _EmmaSttSelectorButton({
    required this.theme,
    required this.onSelected,
  });

  final ThemeColors theme;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(emmaSelectedSttProvider);

    return Tooltip(
      message: kIsWeb
          ? 'local_stt_unavailable_web'.tr
          : '${'emma_stt_tooltip'.tr} ${selected.label}',
      child: PopupMenuButton<EmmaSttPreset>(
        enabled: !kIsWeb,
        tooltip: 'select_stt_model'.tr,
        color: theme.adPopBackground,
        initialValue: selected,
        onSelected: (model) {
          final current = ref.read(emmaSelectedSttProvider);

          if (current.id == model.id) {
            onSelected();
            return;
          }

          ref.read(emmaSelectedSttProvider.notifier).state = model;

          unawaited(
            ref
                .read(localSuperbeeSttClientProvider)
                .loadModel(model.sttModel)
                .catchError((_) => <String, dynamic>{}),
          );

          onSelected();
        },
        itemBuilder: (context) {
          return emmaSttPresets.map((model) {
            final isSelected = model.id == selected.id;

            return PopupMenuItem<EmmaSttPreset>(
              value: model,
              child: Row(
                children: [
                  Icon(
                    Icons.graphic_eq_rounded,
                    size: 19,
                    color: isSelected ? theme.themeColor : theme.textColor,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          model.label,
                          style: TextStyle(
                            color: theme.textColor,
                            fontWeight:
                                isSelected ? FontWeight.w800 : FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          model.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: theme.textColor.withAlpha(145),
                            fontSize: 11,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${model.sttModel} / ${model.language}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: theme.textColor.withAlpha(95),
                            fontSize: 10,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.check_rounded,
                      size: 19,
                      color: theme.themeColor,
                    ),
                  ],
                ],
              ),
            );
          }).toList();
        },
        child: SizedBox(
          height: 50,
          width: 50,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.transparent,
            ),
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    kIsWeb
                        ? Icons.mic_off_rounded
                        : Icons.graphic_eq_rounded,
                    color: kIsWeb
                        ? theme.textColor.withAlpha(95)
                        : theme.textColor,
                    size: 20,
                  ),
                  if (!kIsWeb)
                    Positioned(
                      right: 3,
                      bottom: 4,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 13),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 3,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: theme.themeColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          selected.shortLabel.isNotEmpty
                              ? selected.shortLabel.characters.first
                                  .toUpperCase()
                              : 'S',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}