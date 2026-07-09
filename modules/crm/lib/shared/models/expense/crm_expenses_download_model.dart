import 'dart:convert';

class CrmExpensesDownloadModel {
  final int id;
  final String? name;
  final String amount;
  final String currency;
  final String? transactionType;
  final String? taxAmount;
  final DateTime dateCreate;
  final DateTime dateUpdate;
  final DateTime? paymentDate;
  final bool isPaid;
  final bool isMonthlyPayment;
  final DateTime? whenMonthlyPaymentIsOver;
  final String? note;
  final String? invoiceNumber;
  final Map<String, dynamic>? invoiceData;
  final List<dynamic> documents;
  final List<dynamic> tags;
  final List<dynamic> paymentMethods;
  final String? status;
  final int? objectId;
  final int? contractor;
  final dynamic clients;
  final dynamic contractorInvoice;
  final int? contentType;
  final int? createdBy;
  final dynamic myInvoiceData;

  /// Full original payload from backend.
  final Map<String, dynamic>? rawJson;

  CrmExpensesDownloadModel({
    required this.id,
    this.name,
    required this.amount,
    required this.currency,
    this.transactionType,
    this.taxAmount,
    required this.dateCreate,
    required this.dateUpdate,
    this.paymentDate,
    required this.isPaid,
    required this.isMonthlyPayment,
    this.whenMonthlyPaymentIsOver,
    this.note,
    this.invoiceNumber,
    this.invoiceData,
    required this.documents,
    required this.tags,
    required this.paymentMethods,
    this.status,
    this.objectId,
    this.contractor,
    this.clients,
    this.contractorInvoice,
    this.contentType,
    this.createdBy,
    this.myInvoiceData,
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

  static DateTime _toDateRequired(dynamic v) {
    final parsed = DateTime.tryParse(v?.toString() ?? '');
    return parsed ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  static DateTime? _toDateNullable(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  static List<dynamic> _parseList(dynamic value) {
    if (value == null) return [];
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

  factory CrmExpensesDownloadModel.fromJson(Map<String, dynamic> json) {
    final raw = json.map((k, v) => MapEntry(k.toString(), v));

    return CrmExpensesDownloadModel(
      id: _toInt(json['id']) ?? 0,
      name: json['name']?.toString(),
      amount: json['total_amount']?.toString() ?? '0.0',
      currency: json['currency']?.toString() ?? '',
      transactionType: json['transaction_type']?.toString(),
      taxAmount: json['tax_amount']?.toString(),
      dateCreate: _toDateRequired(json['date_create']),
      dateUpdate: _toDateRequired(json['date_update']),
      paymentDate: _toDateNullable(json['payment_date']),
      isPaid: _toBool(json['is_paid']),
      isMonthlyPayment: _toBool(json['is_monthly_payment']),
      whenMonthlyPaymentIsOver: _toDateNullable(
        json['when_monthly_payment_is_over'],
      ),
      note: json['note']?.toString(),
      invoiceNumber: json['invoice_number']?.toString(),
      invoiceData: _cloneMap(json['invoice_data']),
      documents: _parseList(json['documents']),
      tags: _parseList(json['tags']),
      paymentMethods: _parseList(json['payment_methods']),
      status: json['status']?.toString(),
      objectId: _toInt(json['object_id']),
      contractor: _toInt(json['contractor']),
      clients: json['clients'],
      contractorInvoice: json['contractor_invoice'],
      contentType: _toInt(json['content_type']),
      createdBy: _toInt(json['created_by']),
      myInvoiceData: json['my_invoice_data'],
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
      'amount': amount,
      'currency': currency,
      'transaction_type': transactionType,
      'tax_amount': taxAmount,
      'date_create': dateCreate.toIso8601String(),
      'date_update': dateUpdate.toIso8601String(),
      'payment_date': paymentDate?.toIso8601String(),
      'is_paid': isPaid,
      'is_monthly_payment': isMonthlyPayment,
      'when_monthly_payment_is_over':
          whenMonthlyPaymentIsOver?.toIso8601String(),
      'note': note,
      'invoice_number': invoiceNumber,
      'invoice_data': invoiceData,
      'documents': documents,
      'tags': tags,
      'payment_methods': paymentMethods,
      'status': status,
      'object_id': objectId,
      'contractor': contractor,
      'clients': clients,
      'contractor_invoice': contractorInvoice,
      'content_type': contentType,
      'created_by': createdBy,
      'my_invoice_data': myInvoiceData,
    });

    return base;
  }
}