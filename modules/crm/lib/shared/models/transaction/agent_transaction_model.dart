import "package:crm/compensation/commission_integration/models/commission_integration_models.dart";
import "package:crm/shared/models/clients_model.dart";
import "package:get/get_utils/get_utils.dart";

class UserPublicProfileModel {
  final int id;
  final String username;
  final String? email;
  final String? firstName;
  final String? lastName;
  final dynamic avatar;

  const UserPublicProfileModel({
    required this.id,
    required this.username,
    this.email,
    this.firstName,
    this.lastName,
    this.avatar,
  });

  factory UserPublicProfileModel.fromJson(Map<String, dynamic> json) {
    return UserPublicProfileModel(
      id: _asInt(json["id"]),
      username: _asString(json["username"]),
      email: _asNullableString(json["email"]),
      firstName: _asNullableString(json["first_name"]),
      lastName: _asNullableString(json["last_name"]),
      avatar: json["avatar"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "username": username,
      "email": email,
      "first_name": firstName,
      "last_name": lastName,
      "avatar": avatar,
    };
  }

  String get fullName {
    final first = (firstName ?? "").trim();
    final last = (lastName ?? "").trim();
    final combined = "$first $last".trim();
    return combined.isEmpty ? username : combined;
  }
}

class AgentTransactionModel {
  final int id;
  final UserContactModel client;
  final bool isSeller;
  final bool isBuyer;
  final String name;
  final String commission;
  final String amount;
  final String? finalAmount;
  final String? propertyFinalPrice;
  final String currency;
  final String transactionType;
  final DateTime dateCreate;
  final DateTime dateUpdate;
  final DateTime? dateClosed;
  final DateTime? paymentDate;
  final bool isMonthlyPayment;
  final DateTime? whenMonthlyPaymentIsOver;
  final String? note;
  final String? transactionName;
  final String? invoiceNumber;
  final Map<String, dynamic> invoiceData;
  final bool sendInvoiceEmail;
  final List<Map<String, dynamic>> invoices;
  final List<dynamic> documents;
  final List<dynamic> tags;
  final String? paymentMethods;
  final String? status;
  final bool isPaid;
  final String? country;
  final String? city;
  final String? street;
  final String? postalCode;
  final String? taxAmount;
  final int? draft;
  final int createdBy;
  final int? responsiblePersonId;
  final UserPublicProfileModel? responsiblePersonData;
  final bool isCommisssionPercentage;
  final bool isCommissionNetValue;
  final bool isComplete;
  final bool isArchive;
  final bool? isSuccess;
  final String? propertyUrl;
  final int? propertyNmAdId;
  final CommissionSummaryModel commissionSummary;
  final String? landAndMortgageRegister;
  final String kwDownloadStatus; // idle | pending | downloading | ready | error

  const AgentTransactionModel({
    required this.id,
    required this.client,
    required this.isSeller,
    required this.isBuyer,
    required this.name,
    required this.commission,
    required this.amount,
    this.finalAmount,
    this.propertyFinalPrice,
    required this.currency,
    required this.transactionType,
    required this.dateCreate,
    required this.dateUpdate,
    this.dateClosed,
    this.paymentDate,
    required this.isMonthlyPayment,
    this.whenMonthlyPaymentIsOver,
    this.note,
    this.transactionName,
    this.invoiceNumber,
    required this.invoiceData,
    required this.sendInvoiceEmail,
    this.invoices = const <Map<String, dynamic>>[],
    required this.documents,
    required this.tags,
    required this.paymentMethods,
    this.status,
    required this.isPaid,
    this.country,
    this.city,
    this.street,
    this.postalCode,
    this.taxAmount,
    this.draft,
    required this.createdBy,
    this.responsiblePersonId,
    this.responsiblePersonData,
    required this.isCommisssionPercentage,
    this.isCommissionNetValue = true,
    this.isComplete = false,
    this.isArchive = false,
    this.isSuccess,
    this.propertyUrl,
    this.propertyNmAdId,
    this.commissionSummary = const CommissionSummaryModel.empty(),
    this.landAndMortgageRegister,
    this.kwDownloadStatus = 'idle',
  });

