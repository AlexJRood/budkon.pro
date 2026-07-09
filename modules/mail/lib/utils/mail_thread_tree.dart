import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';

import '../models/mail_models.dart';

enum MailListViewMode {
  flat,
  tree,
}

final mailListViewModeProvider =
    StateProvider<MailListViewMode>((ref) => MailListViewMode.flat);

class MailTreeNode {
  final EmailMessage email;
  final List<MailTreeNode> children;

  MailTreeNode({
    required this.email,
    List<MailTreeNode>? children,
  }) : children = children ?? <MailTreeNode>[];
}

class MailTreeThread {
  final String threadId;
  final EmailMessage summaryEmail;
  final List<MailTreeNode> roots;
  final int totalCount;
  final DateTime latestAt;
  final Set<int> emailIds;

  const MailTreeThread({
    required this.threadId,
    required this.summaryEmail,
    required this.roots,
    required this.totalCount,
    required this.latestAt,
    required this.emailIds,
  });
}

class MailTreeRow {
  final EmailMessage email;
  final String threadId;
  final int depth;
  final bool canToggleThread;
  final bool isThreadExpanded;
  final int hiddenChildrenCount;

  const MailTreeRow({
    required this.email,
    required this.threadId,
    required this.depth,
    required this.canToggleThread,
    required this.isThreadExpanded,
    required this.hiddenChildrenCount,
  });
}

// Strips angle brackets from RFC 2822 message-id strings and trims whitespace.
// "<abc@mail.com>" -> "abc@mail.com"
String _normMsgId(String? raw) {
  if (raw == null) return '';
  var s = raw.trim();
  if (s.length > 2 && s.startsWith('<') && s.endsWith('>')) {
    s = s.substring(1, s.length - 1).trim();
  }
  return s;
}

String threadIdOfMail(EmailMessage email) {
  final replyTo = _normMsgId(email.inReplyTo);
  if (replyTo.isNotEmpty) return replyTo;
  final msgId = _normMsgId(email.messageId);
  if (msgId.isNotEmpty) return msgId;
  return 'single_${email.id}';
}

String? _parentMessageIdOf(EmailMessage email) {
  final raw = _normMsgId(email.inReplyTo);
  return raw.isEmpty ? null : raw;
}

DateTime _timelineOf(EmailMessage email) {
  final candidates = <String?>[
    email.timelineAtIso,
    email.receivedAt,
    email.sentAt,
    email.createdAt,
    email.updatedAt,
  ];

  for (final raw in candidates) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) continue;

    final parsed = DateTime.tryParse(value);
    if (parsed != null) {
      return parsed;
    }
  }

  return DateTime.fromMillisecondsSinceEpoch(0);
}

String _nodeKeyOf(EmailMessage email) {
  final msgId = _normMsgId(email.messageId);
  if (msgId.isNotEmpty) return msgId;
  return 'local_${email.id}';
}

void _sortTreeNodeRecursive(MailTreeNode node) {
  node.children.sort(
    (a, b) => _timelineOf(a.email).compareTo(_timelineOf(b.email)),
  );

  for (final child in node.children) {
    _sortTreeNodeRecursive(child);
  }
}

String _resolveThreadRootId(
  EmailMessage email,
  Map<String, EmailMessage> byMessageId,
) {
  final visited = <String>{};
  EmailMessage current = email;
  // Track the ID of the deepest ancestor we successfully loaded.
  String? lastKnownId;
  int stepsWalked = 0;

  while (true) {
    final currentMsgId = _normMsgId(current.messageId);
    if (currentMsgId.isNotEmpty) {
      if (!visited.add(currentMsgId)) {
        // Cycle — stop here and use whatever we know.
        break;
      }
      lastKnownId = currentMsgId;
    }

    final parentMsgId = _normMsgId(current.inReplyTo);
    if (parentMsgId.isEmpty) {
      // Root email — no parent.
      return lastKnownId ?? 'single_${current.id}';
    }

    final parent = byMessageId[parentMsgId];
    if (parent == null) {
      // Parent not yet loaded.
      // If we walked at least one step we already found a loaded ancestor —
      // anchor the chain there so partial threads stay together instead of
      // fragmenting on the missing link.
      if (stepsWalked > 0 && lastKnownId != null) {
        return lastKnownId;
      }
      // First hop missing: use the parent's ID directly so sibling replies
      // (same inReplyTo) are still grouped together.
      return parentMsgId;
    }

    current = parent;
    stepsWalked++;
  }

  return lastKnownId ?? 'single_${current.id}';
}

