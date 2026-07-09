import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';

import '../core/block_definition.dart';
import '../core/block_descriptor.dart';

class EmailListBlockDefinition extends EmmaBlockDefinition {
  const EmailListBlockDefinition();

  @override
  String get key => 'email_list';

  @override
  bool supports(EmmaBlockDescriptor block) {
    return block.type == EmmaBlockType.emailList;
  }

  @override
  Widget buildBlock({
    required BuildContext context,
    required WidgetRef ref,
    required EmmaBlockDescriptor block,
    required double maxWidth,
    required String messageId,
  }) {
    return _EmailListBlockCard(
      block: block,
      maxWidth: maxWidth,
      messageId: messageId,
    );
  }
}

class _EmailListItem {
  final int? id;
  final String from;
  final String subject;
  final String snippet;
  final String timelineAt;
  final bool isOutgoing;
  final bool isRead;
  final bool isEmma;
  final bool isEmmaDirectSend;
  final String currentTabName;
  final List<String> tagNames;

  const _EmailListItem({
    required this.id,
    required this.from,
    required this.subject,
    required this.snippet,
    required this.timelineAt,
    required this.isOutgoing,
    required this.isRead,
    required this.isEmma,
    required this.isEmmaDirectSend,
    required this.currentTabName,
    required this.tagNames,
  });

  factory _EmailListItem.fromRaw(Map<String, dynamic> raw) {
    List<String> listOf(dynamic value) {
      if (value is List) {
        return value.map((e) => e.toString()).toList(growable: false);
      }
      return const <String>[];
    }

    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }

    return _EmailListItem(
      id: parseInt(raw['id']),
      from: (raw['from'] ?? '').toString(),
      subject: (raw['subject'] ?? '').toString(),
      snippet: (raw['snippet'] ?? '').toString(),
      timelineAt: (raw['timeline_at'] ?? '').toString(),
      isOutgoing: raw['is_outgoing'] == true,
      isRead: raw['is_read'] == true,
      isEmma: raw['is_emma'] == true,
      isEmmaDirectSend: raw['is_emma_direct_send'] == true,
      currentTabName: (raw['current_tab_name'] ?? '').toString(),
      tagNames: listOf(raw['tag_names']),
    );
  }
}

class _EmailListPayload {
  final String title;
  final String folder;
  final List<_EmailListItem> items;
  final List<String> actions;
  final int? summaryCount;
  final int? summaryTotalCount;
  final int? summaryLimit;
  final bool summaryMarkedSeenByEmma;
  final String summarySource;
  final String summaryToolName;

  const _EmailListPayload({
    required this.title,
    required this.folder,
    required this.items,
    required this.actions,
    required this.summaryCount,
    required this.summaryTotalCount,
    required this.summaryLimit,
    required this.summaryMarkedSeenByEmma,
    required this.summarySource,
    required this.summaryToolName,
  });

  int get unreadCount => items.where((e) => !e.isRead).length;
  int get taggedCount => items.where((e) => e.tagNames.isNotEmpty).length;
  int get emmaCount => items.where((e) => e.isEmma).length;
  int get visibleCount => summaryCount ?? items.length;

  factory _EmailListPayload.fromBlock(EmmaBlockDescriptor block) {
    final rawItems = block.raw['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map((e) => _EmailListItem.fromRaw(Map<String, dynamic>.from(e)))
            .toList(growable: false)
        : const <_EmailListItem>[];

    List<String> listOf(dynamic value) {
      if (value is List) {
        return value.map((e) => e.toString()).toList(growable: false);
      }
      return const <String>[];
    }

    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }

    return _EmailListPayload(
      title: (block.raw['title'] ?? 'Wiadomości e-mail').toString(),
      folder: (block.raw['folder'] ?? '').toString(),
      items: items,
      actions: listOf(block.raw['actions']),
      summaryCount: parseInt(block.raw['summary_count']),
      summaryTotalCount: parseInt(block.raw['summary_total_count']),
      summaryLimit: parseInt(block.raw['summary_limit']),
      summaryMarkedSeenByEmma:
          block.raw['summary_marked_seen_by_emma'] == true,
      summarySource: (block.raw['summary_source'] ?? '').toString(),
      summaryToolName: (block.raw['summary_tool_name'] ?? '').toString(),
    );
  }
}

