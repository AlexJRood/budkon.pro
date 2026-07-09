// crm/calendar/widgets/member_calendar_hr_layer.dart

import 'package:crm/calendar/provider/member_calendar_layer_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:calendar/settings/week_start_day_time_format.dart';
import 'package:calendar/settings/calendar_settings.dart';
import 'package:calendar/settings/calendar_settings_provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart' as sf_cal;
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/text_field.dart';
import 'package:core/ui/device_type_util.dart';

class MemberCalendarHrLayer extends ConsumerWidget {
  final int memberId;
  final DateTime rangeStart;
  final DateTime rangeEnd;
  final int? companyId;
  final bool includeEvents;
  final bool includeAvailability;
  final bool includePending;
  final bool includeRules;
  final bool includeAbsences;
  final bool includeOverrides;
  final bool includeTimeEntries;
  final bool includePublicHolidays;
  final bool skipRulesOnPublicHolidays;
  final String publicHolidayCountry;
  final bool collapseAvailabilityRules;
  final Widget Function(
    BuildContext context,
    AsyncValue<List<CalendarLayerItemModel>> state,
  ) builder;

  const MemberCalendarHrLayer({
    super.key,
    required this.memberId,
    required this.rangeStart,
    required this.rangeEnd,
    this.companyId,
    this.includeEvents = true,
    this.includeAvailability = true,
    this.includePending = true,
    this.includeRules = true,
    this.includeAbsences = true,
    this.includeOverrides = true,
    this.includeTimeEntries = true,
    this.includePublicHolidays = true,
    this.skipRulesOnPublicHolidays = true,
    this.publicHolidayCountry = 'PL',
    this.collapseAvailabilityRules = true,
    required this.builder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(
      memberCalendarLayerProvider(
        MemberCalendarLayerParams(
          memberId: memberId,
          rangeStart: rangeStart,
          rangeEnd: rangeEnd,
          companyId: companyId,
          includeEvents: includeEvents,
          includeAvailability: includeAvailability,
          includePending: includePending,
          includeRules: includeRules,
          includeAbsences: includeAbsences,
          includeOverrides: includeOverrides,
          includeTimeEntries: includeTimeEntries,
          includePublicHolidays: includePublicHolidays,
          skipRulesOnPublicHolidays: skipRulesOnPublicHolidays,
          publicHolidayCountry: publicHolidayCountry,
        ),
      ),
    );

    final mapped = state.whenData((value) {
      final items = value.items;
      if (!collapseAvailabilityRules) return items;
      return collapseCalendarAvailabilityRules(items);
    });

    return builder(context, mapped);
  }
}

class TeamAvailabilityHrLayer extends ConsumerWidget {
  final DateTime rangeStart;
  final DateTime rangeEnd;
  final int? companyId;
  final List<int> employeeIds;
  final bool bootstrapDefaults;
  final bool includePending;
  final bool includeRules;
  final bool includeAbsences;
  final bool includeOverrides;
  final bool includeTimeEntries;
  final bool includePublicHolidays;
  final bool skipRulesOnPublicHolidays;
  final String publicHolidayCountry;
  final bool collapseAvailabilityRules;
  final Widget Function(
    BuildContext context,
    AsyncValue<List<CalendarLayerItemModel>> state,
  ) builder;