  AgentTransactionModel copyWith({
    int? id,
    UserContactModel? client,
    bool? isSeller,
    bool? isBuyer,
    String? name,
    String? commission,
    String? amount,
    String? finalAmount,
    bool clearFinalAmount = false,
    String? propertyFinalPrice,
    bool clearPropertyFinalPrice = false,
    String? currency,
    String? transactionType,
    DateTime? dateCreate,
    DateTime? dateUpdate,
    DateTime? dateClosed,
    bool clearDateClosed = false,
    DateTime? paymentDate,
    bool clearPaymentDate = false,
    bool? isMonthlyPayment,
    DateTime? whenMonthlyPaymentIsOver,
    bool clearWhenMonthlyPaymentIsOver = false,
    String? note,
    bool clearNote = false,
    String? transactionName,
    bool clearTransactionName = false,
    String? invoiceNumber,
    bool clearInvoiceNumber = false,
    Map<String, dynamic>? invoiceData,
    bool? sendInvoiceEmail,
    List<Map<String, dynamic>>? invoices,
    List<dynamic>? documents,
    List<dynamic>? tags,
    String? paymentMethods,
    bool clearPaymentMethods = false,
    String? status,
    bool clearStatus = false,
    bool? isPaid,
    String? country,
    String? city,
    String? street,
    String? postalCode,
    String? taxAmount,
    int? draft,
    int? createdBy,
    int? responsiblePersonId,
    bool clearResponsiblePerson = false,
    UserPublicProfileModel? responsiblePersonData,
    bool? isCommisssionPercentage,
    bool? isCommissionNetValue,
    bool? isComplete,
    bool? isArchive,
    bool? isSuccess,
    String? propertyUrl,
    int? propertyNmAdId,
    CommissionSummaryModel? commissionSummary,
    String? landAndMortgageRegister,
    bool clearLandAndMortgageRegister = false,
    String? kwDownloadStatus,
  }) {
    return AgentTransactionModel(
      id: id ?? this.id,
      client: client ?? this.client,
      isSeller: isSeller ?? this.isSeller,
      isBuyer: isBuyer ?? this.isBuyer,
      name: name ?? this.name,
      commission: commission ?? this.commission,
      amount: amount ?? this.amount,
      finalAmount: clearFinalAmount ? null : finalAmount ?? this.finalAmount,
      propertyFinalPrice: clearPropertyFinalPrice
          ? null
          : propertyFinalPrice ?? this.propertyFinalPrice,
      currency: currency ?? this.currency,
      transactionType: transactionType ?? this.transactionType,
      dateCreate: dateCreate ?? this.dateCreate,
      dateUpdate: dateUpdate ?? this.dateUpdate,
      dateClosed: clearDateClosed ? null : dateClosed ?? this.dateClosed,
      paymentDate: clearPaymentDate ? null : paymentDate ?? this.paymentDate,
      isMonthlyPayment: isMonthlyPayment ?? this.isMonthlyPayment,
      whenMonthlyPaymentIsOver: clearWhenMonthlyPaymentIsOver
          ? null
          : whenMonthlyPaymentIsOver ?? this.whenMonthlyPaymentIsOver,
      note: clearNote ? null : note ?? this.note,
      transactionName:
          clearTransactionName ? null : transactionName ?? this.transactionName,
      invoiceNumber:
          clearInvoiceNumber ? null : invoiceNumber ?? this.invoiceNumber,
      invoiceData: invoiceData ?? this.invoiceData,
      sendInvoiceEmail: sendInvoiceEmail ?? this.sendInvoiceEmail,
      invoices: invoices ?? this.invoices,
      documents: documents ?? this.documents,
      tags: tags ?? this.tags,
      paymentMethods:
          clearPaymentMethods ? null : paymentMethods ?? this.paymentMethods,
      status: clearStatus ? null : status ?? this.status,
      isPaid: isPaid ?? this.isPaid,
      country: country ?? this.country,
      city: city ?? this.city,
      street: street ?? this.street,
      postalCode: postalCode ?? this.postalCode,
      taxAmount: taxAmount ?? this.taxAmount,
      draft: draft ?? this.draft,
      createdBy: createdBy ?? this.createdBy,
      responsiblePersonId: clearResponsiblePerson
          ? null
          : responsiblePersonId ?? this.responsiblePersonId,
      responsiblePersonData: clearResponsiblePerson
          ? null
          : responsiblePersonData ?? this.responsiblePersonData,
      isCommisssionPercentage:
          isCommisssionPercentage ?? this.isCommisssionPercentage,
      isCommissionNetValue:
          isCommissionNetValue ?? this.isCommissionNetValue,
      isComplete: isComplete ?? this.isComplete,
      isArchive: isArchive ?? this.isArchive,
      isSuccess: isSuccess ?? this.isSuccess,
      propertyUrl: propertyUrl ?? this.propertyUrl,
      propertyNmAdId: propertyNmAdId ?? this.propertyNmAdId,
      commissionSummary: commissionSummary ?? this.commissionSummary,
      landAndMortgageRegister: clearLandAndMortgageRegister
          ? null
          : landAndMortgageRegister ?? this.landAndMortgageRegister,
      kwDownloadStatus: kwDownloadStatus ?? this.kwDownloadStatus,
    );
  }

