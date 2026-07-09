import 'dart:async';

import 'package:emma/model/massage.dart';
import 'package:emma/provider/audio_provider.dart';
import 'package:emma/provider/emma_notifier.dart';
import 'package:emma/provider/emma_provider.dart';
import 'package:emma/provider/send_message_box_provider.dart';
import 'package:emma/widgets/avatar_widget.dart';
import 'package:emma/widgets/message_bubble.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/export.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/lottie.dart';

String sanitizeFlutterTextForUi(String value) {
  if (value.isEmpty) return value;

  final buffer = StringBuffer();
  final units = value.codeUnits;

  var i = 0;

  while (i < units.length) {
    final unit = units[i];

    final isHighSurrogate = unit >= 0xD800 && unit <= 0xDBFF;
    final isLowSurrogate = unit >= 0xDC00 && unit <= 0xDFFF;

    if (isHighSurrogate) {
      if (i + 1 < units.length) {
        final next = units[i + 1];
        final nextIsLow = next >= 0xDC00 && next <= 0xDFFF;

        if (nextIsLow) {
          buffer.write(String.fromCharCodes([unit, next]));
          i += 2;
          continue;
        }
      }

      buffer.write('\uFFFD');
      i += 1;
      continue;
    }

    if (isLowSurrogate) {
      buffer.write('\uFFFD');
      i += 1;
      continue;
    }

    if (unit == 0) {
      i += 1;
      continue;
    }

    if (unit < 32 && unit != 9 && unit != 10 && unit != 13) {
      buffer.write(' ');
      i += 1;
      continue;
    }

    buffer.writeCharCode(unit);
    i += 1;
  }

  return buffer.toString();
}

class MessageListView extends ConsumerStatefulWidget {
  final bool isMobile;

  const MessageListView({
    super.key,
    this.isMobile = false,
  });

  @override
  ConsumerState<MessageListView> createState() => _MessageListViewState();
}

class _MessageListViewState extends ConsumerState<MessageListView> {
  final ScrollController _scrollController = ScrollController();

  bool _isLoadingMore = false;
  final Set<int> _autoReadDoneIds = <int>{};
  double _lastScrollPixels = 0;

  bool _isNearBottom() {
    if (!_scrollController.hasClients) return true;

    final pos = _scrollController.position;
    const threshold = 160.0;

    return pos.pixels <= (pos.minScrollExtent + threshold);
  }

  void _focusInput() {
    try {
      final focusNode = ref.read(emmaChatInputFocusNodeProvider);

      focusNode.requestFocus();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        focusNode.requestFocus();
      });

