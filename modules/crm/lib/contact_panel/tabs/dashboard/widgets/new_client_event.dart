import 'package:calendar/models/calendar_model.dart';
import 'package:calendar/models/event_model.dart';
import 'package:calendar/state_managers/appointments_provider.dart';
import 'package:calendar/state_managers/calendar_provider.dart';
import 'package:calendar/state_managers/calendar_ui_controller.dart';
import 'package:calendar/state_managers/popup_calendar_provider.dart';
import 'package:calendar/widgets/save_event_widget.dart';
import 'package:crm/contact_panel/components/client_calendar.dart';
import 'package:crm/contact_panel/components/no_event_widget.dart';
import 'package:crm/provider/events_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart' as sf_cal;
import 'package:core/theme/apptheme.dart';

final allEventsListProvider = Provider.family<List<EventModel>, String>((
  ref,
  clientId,
) {
  return ref.watch(clientEventsProvider(clientId));
});

class NewClientEvent extends ConsumerStatefulWidget {
  final String clientId;

  const NewClientEvent({
    super.key,
    required this.clientId,
  });

  @override
  ConsumerState<NewClientEvent> createState() => _NewClientEventState();
}

class _NewClientEventState extends ConsumerState<NewClientEvent> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      await ref
          .read(calendarNotifierProvider.notifier)
          .fetchCalendars(context: context);

      await ref.read(appointmentsProvider).warmUp(
            focusDate: DateTime.now(),
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);

    return Container(
      height: 348,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: theme.dashboardBoarder),
        color: theme.dashboardContainer,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 7,
            child: CustomTableCalendarPc(
              clientId: widget.clientId,
              primaryColor: Theme.of(context).primaryColor,
              fillColor: Colors.white,
              firstDay: DateTime.utc(2010, 10, 16),
              lastDay: DateTime.utc(2030, 3, 14),
            ),
          ),
          Expanded(
            flex: 10,
            child: ClientEvettile(clientId: widget.clientId),
          ),
        ],
      ),
    );
  }
}

class ClientEvettile extends ConsumerWidget {
  final String clientId;
  final bool isMobile;

  const ClientEvettile({
    super.key,
    required this.clientId,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    final todayEvents = ref.watch(eventsForSelectedDateProvider(clientId));
    final allEvents = ref.watch(allEventsListProvider(clientId));
    final nextDayEvents = ref.watch(nextEventsAfterSelectedDateProvider(clientId));
    final nextDateWithEvents = ref.watch(nextEventDateProvider(clientId));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (!isMobile)
            Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    'planned_events_label'.tr,
                    style: TextStyle(
                      color: theme.mobileTextcolor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    style: ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(
                        theme.clientbuttoncolor,
                      ),
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      minimumSize: WidgetStateProperty.all(
                        const Size(double.infinity, 40),
                      ),
                    ),
                    icon: Icon(Icons.add, color: theme.textColor, size: 14),
                    label: Text(
                      'Add Event'.tr,
                      style: TextStyle(fontSize: 10, color: theme.textColor),
                    ),
                    onPressed: () {
                      ref.read(appointmentsProvider).isEdit = false;
                      ref.read(popupCalendarProvider.notifier).clearAllFields();

                      final cid = int.tryParse(clientId);
                      if (cid != null) {
                        final ev = ref.read(popupCalendarProvider).event;
                        ref.read(popupCalendarProvider).event = ev.copyWith(
                          client: cid,
                        );
                      }

                      showSaveEvent(
                        context,
                        index: 0,
                        clientId: clientId,
                        isClientDashboard: true,
                      );
                    },
                  ),
                ),
              ],
            ),
          Expanded(
            child: todayEvents.isNotEmpty
                ? ListView.builder(
                    addAutomaticKeepAlives: false,
                    cacheExtent: 300,
                    itemCount: todayEvents.length,
                    itemBuilder: (context, index) => EventCard(
                      event: todayEvents[index],
                      clientId: clientId,
                      isMobile: isMobile,
                    ),
                  )
                : nextDayEvents.isNotEmpty
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.only(bottom: 8, top: 4),
                            child: Text(
                              '${'no_events_on_selected_day'.tr} ${DateFormat('EEE, d MMM').format(nextDateWithEvents!)}',
                              style: TextStyle(
                                color: theme.textColor.withAlpha(204),
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              addAutomaticKeepAlives: false,
                              cacheExtent: 300,
                              itemCount: nextDayEvents.length,
                              itemBuilder: (context, index) => EventCard(
                                event: nextDayEvents[index],
                                clientId: clientId,
                                isMobile: isMobile,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Center(
                        child: NoEventWidget(
                          isPc: !isMobile,
                          clientId: clientId,
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  void showSaveEvent(
    BuildContext context, {
    required int index,
    required String clientId,
    required bool isClientDashboard,
  }) {
    if (_useBottomSheet()) {
      _showSaveEventSheet(
        context,
        index: index,
        clientId: clientId,
        isClientDashboard: isClientDashboard,
      );
    } else {
      _showSaveEventDialog(
        context,
        index: index,
        clientId: clientId,
        isClientDashboard: isClientDashboard,
      );
    }
  }

  void _showSaveEventDialog(
    BuildContext context, {
    required int index,
    required String clientId,
    required bool isClientDashboard,
  }) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SaveEventWidget(
          index: index,
          clientId: clientId,
          isClientDashboard: isClientDashboard,
        ),
      ),
    );
  }

  void _showSaveEventSheet(
    BuildContext context, {
    required int index,
    required String clientId,
    required bool isClientDashboard,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.55,
          maxChildSize: 0.95,
          expand: false,
          shouldCloseOnMinExtent: true,
          builder: (context, scrollController) {
            return SaveEventWidget(
              index: index,
              clientId: clientId,
              isClientDashboard: isClientDashboard,
              isMobile: true,
              scrollController: scrollController,
            );
          },
        );
      },
    );
  }
}

