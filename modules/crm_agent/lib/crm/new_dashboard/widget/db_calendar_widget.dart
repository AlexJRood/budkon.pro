import 'package:calendar/models/event_model.dart';
import 'package:calendar/state_managers/add_event_provider.dart';
import 'package:calendar/state_managers/appointments_provider.dart';
import 'package:calendar/state_managers/calendar_provider.dart';
import 'package:calendar/state_managers/popup_calendar_provider.dart';
import 'package:calendar/widgets/event_preview_card_widget.dart';
import 'package:calendar/widgets/save_event_widget.dart' hide ClientListAddFormCrm, selectedDateProvider;
import 'package:crm/contact_panel/components/client_calendar.dart';
import 'package:crm/contact_panel/components/no_event_widget.dart';
import 'package:crm/provider/events_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:intl/intl.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/user/user/user_provider.dart';

class DbCalendarWidget extends ConsumerStatefulWidget {
  final String? clientId;
  final bool isMobile;

  const DbCalendarWidget({
    super.key,
    this.clientId,
    this.isMobile = false,
  });

  @override
  ConsumerState<DbCalendarWidget> createState() => _DbCalendarWidgetState();
}

class _DbCalendarWidgetState extends ConsumerState<DbCalendarWidget> {
  static const double _miniCalendarHeight = 400;
  static const double _listOnlyHeightThreshold = 560;
  static const double _compactHeaderHeight = 40;

  Offset? _tapPosition;
  ProviderSubscription<AsyncValue<dynamic>>? _userSub;
  final ScrollController _eventsScrollController = ScrollController();

  // Raw px dragged past the edge since we last saw the list not pinned there.
  // A small threshold before we start forwarding lets the platform's own
  // edge feedback (e.g. iOS bounce) settle instead of fighting the page scroll.
  double _edgeDragSlack = 0;
  static const double _edgeDragSlackThreshold = 6.0;

