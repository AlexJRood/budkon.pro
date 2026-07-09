
class SalesResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<FliperSale> results;

  SalesResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory SalesResponse.fromJson(Map<String, dynamic> json) {
    return SalesResponse(
      count: json['count'] ?? 0,
      next: json['next'],
      previous: json['previous'],
      results:
      (json['results'] as List<dynamic>)
          .map((e) => FliperSale.fromJson(e))
          .toList(),
    );
  }
}

class FliperSale {
  final int id;
  final int transaction;
  final int agent;
  final int client;
  final String salePrice;
  final String? profitPotential;
  final String status;
  final String? saleDate;
  final String createdAt;

  FliperSale({
    required this.id,
    required this.transaction,
    required this.agent,
    required this.client,
    required this.salePrice,
    this.profitPotential,
    required this.status,
    this.saleDate,
    required this.createdAt,
  });

  factory FliperSale.fromJson(Map<String, dynamic> json) {
    return FliperSale(
      id: json['id'],
      transaction: json['transaction'],
      agent: json['agent'],
      client: json['client'],
      salePrice: json['sale_price'] ?? '0',
      profitPotential: json['profit_potential'],
      status: json['status'] ?? '',
      saleDate: json['sale_date'],
      createdAt: json['created_at'] ?? '',
    );
  }
}
