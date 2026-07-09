
/// ---- Config: adjust endpoints to your backend paths ----
class ApiPaths {
  static const String createEvent = "/calendar/event/"; // POST -> create base event
  static String publishSocial(int eventId) => "/calendar/event/$eventId/publish/"; // POST/PATCH
  static const String listCategories = "/calendar/discover/"; // GET (optional)
}

/// ---- Models ----
class EventCategoryDto {
  final int id;
  final String name;
  final String? icon;
  EventCategoryDto({required this.id, required this.name, this.icon});
  factory EventCategoryDto.fromJson(Map<String, dynamic> j) =>
      EventCategoryDto(
        id: (j['id'] as num?)?.toInt() ?? 0,
        name: j['name'] ?? '',
        icon: j['icon'],
      );
}

enum EventVisibility { public, private, unlisted }
