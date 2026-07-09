import 'package:crm_fliper/sale/models/sale_document_model.dart';

class SaleDocumentResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<SaleDocument> results;

  SaleDocumentResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory SaleDocumentResponse.fromJson(Map<String, dynamic> json) {
    return SaleDocumentResponse(
      count: json['count'] as int,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: (json['results'] as List)
          .map((item) => SaleDocument.fromJson(item))
          .toList(),
    );
  }
}
