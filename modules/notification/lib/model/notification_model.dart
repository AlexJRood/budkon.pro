class NotificationModel {
  final int id;
  final String title;
  final String text;
  final String? image;
  final String objectId;
  final String createAt;
  final int user;
  final int? fcmDevice;
  final int contentType;
  final List<NotificationAction> actions;

  /// Raw original payload from backend / local notification payload.
  final Map<String, dynamic> raw;

  NotificationModel({
    required this.id,
    required this.title,
    required this.text,
    this.image,
    required this.objectId,
    required this.createAt,
    required this.user,
    required this.fcmDevice,
    required this.contentType,
    required this.actions,
    Map<String, dynamic>? raw,
  }) : raw = raw ?? const {};

  /// Stable, human-readable notification category coming from the backend
  /// (`email`, `message`, `saved_search`, `tms`, `calendar`, `cloud_storage`,
  /// `association`, `community`, `emma`, `crm`, `finance`, `payments`,
  /// `system`, `others`). Present in FCM data as `type` and in the list API as
  /// `notification_type`. Used as a routing fallback when neither the action
  /// type nor the numeric [contentType] matches a known destination.
  String get notificationType => (raw['type'] ??
          raw['notification_type'] ??
          '')
      .toString()
      .trim()
      .toLowerCase();

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final rawActions = json['actions'];
    final parsedActions = rawActions is List
        ? rawActions
            .whereType<Map>()
            .map((a) => NotificationAction.fromJson(
                  Map<String, dynamic>.from(a),
                ))
            .toList()
        : <NotificationAction>[];

    return NotificationModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      title: json['title']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      image: json['image']?.toString(),
      objectId: json['object_id']?.toString() ?? '',
      createAt: json['create_at']?.toString() ?? '',
      user: int.tryParse(json['user'].toString()) ?? 0,
      fcmDevice: json['fcm_device'] != null
          ? int.tryParse(json['fcm_device'].toString())
          : null,
      contentType: int.tryParse(json['content_type'].toString()) ?? 0,
      actions: parsedActions,
      raw: Map<String, dynamic>.from(json),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'text': text,
      'image': image,
      'object_id': objectId,
      'create_at': createAt,
      'user': user,
      'fcm_device': fcmDevice,
      'content_type': contentType,
      'actions': actions.map((e) => e.toJson()).toList(),
    };
  }
}

class UserNotificationResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<NotificationModel> results;

  UserNotificationResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory UserNotificationResponse.fromJson(Map<String, dynamic> json) {
    final rawResults = json['results'];
    final parsedResults = rawResults is List
        ? rawResults
            .whereType<Map>()
            .map(
              (e) => NotificationModel.fromJson(
                Map<String, dynamic>.from(e),
              ),
            )
            .toList()
        : <NotificationModel>[];

    return UserNotificationResponse(
      count: json['count'] ?? 0,
      next: json['next']?.toString(),
      previous: json['previous']?.toString(),
      results: parsedResults,
    );
  }
}

class NotificationAction {
  final String text;
  final String type;
  final String? chatRoomId;
  final String? roomId;

  /// Full raw action payload so we can extract saved_search_id, ad_id, etc.
  final Map<String, dynamic> raw;

  NotificationAction({
    required this.text,
    required this.type,
    this.chatRoomId,
    this.roomId,
    Map<String, dynamic>? raw,
  }) : raw = raw ?? const {};

  factory NotificationAction.fromJson(Map<String, dynamic> json) {
    return NotificationAction(
      text: json['text']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      chatRoomId: json['chat_room_id']?.toString(),
      roomId: json['room_id']?.toString(),
      raw: Map<String, dynamic>.from(json),
    );
  }

  String? get chatRoomUuid => chatRoomId ?? roomId;

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'type': type,
      'chat_room_id': chatRoomId,
      'room_id': roomId,
      ...raw,
    };
  }
}

class NotificationCategory {
  final String value;
  final String label;
  final int count;
  final int unreadCount;

  NotificationCategory({
    required this.value,
    required this.label,
    required this.count,
    required this.unreadCount,
  });

  factory NotificationCategory.fromJson(Map<String, dynamic> json) {
    return NotificationCategory(
      value: json['value']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      count: json['count'] ?? 0,
      unreadCount: json['unread_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'value': value,
    'label': label,
    'count': count,
    'unread_count': unreadCount,
  };
}

class UnreadCountResponse {
  final int unreadCount;

  UnreadCountResponse({required this.unreadCount});

  factory UnreadCountResponse.fromJson(Map<String, dynamic> json) {
    return UnreadCountResponse(
      unreadCount: json['unread_count'] ?? 0,
    );
  }
}

class NotificationFilters {
  final bool? seen;
  final String? notificationType;
  final List<String>? notificationTypes;
  final String? search;
  final String? groupKey;
  final String? senderId;
  final DateTime? createdFrom;
  final DateTime? createdTo;
  final String? ordering;
  final bool? includeDeleted;

  NotificationFilters({
    this.seen,
    this.notificationType,
    this.notificationTypes,
    this.search,
    this.groupKey,
    this.senderId,
    this.createdFrom,
    this.createdTo,
    this.ordering,
    this.includeDeleted,
  });

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};
    
    if (seen != null) params['seen'] = seen;
    if (notificationType != null) params['notification_type'] = notificationType;
    if (notificationTypes != null && notificationTypes!.isNotEmpty) {
      params['notification_types'] = notificationTypes!.join(',');
    }
    if (search != null && search!.isNotEmpty) params['search'] = search;
    if (groupKey != null) params['group_key'] = groupKey;
    if (senderId != null) params['sender_id'] = senderId;
    if (createdFrom != null) params['created_from'] = createdFrom!.toIso8601String();
    if (createdTo != null) params['created_to'] = createdTo!.toIso8601String();
    if (ordering != null) params['ordering'] = ordering;
    if (includeDeleted != null) params['include_deleted'] = includeDeleted;
    
    return params;
  }
}