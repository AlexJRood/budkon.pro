class TransactionChecklistResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<FliperTransactionCheckList> results;

  TransactionChecklistResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory TransactionChecklistResponse.fromJson(Map<String, dynamic> json) {
    return TransactionChecklistResponse(
      count: json['count'],
      next: json['next'],
      previous: json['previous'],
      results:
      (json['results'] as List<dynamic>)
          .map((e) => FliperTransactionCheckList.fromJson(e))
          .toList(),
    );
  }
}

class FliperTransactionCheckList {
  final int id;
  final String title;
  final String description;
  final dynamic checklist;
  final int? transaction;
  final int? predefined;
  final int user;

  FliperTransactionCheckList({
    required this.id,
    required this.title,
    required this.description,
    this.checklist,
    this.transaction,
    this.predefined,
    required this.user,
  });

  factory FliperTransactionCheckList.fromJson(Map<String, dynamic> json) {
    return FliperTransactionCheckList(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      checklist: json['checklist'],
      transaction: json['transaction'],
      predefined: json['Predefined'],
      user: json['user'],
    );
  }
}
