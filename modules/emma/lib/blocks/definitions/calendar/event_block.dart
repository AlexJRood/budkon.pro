import 'package:calendar/state_managers/add_event_provider.dart';
import 'package:calendar/state_managers/appointments_provider.dart';
import 'package:calendar/state_managers/popup_calendar_provider.dart';
import 'package:calendar/widgets/save_event_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:intl/intl.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/route_constant.dart';

import 'package:emma/blocks/core/block_definition.dart';
import 'package:emma/blocks/core/block_descriptor.dart';
import 'package:emma/blocks/definitions/shared/block_ui.dart';

class CalendarEventBlockDefinition extends EmmaBlockDefinition {
  const CalendarEventBlockDefinition();

  @override
  String get key => 'calendar_event';

  @override
  bool supports(EmmaBlockDescriptor block) {
    return block.type == EmmaBlockType.calendarEvent;
  }

  @override
  Widget buildBlock({
    required BuildContext context,
    required WidgetRef ref,
    required EmmaBlockDescriptor block,
    required double maxWidth,
    required String messageId,
  }) {
    return _CalendarEventBlockCard(
      block: block,
      maxWidth: maxWidth,
    );
  }
}

class _CalendarOption {
  final int? id;
  final String name;
  final String? color;

  const _CalendarOption({
    required this.id,
    required this.name,
    required this.color,
  });

  factory _CalendarOption.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }

    return _CalendarOption(
      id: parseInt(json['id']),
      name: (json['name'] ?? '').toString(),
      color: json['color']?.toString(),
    );
  }
}

class _CalendarEventPayload {
  final String blockTitle;
  final int? eventId;
  final int? calendarId;
  final String title;
  final String calendarName;
  final String description;
  final String? location;
  final DateTime? start;
  final DateTime? end;
  final String? calendarColor;
  final String operation;
  final List<_CalendarOption> availableCalendars;

  const _CalendarEventPayload({
    required this.blockTitle,
    required this.eventId,
    required this.calendarId,
    required this.title,
    required this.calendarName,
    required this.description,
    required this.location,
    required this.start,
    required this.end,
    required this.calendarColor,
    required this.operation,
    required this.availableCalendars,
  });

  factory _CalendarEventPayload.fromBlock(EmmaBlockDescriptor block) {
    final raw = block.raw;
    final rawEvent = raw['event'] is Map
        ? Map<String, dynamic>.from(raw['event'] as Map)
        : Map<String, dynamic>.from(raw);

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      try {
        return DateTime.parse(value.toString()).toLocal();
      } catch (_) {
        return null;
      }
    }

    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }

    final rawCalendars = raw['available_calendars'] ?? rawEvent['available_calendars'];
    final calendars = rawCalendars is List
        ? rawCalendars
            .whereType<Map>()
            .map((e) => _CalendarOption.fromJson(Map<String, dynamic>.from(e)))
            .toList(growable: false)
        : const <_CalendarOption>[];

    return _CalendarEventPayload(
      blockTitle: (raw['title'] ?? 'Calendar event').toString(),
      eventId: parseInt(rawEvent['event_id']),
      calendarId: parseInt(rawEvent['calendar_id']),
      title: (rawEvent['title'] ?? 'Wydarzenie').toString(),
      calendarName: (rawEvent['calendar_name'] ?? 'Kalendarz').toString(),
      description: (rawEvent['description'] ?? '').toString(),
      location: rawEvent['location']?.toString(),
      start: parseDate(rawEvent['start_time']),
      end: parseDate(rawEvent['end_time']),
      calendarColor: rawEvent['calendar_color']?.toString(),
      operation: (raw['operation'] ?? 'create').toString(),
      availableCalendars: calendars,
    );
  }
}

class _CalendarEventBlockCard extends ConsumerStatefulWidget {
  final EmmaBlockDescriptor block;
  final double maxWidth;

  const _CalendarEventBlockCard({
    required this.block,
    required this.maxWidth,
  });

  @override
  ConsumerState<_CalendarEventBlockCard> createState() =>
      _CalendarEventBlockCardState();
}

