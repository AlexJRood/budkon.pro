class DocumentComment {
  final String id;
  final String documentId;
  final int user;
  final String text;
  final DateTime createdAt;

  DocumentComment({
    required this.id,
    required this.documentId,
    required this.user,
    required this.text,
    required this.createdAt,
  });

  factory DocumentComment.fromJson(Map<String, dynamic> json) {
    return DocumentComment(
      id: json['id'],
      documentId: json['document']?.toString() ?? '',
      user: json['user'],
      text: json['text'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'document': documentId,
        'user': user,
        'text': text,
        'created_at': createdAt.toIso8601String(),
      };
}
