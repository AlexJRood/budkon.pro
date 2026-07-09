class BillModel {
  final String transactionid;
  final String client;
  final String amount;
  final String date;
  final String paymentMethod;
  final String note;
  final String status;
  final String transactionName;
  final String invoiceNumber;
  final String address;
  final String name;
  final List<LineItem> items;
  final List<LineItem> invoiceData;
  final bool sendInvoiceEmail;
  final List<String> documents;
  final List<String> tags;
  final String taxAmount;

  BillModel({
    required this.transactionid,
    required this.client,
    required this.amount,
    required this.date,
    required this.paymentMethod,
    required this.note,
    required this.status,
    required this.transactionName,
    required this.invoiceNumber,
    required this.address,
    required this.name,
    required this.items,
    required this.invoiceData,
    required this.sendInvoiceEmail,
    required this.documents,
    required this.tags,
    required this.taxAmount,
  });

  double totalCost() {
    return items.fold(
        0, (previousValue, element) => previousValue + element.cost);
  }

  factory BillModel.fromJson(Map<String, dynamic> json) {
    return BillModel(
      transactionid: json['transactionid'],
      client: json['client'],
      amount: json['amount'],
      date: json['date'],
      paymentMethod: json['paymentMethod'],
      note: json['note'],
      status: json['status'],
      transactionName: json['transactionName'],
      invoiceNumber: json['invoiceNumber'],
      address: json['address'],
      name: json['name'],
      items: (json['items'] as List).map((i) => LineItem.fromJson(i)).toList(),
      invoiceData: (json['invoiceData'] as List)
          .map((i) => LineItem.fromJson(i))
          .toList(),
      sendInvoiceEmail: json['sendInvoiceEmail'],
      documents: List<String>.from(json['documents']),
      tags: List<String>.from(json['tags']),
      taxAmount: json['taxAmount'],
    );
  }
}

class LineItem {
  final String description;
  final double cost;

  LineItem(this.description, this.cost);

  factory LineItem.fromJson(Map<String, dynamic> json) {
    return LineItem(
      json['description'],
      json['cost'],
    );
  }
}
