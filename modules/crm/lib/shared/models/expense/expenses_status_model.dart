class ExpensesStatusModel {
  final int id;
  final String statusName;
  final int statusIndex;
  final List<int> transactionIndex; // Zmieniamy na listę intów

  ExpensesStatusModel({
    required this.id,
    required this.statusName,
    required this.statusIndex,
    required this.transactionIndex,
  });

  factory ExpensesStatusModel.fromJson(Map<String, dynamic> json) {
    return ExpensesStatusModel(
      id: json['id'],
      statusName: json['status_name'],
      statusIndex: json['status_index'],
      transactionIndex: List<int>.from(
        json['transaction_index'],
      ), // Konwersja na listę intów
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status_name': statusName,
      'status_index': statusIndex,
      'transaction_index': transactionIndex,
    };
  }

  ExpensesStatusModel copyWith({
    int? id,
    String? statusName,
    int? statusIndex,
    List<int>? transactionIndex,
  }) {
    return ExpensesStatusModel(
      id: id ?? this.id,
      statusName: statusName ?? this.statusName,
      statusIndex: statusIndex ?? this.statusIndex,
      transactionIndex: transactionIndex ?? this.transactionIndex,
    );
  }
}