enum _HeaderQuickAction {
  answerLatestUnread,
  summarizeVisible,
  listReplyCandidates,
}

class _EmailListBlockCard extends StatefulWidget {
  final EmmaBlockDescriptor block;
  final double maxWidth;
  final String messageId;

  const _EmailListBlockCard({
    required this.block,
    required this.maxWidth,
    required this.messageId,
  });

  @override
  State<_EmailListBlockCard> createState() => _EmailListBlockCardState();
}

class _EmailListBlockCardState extends State<_EmailListBlockCard> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _formatDate(String raw) {
    if (raw.trim().isEmpty) return '';
    final dt = DateTime.tryParse(raw)?.toLocal();
    if (dt == null) return raw;

    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(dt.day)}.${two(dt.month)} ${two(dt.hour)}:${two(dt.minute)}';
  }

  String _shortText(String value, {int max = 180}) {
    final normalized = value.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= max) return normalized;
    return '${normalized.substring(0, max)}…';
  }

  Future<void> _copyPrompt(String prompt) async {
    await Clipboard.setData(ClipboardData(text: prompt));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('prompt_copied_to_emma'.tr),
      ),
    );
  }

  Future<void> _scrollBy(double delta) async {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    final target = (_scrollController.offset + delta)
        .clamp(0.0, position.maxScrollExtent)
        .toDouble();

    await _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  _EmailListItem? _latestUnread(_EmailListPayload payload) {
    for (final item in payload.items) {
      if (!item.isRead) return item;
    }
    if (payload.items.isNotEmpty) return payload.items.first;
    return null;
  }

  String _replyPrompt(_EmailListItem item) {
    final idPart = item.id != null ? '#${item.id}' :  'this_email'.tr;
    final subject = item.subject.trim().isEmpty ? 'no_subject'.tr : item.subject;
    final snippet = _shortText(item.snippet);

    return [
      'Przygotuj gotową odpowiedź na mail $idPart.',
      'Temat: "$subject".',
      'Od: ${item.from}.',
      if (snippet.isNotEmpty) 'Kontekst z podglądu: "$snippet".',
      'Odpowiedź napisz po polsku, konkretnie i profesjonalnie.',
      'Najpierw pokaż samą treść wiadomości gotową do wysłania.',
    ].join(' ');
  }

  String _summaryPrompt(_EmailListItem item) {
    final idPart = item.id != null ? '#${item.id}' : 'this_email'.tr;
    final subject = item.subject.trim().isEmpty ? 'no_subject'.tr : item.subject;
    final snippet = _shortText(item.snippet, max: 260);

    return [
      'Streść mail $idPart.',
      'Temat: "$subject".',
      'Od: ${item.from}.',
      if (snippet.isNotEmpty) 'Podgląd treści: "$snippet".',
      'Podaj 3 rzeczy: krótki sens wiadomości, czy wymaga odpowiedzi i jaki powinien być następny krok.',
    ].join(' ');
  }

  String _headerPrompt(
    _HeaderQuickAction action,
    _EmailListPayload payload,
  ) {
    switch (action) {
      case _HeaderQuickAction.answerLatestUnread:
        final item = _latestUnread(payload);
        if (item == null) {
          return 'Nie ma wiadomości na liście. Powiedz tylko, że skrzynka jest pusta.';
        }
        return _replyPrompt(item);

      case _HeaderQuickAction.summarizeVisible:
        return [
          'Streść listę aktualnie pokazanych maili.',
          'Podaj najważniejsze tematy, które wiadomości są nieprzeczytane i które wymagają pilnej odpowiedzi.',
          'Na końcu wypisz krótką listę priorytetów.',
        ].join(' ');

      case _HeaderQuickAction.listReplyCandidates:
        return [
          'Na podstawie tej listy maili wskaż, które wiadomości wymagają odpowiedzi.',
          'Ułóż je od najważniejszej do najmniej ważnej.',
          'Dla każdej napisz po 1 zdaniu: dlaczego warto odpowiedzieć i jaki ton odpowiedzi wybrać.',
        ].join(' ');
    }
  }

  Widget _chip({
    required String text,
    required Color color,
    Color? fill,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: fill ?? color.withAlpha(24),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(90)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 96),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withAlpha(170),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(
    _EmailListItem item,
    double cardWidth,
  ) {
    const accent = Color(0xFF37B6FF);

    return Container(
      width: cardWidth,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.isRead
              ? Colors.white.withAlpha(16)
              : accent.withAlpha(90),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (!item.isRead) ...[
                Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  item.subject.trim().isEmpty ? 'no_subject'.tr : item.subject,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: item.isRead
                        ? Colors.white.withAlpha(220)
                        : Colors.white,
                    fontSize: 14,
                    fontWeight:
                        item.isRead ? FontWeight.w700 : FontWeight.w800,
                    height: 1.2,
                  ),
                ),
              ),
              if (item.id != null) ...[
                const SizedBox(width: 8),
                Text(
                  '#${item.id}',
                  style: TextStyle(
                    color: Colors.white.withAlpha(120),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.from,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withAlpha(180),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Text(
              item.snippet.trim().isEmpty
                  ? 'no_content_preview'.tr
                  : item.snippet,
              maxLines: 7,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withAlpha(185),
                fontSize: 12,
                height: 1.45,
                fontStyle: item.snippet.trim().isEmpty
                    ? FontStyle.italic
                    : FontStyle.normal,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _chip(
                text: item.isOutgoing ? 'sent'.tr : 'received'.tr,
                color: item.isOutgoing
                    ? const Color(0xFF22C55E)
                    : const Color(0xFF60A5FA),
              ),
              if (item.isEmma)
                _chip(
                  text: 'Emma',
                  color: const Color(0xFFF472B6),
                ),
              if (item.isEmmaDirectSend)
                _chip(
                  text: 'Direct',
                  color: const Color(0xFF14B8A6),
                ),
              if (item.currentTabName.isNotEmpty)
                _chip(
                  text: item.currentTabName,
                  color: const Color(0xFFF59E0B),
                ),
              ...item.tagNames.take(3).map(
                    (tag) => _chip(
                      text: tag,
                      color: Colors.white70,
                      fill: Colors.white.withAlpha(10),
                    ),
                  ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () => _copyPrompt(_replyPrompt(item)),
                style: FilledButton.styleFrom(
                  backgroundColor: accent.withAlpha(220),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                icon: const Icon(Icons.auto_awesome_rounded, size: 15),
                label: Text('ask_for_reply'.tr),
              ),
              OutlinedButton.icon(
                onPressed: () => _copyPrompt(_summaryPrompt(item)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withAlpha(32)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                icon: const Icon(Icons.notes_rounded, size: 15),
                label:Text('summarize'.tr),
              ),
            ],
          ),
          if (item.timelineAt.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              _formatDate(item.timelineAt),
              style: TextStyle(
                color: Colors.white.withAlpha(130),
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final payload = _EmailListPayload.fromBlock(widget.block);

    const accent = Color(0xFF37B6FF);
    final availableWidth = widget.maxWidth.isFinite ? widget.maxWidth : 420.0;
    final cardWidth = ((availableWidth - 24) * 0.82).clamp(260.0, 420.0).toDouble();

    final summaryText = payload.summaryMarkedSeenByEmma
        ? 'Emma sprawdziła ${payload.visibleCount}'
            '${payload.summaryTotalCount != null ? ' z ${payload.summaryTotalCount}' : ''} maili.'
        : 'Pokazuję ${payload.visibleCount}'
            '${payload.summaryTotalCount != null ? ' z ${payload.summaryTotalCount}' : ''} maili.';

    return Container(
      margin: const EdgeInsets.only(left: 8, right: 8, top: 4, bottom: 8),
      padding: const EdgeInsets.all(12),
      constraints: BoxConstraints(maxWidth: widget.maxWidth),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(95),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accent.withAlpha(110),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: payload.items.isEmpty
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.mail_outline_rounded, color: accent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        payload.title,
                        style: TextStyle(
                          color: Colors.white.withAlpha(220),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'no_emails_to_display'.tr,
                  style: TextStyle(
                    color: Colors.white.withAlpha(170),
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.mail_outline_rounded, color: accent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        payload.title,
                        style: TextStyle(
                          color: Colors.white.withAlpha(220),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (payload.folder.isNotEmpty) ...[
                      _chip(
                        text: payload.folder,
                        color: accent,
                      ),
                      const SizedBox(width: 8),
                    ],
                    PopupMenuButton<_HeaderQuickAction>(
                      onSelected: (action) {
                        _copyPrompt(_headerPrompt(action, payload));
                      },
                      color: const Color(0xFF151515),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: _HeaderQuickAction.answerLatestUnread,
                          child: Text('ask_reply_latest_email'.tr),
                        ),
                        PopupMenuItem(
                          value: _HeaderQuickAction.summarizeVisible,
                          child: Text('summarize_this_list'.tr),
                        ),
                        PopupMenuItem(
                          value: _HeaderQuickAction.listReplyCandidates,
                          child: Text('suggest_emails_to_reply'.tr),
                        ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withAlpha(20),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: accent.withAlpha(80)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.auto_awesome_rounded,
                              size: 14,
                              color: accent,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'quick_actions'.tr,
                              style: TextStyle(
                                color: Colors.white.withAlpha(220),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withAlpha(16)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        summaryText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (payload.summarySource.isNotEmpty ||
                          payload.summaryToolName.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          [
                            if (payload.summarySource.isNotEmpty)
                              'source: ${payload.summarySource}',
                            if (payload.summaryToolName.isNotEmpty)
                              'tool: ${payload.summaryToolName}',
                          ].join(' · '),
                          style: TextStyle(
                            color: Colors.white.withAlpha(130),
                            fontSize: 11,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _metricTile(
                            label: 'checked'.tr,
                            value: '${payload.visibleCount}',
                            icon: Icons.mark_email_read_outlined,
                            color: const Color(0xFF22C55E),
                          ),
                          _metricTile(
                            label: 'unread'.tr,
                            value: '${payload.unreadCount}',
                            icon: Icons.mark_email_unread_outlined,
                            color: const Color(0xFF60A5FA),
                          ),
                          _metricTile(
                            label: 'tagged'.tr,
                            value: '${payload.taggedCount}',
                            icon: Icons.sell_outlined,
                            color: const Color(0xFFF59E0B),
                          ),
                          _metricTile(
                            label: 'all'.tr,
                            value: '${payload.summaryTotalCount ?? payload.items.length}',
                            icon: Icons.inbox_outlined,
                            color: const Color(0xFFF472B6),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (payload.items.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Text(
                          'swipe_to_see_more_emails'.tr,
                          style: TextStyle(
                            color: Colors.white.withAlpha(140),
                            fontSize: 11,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => _scrollBy(-cardWidth * 0.92),
                          tooltip: 'left'.tr,
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white70,
                            size: 16,
                          ),
                        ),
                        IconButton(
                          onPressed: () => _scrollBy(cardWidth * 0.92),
                          tooltip: 'right'.tr,
                          icon: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.white70,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(
                  height: 310,
                  child: ListView.separated(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: payload.items.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      return _buildItemCard(payload.items[index], cardWidth);
                    },
                  ),
                ),
              ],
            ),
    );
  }
}