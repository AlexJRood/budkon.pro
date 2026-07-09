// Public Event Create Page (Flutter Web/Desktop)
// Uses Riverpod + your ApiServices. Plug into routing as a standalone page.
// Comments are in English as requested.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:core/platform/api_services.dart';
import 'package:association/models/events_model.dart';



extension on EventVisibility {
  String get api => switch (this) {
        EventVisibility.public => 'public',
        EventVisibility.private => 'private',
        EventVisibility.unlisted => 'unlisted',
      };
}

/// ---- API wrapper using your ApiServices ----
class PublicEventsApi {
  const PublicEventsApi(this.baseUrl, this.ref);
  final String baseUrl;
  final Ref ref;

  Future<List<EventCategoryDto>> fetchCategories() async {
    final res = await ApiServices.get(
      baseUrl + ApiPaths.listCategories,
      hasToken: true,
      responseType: ResponseType.json,
      ref: ref,
    );
    if (res == null || res.statusCode != 200) return [];
    final data = res.data as List;
    return data.map((e) => EventCategoryDto.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<int> createEvent({
    required String title,
    String? description,
    String? location,
    required DateTime start,
    DateTime? end,
    String? timeZone,
    int? calendarId,
    List<Map<String, dynamic>>? guests, // optional (emails/contacts)
  }) async {
    final payload = {
      'title': title,
      if (description != null && description.isNotEmpty) 'description': description,
      if (location != null && location.isNotEmpty) 'location': location,
      'start_time': start.toIso8601String(),
      if (end != null) 'end_time': end.toIso8601String(),
      if (timeZone != null && timeZone.isNotEmpty) 'time_zone': timeZone,
      if (calendarId != null) 'calendar': calendarId,
      if (guests != null && guests.isNotEmpty) 'guests': guests,
    };

    final res = await ApiServices.post(
      baseUrl + ApiPaths.createEvent,
      data: payload,
      hasToken: true,
      ref: ref,
    );
    if (res == null) throw Exception('No response');
    if (res.statusCode != 201) {
      throw Exception('Create Event failed: ${res.statusCode} ${res.data}');
    }
    final body = res.data as Map<String, dynamic>;
    // assume backend returns {"id": <int>, ...}
    return (body['id'] as num).toInt();
  }

  Future<Map<String, dynamic>?> publishSocial({
  required int eventId,
  required EventVisibility visibility,
  required bool isPublished,
  String? coverImageUrl,
  bool? isFree,
  String? externalTicketUrl,
  List<int>? categoryIds,
  String? city,
}) async {
  final payload = {
    'is_published': isPublished,
    'visibility': visibility.api,
    if (coverImageUrl != null && coverImageUrl.isNotEmpty) 'cover_image_url': coverImageUrl,
    if (isFree != null) 'is_free': isFree,
    if (externalTicketUrl != null && externalTicketUrl.isNotEmpty) 'external_ticket_url': externalTicketUrl,
    if (categoryIds != null) 'category_ids': categoryIds,
    if (city != null && city.isNotEmpty) 'city': city,
  };

  final res = await ApiServices.post(
    baseUrl + ApiPaths.publishSocial(eventId),
    data: payload,
    hasToken: true,
    ref: ref,
  );
  
  if (res == null) {
    throw Exception('Publish failed: No response from server');
  }

  if (res.data is Map && (res.data['error'] != null || res.data['success'] == false)) {
    throw Exception('Publish failed: ${res.data['error'] ?? 'Unknown API error'}');
  }
  
  if (res.statusCode != 200 && res.statusCode != 201) {
    throw Exception('Publish failed: ${res.statusCode} ${res.data}');
  }
  
  return res.data;
}
}

final publicEventsApiProvider = Provider.family<PublicEventsApi, String>((ref, baseUrl) {
  return PublicEventsApi(baseUrl, ref);
});

/// ---- Form State ----
class _EventFormState {
  final String title;
  final String description;
  final String location;
  final DateTime? start;
  final DateTime? end;
  final String timeZone;
  final String coverImageUrl;
  final EventVisibility visibility;
  final bool isPublished;
  final bool isFree;
  final String externalTicketUrl;
  final String city;
  final Set<int> selectedCategories;
  final bool loading;
  final String? error;

  _EventFormState({
    this.title = '',
    this.description = '',
    this.location = '',
    this.start,
    this.end,
    this.timeZone = 'Europe/Warsaw',
    this.coverImageUrl = '',
    this.visibility = EventVisibility.public,
    this.isPublished = true,
    this.isFree = true,
    this.externalTicketUrl = '',
    this.city = '',
    this.selectedCategories = const {},
    this.loading = false,
    this.error,
  });

  _EventFormState copyWith({
    String? title,
    String? description,
    String? location,
    DateTime? start,
    DateTime? end,
    String? timeZone,
    String? coverImageUrl,
    EventVisibility? visibility,
    bool? isPublished,
    bool? isFree,
    String? externalTicketUrl,
    String? city,
    Set<int>? selectedCategories,
    bool? loading,
    String? error,
  }) => _EventFormState(
        title: title ?? this.title,
        description: description ?? this.description,
        location: location ?? this.location,
        start: start ?? this.start,
        end: end ?? this.end,
        timeZone: timeZone ?? this.timeZone,
        coverImageUrl: coverImageUrl ?? this.coverImageUrl,
        visibility: visibility ?? this.visibility,
        isPublished: isPublished ?? this.isPublished,
        isFree: isFree ?? this.isFree,
        externalTicketUrl: externalTicketUrl ?? this.externalTicketUrl,
        city: city ?? this.city,
        selectedCategories: selectedCategories ?? this.selectedCategories,
        loading: loading ?? this.loading,
        error: error,
      );
}

class _EventFormNotifier extends StateNotifier<_EventFormState> {
  _EventFormNotifier() : super(_EventFormState());
  void setTitle(String v) => state = state.copyWith(title: v);
  void setDesc(String v) => state = state.copyWith(description: v);
  void setLocation(String v) => state = state.copyWith(location: v);
  void setStart(DateTime v) => state = state.copyWith(start: v);
  void setEnd(DateTime? v) => state = state.copyWith(end: v);
  void setTz(String v) => state = state.copyWith(timeZone: v);
  void setCover(String v) => state = state.copyWith(coverImageUrl: v);
  void setVisibility(EventVisibility v) => state = state.copyWith(visibility: v);
  void setPublished(bool v) => state = state.copyWith(isPublished: v);
  void setFree(bool v) => state = state.copyWith(isFree: v);
  void setTicketUrl(String v) => state = state.copyWith(externalTicketUrl: v);
  void setCity(String v) => state = state.copyWith(city: v);
  void toggleCategory(int id) {
    final s = Set<int>.from(state.selectedCategories);
    if (s.contains(id)) s.remove(id); else s.add(id);
    state = state.copyWith(selectedCategories: s);
  }
  void setLoading(bool v) => state = state.copyWith(loading: v, error: null);
  void setError(String? e) => state = state.copyWith(error: e);
}

final eventFormProvider = StateNotifierProvider<_EventFormNotifier, _EventFormState>((ref) => _EventFormNotifier());

final categoriesProvider = FutureProvider.family<List<EventCategoryDto>, String>((ref, baseUrl) async {
  final api = ref.read(publicEventsApiProvider(baseUrl));
  return api.fetchCategories();
});



