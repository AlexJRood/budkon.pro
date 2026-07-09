class SaleDocument {
  final int id;
  final int sale;
  final String documentName;
  final String fileUrl;

  SaleDocument({
    required this.id,
    required this.sale,
    required this.documentName,
    required this.fileUrl,
  });

  factory SaleDocument.fromJson(Map<String, dynamic> json) {
    return SaleDocument(
      id: json['id'] as int,
      sale: json['sale'] as int,
      documentName: json['document_name'] as String,
      fileUrl: json['file'] as String,
    );
  }
}
