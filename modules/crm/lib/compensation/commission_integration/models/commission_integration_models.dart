class CommissionSummaryModel {
  final double sourceCompanyCommission;
  final double calculatedEmployeeCommission;
  final String currency;
  final int eventsCount;
  final List<CommissionEventItemModel> items;

  const CommissionSummaryModel({
    required this.sourceCompanyCommission,
    required this.calculatedEmployeeCommission,
    required this.currency,
    required this.eventsCount,
    required this.items,
  });

  const CommissionSummaryModel.empty({
    this.currency = "PLN",
  })  : sourceCompanyCommission = 0,
        calculatedEmployeeCommission = 0,
        eventsCount = 0,
        items = const [];

  bool get hasEvents => items.isNotEmpty || eventsCount > 0;

  factory CommissionSummaryModel.fromJson(Map<String, dynamic> json) {
    return CommissionSummaryModel(
      sourceCompanyCommission: _asDouble(
        json["source_company_commission"],
      ),
      calculatedEmployeeCommission: _asDouble(
        json["calculated_employee_commission"],
      ),
      currency: _asString(
        json["currency"],
        fallback: "PLN",
      ),
      eventsCount: _asInt(
        json["events_count"],
        fallback: _asList(json["items"]).length,
      ),
      items: _asList(json["items"])
          .map(CommissionEventItemModel.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "source_company_commission": sourceCompanyCommission,
      "calculated_employee_commission": calculatedEmployeeCommission,
      "currency": currency,
      "events_count": eventsCount,
      "items": items.map((item) => item.toJson()).toList(),
    };
  }
}

class CommissionEventItemModel {
  final int id;
  final int eventId;
  final String eventType;
  final String eventStatus;
  final String eventLabel;
  final String occurredAt;
  final String trigger;
  final String basisKind;
  final double basisAmount;
  final double calculatedCommission;
  final String currency;
  final int? employeeId;
  final int? transactionId;
  final int? invoiceId;
  final List<CommissionSettlementLinkModel> settlementLines;

  const CommissionEventItemModel({
    required this.id,
    required this.eventId,
    required this.eventType,
    required this.eventStatus,
    required this.eventLabel,
    required this.occurredAt,
    required this.trigger,
    required this.basisKind,
    required this.basisAmount,
    required this.calculatedCommission,
    required this.currency,
    required this.employeeId,
    required this.transactionId,
    required this.invoiceId,
    required this.settlementLines,
  });

  bool get isSettled => eventStatus == "settled";

  factory CommissionEventItemModel.fromJson(Map<String, dynamic> json) {
    return CommissionEventItemModel(
      id: _asInt(json["id"]),
      eventId: _asInt(json["event_id"]),
      eventType: _asString(json["event_type"]),
      eventStatus: _asString(json["event_status"]),
      eventLabel: _asString(json["event_label"]),
      occurredAt: _asString(json["occurred_at"]),
      trigger: _asString(json["trigger"]),
      basisKind: _asString(json["basis_kind"]),
      basisAmount: _asDouble(json["basis_amount"]),
      calculatedCommission: _asDouble(
        json["calculated_commission"],
      ),
      currency: _asString(json["currency"], fallback: "PLN"),
      employeeId: _asNullableInt(json["employee_id"]),
      transactionId: _asNullableInt(json["transaction_id"]),
      invoiceId: _asNullableInt(json["invoice_id"]),
      settlementLines: _asList(json["settlement_lines"])
          .map(CommissionSettlementLinkModel.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "event_id": eventId,
      "event_type": eventType,
      "event_status": eventStatus,
      "event_label": eventLabel,
      "occurred_at": occurredAt,
      "trigger": trigger,
      "basis_kind": basisKind,
      "basis_amount": basisAmount,
      "calculated_commission": calculatedCommission,
      "currency": currency,
      "employee_id": employeeId,
      "transaction_id": transactionId,
      "invoice_id": invoiceId,
      "settlement_lines": settlementLines
          .map((line) => line.toJson())
          .toList(),
    };
  }
}

class CommissionSettlementLinkModel {
  final int id;
  final int settlementId;
  final String settlementStatus;
  final int? ruleId;
  final String? ruleTitle;
  final double amount;
  final String currency;

  const CommissionSettlementLinkModel({
    required this.id,
    required this.settlementId,
    required this.settlementStatus,
    required this.ruleId,
    required this.ruleTitle,
    required this.amount,
    required this.currency,
  });

  factory CommissionSettlementLinkModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return CommissionSettlementLinkModel(
      id: _asInt(json["id"]),
      settlementId: _asInt(json["settlement_id"]),
      settlementStatus: _asString(json["settlement_status"]),
      ruleId: _asNullableInt(json["rule_id"]),
      ruleTitle: _asNullableString(json["rule_title"]),
      amount: _asDouble(json["amount"]),
      currency: _asString(json["currency"], fallback: "PLN"),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "settlement_id": settlementId,
      "settlement_status": settlementStatus,
      "rule_id": ruleId,
      "rule_title": ruleTitle,
      "amount": amount,
      "currency": currency,
    };
  }
}

class CommissionSourceModel {
  final int id;
  final String trigger;
  final String basisKind;
  final double basisAmount;
  final String currency;
  final CommissionTransactionSourceModel? transaction;
  final CommissionInvoiceSourceModel? invoice;

  const CommissionSourceModel({
    required this.id,
    required this.trigger,
    required this.basisKind,
    required this.basisAmount,
    required this.currency,
    required this.transaction,
    required this.invoice,
  });

  factory CommissionSourceModel.fromJson(Map<String, dynamic> json) {
    final transactionJson = _asMapOrNull(json["transaction"]);
    final invoiceJson = _asMapOrNull(json["invoice"]);

    return CommissionSourceModel(
      id: _asInt(json["id"]),
      trigger: _asString(json["trigger"]),
      basisKind: _asString(json["basis_kind"]),
      basisAmount: _asDouble(json["basis_amount"]),
      currency: _asString(json["currency"], fallback: "PLN"),
      transaction: transactionJson == null
          ? null
          : CommissionTransactionSourceModel.fromJson(
              transactionJson,
            ),
      invoice: invoiceJson == null
          ? null
          : CommissionInvoiceSourceModel.fromJson(invoiceJson),
    );
  }
}

class CommissionTransactionSourceModel {
  final int id;
  final String name;
  final String transactionType;
  final double value;
  final double companyCommission;

  const CommissionTransactionSourceModel({
    required this.id,
    required this.name,
    required this.transactionType,
    required this.value,
    required this.companyCommission,
  });

  factory CommissionTransactionSourceModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return CommissionTransactionSourceModel(
      id: _asInt(json["id"]),
      name: _asString(
        json["name"],
        fallback: "Transaction",
      ),
      transactionType: _asString(json["transaction_type"]),
      value: _asDouble(json["value"]),
      companyCommission: _asDouble(json["company_commission"]),
    );
  }
}

