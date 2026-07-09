class RevenuesResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<FliperRevenue> results;

  RevenuesResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory RevenuesResponse.fromJson(Map<String, dynamic> json) {
    return RevenuesResponse(
      count: json['count'] ?? 0,
      next: json['next'],
      previous: json['previous'],
      results:
      (json['results'] as List<dynamic>)
          .map((e) => FliperRevenue.fromJson(e))
          .toList(),
    );
  }
}

class FliperRevenue {
  final int id;
  final String title;
  final String amount;
  final String date;
  final String createdAt;
  final int transaction;
  final int? createdBy;

  FliperRevenue({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.createdAt,
    required this.transaction,
    this.createdBy,
  });

  factory FliperRevenue.fromJson(Map<String, dynamic> json) {
    return FliperRevenue(
      id: json['id'],
      title: json['title'] ?? '',
      amount: json['amount'] ?? '0',
      date: json['date'] ?? '',
      createdAt: json['created_at'] ?? '',
      transaction: json['transaction'],
      createdBy: json['created_by'],
    );
  }
}
