class Revenue {
  final int id;
  final String title;
  final String amount;
  final String date;
  final String createdAt;
  final int transaction;
  final int createdBy;

  Revenue({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.createdAt,
    required this.transaction,
    required this.createdBy,
  });

  factory Revenue.fromJson(Map<String, dynamic> json) {
    return Revenue(
      id: json['id'] as int,
      title: json['title'] as String,
      amount: json['amount'] as String,
      date: json['date'] as String,
      createdAt: json['created_at'] as String,
      transaction: json['transaction'] as int,
      createdBy: json['created_by'] as int,
    );
  }
}
