class NoteModel {
  final int id;
  final String title;
  final String content;
  final String createdByUsername;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isShared;
  final List<String> tags;

  const NoteModel({
    required this.id,
    required this.title,
    required this.content,
    required this.createdByUsername,
    required this.createdAt,
    required this.updatedAt,
    required this.isShared,
    required this.tags,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'] as int,
      title: (json['title'] as String?) ?? '',
      content: (json['content'] as String?) ?? '',
      createdByUsername: (json['created_by_username'] as String?) ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isShared: (json['is_shared'] as bool?) ?? false,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'content': content,
        'tags': tags,
      };

  String get displayTitle => title.trim().isNotEmpty ? title.trim() : content.trim().split('\n').first.trim();

  String get preview {
    final t = content.trim();
    if (t.isEmpty) return '';
    return t.length > 80 ? '${t.substring(0, 80)}…' : t;
  }

  NoteModel copyWith({String? title, String? content}) {
    return NoteModel(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdByUsername: createdByUsername,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isShared: isShared,
      tags: tags,
    );
  }
}
