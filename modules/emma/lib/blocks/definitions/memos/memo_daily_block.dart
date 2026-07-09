import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';

import '../../core/block_actions.dart';
import '../../core/block_definition.dart';
import '../../core/block_descriptor.dart';
import '../shared/block_ui.dart';

class MemoDailyBlockDefinition extends EmmaBlockDefinition {
  const MemoDailyBlockDefinition();

  @override
  String get key => 'memo_daily';

  @override
  bool supports(EmmaBlockDescriptor block) {
    return block.type == EmmaBlockType.memoDaily;
  }

  @override
  Widget buildBlock({
    required BuildContext context,
    required WidgetRef ref,
    required EmmaBlockDescriptor block,
    required double maxWidth,
    required String messageId,
  }) {
    return _MemoDailyBlockWidget(
      block: block.raw,
      maxWidth: maxWidth,
      messageId: messageId,
    );
  }
}

class _MemoDailyBlockWidget extends ConsumerWidget {
  final Map<String, dynamic> block;
  final double maxWidth;
  final String messageId;

  const _MemoDailyBlockWidget({
    required this.block,
    required this.maxWidth,
    required this.messageId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memo = _asMap(block['memo']);
    final summary = _asMap(block['summary']);
    final flow = _asMap(block['flow']);
    final sections = _asMapList(block['sections']);
    final quickActions = _asMapList(block['quick_actions']);

    final title = _text(memo['title']).isNotEmpty
        ? _text(memo['title'])
        : 'today_memo_title'.tr;

    final dateFor = _text(memo['date_for']);
    final source = _text(memo['source']);
    final delivery = _text(flow['delivery_channel']);

    final borderColor = _colorForMemo(summary);

    return EmmaBlockCardShell(
      maxWidth: maxWidth,
      borderColor: borderColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MemoHeader(
            title: title,
            dateFor: dateFor,
            source: source,
            delivery: delivery,
            summary: summary,
          ),
          const SizedBox(height: 14),
          _MemoSummaryWrap(summary: summary),
          if (sections.isNotEmpty) ...[
            const SizedBox(height: 14),
            ...sections.map(
              (section) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _MemoSectionCard(
                  section: section,
                  block: block,
                  messageId: messageId,
                ),
              ),
            ),
          ],
          if (quickActions.isNotEmpty) ...[
            const SizedBox(height: 8),
            _MemoQuickActions(
              actions: quickActions,
              block: block,
              messageId: messageId,
            ),
          ],
        ],
      ),
    );
  }

  Color _colorForMemo(Map<String, dynamic> summary) {
    final overdue = _int(summary['tasks_overdue_count']);
    final marketPulse = _text(summary['market_pulse_label']).toLowerCase();

    if (overdue > 0) return Colors.orangeAccent;
    if (marketPulse == 'hot') return Colors.redAccent;
    if (marketPulse == 'warm') return Colors.amberAccent;

    return const Color(0xFF37B6FF);
  }
}

class _MemoHeader extends StatelessWidget {
  final String title;
  final String dateFor;
  final String source;
  final String delivery;
  final Map<String, dynamic> summary;

