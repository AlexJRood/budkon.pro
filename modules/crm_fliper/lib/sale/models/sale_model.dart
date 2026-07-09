class Sale {
  final int id;
  final int transaction;
  final int agent;
  final int client;
  final String salePrice;
  final String profitPotential;
  final String status;
  final String saleDate;
  final String createdAt;

  Sale({
    required this.id,
    required this.transaction,
    required this.agent,
    required this.client,
    required this.salePrice,
    required this.profitPotential,
    required this.status,
    required this.saleDate,
    required this.createdAt,
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: json['id'] as int,
      transaction: json['transaction'] as int,
      agent: json['agent'] as int,
      client: json['client'] as int,
      salePrice: json['sale_price'] as String,
      profitPotential: json['profit_potential'] as String,
      status: json['status'] as String,
      saleDate: json['sale_date'] as String,
      createdAt: json['created_at'] as String,
    );
  }
}
