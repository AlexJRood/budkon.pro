class RenovationCostsResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<FliperRenovationCost> results;

  RenovationCostsResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory RenovationCostsResponse.fromJson(Map<String, dynamic> json) {
    return RenovationCostsResponse(
      count: json['count'] ?? 0,
      next: json['next'],
      previous: json['previous'],
      results:
      (json['results'] as List<dynamic>)
          .map((e) => FliperRenovationCost.fromJson(e))
          .toList(),
    );
  }
}

class FliperRenovationCost {
  final int id;
  final dynamic renovationCosts; // Replace with proper model if needed
  final String renovationSummary;
  final int? transaction;
  final int user;

  FliperRenovationCost({
    required this.id,
    this.renovationCosts,
    required this.renovationSummary,
    this.transaction,
    required this.user,
  });

  factory FliperRenovationCost.fromJson(Map<String, dynamic> json) {
    return FliperRenovationCost(
      id: json['id'],
      renovationCosts: json['renovation_costs'],
      renovationSummary: json['renovation_summary'] ?? '0',
      transaction: json['transaction'],
      user: json['user'],
    );
  }
}