  const TeamAvailabilityHrLayer({
    super.key,
    required this.rangeStart,
    required this.rangeEnd,
    this.companyId,
    this.employeeIds = const [],
    this.bootstrapDefaults = false,
    this.includePending = true,
    this.includeRules = true,
    this.includeAbsences = true,
    this.includeOverrides = true,
    this.includeTimeEntries = true,
    this.includePublicHolidays = true,
    this.skipRulesOnPublicHolidays = true,
    this.publicHolidayCountry = 'PL',
    this.collapseAvailabilityRules = true,
    required this.builder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(
      teamAvailabilityLayerProvider(
        TeamAvailabilityLayerParams(
          rangeStart: rangeStart,
          rangeEnd: rangeEnd,
          companyId: companyId,
          employeeIds: employeeIds,
          bootstrapDefaults: bootstrapDefaults,
          includePending: includePending,
          includeRules: includeRules,
          includeAbsences: includeAbsences,
          includeOverrides: includeOverrides,
          includeTimeEntries: includeTimeEntries,
          includePublicHolidays: includePublicHolidays,
          skipRulesOnPublicHolidays: skipRulesOnPublicHolidays,
          publicHolidayCountry: publicHolidayCountry,
        ),
      ),
    );

    final mapped = state.whenData((items) {
      if (!collapseAvailabilityRules) return items;
      return collapseCalendarAvailabilityRules(items);
    });

    return builder(context, mapped);
  }
}

class EmployeeHrCalendarPreview extends ConsumerStatefulWidget {
  final int memberId;
  final int? companyId;
  final DateTime? initialDate;
  final double? height;
  final bool initiallyShowEvents;
  final bool initiallyShowAvailability;
  final bool initiallyShowPublicHolidays;
  final bool collapseAvailabilityRules;
  final bool skipRulesOnPublicHolidays;
  final String publicHolidayCountry;

  const EmployeeHrCalendarPreview({
    super.key,
    required this.memberId,
    this.companyId,
    this.initialDate,
    this.height,
    this.initiallyShowEvents = true,
    this.initiallyShowAvailability = true,
    this.initiallyShowPublicHolidays = true,
    this.collapseAvailabilityRules = true,
    this.skipRulesOnPublicHolidays = true,
    this.publicHolidayCountry = 'PL',
  });

