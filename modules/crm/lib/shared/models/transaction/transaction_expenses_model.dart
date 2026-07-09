import 'dart:convert';

import 'package:crm/shared/models/expense/crm_expenses_download_model.dart';
import 'package:core/platform/url.dart';

const configUrl = URLs.baseUrl;
const defaultAvatarUrl = '$configUrl/media/avatars/avatar.jpg';

List<dynamic> _parseDynamicList(dynamic value) {
  if (value == null) return const [];
  if (value is List) return value;

  if (value is String) {
    final s = value.trim();
    if (s.isEmpty) return const [];

    if (s.startsWith('[') && s.endsWith(']')) {
      try {
        final decoded = jsonDecode(s);
        if (decoded is List) return decoded;
      } catch (_) {}
    }

    return [s];
  }

  if (value is Map) return [value];

  return const [];
}

Map<String, dynamic>? _cloneMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value.map((k, v) => MapEntry(k.toString(), v));
  }
  if (value is Map) {
    return value.map((k, v) => MapEntry(k.toString(), v));
  }
  return null;
}

class TransactionExpensesModel {
  final int id;
  final String? name;
  final String? transactionType;
  final String totalAmount;
  final String currency;
  final String? taxAmount;
  final DateTime dateCreate;
  final DateTime? dateUpdate;
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
  final dynamic contractor;
  final dynamic clients;
  final dynamic contractorInvoice;
  final dynamic contentType;
  final int? createdBy;
  final dynamic myInvoiceData;
  final String contractorAvatar;

  /// Full backend payload preserved for preview/PDF.
  final Map<String, dynamic>? rawJson;

  TransactionExpensesModel({
    required this.id,
    this.name,
    this.transactionType,
    required this.totalAmount,
    required this.currency,
    this.taxAmount,
    required this.dateCreate,
    this.dateUpdate,
    this.paymentDate,
    required this.isPaid,
    required this.isMonthlyPayment,
    this.whenMonthlyPaymentIsOver,
    this.note,
    this.invoiceNumber,
    this.invoiceData,
    this.documents = const [],
    this.tags = const [],
    this.paymentMethods = const [],
    this.status,
    this.objectId,
    this.contractor,
    this.clients,
    this.contractorInvoice,
    this.contentType,
    this.createdBy,
    this.myInvoiceData,
    required this.contractorAvatar,
    this.rawJson,
  });

  factory TransactionExpensesModel.fromCrmExpensesDownload(
    CrmExpensesDownloadModel expenses,
  ) {
    return TransactionExpensesModel(
      id: expenses.id,
      name: expenses.name,
      transactionType: expenses.transactionType,
      totalAmount: expenses.amount,
      currency: expenses.currency,
      taxAmount: expenses.taxAmount,
      dateCreate: expenses.dateCreate,
      dateUpdate: expenses.dateUpdate,
      paymentDate: expenses.paymentDate,
      isPaid: expenses.isPaid,
      isMonthlyPayment: expenses.isMonthlyPayment,
      whenMonthlyPaymentIsOver: expenses.whenMonthlyPaymentIsOver,
      note: expenses.note,
      invoiceNumber: expenses.invoiceNumber,
      invoiceData: expenses.invoiceData,
      documents: expenses.documents,
      tags: expenses.tags,
      paymentMethods: expenses.paymentMethods,
      status: expenses.status,
      objectId: expenses.objectId,
      contractor: expenses.contractor,
      clients: expenses.clients,
      contractorInvoice: expenses.contractorInvoice,
      contentType: expenses.contentType,
      createdBy: expenses.createdBy,
      myInvoiceData: expenses.myInvoiceData,
      contractorAvatar: defaultAvatarUrl,
      rawJson:
          expenses.rawJson != null
              ? Map<String, dynamic>.from(expenses.rawJson!)
              : expenses.toJson(),
    );
  }

