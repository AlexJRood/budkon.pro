import 'dart:convert';

class AgentRevenueModel {
  final int id;
  final String? name;
  final String? transactionType;
  final String amount;
  final String currency;
  final String? taxAmount;
  final DateTime? date;
  final String? note;
  final DateTime? paymentDate;
  final List<dynamic>? paymentMethods;
  final bool isPaid;
  final bool isMonthlyPayment;
  final DateTime? whenMonthlyPaymentIsOver;
  final String? invoiceNumber;
  final Map<String, dynamic>? invoiceData;
  final List<dynamic>? documents;
  final List<dynamic>? tags;
  final String? status;
  final int? clients; 
  final DateTime? dateCreate;
  final DateTime? dateUpdate;

  /// Keeps full backend payload, including:
  /// buyer_data / seller_data / invoice_items_display / etc.
  final Map<String, dynamic>? rawJson;

  AgentRevenueModel({
    required this.id,
    this.name,
    this.transactionType,
    required this.amount,
    required this.currency,
    this.taxAmount,
    this.date,
    this.note,
    this.paymentDate,
    this.paymentMethods,
    required this.isPaid,
    required this.isMonthlyPayment,
    this.whenMonthlyPaymentIsOver,
    this.invoiceNumber,
    this.invoiceData,
    this.documents,
    this.tags,
    this.status,
    this.clients,
    this.dateCreate,
    this.dateUpdate,
    this.rawJson,
  });

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v.trim());
    return null;
  }

  static bool _toBool(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.trim().toLowerCase();
      return s == 'true' || s == '1' || s == 'yes';
    }
    return false;
  }

  static List<dynamic>? _parsePaymentMethods(dynamic value) {
    if (value == null) return null;
    if (value is List) return value;

    if (value is String) {
      final s = value.trim();
      if (s.isEmpty) return [];

      if (s.startsWith('[') && s.endsWith(']')) {
        try {
          final decoded = jsonDecode(s);
          if (decoded is List) return decoded;
        } catch (_) {}
      }

      return [s];
    }

    if (value is Map) return [value];
    return [];
  }

  static List<dynamic>? _parseListOrNull(dynamic value) {
    if (value == null) return null;
    if (value is List) return value;

    if (value is String) {
      final s = value.trim();
      if (s.isEmpty) return [];

      if (s.startsWith('[') && s.endsWith(']')) {
        try {
          final decoded = jsonDecode(s);
          if (decoded is List) return decoded;
        } catch (_) {}
      }

      return [s];
    }

    if (value is Map) return [value];
    return [];
  }

  static Map<String, dynamic>? _cloneMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
    return null;
  }

  factory AgentRevenueModel.fromJson(Map<String, dynamic> json) {
    final raw = json.map((k, v) => MapEntry(k.toString(), v));

    return AgentRevenueModel(
      id: _toInt(json['id']) ?? 0,
      name: json['name']?.toString(),
      transactionType: json['transaction_type']?.toString(),
      amount: json['total_amount']?.toString() ?? '0',
      currency: json['currency']?.toString() ?? 'PLN',
      taxAmount: json['tax_amount']?.toString(),
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString())
          : null,
      note: json['note']?.toString(),
      paymentDate: json['payment_date'] != null
          ? DateTime.tryParse(json['payment_date'].toString())
          : null,
      paymentMethods: _parsePaymentMethods(json['payment_methods']),
      isPaid: _toBool(json['is_paid']),
      isMonthlyPayment: _toBool(json['is_monthly_payment']),
      whenMonthlyPaymentIsOver: json['when_monthly_payment_is_over'] != null
          ? DateTime.tryParse(json['when_monthly_payment_is_over'].toString())
          : null,
      invoiceNumber: json['invoice_number']?.toString(),
      invoiceData: _cloneMap(json['invoice_data']),
      documents: _parseListOrNull(json['documents']),
      tags: _parseListOrNull(json['tags']),
      status: json['status']?.toString(),
      clients: _toInt(json['clients']),
      dateCreate: json['date_create'] != null
          ? DateTime.tryParse(json['date_create'].toString())
          : null,
      dateUpdate: json['date_update'] != null
          ? DateTime.tryParse(json['date_update'].toString())
          : null,
      rawJson: raw,
    );
  }

  Map<String, dynamic> toJson() {
    final base = <String, dynamic>{
      ...?rawJson,
    };

    base.addAll({
      'id': id,
      'name': name,
      'transaction_type': transactionType,
      'total_amount': amount,
      'currency': currency,
      'tax_amount': taxAmount,
      'date': date?.toIso8601String(),
      'note': note,
      'payment_date': paymentDate?.toIso8601String(),
      'payment_methods': paymentMethods,
      'is_paid': isPaid,
      'is_monthly_payment': isMonthlyPayment,
      'when_monthly_payment_is_over':
          whenMonthlyPaymentIsOver?.toIso8601String(),
      'invoice_number': invoiceNumber,
      'invoice_data': invoiceData,
      'documents': documents,
      'tags': tags,
      'status': status,
      'clients': clients,
      'date_create': dateCreate?.toIso8601String(),
      'date_update': dateUpdate?.toIso8601String(),
    });

    return base;
  }
}