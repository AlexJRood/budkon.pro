import 'package:calendar/state_managers/appointments_provider.dart';
import 'package:calendar/state_managers/popup_calendar_provider.dart';
import 'package:calendar/widgets/save_event_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:intl/intl.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:calendar/state_managers/selected_date_provider.dart';
import 'package:core/platform/route_constant.dart';

import 'package:emma/blocks/core/block_definition.dart';
import 'package:emma/blocks/core/block_descriptor.dart';
import 'package:emma/blocks/definitions/shared/block_ui.dart';

class CalendarEventListBlockDefinition extends EmmaBlockDefinition {
  const CalendarEventListBlockDefinition();

  @override
  String get key => 'calendar_event_list';

  @override
  bool supports(EmmaBlockDescriptor block) {
    return block.type == EmmaBlockType.calendarEventList;
  }

  @override
  Widget buildBlock({
    required BuildContext context,
    required WidgetRef ref,
    required EmmaBlockDescriptor block,
    required double maxWidth,
    required String messageId,
  }) {
    return _CalendarEventListBlockCard(
      block: block,
      maxWidth: maxWidth,
    );
  }
}

class _CalendarListItem {
  final int? eventId;
  final int? calendarId;
  final String title;
  final String calendarName;
  final String description;
  final String? location;
  final DateTime? start;
  final DateTime? end;
  final int? clientId;
  final String? clientName;

  const _CalendarListItem({
    required this.eventId,
    required this.calendarId,
    required this.title,
    required this.calendarName,
    required this.description,
    required this.location,
    required this.start,
    required this.end,
    required this.clientId,
    required this.clientName,
  });

  factory _CalendarListItem.fromRaw(Map<String, dynamic> raw) {
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      try {
        return DateTime.parse(value.toString()).toLocal();
      } catch (_) {
        return null;
      }
    }

    return _CalendarListItem(
      eventId: parseInt(raw['event_id']),
      calendarId: parseInt(raw['calendar_id']),
      title: (raw['title'] ?? 'Wydarzenie').toString(),
      calendarName: (raw['calendar_name'] ?? 'Kalendarz').toString(),
      description: (raw['description'] ?? '').toString(),
      location: raw['location']?.toString(),
      start: parseDate(raw['start_time']),
      end: parseDate(raw['end_time']),
      clientId: parseInt(raw['client_id']),
      clientName: raw['client_name']?.toString(),
    );
  }
}

class _CalendarEventListPayload {
  final String title;
  final List<_CalendarListItem> items;
  final int? totalCount;
  final int? hoursAhead;
  final String summaryText;

  const _CalendarEventListPayload({
    required this.title,
    required this.items,
    required this.totalCount,
    required this.hoursAhead,
    required this.summaryText,
  });

  factory _CalendarEventListPayload.fromBlock(EmmaBlockDescriptor block) {
    final raw = block.raw;
    final rawItems = raw['items'];

    final items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map((e) => _CalendarListItem.fromRaw(Map<String, dynamic>.from(e)))
            .toList(growable: false)
        : const <_CalendarListItem>[];

    final summaryRaw = raw['summary'];
    final summary = summaryRaw is Map
        ? Map<String, dynamic>.from(summaryRaw)
        : <String, dynamic>{};

    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }

    return _CalendarEventListPayload(
      title: (raw['title'] ?? 'Nadchodzące wydarzenia').toString(),
      items: items,
      totalCount: parseInt(summary['count'] ?? raw['count'] ?? raw['total_count']),
      hoursAhead: parseInt(summary['hours_ahead'] ?? raw['hours_ahead']),
      summaryText: (summary['text'] ?? '').toString(),
    );
  }
}

class _CalendarEventListBlockCard extends ConsumerWidget {
  final EmmaBlockDescriptor block;
  final double maxWidth;

  const _CalendarEventListBlockCard({
    required this.block,
    required this.maxWidth,
  });

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('dd.MM.yyyy HH:mm').format(dt);
  }

  Future<void> _openItem(
    BuildContext context,
    WidgetRef ref,
    _CalendarListItem item,
  ) async {
    if (item.eventId == null || item.start == null || item.end == null) return;

    final current = ref.read(popupCalendarProvider).event;
    ref.read(appointmentsProvider).isEdit = true;
    ref.read(popupCalendarProvider).event = current.copyWith(
      id: item.eventId.toString(),
      title: item.title,
      from: item.start,
      to: item.end,
      location: item.location ?? '',
      calendar: item.calendarId?.toString() ?? '',
    );

    final isMobile = MediaQuery.of(context).size.width < 650;

    if (isMobile) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) {
          return DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) => SaveEventWidget(
              isMobile: true,
              scrollController: scrollController,
              index: 0,
            ),
          );
        },
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (_) => const Dialog(
        child: SaveEventWidget(
          index: 0,
          isMobile: false,
        ),
      ),
    );
  }

  Future<void> _showInCalendar(
    BuildContext context,
    WidgetRef ref,
    _CalendarListItem item,
  ) async {
    if (item.start == null) return;
    ref.read(selectedDateProvider.notifier).state = item.start!;
    ref.read(navigationService).pushNamedScreen(Routes.proCalendar);
  }

  Future<void> _openCalendar(
    BuildContext context,
    WidgetRef ref,
  ) async {
    ref.read(navigationService).pushNamedScreen(Routes.proCalendar);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payload = _CalendarEventListPayload.fromBlock(block);

    return EmmaBlockCardShell(
      maxWidth: maxWidth,
      borderColor: Colors.greenAccent,
      child: payload.items.isEmpty
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Text(
                  'emma_checked_calendar'.tr,
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  payload.summaryText.trim().isNotEmpty
                      ? payload.summaryText
                      : 'no_upcoming_events'.tr,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 10),
                EmmaActionPill(
                  label: 'open_calendar'.tr,
                  icon: Icons.open_in_new,
                  onTap: () => _openCalendar(context, ref),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Text(
                  'emma_fetched_events_list'.tr,
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  payload.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (payload.summaryText.trim().isNotEmpty ||
                    payload.totalCount != null ||
                    payload.hoursAhead != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (payload.summaryText.trim().isNotEmpty) payload.summaryText,
                      if (payload.totalCount != null) '${'count'.tr}: ${payload.totalCount}',
                      if (payload.hoursAhead != null) '${'range'.tr}: ${payload.hoursAhead}h',
                    ].join(' · '),
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                ...payload.items.map(
                  (item) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.calendarName,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        if (item.start != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            item.end != null
                                ? '${'from'.tr}  ${_formatDate(item.start)} · ${'to'.tr} ${_formatDate(item.end)}'
                                : _formatDate(item.start),
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                            ),
                          ),
                        ],
                        if ((item.location ?? '').trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            item.location!,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                            ),
                          ),
                        ],
                        if ((item.clientName ?? '').trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${'client'.tr}: ${item.clientName}',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                            ),
                          ),
                        ],
                        if (item.description.trim().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            item.description,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withAlpha(170),
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            EmmaActionPill(
                              label: 'open'.tr,
                              icon: Icons.open_in_new,
                              onTap: () => _openItem(context, ref, item),
                            ),
                            EmmaActionPill(
                              label: 'show_in_calendar'.tr,
                              icon: Icons.calendar_month_outlined,
                              onTap: () => _showInCalendar(context, ref, item),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                EmmaActionPill(
                  label: 'open_calendar'.tr,
                  icon: Icons.open_in_new,
                  onTap: () => _openCalendar(context, ref),
                ),
              ],
            ),
    );
  }
}