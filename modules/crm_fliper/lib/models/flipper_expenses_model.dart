class FlipperExpense {
  final int id;
  final String title;
  final String amount;
  final String date;
  final String? createdAt;
  final int transaction;
  final int? createdBy;

  FlipperExpense({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    this.createdAt,
    required this.transaction,
    this.createdBy,
  });

  factory FlipperExpense.fromJson(Map<String, dynamic> json) {
    return FlipperExpense(
      id: json['id'],
      title: json['title'],
      amount: json['amount'].toString(),
      date: json['date'],
      createdAt: json['created_at'],
      transaction: json['transaction'],
      createdBy: json['created_by'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'amount': amount,
    'date': date,
    'created_at': createdAt,
    'transaction': transaction,
    'created_by': createdBy,
  };
}

class FlipperExpenseResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<FlipperExpense> results;

  FlipperExpenseResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory FlipperExpenseResponse.fromJson(Map<String, dynamic> json) {
    return FlipperExpenseResponse(
      count: json['count'],
      next: json['next'],
      previous: json['previous'],
      results:
      (json['results'] as List)
          .map((e) => FlipperExpense.fromJson(e))
          .toList(),
    );
  }
}
