class CrmExpensesUploadModel {
  final String amount;
  final DateTime dateCreate;
  final DateTime dateUpdate;
  final String? note;
  final int client;
  final String? transactionName;
  final String? invoiceNumber;
  final Map<String, dynamic>? invoiceData;
  final bool sendInvoiceEmail;
  final List<dynamic>? documents;
  final List<dynamic>? tags;
  final List<dynamic>? paymentMethods;
  final String? status;
  final Map<String, dynamic>? address;
  final double? taxAmount;

  CrmExpensesUploadModel({
    required this.amount,
    required this.dateCreate,
    required this.dateUpdate,
    this.note,
    required this.client,
    this.transactionName,
    this.invoiceNumber,
    this.invoiceData,
    required this.sendInvoiceEmail,
    this.documents,
    this.tags,
    this.paymentMethods,
    this.status,
    this.address,
    this.taxAmount,
  });

  factory CrmExpensesUploadModel.fromJson(Map<String, dynamic> json) {
    return CrmExpensesUploadModel(
      amount: json['amount'].toString(),
      dateCreate: DateTime.parse(json['date_create']),
      dateUpdate: DateTime.parse(json['date_update']),
      note: json['note'],
      client: json['client'],
      transactionName: json['transaction_name'],
      invoiceNumber: json['invoice_number'],
      invoiceData: json['invoice_data'],
      sendInvoiceEmail: json['send_invoice_email'],
      documents: json['documents'] ?? [],
      tags: json['tags'] ?? [],
      paymentMethods: json['payment_methods'] ?? [],
      status: json['status'],
      address: json['address'],
      taxAmount: json['tax_amount'] != null
          ? (json['tax_amount'] is String
              ? double.tryParse(json['tax_amount']) ?? 0.0
              : (json['tax_amount'] as num).toDouble())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'date_create': dateCreate.toIso8601String(),
      'date_update': dateUpdate.toIso8601String(),
      'note': note,
      'client': client,
      'transaction_name': transactionName,
      'invoice_number': invoiceNumber,
      'invoice_data': invoiceData,
      'send_invoice_email': sendInvoiceEmail,
      'documents': documents,
      'tags': tags,
      'payment_methods': paymentMethods,
      'status': status,
      'address': address,
      'tax_amount': taxAmount,
    };
  }
}
