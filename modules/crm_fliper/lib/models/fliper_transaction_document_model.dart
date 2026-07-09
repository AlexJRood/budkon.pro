class TransactionDocumentResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<FliperTransactionDocument> results;

  TransactionDocumentResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory TransactionDocumentResponse.fromJson(Map<String, dynamic> json) {
    return TransactionDocumentResponse(
      count: json['count'],
      next: json['next'],
      previous: json['previous'],
      results:
      (json['results'] as List<dynamic>)
          .map((e) => FliperTransactionDocument.fromJson(e))
          .toList(),
    );
  }
}

class FliperTransactionDocument {
  final int id;
  final String documentType;
  final String file;
  final String uploadedAt;
  final int transaction;
  final int user;

  FliperTransactionDocument({
    required this.id,
    required this.documentType,
    required this.file,
    required this.uploadedAt,
    required this.transaction,
    required this.user,
  });

  factory FliperTransactionDocument.fromJson(Map<String, dynamic> json) {
    return FliperTransactionDocument(
      id: json['id'],
      documentType: json['document_type'] ?? '',
      file: json['file'] ?? '',
      uploadedAt: json['uploaded_at'] ?? '',
      transaction: json['transaction'],
      user: json['user'],
    );
  }
}