  factory AgentTransactionModel.fromJson(Map<String, dynamic> json) {
    final responsiblePersonJson = _asMapOrNull(
      json["responsible_person_data"],
    );

    return AgentTransactionModel(
      id: _asInt(json["id"]),
      client: UserContactModel.fromJson(_asMap(json["client"])),
      isSeller: _asBool(json["is_seller"]),
      isBuyer: _asBool(json["is_buyer"]),
      name: _asString(json["name"], fallback: "Unknown Transaction"),
      commission: json["commission"]?.toString() ?? "0.00",
      amount: json["amount"]?.toString() ?? "0.00",
      finalAmount: _asNullableString(json["final_amount"]),
      propertyFinalPrice: _asNullableString(json["property_final_price"]),
      currency: _asString(json["currency"], fallback: "PLN"),
      transactionType: _asString(
        json["transaction_type"],
        fallback: "Unknown",
      ).tr,
      dateCreate: _parseDateLike(json["date_create"]) ?? DateTime.now(),
      dateUpdate: _parseDateLike(json["date_update"]) ?? DateTime.now(),
      dateClosed: _parseDateLike(json["date_closed"]),
      paymentDate: _parseDateLike(json["payment_date"]),
      isMonthlyPayment: _asBool(json["is_monthly_payment"]),
      whenMonthlyPaymentIsOver:
          _parseDateLike(json["when_monthly_payment_is_over"]),
      note: _asNullableString(json["note"]),
      transactionName: _asNullableString(json["transaction_name"]),
      invoiceNumber: _asNullableString(json["invoice_number"]),
      invoiceData: _asMap(json["invoice_data"]),
      sendInvoiceEmail: _asBool(json["send_invoice_email"]),
      invoices: _asMapList(json["invoice"]),
      tags: _asList(json["tags"]),
      documents: _asList(json["documents"]),
      paymentMethods: _asNullableString(json["payment_methods"]),
      status: _asNullableString(json["status"]),
      isPaid: _asBool(json["is_paid"]),
      country: _asNullableString(json["country"]),
      city: _asNullableString(json["city"]),
      street: _asNullableString(json["street"]),
      postalCode: _asNullableString(json["postal_code"]),
      taxAmount: _asNullableString(json["tax_amount"]),
      draft: _asNullableInt(json["draft"]),
      createdBy: _asInt(json["created_by"]),
      responsiblePersonId: _asNullableInt(json["responsible_person"]),
      responsiblePersonData: responsiblePersonJson == null
          ? null
          : UserPublicProfileModel.fromJson(responsiblePersonJson),
      isCommisssionPercentage: _asBool(
        json["isCommisssionPercentage"],
        fallback: true,
      ),
      isCommissionNetValue: _asBool(
        json["isCommissionNetValue"],
        fallback: true,
      ),
      isComplete: _asBool(json["isComplete"]),
      isArchive: _asBool(json["is_archive"]),
      isSuccess: json["isTransactionSuccess"] is bool
          ? json["isTransactionSuccess"] as bool
          : null,
      propertyUrl: _asNullableString(json["property_url"]),
      propertyNmAdId: _asNullableInt(json["property_nm_ad_id"]),
      commissionSummary: CommissionSummaryModel.fromJson(
        _asMap(json["commission_summary"]),
      ),
      landAndMortgageRegister: _asNullableString(json["land_and_mortgage_register"]),
      kwDownloadStatus: _asString(json["kw_download_status"], fallback: "idle"),
    );
  }

