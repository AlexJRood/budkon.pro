// crm/employee_panel/calendar/employee_availability_calendar_adapter.dart
// Generic adapter for showing employee availability in your calendar module.
// It does not depend on a specific calendar package: you can map the markers
// returned here into your own AgentCalendar event model.

import 'package:crm/employee_panel/provider/employee_managment_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';

class EmployeeAvailabilityMarker {
  final int id;
  final int employeeId;
  final String employeeName;
  final String title;
  final DateTime start;
  final DateTime end;
  final String status;
  final String availabilityKind;
  final String absenceTypeKey;
  final String absenceTypeName;
  final bool blocksAvailability;
  final bool isPending;
  final Color color;
  final String tooltip;

  const EmployeeAvailabilityMarker({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.title,
    required this.start,
    required this.end,
    required this.status,
    required this.availabilityKind,
    required this.absenceTypeKey,
    required this.absenceTypeName,
    required this.blocksAvailability,
    required this.isPending,
    required this.color,
    required this.tooltip,
  });

  bool occursOn(DateTime day) {
    final normalized = DateTime(day.year, day.month, day.day);
    return !normalized.isBefore(DateTime(start.year, start.month, start.day)) &&
        !normalized.isAfter(DateTime(end.year, end.month, end.day));
  }
}

List<EmployeeAvailabilityMarker> mapEmployeeAvailabilityMarkers(
  List<EmployeeAvailabilityEventModel> events,
) {
  return events.map((event) {
    return EmployeeAvailabilityMarker(
      id: event.id,
      employeeId: event.employeeId,
      employeeName: event.employeeName,
      title: event.title,
      start: DateTime.tryParse(event.startDate) ?? DateTime.now(),
      end: DateTime.tryParse(event.endDate) ?? DateTime.now(),
      status: event.status,
      availabilityKind: event.availabilityKind,
      absenceTypeKey: event.absenceTypeKey,
      absenceTypeName: event.absenceTypeName,
      blocksAvailability: event.blocksAvailability,
      isPending: event.isPending,
      color: _hexToColor(event.calendarColor),
      tooltip: event.tooltip,
    );
  }).toList(growable: false);
}

class EmployeeAvailabilityCalendarStrip extends ConsumerWidget {
  final DateTime start;
  final DateTime end;
  final int? employeeId;
  final bool includePending;
  final int maxItems;

  const EmployeeAvailabilityCalendarStrip({
    super.key,
    required this.start,
    required this.end,
    this.employeeId,
    this.includePending = true,
    this.maxItems = 5,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final state = ref.watch(
      employeeAvailabilityProvider(
        EmployeeAvailabilityParams(
          start: _date(start),
          end: _date(end),
          employeeId: employeeId,
          includePending: includePending,
        ),
      ),
    );

    return state.when(
      loading: () => const SizedBox(
        height: 34,
        child: Center(child: LinearProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (events) {
        if (events.isEmpty) {
          return Text(
            'all_employees_available'.tr,
            style: TextStyle(color: theme.textColor.withAlpha(150), fontSize: 12),
          );
        }

        final visible = events.take(maxItems).toList(growable: false);
        final hidden = events.length - visible.length;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final event in visible) ...[
                _AvailabilityChip(event: event),
                const SizedBox(width: 8),
              ],
              if (hidden > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.themeColor.withAlpha(12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: theme.dashboardBoarder),
                  ),
                  child: Text(
                    '+$hidden',
                    style: TextStyle(
                      color: theme.textColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _AvailabilityChip extends ConsumerWidget {
  final EmployeeAvailabilityEventModel event;

  const _AvailabilityChip({required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    return Tooltip(
      message: event.tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _hexToColor(event.calendarColor).withAlpha(event.isPending ? 40 : 70),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: theme.dashboardBoarder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _availabilityIcon(event.availabilityKind),
              size: 14,
              color: theme.textColor,
            ),
            const SizedBox(width: 6),
            Text(
              event.employeeName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: theme.textColor,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (event.isPending) ...[
              const SizedBox(width: 6),
              Text(
                'pending'.tr,
                style: TextStyle(
                  color: theme.textColor.withAlpha(160),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

IconData _availabilityIcon(String value) {
  switch (value) {
    case 'sick':
      return Icons.healing_outlined;
    case 'remote':
      return Icons.home_work_outlined;
    case 'business_trip':
      return Icons.flight_takeoff_outlined;
    case 'out_of_office':
      return Icons.event_busy_outlined;
    default:
      return Icons.check_circle_outline;
  }
}

Color _hexToColor(String hex) {
  var value = hex.trim();
  if (!value.startsWith('#')) value = '#$value';
  if (value.length == 4) {
    final r = value[1];
    final g = value[2];
    final b = value[3];
    value = '#$r$r$g$g$b$b';
  }
  try {
    if (value.length == 7) {
      return Color(int.parse(value.replaceFirst('#', '0xFF')));
    }
  } catch (_) {}
  return Colors.orange;
}

String _date(DateTime value) {
  return '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
