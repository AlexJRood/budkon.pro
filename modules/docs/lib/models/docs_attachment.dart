// models/document_attachment_model.dart
class DocumentAttachment {
  final String id;
  final String documentId;
  final String fileName;
  final String fileUrl;
  final String fileType;
  final int fileSize;
  final DateTime uploadedAt;
  final String uploadedBy;

  DocumentAttachment({
    required this.id,
    required this.documentId,
    required this.fileName,
    required this.fileUrl,
    required this.fileType,
    required this.fileSize,
    required this.uploadedAt,
    required this.uploadedBy,
  });

  factory DocumentAttachment.fromJson(Map<String, dynamic> json) {
    return DocumentAttachment(
      id: json['id']?.toString() ?? '',
      documentId: json['document']?.toString() ?? '',
      fileName: json['file_name'] ?? '',
      fileUrl: json['file_url'] ?? '',
      fileType: json['file_type'] ?? '',
      fileSize: json['file_size'] ?? 0,
      uploadedAt: DateTime.parse(json['uploaded_at'] ?? DateTime.now().toIso8601String()),
      uploadedBy: json['uploaded_by'] ?? '',
    );
  }
}