import 'package:crm/provider/events_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/colors.dart';
import 'package:core/theme/icons.dart';

class CustomTableCalendarPc extends ConsumerWidget {
  final String? clientId;
  final Color primaryColor;
  final Color fillColor;
  final DateTime firstDay;
  final DateTime lastDay;

  const CustomTableCalendarPc({
    super.key,
    this.clientId,
    required this.primaryColor,
    required this.fillColor,
    required this.firstDay,
    required this.lastDay,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final isDark = ref.watch(isDefaultDarkSystemProvider);
    final allEvents =
        clientId == null
            ? ref.watch(allCalendarEventsProvider)
            : ref.watch(clientEventsProvider(clientId!));
    final focusedDay = ref.watch(focusedDayProvider);

    return TableCalendar(
      selectedDayPredicate:
          (day) => isSameDay(day, ref.watch(selectedDateProvider)),
      onDaySelected: (selectedDay, _) {
        ref.read(selectedDateProvider.notifier).state = selectedDay;
        ref.read(focusedDayProvider.notifier).state = selectedDay;
      },
      onPageChanged: (focusedDay) {
        ref.read(focusedDayProvider.notifier).state = focusedDay;
      },
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: TextStyle(fontSize: 12, color: theme.mobileTextcolor),
        weekendStyle: TextStyle(fontSize: 12, color: theme.mobileTextcolor),
      ),
      calendarStyle: CalendarStyle(
        selectedDecoration: BoxDecoration(
          color: theme.themeColor,
          shape: BoxShape.circle,
        ),
        selectedTextStyle: TextStyle(
          fontSize: 12,
          color: theme.themeTextColor,
        ),
        todayDecoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(width: 3, color: theme.themeColor),
        ),
        todayTextStyle: TextStyle(fontSize: 12, color: theme.textColor),
        weekendTextStyle: TextStyle(
          color: theme.mobileTextcolor,
          fontSize: 12,
        ),
        outsideTextStyle: TextStyle(
          color: theme.mobileTextcolor,
          fontSize: 12,
        ),
        defaultTextStyle: TextStyle(
          color: theme.mobileTextcolor,
          fontSize: 12,
        ),
      ),
      headerStyle: HeaderStyle(
        leftChevronIcon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: theme.mobileTextcolor,
        ),
        rightChevronIcon: Icon(
          Icons.arrow_forward_ios_rounded,
          color: theme.mobileTextcolor,
        ),
        titleCentered: true,
        formatButtonVisible: false,
        titleTextStyle: TextStyle(color: theme.mobileTextcolor, fontSize: 12),
      ),
      shouldFillViewport: true,
      rowHeight: 12,
      firstDay: firstDay,
      lastDay: lastDay,
      focusedDay: focusedDay,
      availableGestures: AvailableGestures.none,
      daysOfWeekHeight: 20,
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, day, focusedDay) {
          final hasEvent = allEvents.any((event) {
            final eventDate = event.from.toLocal();
            return eventDate.year == day.year &&
                eventDate.month == day.month &&
                eventDate.day == day.day;
          });

          if (hasEvent) {
            return Center(
              child: Container(
                width: 25,
                height: 25,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? clienttileTextcolor
                          : Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  day.day.toString(),
                  style: TextStyle(color: theme.textColor, fontSize: 12),
                ),
              ),
            );
          }
          return null;
        },
      ),
    );
  }
}

class CustomTableCalendarMobile extends ConsumerWidget {
  final String? clientId;
  final Color primaryColor;
  final Color fillColor;
  final DateTime firstDay;
  final DateTime lastDay;
  final DateTime focusedDay;
  final List<Map<String, dynamic>> events;

  const CustomTableCalendarMobile({
    super.key,
    this.clientId,
    required this.primaryColor,
    required this.fillColor,
    required this.firstDay,
    required this.lastDay,
    required this.focusedDay,
    required this.events,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final isDark = ref.watch(isDefaultDarkSystemProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final fontsizemobile = screenWidth * 0.035;
    final fontsizetab = screenWidth * 0.02;
    final allEvents =
        clientId == null
            ? ref.watch(allCalendarEventsProvider)
            : ref.watch(clientEventsProvider(clientId!));

    return TableCalendar(
      selectedDayPredicate:
          (day) => isSameDay(day, ref.watch(selectedDateProvider)),
      onDaySelected: (selectedDay, _) {
        ref.read(selectedDateProvider.notifier).state = selectedDay;
      },
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: TextStyle(
          fontSize: screenWidth > 600 ? fontsizetab : fontsizemobile,
          color: theme.mobileTextcolor,
        ),
        weekendStyle: TextStyle(
          fontSize: screenWidth > 600 ? fontsizetab : fontsizemobile,
          color: theme.mobileTextcolor,
        ),
      ),
      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            width: 3,
            color: isDark ? clienttileTextcolor : primaryColor,
          ),
        ),
        todayTextStyle: TextStyle(
          fontSize: screenWidth > 600 ? fontsizetab : fontsizemobile,
          color: isDark ? clienttileTextcolor : primaryColor,
        ),
        weekendTextStyle: TextStyle(
          color: theme.mobileTextcolor,
          fontSize: screenWidth > 600 ? fontsizetab : fontsizemobile,
        ),
        outsideTextStyle: TextStyle(
          color: theme.mobileTextcolor,
          fontSize: screenWidth > 600 ? fontsizetab : fontsizemobile,
        ),
        defaultTextStyle: TextStyle(
          color: theme.mobileTextcolor,
          fontSize: screenWidth > 600 ? fontsizetab : fontsizemobile,
        ),
      ),
      headerStyle: HeaderStyle(
        leftChevronIcon: AppIcons.iosArrowLeft(color: theme.mobileTextcolor),
        rightChevronIcon: AppIcons.iosArrowRight(color: theme.mobileTextcolor),
        titleCentered: true,
        formatButtonVisible: false,
        titleTextStyle: TextStyle(
          color: theme.mobileTextcolor,
          fontSize: screenWidth > 600 ? fontsizetab : fontsizemobile,
        ),
      ),
      shouldFillViewport: true,
      rowHeight: MediaQuery.of(context).size.height * 0.02,
      firstDay: firstDay,
      lastDay: lastDay,
      focusedDay: focusedDay,
      availableGestures: AvailableGestures.none,
      daysOfWeekHeight: 35,
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, day, focusedDay) {
          final hasEvent = allEvents.any((event) {
            final eventDate = event.from.toLocal();
            return eventDate.year == day.year &&
                eventDate.month == day.month &&
                eventDate.day == day.day;
          });

          if (hasEvent) {
            return Center(
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark ? clienttileTextcolor : primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  day.day.toString(),
                  style: TextStyle(color: theme.textColor, fontSize: 18),
                ),
              ),
            );
          }
          return null;
        },
      ),
    );
  }
}