  @override
  void initState() {
    super.initState();

    final currentUser = ref.read(userProvider).valueOrNull;

    if (currentUser?.userId != null) {
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

    _userSub = ref.listenManual(userProvider, (prev, next) {
      next.whenData((user) async {
        if (user?.userId == null) return;

        await ref
            .read(calendarNotifierProvider.notifier)
            .fetchCalendars(context: context);

        await ref.read(appointmentsProvider).warmUp(
              focusDate: DateTime.now(),
            );
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      await ref
          .read(calendarNotifierProvider.notifier)
          .fetchCalendars(context: context);
    });
  }

  @override
  void dispose() {
    _userSub?.close();
    _userSub = null;
    _eventsScrollController.dispose();
    super.dispose();
  }

  String _formatDateRange(DateTime start, DateTime end) {
    String two(int n) => n.toString().padLeft(2, '0');
    String ampm(int h) => h >= 12 ? 'PM' : 'AM';
    int h12(int h) => h == 0 ? 12 : (h > 12 ? h - 12 : h);

    final dayNames = [
      'Mon'.tr,
      'Tue'.tr,
      'Wed'.tr,
      'Thu'.tr,
      'Fri'.tr,
      'Sat'.tr,
      'Sun'.tr,
    ];

    final monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final dayLine =
        '${dayNames[(start.weekday - 1) % 7]}, ${start.day} ${monthNames[start.month - 1]}';

    final timeLine =
        '${h12(start.hour)}:${two(start.minute)} – ${h12(end.hour)}:${two(end.minute)} ${ampm(end.hour)}';

    return '$dayLine  •  $timeLine';
  }

  Color? _parseHexColor(String? hex) {
    if (hex == null) return null;

    var v = hex.trim();

    if (v.isEmpty) return null;
    if (v.startsWith('#')) v = v.substring(1);
    if (v.length == 6) v = 'FF$v';
    if (v.length != 8) return null;

    final n = int.tryParse(v, radix: 16);

    return n == null ? null : Color(n);
  }

  dynamic _findCalendarById({
    required WidgetRef ref,
    required String? calendarId,
  }) {
    final calendars = ref.read(calendarNotifierProvider).valueOrNull;
    final idStr = calendarId?.toString();

    if (calendars == null || idStr == null) return null;

    for (final calendar in calendars) {
      if (calendar.id.toString() == idStr) {
        return calendar;
      }
    }

    return null;
  }

  String _calendarDisplayName({
    required WidgetRef ref,
    required String? calendarId,
  }) {
    final idStr = calendarId?.toString();

    final matched = _findCalendarById(
      ref: ref,
      calendarId: calendarId,
    );

    if (matched == null) return 'Calendar #${idStr ?? "-"}';

    final name = matched.name?.toString().trim() ?? '';
    if (name.isNotEmpty) return name;

    final owner = matched.owner;

    if (owner?.username?.toString().isNotEmpty == true) {
      return owner.username.toString();
    }

    if (owner?.email?.toString().isNotEmpty == true) {
      return owner.email.toString();
    }

    return 'Calendar #${idStr ?? "-"}';
  }

  Color _calendarDisplayColor({
    required WidgetRef ref,
    required EventModel event,
    required ThemeColors theme,
  }) {
    final fromEvent = _parseHexColor(event.color);
    if (fromEvent != null) return fromEvent;

    final matched = _findCalendarById(
      ref: ref,
      calendarId: event.calendar?.toString(),
    );

    final fromCalendar = _parseHexColor(matched?.color?.toString());
    if (fromCalendar != null) return fromCalendar;

    return theme.themeColor;
  }

  RelativeRect _anchorRectFromTap(BuildContext context, Offset anchor) {
    final overlay = Overlay.of(context, rootOverlay: true);
    final renderObject = overlay.context.findRenderObject();

    final size = renderObject is RenderBox
        ? renderObject.size
        : MediaQuery.of(context).size;

    return RelativeRect.fromLTRB(
      anchor.dx,
      anchor.dy,
      size.width - anchor.dx,
      size.height - anchor.dy,
    );
  }

  void _openEditForEvent({
    required BuildContext context,
    required WidgetRef ref,
    required EventModel event,
  }) {
    final apptState = ref.read(appointmentsProvider);
    apptState.isEdit = true;

    ref.read(popupCalendarProvider).event = event;

    final theme = ref.read(themeColorsProvider);

    if (widget.isMobile) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: theme.dashboardContainer,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(12),
          ),
        ),
        builder: (_) {
          return DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.40,
            maxChildSize: 0.95,
            expand: false,
            builder: (ctx, scrollController) {
              return SaveEventWidget(
                index: 0,
                isMobile: true,
                isClientDashboard: widget.clientId != null,
                clientId: widget.clientId ?? '0',
                scrollController: scrollController,
              );
            },
          );
        },
      );

      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        final screenSize = MediaQuery.sizeOf(dialogContext);