  factory TransactionExpensesModel.fromJson(Map<String, dynamic> json) {
    final raw = json.map((k, v) => MapEntry(k.toString(), v));

    return TransactionExpensesModel(
      id: _toInt(json['id']) ?? 0,
      name: json['name']?.toString(),
      transactionType: json['transaction_type']?.toString(),
      totalAmount: json['total_amount']?.toString() ?? '0',
      currency: json['currency']?.toString() ?? 'PLN',
      taxAmount: json['tax_amount']?.toString(),
      dateCreate: DateTime.parse(json['date_create']),
      dateUpdate:
          json['date_update'] != null
              ? DateTime.tryParse(json['date_update'].toString())
              : null,
      paymentDate:
          json['payment_date'] != null
              ? DateTime.tryParse(json['payment_date'].toString())
              : null,
      isPaid: json['is_paid'] == true,
      isMonthlyPayment: json['is_monthly_payment'] == true,
      whenMonthlyPaymentIsOver:
          json['when_monthly_payment_is_over'] != null
              ? DateTime.tryParse(
                json['when_monthly_payment_is_over'].toString(),
              )
              : null,
      note: json['note']?.toString(),
      invoiceNumber: json['invoice_number']?.toString(),
      invoiceData: _cloneMap(json['invoice_data']),
      documents: _parseDynamicList(json['documents']),
      tags: _parseDynamicList(json['tags']),
      paymentMethods: _parseDynamicList(json['payment_methods']),
      status: json['status']?.toString(),
      objectId: _toInt(json['object_id']),
      contractor: json['contractor'],
      clients: json['clients'],
      contractorInvoice: json['contractor_invoice'],
      contentType: json['content_type'],
      createdBy: _toInt(json['created_by']),
      myInvoiceData: json['my_invoice_data'],
      contractorAvatar: json['contractor_avatar'] ?? defaultAvatarUrl,
      rawJson: raw,
    );
  }
  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v.trim());
    return null;
  }

  Map<String, dynamic> toJson() {
    final base = <String, dynamic>{...?rawJson};

    base.addAll({
      'id': id,
      'name': name,
      'transaction_type': transactionType,
      'total_amount': totalAmount,
      'currency': currency,
      'tax_amount': taxAmount,
      'date_create': dateCreate.toIso8601String(),
      'date_update': dateUpdate?.toIso8601String(),
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
      'contractor_avatar': contractorAvatar,
    });

    return base;
  }

  TransactionExpensesModel copyWith({
    int? id,
    String? name,
    String? transactionType,
    String? totalAmount,
    String? currency,
    String? taxAmount,
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
    int? objectId,
    dynamic contractor,
    dynamic clients,
    dynamic contractorInvoice,
    dynamic contentType,
    int? createdBy,
    dynamic myInvoiceData,
    String? contractorAvatar,
    Map<String, dynamic>? rawJson,
  }) {
    return TransactionExpensesModel(
      id: id ?? this.id,
      name: name ?? this.name,
      transactionType: transactionType ?? this.transactionType,
      totalAmount: totalAmount ?? this.totalAmount,
      currency: currency ?? this.currency,
      taxAmount: taxAmount ?? this.taxAmount,
      dateCreate: dateCreate ?? this.dateCreate,
      dateUpdate: dateUpdate ?? this.dateUpdate,
      paymentDate: paymentDate ?? this.paymentDate,
      isPaid: isPaid ?? this.isPaid,
      isMonthlyPayment: isMonthlyPayment ?? this.isMonthlyPayment,
      whenMonthlyPaymentIsOver:
          whenMonthlyPaymentIsOver ?? this.whenMonthlyPaymentIsOver,
      note: note ?? this.note,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      invoiceData: invoiceData ?? this.invoiceData,
      documents: documents ?? this.documents,
      tags: tags ?? this.tags,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      status: status ?? this.status,
      objectId: objectId ?? this.objectId,
      contractor: contractor ?? this.contractor,
      clients: clients ?? this.clients,
      contractorInvoice: contractorInvoice ?? this.contractorInvoice,
      contentType: contentType ?? this.contentType,
      createdBy: createdBy ?? this.createdBy,
      myInvoiceData: myInvoiceData ?? this.myInvoiceData,
      contractorAvatar: contractorAvatar ?? this.contractorAvatar,
      rawJson: rawJson ?? this.rawJson,
    );
  }
}
