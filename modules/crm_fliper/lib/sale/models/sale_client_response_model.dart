import 'package:crm_fliper/sale/models/sale_client_model.dart';

class SaleClientResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<SaleClient> results;

  SaleClientResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory SaleClientResponse.fromJson(Map<String, dynamic> json) {
    return SaleClientResponse(
      count: json['count'] as int,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: (json['results'] as List)
          .map((item) => SaleClient.fromJson(item))
          .toList(),
    );
  }
}