  @override
  ConsumerState<EmployeeHrCalendarPreview> createState() =>
      _EmployeeHrCalendarPreviewState();
}

class _EmployeeHrCalendarPreviewState
    extends ConsumerState<EmployeeHrCalendarPreview> {
  late DateTime _anchorDate;
  late bool _showEvents;
  late bool _showAvailability;
  late bool _showPublicHolidays;
  late CalendarDefaultView _lastSettingsDefaultView;
  bool _viewChangedInThisWidget = false;
  sf_cal.CalendarView _view = sf_cal.CalendarView.week;

  DateTime get _rangeStart {
    switch (_view) {
      case sf_cal.CalendarView.day:
      case sf_cal.CalendarView.timelineDay:
        return DateTime(_anchorDate.year, _anchorDate.month, _anchorDate.day);
      case sf_cal.CalendarView.month:
      case sf_cal.CalendarView.timelineMonth:
      case sf_cal.CalendarView.schedule:
        return DateTime(_anchorDate.year, _anchorDate.month, 1);
      case sf_cal.CalendarView.workWeek:
        final start = _anchorDate.subtract(Duration(days: _anchorDate.weekday - 1));
        return DateTime(start.year, start.month, start.day);
      case sf_cal.CalendarView.week:
      case sf_cal.CalendarView.timelineWeek:
      default:
        final start = _anchorDate.subtract(Duration(days: _anchorDate.weekday - 1));
        return DateTime(start.year, start.month, start.day);
    }
  }

  DateTime get _rangeEnd {
    switch (_view) {
      case sf_cal.CalendarView.day:
      case sf_cal.CalendarView.timelineDay:
        return _rangeStart.add(const Duration(days: 1));
      case sf_cal.CalendarView.month:
      case sf_cal.CalendarView.timelineMonth:
      case sf_cal.CalendarView.schedule:
        return DateTime(_rangeStart.year, _rangeStart.month + 1, 1);
      case sf_cal.CalendarView.workWeek:
        return _rangeStart.add(const Duration(days: 5));
      case sf_cal.CalendarView.week:
      case sf_cal.CalendarView.timelineWeek:
      default:
        return _rangeStart.add(const Duration(days: 7));
    }
  }

  @override
  void initState() {
    super.initState();
    final initial = widget.initialDate ?? DateTime.now();
    _anchorDate = DateTime(initial.year, initial.month, initial.day);
    _showEvents = widget.initiallyShowEvents;
    _showAvailability = widget.initiallyShowAvailability;
    _showPublicHolidays = widget.initiallyShowPublicHolidays;

    final calendarSettings = ref.read(calendarSettingsProvider);
    _lastSettingsDefaultView = calendarSettings.defaultView;
    _view = _calendarViewFromDefault(calendarSettings.defaultView);
  }

  void _applySavedCalendarViewIfNeeded(CalendarDefaultView savedView) {
    if (_viewChangedInThisWidget || _lastSettingsDefaultView == savedView) {
      return;
    }

    _lastSettingsDefaultView = savedView;
    final nextView = _calendarViewFromDefault(savedView);
    if (_view == nextView) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _viewChangedInThisWidget) return;
      setState(() => _view = nextView);
    });
  }

  void _changeView(sf_cal.CalendarView value) {
    final settingsView = _defaultViewFromCalendarView(value);

    setState(() {
      _view = value;
      _viewChangedInThisWidget = true;
      _lastSettingsDefaultView = settingsView;
    });

    ref.read(calendarSettingsProvider.notifier).setDefaultView(settingsView);
  }

  void _openCalendarSettingsSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.35,
          maxChildSize: 0.9,
          expand: false,
          builder: (ctx, scrollController) => _EmployeeCalendarSettingsSheet(
            scrollController: scrollController,
            showEvents: _showEvents,
            showAvailability: _showAvailability,
            showPublicHolidays: _showPublicHolidays,
            onEventsChanged: (value) => setState(() => _showEvents = value),
            onAvailabilityChanged: (value) =>
                setState(() => _showAvailability = value),
            onPublicHolidaysChanged: (value) =>
                setState(() => _showPublicHolidays = value),
            view: _view,
            onViewChanged: _changeView,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final calendarSettings = ref.watch(calendarSettingsProvider);

    _applySavedCalendarViewIfNeeded(calendarSettings.defaultView);

    final decoration = BoxDecoration(
      color: theme.dashboardContainer,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: theme.dashboardBoarder),
    );

    final inner = Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final header = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_month_outlined, color: theme.textColor),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'employee_calendar'.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                );

                final actions = Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _LayerToggleChip(
                      label: 'events'.tr,
                      value: _showEvents,
                      icon: Icons.event_note_outlined,
                      onChanged: (value) => setState(() => _showEvents = value),
                    ),
                    _LayerToggleChip(
                      label: 'availability'.tr,
                      value: _showAvailability,
                      icon: Icons.access_time_outlined,
                      onChanged: (value) => setState(() => _showAvailability = value),
                    ),
                    _LayerToggleChip(
                      label: _ui('public_holidays', 'Święta'),
                      value: _showPublicHolidays,
                      icon: Icons.beach_access_outlined,
                      onChanged: (value) => setState(() => _showPublicHolidays = value),
                    ),
                    _LayerToggleChip(
                      label: _ui(
                        'calendar_work_hours_short',
                        'Od ${_formatHourOnly(calendarSettings.workdayStartHour, calendarSettings.timeFormat)}',
                      ),
                      value: calendarSettings.compactWorkHoursEnabled,
                      icon: Icons.vertical_align_top_outlined,
                      onChanged: (value) => ref
                          .read(calendarSettingsProvider.notifier)
                          .setCompactWorkHoursEnabled(value),
                    ),
                    PopupMenuButton<sf_cal.CalendarView>(
                      color: theme.dashboardContainer,
                      tooltip: 'calendar_view'.tr,
                      onSelected: _changeView,
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: sf_cal.CalendarView.day,
                          child: Text('day'.tr, style: TextStyle(color: theme.textColor)),
                        ),
                        PopupMenuItem(
                          value: sf_cal.CalendarView.week,
                          child: Text('week'.tr, style: TextStyle(color: theme.textColor)),
                        ),
                        PopupMenuItem(
                          value: sf_cal.CalendarView.workWeek,
                          child: Text('work_week'.tr, style: TextStyle(color: theme.textColor)),
                        ),
                        PopupMenuItem(
                          value: sf_cal.CalendarView.month,
                          child: Text('month'.tr, style: TextStyle(color: theme.textColor)),
                        ),
                      ],
                      child: Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: theme.dashboardBoarder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.view_week_outlined, size: 16, color: theme.textColor),
                            const SizedBox(width: 6),
                            Text(
                              _viewLabel(_view),
                              style: TextStyle(
                                color: theme.textColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );

                if (constraints.maxWidth < 720) {
                  return Row(
                    children: [
                      Expanded(child: header),
                      _EmployeeCalendarVerticalBar(
                        onOpenSettings: () => _openCalendarSettingsSheet(context),
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: header),
                    actions,
                  ],
                );
              },
            ),
          ),
          Divider(height: 1, color: theme.dashboardBoarder),
          Expanded(
            child: MemberCalendarHrLayer(
              memberId: widget.memberId,
              companyId: widget.companyId,
              rangeStart: _rangeStart,
              rangeEnd: _rangeEnd,
              includeEvents: _showEvents,
              includeAvailability: _showAvailability,
              includePublicHolidays: _showPublicHolidays,
              skipRulesOnPublicHolidays: widget.skipRulesOnPublicHolidays,
              publicHolidayCountry: widget.publicHolidayCountry,
              collapseAvailabilityRules: widget.collapseAvailabilityRules,
              builder: (context, state) {
                return state.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        error.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: theme.textColor.withAlpha(170)),
                      ),
                    ),
                  ),
                  data: (items) {
                    final absenceDays = <DateTime>{};
                    for (final item in items) {
                      if (!item.isAbsence) continue;
                      final startDay = DateTime(item.startAt.toLocal().year, item.startAt.toLocal().month, item.startAt.toLocal().day);
                      final endDt = item.endAt.toLocal().subtract(const Duration(microseconds: 1));
                      final endDay = DateTime(endDt.year, endDt.month, endDt.day);
                      var day = startDay;
                      while (!day.isAfter(endDay)) {
                        absenceDays.add(day);
                        day = day.add(const Duration(days: 1));
                      }
                    }

                    final filtered = items.where((item) {
                      if (item.isEvent && !_showEvents) return false;
                      if (item.isAvailability && !_showAvailability) return false;
                      if (item.isRule || item.isAvailability) {
                        final itemDay = DateTime(item.startAt.toLocal().year, item.startAt.toLocal().month, item.startAt.toLocal().day);
                        if (absenceDays.contains(itemDay)) return false;
                      }
                      return true;
                    }).toList(growable: false);

                    return _LayerCalendar(
                      items: filtered,
                      absenceDays: absenceDays,
                      view: _view,
                      initialDate: _anchorDate,
                      compactWorkHoursEnabled: calendarSettings.compactWorkHoursEnabled,
                      workdayStartHour: calendarSettings.workdayStartHour,
                      workdayEndHour: calendarSettings.workdayEndHour,
                      timeFormat: calendarSettings.timeFormat,
                      weekStart: calendarSettings.weekStart,
                      onDateChanged: (date) {
                        if (!mounted) return;
                        setState(() {
                          _anchorDate = DateTime(date.year, date.month, date.day);
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),
          SizedBox(height: BottomBarSize.resolve(context))
        ],
      );

    if (widget.height != null) {
      return Container(height: widget.height!, decoration: decoration, child: inner);
    }
    return SizedBox.expand(
      child: DecoratedBox(decoration: decoration, child: inner),
    );
  }
}

