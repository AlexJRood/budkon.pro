import 'package:crm_fliper/sale/models/sale_model.dart';

class SalesResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<Sale> results;

  SalesResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory SalesResponse.fromJson(Map<String, dynamic> json) {
    return SalesResponse(
      count: json['count'] as int,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: (json['results'] as List)
          .map((item) => Sale.fromJson(item))
          .toList(),
    );
  }
}
