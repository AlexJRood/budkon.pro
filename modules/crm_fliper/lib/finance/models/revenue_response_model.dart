import 'package:crm_fliper/finance/models/revenue_model.dart';

class RevenueResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<Revenue> results;

  RevenueResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory RevenueResponse.fromJson(Map<String, dynamic> json) {
    return RevenueResponse(
      count: json['count'] as int,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: (json['results'] as List)
          .map((item) => Revenue.fromJson(item))
          .toList(),
    );
  }
}