  const _MemoHeader({
    required this.title,
    required this.dateFor,
    required this.source,
    required this.delivery,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final icon = _headerIcon(summary);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withAlpha(26),
            ),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'emma_memo_label'.tr,
                style: TextStyle(
                  color: Color(0xFF9EDBFF),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (dateFor.isNotEmpty)
                    _TinyBadge(
                      icon: Icons.event_rounded,
                      text: dateFor,
                    ),
                  if (source.isNotEmpty)
                    _TinyBadge(
                      icon: Icons.auto_awesome_rounded,
                      text: _sourceLabel(source),
                    ),
                  if (delivery.isNotEmpty)
                    _TinyBadge(
                      icon: Icons.chat_bubble_outline_rounded,
                      text: delivery,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _headerIcon(Map<String, dynamic> summary) {
    final marketCount = _int(summary['market_new_count']);
    final eventsCount = _int(summary['events_count']);
    final overdue = _int(summary['tasks_overdue_count']);
    final tasks = _int(summary['tasks_today_count']);
    final emails = _int(summary['emails_count']);

    if (overdue > 0 || tasks > 0) return Icons.task_alt_rounded;
    if (eventsCount > 0) return Icons.calendar_month_rounded;
    if (marketCount > 0) return Icons.trending_up_rounded;
    if (emails > 0) return Icons.mail_outline_rounded;

    return Icons.auto_awesome_rounded;
  }
}

class _MemoSummaryWrap extends StatelessWidget {
  final Map<String, dynamic> summary;

  const _MemoSummaryWrap({
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final events = _int(summary['events_count']);
    final emails = _int(summary['emails_count']);
    final tasksToday = _int(summary['tasks_today_count']);
    final tasksOverdue = _int(summary['tasks_overdue_count']);
    final market = _int(summary['market_new_count']);
    final pulse = _text(summary['market_pulse_label']);
    final velocity = summary['market_velocity_score'];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _SummaryChip(
          icon: Icons.calendar_today_rounded,
          label: 'meetings_label'.tr,
          value: events.toString(),
        ),
        _SummaryChip(
          icon: Icons.check_circle_outline_rounded,
          label: 'tasks_label'.tr,
          value: tasksToday.toString(),
        ),
        if (tasksOverdue > 0)
          _SummaryChip(
            icon: Icons.warning_amber_rounded,
            label: 'overdue_label'.tr,
            value: tasksOverdue.toString(),
            accent: Colors.orangeAccent,
          ),
        _SummaryChip(
          icon: Icons.mail_outline_rounded,
          label: 'emails_label'.tr,
          value: emails.toString(),
        ),
        if (market > 0)
          _SummaryChip(
            icon: Icons.trending_up_rounded,
            label: 'market_label'.tr,
            value: market.toString(),
          ),
        if (pulse.isNotEmpty)
          _SummaryChip(
            icon: Icons.speed_rounded,
            label: 'pulse_label'.tr,
            value: velocity == null ? pulse : '$pulse / $velocity',
          ),
      ],
    );
  }
}

class _MemoSectionCard extends ConsumerWidget {
  final Map<String, dynamic> section;
  final Map<String, dynamic> block;
  final String messageId;

  const _MemoSectionCard({
    required this.section,
    required this.block,
    required this.messageId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = _text(section['key']);
    final title = _text(section['title']).isNotEmpty
        ? _text(section['title'])
        : 'section_default_title'.tr;
    final count = _int(section['count']);
    final actions = _asMapList(section['actions']);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withAlpha(18),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            keyName: key,
            title: title,
            count: count,
          ),
          const SizedBox(height: 10),
          _SectionBody(section: section),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 10),
            _ActionWrap(
              actions: actions,
              block: block,
              messageId: messageId,
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String keyName;
  final String title;
  final int count;

  const _SectionHeader({
    required this.keyName,
    required this.title,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          _sectionIcon(keyName),
          color: _sectionColor(keyName),
          size: 17,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (count > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _sectionColor(keyName).withAlpha(28),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                color: _sectionColor(keyName),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }

  IconData _sectionIcon(String key) {
    switch (key) {
      case 'calendar':
        return Icons.calendar_month_rounded;
      case 'tasks':
        return Icons.task_alt_rounded;
      case 'email':
        return Icons.mail_outline_rounded;
      case 'market':
        return Icons.trending_up_rounded;
      default:
        return Icons.auto_awesome_rounded;
    }
  }

  Color _sectionColor(String key) {
    switch (key) {
      case 'calendar':
        return const Color(0xFF7FD8FF);
      case 'tasks':
        return Colors.greenAccent;
      case 'email':
        return const Color(0xFFBCA7FF);
      case 'market':
        return Colors.amberAccent;
      default:
        return Colors.white70;
    }
  }
}

class _SectionBody extends StatelessWidget {
  final Map<String, dynamic> section;

  const _SectionBody({
    required this.section,
  });

  @override
  Widget build(BuildContext context) {
    final key = _text(section['key']);

    switch (key) {
      case 'calendar':
        return _CalendarItems(items: _asMapList(section['items']));

      case 'tasks':
        return _TaskItems(items: _asMap(section['items']));

      case 'email':
        return _EmailItems(items: _asMapList(section['items']));

      case 'market':
        return _MarketItems(section: section);

      default:
        return _GenericItems(items: _asMapList(section['items']));
    }
  }
}

class _CalendarItems extends StatelessWidget {
  final List<Map<String, dynamic>> items;

  const _CalendarItems({
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return _MutedText('no_events_to_show'.tr);

    return Column(
      children: items.take(5).map((item) {
        final title = _text(item['title']).isNotEmpty
            ? _text(item['title'])
            : 'event_default_title'.tr;
        final time = _timeRange(item['start_time'], item['end_time']);
        final location = _text(item['location']);
        final client = _text(item['client_name']);

        return _MiniRow(
          icon: Icons.event_rounded,
          title: title,
          subtitle: [
            if (time.isNotEmpty) time,
            if (client.isNotEmpty) client,
            if (location.isNotEmpty) location,
          ].join(' • '),
        );
      }).toList(growable: false),
    );
  }
}

class _TaskItems extends StatelessWidget {
  final Map<String, dynamic> items;

  const _TaskItems({
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final today = _asMapList(items['today']);
    final overdue = _asMapList(items['overdue']);

    if (today.isEmpty && overdue.isEmpty) {
      return _MutedText('no_tasks_to_show'.tr);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (overdue.isNotEmpty) ...[
          _SmallSectionLabel(
            text: 'overdue_section_label'.tr,
            color: Colors.orangeAccent,
          ),
          const SizedBox(height: 6),
          ...overdue.take(4).map(
                (item) => _TaskRow(
                  item: item,
                  overdue: true,
                ),
              ),
          if (today.isNotEmpty) const SizedBox(height: 8),
        ],
        if (today.isNotEmpty) ...[
          _SmallSectionLabel(
            text: 'today_section_label'.tr,
            color: Colors.greenAccent,
          ),
          const SizedBox(height: 6),
          ...today.take(5).map(
                (item) => _TaskRow(
                  item: item,
                  overdue: false,
                ),
              ),
        ],
      ],
    );
  }
}

class _TaskRow extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool overdue;

  const _TaskRow({
    required this.item,
    required this.overdue,
  });

  @override
  Widget build(BuildContext context) {
    final title = _text(item['name']).isNotEmpty ? _text(item['name']) : 'task_default_title'.tr;
    final project = _text(item['project_name']);
    final deadline = _formatDateTime(item['deadline']);
    final priority = _text(item['priority']);

    return _MiniRow(
      icon: overdue ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
      iconColor: overdue ? Colors.orangeAccent : Colors.greenAccent,
      title: title,
      subtitle: [
        if (project.isNotEmpty) project,
        if (deadline.isNotEmpty) deadline,
        if (priority.isNotEmpty) '${'priority_prefix'.tr} $priority',
      ].join(' • '),
    );
  }
}

class _EmailItems extends StatelessWidget {
  final List<Map<String, dynamic>> items;

  const _EmailItems({
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return _MutedText('no_emails_to_show'.tr);

    return Column(
      children: items.take(5).map((item) {
        final subject = _text(item['subject']).isNotEmpty
            ? _text(item['subject'])
            : 'no_subject_label'.tr;
        final from = _text(item['sender_display_name']).isNotEmpty
            ? _text(item['sender_display_name'])
            : _text(item['from']);
        final received = _formatDateTime(item['received_at']);
        final unread = item['is_read'] != true;

        return _MiniRow(
          icon: unread ? Icons.mark_email_unread_rounded : Icons.mail_outline_rounded,
          iconColor: unread ? Colors.amberAccent : const Color(0xFFBCA7FF),
          title: subject,
          subtitle: [
            if (from.isNotEmpty) from,
            if (received.isNotEmpty) received,
          ].join(' • '),
        );
      }).toList(growable: false),
    );
  }
}

class _MarketItems extends StatelessWidget {
  final Map<String, dynamic> section;

  const _MarketItems({
    required this.section,
  });

  @override
  Widget build(BuildContext context) {
    final summary = _asMap(section['summary']);
    final items = _asMap(section['items']);
    final fastest = _asMapList(items['fastest_segments']);
    final narrative = _asMap(items['narrative']);
    final text = _text(summary['text']);

    final city = _text(summary['city']);
    final currency = _text(summary['currency']);
    final activeInventory = _int(summary['active_inventory']);
    final new24h = _int(summary['new_listings_24h']);
    final new7d = _int(summary['new_listings_7d']);
    final removed24h = _int(summary['removed_listings_24h']);
    final removed7d = _int(summary['removed_listings_7d']);
    final pulse = _text(summary['pulse_label']);
    final velocity = summary['velocity_score'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (text.isNotEmpty)
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withAlpha(205),
              fontSize: 12,
              height: 1.45,
            ),
          ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            if (city.isNotEmpty)
              _TinyBadge(
                icon: Icons.location_city_rounded,
                text: city,
              ),
            if (currency.isNotEmpty)
              _TinyBadge(
                icon: Icons.payments_outlined,
                text: currency,
              ),
            _TinyBadge(
              icon: Icons.inventory_2_outlined,
              text: '${'active_label'.tr} $activeInventory',
            ),
            _TinyBadge(
              icon: Icons.add_home_work_outlined,
              text: '${'last_24h_label'.tr} $new24h',
            ),
            _TinyBadge(
              icon: Icons.date_range_rounded,
              text: '${'last_7d_label'.tr} $new7d',
            ),
            if (removed24h > 0 || removed7d > 0)
              _TinyBadge(
                icon: Icons.remove_circle_outline_rounded,
                text: '${'removed_label'.tr} $removed24h / $removed7d',
              ),
            if (pulse.isNotEmpty)
              _TinyBadge(
                icon: Icons.speed_rounded,
                text: velocity == null ? pulse : '$pulse $velocity',
              ),
          ],
        ),
        if (fastest.isNotEmpty) ...[
          const SizedBox(height: 10),
          _SmallSectionLabel(
            text: 'fastest_segments_label'.tr,
            color: Colors.amberAccent,
          ),
          const SizedBox(height: 6),
          ...fastest.take(3).map((segment) {
            final propertyType = _text(segment['property_type']).isNotEmpty
                ? _text(segment['property_type'])
                : _text(segment['segment']).isNotEmpty
                    ? _text(segment['segment'])
                    : 'segment_default_label'.tr;

            final label = _text(segment['label']);
            final velocityScore = segment['velocity_score'];

            return _MiniRow(
              icon: Icons.bolt_rounded,
              iconColor: Colors.amberAccent,
              title: propertyType,
              subtitle: [
                if (label.isNotEmpty) label,
                if (velocityScore != null) '${'score_prefix'.tr} $velocityScore',
              ].join(' • '),
            );
          }),
        ],
        if (_asList(narrative['bullets']).isNotEmpty) ...[
          const SizedBox(height: 10),
          ..._asList(narrative['bullets']).take(3).map(
                (bullet) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• ${bullet.toString()}',
                    style: TextStyle(
                      color: Colors.white.withAlpha(190),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
        ],
      ],
    );
  }
}

class _GenericItems extends StatelessWidget {
  final List<Map<String, dynamic>> items;

  const _GenericItems({
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return _MutedText('no_items_to_show'.tr);

    return Column(
      children: items.take(5).map((item) {
        final title = _text(item['title']).isNotEmpty
            ? _text(item['title'])
            : _text(item['name']).isNotEmpty
                ? _text(item['name'])
                : 'item_default_title'.tr;

        return _MiniRow(
          icon: Icons.circle_outlined,
          title: title,
          subtitle: _text(item['description']),
        );
      }).toList(growable: false),
    );
  }
}

class _MemoQuickActions extends StatelessWidget {
  final List<Map<String, dynamic>> actions;
  final Map<String, dynamic> block;
  final String messageId;

  const _MemoQuickActions({
    required this.actions,
    required this.block,
    required this.messageId,
  });

  @override
  Widget build(BuildContext context) {
    return _ActionWrap(
      actions: actions,
      block: block,
      messageId: messageId,
      emphasized: true,
    );
  }
}

class _ActionWrap extends ConsumerWidget {
  final List<Map<String, dynamic>> actions;
  final Map<String, dynamic> block;
  final String messageId;
  final bool emphasized;

  const _ActionWrap({
    required this.actions,
    required this.block,
    required this.messageId,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: actions.map((action) {
        final label = _text(action['label']).isNotEmpty
            ? _text(action['label'])
            : _text(action['text']).isNotEmpty
                ? _text(action['text'])
                : 'action_default_label'.tr;

        return _ActionButton(
          label: label,
          emphasized: emphasized,
          onTap: () {
            runEmmaBlockAction(
              context: context,
              ref: ref,
              action: action,
              messageId: messageId,
              block: block,
            );
          },
        );
      }).toList(growable: false),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final bool emphasized;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.emphasized,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = emphasized
        ? const Color(0xFF37B6FF).withAlpha(45)
        : Colors.white.withAlpha(16);

    final border = emphasized
        ? const Color(0xFF37B6FF).withAlpha(110)
        : Colors.white.withAlpha(24);

    final textColor = emphasized ? const Color(0xFFBFEFFF) : Colors.white.withAlpha(220);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _MiniRow extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String subtitle;

  const _MiniRow({
    required this.icon,
    required this.title,
    this.iconColor,
    this.subtitle = '',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: iconColor ?? Colors.white.withAlpha(170),
            size: 15,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withAlpha(225),
                    fontSize: 12.3,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withAlpha(145),
                      fontSize: 11.2,
                      height: 1.25,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? accent;

  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.value,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final color = accent ?? const Color(0xFF9EDBFF);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withAlpha(42),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.white.withAlpha(165),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyBadge extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TinyBadge({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withAlpha(18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white.withAlpha(150),
            size: 12,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withAlpha(155),
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallSectionLabel extends StatelessWidget {
  final String text;
  final Color color;

  const _SmallSectionLabel({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: color,
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.4,
      ),
    );
  }
}

class _MutedText extends StatelessWidget {
  final String text;

  const _MutedText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withAlpha(145),
        fontSize: 12,
        height: 1.35,
      ),
    );
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

List<dynamic> _asList(dynamic value) {
  if (value is List) return value;
  return const [];
}

List<Map<String, dynamic>> _asMapList(dynamic value) {
  if (value is! List) return const <Map<String, dynamic>>[];

  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList(growable: false);
}

String _text(dynamic value) {
  if (value == null) return '';
  return value.toString().trim();
}

int _int(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.round();
  return int.tryParse(value.toString()) ?? 0;
}

String _sourceLabel(String source) {
  switch (source) {
    case 'scheduled':
      return 'automatic_source'.tr;
    case 'login_fallback':
      return 'after_login_source'.tr;
    case 'manual':
      return 'manual_source'.tr;
    default:
      return source;
  }
}

String _timeRange(dynamic startRaw, dynamic endRaw) {
  final start = _formatTime(startRaw);
  final end = _formatTime(endRaw);

  if (start.isEmpty && end.isEmpty) return '';
  if (start.isNotEmpty && end.isNotEmpty) return '$start–$end';
  return start.isNotEmpty ? start : end;
}

String _formatTime(dynamic raw) {
  final value = _text(raw);
  if (value.isEmpty) return '';

  final dt = DateTime.tryParse(value);
  if (dt == null) return value;

  final local = dt.toLocal();
  final h = local.hour.toString().padLeft(2, '0');
  final m = local.minute.toString().padLeft(2, '0');

  return '$h:$m';
}

String _formatDateTime(dynamic raw) {
  final value = _text(raw);
  if (value.isEmpty) return '';

  final dt = DateTime.tryParse(value);
  if (dt == null) return value;

  final local = dt.toLocal();
  final d = local.day.toString().padLeft(2, '0');
  final mo = local.month.toString().padLeft(2, '0');
  final h = local.hour.toString().padLeft(2, '0');
  final m = local.minute.toString().padLeft(2, '0');

  return '$d.$mo $h:$m';
}