  static List<AgentTransactionModel> fromList(List<dynamic> list) {
    return list
        .whereType<Map>()
        .map(
          (json) => AgentTransactionModel.fromJson(
            Map<String, dynamic>.from(json),
          ),
        )
        .toList();
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "client": client.toJson(),
      "is_seller": isSeller,
      "is_buyer": isBuyer,
      "name": name,
      "commission": commission,
      "amount": amount,
      "final_amount": finalAmount,
      "property_final_price": propertyFinalPrice,
      "currency": currency,
      "transaction_type": transactionType,
      "date_create": dateCreate.toIso8601String(),
      "date_update": dateUpdate.toIso8601String(),
      "date_closed": dateClosed?.toIso8601String().split("T").first,
      "payment_date": paymentDate?.toIso8601String(),
      "is_monthly_payment": isMonthlyPayment,
      "when_monthly_payment_is_over":
          whenMonthlyPaymentIsOver?.toIso8601String(),
      "note": note,
      "transaction_name": transactionName,
      "invoice_number": invoiceNumber,
      "invoice_data": invoiceData,
      "send_invoice_email": sendInvoiceEmail,
      "documents": documents,
      "tags": tags,
      "payment_methods": paymentMethods,
      "status": status,
      "is_paid": isPaid,
      "country": country,
      "city": city,
      "street": street,
      "postal_code": postalCode,
      "tax_amount": taxAmount,
      "draft": draft,
      "created_by": createdBy,
      "responsible_person": responsiblePersonId,
      "isCommisssionPercentage": isCommisssionPercentage,
      "isCommissionNetValue": isCommissionNetValue,
      "isComplete": isComplete,
      "is_archive": isArchive,
      "isTransactionSuccess": isSuccess,
      "property_url": propertyUrl,
      "property_nm_ad_id": propertyNmAdId,
      "land_and_mortgage_register": landAndMortgageRegister,
    };
  }
}

DateTime? _parseDateLike(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString().trim());
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

Map<String, dynamic>? _asMapOrNull(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

List<Map<String, dynamic>> _asMapList(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

List<dynamic> _asList(dynamic value) {
  if (value is List) return List<dynamic>.from(value);
  if (value == null) return const [];
  return [value];
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

int? _asNullableInt(dynamic value) {
  if (value == null || value.toString().trim().isEmpty) return null;
  final result = _asInt(value, fallback: -1);
  return result < 0 ? null : result;
}

String _asString(dynamic value, {String fallback = ""}) {
  final result = value?.toString().trim();
  return result == null || result.isEmpty ? fallback : result;
}

String? _asNullableString(dynamic value) {
  final result = value?.toString().trim();
  return result == null || result.isEmpty ? null : result;
}

bool _asBool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (["1", "true", "yes", "on"].contains(normalized)) return true;
    if (["0", "false", "no", "off"].contains(normalized)) return false;
  }
  return fallback;
}