class CommissionInvoiceSourceModel {
  final int id;
  final String invoiceNumber;
  final double netAmount;
  final double taxAmount;
  final double grossAmount;

  const CommissionInvoiceSourceModel({
    required this.id,
    required this.invoiceNumber,
    required this.netAmount,
    required this.taxAmount,
    required this.grossAmount,
  });

  factory CommissionInvoiceSourceModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return CommissionInvoiceSourceModel(
      id: _asInt(json["id"]),
      invoiceNumber: _asString(
        json["invoice_number"],
        fallback: "Invoice",
      ),
      netAmount: _asDouble(json["net_amount"]),
      taxAmount: _asDouble(json["tax_amount"]),
      grossAmount: _asDouble(json["gross_amount"]),
    );
  }
}

class LinkedTransactionModel {
  final int id;
  final String name;
  final String transactionType;
  final int? responsiblePersonId;
  final double amount;
  final String currency;

  const LinkedTransactionModel({
    required this.id,
    required this.name,
    required this.transactionType,
    required this.responsiblePersonId,
    required this.amount,
    required this.currency,
  });

  factory LinkedTransactionModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return LinkedTransactionModel(
      id: _asInt(json["id"]),
      name: _asString(
        json["name"],
        fallback: "Transaction",
      ),
      transactionType: _asString(json["transaction_type"]),
      responsiblePersonId: _asNullableInt(
        json["responsible_person_id"],
      ),
      amount: _asDouble(json["amount"]),
      currency: _asString(json["currency"], fallback: "PLN"),
    );
  }
}


class InvoiceCommissionIntegrationModel {
  final int revenueId;
  final LinkedTransactionModel? linkedTransaction;
  final CommissionSummaryModel commissionSummary;

  const InvoiceCommissionIntegrationModel({
    required this.revenueId,
    this.linkedTransaction,
    this.commissionSummary = const CommissionSummaryModel.empty(),
  });

  factory InvoiceCommissionIntegrationModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final linked = _asMapOrNull(json["linked_transaction"]);

    return InvoiceCommissionIntegrationModel(
      revenueId: _asInt(json["id"]),
      linkedTransaction: linked == null
          ? null
          : LinkedTransactionModel.fromJson(linked),
      commissionSummary: CommissionSummaryModel.fromJson(
        _asMap(json["commission_summary"]),
      ),
    );
  }
}

class CommissionTransactionOption {
  final int id;
  final String title;
  final String? subtitle;
  final double amount;
  final String currency;
  final bool isClosed;

  const CommissionTransactionOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.currency,
    required this.isClosed,
  });

  factory CommissionTransactionOption.fromJson(
    Map<String, dynamic> json,
  ) {
    final fallbackTitle = [
      json["name"],
      json["transaction_name"],
    ].where((value) => value != null && value.toString().trim().isNotEmpty)
        .map((value) => value.toString().trim())
        .firstOrNull;

    return CommissionTransactionOption(
      id: _asInt(json["id"]),
      title: fallbackTitle ?? "Transaction #${_asInt(json["id"])}",
      subtitle: _asNullableString(json["transaction_type"]),
      amount: _asDouble(
        json["property_final_price"] ??
            json["final_amount"] ??
            json["amount"],
      ),
      currency: _asString(json["currency"], fallback: "PLN"),
      isClosed: json["date_closed"] != null ||
          json["isComplete"] == true ||
          json["isTransactionSuccess"] == true,
    );
  }
}

extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}


Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }

  return <String, dynamic>{};
}

Map<String, dynamic>? _asMapOrNull(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return null;
}

List<Map<String, dynamic>> _asList(dynamic value) {
  if (value is! List) {
    return const [];
  }

  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

double _asDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }

  if (value is String) {
    return double.tryParse(value.replaceAll(",", ".")) ?? 0;
  }

  return 0;
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  if (value is String) {
    return int.tryParse(value) ?? fallback;
  }

  return fallback;
}

int? _asNullableInt(dynamic value) {
  if (value == null) {
    return null;
  }

  final result = _asInt(value, fallback: -1);
  return result < 0 ? null : result;
}

String _asString(
  dynamic value, {
  String fallback = "",
}) {
  final result = value?.toString().trim();
  return result == null || result.isEmpty ? fallback : result;
}

String? _asNullableString(dynamic value) {
  final result = value?.toString().trim();
  return result == null || result.isEmpty ? null : result;
}