class _LayerCalendar extends ConsumerStatefulWidget {
  final List<CalendarLayerItemModel> items;
  final sf_cal.CalendarView view;
  final DateTime initialDate;
  final bool compactWorkHoursEnabled;
  final int workdayStartHour;
  final int workdayEndHour;
  final TimeFormat timeFormat;
  final WeekStartDay weekStart;
  final ValueChanged<DateTime> onDateChanged;
  final Set<DateTime> absenceDays;

  const _LayerCalendar({
    required this.items,
    required this.view,
    required this.initialDate,
    required this.compactWorkHoursEnabled,
    required this.workdayStartHour,
    required this.workdayEndHour,
    required this.timeFormat,
    required this.weekStart,
    required this.onDateChanged,
    this.absenceDays = const {},
  });

  @override
  ConsumerState<_LayerCalendar> createState() => _LayerCalendarState();
}

class _LayerCalendarState extends ConsumerState<_LayerCalendar> {
  late final sf_cal.CalendarController _controller;
  DateTime? _lastNotifiedAnchorDate;
  bool _isNotifyingViewChange = false;

  @override
  void initState() {
    super.initState();
    _controller = sf_cal.CalendarController();
    _syncControllerWithWidget(forceDate: true);
  }

  @override
  void didUpdateWidget(covariant _LayerCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);

