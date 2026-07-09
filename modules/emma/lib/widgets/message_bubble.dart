import 'dart:async';
import 'dart:convert';

import 'package:emma/blocks/blocks.dart';
import 'package:emma/provider/emma_notifier.dart';
import 'package:emma/widgets/action_icons_widget.dart';
import 'package:emma/widgets/avatar_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/platforms/html_utils_stub.dart'
    if (dart.library.html) 'package:core/platform/platforms/html_utils_web.dart';
import 'package:core/platform/url.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/icons.dart';
import 'package:url_launcher/url_launcher.dart';

class MessageEditingNotifier extends StateNotifier<bool> {
  MessageEditingNotifier() : super(false);

  void startEditing() => state = true;

  void stopEditing() => state = false;
}

final messageEditingProvider =
    StateNotifierProvider.family<MessageEditingNotifier, bool, String>(
  (ref, messageId) => MessageEditingNotifier(),
);

class MessageBubble extends ConsumerWidget {
  final String content;
  final DateTime timestamp;
  final bool isUser;
  final String messageId;
  final bool isMobile;
  final Map<String, dynamic>? meta;

  /// Whether AI bubble should use typewriter animation.
  final bool animateAi;

  const MessageBubble({
    super.key,
    required this.content,
    required this.timestamp,
    required this.isUser,
    required this.messageId,
    this.isMobile = false,
    this.meta,
    this.animateAi = false,
  });

  double _maxBubbleWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    // Same behavior as normal chat bubbles.
    return isMobile ? width / 1.4 : width / 3;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final isEditing = ref.watch(messageEditingProvider(messageId));
    final maxBubbleWidth = _maxBubbleWidth(context);

    final customBlocks = parseBlocksFromMeta(meta);
    final richBlocks = _extractEmmaRichBlocks(meta);

    // Mentions map: tag -> display
    final mentionMap = <String, String>{};
    final metaMentions = meta?['mentions'];
    if (metaMentions is List) {
      for (final m in metaMentions) {
        if (m is Map && m['tag'] is String && m['display'] is String) {
          mentionMap[m['tag'] as String] = m['display'] as String;
        }
      }
    }

    final rawText = content;
    final decodedTextForEditing = _decodeMentions(rawText, mentionMap);
    final editingController = TextEditingController(text: decodedTextForEditing);

    final visibleRichBlocks = _dedupeBlocksAgainstText(
      rawText: rawText,
      blocks: richBlocks,
    );

    final hasText = rawText.trim().isNotEmpty;
    final hasRichBlocks = visibleRichBlocks.isNotEmpty;
    final shouldShowMainBubble = isEditing || hasText || hasRichBlocks;

    final isStandaloneRich =
        !isEditing && !hasText && _isStandaloneRichMessage(visibleRichBlocks);

    final numericId = int.tryParse(messageId) ?? 0;
    final canRetract = isUser && numericId > 0;

    void onLongPress() {
      if (!canRetract) return;
      showModalBottomSheet<void>(
        context: context,
        builder: (_) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.undo),
                title: Text('retract_message'.tr),
                onTap: () async {
                  Navigator.of(context).pop();
                  await ref
                      .read(chatAiMessageProvider.notifier)
                      .retractMessage(numericId);
                },
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onLongPress: canRetract ? onLongPress : null,
      child: Row(
      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isUser) ...[
          const Center(child: Avatar()),
          const SizedBox(width: 8),
        ],

        // if (isUser && !isEditing) ...[
        //   IconButton(
        //     icon: AppIcons.pencil(
        //       color: Colors.white,
        //       height: 20,
        //       width: 20,
        //     ),
        //     onPressed: () {
        //       ref.read(messageEditingProvider(messageId).notifier).startEditing();
        //     },
        //   ),
        //   const SizedBox(width: 4),
        // ],

        Flexible(
          child: Align(
            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (shouldShowMainBubble)
                  isStandaloneRich
                      ? _StandaloneRichBubble(
                          block: visibleRichBlocks.first,
                          isUser: isUser,
                          isMobile: isMobile,
                          maxWidth: maxBubbleWidth,
                          timestamp: timestamp,
                        )
                      : _TextAndBlocksBubble(
                          rawText: rawText,
                          richBlocks: visibleRichBlocks,
                          mentionMap: mentionMap,
                          timestamp: timestamp,
                          isUser: isUser,
                          isMobile: isMobile,
                          maxWidth: maxBubbleWidth,
                          theme: theme,
                          animateAi: animateAi,
                          isEditing: isEditing,
                          editingController: editingController,
                          onCancelEditing: () {
                            ref
                                .read(messageEditingProvider(messageId).notifier)
                                .stopEditing();
                          },
                          onSaveEditing: () async {
                            // TODO: connect editing API when ready.
                          },
                        ),

                // Keep old Emma custom blocks support.
                //
                // If meta['blocks'] contained normal chat-like blocks, we already rendered
                // them above, so we avoid duplicating them through EmmaBlocksSection.
                if (!hasRichBlocks && !isUser && customBlocks.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: EmmaBlocksSection(
                      blocks: customBlocks,
                      maxWidth: maxBubbleWidth,
                      messageId: messageId,
                    ),
                  ),
              ],
            ),
          ),
        ),

        // if (!isUser) ...[
        //   const SizedBox(width: 6),
        //   const ActionIcons(),
        // ],
      ],
      ),
    );
  }

  String _decodeMentions(
    String raw,
    Map<String, String> mentionMap,
  ) {
    var decoded = raw;
    mentionMap.forEach((tag, display) {
      decoded = decoded.replaceAll(tag, '@$display');
    });
    return decoded;
  }
}

