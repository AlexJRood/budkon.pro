// ==============================
// MODELS
// ==============================
class EventPublicCardModel {
  final String slug;
  final String title;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? location;
  final String? city;
  final String? coverImageUrl;
  final int goingCount;
  final bool isFree;

  EventPublicCardModel({
    required this.slug,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.city,
    required this.coverImageUrl,
    required this.goingCount,
    required this.isFree,
  });

  factory EventPublicCardModel.fromJson(Map<String, dynamic> j) {
    DateTime? _dt(String? s) => s == null ? null : DateTime.tryParse(s);
    return EventPublicCardModel(
      slug: j['slug'] as String,
      title: j['title'] as String,
      startTime: _dt(j['start_time'] as String?),
      endTime: _dt(j['end_time'] as String?),
      location: j['location'] as String?,
      city: j['city'] as String?,
      coverImageUrl: j['cover_image_url'] as String?,
      goingCount: (j['going_count'] as num?)?.toInt() ?? 0,
      isFree: (j['is_free'] as bool?) ?? false,
    );
  }
}

class EventCoreModel {
  final String title;
  final String? description;
  final String? location;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? timeZone;

  EventCoreModel({
    required this.title,
    this.description,
    this.location,
    this.startTime,
    this.endTime,
    this.timeZone,
  });

  factory EventCoreModel.fromJson(Map<String, dynamic> j) {
    DateTime? _dt(String? s) => s == null ? null : DateTime.tryParse(s);
    return EventCoreModel(
      title: j['title'] ?? '',
      description: j['description'] as String?,
      location: j['location'] as String?,
      startTime: _dt(j['start_time'] as String?),
      endTime: _dt(j['end_time'] as String?),
      timeZone: j['time_zone'] as String?,
    );
  }
}

// --- model rozszerzamy o eventId ---
class EventSocialDetailModel {
  final EventCoreModel event;
  final int eventId; // <-- NEW
  final String slug;
  final String? coverImageUrl;
  final String visibility;
  final bool isPublished;
  final String? city;
  final int goingCount;
  final int interestedCount;
  final String? externalTicketUrl;
  final bool isFree;
  final String? myStatus; // <-- NEW: "going" | "maybe" | "decline" | null

  EventSocialDetailModel({
    required this.event,
    required this.eventId,
    required this.slug,
    required this.coverImageUrl,
    required this.visibility,
    required this.isPublished,
    required this.city,
    required this.goingCount,
    required this.interestedCount,
    required this.externalTicketUrl,
    required this.isFree,
    required this.myStatus,
  });

  factory EventSocialDetailModel.fromJson(Map<String, dynamic> j) {
    return EventSocialDetailModel(
      event: EventCoreModel.fromJson(j['event'] as Map<String, dynamic>),
      eventId: (j['event_id'] as num).toInt(), // <-- NEW
      slug: j['slug'],
      coverImageUrl: j['cover_image_url'] as String?,
      visibility: j['visibility'] as String? ?? 'public',
      isPublished: j['is_published'] as bool? ?? false,
      city: j['city'] as String?,
      goingCount: (j['going_count'] as num?)?.toInt() ?? 0,
      interestedCount: (j['interested_count'] as num?)?.toInt() ?? 0,
      externalTicketUrl: j['external_ticket_url'] as String?,
      isFree: j['is_free'] as bool? ?? true,
      myStatus: j['my_rsvp'] as String?, // <-- NEW
    );
  }
}

// --- API c
class EventCategoryModel {
  final int id;
  final String name;
  final String? icon;
  EventCategoryModel({required this.id, required this.name, this.icon});
  factory EventCategoryModel.fromJson(Map<String, dynamic> j) =>
      EventCategoryModel(id: j['id'], name: j['name'], icon: j['icon']);
}