      Future.delayed(const Duration(milliseconds: 60), () {
        if (!mounted) return;
        focusNode.requestFocus();
      });
    } catch (_) {}
  }

  Widget _focusableConversationArea({
    required Widget child,
  }) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _focusInput(),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _focusInput,
        child: child,
      ),
    );
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_scrollController.hasClients) return;

    final target = _scrollController.position.minScrollExtent;

    if (animated) {
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(target);
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoadingMore) return;

    final pos = _scrollController.position;
    const threshold = 120.0;

    if (pos.pixels > _lastScrollPixels + 8) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
    _lastScrollPixels = pos.pixels;

    if (pos.pixels >= pos.maxScrollExtent - threshold) {
      _loadOlderMessages();
    }
  }

  Future<void> _loadOlderMessages() async {
    if (_isLoadingMore) return;

    setState(() => _isLoadingMore = true);

    try {
      await ref.read(chatAiMessageProvider.notifier).loadOlderMessages();
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('Error loading older Emma messages: $e\n$stack');
      }
    } finally {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  bool _shouldRenderMessage(ChatMessageDto msg) {
    if (msg.isUser) return true;

    final content = msg.content.trim();
    if (content.isNotEmpty) return true;

    final blocks = msg.meta['blocks'];
    if (blocks is List && blocks.isNotEmpty) {
      return true;
    }

    final hasAudio = msg.meta['has_audio'] == true;
    if (hasAudio) return true;

    final streamState = (msg.meta['stream_state'] ?? '').toString();
    final streaming = msg.meta['streaming'] == true;

    if (streaming ||
        streamState == 'started' ||
        streamState == 'streaming' ||
        streamState == 'waiting_local_engine') {
      return false;
    }

    return false;
  }

  void _maybeAutoReadAssistantMessage(ChatAiMessagesState next) {
    if (kIsWeb) return;

    final autoRead = ref.read(emmaAutoReadMessagesProvider);
    if (!autoRead) return;

    final candidates = next.messages
        .where((m) => !m.isUser && m.id > 0 && m.content.trim().isNotEmpty)
        .toList();

    if (candidates.isEmpty) return;

    candidates.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final latest = candidates.last;

    if (_autoReadDoneIds.contains(latest.id)) return;

    final streaming = latest.meta['streaming'] == true;
    final streamState = (latest.meta['stream_state'] ?? '').toString();

    if (streaming || streamState == 'streaming' || streamState == 'started') {
      return;
    }

    _autoReadDoneIds.add(latest.id);

    unawaited(
      ref.read(emmaAudioMessageProvider.notifier).readMessage(
            messageId: latest.id,
            text: latest.content,
            meta: latest.meta,
          ),
    );
  }

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_onScroll);

    ref.listenManual<ChatAiMessagesState>(
      chatAiMessageProvider,
      (prev, next) {
        final prevLen = prev?.messages.length ?? 0;
        final nextLen = next.messages.length;

        final activityChanged =
            prev?.activityTitle != next.activityTitle ||
                prev?.activityDetail != next.activityDetail ||
                prev?.isLoading != next.isLoading;

        if (nextLen > prevLen || activityChanged) {
          if (_isNearBottom()) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _scrollToBottom(animated: true);
            });
          }
        }

        if (!mounted) return;
        _maybeAutoReadAssistantMessage(next);
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollToBottom(animated: false);
      _focusInput();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ai = ref.watch(chatAiMessageProvider);
    final theme = ref.watch(themeColorsProvider);

    final renderableMessages = ai.messages.where(_shouldRenderMessage).toList();

    if (renderableMessages.isEmpty && !ai.isLoading) {
      return _focusableConversationArea(
        child: Center(
          child: Text(
            'There are no messages'.tr,
            style: TextStyle(
              fontSize: 22,
              color: theme.textColor,
            ),
          ),
        ),
      );
    }

    final messages = renderableMessages.reversed.toList();

    // Gdy status jest już renderowany jako blok w wiadomości (activityInline),
    // nie pokazujemy pływającego bąbelka — inaczej ten sam komunikat dubluje się.
    // Błąd wysyłki wyklucza wskaźnik pracy — pokazujemy jedno albo drugie.
    final bool showError = ai.hasError;

    final bool showThinkingBubble = !showError &&
        (ai.isLoading || ai.thinking != null || ai.activityTitle != null) &&
            !ai.activityInline;

    final int leadingCount = (showError || showThinkingBubble) ? 1 : 0;

    final int itemCount =
        messages.length + leadingCount + (_isLoadingMore ? 1 : 0);

    final int latestAiIndex = messages.indexWhere((m) => !m.isUser);

    return _focusableConversationArea(
      child: ListView.builder(
        controller: _scrollController,
        addAutomaticKeepAlives: false,
        cacheExtent: 300.0,
        reverse: true,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
        padding: EdgeInsets.only(
          bottom: widget.isMobile ? 85 : 10,
          right: widget.isMobile ? 6 : 10,
          left: widget.isMobile ? 6 : 10,
          top: 10,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (showError && index == 0) {
            return Padding(
              padding: EdgeInsets.only(
                top: 4,
                left: 4,
                right: widget.isMobile ? 24 : 80,
                bottom: 8,
              ),
              child: _EmmaSendErrorBanner(
                message: ai.errorText ?? '',
                canRetry: ai.canRetry,
                onRetry: () => ref
                    .read(chatAiMessageProvider.notifier)
                    .retryLastMessage(),
                onDismiss: () => ref
                    .read(chatAiMessageProvider.notifier)
                    .dismissSendError(),
              ),
            );
          }

          if (showThinkingBubble && index == 0) {
            return Padding(
              padding: EdgeInsets.only(
                top: 4,
                left: 4,
                right: widget.isMobile ? 24 : 80,
                bottom: 8,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Avatar(),
                  const SizedBox(width: 8),
                  _EmmaThinkingBubble(
                    theme,
                    thinking: ai.thinking,
                    activityTitle: ai.activityTitle,
                    activityDetail: ai.activityDetail,
                  ),
                ],
              ),
            );
          }

          final msgStartIndex = leadingCount;
          final msgEndIndex = msgStartIndex + messages.length;

          if (index >= msgStartIndex && index < msgEndIndex) {
            final localIndex = index - msgStartIndex;
            final msg = messages[localIndex];
            final isUser = msg.isUser;

            final shouldAnimateAi =
                !isUser && localIndex == latestAiIndex && !msg.isSeen;

            return _MessageWithActions(
              message: msg,
              isMobile: widget.isMobile,
              animateAi: shouldAnimateAi,
            );
          }

          if (_isLoadingMore && index == itemCount - 1) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Center(
                child: SizedBox(
                  height: 26,
                  width: 26,
                  child: AppLottie.loading(),
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _MessageWithActions extends ConsumerWidget {
  const _MessageWithActions({
    required this.message,
    required this.isMobile,
    required this.animateAi,
  });

  final ChatMessageDto message;
  final bool isMobile;
  final bool animateAi;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUser = message.isUser;

    return Padding(
      padding: EdgeInsets.only(
        bottom: isMobile ? 8 : 6,
      ),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          MessageBubble(
            content: sanitizeFlutterTextForUi(message.content),
            timestamp: message.createdAt,
            isUser: isUser,
            messageId: message.id.toString(),
            isMobile: isMobile,
            meta: message.meta,
            animateAi: animateAi,
          ),
          if (message.id > 0 && message.content.trim().isNotEmpty)
            _MessageActionsBar(
              message: message,
              isMobile: isMobile,
            ),
        ],
      ),
    );
  }
}

class _MessageActionsBar extends ConsumerStatefulWidget {
  const _MessageActionsBar({
    required this.message,
    required this.isMobile,
  });

  final ChatMessageDto message;
  final bool isMobile;

  @override
  ConsumerState<_MessageActionsBar> createState() => _MessageActionsBarState();
}

class _MessageActionsBarState extends ConsumerState<_MessageActionsBar> {
  bool _isCopySuccess = false;
  Timer? _copyFeedbackTimer;

  void _handleCopy() {
    // Copy the text
    Clipboard.setData(ClipboardData(text: widget.message.content));
    
    // Change icon to checkmark
    setState(() {
      _isCopySuccess = true;
    });

    // Reset back to copy icon after 1.5 seconds
    _copyFeedbackTimer?.cancel();
    _copyFeedbackTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isCopySuccess = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _copyFeedbackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final audio = ref.watch(emmaAudioMessageProvider);

    final isPlayingThis = audio.isBusy && audio.playingMessageId == widget.message.id;

    final disabledAudio = kIsWeb;

    return Padding(
      padding: EdgeInsets.only(
        left: widget.message.isUser ? 0 : 54,
        right: widget.message.isUser ? 12 : 0,
        top: 3,
        bottom: 2,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        reverse: widget.message.isUser,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TinyActionButton(
              tooltip: disabledAudio
                  ? 'local_reading_unavailable_web'.tr
                  : isPlayingThis
                      ? 'stop_reading_tooltip'.tr
                      : 'read_message_tooltip'.tr,
              icon: disabledAudio
                  ? Icons.volume_off_rounded
                  : isPlayingThis
                      ? Icons.stop_rounded
                      : Icons.volume_up_rounded,
              color: isPlayingThis ? theme.themeColor : theme.textColor,
              onTap: disabledAudio
                  ? null
                  : () {
                      if (isPlayingThis) {
                        unawaited(
                          ref.read(emmaAudioMessageProvider.notifier).stop(),
                        );
                      } else {
                        unawaited(
                          ref.read(emmaAudioMessageProvider.notifier).readMessage(
                                messageId: widget.message.id,
                                text: widget.message.content,
                                meta: widget.message.meta,
                              ),
                        );
                      }
                    },
            ),
            const SizedBox(width: 4),
            _TinyActionButton(
              tooltip: _isCopySuccess ? 'copied_tooltip'.tr : 'copy_tooltip'.tr,
              icon: _isCopySuccess ? Icons.check_rounded : Icons.copy_rounded,
              color: theme.textColor,
              onTap: _handleCopy,
            ),
            if (!widget.message.isUser) ...[
              const SizedBox(width: 4),
              _TinyActionButton(
                tooltip: 'like_tooltip'.tr,
                icon: Icons.thumb_up_alt_outlined,
                color: widget.message.likesCount > 0 ? theme.themeColor : theme.textColor,
                label: widget.message.likesCount > 0 ? widget.message.likesCount.toString() : '',
                onTap: () {
                  unawaited(
                    ref.read(chatAiMessageProvider.notifier).reactMessage(
                          messageId: widget.message.id,
                          value: 'up',
                        ),
                  );
                },
              ),
              const SizedBox(width: 4),
              _TinyActionButton(
                tooltip: 'dislike_tooltip'.tr,
                icon: Icons.thumb_down_alt_outlined,
                color: widget.message.dislikesCount > 0
                    ? Colors.redAccent
                    : theme.textColor,
                label: widget.message.dislikesCount > 0
                    ? widget.message.dislikesCount.toString()
                    : '',
                onTap: () {
                  unawaited(
                    ref.read(chatAiMessageProvider.notifier).reactMessage(
                          messageId: widget.message.id,
                          value: 'down',
                        ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TinyActionButton extends StatelessWidget {
  const _TinyActionButton({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onTap,
    this.label = '',
  });

  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    final child = InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.42 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(28),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.white.withAlpha(12),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: color.withAlpha(220),
              ),
              if (label.trim().isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: color.withAlpha(220),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    return Tooltip(
      message: tooltip,
      child: child,
    );
  }
}

class _EmmaThinkingBubble extends StatelessWidget {
  final ThemeColors theme;
  final dynamic thinking;
  final String? activityTitle;
  final String? activityDetail;

  const _EmmaThinkingBubble(
    this.theme, {
    this.thinking,
    this.activityTitle,
    this.activityDetail,
  });

  @override
  Widget build(BuildContext context) {
    String? headline = activityTitle;
    String? detail = activityDetail;

    try {
      final t = thinking;

      if (t != null) {
        final thinkingHeadline = (t.title ?? t.label ?? '').toString().trim();
        final thinkingDetail = (t.summary ?? t.text ?? '').toString().trim();

        if ((headline ?? '').trim().isEmpty && thinkingHeadline.isNotEmpty) {
          headline = thinkingHeadline;
        }

        if ((detail ?? '').trim().isEmpty && thinkingDetail.isNotEmpty) {
          detail = thinkingDetail;
        }
      }
    } catch (_) {}

    final safeHeadline =
        (headline != null && headline!.trim().isNotEmpty)
            ? headline!.trim()
            :  'emma_is_working'.tr;

    final safeDetail = (detail ?? '').trim();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(150),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withAlpha(14),
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: AppLottie.loading(),
            ),
            const SizedBox(width: 9),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    safeHeadline,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (safeDetail.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        safeDetail,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                          height: 1.35,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
/// Widoczny, akcjonowalny błąd wysyłki.
///
/// Wcześniej porażka tylko czyściła stan (albo migała etykietą na 3s), więc
/// użytkownik nie wiedział, czy Emma myśli, czy coś się wywaliło.
class _EmmaSendErrorBanner extends StatelessWidget {
  final String message;
  final bool canRetry;
  final VoidCallback onRetry;
  final VoidCallback onDismiss;

  const _EmmaSendErrorBanner({
    required this.message,
    required this.canRetry,
    required this.onRetry,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFE5484D);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withAlpha(90)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, color: accent, size: 18),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              message,
              style: const TextStyle(
                color: accent,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (canRetry) ...[
            const SizedBox(width: 12),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text('emma_retry'.tr),
              style: TextButton.styleFrom(
                foregroundColor: accent,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
          IconButton(
            onPressed: onDismiss,
            icon: const Icon(Icons.close_rounded, size: 16),
            color: accent.withAlpha(180),
            tooltip: 'emma_dismiss'.tr,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