class _TextAndBlocksBubble extends StatelessWidget {
  const _TextAndBlocksBubble({
    required this.rawText,
    required this.richBlocks,
    required this.mentionMap,
    required this.timestamp,
    required this.isUser,
    required this.isMobile,
    required this.maxWidth,
    required this.theme,
    required this.animateAi,
    required this.isEditing,
    required this.editingController,
    required this.onCancelEditing,
    required this.onSaveEditing,
  });

  final String rawText;
  final List<_EmmaRichBlock> richBlocks;
  final Map<String, String> mentionMap;
  final DateTime timestamp;
  final bool isUser;
  final bool isMobile;
  final double maxWidth;
  final ThemeColors theme;
  final bool animateAi;
  final bool isEditing;
  final TextEditingController editingController;
  final VoidCallback onCancelEditing;
  final Future<void> Function() onSaveEditing;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: maxWidth,
        minWidth: 80,
      ),
      margin: const EdgeInsets.symmetric(
        vertical: 4.0,
        horizontal: 12.0,
      ),
      decoration: BoxDecoration(
        color: isUser
            ? theme.themeColor.withAlpha((255 * 0.75).toInt())
            : theme.textFieldColor.withAlpha((255 * 0.75).toInt()),
        borderRadius: const BorderRadius.all(Radius.circular(12.0)),
      ),
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              12,
              12,
              12,
              isEditing ? 10 : 26,
            ),
            child: isEditing
                ? _EditingMessageContent(
                    controller: editingController,
                    onCancel: onCancelEditing,
                    onSave: onSaveEditing,
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (rawText.trim().isNotEmpty)
                        isUser
                            ? buildRichTextWithMentionsAndLinks(
                                rawText,
                                mentionMap,
                                textColor: Colors.white,
                                mentionColor: Colors.cyanAccent,
                                linkColor: Colors.white,
                                fontSize: isMobile ? 14 : 16,
                              )
                            : (animateAi
                                ? _AnimatedAiText(
                                    raw: rawText,
                                    mentionMap: mentionMap,
                                    textColor: theme.textColor,
                                    mentionColor: Colors.cyanAccent,
                                    linkColor: theme.themeColor,
                                    fontSize: isMobile ? 14 : 16,
                                  )
                                : buildRichTextWithMentionsAndLinks(
                                    rawText,
                                    mentionMap,
                                    textColor: theme.textColor,
                                    mentionColor: Colors.cyanAccent,
                                    linkColor: theme.themeColor,
                                    fontSize: isMobile ? 14 : 16,
                                  )),
                      if (rawText.trim().isNotEmpty && richBlocks.isNotEmpty)
                        const SizedBox(height: 10),
                      for (int i = 0; i < richBlocks.length; i++) ...[
                        _EmmaRichBlockRenderer(
                          block: richBlocks[i],
                          isUser: isUser,
                          isMobile: isMobile,
                        ),
                        if (i < richBlocks.length - 1)
                          const SizedBox(height: 10),
                      ],
                    ],
                  ),
          ),
          if (!isEditing)
            Positioned(
              bottom: 8,
              right: isUser ? 10 : null,
              left: isUser ? null : 10,
              child: Padding(
                padding: EdgeInsets.only(
                  right: isUser ? 4 : 0,
                  left: isUser ? 0 : 4,
                ),
                child: Text(
                  "${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}",
                  style: TextStyle(
                    color: (isUser ? Colors.white : theme.textColor)
                        .withAlpha((255 * 0.35).toInt()),
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StandaloneRichBubble extends ConsumerWidget {
  const _StandaloneRichBubble({
    required this.block,
    required this.isUser,
    required this.isMobile,
    required this.maxWidth,
    required this.timestamp,
  });

  final _EmmaRichBlock block;
  final bool isUser;
  final bool isMobile;
  final double maxWidth;
  final DateTime timestamp;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 4.0,
        horizontal: 12.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              minWidth: 80,
            ),
            child: _EmmaRichBlockRenderer(
              block: block,
              isUser: isUser,
              isMobile: isMobile,
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              "${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}",
              style: TextStyle(
                color: (isUser ? Colors.white : theme.textColor)
                    .withAlpha((255 * 0.35).toInt()),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditingMessageContent extends StatelessWidget {
  const _EditingMessageContent({
    required this.controller,
    required this.onCancel,
    required this.onSave,
  });

  final TextEditingController controller;
  final VoidCallback onCancel;
  final Future<void> Function() onSave;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          maxLines: null,
          decoration: InputDecoration(
            hintText: "Edit your message...".tr,
            hintStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: Colors.transparent,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: onCancel,
              child: Text(
                'Cancel'.tr,
                style: const TextStyle(color: Colors.red),
              ),
            ),
            TextButton(
              onPressed: () async => onSave(),
              child: Text(
                'Save'.tr,
                style: const TextStyle(color: Colors.green),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// ---------- Animated AI text ----------

class _AnimatedAiText extends StatefulWidget {
  final String raw;
  final Map<String, String> mentionMap;
  final Color textColor;
  final Color mentionColor;
  final Color linkColor;
  final double fontSize;

  const _AnimatedAiText({
    required this.raw,
    required this.mentionMap,
    required this.textColor,
    required this.mentionColor,
    required this.linkColor,
    required this.fontSize,
  });

  @override
  State<_AnimatedAiText> createState() => _AnimatedAiTextState();
}

class _AnimatedAiTextState extends State<_AnimatedAiText> {
  String _visible = '';
  Timer? _timer;

  late final int _stepSize;

  @override
  void initState() {
    super.initState();

    if (widget.raw.isEmpty) return;

    final length = widget.raw.length;
    if (length > 2000) {
      _stepSize = 8;
    } else if (length > 1000) {
      _stepSize = 6;
    } else if (length > 400) {
      _stepSize = 4;
    } else if (length > 150) {
      _stepSize = 3;
    } else {
      _stepSize = 2;
    }

    const step = Duration(milliseconds: 10);

    _visible = '';

    _timer = Timer.periodic(step, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_visible.length >= widget.raw.length) {
        timer.cancel();
        return;
      }

      setState(() {
        final nextLen = _visible.length + _stepSize;
        final safeNextLen =
            nextLen > widget.raw.length ? widget.raw.length : nextLen;
        _visible = widget.raw.substring(0, safeNextLen);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textToShow =
        _visible.isEmpty && widget.raw.isNotEmpty ? widget.raw[0] : _visible;

    return buildRichTextWithMentionsAndLinks(
      textToShow,
      widget.mentionMap,
      textColor: widget.textColor,
      mentionColor: widget.mentionColor,
      linkColor: widget.linkColor,
      fontSize: widget.fontSize,
    );
  }
}

/// ---------- Rich blocks support ----------

enum _EmmaRichBlockType {
  text,
  link,
  entityShare,
  image,
  video,
  audio,
  file,
  pdf,
  systemEvent,
  unknown,
}

class _EmmaRichBlock {
  const _EmmaRichBlock({
    required this.type,
    this.text = '',
    this.url = '',
    this.name = '',
    this.extension = '',
    this.payload = const <String, dynamic>{},
    this.preview,
  });

  final _EmmaRichBlockType type;
  final String text;
  final String url;
  final String name;
  final String extension;
  final Map<String, dynamic> payload;
  final _EmmaEntityPreview? preview;
}

class _EmmaEntityPreview {
  const _EmmaEntityPreview({
    required this.title,
    required this.subtitle,
    required this.url,
    required this.imageUrl,
    required this.priceText,
    required this.fallbackText,
    required this.entityKind,
    required this.source,
  });

  final String title;
  final String subtitle;
  final String url;
  final String imageUrl;
  final String priceText;
  final String fallbackText;
  final String entityKind;
  final String source;
}

class _EmmaRichBlockRenderer extends ConsumerWidget {
  const _EmmaRichBlockRenderer({
    required this.block,
    required this.isUser,
    required this.isMobile,
  });

  final _EmmaRichBlock block;
  final bool isUser;
  final bool isMobile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (block.type) {
      case _EmmaRichBlockType.text:
        return _TextBlock(
          text: block.text,
          isUser: isUser,
          isMobile: isMobile,
        );

      case _EmmaRichBlockType.link:
        return _LinkBlock(
          url: block.url,
          isUser: isUser,
          isMobile: isMobile,
        );

      case _EmmaRichBlockType.entityShare:
        return _EntityShareBlock(
          block: block,
          isUser: isUser,
          isMobile: isMobile,
        );

      case _EmmaRichBlockType.image:
        return _ImageBlock(
          url: block.url,
          name: block.name,
          isUser: isUser,
          isMobile: isMobile,
        );

      case _EmmaRichBlockType.video:
        return _FileLikeBlock(
          icon: Icons.videocam_outlined,
          title: block.name.isNotEmpty ? block.name : 'Video'.tr,
          subtitle: block.url,
          url: block.url,
          isUser: isUser,
        );

      case _EmmaRichBlockType.audio:
        return _FileLikeBlock(
          icon: Icons.audiotrack_rounded,
          title: block.name.isNotEmpty ? block.name : 'Audio'.tr,
          subtitle: block.url,
          url: block.url,
          isUser: isUser,
        );

      case _EmmaRichBlockType.pdf:
        return _PdfLikeBlock(
          title: block.name.isNotEmpty ? block.name : 'PDF'.tr,
          url: block.url,
          isUser: isUser,
        );

      case _EmmaRichBlockType.file:
        return _FileLikeBlock(
          icon: Icons.insert_drive_file_outlined,
          title: block.name.isNotEmpty ? block.name : 'File'.tr,
          subtitle: block.extension.isNotEmpty ? block.extension : block.url,
          url: block.url,
          isUser: isUser,
        );

      case _EmmaRichBlockType.systemEvent:
        return _SystemEventBlock(
          text: block.text.isNotEmpty ? block.text : 'System event'.tr,
          isUser: isUser,
        );

      case _EmmaRichBlockType.unknown:
        return _UnknownBlock(
          text: jsonEncode(block.payload),
          isUser: isUser,
        );
    }
  }
}

class _TextBlock extends ConsumerWidget {
  const _TextBlock({
    required this.text,
    required this.isUser,
    required this.isMobile,
  });

  final String text;
  final bool isUser;
  final bool isMobile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return buildRichTextWithMentionsAndLinks(
      text,
      const {},
      textColor: isUser ? Colors.white : theme.textColor,
      mentionColor: Colors.cyanAccent,
      linkColor: isUser ? Colors.white : theme.themeColor,
      fontSize: isMobile ? 14 : 16,
    );
  }
}

class _LinkBlock extends ConsumerWidget {
  const _LinkBlock({
    required this.url,
    required this.isUser,
    required this.isMobile,
  });

  final String url;
  final bool isUser;
  final bool isMobile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return InkWell(
      onTap: () => _openUrl(url),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          url,
          style: TextStyle(
            color: isUser ? Colors.white : theme.themeColor,
            fontSize: isMobile ? 13 : 14,
            decoration: TextDecoration.underline,
            decorationColor: isUser ? Colors.white : theme.themeColor,
          ),
        ),
      ),
    );
  }
}

class _EntityShareBlock extends ConsumerWidget {
  const _EntityShareBlock({
    required this.block,
    required this.isUser,
    required this.isMobile,
  });

  final _EmmaRichBlock block;
  final bool isUser;
  final bool isMobile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preview = block.preview;
    final theme = ref.watch(themeColorsProvider);

    if (preview == null) {
      return _UnknownBlock(
        text: jsonEncode(block.payload),
        isUser: isUser,
      );
    }

    final textColor = isUser ? Colors.white : theme.textColor;
    final secondary = textColor.withAlpha(185);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: preview.url.trim().isEmpty ? null : () => _openUrl(preview.url),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: textColor.withAlpha(35)),
          borderRadius: BorderRadius.circular(12),
          color: Colors.transparent,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (preview.imageUrl.trim().isNotEmpty)
              Image.network(
                _resolveMediaUrl(preview.imageUrl),
                width: double.infinity,
                height: isMobile ? 120 : 140,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return _MessageFallbackCard(
                    icon: _resolveEntityIcon(preview),
                    title: preview.title.isNotEmpty
                        ? preview.title
                        : _resolveEntityLabel(preview),
                    subtitle:
                        preview.subtitle.isNotEmpty ? preview.subtitle : preview.url,
                    isUser: isUser,
                    minHeight: isMobile ? 120 : 140,
                  );
                },
              )
            else
              _MessageFallbackCard(
                icon: _resolveEntityIcon(preview),
                title: preview.title.isNotEmpty
                    ? preview.title
                    : _resolveEntityLabel(preview),
                subtitle:
                    preview.subtitle.isNotEmpty ? preview.subtitle : preview.url,
                isUser: isUser,
                minHeight: isMobile ? 120 : 140,
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    preview.title.isNotEmpty
                        ? preview.title
                        : _resolveEntityLabel(preview),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: isMobile ? 13 : 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (preview.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      preview.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: secondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (preview.priceText.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      preview.priceText,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  if (preview.url.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      preview.url,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: secondary,
                        fontSize: 11,
                      ),
                    ),
                  ] else if (preview.fallbackText.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      preview.fallbackText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: secondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _resolveEntityIcon(_EmmaEntityPreview preview) {
    if (preview.entityKind == 'advertisement') return Icons.home_work_outlined;
    if (preview.entityKind == 'pdf') return Icons.picture_as_pdf_outlined;
    if (preview.entityKind == 'document') return Icons.description_outlined;
    if (preview.entityKind == 'video') return Icons.videocam_outlined;
    return Icons.share_outlined;
  }

  String _resolveEntityLabel(_EmmaEntityPreview preview) {
    if (preview.entityKind == 'advertisement' &&
        preview.source == 'network_monitoring') {
      return 'ad_nm'.tr;
    }

    if (preview.entityKind == 'advertisement') {
      return 'advertisement'.tr;
    }

    if (preview.entityKind == 'pdf') return 'pdf'.tr;
    if (preview.entityKind == 'document') return 'document'.tr;

    return 'shared_element'.tr;
  }
}

class _ImageBlock extends StatelessWidget {
  const _ImageBlock({
    required this.url,
    required this.name,
    required this.isUser,
    required this.isMobile,
  });

  final String url;
  final String name;
  final bool isUser;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final fullUrl = _resolveMediaUrl(url);

    if (fullUrl.isEmpty) {
      return _ImageFallback(
        name: name,
        isUser: isUser,
        isMobile: isMobile,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        fullUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: isMobile ? 180 : 220,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;

          return SizedBox(
            height: isMobile ? 160 : 180,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _ImageFallback(
            name: name,
            isUser: isUser,
            isMobile: isMobile,
          );
        },
      ),
    );
  }
}

class _ImageFallback extends ConsumerWidget {
  const _ImageFallback({
    required this.name,
    required this.isUser,
    required this.isMobile,
  });

  final String name;
  final bool isUser;
  final bool isMobile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _MessageFallbackCard(
      icon: Icons.image_not_supported_outlined,
      title: name.isNotEmpty ? name : 'Picture'.tr,
      subtitle: 'failed_to_load_image'.tr,
      isUser: isUser,
      minHeight: isMobile ? 120 : 140,
    );
  }
}

class _PdfLikeBlock extends ConsumerWidget {
  const _PdfLikeBlock({
    required this.title,
    required this.url,
    required this.isUser,
  });

  final String title;
  final String url;
  final bool isUser;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final textColor = isUser ? Colors.white : theme.textColor;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: url.trim().isEmpty ? null : () => _openUrl(_resolveMediaUrl(url)),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: textColor.withAlpha(35)),
          color: Colors.transparent,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 90,
              width: double.infinity,
              color: theme.textFieldColor.withAlpha(120),
              child: Center(
                child: Icon(
                  Icons.picture_as_pdf_outlined,
                  size: 48,
                  color: textColor.withAlpha(180),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              color: isUser ? theme.themeColor : theme.themeColor.withAlpha(230),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FileLikeBlock extends ConsumerWidget {
  const _FileLikeBlock({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.url,
    required this.isUser,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String url;
  final bool isUser;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final textColor = isUser ? Colors.white : theme.textColor;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: url.trim().isEmpty ? null : () => _openUrl(_resolveMediaUrl(url)),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: textColor.withAlpha(35)),
          borderRadius: BorderRadius.circular(12),
          color: Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(icon, color: textColor, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle.trim().isNotEmpty)
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor.withAlpha(180),
                        fontSize: 12,
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

class _SystemEventBlock extends ConsumerWidget {
  const _SystemEventBlock({
    required this.text,
    required this.isUser,
  });

  final String text;
  final bool isUser;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Text(
      text,
      style: TextStyle(
        color: (isUser ? Colors.white : theme.textColor).withAlpha(180),
        fontStyle: FontStyle.italic,
        fontSize: 13,
      ),
    );
  }
}

class _UnknownBlock extends ConsumerWidget {
  const _UnknownBlock({
    required this.text,
    required this.isUser,
  });

  final String text;
  final bool isUser;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final textColor = isUser ? Colors.white : theme.textColor;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: textColor.withAlpha(40)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _MessageFallbackCard extends ConsumerWidget {
  const _MessageFallbackCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isUser,
    this.minHeight = 100,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isUser;
  final double minHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final textColor = isUser ? Colors.white : theme.textColor;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: minHeight),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: textColor.withAlpha(35)),
        borderRadius: BorderRadius.circular(12),
        color: theme.textFieldColor.withAlpha(80),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 32,
            color: textColor.withAlpha(220),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          if (subtitle.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor.withAlpha(180),
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// ---------- RichText helper: mentions + links ----------

Widget buildRichTextWithMentionsAndLinks(
  String raw,
  Map<String, String> mentionMap, {
  required Color textColor,
  required Color mentionColor,
  required Color linkColor,
  required double fontSize,
}) {
  final matches = <_InlineToken>[];

  mentionMap.forEach((tag, display) {
    if (tag.trim().isEmpty) return;

    var start = raw.indexOf(tag);
    while (start != -1) {
      matches.add(
        _InlineToken(
          start: start,
          end: start + tag.length,
          text: '@$display',
          type: _InlineTokenType.mention,
          raw: tag,
        ),
      );

      start = raw.indexOf(tag, start + tag.length);
    }
  });

  final urlRegex = RegExp(
    r'(https?://[^\s]+|www\.[^\s]+|[a-zA-Z0-9][a-zA-Z0-9-]*\.[a-zA-Z]{2,}(?:/[^\s]*)?)',
    caseSensitive: false,
  );

  for (final match in urlRegex.allMatches(raw)) {
    final url = match.group(0);
    if (url == null || url.trim().isEmpty) continue;

    matches.add(
      _InlineToken(
        start: match.start,
        end: match.end,
        text: url,
        type: _InlineTokenType.link,
        raw: url,
      ),
    );
  }

  if (matches.isEmpty) {
    return Text(
      raw,
      softWrap: true,
      style: TextStyle(
        color: textColor,
        fontSize: fontSize,
        fontWeight: FontWeight.w200,
      ),
    );
  }

  matches.sort((a, b) => a.start.compareTo(b.start));

  final spans = <TextSpan>[];
  var index = 0;

  for (final token in matches) {
    if (token.start < index) continue;

    if (token.start > index) {
      spans.add(
        TextSpan(
          text: raw.substring(index, token.start),
          style: TextStyle(
            color: textColor,
            fontSize: fontSize,
            fontWeight: FontWeight.w200,
          ),
        ),
      );
    }

    if (token.type == _InlineTokenType.mention) {
      spans.add(
        TextSpan(
          text: token.text,
          style: TextStyle(
            color: mentionColor,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    } else {
      spans.add(
        TextSpan(
          text: token.text,
          style: TextStyle(
            color: linkColor,
            fontSize: fontSize,
            fontWeight: FontWeight.w400,
            decoration: TextDecoration.underline,
            decorationColor: linkColor,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              _openUrl(token.raw);
            },
        ),
      );
    }

    index = token.end;
  }

  if (index < raw.length) {
    spans.add(
      TextSpan(
        text: raw.substring(index),
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w200,
        ),
      ),
    );
  }

  return RichText(
    softWrap: true,
    text: TextSpan(children: spans),
  );
}

enum _InlineTokenType {
  mention,
  link,
}

class _InlineToken {
  const _InlineToken({
    required this.start,
    required this.end,
    required this.text,
    required this.type,
    required this.raw,
  });

  final int start;
  final int end;
  final String text;
  final _InlineTokenType type;
  final String raw;
}

/// ---------- Parsing helpers ----------

List<_EmmaRichBlock> _extractEmmaRichBlocks(Map<String, dynamic>? meta) {
  final rawBlocks = meta?['blocks'];

  if (rawBlocks is! List) return const [];

  final result = <_EmmaRichBlock>[];

  for (final raw in rawBlocks) {
    final map = _asStringDynamicMap(raw);
    if (map == null) continue;

    final parsed = _parseEmmaRichBlock(map);
    if (parsed == null) continue;

    result.add(parsed);
  }

  return _cleanRichBlocks(result);
}

_EmmaRichBlock? _parseEmmaRichBlock(Map<String, dynamic> map) {
  final rawType = _s(
    map['block_type'] ??
        map['type'] ??
        map['kind'] ??
        map['blockType'] ??
        map['block'],
  ).toLowerCase();

  final type = rawType
      .replaceAll('-', '_')
      .replaceAll(' ', '_')
      .replaceAll('.', '_')
      .trim();

  // Obrazy wygenerowane przez Emmę mają własny blok (ImageBlockDefinition):
  // osobny kafelek pod wiadomością, właściwe proporcje, fullscreen i przycisk
  // „Cloud Storage". Ścieżka „rich" renderowałaby je surowo WEWNĄTRZ bąbelka i —
  // przez warunek `!hasRichBlocks` — całkowicie zablokowałaby system bloków.
  // Zwykłe załączniki obrazkowe (bez cloud_file_id) zostają na ścieżce rich.
  final isEmmaGeneratedImage = (type == 'generated_image') ||
      (type == 'image' &&
          (map['cloud_file_id'] != null || map['saved_to_cloud'] != null));
  if (isEmmaGeneratedImage) return null;

  final text = _s(map['text'] ?? map['content'] ?? map['message']);
  final url = _s(map['url'] ?? map['href'] ?? map['file_url']);
  final name = _s(
    map['name'] ??
        map['filename'] ??
        map['file_name'] ??
        map['title'] ??
        map['label'],
  );
  final extension = _s(map['extension'] ?? map['ext']).toLowerCase();

  if (type == 'text') {
    return _EmmaRichBlock(
      type: _EmmaRichBlockType.text,
      text: text,
      payload: map,
    );
  }

  if (type == 'link') {
    return _EmmaRichBlock(
      type: _EmmaRichBlockType.link,
      url: url.isNotEmpty ? url : text,
      text: text,
      payload: map,
    );
  }

  if (type == 'entity_share' || type == 'entityshare' || type == 'share') {
    return _EmmaRichBlock(
      type: _EmmaRichBlockType.entityShare,
      payload: map,
      preview: _parseEntityPreview(map),
    );
  }

  if (type == 'image' || _looksLikeImageUrl(url) || _looksLikeImageName(name)) {
    return _EmmaRichBlock(
      type: _EmmaRichBlockType.image,
      url: url,
      name: name,
      extension: extension,
      payload: map,
    );
  }

  if (type == 'video') {
    return _EmmaRichBlock(
      type: _EmmaRichBlockType.video,
      url: url,
      name: name,
      extension: extension,
      payload: map,
    );
  }

  if (type == 'audio') {
    return _EmmaRichBlock(
      type: _EmmaRichBlockType.audio,
      url: url,
      name: name,
      extension: extension,
      payload: map,
    );
  }

  final isPdf = type == 'pdf' ||
      extension == 'pdf' ||
      name.toLowerCase().endsWith('.pdf') ||
      url.toLowerCase().contains('.pdf');

  if (isPdf) {
    return _EmmaRichBlock(
      type: _EmmaRichBlockType.pdf,
      url: url,
      name: name,
      extension: extension,
      payload: map,
    );
  }

  if (type == 'file' || type == 'document') {
    return _EmmaRichBlock(
      type: _EmmaRichBlockType.file,
      url: url,
      name: name,
      extension: extension,
      payload: map,
    );
  }

  if (type == 'system_event' || type == 'systemevent' || type == 'system') {
    return _EmmaRichBlock(
      type: _EmmaRichBlockType.systemEvent,
      text: text,
      payload: map,
    );
  }

  if (type == 'unknown') {
    return _EmmaRichBlock(
      type: _EmmaRichBlockType.unknown,
      payload: map,
    );
  }

  // Important:
  // Return null for unknown custom Emma blocks, so EmmaBlocksSection can still
  // render them without duplication.
  return null;
}

_EmmaEntityPreview? _parseEntityPreview(Map<String, dynamic> map) {
  final previewMap = _asStringDynamicMap(
        map['entity_share_preview'] ??
            map['entitySharePreview'] ??
            map['preview'] ??
            map['entity_preview'],
      ) ??
      map;

  final title = _s(previewMap['title'] ?? previewMap['name']);
  final subtitle = _s(previewMap['subtitle'] ?? previewMap['description']);
  final url = _s(previewMap['url'] ?? previewMap['href'] ?? map['url']);
  final imageUrl = _s(
    previewMap['image_url'] ??
        previewMap['imageUrl'] ??
        previewMap['main_image_url'] ??
        previewMap['thumbnail'] ??
        previewMap['thumbnail_url'],
  );
  final priceText = _s(previewMap['price_text'] ?? previewMap['priceText']);
  final fallbackText = _s(previewMap['fallback_text'] ?? previewMap['fallbackText']);
  final entityKind = _s(previewMap['entity_kind'] ?? previewMap['entityKind']);
  final source = _s(previewMap['source']);

  if (title.isEmpty &&
      subtitle.isEmpty &&
      url.isEmpty &&
      imageUrl.isEmpty &&
      priceText.isEmpty &&
      fallbackText.isEmpty &&
      entityKind.isEmpty &&
      source.isEmpty) {
    return null;
  }

  return _EmmaEntityPreview(
    title: title,
    subtitle: subtitle,
    url: url,
    imageUrl: imageUrl,
    priceText: priceText,
    fallbackText: fallbackText,
    entityKind: entityKind,
    source: source,
  );
}

List<_EmmaRichBlock> _cleanRichBlocks(List<_EmmaRichBlock> blocks) {
  final cleaned = blocks.where((b) => !_isPlaceholderTextBlock(b)).toList();

  if (cleaned.isNotEmpty) return cleaned;

  return blocks;
}

List<_EmmaRichBlock> _dedupeBlocksAgainstText({
  required String rawText,
  required List<_EmmaRichBlock> blocks,
}) {
  final text = rawText.trim();

  if (text.isEmpty) return blocks;

  return blocks.where((block) {
    if (block.type != _EmmaRichBlockType.text) return true;

    return block.text.trim() != text;
  }).toList();
}

bool _isPlaceholderTextBlock(_EmmaRichBlock block) {
  if (block.type != _EmmaRichBlockType.text) return false;

  final text = block.text.trim().toLowerCase();

  if (text.isEmpty) return true;
  if (text == 'image') return true;
  if (text == 'file') return true;
  if (text == 'audio') return true;
  if (text == 'video') return true;
  if (RegExp(r'^sent\s+\d+\s+file\(s\)$').hasMatch(text)) return true;

  return false;
}

bool _isStandaloneRichMessage(List<_EmmaRichBlock> blocks) {
  if (blocks.length != 1) return false;

  final type = blocks.first.type;

  return type == _EmmaRichBlockType.entityShare ||
      type == _EmmaRichBlockType.image ||
      type == _EmmaRichBlockType.file ||
      type == _EmmaRichBlockType.pdf ||
      type == _EmmaRichBlockType.video ||
      type == _EmmaRichBlockType.audio;
}

Map<String, dynamic>? _asStringDynamicMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;

  if (value is Map) {
    return value.map(
      (key, val) => MapEntry(key.toString(), val),
    );
  }

  return null;
}

String _s(dynamic value) {
  if (value == null) return '';
  return value.toString().trim();
}

bool _looksLikeImageUrl(String value) {
  final lower = value.toLowerCase();

  return lower.endsWith('.png') ||
      lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.webp') ||
      lower.endsWith('.gif') ||
      lower.contains('.png?') ||
      lower.contains('.jpg?') ||
      lower.contains('.jpeg?') ||
      lower.contains('.webp?') ||
      lower.contains('.gif?');
}

bool _looksLikeImageName(String value) {
  final lower = value.toLowerCase();

  return lower.endsWith('.png') ||
      lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.webp') ||
      lower.endsWith('.gif');
}

/// ---------- URL helpers ----------

String _resolveMediaUrl(String rawUrl) {
  final trimmed = rawUrl.trim();
  if (trimmed.isEmpty) return '';

  final uri = Uri.tryParse(trimmed);

  if (uri != null && uri.hasScheme) {
    return trimmed;
  }

  return '${URLs.baseUrl}$trimmed';
}

Future<void> _openUrl(String rawUrl) async {
  final raw = rawUrl.trim();
  if (raw.isEmpty) return;

  String finalUrl = raw;

  if (!finalUrl.startsWith('http://') &&
      !finalUrl.startsWith('https://') &&
      !finalUrl.startsWith('/') &&
      !finalUrl.startsWith('mailto:') &&
      !finalUrl.startsWith('tel:')) {
    finalUrl = 'https://$finalUrl';
  }

  if (finalUrl.startsWith('/')) {
    finalUrl = '${URLs.baseUrl}$finalUrl';
  }

  if (kIsWeb) {
    await openNewTabAndRoute(finalUrl);
    return;
  }

  final uri = Uri.tryParse(finalUrl);
  if (uri != null && await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}