
// --------------------
// Model: SavedSearchModel
// --------------------

bool _bool(dynamic v) {
  if (v == null) return false;
  if (v is bool) return v;
  final s = v.toString().trim().toLowerCase();
  return s == '1' || s == 'true' || s == 'yes' || s == 'y';
}

class SavedSearchModel {
  final int id;
  final String title;
  final String description;
  final String tags;
  final String searchQuery;
  final Map<String, dynamic> filters;
  final int lastCount;
  final String lastChecked;
  final String createdAt;
  final String updatedAt;
  final String avatar;

  // flags
  final bool enableNotifications;
  final bool enableEmailNotification;

  const SavedSearchModel({
    required this.id,
    required this.title,
    required this.description,
    required this.tags,
    required this.searchQuery,
    required this.filters,
    required this.lastCount,
    required this.lastChecked,
    required this.createdAt,
    required this.updatedAt,
    required this.avatar,
    required this.enableNotifications,
    required this.enableEmailNotification,
  });

  factory SavedSearchModel.fromJson(Map<String, dynamic> json) {
    return SavedSearchModel(
      id: json['id'] ?? 0,
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      tags: (json['tags'] ?? '').toString(),
      searchQuery: (json['search_query'] ?? '').toString(),
      filters: (json['filters'] as Map?)?.cast<String, dynamic>() ?? {},
      lastCount: json['last_count'] ?? 0,
      lastChecked: (json['last_checked'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
      updatedAt: (json['updated_at'] ?? '').toString(),
      avatar: (json['avatar'] ?? 'assets/images/landingpage.webp').toString(),
      enableNotifications: _bool(json['enable_notifications']),
      enableEmailNotification: _bool(json['enable_email_notification']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'tags': tags,
      'search_query': searchQuery,
      'filters': filters,
      'last_count': lastCount,
      'last_checked': lastChecked,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'avatar': avatar,
      'enable_notifications': enableNotifications,
      'enable_email_notification': enableEmailNotification,
    };
  }

  SavedSearchModel copyWith({
    String? title,
    String? description,
    String? tags,
    String? searchQuery,
    Map<String, dynamic>? filters,
    int? lastCount,
    String? lastChecked,
    String? updatedAt,
    String? avatar,
    bool? enableNotifications,
    bool? enableEmailNotification,
  }) {
    return SavedSearchModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      searchQuery: searchQuery ?? this.searchQuery,
      filters: filters ?? this.filters,
      lastCount: lastCount ?? this.lastCount,
      lastChecked: lastChecked ?? this.lastChecked,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      avatar: avatar ?? this.avatar,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      enableEmailNotification: enableEmailNotification ?? this.enableEmailNotification,
    );
  }
}