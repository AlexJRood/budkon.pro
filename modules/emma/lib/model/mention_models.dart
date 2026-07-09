// emma/models/mention_models.dart

enum MentionKind { user, contact, transaction, tool }

class MentionItem {
  final MentionKind kind;
  final int id;
  final String displayName;
  final String? subtitle;
  final String tag;
  final String? avatarUrl;

  MentionItem({
    required this.kind,
    required this.id,
    required this.displayName,
    required this.tag,
    this.subtitle,
    this.avatarUrl,
  });

  factory MentionItem.fromJson(Map<String, dynamic> json) {
    return MentionItem(
      kind: _parseKind(json['type'] as String),
      id: json['id'] as int,
      displayName: json['name'] as String? ?? '',
      subtitle: json['subtitle'] as String?,
      tag: json['tag'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String? ??
          json['avatar'] as String? ??
          json['photo'] as String?,
    );
  }

  static MentionKind _parseKind(String raw) {
    switch (raw) {
      case 'user':
        return MentionKind.user;
      case 'contact':
        return MentionKind.contact;
      case 'transaction':
        return MentionKind.transaction;
      case 'tool':
        return MentionKind.tool;
      default:
        return MentionKind.contact;
    }
  }
}