List<MailTreeThread> buildMailTreeThreads(List<EmailMessage> items) {
  // Keyed by normalized messageId so inReplyTo lookups always match
  // regardless of whether the header value uses angle-bracket format.
  final byMessageId = <String, EmailMessage>{};
  for (final email in items) {
    final msgId = _normMsgId(email.messageId);
    if (msgId.isNotEmpty) {
      byMessageId[msgId] = email;
    }
  }

  final grouped = <String, List<EmailMessage>>{};
  for (final email in items) {
    final threadId = _resolveThreadRootId(email, byMessageId);
    grouped.putIfAbsent(threadId, () => <EmailMessage>[]).add(email);
  }

  final threads = <MailTreeThread>[];

  for (final entry in grouped.entries) {
    final threadItems = [...entry.value]
      ..sort((a, b) => _timelineOf(a).compareTo(_timelineOf(b)));

    // nodeByKey uses the same normalized key as byMessageId so parent lookups
    // via _parentMessageIdOf (which also normalizes) always hit correctly.
    final nodeByKey = <String, MailTreeNode>{};
    for (final email in threadItems) {
      nodeByKey[_nodeKeyOf(email)] = MailTreeNode(email: email);
    }

    final roots = <MailTreeNode>[];

    for (final email in threadItems) {
      final node = nodeByKey[_nodeKeyOf(email)]!;
      final parentKey = _parentMessageIdOf(email);
      final parentNode = parentKey != null ? nodeByKey[parentKey] : null;

      if (parentNode != null && !identical(parentNode, node)) {
        parentNode.children.add(node);
      } else {
        roots.add(node);
      }
    }

    roots.sort(
      (a, b) => _timelineOf(a.email).compareTo(_timelineOf(b.email)),
    );

    for (final root in roots) {
      _sortTreeNodeRecursive(root);
    }

    final summaryEmail = threadItems.last;
    final latestAt = _timelineOf(summaryEmail);

    threads.add(
      MailTreeThread(
        threadId: entry.key,
        summaryEmail: summaryEmail,
        roots: roots,
        totalCount: threadItems.length,
        latestAt: latestAt,
        emailIds: threadItems.map((e) => e.id).toSet(),
      ),
    );
  }

  threads.sort((a, b) => b.latestAt.compareTo(a.latestAt));
  return threads;
}

void _appendNodeRows({
  required List<MailTreeRow> rows,
  required MailTreeNode node,
  required String threadId,
  required int depth,
  required bool canToggleOnThisRow,
  required bool isThreadExpanded,
  required int hiddenChildrenCount,
}) {
  rows.add(
    MailTreeRow(
      email: node.email,
      threadId: threadId,
      depth: depth,
      canToggleThread: canToggleOnThisRow,
      isThreadExpanded: isThreadExpanded,
      hiddenChildrenCount: hiddenChildrenCount,
    ),
  );

  for (final child in node.children) {
    _appendNodeRows(
      rows: rows,
      node: child,
      threadId: threadId,
      depth: depth + 1,
      canToggleOnThisRow: false,
      isThreadExpanded: isThreadExpanded,
      hiddenChildrenCount: 0,
    );
  }
}

List<MailTreeRow> buildMailTreeRows(
  List<EmailMessage> items, {
  required Set<String> expandedThreadIds,
  int? selectedEmailId,
}) {
  final threads = buildMailTreeThreads(items);
  final rows = <MailTreeRow>[];

  for (final thread in threads) {
    final containsSelected = selectedEmailId != null &&
        thread.emailIds.contains(selectedEmailId);

    final isExpanded = thread.totalCount > 1 &&
        (expandedThreadIds.contains(thread.threadId) || containsSelected);

    if (!isExpanded) {
      rows.add(
        MailTreeRow(
          email: thread.summaryEmail,
          threadId: thread.threadId,
          depth: 0,
          canToggleThread: thread.totalCount > 1,
          isThreadExpanded: false,
          hiddenChildrenCount:
              thread.totalCount > 1 ? thread.totalCount - 1 : 0,
        ),
      );
      continue;
    }

    var firstRootHandled = false;
    for (final root in thread.roots) {
      _appendNodeRows(
        rows: rows,
        node: root,
        threadId: thread.threadId,
        depth: 0,
        canToggleOnThisRow: !firstRootHandled && thread.totalCount > 1,
        isThreadExpanded: true,
        hiddenChildrenCount: thread.totalCount - 1,
      );
      firstRootHandled = true;
    }
  }

  return rows;
}

class MailViewModeSwitcher extends ConsumerWidget {
  const MailViewModeSwitcher({super.key});

  Widget _buildItem({
    required ThemeColors theme,
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? theme.themeColor.withAlpha(28)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? theme.themeColor.withAlpha(120)
                  : theme.dashboardBoarder.withAlpha(120),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? theme.themeColor : theme.textColor,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? theme.themeColor : theme.textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final isTreeMode =
        ref.watch(mailListViewModeProvider) == MailListViewMode.tree;

    return Row(
      children: [
        _buildItem(
          theme: theme,
          label: 'Flat list'.tr,
          icon: Icons.view_stream_outlined,
          selected: !isTreeMode,
          onTap: () {
            ref.read(mailListViewModeProvider.notifier).state =
                MailListViewMode.flat;
          },
        ),
        const SizedBox(width: 10),
        _buildItem(
          theme: theme,
          label: 'Mail tree'.tr,
          icon: Icons.account_tree_outlined,
          selected: isTreeMode,
          onTap: () {
            ref.read(mailListViewModeProvider.notifier).state =
                MailListViewMode.tree;
          },
        ),
      ],
    );
  }
}
