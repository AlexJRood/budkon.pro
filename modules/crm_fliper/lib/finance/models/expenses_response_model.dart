import 'package:crm_fliper/finance/models/expense_model.dart';

class ExpensesResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<Expense> results;

  ExpensesResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory ExpensesResponse.fromJson(Map<String, dynamic> json) {
    return ExpensesResponse(
      count: json['count'] as int,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: (json['results'] as List)
          .map((item) => Expense.fromJson(item))
          .toList(),
    );
  }
}