    final viewChanged = oldWidget.view != widget.view;
    final dateChanged = !_sameDay(oldWidget.initialDate, widget.initialDate);

    if (viewChanged || dateChanged) {
      _syncControllerWithWidget(forceDate: dateChanged || viewChanged);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _syncControllerWithWidget({required bool forceDate}) {
    _controller.view = widget.view;

    if (!forceDate) return;

    final normalized = _normalizeDay(widget.initialDate);
    _controller.displayDate = normalized;
    _controller.selectedDate = normalized;
    _lastNotifiedAnchorDate = normalized;
  }

  void _handleViewChanged(sf_cal.ViewChangedDetails details) {
    if (details.visibleDates.isEmpty || _isNotifyingViewChange) return;

    final center = details.visibleDates[details.visibleDates.length ~/ 2];
    final normalized = _normalizeDay(center);

    if (_lastNotifiedAnchorDate != null &&
        _sameDay(_lastNotifiedAnchorDate!, normalized)) {
      return;
    }

    _lastNotifiedAnchorDate = normalized;
    _isNotifyingViewChange = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isNotifyingViewChange = false;
      if (!mounted) return;
      widget.onDateChanged(normalized);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final appointments = mapCalendarLayerItemsToAppointments(widget.items);
    final isTimeGridView = _isTimeGridView(widget.view);
    final hasEarlyTimedItems = _hasTimedItemBefore(
      widget.items,
      widget.workdayStartHour,
    );
    final useCompactHours =
        isTimeGridView && widget.compactWorkHoursEnabled && !hasEarlyTimedItems;
    final startHour = useCompactHours ? widget.workdayStartHour.toDouble() : 0.0;
    final endHour = useCompactHours
        ? _safeCalendarEndHour(widget.workdayStartHour, widget.workdayEndHour)
        : 24.0;
    final slotTimeFormat = _calendarTimeSlotFormat(widget.timeFormat);

    final absenceRegions = <sf_cal.TimeRegion>[
      for (final day in widget.absenceDays)
        sf_cal.TimeRegion(
          startTime: day,
          endTime: day.add(const Duration(days: 1)),
          color: Colors.black.withOpacity(0.28),
          enablePointerInteraction: false,
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        double? timeIntervalHeight;
        if (isTimeGridView && useCompactHours && constraints.hasBoundedHeight && constraints.maxHeight > 0) {
          final numHours = endHour - startHour;
          if (numHours > 0) timeIntervalHeight = constraints.maxHeight / numHours;
        }

        return sf_cal.SfCalendar(
          key: ValueKey<String>(
            'employee-hr-calendar-${widget.view.name}-$startHour-$endHour-$slotTimeFormat-${widget.weekStart.name}',
          ),
          controller: _controller,
          view: widget.view,
          firstDayOfWeek: _calendarFirstDayOfWeek(widget.weekStart),
          dataSource: _CalendarLayerAppointmentSource(appointments),
          specialRegions: absenceRegions,
          todayHighlightColor: theme.themeColor,
          todayTextStyle: TextStyle(color: theme.themeTextColor),
          backgroundColor: theme.dashboardContainer,
          cellBorderColor: theme.dashboardBoarder,
          showDatePickerButton: true,
          showNavigationArrow: true,
          allowAppointmentResize: false,
          allowDragAndDrop: false,
          headerStyle: sf_cal.CalendarHeaderStyle(
            backgroundColor: theme.dashboardContainer,
            textStyle: TextStyle(color: theme.textColor, fontSize: 15),
          ),
          viewHeaderStyle: sf_cal.ViewHeaderStyle(
            dayTextStyle: TextStyle(
              color: theme.textColor.withAlpha(180),
              fontWeight: FontWeight.bold,
            ),
            dateTextStyle: TextStyle(
              color: theme.textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          timeSlotViewSettings: sf_cal.TimeSlotViewSettings(
            startHour: startHour,
            endHour: endHour,
            timeIntervalHeight: timeIntervalHeight ?? -1,
            timeFormat: slotTimeFormat,
            timeTextStyle: TextStyle(
              color: theme.textColor.withAlpha(180),
              fontSize: 12,
            ),
          ),
          monthViewSettings: const sf_cal.MonthViewSettings(
            appointmentDisplayMode: sf_cal.MonthAppointmentDisplayMode.appointment,
            showAgenda: true,
          ),
          onViewChanged: _handleViewChanged,
          onTap: (details) async {
            final rawAppointments = details.appointments;
            if (rawAppointments == null || rawAppointments.isEmpty) return;

            final appointment = rawAppointments.whereType<sf_cal.Appointment>().isEmpty
                ? null
                : rawAppointments.whereType<sf_cal.Appointment>().first;
            if (appointment == null) return;

            await _showLayerAppointmentPreview(context, ref, appointment);
          },
        );
      },
    );
  }
}

class _LayerToggleChip extends ConsumerWidget {
  final String label;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _LayerToggleChip({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => onChanged(!value),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: value ? theme.themeColor.withAlpha(28) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: value ? theme.themeColor : theme.dashboardBoarder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: theme.textColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 6),
            Switch.adaptive(
              value: value,
              onChanged: onChanged,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmployeeCalendarVerticalBar extends ConsumerWidget {
  final VoidCallback onOpenSettings;

  const _EmployeeCalendarVerticalBar({required this.onOpenSettings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Tooltip(
      message: _ui('calendar_settings', 'Ustawienia kalendarza'),
      waitDuration: const Duration(milliseconds: 450),
      child: Container(
        height: 36,
        width: 36,
        decoration: BoxDecoration(
          color: theme.adPopBackground,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: theme.dashboardBoarder),
        ),
        child: IconButton(
          padding: EdgeInsets.zero,
          onPressed: onOpenSettings,
          icon: Icon(Icons.tune, size: 18, color: theme.textColor),
        ),
      ),
    );
  }
}

class _EmployeeCalendarSettingsSheet extends ConsumerWidget {
  final ScrollController scrollController;
  final bool showEvents;
  final bool showAvailability;
  final bool showPublicHolidays;
  final ValueChanged<bool> onEventsChanged;
  final ValueChanged<bool> onAvailabilityChanged;
  final ValueChanged<bool> onPublicHolidaysChanged;
  final sf_cal.CalendarView view;
  final ValueChanged<sf_cal.CalendarView> onViewChanged;

  const _EmployeeCalendarSettingsSheet({
    required this.scrollController,
    required this.showEvents,
    required this.showAvailability,
    required this.showPublicHolidays,
    required this.onEventsChanged,
    required this.onAvailabilityChanged,
    required this.onPublicHolidaysChanged,
    required this.view,
    required this.onViewChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final calendarSettings = ref.watch(calendarSettingsProvider);

    return Container(
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: theme.textColor.withValues(alpha: .25),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'employee_calendar'.tr,
                style: TextStyle(
                  color: theme.textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              InkWell(
                onTap: () => Navigator.of(context).maybePop(),
                child: Icon(Icons.close, color: theme.textColor),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _LayerToggleChip(
                label: 'events'.tr,
                value: showEvents,
                icon: Icons.event_note_outlined,
                onChanged: onEventsChanged,
              ),
              _LayerToggleChip(
                label: 'availability'.tr,
                value: showAvailability,
                icon: Icons.access_time_outlined,
                onChanged: onAvailabilityChanged,
              ),
              _LayerToggleChip(
                label: _ui('public_holidays', 'Święta'),
                value: showPublicHolidays,
                icon: Icons.beach_access_outlined,
                onChanged: onPublicHolidaysChanged,
              ),
              _LayerToggleChip(
                label: _ui(
                  'calendar_work_hours_short',
                  'Od ${_formatHourOnly(calendarSettings.workdayStartHour, calendarSettings.timeFormat)}',
                ),
                value: calendarSettings.compactWorkHoursEnabled,
                icon: Icons.vertical_align_top_outlined,
                onChanged: (value) => ref
                    .read(calendarSettingsProvider.notifier)
                    .setCompactWorkHoursEnabled(value),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'calendar_view'.tr,
            style: TextStyle(
              color: theme.textColor,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              sf_cal.CalendarView.day,
              sf_cal.CalendarView.week,
              sf_cal.CalendarView.workWeek,
              sf_cal.CalendarView.month,
            ].map((option) {
              final isSelected = option == view;

              return ChoiceChip(
                label: Text(_viewLabel(option)),
                selected: isSelected,
                onSelected: (_) => onViewChanged(option),
                selectedColor: theme.themeColor.withValues(alpha: .25),
                labelStyle: TextStyle(
                  color: isSelected ? theme.themeColor : theme.textColor,
                  fontWeight: FontWeight.w600,
                ),
                side: BorderSide(
                  color: isSelected
                      ? theme.themeColor
                      : theme.textColor.withValues(alpha: .3),
                ),
                backgroundColor: theme.textFieldColor,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class CalendarHrLayerLegend extends StatelessWidget {
  const CalendarHrLayerLegend({super.key});

  @override
  Widget build(BuildContext context) {
    const items = [
      _LegendItem('Event / busy', Color(0xFFA855F7)),
      _LegendItem('Dostępny', Color(0xFF22C55E)),
      _LegendItem('Prezentacje', Color(0xFF0EA5E9)),
      _LegendItem('Zajęty', Color(0xFFF59E0B)),
      _LegendItem('L4', Color(0xFFEF4444)),
      _LegendItem('Święto', Color(0xFF94A3B8)),
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
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _CalendarLayerAppointmentSource extends sf_cal.CalendarDataSource {
  _CalendarLayerAppointmentSource(List<sf_cal.Appointment> source) {
    appointments = source;
  }
}

List<sf_cal.Appointment> mapCalendarLayerItemsToAppointments(
  List<CalendarLayerItemModel> items, {
  bool includeEmployeeName = true,
}) {
  return items.map((item) {
    final employeePrefix = includeEmployeeName && item.employeeName.trim().isNotEmpty
        ? '${item.employeeName.trim()} · '
        : '';
    final title = '$employeePrefix${item.title}'.trim();
    final localStart = item.startAt.toLocal();
    final rawLocalEnd = item.endAt.toLocal();
    final localEnd = rawLocalEnd.isAfter(localStart)
        ? rawLocalEnd
        : localStart.add(const Duration(hours: 1));

    return sf_cal.Appointment(
      id: item.id,
      subject: title.isEmpty ? 'Zajęty' : title,
      startTime: localStart,
      endTime: localEnd,
      color: item.displayColor.withOpacity(item.isRule ? .30 : .88),
      notes: item.tooltip.isNotEmpty
          ? item.tooltip
          : '${item.source} · ${item.status}',
      location: item.source,
      isAllDay: _looksLikeAllDay(localStart, localEnd),
    );
  }).toList(growable: false);
}

Future<void> _showLayerAppointmentPreview(
  BuildContext context,
  WidgetRef ref,
  sf_cal.Appointment appointment,
) async {
  final theme = ref.read(themeColorsProvider);
  final notes = (appointment.notes ?? '').trim();

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: theme.dashboardContainer,
        title: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: appointment.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                appointment.subject,
                style: TextStyle(color: theme.textColor),
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PreviewRow(
                icon: Icons.schedule_outlined,
                text: '${_formatDateTime(appointment.startTime)} – ${_formatDateTime(appointment.endTime)}',
              ),
              if (notes.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  notes,
                  style: TextStyle(
                    color: theme.textColor.withAlpha(190),
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('close'.tr),
          ),
        ],
      );
    },
  );
}

class _PreviewRow extends ConsumerWidget {
  final IconData icon;
  final String text;

  const _PreviewRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: theme.textColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: theme.textColor.withAlpha(190)),
          ),
        ),
      ],
    );
  }
}

DateTime _normalizeDay(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

bool _sameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}


bool _isTimeGridView(sf_cal.CalendarView view) {
  switch (view) {
    case sf_cal.CalendarView.day:
    case sf_cal.CalendarView.week:
    case sf_cal.CalendarView.workWeek:
    case sf_cal.CalendarView.timelineDay:
    case sf_cal.CalendarView.timelineWeek:
      return true;
    case sf_cal.CalendarView.month:
    case sf_cal.CalendarView.timelineMonth:
    case sf_cal.CalendarView.schedule:
    default:
      return false;
  }
}

bool _hasTimedItemBefore(
  List<CalendarLayerItemModel> items,
  int startHour,
) {
  final safeStartHour = startHour.clamp(0, 23).toInt();
  return items.any((item) {
    final localStart = item.startAt.toLocal();
    final localEnd = item.endAt.toLocal();

    if (_looksLikeAllDay(localStart, localEnd)) {
      return false;
    }

    final itemHourValue = localStart.hour + (localStart.minute / 60.0);
    return itemHourValue < safeStartHour;
  });
}

double _safeCalendarEndHour(int startHour, int endHour) {
  final safeStart = startHour.clamp(0, 23).toInt();
  final safeEnd = endHour.clamp(1, 24).toInt();
  if (safeEnd <= safeStart) return 24.0;
  return safeEnd.toDouble();
}

String _calendarTimeSlotFormat(TimeFormat format) {
  return format == TimeFormat.twentyFourHour ? 'HH:mm' : 'h a';
}

String _formatHourOnly(int hour, TimeFormat format) {
  final safeHour = hour.clamp(0, 23).toInt();
  if (format == TimeFormat.twentyFourHour) {
    return '${_two(safeHour)}:00';
  }

  if (safeHour == 0) return '12 AM';
  if (safeHour == 12) return '12 PM';
  if (safeHour > 12) return '${safeHour - 12} PM';
  return '$safeHour AM';
}

int _calendarFirstDayOfWeek(WeekStartDay value) {
  switch (value.name) {
    case 'monday':
      return 1;
    case 'tuesday':
      return 2;
    case 'wednesday':
      return 3;
    case 'thursday':
      return 4;
    case 'friday':
      return 5;
    case 'saturday':
      return 6;
    case 'sunday':
    default:
      return 7;
  }
}

String _ui(String key, String fallback) {
  final translated = key.tr;
  return translated == key ? fallback : translated;
}


sf_cal.CalendarView _calendarViewFromDefault(CalendarDefaultView view) {
  switch (view) {
    case CalendarDefaultView.day:
      return sf_cal.CalendarView.day;
    case CalendarDefaultView.week:
      return sf_cal.CalendarView.week;
    case CalendarDefaultView.workWeek:
      return sf_cal.CalendarView.workWeek;
    case CalendarDefaultView.month:
      return sf_cal.CalendarView.month;
  }
}

CalendarDefaultView _defaultViewFromCalendarView(sf_cal.CalendarView view) {
  switch (view) {
    case sf_cal.CalendarView.day:
    case sf_cal.CalendarView.timelineDay:
      return CalendarDefaultView.day;
    case sf_cal.CalendarView.workWeek:
      return CalendarDefaultView.workWeek;
    case sf_cal.CalendarView.month:
    case sf_cal.CalendarView.timelineMonth:
    case sf_cal.CalendarView.schedule:
      return CalendarDefaultView.month;
    case sf_cal.CalendarView.week:
    case sf_cal.CalendarView.timelineWeek:
    default:
      return CalendarDefaultView.week;
  }
}

String _viewLabel(sf_cal.CalendarView view) {
  switch (view) {
    case sf_cal.CalendarView.day:
    case sf_cal.CalendarView.timelineDay:
      return 'day'.tr;
    case sf_cal.CalendarView.workWeek:
      return 'work_week'.tr;
    case sf_cal.CalendarView.month:
    case sf_cal.CalendarView.timelineMonth:
      return 'month'.tr;
    case sf_cal.CalendarView.week:
    case sf_cal.CalendarView.timelineWeek:
    default:
      return 'week'.tr;
  }
}

String _two(int value) => value.toString().padLeft(2, '0');

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  return '${_two(local.day)}.${_two(local.month)}.${local.year} ${_two(local.hour)}:${_two(local.minute)}';
}

bool _looksLikeAllDay(DateTime start, DateTime end) {
  return start.hour == 0 &&
      start.minute == 0 &&
      start.second == 0 &&
      end.hour == 0 &&
      end.minute == 0 &&
      end.second == 0 &&
      end.difference(start).inHours >= 23;
}
