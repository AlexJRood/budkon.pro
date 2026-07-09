class GeneratedDocument {
  final String id;
  final String documentId;
  final String fileUrl;
  final String format;
  final String status;
  final Map<String, dynamic> metaData;
  final DateTime createdAt;

  GeneratedDocument({
    required this.id,
    required this.documentId,
    required this.fileUrl,
    required this.format,
    required this.status,
    required this.metaData,
    required this.createdAt,
  });

  factory GeneratedDocument.fromJson(Map<String, dynamic> json) {
    return GeneratedDocument(
      id: json['id'],
      documentId: json['document'],
      fileUrl: json['pdf_file'] ?? json['document_file'],
      format: json['format'] ?? 'pdf',
      status: json['status'] ?? 'draft',
      metaData: json['meta_data'] ?? {},
      createdAt: DateTime.parse(
          json['date_created'] ?? DateTime.now().toIso8601String()),
    );
  }
}
