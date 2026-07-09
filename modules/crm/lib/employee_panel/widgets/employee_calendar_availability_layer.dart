// crm/calendar/widgets/employee_calendar_availability_layer.dart
// Adapter layer for any calendar implementation used in the app.

import 'package:crm/employee_panel/provider/employee_availability_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EmployeeCalendarAvailabilityEvent {
  final String id;
  final int employeeId;
  final String employeeName;
  final String title;
  final DateTime start;
  final DateTime end;
  final String kind;
  final String source;
  final Color color;
  final bool blocksBooking;
  final bool isBookable;
  final int priority;
  final String tooltip;

  const EmployeeCalendarAvailabilityEvent({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.title,
    required this.start,
    required this.end,
    required this.kind,
    required this.source,
    required this.color,
    required this.blocksBooking,
    required this.isBookable,
    required this.priority,
    required this.tooltip,
  });

  bool get isAbsence => source == 'absence';
  bool get isRule => source == 'availability_rule';
  bool get isBusy => blocksBooking || kind == 'busy';

  factory EmployeeCalendarAvailabilityEvent.fromBlock(EmployeeAvailabilityBlockModel block) {
    return EmployeeCalendarAvailabilityEvent(
      id: block.id,
      employeeId: block.employeeId,
      employeeName: block.employeeName,
      title: block.title,
      start: block.startAt,
      end: block.endAt,
      kind: block.kind,
      source: block.source,
      color: _hexToColor(block.color),
      blocksBooking: block.blocksBooking,
      isBookable: block.isBookable,
      priority: block.priority,
      tooltip: block.tooltip,
    );
  }
}

List<EmployeeCalendarAvailabilityEvent> mapEmployeeAvailabilityToCalendarEvents(
  List<EmployeeAvailabilityBlockModel> blocks, {
  bool collapseRulesWhenBlocked = true,
}) {
  final events = blocks
      .map(EmployeeCalendarAvailabilityEvent.fromBlock)
      .toList(growable: false);

  if (!collapseRulesWhenBlocked) return events;

  // For day cells: hide low-priority availability windows when a higher-priority
  // absence/busy block covers the same employee and date. In timeline views you
  // may want collapseRulesWhenBlocked=false to show all layers.
  return events.where((event) {
    if (!event.isRule) return true;
    return !events.any((other) {
      if (other.employeeId != event.employeeId) return false;
      if (other.priority <= event.priority) return false;
      if (!other.blocksBooking) return false;
      return _overlaps(event.start, event.end, other.start, other.end);
    });
  }).toList(growable: false);
}

class EmployeeCalendarAvailabilityLayer extends ConsumerWidget {
  final DateTime start;
  final DateTime end;
  final int? employeeId;
  final bool collapseRulesWhenBlocked;
  final Widget Function(
    BuildContext context,
    AsyncValue<List<EmployeeCalendarAvailabilityEvent>> state,
  ) builder;

  const EmployeeCalendarAvailabilityLayer({
    super.key,
    required this.start,
    required this.end,
    this.employeeId,
    this.collapseRulesWhenBlocked = true,
    required this.builder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(
      employeeAvailabilityCalendarProvider(
        EmployeeAvailabilityCalendarParams(
          start: _date(start),
          end: _date(end),
          employeeId: employeeId,
          includePending: true,
          includeRules: true,
          includeAbsences: true,
          includeOverrides: true,
          includeTimeEntries: true,
        ),
      ),
    );

    final mapped = state.whenData(
      (blocks) => mapEmployeeAvailabilityToCalendarEvents(
        blocks,
        collapseRulesWhenBlocked: collapseRulesWhenBlocked,
      ),
    );

    return builder(context, mapped);
  }
}

class EmployeeAvailabilityLegend extends StatelessWidget {
  const EmployeeAvailabilityLegend({super.key});

  @override
  Widget build(BuildContext context) {
    const items = [
      _LegendItem('Dostępny', Color(0xFF22C55E)),
      _LegendItem('Prezentacje', Color(0xFF0EA5E9)),
      _LegendItem('Zajęty', Color(0xFFF59E0B)),
      _LegendItem('Urlop / wolne', Color(0xFF22C55E)),
      _LegendItem('L4', Color(0xFFEF4444)),
      _LegendItem('Poza dostępnością', Color(0xFF64748B)),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: items,
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendItem(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

bool _overlaps(DateTime aStart, DateTime aEnd, DateTime bStart, DateTime bEnd) {
  return aStart.isBefore(bEnd) && aEnd.isAfter(bStart);
}

String _date(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}

Color _hexToColor(String value) {
  var hex = value.trim();
  if (!hex.startsWith('#')) hex = '#$hex';
  if (hex.length == 4) {
    final r = hex[1];
    final g = hex[2];
    final b = hex[3];
    hex = '#$r$r$g$g$b$b';
  }
  try {
    if (hex.length == 7) {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    }
  } catch (_) {}
  return const Color(0xFF64748B);
}
