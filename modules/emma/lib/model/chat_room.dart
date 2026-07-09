// emma/model/chat_room.dart

class ChatRoom {
  final int id;
  final String? title;
  final String? createdAt;
  final String? lastActivityAt;
  final bool isArchived;
  final String? source;
  final Map<String, dynamic>? meta;
  final int unreadCount;

  const ChatRoom({
    required this.id,
    this.title,
    this.createdAt,
    this.lastActivityAt,
    this.isArchived = false,
    this.source,
    this.meta,
    this.unreadCount = 0,
  });

  bool get isProactiveInbox =>
      source == 'system' && meta?['proactive_inbox'] == true;

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    final rawMeta = json['meta'];
    return ChatRoom(
      id: json['id'] as int,
      title: json['title'] as String?,
      createdAt: json['created_at'] as String?,
      lastActivityAt: json['last_activity_at'] as String?,
      isArchived: json['is_archived'] as bool? ?? false,
      source: json['source'] as String?,
      meta: rawMeta is Map
          ? Map<String, dynamic>.from(rawMeta)
          : null,
      unreadCount: (json['unread_count'] as int?) ?? 0,
    );
  }

  ChatRoom copyWith({
    int? id,
    String? title,
    String? createdAt,
    String? lastActivityAt,
    bool? isArchived,
    String? source,
    Map<String, dynamic>? meta,
    int? unreadCount,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      isArchived: isArchived ?? this.isArchived,
      source: source ?? this.source,
      meta: meta ?? this.meta,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}
