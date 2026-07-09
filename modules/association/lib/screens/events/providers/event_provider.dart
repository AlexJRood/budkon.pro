
// ==============================
// API PATHS — adjust if needed
// ==============================

// _ApiPaths – podmień
import 'package:association/screens/events/models/event_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:core/platform/api_services.dart';

class _ApiPaths {
  static const _base = 'https://www.superbee.cloud'; // backend (Django)
  static const listPublic = '$_base/calendar/discover/'; // GET
  static String bySlug(String slug) => '$_base/calendar/e/$slug/'; // GET
  static String rsvp(int eventId) =>
      '$_base/calendar/event/$eventId/rsvp/'; // POST
  static String invite(int eventId) =>
      '$_base/calendar/event/$eventId/invite/'; // POST
  static const categories =
      '$_base/event/social/categories/'; // GET (opcjonalnie)
}


// ==============================
// API LAYER (uses ApiServices)
// ==============================
class PublicEventsApi {
  const PublicEventsApi(this.ref);
  final Ref ref;

  // RSVP: going/maybe/decline
  Future<void> rsvp({required int eventId, required String status}) async {
    final res = await ApiServices.post(
      _ApiPaths.rsvp(eventId),
      data: {"status": status}, // "going" | "maybe" | "decline"
      hasToken: true, // needs auth
      ref: ref,
    );
    if (res == null || res.statusCode != 200) {
      throw Exception('RSVP failed (${res?.statusCode})');
    }
  }

  // Invite guests
  Future<int> invite(int eventId, Map<String, dynamic> guests) async {
    final res = await ApiServices.post(
      _ApiPaths.invite(eventId),
      data: guests, // lista leci jako JSON array
      hasToken: true,
      ref: ref,
    );
    if (res == null || (res.statusCode != 202 && res.statusCode != 200)) {
      throw Exception('Invite failed (${res?.statusCode})');
    }
    final d = Map<String, dynamic>.from(res.data as Map);
    return (d['invited_count'] as num?)?.toInt() ?? 0;
  }

  Future<List<EventPublicCardModel>> list({
    String? q,
    String? city,
    String? category,
    DateTime? start,
    DateTime? end,
  }) async {
    final qp = <String, dynamic>{};
    if (q != null && q.isNotEmpty) qp['q'] = q;
    if (city != null && city.isNotEmpty) qp['city'] = city;
    if (category != null && category.isNotEmpty) qp['category'] = category;
    if (start != null) qp['start'] = DateFormat('yyyy-MM-dd').format(start);
    if (end != null) qp['end'] = DateFormat('yyyy-MM-dd').format(end);

    final res = await ApiServices.get(
      _ApiPaths.listPublic,
      hasToken: false,
      queryParameters: qp,
      responseType: ResponseType.json,
      ref: ref,
    );
    if (res == null || res.statusCode != 200) {
      throw Exception('Failed to fetch public events: ${res?.statusCode}');
    }
    final data = (res.data as List)
        .map((e) => EventPublicCardModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return data;
  }

  Future<List<EventCategoryModel>> fetchCategories() async {
    final res = await ApiServices.get(
      _ApiPaths.categories,
      hasToken: false,
      responseType: ResponseType.json,
      ref: ref,
    );
    if (res == null || res.statusCode != 200) return [];
    final list = (res.data as List)
        .map((e) => EventCategoryModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return list;
  }

  Future<EventSocialDetailModel> bySlug(String slug) async {
    final res = await ApiServices.get(
      _ApiPaths.bySlug(slug),
      hasToken: false,
      responseType: ResponseType.json,
      ref: ref,
    );
    if (res == null) throw Exception('No response');
    if (res.statusCode == 404) throw Exception('not-found');
    if (res.statusCode != 200) throw Exception('Error ${res.statusCode}');
    final j = Map<String, dynamic>.from(res.data as Map);
    return EventSocialDetailModel.fromJson(j);
  }
}

final publicEventsApiProvider = Provider<PublicEventsApi>(
  (ref) => PublicEventsApi(ref),
);

// ==============================
// FILTER STATE
// ==============================
class EventsFilter {
  final String q;
  final String city;
  final String category;
  final DateTime? start;
  final DateTime? end;
  const EventsFilter({
    this.q = '',
    this.city = '',
    this.category = '',
    this.start,
    this.end,
  });
  EventsFilter copyWith({
    String? q,
    String? city,
    String? category,
    DateTime? start,
    DateTime? end,
  }) => EventsFilter(
    q: q ?? this.q,
    city: city ?? this.city,
    category: category ?? this.category,
    start: start ?? this.start,
    end: end ?? this.end,
  );
}

final eventsFilterProvider = StateProvider<EventsFilter>(
  (_) => const EventsFilter(),
);

final categoriesProvider = FutureProvider<List<EventCategoryModel>>((
  ref,
) async {
  return ref.read(publicEventsApiProvider).fetchCategories();
});

final publicEventsProvider = FutureProvider<List<EventPublicCardModel>>((
  ref,
) async {
  final api = ref.read(publicEventsApiProvider);
  final f = ref.watch(eventsFilterProvider);
  return api.list(
    q: f.q,
    city: f.city,
    category: f.category,
    start: f.start,
    end: f.end,
  );
});