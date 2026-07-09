import 'package:calendar/models/event_model.dart';
import 'package:calendar/state_managers/appointments_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());
final focusedDayProvider = StateProvider<DateTime>((ref) => DateTime.now());

DateTime _dayKey(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

final allCalendarEventsProvider = Provider<List<EventModel>>((ref) {
  final appointmentsState = ref.watch(appointmentsProvider);
  final list = [...appointmentsState.events]..sort((a, b) => a.from.compareTo(b.from));
  return list;
});

final clientEventsProvider = Provider.family<List<EventModel>, String>((
  ref,
  clientId,
) {
  final allEvents = ref.watch(allCalendarEventsProvider);
  final parsedClientId = int.tryParse(clientId);

  if (parsedClientId == null) return const <EventModel>[];

  final list =
      allEvents.where((event) {
        return event.client == parsedClientId;
      }).toList();

  list.sort((a, b) => a.from.compareTo(b.from));
  return list;
});

final eventsForSelectedDateProvider = Provider.family<List<EventModel>, String?>((
  ref,
  clientId,
) {
  final events =
      clientId == null
          ? ref.watch(allCalendarEventsProvider)
          : ref.watch(clientEventsProvider(clientId));

  final selectedDate = ref.watch(selectedDateProvider);
  final selectedDay = _dayKey(selectedDate);

  return events.where((event) {
    final eventDay = _dayKey(event.from);
    return eventDay == selectedDay;
  }).toList();
});

final nextEventsAfterSelectedDateProvider =
    Provider.family<List<EventModel>, String?>((ref, clientId) {
      final events =
          clientId == null
              ? ref.watch(allCalendarEventsProvider)
              : ref.watch(clientEventsProvider(clientId));

      final selectedDate = ref.watch(selectedDateProvider);
      final selectedDay = _dayKey(selectedDate);

      final futureEvents =
          events.where((event) {
            final eventDay = _dayKey(event.from);
            return eventDay.isAfter(selectedDay);
          }).toList();

      if (futureEvents.isEmpty) return const <EventModel>[];

      futureEvents.sort((a, b) => a.from.compareTo(b.from));
      final nextDay = _dayKey(futureEvents.first.from);

      return futureEvents.where((event) {
        final eventDay = _dayKey(event.from);
        return eventDay == nextDay;
      }).toList();
    });

final nextEventDateProvider = Provider.family<DateTime?, String?>((ref, clientId) {
  final nextEvents = ref.watch(nextEventsAfterSelectedDateProvider(clientId));
  if (nextEvents.isEmpty) return null;
  final first = nextEvents.first;
  return DateTime(first.from.year, first.from.month, first.from.day);
});