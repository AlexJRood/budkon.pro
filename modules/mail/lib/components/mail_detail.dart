import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:intl/intl.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:core/platform/api_services.dart' as core_api;

import 'package:mail/components/email_meta_expandable.dart';
import 'package:mail/models/mail_models.dart';
import 'package:mail/send_mail/send_mail.dart';
import 'package:mail/utils/utils.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/lottie.dart';

import '../provider/mail_taxonomy_providers.dart';
import '../provider/urls_mail.dart';
import '../utils/Link_handler.dart';
import '../utils/api_services.dart';
import '../utils/mail_filters.dart';
import 'email_emma_panel.dart';
import 'html_email_view.dart';

enum EmailDetailSection {
  message,
  details,
  thread,
  tags,
  attachments,
}

final emailReadOverrideProvider = StateProvider<Map<int, bool>>((ref) => {});

final emailThreadProvider =
    FutureProvider.family<List<EmailThreadItem>, int>((ref, emailId) async {
  final response = await core_api.ApiServices.get(
    EmailsURLs.thread(emailId),
    ref: ref,
    hasToken: true,
    headers: const {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
  );

  if (response == null || (response.statusCode ?? 0) >= 400) {
    throw Exception('Thread request failed: ${response?.statusCode}');
  }

  final decoded = _decodeAnyJson(response.data);
  final list = _extractThreadList(decoded);

  final items = list
      .whereType<Map>()
      .map(
        (e) => EmailThreadItem.fromJson(
          e.map((k, v) => MapEntry(k.toString(), v)),
        ),
      )
      .toList();

  items.sort((a, b) {
    final aDate = a.timelineAt ?? a.sentAt ?? a.receivedAt ?? DateTime(1970);
    final bDate = b.timelineAt ?? b.sentAt ?? b.receivedAt ?? DateTime(1970);
    return aDate.compareTo(bDate);
  });

  return items;
});

class EmailViewAttachment {
  final String id;
  final String fileId;
  final String name;
  final String? url;
  final String deliveryMode;
  final int sizeBytes;

  /// Used for inline HTML images like: <img src="cid:...">
  final String? contentId;

  const EmailViewAttachment({
    required this.id,
    required this.fileId,
    required this.name,
    required this.url,
    required this.deliveryMode,
    required this.sizeBytes,
    this.contentId,
  });

  bool get isLinkMode => deliveryMode.toLowerCase().trim() == 'link';

  bool get hasUrl => (url ?? '').trim().isNotEmpty;

  String get extension {
    final cleanName = name.toLowerCase().split('?').first;
    final dotIndex = cleanName.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == cleanName.length - 1) return '';
    return cleanName.substring(dotIndex + 1);
  }

  bool get isPreviewableImage {
    return const {
      'png',
      'jpg',
      'jpeg',
      'gif',
      'webp',
      'bmp',
    }.contains(extension);
  }

  bool get isSvg => extension == 'svg';

  static String _nameFromUrl(String? rawUrl) {
    final value = (rawUrl ?? '').trim();
    if (value.isEmpty) return '';

    try {
      final uri = Uri.parse(value);
      if (uri.pathSegments.isEmpty) return '';
      return Uri.decodeComponent(uri.pathSegments.last);
    } catch (_) {
      final parts = value.split('/');
      return parts.isEmpty ? '' : parts.last.split('?').first;
    }
  }

  factory EmailViewAttachment.fromJson(Map<String, dynamic> json) {
    final rawFile = json['file'];

    final fileMap = rawFile is Map
        ? rawFile.map((k, v) => MapEntry(k.toString(), v))
        : <String, dynamic>{};

    dynamic pickRaw(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value;
        }

        final nestedValue = fileMap[key];
        if (nestedValue != null && nestedValue.toString().trim().isNotEmpty) {
          return nestedValue;
        }
      }

      return null;
    }

    String pickString(List<String> keys, {String fallback = ''}) {
      final value = pickRaw(keys);
      if (value == null) return fallback;
      final s = value.toString().trim();
      return s.isEmpty ? fallback : s;
    }

    final url = pickString(
      [
        'url',
        'download_url',
        'file_url',
        'public_url',
        'storage_url',
        'signed_url',
        'absolute_url',
        'href',
        'link',
      ],
    );

    final fallbackName = _nameFromUrl(url);

    final name = pickString(
      [
        'name',
        'filename',
        'file_name',
        'original_filename',
        'display_name',
        'title',
      ],
      fallback: fallbackName.isNotEmpty ? fallbackName : 'attachment',
    );

    final id = pickString(
      ['id', 'attachment_id', 'uuid'],
      fallback: '',
    );

    final nestedFileId = fileMap['id']?.toString().trim();

    final contentId = pickString(
      [
        'content_id',
        'contentId',
        'cid',
        'content-id',
        'mime_content_id',
      ],
    );

    return EmailViewAttachment(
      id: id,
      fileId: pickString(
        ['file_id', 'cloud_file_id', 'storage_id'],
        fallback: (nestedFileId == null || nestedFileId.isEmpty)
            ? id
            : nestedFileId,
      ),
      name: name,
      url: url.isEmpty ? null : url,
      deliveryMode: pickString(
        ['delivery_mode', 'mode'],
        fallback: url.isNotEmpty ? 'link' : 'direct',
      ),
      sizeBytes: _safeInt(
        pickRaw(['size_bytes', 'size', 'file_size', 'bytes']),
      ),
      contentId: contentId.isEmpty ? null : contentId,
    );
  }
}

class EmailDetailViewPayload {
  final EmailMessage email;
  final List<EmailViewAttachment> attachments;
  final String htmlBody;

  const EmailDetailViewPayload({
    required this.email,
    required this.attachments,
    required this.htmlBody,
  });
}

final emailDetailViewProvider =
    FutureProvider.family<EmailDetailViewPayload, int>((ref, emailId) async {
  final response = await core_api.ApiServices.get(
    '${EmailsURLs.emails}$emailId/',
    ref: ref,
    hasToken: true,
    headers: const {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
  );

  if (response == null || (response.statusCode ?? 0) >= 400) {
    throw Exception('Email details request failed: ${response?.statusCode}');
  }

  final decoded = _decodeAnyJson(response.data);

  if (decoded is! Map) {
    throw Exception('Invalid email details response');
  }

  final map = decoded.map((k, v) => MapEntry(k.toString(), v));
  final email = EmailMessage.fromJson(map);
  final attachments = _extractEmailAttachments(map);
  final htmlBody = _extractEmailHtmlBody(map);

  return EmailDetailViewPayload(
    email: email,
    attachments: attachments,
    htmlBody: htmlBody,
  );
});

String formatDate(dynamic value) {
  if (value == null) return '';

  if (value is DateTime) {
    return DateFormat('dd.MM.yyyy HH:mm').format(value.toLocal());
  }

  final raw = value.toString().trim();
  if (raw.isEmpty) return '';

  final parsed = DateTime.tryParse(raw);
  if (parsed != null) {
    return DateFormat('dd.MM.yyyy HH:mm').format(parsed.toLocal());
  }

  return raw;
}

dynamic _decodeAnyJson(dynamic raw) {
  if (raw == null) return null;

  if (raw is Uint8List) {
    try {
      return json.decode(utf8.decode(raw));
    } catch (_) {
      return raw;
    }
  }

  if (raw is List<int>) {
    try {
      return json.decode(utf8.decode(raw));
    } catch (_) {
      return raw;
    }
  }

  if (raw is String) {
    try {
      return json.decode(raw);
    } catch (_) {
      return raw;
    }
  }

  if (raw is Map || raw is List) {
    return raw;
  }

  return raw;
}

int _safeInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

String _extractEmailHtmlBody(Map<String, dynamic> decoded) {
  String pickString(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }

    return '';
  }

  const htmlKeys = [
    'html_body',
    'htmlBody',
    'body_html',
    'bodyHtml',
    'html',
    'body_html_content',
    'html_content',
  ];

  final direct = pickString(decoded, htmlKeys);
  if (direct.trim().isNotEmpty) return direct;

  final nestedEmail = decoded['email'];
  if (nestedEmail is Map) {
    final nestedMap = nestedEmail.map((k, v) => MapEntry(k.toString(), v));
    final nested = pickString(nestedMap, htmlKeys);
    if (nested.trim().isNotEmpty) return nested;
  }

  return '';
}

List<EmailViewAttachment> _extractEmailAttachments(
  Map<String, dynamic> decoded,
) {
  List<EmailViewAttachment> parseList(dynamic raw) {
    if (raw is! List) return const [];

    return raw
        .whereType<Map>()
        .map(
          (e) => EmailViewAttachment.fromJson(
            e.map((k, v) => MapEntry(k.toString(), v)),
          ),
        )
        .toList(growable: false);
  }

  final candidates = [
    decoded['attachments'],
    decoded['email_attachments'],
    decoded['attachment_files'],
    decoded['files'],
  ];

  for (final candidate in candidates) {
    final parsed = parseList(candidate);
    if (parsed.isNotEmpty) return parsed;
  }

  final nestedEmail = decoded['email'];
  if (nestedEmail is Map) {
    final nestedMap = nestedEmail.map((k, v) => MapEntry(k.toString(), v));

    final nestedCandidates = [
      nestedMap['attachments'],
      nestedMap['email_attachments'],
      nestedMap['attachment_files'],
      nestedMap['files'],
    ];

    for (final candidate in nestedCandidates) {
      final parsed = parseList(candidate);
      if (parsed.isNotEmpty) return parsed;
    }
  }

  return const [];
}

