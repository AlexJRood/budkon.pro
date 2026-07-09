class DocumentVersion {
  final String id;
  final String documentId;
  final Map<String, dynamic> delta;
  final Map<String, dynamic> style;
  final String? comment;
  final DateTime createdAt;
  final String? createdBy;

  DocumentVersion({
    required this.id,
    required this.documentId,
    required this.delta,
    required this.style,
    this.comment,
    required this.createdAt,
    this.createdBy,
  });

  factory DocumentVersion.fromJson(Map<String, dynamic> json) {
    return DocumentVersion(
      id: json['id'].toString(),
      documentId: json['document'].toString(),
      delta: json['delta_json'] ?? {'ops': []},
      style: json['style_json'] ?? {},
      comment: json['comment'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      createdBy: json['created_by'] ?? json['created_by_username'],
    );
  }
}