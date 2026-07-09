// emma/model/massage.dart

class ChatMessageDto {
  final int id;
  final int sessionId;
  final String role; // "user" | "assistant" | "system"
  final String kind; // "text", "tool_call", ...
  final String content;
  final DateTime createdAt;
  final int likesCount;
  final int dislikesCount;
  final Map<String, dynamic> meta;

  /// NEW: seen flags
  final bool isSeen;
  final DateTime? seenAt;

  final bool isVisible;

  const ChatMessageDto({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.kind,
    required this.content,
    required this.createdAt,
    required this.likesCount,
    required this.dislikesCount,
    required this.meta,
    required this.isSeen,
    required this.seenAt,
    this.isVisible = true,
  });

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';

  factory ChatMessageDto.fromJson(Map<String, dynamic> json) {
    final meta = (json['meta'] as Map<String, dynamic>?) ?? <String, dynamic>{};

    // Support both explicit fields and meta fallback
    final bool isSeen = (json['is_seen'] as bool?) ??
        (meta['is_seen'] as bool?) ??
        (meta['seen'] as bool?) ??
        false;

    DateTime? seenAt;
    final rawSeenAt = json['seen_at'] ?? meta['seen_at'];
    if (rawSeenAt is String && rawSeenAt.isNotEmpty) {
      try {
        seenAt = DateTime.parse(rawSeenAt).toLocal();
      } catch (_) {}
    }

    return ChatMessageDto(
      id: json['id'] as int,
      sessionId: json['session'] as int,
      role: json['role'] as String,
      kind: json['kind'] as String? ?? 'text',
      content: json['content'] as String? ?? '',
      // Backend serializuje czas w UTC (+00:00). Bez .toLocal() DateTime zostaje
      // w UTC, a `timestamp.hour` pokazywał godzinę UTC (np. 19:55 zamiast 21:55).
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      likesCount: json['likes_count'] as int? ?? 0,
      dislikesCount: json['dislikes_count'] as int? ?? 0,
      meta: meta,
      isSeen: isSeen,
      seenAt: seenAt,
      isVisible: json['is_visible'] != false,
    );
  }

  ChatMessageDto copyWith({
    int? id,
    int? sessionId,
    String? role,
    String? kind,
    String? content,
    DateTime? createdAt,
    int? likesCount,
    int? dislikesCount,
    Map<String, dynamic>? meta,
    bool? isSeen,
    DateTime? seenAt,
    bool? isVisible,
  }) {
    return ChatMessageDto(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      role: role ?? this.role,
      kind: kind ?? this.kind,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      likesCount: likesCount ?? this.likesCount,
      dislikesCount: dislikesCount ?? this.dislikesCount,
      meta: meta ?? this.meta,
      isSeen: isSeen ?? this.isSeen,
      seenAt: seenAt ?? this.seenAt,
      isVisible: isVisible ?? this.isVisible,
    );
  }
}
