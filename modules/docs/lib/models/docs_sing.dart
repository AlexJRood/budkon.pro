// models/document_signature_model.dart
class DocumentSignature {
  final String id;
  final String documentId;
  final dynamic signatureData;
  final DateTime createdAt;
  final String createdBy;

  DocumentSignature({
    required this.id,
    required this.documentId,
    required this.signatureData,
    required this.createdAt,
    required this.createdBy,
  });

  factory DocumentSignature.fromJson(Map<String, dynamic> json) {
    return DocumentSignature(
      id: json['id']?.toString() ?? '',
      documentId: json['document']?.toString() ?? '',
      signatureData: json['signature_data'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      createdBy: json['created_by'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'document': documentId,
      'signature_data': signatureData,
    };
  }
}