class _CalendarEventBlockCardState
    extends ConsumerState<_CalendarEventBlockCard> {
  late final _CalendarEventPayload _payload;

  @override
  void initState() {
    super.initState();
    _payload = _CalendarEventPayload.fromBlock(widget.block);
    if (_payload.start != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(selectedDateProvider.notifier).state = _payload.start!;
        }
      });
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('dd.MM.yyyy HH:mm').format(dt);
  }

  Color _parseColor(String? raw, {Color fallback = Colors.greenAccent}) {
    if (raw == null || raw.trim().isEmpty) return fallback;
    var hex = raw.trim();
    if (hex.startsWith('#')) hex = hex.substring(1);
    if (hex.length == 6) hex = 'FF$hex';
    if (hex.length != 8) return fallback;
    final value = int.tryParse(hex, radix: 16);
    if (value == null) return fallback;
    return Color(value);
  }

  String _operationLabel(String operation, String blockTitle) {
    if (blockTitle.trim().isNotEmpty &&
        blockTitle.toLowerCase() != 'calendar event') {
      return blockTitle;
    }

    switch (operation) {
      case 'update':
        return 'emma_updated_event'.tr;
      case 'create':
      default:
        return 'emma_scheduled_event'.tr;
    }
  }

  Color _resolveAccent(_CalendarEventPayload payload) {
    if ((payload.calendarColor ?? '').trim().isNotEmpty) {
      return _parseColor(payload.calendarColor);
    }

    if (payload.calendarId != null) {
      for (final c in payload.availableCalendars) {
        if (c.id == payload.calendarId) {
          return _parseColor(c.color);
        }
      }
    }

    return Colors.greenAccent;
  }

  Future<void> _openEditor(
    BuildContext context,
    _CalendarEventPayload payload,
  ) async {
    if (payload.eventId == null || payload.start == null || payload.end == null) {
      return;
    }

    final current = ref.read(popupCalendarProvider).event;
    ref.read(appointmentsProvider).isEdit = true;
    ref.read(popupCalendarProvider).event = current.copyWith(
      id: payload.eventId.toString(),
      title: payload.title,
      from: payload.start,
      to: payload.end,
      location: payload.location ?? '',
      calendar: payload.calendarId?.toString() ?? '',
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
    _CalendarEventPayload payload,
  ) async {
    if (payload.start == null) return;
    ref.read(selectedDateProvider.notifier).state = payload.start!;
    ref.read(navigationService).pushNamedScreen(Routes.proCalendar);
  }

  Future<void> _changeCalendar(
    BuildContext context,
    _CalendarEventPayload payload,
    int calendarId,
  ) async {
    if (payload.eventId == null || payload.start == null || payload.end == null) {
      return;
    }

    final current = ref.read(popupCalendarProvider).event;
    ref.read(appointmentsProvider).isEdit = true;
    ref.read(popupCalendarProvider).event = current.copyWith(
      id: payload.eventId.toString(),
      title: payload.title,
      from: payload.start,
      to: payload.end,
      location: payload.location ?? '',
      calendar: calendarId.toString(),
    );

    await ref.read(addEventNotifierProvider.notifier).editEvent(ref);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(('calendar_changed'.tr))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final payload = _payload;
    final accent = _resolveAccent(payload);

    final startStr = _formatDate(payload.start);
    final endStr = _formatDate(payload.end);

    return EmmaBlockCardShell(
      maxWidth: widget.maxWidth,
      borderColor: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _operationLabel(payload.operation, payload.blockTitle),
            style: TextStyle(
              color: accent,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 56,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payload.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      payload.calendarName,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    if (startStr.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        endStr.isNotEmpty
                            ? '${'from'.tr}  $startStr · ${'to'.tr} $endStr'
                            : '${'start'.tr}: $startStr',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                        ),
                      ),
                    ],
                    if ((payload.location ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        payload.location!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                        ),
                      ),
                    ],
                    if (payload.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        payload.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withAlpha(175),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.event_available,
                size: 18,
                color: accent,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              EmmaActionPill(
                label: 'open'.tr,
                icon: Icons.open_in_new,
                onTap: () => _openEditor(context, payload),
              ),
              EmmaActionPill(
                label: 'show_in_calendar'.tr,
                icon: Icons.calendar_month_outlined,
                onTap: () => _showInCalendar(context, payload),
              ),
              if (payload.availableCalendars.isNotEmpty)
                PopupMenuButton<int>(
                  tooltip: 'change_calendar'.tr,
                  color: const Color(0xFF101010),
                  onSelected: (value) => _changeCalendar(context, payload, value),
                  itemBuilder: (_) {
                    return payload.availableCalendars
                        .where((e) => e.id != null)
                        .map((calendar) {
                      final color = _parseColor(
                        calendar.color,
                        fallback: Colors.white70,
                      );
                      return PopupMenuItem<int>(
                        value: calendar.id!,
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                calendar.name,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(growable: false);
                  },
                  child: EmmaActionPill(
                    label: 'change_calendar'.tr,
                    icon: Icons.swap_horiz,
                    onTap: null,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}