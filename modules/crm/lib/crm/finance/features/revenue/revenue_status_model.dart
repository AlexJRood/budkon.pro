class RevenueStatusModel {
  final int id;
  final String statusName;
  final int statusIndex;
  final List<int> transactionIndex;

  RevenueStatusModel({
    required this.id,
    required this.statusName,
    required this.statusIndex,
    required this.transactionIndex,
  });

  factory RevenueStatusModel.fromJson(Map<String, dynamic> json) {
    final transactionIndex = json['transaction_index'];
    return RevenueStatusModel(
      id: json['id'],
      statusName: json['status_name'],
      statusIndex: json['status_index'],
      transactionIndex: (transactionIndex is List) ? List<int>.from(transactionIndex) : [],
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

  RevenueStatusModel copyWith({
    int? id,
    String? statusName,
    int? statusIndex,
    List<int>? transactionIndex,
  }) {
    return RevenueStatusModel(
      id: id ?? this.id,
      statusName: statusName ?? this.statusName,
      statusIndex: statusIndex ?? this.statusIndex,
      transactionIndex: transactionIndex ?? this.transactionIndex,
    );
  }
}
