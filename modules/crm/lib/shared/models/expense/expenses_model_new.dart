
class ExpenseModelNew {
  final int? id;
  final String? name;
  final String? transactionType;
  final double amount;
  final String currency;
  final double? taxAmount;
  final DateTime? dateCreate;
  final DateTime? dateUpdate;
  final DateTime? paymentDate;
  final bool isPaid;
  final bool isMonthlyPayment;
  final DateTime? whenMonthlyPaymentIsOver;
  final String? note;
  final String? invoiceNumber;
  final Map<String, dynamic>? invoiceData;
  final List<dynamic>? documents;
  final List<dynamic>? tags;
  final List<dynamic>? paymentMethods;
  final String? status;
  final int? contractorId;
  final int? clientId;
  final int? contentTypeId;
  final int? objectId;

  ExpenseModelNew({
    this.id,
    this.name,
    this.transactionType,
    required this.amount,
    this.currency = 'PLN',
    this.taxAmount,
    this.dateCreate,
    this.dateUpdate,
    this.paymentDate,
    this.isPaid = false,
    this.isMonthlyPayment = false,
    this.whenMonthlyPaymentIsOver,
    this.note,
    this.invoiceNumber,
    this.invoiceData,
    this.documents,
    this.tags,
    this.paymentMethods,
    this.status,
    this.contractorId,
    this.clientId,
    this.contentTypeId,
    this.objectId,
  });

  factory ExpenseModelNew.fromJson(Map<String, dynamic> json) {
    return ExpenseModelNew(
      id: json['id'],
      name: json['name'],
      transactionType: json['transaction_type'],
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] ?? 'PLN',
      taxAmount: json['tax_amount'] != null ? (json['tax_amount'] as num).toDouble() : null,
      dateCreate: DateTime.parse(json['date_create']),
      dateUpdate: DateTime.parse(json['date_update']),
      paymentDate: json['payment_date'] != null ? DateTime.parse(json['payment_date']) : null,
      isPaid: json['is_paid'] ?? false,
      isMonthlyPayment: json['is_monthly_payment'] ?? false,
      whenMonthlyPaymentIsOver: json['when_monthly_payment_is_over'] != null
          ? DateTime.parse(json['when_monthly_payment_is_over'])
          : null,
      note: json['note'],
      invoiceNumber: json['invoice_number'],
      invoiceData: json['invoice_data'],
      documents: json['documents'] ?? [],
      tags: json['tags'] ?? [],
      paymentMethods: json['payment_methods'] ?? [],
      status: json['status'],
      contractorId: json['contractor'],
      clientId: json['clients'],
      contentTypeId: json['content_type'],
      objectId: json['object_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'transaction_type': transactionType,
      'amount': amount,
      'currency': currency,
      'tax_amount': taxAmount,
      'date_create': dateCreate?.toIso8601String(),
      'date_update': dateUpdate?.toIso8601String(),
      'payment_date': paymentDate?.toIso8601String(),
      'is_paid': isPaid,
      'is_monthly_payment': isMonthlyPayment,
      'when_monthly_payment_is_over': whenMonthlyPaymentIsOver?.toIso8601String(),
      'note': note,
      'invoice_number': invoiceNumber,
      'invoice_data': invoiceData,
      'documents': documents,
      'tags': tags,
      'payment_methods': paymentMethods,
      'status': status,
      'contractor': contractorId,
      'clients': clientId,
      'content_type': contentTypeId,
      'object_id': objectId,
    };
  }

  ExpenseModelNew copyWith({
    int? id,
    String? name,
    String? transactionType,
    double? amount,
    String? currency,
    double? taxAmount,
    DateTime? dateCreate,
    DateTime? dateUpdate,
    DateTime? paymentDate,
    bool? isPaid,
    bool? isMonthlyPayment,
    DateTime? whenMonthlyPaymentIsOver,
    String? note,
    String? invoiceNumber,
    Map<String, dynamic>? invoiceData,
    List<dynamic>? documents,
    List<dynamic>? tags,
    List<dynamic>? paymentMethods,
    String? status,
    int? contractorId,
    int? clientId,
    int? contentTypeId,
    int? objectId,
  }) {
    return ExpenseModelNew(
      id: id ?? this.id,
      name: name ?? this.name,
      transactionType: transactionType ?? this.transactionType,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      taxAmount: taxAmount ?? this.taxAmount,
      dateCreate: dateCreate ?? this.dateCreate,
      dateUpdate: dateUpdate ?? this.dateUpdate,
      paymentDate: paymentDate ?? this.paymentDate,
      isPaid: isPaid ?? this.isPaid,
      isMonthlyPayment: isMonthlyPayment ?? this.isMonthlyPayment,
      whenMonthlyPaymentIsOver: whenMonthlyPaymentIsOver ?? this.whenMonthlyPaymentIsOver,
      note: note ?? this.note,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      invoiceData: invoiceData ?? this.invoiceData,
      documents: documents ?? this.documents,
      tags: tags ?? this.tags,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      status: status ?? this.status,
      contractorId: contractorId ?? this.contractorId,
      clientId: clientId ?? this.clientId,
      contentTypeId: contentTypeId ?? this.contentTypeId,
      objectId: objectId ?? this.objectId,
    );
  }
}