List<dynamic> _extractThreadList(dynamic decoded) {
  if (decoded == null) return const [];

  if (decoded is List) {
    return decoded.whereType<Map>().toList();
  }

  if (decoded is Map) {
    const keys = [
      'results',
      'items',
      'messages',
      'thread',
      'emails',
      'data',
    ];

    for (final key in keys) {
      final value = decoded[key];
      if (value is List) {
        return value.whereType<Map>().toList();
      }
    }

    if (decoded.containsKey('id') &&
        (decoded.containsKey('subject') ||
            decoded.containsKey('body') ||
            decoded.containsKey('sender'))) {
      return [decoded];
    }
  }

  return const [];
}

String _normalizeContentId(String value) {
  var s = value.trim();

  if (s.toLowerCase().startsWith('cid:')) {
    s = s.substring(4);
  }

  try {
    s = Uri.decodeComponent(s);
  } catch (_) {}

  s = s.replaceAll(RegExp(r'^[<\s]+'), '');
  s = s.replaceAll(RegExp(r'[>\s]+$'), '');

  return s.toLowerCase();
}

String rewriteInlineAttachmentSources(
  String html,
  List<EmailViewAttachment> attachments,
) {
  if (html.trim().isEmpty || attachments.isEmpty) return html;

  final cidToUrl = <String, String>{};

  for (final attachment in attachments) {
    final cid = attachment.contentId;
    final url = attachment.url;

    if (cid == null || cid.trim().isEmpty) continue;
    if (url == null || url.trim().isEmpty) continue;

    cidToUrl[_normalizeContentId(cid)] = url.trim();
  }

  if (cidToUrl.isEmpty) return html;

  final srcCidRegex = RegExp(
    r'''(src\s*=\s*["'])cid:([^"']+)(["'])''',
    caseSensitive: false,
  );

  return html.replaceAllMapped(srcCidRegex, (match) {
    final prefix = match.group(1) ?? 'src="';
    final rawCid = match.group(2) ?? '';
    final suffix = match.group(3) ?? '"';

    final normalizedCid = _normalizeContentId(rawCid);
    final url = cidToUrl[normalizedCid];

    if (url == null || url.isEmpty) return match.group(0) ?? '';

    return '$prefix$url$suffix';
  });
}

bool _looksLikeHtml(String value) {
  final s = value.trim().toLowerCase();
  if (s.isEmpty) return false;

  return s.contains('<!doctype html') ||
      s.contains('<html') ||
      s.contains('<body') ||
      RegExp(
        r'<(div|span|p|br|table|tbody|thead|tr|td|th|img|a|strong|b|i|u|ul|ol|li|style|font|center|blockquote|h1|h2|h3|h4|h5|h6)\b',
        caseSensitive: false,
      ).hasMatch(s);
}

String _decodeBasicHtmlEntities(String input) {
  return input
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#34;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&apos;', "'")
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&');
}

String _preparePotentialHtml(String input) {
  var current = input.trim();
  if (current.isEmpty) return input;

  if (_looksLikeHtml(current)) return current;

  for (int i = 0; i < 3; i++) {
    final decoded = _decodeBasicHtmlEntities(current);
    if (decoded == current) break;

    current = decoded.trim();

    if (_looksLikeHtml(current)) {
      return current;
    }
  }

  return input;
}

DateTime? _tryParseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;

  final stringValue = value.toString().trim();
  if (stringValue.isEmpty) return null;

  return DateTime.tryParse(stringValue);
}

bool _readBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;

  final s = value?.toString().toLowerCase().trim();
  return s == 'true' || s == '1' || s == 'yes';
}

class EmailThreadItem {
  final int id;
  final String subject;
  final String sender;
  final String senderDisplayName;
  final String preview;
  final bool isRead;
  final DateTime? timelineAt;
  final DateTime? sentAt;
  final DateTime? receivedAt;

  const EmailThreadItem({
    required this.id,
    required this.subject,
    required this.sender,
    required this.senderDisplayName,
    required this.preview,
    required this.isRead,
    required this.timelineAt,
    required this.sentAt,
    required this.receivedAt,
  });

  factory EmailThreadItem.fromJson(Map<String, dynamic> json) {
    final body = (json['body'] ?? '').toString();
    final snippet = (json['snippet'] ?? json['preview'] ?? '').toString();

    return EmailThreadItem(
      id: int.tryParse('${json['id']}') ?? 0,
      subject: (json['subject'] ?? '').toString(),
      sender: (json['sender'] ?? json['from'] ?? json['sender_email'] ?? '')
          .toString(),
      senderDisplayName: (json['sender_display_name'] ??
              json['from_name'] ??
              json['display_name'] ??
              '')
          .toString(),
      preview: snippet.isNotEmpty
          ? snippet
          : normalizePlainText(body).replaceAll('\n', ' '),
      isRead: _readBool(json['is_read']),
      timelineAt: _tryParseDate(json['timeline_at']),
      sentAt: _tryParseDate(json['sent_at']),
      receivedAt: _tryParseDate(json['received_at']),
    );
  }
}

class EmailDetail extends ConsumerStatefulWidget {
  final int emailId;
  final bool isMobile;
  final ScrollController? scrollController;
  final DraggableScrollableController? sheetController;

  const EmailDetail({
    super.key,
    required this.emailId,
    required this.isMobile,
    this.scrollController,
    this.sheetController,
  });

  @override
  ConsumerState<EmailDetail> createState() => _EmailDetailState();
}

