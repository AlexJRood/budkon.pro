
class SaleDocumentResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<FliperSaleDocument> results;

  SaleDocumentResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory SaleDocumentResponse.fromJson(Map<String, dynamic> json) {
    return SaleDocumentResponse(
      count: json['count'] ?? 0,
      next: json['next'],
      previous: json['previous'],
      results:
      (json['results'] as List<dynamic>)
          .map((e) => FliperSaleDocument.fromJson(e))
          .toList(),
    );
  }
}

class FliperSaleDocument {
  final int id;
  final String title;
  final String url;
  final String uploadedAt;
  final int saleClient;

  FliperSaleDocument({
    required this.id,
    required this.title,
    required this.url,
    required this.uploadedAt,
    required this.saleClient,
  });

  factory FliperSaleDocument.fromJson(Map<String, dynamic> json) {
    return FliperSaleDocument(
      id: json['id'],
      title: json['title'] ?? '',
      url: json['url'] ?? '',
      uploadedAt: json['uploaded_at'] ?? '',
      saleClient: json['sale_client'],
    );
  }
}
