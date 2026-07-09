class TransactionItem {
  final String? transactionType;
  final String currency;
  final double totalAmount;

  TransactionItem({
    required this.transactionType,
    required this.currency,
    required this.totalAmount,
  });

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    return TransactionItem(
      transactionType: json['transaction_type'],
      currency: json['currency'],
      totalAmount:
          (json['total_amount'] is int)
              ? (json['total_amount'] as int).toDouble()
              : double.tryParse(json['total_amount'].toString()) ?? 0.0,
    );
  }
}

class TransactionSummary {
  final List<TransactionItem> expenses;
  final List<TransactionItem> revenues;

  TransactionSummary({required this.expenses, required this.revenues});

  factory TransactionSummary.fromJson(Map<String, dynamic> json) {
    return TransactionSummary(
      expenses:
          (json['expenses'] as List<dynamic>)
              .map((e) => TransactionItem.fromJson(e))
              .toList(),
      revenues:
          (json['revenues'] as List<dynamic>)
              .map((e) => TransactionItem.fromJson(e))
              .toList(),
    );
  }
}
