class RevenuePlanModel {
  final int id;
  final double amount;
  final String currency;
  final String status;
  final String? name;
  final String? note;
  final String? invoiceNumber;
  final Map<String, dynamic>? invoiceData;
  final List<dynamic>? documents;
  final List<dynamic>? tags;
  final Map<String, dynamic>? address;
  final List<dynamic>? paymentMethods;
  final bool isPaid;
  final double? taxAmount;
  final String? contractor;
  final String? clients;
  final DateTime? paymentDate;
  final int year;
  final int month;
  final int? day;
  final bool isMonthlyPayment;
  final DateTime? whenMonthlyPaymentIsOver;
  final String dateCreate;
  final String? dateUpdate;

  const RevenuePlanModel({
    required this.id,
    required this.amount,
    required this.currency,
    required this.status,
    required this.dateCreate,
    this.name,
    this.dateUpdate,
    this.note,
    this.invoiceNumber,
    this.invoiceData,
    this.documents,
    this.tags,
    this.address,
    this.paymentMethods,
    this.isPaid = false,
    this.taxAmount,
    this.contractor,
    this.clients,
    this.paymentDate,
    required this.year,
    required this.month,
    this.day,
    this.isMonthlyPayment = false,
    this.whenMonthlyPaymentIsOver,
  });

  factory RevenuePlanModel.fromJson(Map<String, dynamic> json) {
    return RevenuePlanModel(
      id: json['id'],
      name: json['name'] ?? 'transaction name',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      currency: json['currency'] ?? 'PLN',
      status: json['status'] ?? 'Do opłacenia',
      dateCreate: json['date_create'],
      dateUpdate: json['date_update'],
      note: json['note'],
      invoiceNumber: json['invoice_number'],
      invoiceData: json['invoice_data'],
      documents: json['documents'] != null
          ? List<dynamic>.from(json['documents'])
          : null,
      tags: json['tags'] != null ? List<dynamic>.from(json['tags']) : null,
      address: json['address'],
      paymentMethods: json['payment_methods'] != null
          ? List<dynamic>.from(json['payment_methods'])
          : null,
      isPaid: json['is_paid'] ?? false,
      taxAmount: json['tax_amount'] != null
          ? double.tryParse(json['tax_amount']?.toString() ?? '0')
          : null,
      contractor: json['contractor'],
      clients: json['clients'],
      paymentDate: json['payment_date'] != null
          ? DateTime.parse(json['payment_date'])
          : null,
      year: json['year'],
      month: json['month'],
      day: json['day'],
      isMonthlyPayment: json['is_monthly_payment'] ?? false,
      whenMonthlyPaymentIsOver: json['when_monthly_payment_is_over'] != null
          ? DateTime.parse(json['when_monthly_payment_is_over'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'currency': currency,
      'status': status,
      'date_create': dateCreate,
      'date_update': dateUpdate,
      'note': note,
      'invoice_number': invoiceNumber,
      'invoice_data': invoiceData,
      'documents': documents,
      'tags': tags,
      'address': address,
      'payment_methods': paymentMethods,
      'is_paid': isPaid,
      'tax_amount': taxAmount,
      'contractor': contractor,
      'clients': clients,
      'payment_date': paymentDate?.toIso8601String(),
      'year': year,
      'month': month,
      'day': day,
      'is_monthly_payment': isMonthlyPayment,
      'when_monthly_payment_is_over':
          whenMonthlyPaymentIsOver?.toIso8601String(),
    };
  }
}

// models/available_years.dart
class AvailableYearRevenue {
  final int year;

  AvailableYearRevenue({required this.year});

  factory AvailableYearRevenue.fromJson(Map<String, dynamic> json) {
    return AvailableYearRevenue(
      year: json['year'],
    );
  }
}