        return Dialog(
          insetPadding: const EdgeInsets.all(24),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 720,
              maxHeight: screenSize.height - 48,
            ),
            child: SaveEventWidget(
              index: 0,
              clientId: widget.clientId ?? '0',
              isClientDashboard: widget.clientId != null,
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteEvent({
    required BuildContext context,
    required WidgetRef ref,
    required EventModel event,
  }) async {
    await ref.read(addEventNotifierProvider.notifier).deleteEvent(
          event.id,
          ref: ref,
          refreshDate: event.from,
          context: context,
        );
  }

  Future<void> _openCalendarEventPreviewPopup({
    required BuildContext context,
    required WidgetRef ref,
    required EventModel event,
  }) async {
    final theme = ref.read(themeColorsProvider);

    final calName = _calendarDisplayName(
      ref: ref,
      calendarId: event.calendar,
    );

    final calColor = _calendarDisplayColor(
      ref: ref,
      event: event,
      theme: theme,
    );

    final anchor = _tapPosition ??
        Offset(
          MediaQuery.of(context).size.width / 2,
          MediaQuery.of(context).size.height / 2,
        );

    await showMenu<void>(
      context: context,
      color: theme.textFieldColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      position: _anchorRectFromTap(context, anchor),
      items: <PopupMenuEntry<void>>[
        PopupMenuItem<void>(
          enabled: false,
          padding: EdgeInsets.zero,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 360,
              maxWidth: 520,
            ),
            child: EventPreviewCard(
              color: calColor,
              title: event.title,
              dateLine: _formatDateRange(event.from, event.to),
              location: event.location,
              notes: event.description,
              calendarName: calName,
              createdBy: null,
              timeZone: event.timeZone,
              onlineCallLink: event.onlineCallLink,
              visibility: event.visibility.type,
              busy: event.busy,
              clientDisplay: event.client?.toString(),
              attendees: event.guests
                  .map((g) {
                    final name = (g.name ?? '').trim();
                    final email = g.email.trim();
                    return name.isNotEmpty ? name : email;
                  })
                  .where((s) => s.isNotEmpty)
                  .toList(),
              remindersSummary: event.reminders.isEmpty
                  ? null
                  : event.reminders
                      .map((r) => '${r.minutes} min ${r.method}')
                      .join(', '),
              onClose: () => Navigator.of(context).pop(),
              onEdit: () {
                Navigator.of(context).pop();

                _openEditForEvent(
                  context: context,
                  ref: ref,
                  event: event,
                );
              },
              onDelete: () async {
                Navigator.of(context).pop();

                await _deleteEvent(
                  context: context,
                  ref: ref,
                  event: event,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  DateTime _dayOnly(DateTime dt) {
    final local = dt.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  ({List<EventModel> events, DateTime? futureDay}) _pickEventsToShow({
    required List<EventModel> selectedDayEvents,
    required List<EventModel> allEvents,
  }) {
    if (selectedDayEvents.isNotEmpty) {
      return (events: selectedDayEvents, futureDay: null);
    }

    final selectedDate = ref.read(selectedDateProvider).toLocal();
    final startOfSelectedDay = _dayOnly(selectedDate);

    final byDay = <DateTime, List<EventModel>>{};

    for (final e in allEvents) {
      final day = _dayOnly(e.from);

      if (day.isAfter(startOfSelectedDay)) {
        byDay.putIfAbsent(day, () => []).add(e);
      }
    }

    if (byDay.isEmpty) {
      return (events: const <EventModel>[], futureDay: null);
    }

    final sortedDays = byDay.keys.toList()..sort();
    final nextDay = sortedDays.first;

    final list = byDay[nextDay]!
      ..sort((a, b) => a.from.compareTo(b.from));

    return (events: list, futureDay: nextDay);
  }

  void _openAddEventForm(BuildContext context) {
    final theme = ref.read(themeColorsProvider);

    ref.read(appointmentsProvider).isEdit = false;
    ref.read(popupCalendarProvider.notifier).clearAllFields();

    final selectedDate = ref.read(selectedDateProvider).toLocal();
    final currentEvent = ref.read(popupCalendarProvider).event;

    final start = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      currentEvent.from.hour,
      currentEvent.from.minute,
    );

    final clientIdAsInt =
        widget.clientId == null ? null : int.tryParse(widget.clientId!);

    ref.read(popupCalendarProvider).event = currentEvent.copyWith(
          from: start,
          to: start.add(const Duration(hours: 1)),
          client: clientIdAsInt ?? currentEvent.client,
        );

    if (widget.isMobile) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: theme.dashboardContainer,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(12),
          ),
        ),
        builder: (context) {
          return DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return SaveEventWidget(
                isMobile: true,
                scrollController: scrollController,
                index: 0,
                clientId: widget.clientId ?? '0',
                isClientDashboard: widget.clientId != null,
              );
            },
          );
        },
      );

      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        final screenSize = MediaQuery.sizeOf(dialogContext);

        return Dialog(
          insetPadding: const EdgeInsets.all(24),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 720,
              maxHeight: screenSize.height - 48,
            ),
            child: SaveEventWidget(
              isMobile: false,
              index: 0,
              clientId: widget.clientId ?? '0',
              isClientDashboard: widget.clientId != null,
            ),
          ),
        );
      },
    );
  }

  Widget _buildCalendarSection({
    required ThemeColors theme,
  }) {
    return SizedBox(
      height: _miniCalendarHeight,
      child: ClipRect(
        child: CustomTableCalendarPc(
          clientId: widget.clientId,
          primaryColor: theme.themeColor,
          fillColor: theme.textColor,
          firstDay: DateTime(2010, 10, 16),
          lastDay: DateTime(2030, 3, 14),
        ),
      ),
    );
  }

  Widget _buildHeaderRow({
    required BuildContext context,
    required ThemeColors theme,
    required bool listOnlyMode,
  }) {
    return SizedBox(
      height: _compactHeaderHeight,
      child: Row(
        children: [
          Expanded(
            child: Text(
              listOnlyMode ? "Planned Events".tr : "Planned Events".tr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: theme.textColor,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            style: elevatedButtonStyleRounded10,
            onPressed: () => _openAddEventForm(context),
            child: Text(
              "+Add event".tr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: theme.textColor,
                fontSize: 12.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFutureNotice({
    required ThemeColors theme,
    required DateTime selectedDate,
    required DateTime futureDay,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: theme.adPopBackground,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: theme.dashboardBoarder,
        ),
      ),
      child: Text(
        '${'no_events_on'.tr} ${DateFormat('EEE, d MMM').format(selectedDate)}. ${'showing_events_on'.tr} ${DateFormat('EEE, d MMM').format(futureDay.toLocal())}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: theme.textColor,
          fontSize: 12.sp,
        ),
      ),
    );
  }

  Widget _buildEventsArea({
    required BuildContext context,
    required ThemeColors theme,
    required DateTime selectedDate,
    required bool showingFuture,
    required DateTime? futureDay,
    required List<EventModel> displayEvents,
  }) {
    if (displayEvents.isEmpty) {
      return  Center(
        child: NoEventWidget(
          isPc: !widget.isMobile,
        ),
      );
    }

    final itemCount = displayEvents.length + (showingFuture ? 1 : 0);

    return Listener(
      onPointerMove: (event) => _forwardEdgeDragToAncestor(context, event),
      onPointerUp: (_) => _edgeDragSlack = 0,
      onPointerCancel: (_) => _edgeDragSlack = 0,
      child: ListView.builder(
        controller: _eventsScrollController,
        padding: EdgeInsets.zero,
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (showingFuture && index == 0) {
            return _buildFutureNotice(
              theme: theme,
              selectedDate: selectedDate,
              futureDay: futureDay!,
            );
          }

          final eventIndex = showingFuture ? index - 1 : index;
          final event = displayEvents[eventIndex];

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => _tapPosition = d.globalPosition,
            onTap: () => _openCalendarEventPreviewPopup(
              context: context,
              ref: ref,
              event: event,
            ),
            child: EventCard(
              title: event.title,
              date: DateFormat('yyyy-MM-dd HH:mm').format(event.from),
              location: event.location,
            ),
          );
        },
      ),
    );
  }

  // The events list is a nested vertical Scrollable inside the dashboard's
  // page-level scroll view. Flutter's gesture arena hands the whole drag to
  // whichever Scrollable is deepest, so once it wins there is no built-in way
  // for the ancestor page to take over even after the inner list is fully
  // scrolled to its edge -- OverscrollNotification alone is too damped/late
  // to feel usable (esp. with iOS's BouncingScrollPhysics). `onPointerMove`
  // bypasses the gesture arena entirely (it fires for every raw pointer move
  // regardless of which recognizer "wins"), so once the inner list is pinned
  // at an edge we can drive the ancestor Scrollable's position 1:1 with the
  // finger for the rest of the drag.
  void _forwardEdgeDragToAncestor(BuildContext context, PointerMoveEvent event) {
    if (!_eventsScrollController.hasClients) return;

    final dy = event.delta.dy;
    if (dy == 0) return;

    final inner = _eventsScrollController.position;
    final atTop = inner.pixels <= inner.minScrollExtent;
    final atBottom = inner.pixels >= inner.maxScrollExtent;

    final draggingTowardsStart = dy > 0;
    final pinnedAtRelevantEdge =
        draggingTowardsStart ? atTop : atBottom;

    if (!pinnedAtRelevantEdge) {
      _edgeDragSlack = 0;
      return;
    }

    // Let a bit of the platform's own edge feedback (e.g. iOS bounce) play
    // out before handing off, so it doesn't fight the page scroll visually.
    _edgeDragSlack += dy.abs();
    if (_edgeDragSlack < _edgeDragSlackThreshold) return;

    // Cancel whatever rubber-band this same move started locally so the
    // list doesn't bounce while the outer page is also scrolling.
    final edgeValue = atTop ? inner.minScrollExtent : inner.maxScrollExtent;
    if (inner.pixels != edgeValue) {
      inner.jumpTo(edgeValue);
    }

    final outer = Scrollable.maybeOf(context)?.position;
    if (outer == null) return;

    final target = (outer.pixels - dy).clamp(
      outer.minScrollExtent,
      outer.maxScrollExtent,
    );

    if (target != outer.pixels) {
      outer.jumpTo(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);

    final selectedDayEvents = ref.watch(
      eventsForSelectedDateProvider(widget.clientId),
    );

    final selectedDate = ref.watch(selectedDateProvider).toLocal();

    final allEvents = widget.clientId == null
        ? ref.watch(allCalendarEventsProvider)
        : ref.watch(clientEventsProvider(widget.clientId!));

    final pick = _pickEventsToShow(
      selectedDayEvents: selectedDayEvents,
      allEvents: allEvents,
    );

    final showingFuture = pick.futureDay != null;
    final displayEvents = pick.events;

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasBoundedHeight = constraints.maxHeight.isFinite;
        final availableHeight =
            hasBoundedHeight ? constraints.maxHeight : (widget.isMobile ? 620.0 : 640.0);

        final listOnlyMode = availableHeight < _listOnlyHeightThreshold;

        final content = ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: theme.dashboardContainer,
              border: Border.all(
                color: theme.dashboardBoarder,
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!listOnlyMode) ...[
                  _buildCalendarSection(
                    theme: theme,
                  ),
                  const SizedBox(height: 10),
                ],
                _buildHeaderRow(
                  context: context,
                  theme: theme,
                  listOnlyMode: listOnlyMode,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _buildEventsArea(
                    context: context,
                    theme: theme,
                    selectedDate: selectedDate,
                    showingFuture: showingFuture,
                    futureDay: pick.futureDay,
                    displayEvents: displayEvents,
                  ),
                ),
              ],
            ),
          ),
        );

        if (hasBoundedHeight) {
          return SizedBox.expand(
            child: content,
          );
        }

        return SizedBox(
          height: availableHeight,
          child: content,
        );
      },
    );
  }
}

class EventCard extends ConsumerWidget {
  final String title;
  final String date;
  final String location;

  const EventCard({
    super.key,
    required this.title,
    required this.date,
    required this.location,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final hasLocation = location.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        constraints: const BoxConstraints(
          minHeight: 68,
          maxHeight: 92,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: theme.adPopBackground,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            SizedBox(
              height: hasLocation ? 58 : 46,
              child: VerticalDivider(
                color: theme.textColor,
                thickness: 2,
                width: 10.w,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title.trim().isEmpty ? 'untitled_event'.tr : title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color.fromRGBO(87, 148, 221, 1),
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.more_vert,
                        color: theme.textColor,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 12.sp,
                    ),
                  ),
                  if (hasLocation) ...[
                    const SizedBox(height: 2),
                    Text(
                      location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.textColor.withOpacity(0.78),
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}