class EventCard extends ConsumerWidget {
  final EventModel event;
  final String clientId;
  final bool isMobile;

  const EventCard({
    super.key,
    required this.event,
    required this.clientId,
    this.isMobile = false,
  });

  Color? _parseHexColor(String? hex) {
    if (hex == null) return null;

    var value = hex.trim();
    if (value.isEmpty) return null;

    if (value.startsWith('#')) {
      value = value.substring(1);
    }

    if (value.length == 6) {
      value = 'FF$value';
    }

    if (value.length != 8) return null;

    final parsed = int.tryParse(value, radix: 16);
    return parsed == null ? null : Color(parsed);
  }

  Color _calendarDisplayColor(WidgetRef ref, ThemeColors theme) {
    final fromEvent = _parseHexColor(event.color);
    if (fromEvent != null) return fromEvent;

    final List<Calendar> calendars =
        ref.read(calendarNotifierProvider).valueOrNull ?? const <Calendar>[];

    final idStr = event.calendar?.toString();

    Calendar? matched;
    for (final calendar in calendars) {
      if (calendar.id.toString() == idStr) {
        matched = calendar;
        break;
      }
    }

    final fromCalendar = _parseHexColor(matched?.color);
    return fromCalendar ?? theme.themeColor;
  }

  sf_cal.Appointment _toAppt(EventModel e, Color fallbackColor) {
    return sf_cal.Appointment(
      id: e.id,
      startTime: e.from,
      endTime: e.to,
      subject: e.title,
      notes: e.description,
      location: e.location,
      color: fallbackColor,
      resourceIds: [int.tryParse(e.calendar ?? '') ?? 0],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final ui = ref.read(calendarUiControllerProvider.notifier);

    final formattedDate = DateFormat('MMMM dd, HH:mm').format(event.from);
    final displayColor = _calendarDisplayColor(ref, theme);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) {
        ui.setPointer(details.globalPosition);

        final appt = _toAppt(event, displayColor);
        ui.openPreviewForAppointment(
          context,
          appt,
          isMobile: isMobile,
          ref: ref,
        );
      },
      child: Card(
        color: theme.popupcontainercolor,
        margin: const EdgeInsets.symmetric(vertical: 3),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 15),
          child: IntrinsicHeight(
            child: Row(
              children: [
                VerticalDivider(
                  thickness: 2,
                  color: displayColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Location: ${event.location}'.tr,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    IconButton(
                      highlightColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      padding: EdgeInsets.zero,
                      onPressed: () {},
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: theme.textColor,
                        size: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

bool _useBottomSheet() {
  if (kIsWeb) return false;

  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}