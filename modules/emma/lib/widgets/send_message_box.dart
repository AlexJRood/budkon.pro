import 'dart:async';

import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:emma/attachments/emma_attachment_controller.dart';
import 'package:emma/attachments/emma_attachment_strip.dart';
import 'package:emma/model/mention_models.dart';
import 'package:emma/provider/audio_provider.dart';
import 'package:emma/provider/emma_notifier.dart';
import 'package:emma/provider/emma_provider.dart';
import 'package:emma/provider/local_voice_model_status_provider.dart';
import 'package:emma/provider/mention_provider.dart';
import 'package:emma/provider/runtime_provider.dart';
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
import 'package:core/theme/text_field.dart';
import 'package:core/translate/language_provider.dart';
part 'send_message_box/send_message_box_focus.dart';
part 'send_message_box/send_message_box_drafts.dart';
part 'send_message_box/send_message_box_keyboard.dart';
part 'send_message_box/send_message_box_mentions.dart';
part 'send_message_box/send_message_box_voice.dart';
part 'send_message_box/send_message_box_send.dart';
part 'send_message_box/send_message_box_selectors.dart';

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

  /// Podświetlenie pola podczas przeciągania plików z pulpitu.
  bool _isDraggingFiles = false;

  late final VoidCallback _textChangedListener;
  late final bool Function(KeyEvent event) _keyboardHandler;

  ProviderSubscription<String>? _selectedRoomSubscription;
  ProviderSubscription<SttSessionState>? _sttStateSubscription;
  ProviderSubscription<ChatAiMessagesState>? _chatMessagesSubscription;

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

  bool _showMobileToolsOverlay = false;

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

    _textChangedListener = this._onTextChanged;
    _keyboardHandler = this._handleHardwareKeyEvent;

    _controller.addListener(_textChangedListener);

    _hasTypedText = _controller.text.trim().isNotEmpty;

    _focusNode = ref.read(emmaChatInputFocusNodeProvider);

    _selectedRoomSubscription = ref.listenManual<String>(
      selectedAiRoomProvider,
      (previous, next) {
        if (!_alive) return;
        this._handleSelectedRoomChanged(next);
      },
    );

    HardwareKeyboard.instance.addHandler(_keyboardHandler);

    _sttStateSubscription = ref.listenManual<SttSessionState>(
      sttSessionProvider(_sendMessageBoxSttSessionId),
      (previous, next) {
        if (!_alive) return;
        this._syncControllerFromStt(previous: previous, next: next);
        this._scheduleVoiceSilenceStop(next);
        this._maybeStartTalkAfterStt(previous: previous, next: next);
      },
    );

    _chatMessagesSubscription = ref.listenManual<ChatAiMessagesState>(
      chatAiMessageProvider,
      (previous, next) {
        if (!_alive) return;
        final wasLoading = previous?.isLoading ?? false;
        final finished = wasLoading && !next.isLoading;
        if (finished && _voiceTalkActive && !_continuousTalkMode) {
          this._setVoiceTalkActive(false);
        }
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_alive) return;

      this._requestFocus();

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

    if (shouldSaveDraftOnDispose) {
      this._saveDraftSnapshotLater(
        key: draftKeyBeforeDispose,
        text: draftTextBeforeDispose,
      );
    }

    _selectedRoomSubscription?.close();
    _sttStateSubscription?.close();
    _chatMessagesSubscription?.close();

    HardwareKeyboard.instance.removeHandler(_keyboardHandler);

    _controller.removeListener(_textChangedListener);
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final ui = ref.watch(sendMessageBoxUiProvider);
    final sttState = ref.watch(sttSessionProvider(_sendMessageBoxSttSessionId));
    final autoRead = ref.watch(emmaAutoReadMessagesProvider);

    final attachments = ref.watch(emmaAttachmentControllerProvider);
    final attachmentsUploading = attachments.any((a) => a.isUploading);
    final hasReadyAttachment = attachments.any((a) => a.isReady);

    final runtimeMode = ref.watch(emmaEffectiveRuntimeModeProvider);
    final localVoiceMode = !kIsWeb && runtimeMode == EmmaRuntimeMode.localVoice;

    final sttVoiceState = localVoiceMode
        ? ref.watch(emmaLocalSttModelStatusProvider).valueOrNull
        : null;

    final ttsVoiceState = localVoiceMode
        ? ref.watch(emmaLocalTtsModelStatusProvider).valueOrNull
        : null;

    final canUseLocalStt =
        localVoiceMode && this._isVoiceModelReady(sttVoiceState);

    final canUseLocalTts =
        localVoiceMode && this._isVoiceModelReady(ttsVoiceState);

    final canUseLocalTalk = canUseLocalStt && canUseLocalTts;

    final sttUnavailableTooltip = this._voiceUnavailableTooltip(
      label: 'stt_label'.tr,
      state: sttVoiceState,
      requireLocalVoiceMode: true,
      localVoiceMode: localVoiceMode,
    );

    final talkUnavailableTooltip = !localVoiceMode
        ? 'voice_talk_requires_local_voice'.tr
        : !canUseLocalStt
            ? this._voiceUnavailableTooltip(
                label: 'stt_label'.tr,
                state: sttVoiceState,
                requireLocalVoiceMode: true,
                localVoiceMode: localVoiceMode,
              )
            : !canUseLocalTts
                ? this._voiceUnavailableTooltip(
                    label: 'tts_label'.tr,
                    state: ttsVoiceState,
                    requireLocalVoiceMode: true,
                    localVoiceMode: localVoiceMode,
                  )
                : '';

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

    final canSend = !busy &&
        !attachmentsUploading &&
        (_controller.text.trim().isNotEmpty || hasReadyAttachment);

    if (_hasTypedText && _showMobileToolsOverlay) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _showMobileToolsOverlay) {
          setState(() => _showMobileToolsOverlay = false);
        }
      });
    }

    return DropTarget(
      onDragEntered: (_) {
        if (mounted) setState(() => _isDraggingFiles = true);
      },
      onDragExited: (_) {
        if (mounted) setState(() => _isDraggingFiles = false);
      },
      onDragDone: (detail) {
        if (mounted) setState(() => _isDraggingFiles = false);
        unawaited(_handleDroppedFiles(detail.files));
      },
      child: Padding(
      padding: widget.centerMode
        ? const EdgeInsets.symmetric(horizontal: 24, vertical: 0)
        : widget.isMobile
            ? const EdgeInsets.only(right: 12, left: 12, bottom: 12)
            : const EdgeInsets.only(right: 25, left: 25, bottom: 20),
      child: Container(
        constraints: BoxConstraints(
        minHeight: widget.isMobile ? 44 : 50,
        maxHeight: widget.isMobile ? 400 : 500, ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6.0),
          color: theme.textFieldColor.withAlpha((255 * 0.55).toInt()),
          border: _isDraggingFiles
              ? Border.all(color: const Color(0xFF9B6BFF), width: 2)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (attachments.isNotEmpty)
              EmmaAttachmentStrip(
                attachments: attachments,
                onRemove: (id) => ref
                    .read(emmaAttachmentControllerProvider.notifier)
                    .removeAttachment(id),
              ),
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
                          onTap: () => this._insertMention(item),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 4,
                            ),
                            child: Row(
                              children: [
                                _MentionAvatar(item: item),
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
                                  item.kind == MentionKind.tool
                                      ? 'komenda'.tr
                                      : item.kind == MentionKind.transaction
                                          ? 'transakcja'.tr
                                          : (isUser ? 'user'.tr : 'contact'.tr),
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
                if (widget.isMobile) ...[
                  SizedBox(
                    height: 50,
                    width: 50,
                    child: ElevatedButton(
                      style: elevatedButtonStyleRounded10,
                      onPressed: busy ? null : () {
                        setState(() {
                          _showMobileToolsOverlay = !_showMobileToolsOverlay;
                        });
                      },
                      child: Icon(
                        _showMobileToolsOverlay ? Icons.close : Icons.more_horiz,
                        color: theme.textColor,
                        size: 24,
                      ),
                    ),
                  ),
                ] else ...[
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: showUtilityButtons
                        ? Row(
                            key: const ValueKey('emma-input-tools-visible'),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Tooltip(
                                message: 'emma_attach_file'.tr,
                                child: SizedBox(
                                  height: 50,
                                  width: 50,
                                  child: ElevatedButton(
                                    style: elevatedButtonStyleRounded10,
                                    onPressed: busy
                                        ? null
                                        : () async {
                                            await ref
                                                .read(emmaAttachmentControllerProvider
                                                    .notifier)
                                                .pickFiles();
                                            this._requestFocusStable();
                                          },
                                    child: AppIcons.document(color: theme.textColor),
                                  ),
                                ),
                              ),
                              Tooltip(
                                message: sttState.isListening
                                    ? 'stop_recording_tooltip'.tr
                                    : canUseLocalStt
                                        ? 'dictate_message_tooltip'.tr
                                        : sttUnavailableTooltip,
                                child: SizedBox(
                                  height: 50,
                                  width: 50,
                                  child: ElevatedButton(
                                    style: elevatedButtonStyleRounded10,
                                    onPressed: baseBusy ||
                                            sttControlsBusy ||
                                            (!sttState.isBusy &&
                                                !canUseLocalStt)
                                        ? null
                                        : () => unawaited(
                                              this._toggleStt(busy: baseBusy),
                                            ),
                                    child: Icon(
                                      sttState.isListening && !_talkAfterStt
                                          ? Icons.stop
                                          : Icons.mic,
                                      color: canUseLocalStt || sttState.isBusy
                                          ? theme.textColor
                                          : theme.textColor.withAlpha(90),
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 50,
                                width: 50,
                                child: Tooltip(
                                  message: kIsWeb
                                      ? 'talk_unavailable_web'.tr
                                      : !canUseLocalTalk &&
                                              !sttState.isBusy &&
                                              !talkButtonActive
                                          ? talkUnavailableTooltip
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
                                    onPressed: kIsWeb ||
                                            (!canUseLocalTalk &&
                                                !sttState.isBusy &&
                                                !talkButtonActive)
                                        ? null
                                        : () => unawaited(
                                              this._toggleVoiceTalk(
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
                                          : canUseLocalTalk
                                              ? theme.textColor
                                              : theme.textColor.withAlpha(90),
                                      size: 21,
                                    ),
                                  ),
                                ),
                              ),
                              _EmmaSttSelectorButton(
                                theme: theme,
                                onSelected: this._requestFocusStable,
                              ),
                              Tooltip(
                                message: kIsWeb
                                    ? 'local_reading_unavailable_web'.tr
                                    : !canUseLocalTts
                                        ? this._voiceUnavailableTooltip(
                                            label: 'TTS',
                                            state: ttsVoiceState,
                                            requireLocalVoiceMode: true,
                                            localVoiceMode: localVoiceMode,
                                          )
                                        : autoRead
                                            ? 'auto_read_on'.tr
                                            :'auto_read_off'.tr,
                                child: SizedBox(
                                  height: 50,
                                  width: 50,
                                  child: ElevatedButton(
                                    style: elevatedButtonStyleRounded10,
                                    onPressed: kIsWeb || !canUseLocalTts
                                        ? null
                                        : this._toggleAutoRead,
                                    child: Icon(
                                      kIsWeb
                                          ? Icons.volume_off_rounded
                                          : autoRead
                                              ? Icons.volume_up_rounded
                                              : Icons.volume_off_rounded,
                                      color: autoRead && !kIsWeb && canUseLocalTts
                                          ? theme.themeColor
                                          : canUseLocalTts
                                              ? theme.textColor
                                              : theme.textColor.withAlpha(90),
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                              _EmmaVoiceSelectorButton(
                                theme: theme,
                                onSelected: this._requestFocusStable,
                              ),
                            ],
                          )
                        : const SizedBox(
                            key: ValueKey('emma-input-tools-hidden'),
                            width: 0,
                            height: 50,
                          ),
                  ),
                ],
                Expanded(
                  child: CallbackShortcuts(
                    bindings: <ShortcutActivator, VoidCallback>{
                      const SingleActivator(LogicalKeyboardKey.keyV, control: true):
                          () => unawaited(_handlePaste()),
                      const SingleActivator(LogicalKeyboardKey.keyV, meta: true):
                          () => unawaited(_handlePaste()),
                    },
                    child: CoreTextField(
                    label: '',
                    focusNode: _focusNode,
                    controller: _controller,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    minLines: 1,
                    maxLines: widget.isMobile ? 8 : 15,
                    readOnly: textInputReadOnly,
                    fillColor: Colors.transparent,
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
                                                : 'emma_thinking'.tr)
                                            : 'write_message'.tr,
                  ),
                  ),
                ),
                SizedBox(
                  height: 50,
                  width: 50,
                  child: ElevatedButton(
                    style: elevatedButtonStyleRounded10,
                    onPressed: canSend
                        ? () => unawaited(this._sendCurrentMessage())
                        : null,
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
            // Mobile tools overlay
            if (widget.isMobile && _showMobileToolsOverlay && !busy)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.dashboardContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.textColor.withAlpha(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(50),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    SizedBox(
                      height: 45,
                      width: 45,
                      child: ElevatedButton(
                        style: elevatedButtonStyleRounded10,
                        onPressed: () async {
                          setState(() => _showMobileToolsOverlay = false);
                          await ref
                              .read(emmaAttachmentControllerProvider.notifier)
                              .pickFiles();
                          this._requestFocusStable();
                        },
                        child: AppIcons.document(color: theme.textColor),
                      ),
                    ),
                    // Mic button
                    Tooltip(
                      message: sttState.isListening
                          ? 'stop_recording_tooltip'.tr
                          : canUseLocalStt
                              ? 'dictate_message_tooltip'.tr
                              : sttUnavailableTooltip,
                      child: SizedBox(
                        height: 45,
                        width: 45,
                        child: ElevatedButton(
                          style: elevatedButtonStyleRounded10,
                          onPressed: baseBusy ||
                                  sttControlsBusy ||
                                  (!sttState.isBusy && !canUseLocalStt)
                              ? null
                              : () {
                                  setState(() => _showMobileToolsOverlay = false);
                                  unawaited(this._toggleStt(busy: baseBusy));
                                },
                          child: Icon(
                            sttState.isListening && !_talkAfterStt
                                ? Icons.stop
                                : Icons.mic,
                            color: canUseLocalStt || sttState.isBusy
                                ? theme.textColor
                                : theme.textColor.withAlpha(90),
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    // Talk button
                    SizedBox(
                      height: 45,
                      width: 45,
                      child: Tooltip(
                        message: kIsWeb
                            ? 'talk_unavailable_web'.tr
                            : !canUseLocalTalk && !sttState.isBusy && !talkButtonActive
                                ? talkUnavailableTooltip
                                : sttState.isListening
                                    ? 'finish_speech_and_send'.tr
                                    : _continuousTalkMode && !chatState.isLoading && !_voiceTalkActive
                                        ? 'end_talk_mode'.tr
                                        : talkButtonActive
                                            ? 'interrupt_emma_and_speak'.tr
                                            : 'talk_with_emma_voice'.tr,
                        child: ElevatedButton(
                          style: elevatedButtonStyleRounded10,
                          onPressed: kIsWeb || (!canUseLocalTalk && !sttState.isBusy && !talkButtonActive)
                              ? null
                              : () {
                                  setState(() => _showMobileToolsOverlay = false);
                                  unawaited(this._toggleVoiceTalk(baseBusy: baseBusy));
                                },
                          child: Icon(
                            sttState.isListening
                                ? Icons.stop_circle_rounded
                                : _continuousTalkMode
                                    ? Icons.forum_rounded
                                    : Icons.hearing_rounded,
                            color: talkButtonActive
                                ? theme.themeColor
                                : canUseLocalTalk
                                    ? theme.textColor
                                    : theme.textColor.withAlpha(90),
                            size: 21,
                          ),
                        ),
                      ),
                    ),
                    _EmmaSttSelectorButton(
                      theme: theme,
                      onSelected: () {
                        setState(() => _showMobileToolsOverlay = false);
                        this._requestFocusStable();
                      },
                    ),
                    Tooltip(
                      message: kIsWeb
                          ? 'local_reading_unavailable_web'.tr
                          : !canUseLocalTts
                              ? this._voiceUnavailableTooltip(
                                  label: 'TTS',
                                  state: ttsVoiceState,
                                  requireLocalVoiceMode: true,
                                  localVoiceMode: localVoiceMode,
                                )
                              : autoRead
                                  ? 'auto_read_on'.tr
                                  : 'auto_read_off'.tr,
                      child: SizedBox(
                        height: 45,
                        width: 45,
                        child: ElevatedButton(
                          style: elevatedButtonStyleRounded10,
                          onPressed: kIsWeb || !canUseLocalTts
                              ? null
                              : () {
                                  setState(() => _showMobileToolsOverlay = false);
                                  this._toggleAutoRead();
                                },
                          child: Icon(
                            kIsWeb
                                ? Icons.volume_off_rounded
                                : autoRead
                                    ? Icons.volume_up_rounded
                                    : Icons.volume_off_rounded,
                            color: autoRead && !kIsWeb && canUseLocalTts
                                ? theme.themeColor
                                : canUseLocalTts
                                    ? theme.textColor
                                    : theme.textColor.withAlpha(90),
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    _EmmaVoiceSelectorButton(
                      theme: theme,
                      onSelected: () {
                        setState(() => _showMobileToolsOverlay = false);
                        this._requestFocusStable();
                      },
                    ),
                  ],
                ),
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
      ),
    );
  }
}

class _MentionAvatar extends ConsumerWidget {
  final MentionItem item;

  const _MentionAvatar({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final url = item.avatarUrl;
    final initials = item.displayName.isNotEmpty
        ? item.displayName[0].toUpperCase()
        : '?';

    // Slash-komenda → ikonka ✨ zamiast inicjałów.
    if (item.kind == MentionKind.tool) {
      return const CircleAvatar(
        radius: 14,
        backgroundColor: Color(0x339B6BFF),
        child: Icon(Icons.auto_awesome, size: 15, color: Color(0xFF9B6BFF)),
      );
    }

    if (url != null && url.isNotEmpty) {
      return CircleAvatar(
        radius: 14,
        backgroundImage: NetworkImage(url),
        onBackgroundImageError: (_, __) {},
        child: null,
      );
    }

    return CircleAvatar(
      radius: 14,
      backgroundColor: theme.themeColor.withAlpha(40),
      child: Text(
        initials,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: theme.themeColor,
        ),
      ),
    );
  }
}