class _HorizontalScrollList extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final EdgeInsetsGeometry padding;
  final CrossAxisAlignment crossAxisAlignment;

  const _HorizontalScrollList({
    required this.children,
    this.spacing = 8,
    this.padding = EdgeInsets.zero,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: padding,
        clipBehavior: Clip.none,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: crossAxisAlignment,
          children: [
            for (int i = 0; i < children.length; i++) ...[
              if (i > 0) SizedBox(width: spacing),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

class _EmailDetailState extends ConsumerState<EmailDetail> {
  EmailDetailSection _selectedSection = EmailDetailSection.message;

  final Set<int> _autoMarkReadSent = {};
  final Set<int> _markReadInFlight = {};

  @override
  void didUpdateWidget(covariant EmailDetail oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.emailId != widget.emailId) {
      _selectedSection = EmailDetailSection.message;
    }
  }

  Color _parseColor(String? hex, Color fallback) {
    final normalized = (hex ?? '').replaceAll('#', '').trim();
    if (normalized.isEmpty) return fallback;

    final value =
        normalized.length == 6 ? 'FF$normalized' : normalized.padLeft(8, 'F');

    return Color(int.tryParse(value, radix: 16) ?? fallback.value);
  }

  EmailMessage _applyReadOverride(EmailMessage email) {
    final overrides = ref.read(emailReadOverrideProvider);
    final override = overrides[email.id];

    if (override == null) return email;
    if (override == email.isRead) return email;

    return email.copyWith(isRead: override);
  }

  void _setLocalReadOverride(int emailId, bool isRead) {
    final current = ref.read(emailReadOverrideProvider);

    ref.read(emailReadOverrideProvider.notifier).state = {
      ...current,
      emailId: isRead,
    };
  }

  void _softRefreshMailLists(WidgetRef ref) {
    triggerMailRefresh(ref);
    ref.invalidate(emailThreadProvider(widget.emailId));
  }

  void _invalidateEmailData(WidgetRef ref) {
    triggerMailRefresh(ref);
    ref.invalidate(emailDetailsProvider(widget.emailId));
    ref.invalidate(emailDetailViewProvider(widget.emailId));
    ref.invalidate(emailThreadProvider(widget.emailId));
  }

  void _scheduleAutoMarkAsRead(EmailMessage email) {
    if (email.id <= 0) return;
    if (email.isRead) return;
    if (email.isOutgoing) return;
    if (_autoMarkReadSent.contains(email.id)) return;
    if (_markReadInFlight.contains(email.id)) return;

    _autoMarkReadSent.add(email.id);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      _setLocalReadOverride(email.id, true);
      _markReadInFlight.add(email.id);

      try {
        await _postAction(
          ref: ref,
          url: EmailsURLs.markRead(email.id),
        );

        _softRefreshMailLists(ref);
      } catch (e) {
        _setLocalReadOverride(email.id, false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Mark read failed: $e')),
          );
        }
      } finally {
        _markReadInFlight.remove(email.id);
      }
    });
  }

  Widget _adaptiveWrapOrHorizontalList({
    required List<Widget> children,
    double spacing = 8,
    double runSpacing = 8,
    WrapCrossAlignment wrapCrossAlignment = WrapCrossAlignment.start,
    CrossAxisAlignment scrollCrossAxisAlignment = CrossAxisAlignment.center,
  }) {
    if (children.isEmpty) return const SizedBox.shrink();

    if (widget.isMobile) {
      return _HorizontalScrollList(
        spacing: spacing,
        crossAxisAlignment: scrollCrossAxisAlignment,
        children: children,
      );
    }

    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      crossAxisAlignment: wrapCrossAlignment,
      children: children,
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    double value = bytes.toDouble();
    int unitIndex = 0;

    while (value >= 1024 && unitIndex < units.length - 1) {
      value /= 1024;
      unitIndex++;
    }

    if (unitIndex == 0) {
      return '${value.toStringAsFixed(0)} ${units[unitIndex]}';
    }

    return '${value.toStringAsFixed(1)} ${units[unitIndex]}';
  }

  String _attachmentTypeLabel(EmailViewAttachment attachment) {
    if (attachment.isPreviewableImage) return 'Image'.tr;
    if (attachment.isSvg) return 'SVG'.tr;
    return attachment.isLinkMode ? 'Link'.tr : 'Attachment'.tr;
  }

  IconData _attachmentIcon(EmailViewAttachment attachment) {
    final name = attachment.name.toLowerCase();

    if (name.endsWith('.pdf')) return Icons.picture_as_pdf_outlined;

    if (name.endsWith('.png') ||
        name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.gif') ||
        name.endsWith('.webp') ||
        name.endsWith('.bmp') ||
        name.endsWith('.svg')) {
      return Icons.image_outlined;
    }

    if (name.endsWith('.doc') ||
        name.endsWith('.docx') ||
        name.endsWith('.odt')) {
      return Icons.description_outlined;
    }

    if (name.endsWith('.xls') ||
        name.endsWith('.xlsx') ||
        name.endsWith('.csv') ||
        name.endsWith('.ods')) {
      return Icons.table_chart_outlined;
    }

    if (name.endsWith('.ppt') ||
        name.endsWith('.pptx') ||
        name.endsWith('.odp')) {
      return Icons.slideshow_outlined;
    }

    if (name.endsWith('.zip') ||
        name.endsWith('.rar') ||
        name.endsWith('.7z') ||
        name.endsWith('.tar') ||
        name.endsWith('.gz')) {
      return Icons.archive_outlined;
    }

    if (name.endsWith('.mp4') ||
        name.endsWith('.mov') ||
        name.endsWith('.avi') ||
        name.endsWith('.mkv') ||
        name.endsWith('.webm')) {
      return Icons.video_file_outlined;
    }

    if (name.endsWith('.mp3') ||
        name.endsWith('.wav') ||
        name.endsWith('.ogg') ||
        name.endsWith('.m4a')) {
      return Icons.audio_file_outlined;
    }

    return attachment.isLinkMode ? Icons.link_outlined : Icons.attach_file_outlined;
  }

  Widget _attachmentFallbackLeading(
    ThemeColors theme,
    EmailViewAttachment attachment, {
    bool isLoading = false,
  }) {
    final isLink = attachment.isLinkMode;
    final bgColor =
        isLink ? Colors.orange.withAlpha(20) : theme.themeColor.withAlpha(18);

    final borderColor =
        isLink ? Colors.orange.withAlpha(70) : theme.themeColor.withAlpha(60);

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Center(
        child: isLoading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.themeColor,
                ),
              )
            : Icon(
                _attachmentIcon(attachment),
                color: isLink ? Colors.orange : theme.themeColor,
                size: 24,
              ),
      ),
    );
  }

  Widget _buildAttachmentLeading(
    ThemeColors theme,
    EmailViewAttachment attachment,
  ) {
    final imageUrl = attachment.url?.trim();

    if (attachment.isPreviewableImage &&
        imageUrl != null &&
        imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: theme.dashboardContainer,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: theme.dashboardBoarder.withAlpha(120),
            ),
          ),
          child: Image.network(
            imageUrl,
            width: 46,
            height: 46,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;

              return _attachmentFallbackLeading(
                theme,
                attachment,
                isLoading: true,
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return _attachmentFallbackLeading(theme, attachment);
            },
          ),
        ),
      );
    }

    return _attachmentFallbackLeading(theme, attachment);
  }

  Widget _buildCompactAttachmentTile(
    BuildContext context,
    ThemeColors theme,
    EmailViewAttachment attachment,
  ) {
    final sizeLabel = _formatFileSize(attachment.sizeBytes);
    final typeLabel = _attachmentTypeLabel(attachment);

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: attachment.hasUrl ? () => _openAttachment(context, attachment) : null,
      child: Container(
        width: widget.isMobile ? 172 : 210,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.dashboardContainer.withAlpha(130),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: theme.dashboardBoarder.withAlpha(130),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 34,
              height: 34,
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: 46,
                  height: 46,
                  child: _buildAttachmentLeading(theme, attachment),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attachment.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sizeLabel.isEmpty ? typeLabel : '$typeLabel • $sizeLabel',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.textColor.withAlpha(150),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 130,
              ),
              icon: Icon(
                Icons.more_vert,
                color: theme.textColor.withAlpha(180),
                size: 18,
              ),
              color: theme.dashboardContainer,
              onSelected: (value) async {
                switch (value) {
                  case 'open':
                    await _openAttachment(context, attachment);
                    break;
                  case 'copy':
                    await _copyAttachmentLink(context, attachment);
                    break;
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem<String>(
                  value: 'open',
                  enabled: attachment.hasUrl,
                  child: Row(
                    children: [
                      const Icon(Icons.open_in_new, size: 17),
                      const SizedBox(width: 8),
                      Text('Open'.tr),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'copy',
                  enabled: attachment.hasUrl,
                  child: Row(
                    children: [
                      const Icon(Icons.copy_outlined, size: 17),
                      const SizedBox(width: 8),
                      Text('Copy link'.tr),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactAttachmentsBottomBar(
    BuildContext context,
    ThemeColors theme,
    List<EmailViewAttachment> attachments,
  ) {
    if (attachments.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.adPopBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dashboardBoarder.withAlpha(130),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.attach_file_outlined,
                size: 15,
                color: theme.themeColor,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${'Attachments'.tr} (${attachments.length})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () {
                  setState(() {
                    _selectedSection = EmailDetailSection.attachments;
                  });
                },
                child: Text(
                  'Open all'.tr,
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 54,
            child: _HorizontalScrollList(
              spacing: 8,
              children: attachments
                  .map(
                    (attachment) => _buildCompactAttachmentTile(
                      context,
                      theme,
                      attachment,
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openAttachment(
    BuildContext context,
    EmailViewAttachment attachment,
  ) async {
    final rawUrl = (attachment.url ?? '').trim();
    final fileId = attachment.fileId.trim();

    // Private cloud storage files need a presigned URL — direct launchUrl would
    // fail with 401 because the backend download endpoint requires auth.
    // If we have a fileId, resolve via the backend endpoint first.
    if (fileId.isNotEmpty) {
      await _openCloudStorageFile(context, fileId);
      return;
    }

    if (rawUrl.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Attachment has no URL'.tr)),
      );
      return;
    }

    final uri = Uri.tryParse(rawUrl);
    if (uri == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid attachment URL'.tr)),
      );
      return;
    }

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open attachment'.tr)),
      );
    }
  }

  Future<void> _openCloudStorageFile(
    BuildContext context,
    String fileId,
  ) async {
    try {
      final endpoint =
          'https://www.superbee.cloud/storage/files/$fileId/resolve-download-url/';

      final data = await core_api.ApiServices.getJson(
        endpoint,
        hasToken: true,
        ref: ref,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Timeout resolving attachment URL'),
      );

      final resolvedUrl = (data['url'] ??
              data['preview_url'] ??
              data['download_url'] ??
              '')
          .toString()
          .trim();

      if (resolvedUrl.isEmpty) {
        throw Exception('No URL in resolve-download-url response');
      }

      final uri = Uri.tryParse(resolvedUrl);
      if (uri == null) throw Exception('Invalid resolved URL: $resolvedUrl');

      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open attachment'.tr)),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${'Could not open attachment'.tr}: $e')),
      );
    }
  }

  Future<void> _copyAttachmentLink(
    BuildContext context,
    EmailViewAttachment attachment,
  ) async {
    final rawUrl = (attachment.url ?? '').trim();
    if (rawUrl.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Attachment has no URL'.tr)),
      );
      return;
    }

    await Clipboard.setData(ClipboardData(text: rawUrl));

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Attachment link copied'.tr)),
    );
  }

  Future<Map<String, dynamic>> _postAction({
    required WidgetRef ref,
    required String url,
    Map<String, dynamic>? data,
  }) async {
    final response = await core_api.ApiServices.post(
      url,
      ref: ref,
      hasToken: true,
      data: data,
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    if (response == null || (response.statusCode ?? 0) >= 400) {
      throw Exception('Request failed: ${response?.statusCode}');
    }

    final raw = response.data;

    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);

    if (raw is String) {
      final decoded = json.decode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }

    if (raw is Uint8List) {
      final decoded = json.decode(utf8.decode(raw));
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }

    if (raw is List<int>) {
      final decoded = json.decode(utf8.decode(raw));
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }

    return <String, dynamic>{};
  }

  Future<void> _handleMarkRead(
    BuildContext context,
    WidgetRef ref,
    bool isRead,
  ) async {
    final nextValue = !isRead;

    if (_markReadInFlight.contains(widget.emailId)) return;

    _setLocalReadOverride(widget.emailId, nextValue);
    _markReadInFlight.add(widget.emailId);

    try {
      await _postAction(
        ref: ref,
        url: isRead
            ? EmailsURLs.markUnread(widget.emailId)
            : EmailsURLs.markRead(widget.emailId),
      );

      _softRefreshMailLists(ref);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isRead ? 'Marked as unread'.tr : 'Marked as read'.tr,
            ),
          ),
        );
      }
    } catch (e) {
      _setLocalReadOverride(widget.emailId, isRead);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action failed: $e')),
        );
      }
    } finally {
      _markReadInFlight.remove(widget.emailId);
    }
  }

  Future<void> _handleSpamToggle(
    BuildContext context,
    WidgetRef ref,
    bool isSpam,
  ) async {
    try {
      await _postAction(
        ref: ref,
        url: isSpam
            ? EmailsURLs.markNotSpam(widget.emailId)
            : EmailsURLs.markSpam(widget.emailId),
      );

      _invalidateEmailData(ref);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isSpam ? 'Marked as not spam'.tr : 'Marked as spam'.tr,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action failed: $e')),
        );
      }
    }
  }

  Future<void> _handleTouchEmmaUsed(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      await _postAction(
        ref: ref,
        url: EmailsURLs.touchEmmaUsed(widget.emailId),
      );

      _invalidateEmailData(ref);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Emma usage updated'.tr)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action failed: $e')),
        );
      }
    }
  }

  Future<void> _handleMoveToTab(
    BuildContext context,
    WidgetRef ref,
    int tabId,
  ) async {
    try {
      await _postAction(
        ref: ref,
        url: EmailsURLs.moveToTab(widget.emailId),
        data: {'tab_id': tabId},
      );

      _invalidateEmailData(ref);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Moved to tab'.tr)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action failed: $e')),
        );
      }
    }
  }

  Future<void> _showMoveToTabDialog(
    BuildContext context,
    WidgetRef ref,
    int? currentTabId,
  ) async {
    final tabs = await ref.read(emailTabsProvider.future);
    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        final theme = ref.read(themeColorsProvider);

        return AlertDialog(
          backgroundColor: theme.dashboardContainer,
          title: Text(
            'Move to tab'.tr,
            style: TextStyle(color: theme.textColor),
          ),
          content: SizedBox(
            width: 360,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: tabs.length,
              separatorBuilder: (_, __) => Divider(
                color: theme.dashboardBoarder,
                height: 1,
              ),
              itemBuilder: (_, index) {
                final tab = tabs[index];
                final isSelected = tab.id == currentTabId;
                final color = _parseColor(tab.color, theme.themeColor);

                return ListTile(
                  onTap: () async {
                    Navigator.of(dialogContext).pop();
                    await _handleMoveToTab(context, ref, tab.id);
                  },
                  leading: CircleAvatar(
                    radius: 8,
                    backgroundColor: color,
                  ),
                  title: Text(
                    tab.name,
                    style: TextStyle(color: theme.textColor),
                  ),
                  trailing:
                      isSelected ? Icon(Icons.check, color: theme.themeColor) : null,
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _showEditTagsDialog(
    BuildContext context,
    WidgetRef ref,
    List<EmailTag> currentTags,
  ) async {
    final allTags = await ref.read(emailTagsProvider.future);
    if (!context.mounted) return;

    final selected = currentTags.map((e) => e.id).toSet();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        final theme = ref.read(themeColorsProvider);

        return StatefulBuilder(
          builder: (context, setLocalState) {
            final tagChips = allTags.map((tag) {
              final isSelected = selected.contains(tag.id);
              final color = _parseColor(tag.color, theme.themeColor);

              return FilterChip(
                selected: isSelected,
                label: Text(tag.name),
                labelStyle: TextStyle(
                  color: isSelected ? color : theme.textColor,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
                showCheckmark: false,
                selectedColor: color.withAlpha(45),
                backgroundColor: theme.adPopBackground,
                shape: StadiumBorder(
                  side: BorderSide(
                    color: isSelected ? color.withAlpha(160) : theme.dashboardBoarder.withAlpha(140),
                  ),
                ),
                elevation: 0,
                pressElevation: 0,
                onSelected: (value) {
                  setLocalState(() {
                    if (value) {
                      selected.add(tag.id);
                    } else {
                      selected.remove(tag.id);
                    }
                  });
                },
              );
            }).toList();

            return AlertDialog(
              backgroundColor: theme.dashboardContainer,
              title: Text(
                'Edit tags'.tr,
                style: TextStyle(color: theme.textColor),
              ),
              content: SizedBox(
                width: 420,
                child: _adaptiveWrapOrHorizontalList(
                  spacing: 8,
                  runSpacing: 8,
                  children: tagChips,
                ),
              ),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: theme.textColor),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text('Cancel'.tr),
                ),
                ElevatedButton(
                  style: elevatedButtonStyleRounded10.copyWith(
                    backgroundColor: WidgetStatePropertyAll(theme.themeColor),
                    foregroundColor: WidgetStatePropertyAll(theme.themeTextColor),
                  ),
                  onPressed: () async {
                    final currentIds = currentTags.map((e) => e.id).toSet();
                    final addIds =
                        selected.where((id) => !currentIds.contains(id)).toList();
                    final removeIds =
                        currentIds.where((id) => !selected.contains(id)).toList();

                    Navigator.of(dialogContext).pop();

                    try {
                      await EmailTaxonomyService.setEmailTags(
                        ref: ref,
                        emailId: widget.emailId,
                        addTagIds: addIds,
                        removeTagIds: removeIds,
                      );

                      _invalidateEmailData(ref);

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Tags updated'.tr)),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Action failed: $e')),
                        );
                      }
                    }
                  },
                  child: Text('Save'.tr),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleForwardEmail(
    BuildContext context,
    WidgetRef ref, {
    required String to,
    String? cc,
    String? bcc,
    String? note,
  }) async {
    try {
      await _postAction(
        ref: ref,
        url: EmailsURLs.forward(widget.emailId),
        data: {
          'to': to,
          'cc': cc,
          'bcc': bcc,
          'note': note,
        },
      );

      _invalidateEmailData(ref);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Email forwarded'.tr)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Forward failed: $e')),
        );
      }
    }
  }

  Future<void> _showForwardDialog(
    BuildContext context,
    WidgetRef ref,
    EmailMessage email,
  ) async {
    final toController = TextEditingController();
    final ccController = TextEditingController();
    final bccController = TextEditingController();
    final noteController = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        final theme = ref.read(themeColorsProvider);

        InputDecoration decoration(String label) => InputDecoration(
              labelText: label,
              labelStyle: TextStyle(color: theme.textColor.withAlpha(170)),
              filled: true,
              fillColor: theme.adPopBackground,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: theme.dashboardBoarder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: theme.themeColor),
              ),
            );

        return AlertDialog(
          backgroundColor: theme.dashboardContainer,
          title: Text(
            'Forward email'.tr,
            style: TextStyle(color: theme.textColor),
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    email.subject,
                    style: TextStyle(
                      color: theme.textColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${'From'.tr}: ${email.senderDisplayName.isNotEmpty ? email.senderDisplayName : email.sender}',
                    style: TextStyle(
                      color: theme.textColor.withAlpha(180),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: toController,
                    style: TextStyle(color: theme.textColor),
                    decoration: decoration('To'.tr),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: ccController,
                    style: TextStyle(color: theme.textColor),
                    decoration: decoration('CC'.tr),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: bccController,
                    style: TextStyle(color: theme.textColor),
                    decoration: decoration('BCC'.tr),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    maxLines: 4,
                    style: TextStyle(color: theme.textColor),
                    decoration: decoration('Note above forwarded message'.tr),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Cancel'.tr),
            ),
            ElevatedButton.icon(
              style: elevatedButtonStyleRounded10,
              onPressed: () async {
                final to = toController.text.trim();
                final cc = ccController.text.trim();
                final bcc = bccController.text.trim();
                final note = noteController.text.trim();

                if (to.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text('Recipient is required'.tr)),
                  );
                  return;
                }

                Navigator.of(dialogContext).pop();

                await _handleForwardEmail(
                  context,
                  ref,
                  to: to,
                  cc: cc.isEmpty ? null : cc,
                  bcc: bcc.isEmpty ? null : bcc,
                  note: note.isEmpty ? null : note,
                );
              },
              icon: const Icon(Icons.forward_to_inbox_outlined),
              label: Text('Forward'.tr),
            ),
          ],
        );
      },
    );

    toController.dispose();
    ccController.dispose();
    bccController.dispose();
    noteController.dispose();
  }

  Future<void> _handleUnsubscribe(
    BuildContext context,
    WidgetRef ref,
    String? fallbackUrl,
    String? fallbackMailto,
  ) async {
    try {
      final data = await _postAction(
        ref: ref,
        url: EmailsURLs.unsubscribe(widget.emailId),
      );

      final url = (data['unsubscribe_url'] ?? fallbackUrl)?.toString();
      final mailto = (data['unsubscribe_mailto'] ?? fallbackMailto)?.toString();

      Uri? uri;
      if (url != null && url.isNotEmpty) {
        uri = Uri.tryParse(url);
      } else if (mailto != null && mailto.isNotEmpty) {
        final normalized = mailto.startsWith('mailto:') ? mailto : 'mailto:$mailto';
        uri = Uri.tryParse(normalized);
      }

      _invalidateEmailData(ref);

      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No unsubscribe link available'.tr)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unsubscribe failed: $e')),
        );
      }
    }
  }

  Widget _buildChip({
    required ThemeColors theme,
    required String label,
    required IconData icon,
    String? colorHex,
  }) {
    final color = _parseColor(colorHex, theme.themeColor);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: theme.textColor.withAlpha(220),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailBadges(
    EmailMessage email,
    List<EmailViewAttachment> attachments,
    ThemeColors theme,
  ) {
    final tags = email.tags.take(6).toList();

    return _adaptiveWrapOrHorizontalList(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (email.currentTabName.isNotEmpty)
          _buildChip(
            theme: theme,
            label: email.currentTabName,
            icon: Icons.folder_open_outlined,
            colorHex: email.currentTabColor,
          ),
        if (email.isEmma)
          _buildChip(
            theme: theme,
            label: 'Emma',
            icon: Icons.smart_toy_outlined,
            colorHex: '#692125',
          ),
        if (email.isEmmaDirectSend)
          _buildChip(
            theme: theme,
            label: 'Direct',
            icon: Icons.send_outlined,
            colorHex: '#14B8A6',
          ),
        if (email.effectiveIsSpam)
          _buildChip(
            theme: theme,
            label: 'Spam',
            icon: Icons.report_gmailerrorred_outlined,
            colorHex: '#DC2626',
          ),
        if ((email.unsubscribeUrl ?? '').isNotEmpty ||
            (email.unsubscribeMailto ?? '').isNotEmpty)
          _buildChip(
            theme: theme,
            label: 'Unsubscribe',
            icon: Icons.unsubscribe_outlined,
            colorHex: '#F59E0B',
          ),
        if (attachments.isNotEmpty)
          _buildChip(
            theme: theme,
            label:
                '${attachments.length} ${attachments.length == 1 ? 'attachment'.tr : 'attachments'.tr}',
            icon: Icons.attach_file_outlined,
            colorHex: '#2563EB',
          ),
        ...tags.map(
          (tag) => _buildChip(
            theme: theme,
            label: tag.name,
            icon: Icons.sell_outlined,
            colorHex: tag.color,
          ),
        ),
      ],
    );
  }

  void _showEmmaSheet(BuildContext context, EmailMessage email) {
    const emmaAccent = Color(0xFF37B6FF);
    final theme = ref.read(themeColorsProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.78,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (sheetContext, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: theme.dashboardContainer,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                border:
                    Border.all(color: theme.dashboardBoarder.withAlpha(120)),
              ),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: theme.dashboardBoarder.withAlpha(140),
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome_rounded,
                            color: emmaAccent, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Sugestie Emmy',
                          style: TextStyle(
                            color: theme.textColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: emmaAccent.withAlpha(30)),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: EmailEmmaPanel(
                        emailId: email.id,
                        standalone: true,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSecondaryActionsSheet(
    BuildContext context,
    WidgetRef ref,
    EmailMessage email,
    ThemeColors theme,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (sheetContext, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: theme.dashboardContainer,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                border:
                    Border.all(color: theme.dashboardBoarder.withAlpha(120)),
              ),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: theme.dashboardBoarder.withAlpha(140),
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: Row(
                      children: [
                        Icon(Icons.more_horiz, color: theme.textColor, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'More actions'.tr,
                          style: TextStyle(
                            color: theme.textColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: theme.dashboardBoarder.withAlpha(120)),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: _buildSecondaryActionButtons(
                                context, ref, email, theme)
                            .map(
                              (button) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: button,
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Floating square icon button, matching the vertical action bars used
  /// elsewhere in the app (see MailVerticalBar / CalendarVerticalBar).
  Widget _buildFloatingVerticalButton({
    required ThemeColors theme,
    required IconData icon,
    required Color iconColor,
    required String tooltip,
    required VoidCallback onPressed,
    Color? backgroundColor,
  }) {
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 450),
      child: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: backgroundColor ?? theme.textFieldColor,
          borderRadius: const BorderRadius.all(Radius.circular(6)),
        ),
        child: ElevatedButton(
          style: elevatedButtonStyleRounded10,
          onPressed: onPressed,
          child: Icon(icon, color: iconColor, size: 20),
        ),
      ),
    );
  }

  /// Reply + Emma, positioned like the app-wide floating vertical action
  /// bar (BarManager's `verticalButtons`), instead of inline in the action row.
  Widget _buildReplyEmmaVerticalBar(
    BuildContext context,
    WidgetRef ref,
    EmailMessage email,
    ThemeColors theme,
  ) {
    const emmaAccent = Color(0xFF37B6FF);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildFloatingVerticalButton(
          theme: theme,
          icon: Icons.more_horiz,
          iconColor: theme.textColor,
          tooltip: 'More'.tr,
          onPressed: () => _showSecondaryActionsSheet(context, ref, email, theme),
        ),
        const SizedBox(height: 5),
        if (!email.isOutgoing) ...[
          _buildFloatingVerticalButton(
            theme: theme,
            icon: Icons.auto_awesome_rounded,
            iconColor: emmaAccent,
            tooltip: 'Emma',
            onPressed: () => _showEmmaSheet(context, email),
          ),
          const SizedBox(height: 5),
        ],
        _buildFloatingVerticalButton(
          theme: theme,
          icon: Icons.reply,
          iconColor: theme.textColor,
          tooltip: 'Reply'.tr,
          onPressed: () {
            if (email.isEmma) {
              _handleTouchEmmaUsed(context, ref);
            }

            showEmailOverlay(
              context,
              ref,
              leadId: email.leadId,
              lead: email,
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionsBar(
    BuildContext context,
    WidgetRef ref,
    EmailMessage email,
    ThemeColors theme,
  ) {
    return _adaptiveWrapOrHorizontalList(
      spacing: 8,
      runSpacing: 8,
      children: [
        ElevatedButton.icon(
          style: elevatedButtonStyleRounded10,
          onPressed: () {
            if (email.isEmma) {
              _handleTouchEmmaUsed(context, ref);
            }

            showEmailOverlay(
              context,
              ref,
              leadId: email.leadId,
              lead: email,
            );
          },
          icon: Icon(Icons.reply, color: theme.textColor),
          label: Text('Reply'.tr, style: TextStyle(color: theme.textColor)),
        ),
        ..._buildSecondaryActionButtons(context, ref, email, theme),
      ],
    );
  }

  List<Widget> _buildSecondaryActionButtons(
    BuildContext context,
    WidgetRef ref,
    EmailMessage email,
    ThemeColors theme,
  ) {
    return [
        OutlinedButton.icon(
          onPressed: () => _showForwardDialog(context, ref, email),
          icon: Icon(Icons.forward_to_inbox_outlined, color: theme.textColor),
          label: Text(
            'Forward'.tr,
            style: TextStyle(color: theme.textColor),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => _handleMarkRead(context, ref, email.isRead),
          icon: Icon(
            email.isRead
                ? Icons.mark_email_unread_outlined
                : Icons.mark_email_read_outlined,
            color: theme.textColor,
          ),
          label: Text(
            email.isRead ? 'Mark unread'.tr : 'Mark read'.tr,
            style: TextStyle(color: theme.textColor),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => _handleSpamToggle(context, ref, email.effectiveIsSpam),
          icon: Icon(
            email.effectiveIsSpam
                ? Icons.check_circle_outline
                : Icons.report_gmailerrorred_outlined,
            color: theme.textColor,
          ),
          label: Text(
            email.effectiveIsSpam ? 'Not spam'.tr : 'Spam'.tr,
            style: TextStyle(color: theme.textColor),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => _showMoveToTabDialog(
            context,
            ref,
            email.currentTabId,
          ),
          icon: Icon(Icons.folder_open_outlined, color: theme.textColor),
          label: Text(
            'Move to tab'.tr,
            style: TextStyle(color: theme.textColor),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => _showEditTagsDialog(
            context,
            ref,
            email.tags,
          ),
          icon: Icon(Icons.sell_outlined, color: theme.textColor),
          label: Text(
            'Tags'.tr,
            style: TextStyle(color: theme.textColor),
          ),
        ),
        if (email.isEmma)
          OutlinedButton.icon(
            onPressed: () => _handleTouchEmmaUsed(context, ref),
            icon: Icon(Icons.bolt_outlined, color: theme.textColor),
            label: Text(
              'Touch Emma'.tr,
              style: TextStyle(color: theme.textColor),
            ),
          ),
        if ((email.unsubscribeUrl ?? '').isNotEmpty ||
            (email.unsubscribeMailto ?? '').isNotEmpty)
          OutlinedButton.icon(
            onPressed: () => _handleUnsubscribe(
              context,
              ref,
              email.unsubscribeUrl,
              email.unsubscribeMailto,
            ),
            icon: Icon(Icons.unsubscribe_outlined, color: theme.textColor),
            label: Text(
              'Unsubscribe'.tr,
              style: TextStyle(color: theme.textColor),
            ),
          ),
    ];
  }

  Widget _buildSectionSwitcher(
    ThemeColors theme,
    List<EmailViewAttachment> attachments,
  ) {
    Widget item({
      required String label,
      required IconData icon,
      required EmailDetailSection section,
    }) {
      final selected = _selectedSection == section;

      return InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          setState(() {
            _selectedSection = section;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? theme.themeColor.withAlpha(24) : theme.adPopBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? theme.themeColor.withAlpha(120)
                  : theme.dashboardBoarder.withAlpha(140),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? theme.themeColor : theme.textColor,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected ? theme.themeColor : theme.textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _adaptiveWrapOrHorizontalList(
      spacing: 8,
      runSpacing: 8,
      children: [
        item(
          label: 'Message'.tr,
          icon: Icons.mail_outline,
          section: EmailDetailSection.message,
        ),
        item(
          label: 'Details'.tr,
          icon: Icons.info_outline,
          section: EmailDetailSection.details,
        ),
        item(
          label: 'Thread'.tr,
          icon: Icons.account_tree_outlined,
          section: EmailDetailSection.thread,
        ),
        item(
          label: 'Tags'.tr,
          icon: Icons.sell_outlined,
          section: EmailDetailSection.tags,
        ),
        item(
          label: attachments.isEmpty
              ? 'Attachments'.tr
              : '${'Attachments'.tr} (${attachments.length})',
          icon: Icons.attach_file_outlined,
          section: EmailDetailSection.attachments,
        ),
      ],
    );
  }

  Widget _buildCardSection({
    required ThemeColors theme,
    required String title,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.adPopBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dashboardBoarder.withAlpha(140)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: theme.themeColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildMetaRow({
    required ThemeColors theme,
    required String label,
    required String value,
    bool allowSelect = false,
  }) {
    final textWidget = allowSelect
        ? SelectableText(
            value,
            style: TextStyle(
              color: theme.textColor.withAlpha(215),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          )
        : Text(
            value,
            style: TextStyle(
              color: theme.textColor.withAlpha(215),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                color: theme.textColor.withAlpha(150),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: textWidget),
        ],
      ),
    );
  }

  Widget _buildAttachmentTile(
    BuildContext context,
    ThemeColors theme,
    EmailViewAttachment attachment,
  ) {
    final sizeLabel = _formatFileSize(attachment.sizeBytes);
    final typeLabel = _attachmentTypeLabel(attachment);

    return Container(
      decoration: BoxDecoration(
        color: theme.dashboardContainer.withAlpha(120),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dashboardBoarder.withAlpha(140)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: _buildAttachmentLeading(theme, attachment),
        title: Text(
          attachment.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: theme.textColor,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _adaptiveWrapOrHorizontalList(
                spacing: 8,
                runSpacing: 6,
                wrapCrossAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: attachment.isLinkMode
                          ? Colors.orange.withAlpha(20)
                          : Colors.green.withAlpha(20),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: attachment.isLinkMode
                            ? Colors.orange.withAlpha(90)
                            : Colors.green.withAlpha(90),
                      ),
                    ),
                    child: Text(
                      typeLabel,
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (sizeLabel.isNotEmpty)
                    Text(
                      sizeLabel,
                      style: TextStyle(
                        color: theme.textColor.withAlpha(170),
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
              if (attachment.hasUrl) ...[
                const SizedBox(height: 6),
                Text(
                  attachment.url!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.textColor.withAlpha(150),
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: theme.textColor),
          color: theme.dashboardContainer,
          onSelected: (value) async {
            switch (value) {
              case 'open':
                await _openAttachment(context, attachment);
                break;
              case 'copy':
                await _copyAttachmentLink(context, attachment);
                break;
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem<String>(
              value: 'open',
              enabled: attachment.hasUrl,
              child: Row(
                children: [
                  const Icon(Icons.open_in_new, size: 18),
                  const SizedBox(width: 8),
                  Text('Open'.tr),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'copy',
              enabled: attachment.hasUrl,
              child: Row(
                children: [
                  const Icon(Icons.copy_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text('Copy link'.tr),
                ],
              ),
            ),
          ],
        ),
        onTap: attachment.hasUrl ? () => _openAttachment(context, attachment) : null,
      ),
    );
  }

  Widget _buildAttachmentsSectionContent(
    BuildContext context,
    ThemeColors theme,
    List<EmailViewAttachment> attachments,
  ) {
    if (attachments.isEmpty) {
      return Text(
        'No attachments'.tr,
        style: TextStyle(
          color: theme.textColor.withAlpha(170),
          fontSize: 13,
        ),
      );
    }

    return Column(
      children: List.generate(attachments.length, (index) {
        final item = attachments[index];

        return Padding(
          padding: EdgeInsets.only(
            bottom: index == attachments.length - 1 ? 0 : 10,
          ),
          child: _buildAttachmentTile(context, theme, item),
        );
      }),
    );
  }

  Widget _buildDetailsSection(
    BuildContext context,
    WidgetRef ref,
    EmailMessage email,
    List<EmailViewAttachment> attachments,
    ThemeColors theme,
  ) {
    final recipients = email.recipients.join(', ');
    final cc = email.cc.join(', ');
    final bcc = email.bcc.join(', ');

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(10),
      children: [
        _buildCardSection(
          theme: theme,
          title: 'Message details'.tr,
          icon: Icons.info_outline,
          child: Column(
            children: [
              _buildMetaRow(
                theme: theme,
                label: 'From'.tr,
                value: email.senderDisplayName.isNotEmpty
                    ? '${email.senderDisplayName} <${email.sender}>'
                    : email.sender,
                allowSelect: true,
              ),
              _buildMetaRow(
                theme: theme,
                label: 'To'.tr,
                value: recipients.isNotEmpty ? recipients : '-',
                allowSelect: true,
              ),
              if (cc.isNotEmpty)
                _buildMetaRow(
                  theme: theme,
                  label: 'CC'.tr,
                  value: cc,
                  allowSelect: true,
                ),
              if (bcc.isNotEmpty)
                _buildMetaRow(
                  theme: theme,
                  label: 'BCC'.tr,
                  value: bcc,
                  allowSelect: true,
                ),
              _buildMetaRow(
                theme: theme,
                label: 'Sent'.tr,
                value: formatDate(email.sentAt),
              ),
              _buildMetaRow(
                theme: theme,
                label: 'Received'.tr,
                value: formatDate(email.receivedAt),
              ),
              _buildMetaRow(
                theme: theme,
                label: 'Read'.tr,
                value: email.isRead ? 'Yes'.tr : 'No'.tr,
              ),
              _buildMetaRow(
                theme: theme,
                label: 'Spam'.tr,
                value: email.effectiveIsSpam ? 'Yes'.tr : 'No'.tr,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildCardSection(
          theme: theme,
          title: 'Classification'.tr,
          icon: Icons.label_important_outline,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (email.currentTabName.isNotEmpty)
                _buildMetaRow(
                  theme: theme,
                  label: 'Tab'.tr,
                  value: email.currentTabName,
                ),
              _buildMetaRow(
                theme: theme,
                label: 'Emma'.tr,
                value: email.isEmma ? 'Yes'.tr : 'No'.tr,
              ),
              _buildMetaRow(
                theme: theme,
                label: 'Direct send'.tr,
                value: email.isEmmaDirectSend ? 'Yes'.tr : 'No'.tr,
              ),
              _buildMetaRow(
                theme: theme,
                label: 'Attachments'.tr,
                value: attachments.length.toString(),
              ),
              if ((email.unsubscribeUrl ?? '').isNotEmpty)
                _buildMetaRow(
                  theme: theme,
                  label: 'Unsubscribe URL'.tr,
                  value: email.unsubscribeUrl!,
                  allowSelect: true,
                ),
              if ((email.unsubscribeMailto ?? '').isNotEmpty)
                _buildMetaRow(
                  theme: theme,
                  label: 'Unsubscribe mail'.tr,
                  value: email.unsubscribeMailto!,
                  allowSelect: true,
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildCardSection(
          theme: theme,
          title: 'Attachments'.tr,
          icon: Icons.attach_file_outlined,
          trailing: attachments.isNotEmpty
              ? Text(
                  '${attachments.length}',
                  style: TextStyle(
                    color: theme.textColor.withAlpha(170),
                    fontWeight: FontWeight.w700,
                  ),
                )
              : null,
          child: _buildAttachmentsSectionContent(context, theme, attachments),
        ),
        const SizedBox(height: 12),
        _buildCardSection(
          theme: theme,
          title: 'Quick actions'.tr,
          icon: Icons.flash_on_outlined,
          child: _adaptiveWrapOrHorizontalList(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => setState(() {
                  _selectedSection = EmailDetailSection.thread;
                }),
                icon: Icon(Icons.account_tree_outlined, color: theme.textColor),
                label: Text(
                  'Open thread'.tr,
                  style: TextStyle(color: theme.textColor),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => setState(() {
                  _selectedSection = EmailDetailSection.attachments;
                }),
                icon: Icon(Icons.attach_file_outlined, color: theme.textColor),
                label: Text(
                  'Open attachments'.tr,
                  style: TextStyle(color: theme.textColor),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _showForwardDialog(context, ref, email),
                icon: Icon(
                  Icons.forward_to_inbox_outlined,
                  color: theme.textColor,
                ),
                label: Text(
                  'Forward'.tr,
                  style: TextStyle(color: theme.textColor),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _showEditTagsDialog(context, ref, email.tags),
                icon: Icon(Icons.sell_outlined, color: theme.textColor),
                label: Text(
                  'Edit tags'.tr,
                  style: TextStyle(color: theme.textColor),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThreadSection(
    BuildContext context,
    WidgetRef ref,
    EmailMessage currentEmail,
    ThemeColors theme,
  ) {
    final threadAsync = ref.watch(emailThreadProvider(widget.emailId));

    return threadAsync.when(
      loading: () => Center(child: AppLottie.loading(size: 180)),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${'Failed to load thread'.tr}: $e',
                style: TextStyle(color: theme.textColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  ref.invalidate(emailThreadProvider(widget.emailId));
                },
                icon: Icon(Icons.refresh, color: theme.textColor),
                label: Text(
                  'Retry'.tr,
                  style: TextStyle(color: theme.textColor),
                ),
              ),
            ],
          ),
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Text(
              'No thread data available'.tr,
              style: TextStyle(color: theme.textColor),
            ),
          );
        }

        return ListView.separated(
          controller: widget.scrollController,
          padding: const EdgeInsets.all(10),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final item = items[index];
            final isCurrent = item.id == currentEmail.id;
            final author =
                item.senderDisplayName.isNotEmpty ? item.senderDisplayName : item.sender;

            final date = item.timelineAt ?? item.sentAt ?? item.receivedAt;
            final preview = shortenText(item.preview, 220);

            return Container(
              decoration: BoxDecoration(
                color: isCurrent
                    ? theme.themeColor.withAlpha(16)
                    : theme.adPopBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCurrent
                      ? theme.themeColor.withAlpha(120)
                      : theme.dashboardBoarder.withAlpha(120),
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? theme.themeColor.withAlpha(26)
                          : theme.dashboardContainer,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isCurrent
                            ? theme.themeColor.withAlpha(120)
                            : theme.dashboardBoarder.withAlpha(120),
                      ),
                    ),
                    child: Icon(
                      isCurrent ? Icons.mail : Icons.reply_all_outlined,
                      size: 16,
                      color: isCurrent ? theme.themeColor : theme.textColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                author,
                                style: TextStyle(
                                  color: theme.textColor,
                                  fontWeight:
                                      item.isRead ? FontWeight.w500 : FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            if (isCurrent)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.themeColor.withAlpha(24),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'Current'.tr,
                                  style: TextStyle(
                                    color: theme.themeColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.subject.isNotEmpty ? item.subject : '(No subject)'.tr,
                          style: TextStyle(
                            color: theme.textColor.withAlpha(210),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (date != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            formatDate(date),
                            style: TextStyle(
                              color: theme.textColor.withAlpha(150),
                              fontSize: 11,
                            ),
                          ),
                        ],
                        if (preview.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            preview,
                            style: TextStyle(
                              color: theme.textColor.withAlpha(185),
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTagsSection(
    BuildContext context,
    WidgetRef ref,
    EmailMessage email,
    ThemeColors theme,
  ) {
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(10),
      children: [
        _buildCardSection(
          theme: theme,
          title: 'Assigned tags'.tr,
          icon: Icons.sell_outlined,
          trailing: OutlinedButton.icon(
            onPressed: () => _showEditTagsDialog(context, ref, email.tags),
            icon: Icon(Icons.edit_outlined, size: 16, color: theme.textColor),
            label: Text(
              'Edit'.tr,
              style: TextStyle(color: theme.textColor),
            ),
          ),
          child: email.tags.isEmpty
              ? Text(
                  'No tags assigned'.tr,
                  style: TextStyle(
                    color: theme.textColor.withAlpha(170),
                    fontSize: 13,
                  ),
                )
              : _adaptiveWrapOrHorizontalList(
                  spacing: 8,
                  runSpacing: 8,
                  children: email.tags.map((tag) {
                    return _buildChip(
                      theme: theme,
                      label: tag.name,
                      icon: Icons.sell_outlined,
                      colorHex: tag.color,
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(height: 12),
        _buildCardSection(
          theme: theme,
          title: 'Tag actions'.tr,
          icon: Icons.auto_awesome_motion_outlined,
          child: _adaptiveWrapOrHorizontalList(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showEditTagsDialog(context, ref, email.tags),
                icon: Icon(Icons.add_circle_outline, color: theme.textColor),
                label: Text(
                  'Add or remove tags'.tr,
                  style: TextStyle(color: theme.textColor),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _showMoveToTabDialog(
                  context,
                  ref,
                  email.currentTabId,
                ),
                icon: Icon(Icons.folder_open_outlined, color: theme.textColor),
                label: Text(
                  'Move to tab'.tr,
                  style: TextStyle(color: theme.textColor),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentsSection(
    BuildContext context,
    ThemeColors theme,
    List<EmailViewAttachment> attachments,
  ) {
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(10),
      children: [
        _buildCardSection(
          theme: theme,
          title: 'Attachments'.tr,
          icon: Icons.attach_file_outlined,
          trailing: attachments.isNotEmpty
              ? Text(
                  '${attachments.length}',
                  style: TextStyle(
                    color: theme.textColor.withAlpha(170),
                    fontWeight: FontWeight.w700,
                  ),
                )
              : null,
          child: _buildAttachmentsSectionContent(context, theme, attachments),
        ),
      ],
    );
  }

  Widget _buildPlainBodyInlineContent(
    BuildContext context,
    WidgetRef ref,
    String messageBody,
    ThemeColors theme,
  ) {
    final normalized = normalizePlainText(messageBody);
    final urls = extractUrls(normalized);
    final text = removeUrls(normalized);

    final linkButtons = [
      for (int i = 0; i < urls.length; i++)
        Builder(
          builder: (context) {
            return PieMenu(
              theme: PieTheme.of(context).copyWith(
                overlayColor: theme.textColor.computeLuminance() > 0.5
                    ? Colors.black.withValues(alpha: 0.70)
                    : Colors.white.withValues(alpha: 0.70),
              ),
              actions: buildLinkPieActions(
                url: urls[i],
                ref: ref,
                context: context,
                theme: theme,
              ),
              child: OutlinedButton.icon(
                onPressed: () {
                  final urlToHandle = urls[i];
                  final localRef = ref;
                  final localContext = context;

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!localContext.mounted) return;

                    LinkHandler.handleLinkPress(
                      urlToHandle,
                      localRef,
                      localContext,
                    );
                  });
                },
                icon: Icon(
                  Icons.open_in_new,
                  color: theme.textColor,
                  size: 18,
                ),
                label: Text(
                  '${prettyUrlLabel(urls[i])}  •  ${i + 1}',
                  style: TextStyle(color: theme.textColor),
                ),
              ),
            );
          },
        ),
    ];

    final shouldUseHorizontalLinks =
        widget.isMobile || MediaQuery.sizeOf(context).width < 620;

    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (text.isNotEmpty)
            SelectableText(
              text,
              style: TextStyle(
                color: theme.textColor,
                fontSize: 14,
              ),
            ),
          if (urls.isNotEmpty) ...[
            const SizedBox(height: 12),
            Divider(color: theme.dashboardBoarder.withAlpha(160)),
            const SizedBox(height: 10),
            Text(
              'Links in the message'.tr,
              style: TextStyle(
                color: theme.textColor.withAlpha(180),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            shouldUseHorizontalLinks
                ? _HorizontalScrollList(
                    spacing: 8,
                    children: linkButtons,
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: linkButtons,
                  ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageSection(
    BuildContext context,
    WidgetRef ref,
    EmailMessage email,
    List<EmailViewAttachment> attachments,
    ThemeColors theme,
    String htmlBody,
  ) {
    final htmlCandidate = _preparePotentialHtml(htmlBody);
    final bodyCandidate = _preparePotentialHtml(email.body);

    final String htmlSource = _looksLikeHtml(htmlCandidate)
        ? htmlCandidate
        : _looksLikeHtml(bodyCandidate)
            ? bodyCandidate
            : '';

    final bool isHtml = htmlSource.trim().isNotEmpty;

    final String messageBody = isHtml
        ? rewriteInlineAttachmentSources(htmlSource, attachments)
        : email.body;

    final bool useSheetLinkedScroll =
        widget.isMobile && widget.scrollController != null;

    Widget attachmentsBottomBar() {
      return _buildCompactAttachmentsBottomBar(
        context,
        theme,
        attachments,
      );
    }

    if (useSheetLinkedScroll) {
      return ListView(
        controller: widget.scrollController,
        padding: EdgeInsets.zero,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          if (isHtml)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: HtmlEmailView(
                html: messageBody,
                theme: theme,
                sheetController: widget.sheetController,
                shrinkToContent: true,
              ),
            )
          else
            _buildPlainBodyInlineContent(
              context,
              ref,
              messageBody,
              theme,
            ),
          if (!email.isOutgoing && !widget.isMobile)
            EmailEmmaPanel(emailId: email.id),
          attachmentsBottomBar(),
          const SizedBox(height: 8),
        ],
      );
    }

    return Column(
      children: [
        Expanded(
          child: isHtml
              ? HtmlEmailView(
                  html: messageBody,
                  theme: theme,
                  sheetController: widget.sheetController,
                  shrinkToContent: false,
                )
              : PlainBodyWithLinkButtons(
                  rawText: messageBody,
                  theme: theme,
                  controller: widget.scrollController,
                  useHorizontalLinkList: widget.isMobile,
                ),
        ),
        if (!email.isOutgoing && !widget.isMobile)
          EmailEmmaPanel(emailId: email.id),
        attachmentsBottomBar(),
      ],
    );
  }

  Widget _buildSelectedSectionBody(
    BuildContext context,
    WidgetRef ref,
    EmailMessage email,
    List<EmailViewAttachment> attachments,
    ThemeColors theme,
    String htmlBody,
  ) {
    switch (_selectedSection) {
      case EmailDetailSection.message:
        return _buildMessageSection(
          context,
          ref,
          email,
          attachments,
          theme,
          htmlBody,
        );

      case EmailDetailSection.details:
        return _buildDetailsSection(
          context,
          ref,
          email,
          attachments,
          theme,
        );

      case EmailDetailSection.thread:
        return _buildThreadSection(context, ref, email, theme);

      case EmailDetailSection.tags:
        return _buildTagsSection(context, ref, email, theme);

      case EmailDetailSection.attachments:
        return _buildAttachmentsSection(context, theme, attachments);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(emailReadOverrideProvider);

    final detailAsync = ref.watch(emailDetailViewProvider(widget.emailId));
    final theme = ref.watch(themeColorsProvider);
    final bool inBottomSheet = widget.scrollController != null;
    final isMobile = widget.isMobile;

    return detailAsync.when(
      data: (payload) {
        final email = _applyReadOverride(payload.email);
        final attachments = payload.attachments;
        final htmlBody = payload.htmlBody;

        _scheduleAutoMarkAsRead(email);

        Widget bodyContainer({required Widget child}) {
          final container = Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.dashboardContainer,
              border: Border.all(color: theme.dashboardBoarder, width: 1.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 0 : 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 4),
                    child: Text(
                      email.subject,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.textColor.withAlpha(210),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (!isMobile) ...[
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _buildActionsBar(context, ref, email, theme),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 4),
                    child: _buildSectionSwitcher(theme, attachments),
                  ),
                  const SizedBox(height: 12),
                  if (!isMobile) ...[
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 4),
                      child: _buildDetailBadges(email, attachments, theme),
                    ),
                  ],
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 8.0 : 4.0,
                    ),
                    child: Divider(
                      height: isMobile ? 14 : 24,
                      color: theme.dashboardBoarder,
                    ),
                  ),
                  Expanded(child: child),
                ],
              ),
            ),
          );

          if (!isMobile) return container;

          return Stack(
            children: [
              container,
              Positioned(
                right: 10,
                bottom: 10,
                child: _buildReplyEmmaVerticalBar(context, ref, email, theme),
              ),
            ],
          );
        }

        final selectedBody = _buildSelectedSectionBody(
          context,
          ref,
          email,
          attachments,
          theme,
          htmlBody,
        );

        if (inBottomSheet) {
          return Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: theme.adPopBackground,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 5 : 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: theme.dashboardBoarder.withAlpha(120),
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                      ),
                      EmailMetaExpandable(
                        sender: email.sender,
                        senderDisplayName: email.senderDisplayName,
                        recipients: email.recipients,
                        cc: email.cc,
                        bcc: email.bcc,
                        sentAt: email.sentAt,
                        receivedAt: email.receivedAt,
                        theme: theme,
                        initiallyExpanded: false,
                        useCard: true,
                        cardColor: theme.dashboardContainer,
                        cardBorderColor: theme.dashboardBoarder,
                      ),
                      SizedBox(height: isMobile ? 5 : 16),
                      Expanded(
                        child: bodyContainer(
                          child: selectedBody,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.all(isMobile ? 5 : 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EmailMetaExpandable(
                sender: email.sender,
                senderDisplayName: email.senderDisplayName,
                recipients: email.recipients,
                cc: email.cc,
                bcc: email.bcc,
                sentAt: email.sentAt,
                receivedAt: email.receivedAt,
                theme: theme,
                initiallyExpanded: false,
                useCard: true,
                cardColor: theme.dashboardContainer,
                cardBorderColor: theme.dashboardBoarder,
              ),
              SizedBox(height: isMobile ? 5 : 16),
              Expanded(
                child: bodyContainer(
                  child: selectedBody,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Center(child: AppLottie.loading(size: 450)),
      error: (e, _) => Center(
        child: Text('${'Error'.tr}: $e', style: TextStyle(color: theme.textColor)),
      ),
    );
  }
}

String normalizePlainText(String input) {
  var s = input;

  s = s.replaceAll(RegExp(r'&zwnj;?', caseSensitive: false), '');
  s = s.replaceAll(RegExp(r'&#8204;?', caseSensitive: false), '');
  s = s.replaceAll(RegExp(r'[\u200B\u200C\u200D\uFEFF]'), '');

  s = s.replaceAll('&nbsp;', ' ');
  s = s.replaceAll('&amp;', '&');
  s = s.replaceAll('&lt;', '<');
  s = s.replaceAll('&gt;', '>');
  s = s.replaceAll('&quot;', '"');
  s = s.replaceAll('&#39;', "'");

  s = s.replaceAll(RegExp(r'[ \t]+\n'), '\n');
  s = s.replaceAll(RegExp(r'\n{4,}'), '\n\n\n');

  return s.trim();
}

List<String> extractUrls(String text) {
  final re = RegExp(r'(https?:\/\/[^\s<>()]+)', caseSensitive: false);
  final matches = re.allMatches(text);

  final out = <String>[];
  for (final m in matches) {
    var url = m.group(0) ?? '';
    url = url.replaceAll(RegExp(r'[)\].,;:]+$'), '');
    if (url.isNotEmpty) out.add(url);
  }

  final seen = <String>{};
  return out.where((u) => seen.add(u)).toList();
}

String removeUrls(String text) {
  return text
      .replaceAll(RegExp(r'https?:\/\/[^\s<>()]+', caseSensitive: false), '')
      .trim();
}

String prettyUrlLabel(String url) {
  try {
    final uri = Uri.parse(url);
    final host = uri.host.isEmpty ? url : uri.host;
    return host.replaceFirst(RegExp(r'^www\.'), '');
  } catch (_) {
    return 'Link';
  }
}

class PlainBodyWithLinkButtons extends ConsumerWidget {
  final String rawText;
  final ThemeColors theme;
  final ScrollController? controller;
  final bool useHorizontalLinkList;

  const PlainBodyWithLinkButtons({
    super.key,
    required this.rawText,
    required this.theme,
    this.controller,
    this.useHorizontalLinkList = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final normalized = normalizePlainText(rawText);
    final urls = extractUrls(normalized);
    final text = removeUrls(normalized);

    final linkButtons = [
      for (int i = 0; i < urls.length; i++)
        Builder(
          builder: (context) {
            return PieMenu(
              theme: PieTheme.of(context).copyWith(
                overlayColor: theme.textColor.computeLuminance() > 0.5
                    ? Colors.black.withValues(alpha: 0.70)
                    : Colors.white.withValues(alpha: 0.70),
              ),
              actions: buildLinkPieActions(
                url: urls[i],
                ref: ref,
                context: context,
                theme: theme,
              ),
              child: OutlinedButton.icon(
                onPressed: () {
                  final urlToHandle = urls[i];
                  final localRef = ref;
                  final localContext = context;

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!localContext.mounted) return;

                    LinkHandler.handleLinkPress(
                      urlToHandle,
                      localRef,
                      localContext,
                    );
                  });
                },
                icon: Icon(
                  Icons.open_in_new,
                  color: theme.textColor,
                  size: 18,
                ),
                label: Text(
                  '${prettyUrlLabel(urls[i])}  •  ${i + 1}',
                  style: TextStyle(color: theme.textColor),
                ),
              ),
            );
          },
        ),
    ];

    final shouldUseHorizontalLinks =
        useHorizontalLinkList || MediaQuery.sizeOf(context).width < 620;

    return ListView(
      controller: controller,
      padding: const EdgeInsets.all(10),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        if (text.isNotEmpty)
          SelectableText(
            text,
            style: TextStyle(color: theme.textColor, fontSize: 14),
          ),
        if (urls.isNotEmpty) ...[
          const SizedBox(height: 12),
          Divider(color: theme.dashboardBoarder.withAlpha(160)),
          const SizedBox(height: 10),
          Text(
            'Links in the message'.tr,
            style: TextStyle(
              color: theme.textColor.withAlpha(180),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          shouldUseHorizontalLinks
              ? _HorizontalScrollList(
                  spacing: 8,
                  children: linkButtons,
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: linkButtons,
                ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}