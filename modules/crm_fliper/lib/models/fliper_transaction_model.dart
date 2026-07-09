class TransactionsResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<FliperTransaction> results;

  TransactionsResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory TransactionsResponse.fromJson(Map<String, dynamic> json) {
    return TransactionsResponse(
      count: json['count'],
      next: json['next'],
      previous: json['previous'],
      results:
      (json['results'] as List)
          .map((e) => FliperTransaction.fromJson(e))
          .toList(),
    );
  }
}

class FliperTransaction {
  final int id;
  final String? title;
  final String? image;
  final String? address;
  final String? area;
  final int? rooms;
  final String? technicalCondition;
  final String? description;
  final String? note;
  final dynamic checklist;
  final String? dateCreate;
  final String? dateUpdate;
  final int? transaction;
  final int? transactionNetworkMonitoring;
  final int? transactionHously;
  final int user;
  final int client;

  FliperTransaction({
    required this.id,
    this.title,
    this.image,
    this.address,
    this.area,
    this.rooms,
    this.technicalCondition,
    this.description,
    this.note,
    this.checklist,
    this.dateCreate,
    this.dateUpdate,
    this.transaction,
    this.transactionNetworkMonitoring,
    this.transactionHously,
    required this.user,
    required this.client,
  });

  factory FliperTransaction.fromJson(Map<String, dynamic> json) {
    return FliperTransaction(
      id: json['id'],
      title: json['title'],
      image: json['image'],
      address: json['address'],
      area: json['area'],
      rooms: json['rooms'],
      technicalCondition: json['technical_condition'],
      description: json['description'],
      note: json['note'],
      checklist: json['checklist'],
      dateCreate: json['date_create'],
      dateUpdate: json['date_update'],
      transaction: json['transaction'],
      transactionNetworkMonitoring: json['transaction_network_monitoring'],
      transactionHously: json['transaction_hously'],
      user: json['user'],
      client: json['client'],
    );
  }
}
