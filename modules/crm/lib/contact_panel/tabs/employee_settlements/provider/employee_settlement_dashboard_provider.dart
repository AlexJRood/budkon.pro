import "dart:convert";

import "package:crm/compensation/commission_integration/models/commission_integration_models.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:core/platform/api_services.dart";

class EmployeeCompensationUrls {
  static const String dashboard =
      "https://www.superbee.cloud/finance/compensation/employee-dashboard/";
  static const String agreements =
      "https://www.superbee.cloud/finance/compensation/agreements/";
  static const String rules =
      "https://www.superbee.cloud/finance/compensation/rules/";
  static const String settlements =
      "https://www.superbee.cloud/finance/compensation/settlements/";
}

class EmployeeSettlementDashboardParams {
  final int employeeId;
  final String period;
  final String currency;

  /// `period` keeps the dashboard focused on the selected month.
  /// `all` is useful for the history tab / all-time overview.
  final String summaryScope;

  /// `recent` returns the default short history, `all` returns every settlement.
  final String historyScope;

  const EmployeeSettlementDashboardParams({
    required this.employeeId,
    required this.period,
    this.currency = "PLN",
    this.summaryScope = "period",
    this.historyScope = "recent",
  });

  Map<String, String> toQueryParameters() => {
        "employee_id": employeeId.toString(),
        "period": period,
        "currency": currency,
        "summary_scope": summaryScope,
        "history_scope": historyScope,
      };

  @override
  bool operator ==(Object other) {
    return other is EmployeeSettlementDashboardParams &&
        other.employeeId == employeeId &&
        other.period == period &&
        other.currency == currency &&
        other.summaryScope == summaryScope &&
        other.historyScope == historyScope;
  }

  @override
  int get hashCode => Object.hash(
        employeeId,
        period,
        currency,
        summaryScope,
        historyScope,
      );
}

class EmployeeSettlementPermissionsModel {
  final bool canManage;
  final bool canEditAgreement;
  final bool canCalculate;
  final bool canAddManualLine;
  final bool canPublish;
  final bool canMarkPaid;
  final bool isSelf;

  const EmployeeSettlementPermissionsModel({
    required this.canManage,
    required this.canEditAgreement,
    required this.canCalculate,
    required this.canAddManualLine,
    required this.canPublish,
    required this.canMarkPaid,
    required this.isSelf,
  });

  factory EmployeeSettlementPermissionsModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return EmployeeSettlementPermissionsModel(
      canManage: _asBool(json["can_manage"]),
      canEditAgreement: _asBool(json["can_edit_agreement"]),
      canCalculate: _asBool(json["can_calculate"]),
      canAddManualLine: _asBool(json["can_add_manual_line"]),
      canPublish: _asBool(json["can_publish"]),
      canMarkPaid: _asBool(json["can_mark_paid"]),
      isSelf: _asBool(json["is_self"]),
    );
  }
}

class EmployeeSettlementSummaryModel {
  final double total;
  final double paid;
  final double unpaid;
  final double earnings;
  final double deductions;
  final double reimbursements;
  final double employerCost;
  final int pendingEvents;
  final int settlementsCount;

  const EmployeeSettlementSummaryModel({
    required this.total,
    required this.paid,
    required this.unpaid,
    required this.earnings,
    required this.deductions,
    required this.reimbursements,
    required this.employerCost,
    required this.pendingEvents,
    required this.settlementsCount,
  });

  factory EmployeeSettlementSummaryModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return EmployeeSettlementSummaryModel(
      total: _asDouble(json["total"]),
      paid: _asDouble(json["paid"]),
      unpaid: _asDouble(json["unpaid"]),
      earnings: _asDouble(json["earnings"]),
      deductions: _asDouble(json["deductions"]),
      reimbursements: _asDouble(json["reimbursements"]),
      employerCost: _asDouble(json["employer_cost"]),
      pendingEvents: _asInt(json["pending_events"]),
      settlementsCount: _asInt(json["settlements_count"]),
    );
  }
}

class CompensationComponentModel {
  final int? id;
  final String type;
  final String title;
  final String code;
  final double amount;
  final double hourlyRate;
  final double expectedHoursPerPeriod;
  final bool requiresTimeEntries;
  final String direction;
  final String calculationMethod;
  final String eventType;
  final double fixedAmount;
  final double percentageRate;
  final double unitRate;
  final String commissionBasis;
  final double? minimumAmount;
  final double? maximumAmount;
  final String stackingPolicy;
  final String exclusiveGroup;
  final int calculationOrder;
  final bool isActive;
  final bool isEmployeeVisible;
  final Map<String, dynamic> conditions;
  final List<dynamic> tiers;
  final Map<String, dynamic> formula;
  final Map<String, dynamic> metadata;

  const CompensationComponentModel({
    this.id,
    required this.type,
    this.title = "",
    this.code = "",
    this.amount = 0,
    this.hourlyRate = 0,
    this.expectedHoursPerPeriod = 0,
    this.requiresTimeEntries = false,
    this.direction = "earning",
    this.calculationMethod = "fixed",
    this.eventType = "",
    this.fixedAmount = 0,
    this.percentageRate = 0,
    this.unitRate = 0,
    this.commissionBasis = "revenue",
    this.minimumAmount,
    this.maximumAmount,
    this.calculationOrder = 100,
    this.stackingPolicy = "stack",
    this.exclusiveGroup = "",
    this.isActive = true,
    this.isEmployeeVisible = true,
    this.conditions = const {},
    this.tiers = const [],
    this.formula = const {},
    this.metadata = const {},
  });

  bool get isFixed => type == "fixed";
  bool get isHourly => type == "hourly";
  bool get isCommission => type == "commission";
  bool get isMilestone => type == "milestone";
  bool get isRuleBased => !isFixed && !isHourly;

  factory CompensationComponentModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return CompensationComponentModel(
      id: _asNullableInt(json["id"]),
      type: _asString(json["type"], fallback: "custom"),
      title: _asString(json["title"]),
      code: _asString(json["code"]),
      amount: _asDouble(json["amount"]),
      hourlyRate: _asDouble(json["hourly_rate"]),
      expectedHoursPerPeriod:
          _asDouble(json["expected_hours_per_period"]),
      requiresTimeEntries: _asBool(json["requires_time_entries"]),
      direction: _asString(json["direction"], fallback: "earning"),
      calculationMethod: _asString(
        json["calculation_method"],
        fallback: "fixed",
      ),
      eventType: _asString(json["event_type"]),
      fixedAmount: _asDouble(json["fixed_amount"]),
      percentageRate: _asDouble(json["percentage_rate"]),
      unitRate: _asDouble(json["unit_rate"]),
      commissionBasis: _asString(
        json["commission_basis"],
        fallback: "revenue",
      ),
      minimumAmount: _asNullableDouble(json["minimum_amount"]),
      maximumAmount: _asNullableDouble(json["maximum_amount"]),
      stackingPolicy: _asString(
        json["stacking_policy"],
        fallback: "stack",
      ),
      exclusiveGroup: _asString(json["exclusive_group"]),
      calculationOrder: _asInt(json["calculation_order"], fallback: 100),
      isActive: _asBool(json["is_active"], fallback: true),
      isEmployeeVisible:
          _asBool(json["is_employee_visible"], fallback: true),
      conditions: _asMap(json["conditions"]),
      tiers: _asList(json["tiers"]),
      formula: _asMap(json["formula"]),
      metadata: _asMap(json["metadata"]),
    );
  }

  CompensationComponentModel copyWith({
    int? id,
    String? type,
    String? title,
    String? code,
    double? amount,
    double? hourlyRate,
    double? expectedHoursPerPeriod,
    bool? requiresTimeEntries,
    String? direction,
    String? calculationMethod,
    String? eventType,
    double? fixedAmount,
    double? percentageRate,
    double? unitRate,
    String? commissionBasis,
    double? minimumAmount,
    double? maximumAmount,
    int? calculationOrder,
    String? stackingPolicy,
    String? exclusiveGroup,
    bool? isActive,
    bool? isEmployeeVisible,
    Map<String, dynamic>? conditions,
    List<dynamic>? tiers,
    Map<String, dynamic>? formula,
    Map<String, dynamic>? metadata,
  }) {
    return CompensationComponentModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      code: code ?? this.code,
      amount: amount ?? this.amount,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      expectedHoursPerPeriod:
          expectedHoursPerPeriod ?? this.expectedHoursPerPeriod,
      requiresTimeEntries:
          requiresTimeEntries ?? this.requiresTimeEntries,
      direction: direction ?? this.direction,
      calculationMethod: calculationMethod ?? this.calculationMethod,
      eventType: eventType ?? this.eventType,
      fixedAmount: fixedAmount ?? this.fixedAmount,
      percentageRate: percentageRate ?? this.percentageRate,
      unitRate: unitRate ?? this.unitRate,
      commissionBasis: commissionBasis ?? this.commissionBasis,
      minimumAmount: minimumAmount ?? this.minimumAmount,
      maximumAmount: maximumAmount ?? this.maximumAmount,
      calculationOrder: calculationOrder ?? this.calculationOrder,
      stackingPolicy: stackingPolicy ?? this.stackingPolicy,
      exclusiveGroup: exclusiveGroup ?? this.exclusiveGroup,
      isActive: isActive ?? this.isActive,
      isEmployeeVisible: isEmployeeVisible ?? this.isEmployeeVisible,
      conditions: conditions ?? this.conditions,
      tiers: tiers ?? this.tiers,
      formula: formula ?? this.formula,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) "id": id,
      "type": type,
      "title": title,
      "code": code,
      "amount": amount,
      "hourly_rate": hourlyRate,
      "expected_hours_per_period": expectedHoursPerPeriod,
      "requires_time_entries": requiresTimeEntries,
      "direction": direction,
      "calculation_method": calculationMethod,
      "event_type": eventType,
      "fixed_amount": fixedAmount,
      "percentage_rate": percentageRate,
      "unit_rate": unitRate,
      "commission_basis": commissionBasis,
      "minimum_amount": minimumAmount,
      "maximum_amount": maximumAmount,
      "calculation_order": calculationOrder,
      "stacking_policy": stackingPolicy,
      "exclusive_group": exclusiveGroup,
      "is_active": isActive,
      "is_employee_visible": isEmployeeVisible,
      "conditions": conditions,
      "tiers": tiers,
      "formula": formula,
      "metadata": metadata,
    };
  }
}

class CompensationRuleModel {
  final int id;
  final int agreementId;
  final String title;
  final String code;
  final String componentType;
  final String direction;
  final String calculationMethod;
  final String eventType;
  final double fixedAmount;
  final double percentageRate;
  final double unitRate;
  final double? minimumAmount;
  final double? maximumAmount;
  final int calculationOrder;
  final bool isActive;
  final bool isEmployeeVisible;
  final Map<String, dynamic> conditions;
  final List<dynamic> tiers;
  final Map<String, dynamic> formula;
  final Map<String, dynamic> metadata;

  const CompensationRuleModel({
    required this.id,
    required this.agreementId,
    required this.title,
    required this.code,
    required this.componentType,
    required this.direction,
    required this.calculationMethod,
    required this.eventType,
    required this.fixedAmount,
    required this.percentageRate,
    required this.unitRate,
    required this.minimumAmount,
    required this.maximumAmount,
    required this.calculationOrder,
    required this.isActive,
    required this.isEmployeeVisible,
    required this.conditions,
    required this.tiers,
    required this.formula,
    required this.metadata,
  });

  factory CompensationRuleModel.fromJson(Map<String, dynamic> json) {
    return CompensationRuleModel(
      id: _asInt(json["id"]),
      agreementId: _asInt(json["agreement"]),
      title: _asString(json["title"]),
      code: _asString(json["code"]),
      componentType:
          _asString(json["component_type"], fallback: "custom"),
      direction: _asString(json["direction"], fallback: "earning"),
      calculationMethod: _asString(
        json["calculation_method"],
        fallback: "percentage",
      ),
      eventType: _asString(json["event_type"]),
      fixedAmount: _asDouble(json["fixed_amount"]),
      percentageRate: _asDouble(json["percentage_rate"]),
      unitRate: _asDouble(json["unit_rate"]),
      minimumAmount: _asNullableDouble(json["minimum_amount"]),
      maximumAmount: _asNullableDouble(json["maximum_amount"]),
      calculationOrder: _asInt(json["calculation_order"], fallback: 100),
      isActive: _asBool(json["is_active"], fallback: true),
      isEmployeeVisible:
          _asBool(json["is_employee_visible"], fallback: true),
      conditions: _asMap(json["conditions"]),
      tiers: _asList(json["tiers"]),
      formula: _asMap(json["formula"]),
      metadata: _asMap(json["metadata"]),
    );
  }
}

class CompensationDocumentBindingModel {
  final String appLabel;
  final String model;
  final String objectId;
  final String relationPrefix;
  final String defaultRelationType;
  final List<String> relationTypes;
  final bool canView;
  final bool canManage;

  const CompensationDocumentBindingModel({
    required this.appLabel,
    required this.model,
    required this.objectId,
    required this.relationPrefix,
    required this.defaultRelationType,
    required this.relationTypes,
    required this.canView,
    required this.canManage,
  });

  factory CompensationDocumentBindingModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return CompensationDocumentBindingModel(
      appLabel: _asString(
        json["app_label"],
        fallback: "compensation",
      ),
      model: _asString(
        json["model"],
        fallback: "compensationagreement",
      ),
      objectId: _asString(json["object_id"]),
      relationPrefix: _asString(
        json["relation_prefix"],
        fallback: "compensation_agreement_",
      ),
      defaultRelationType: _asString(
        json["default_relation_type"],
        fallback: "compensation_agreement_contract",
      ),
      relationTypes: _asList(json["relation_types"])
          .map((value) => value.toString())
          .where((value) => value.trim().isNotEmpty)
          .toList(growable: false),
      canView: _asBool(json["can_view"]),
      canManage: _asBool(json["can_manage"]),
    );
  }
}

class CompensationAgreementModel {
  final int id;
  final int employeeId;
  final String employeeName;
  final String employeeEmail;
  final String title;
  final String relationshipType;
  final String compensationMode;
  final String payFrequency;
  final String status;
  final String currency;
  final int paymentDay;
  final double baseAmount;
  final double hourlyRate;
  final double expectedHoursPerPeriod;
  final double minimumGuarantee;
  final double defaultCommissionRate;
  final String commissionBasis;
  final String validFrom;
  final String? validTo;
  final bool autoGenerateSettlements;
  final bool requiresTimeEntries;
  final bool employeeCanViewRules;
  final bool employeeCanViewSources;
  final String notes;
  final Map<String, dynamic> customTerms;
  final Map<String, dynamic> metadata;
  final List<CompensationComponentModel> components;
  final List<CompensationRuleModel> rules;
  final int documentsCount;
  final CompensationDocumentBindingModel? documentBinding;

  const CompensationAgreementModel({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.employeeEmail,
    required this.title,
    required this.relationshipType,
    required this.compensationMode,
    required this.payFrequency,
    required this.status,
    required this.currency,
    required this.paymentDay,
    required this.baseAmount,
    required this.hourlyRate,
    required this.expectedHoursPerPeriod,
    required this.minimumGuarantee,
    required this.defaultCommissionRate,
    required this.commissionBasis,
    required this.validFrom,
    required this.validTo,
    required this.autoGenerateSettlements,
    required this.requiresTimeEntries,
    required this.employeeCanViewRules,
    required this.employeeCanViewSources,
    required this.notes,
    required this.customTerms,
    required this.metadata,
    required this.components,
    required this.rules,
    required this.documentsCount,
    required this.documentBinding,
  });

  factory CompensationAgreementModel.fromJson(Map<String, dynamic> json) {
    return CompensationAgreementModel(
      id: _asInt(json["id"]),
      employeeId: _asInt(json["employee"]),
      employeeName: _asString(json["employee_name"]),
      employeeEmail: _asString(json["employee_email"]),
      title: _asString(json["title"]),
      relationshipType:
          _asString(json["relationship_type"], fallback: "employment"),
      compensationMode:
          _asString(json["compensation_mode"], fallback: "fixed"),
      payFrequency:
          _asString(json["pay_frequency"], fallback: "monthly"),
      status: _asString(json["status"], fallback: "draft"),
      currency: _asString(json["currency"], fallback: "PLN"),
      paymentDay: _asInt(json["payment_day"], fallback: 10),
      baseAmount: _asDouble(json["base_amount"]),
      hourlyRate: _asDouble(json["hourly_rate"]),
      expectedHoursPerPeriod:
          _asDouble(json["expected_hours_per_period"]),
      minimumGuarantee: _asDouble(json["minimum_guarantee"]),
      defaultCommissionRate:
          _asDouble(json["default_commission_rate"]),
      commissionBasis:
          _asString(json["commission_basis"], fallback: "revenue"),
      validFrom: _asString(json["valid_from"]),
      validTo: _asNullableString(json["valid_to"]),
      autoGenerateSettlements:
          _asBool(json["auto_generate_settlements"], fallback: true),
      requiresTimeEntries: _asBool(json["requires_time_entries"]),
      employeeCanViewRules:
          _asBool(json["employee_can_view_rules"], fallback: true),
      employeeCanViewSources:
          _asBool(json["employee_can_view_sources"], fallback: true),
      notes: _asString(json["notes"]),
      customTerms: _asMap(json["custom_terms"]),
      metadata: _asMap(json["metadata"]),
      components: _asMapList(json["components"])
          .map(CompensationComponentModel.fromJson)
          .toList(),
      rules: _asMapList(json["rules"])
          .map(CompensationRuleModel.fromJson)
          .toList(),
      documentsCount: _asInt(json["documents_count"]),
      documentBinding: _asMapOrNull(json["document_binding"]) == null
          ? null
          : CompensationDocumentBindingModel.fromJson(
              _asMap(json["document_binding"]),
            ),
    );
  }
}

class CompensationSettlementLineModel {
  final int id;
  final int? settlementId;
  final int? ruleId;
  final int? eventId;
  final String title;
  final String description;
  final String lineType;
  final String direction;
  final double quantity;
  final double unitRate;
  final double basisAmount;
  final double percentageRate;
  final double amount;
  final bool isManual;
  final bool isEmployeeVisible;
  final String? eventLabel;
  final String? eventType;
  final String? ruleTitle;
  final String? componentType;
  final Map<String, dynamic> metadata;
  final CommissionSourceModel? source;

  const CompensationSettlementLineModel({
    required this.id,
    required this.settlementId,
    required this.ruleId,
    required this.eventId,
    required this.title,
    required this.description,
    required this.lineType,
    required this.direction,
    required this.quantity,
    required this.unitRate,
    required this.basisAmount,
    required this.percentageRate,
    required this.amount,
    required this.isManual,
    required this.isEmployeeVisible,
    required this.eventLabel,
    required this.eventType,
    required this.ruleTitle,
    required this.componentType,
    required this.metadata,
    required this.source,
  });

  factory CompensationSettlementLineModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final sourceJson = _asMapOrNull(json["source"]);

    return CompensationSettlementLineModel(
      id: _asInt(json["id"]),
      settlementId: _asNullableInt(json["settlement"]),
      ruleId: _asNullableInt(json["rule"]),
      eventId: _asNullableInt(json["event"]),
      title: _asString(json["title"]),
      description: _asString(json["description"]),
      lineType: _asString(json["line_type"], fallback: "custom"),
      direction: _asString(json["direction"], fallback: "earning"),
      quantity: _asDouble(json["quantity"]),
      unitRate: _asDouble(json["unit_rate"]),
      basisAmount: _asDouble(json["basis_amount"]),
      percentageRate: _asDouble(json["percentage_rate"]),
      amount: _asDouble(json["amount"]),
      isManual: _asBool(json["is_manual"]),
      isEmployeeVisible:
          _asBool(json["is_employee_visible"], fallback: true),
      eventLabel: _asNullableString(json["event_label"]),
      eventType: _asNullableString(json["event_type"]),
      ruleTitle: _asNullableString(json["rule_title"]),
      componentType: _asNullableString(json["component_type"]),
      metadata: _asMap(json["metadata"]),
      source: sourceJson == null
          ? null
          : CommissionSourceModel.fromJson(sourceJson),
    );
  }

  String get calculationDescription {
    if (percentageRate != 0 && basisAmount != 0) {
      return "${basisAmount.toStringAsFixed(2)} × "
          "${percentageRate.toStringAsFixed(2)}%";
    }
    if (quantity != 0 && unitRate != 0) {
      return "${quantity.toStringAsFixed(2)} × "
          "${unitRate.toStringAsFixed(2)}";
    }
    return isManual ? "manual" : "fixed";
  }
}

class CompensationPayoutModel {
  final int id;
  final double amount;
  final String currency;
  final String status;
  final String paymentMethod;
  final String? scheduledFor;
  final String? paidAt;
  final String reference;
  final String note;
  final int? accountingExpenseId;

  const CompensationPayoutModel({
    required this.id,
    required this.amount,
    required this.currency,
    required this.status,
    required this.paymentMethod,
    required this.scheduledFor,
    required this.paidAt,
    required this.reference,
    required this.note,
    required this.accountingExpenseId,
  });

  factory CompensationPayoutModel.fromJson(Map<String, dynamic> json) {
    return CompensationPayoutModel(
      id: _asInt(json["id"]),
      amount: _asDouble(json["amount"]),
      currency: _asString(json["currency"], fallback: "PLN"),
      status: _asString(json["status"], fallback: "scheduled"),
      paymentMethod:
          _asString(json["payment_method"], fallback: "bank_transfer"),
      scheduledFor: _asNullableString(json["scheduled_for"]),
      paidAt: _asNullableString(json["paid_at"]),
      reference: _asString(json["reference"]),
      note: _asString(json["note"]),
      accountingExpenseId: _asNullableInt(json["accounting_expense"]),
    );
  }
}

class CompensationSettlementModel {
  final int id;
  final String periodStart;
  final String periodEnd;
  final String? dueDate;
  final String status;
  final String currency;
  final double earningsTotal;
  final double deductionsTotal;
  final double reimbursementsTotal;
  final double netToPay;
  final double paidAmount;
  final double outstandingAmount;
  final double employerCost;
  final bool visibleToEmployee;
  final String? publishedAt;
  final String? paidAt;
  final List<CompensationSettlementLineModel> lines;
  final List<CompensationPayoutModel> payouts;

  const CompensationSettlementModel({
    required this.id,
    required this.periodStart,
    required this.periodEnd,
    required this.dueDate,
    required this.status,
    required this.currency,
    required this.earningsTotal,
    required this.deductionsTotal,
    required this.reimbursementsTotal,
    required this.netToPay,
    required this.paidAmount,
    required this.outstandingAmount,
    required this.employerCost,
    required this.visibleToEmployee,
    required this.publishedAt,
    required this.paidAt,
    required this.lines,
    required this.payouts,
  });

  factory CompensationSettlementModel.fromJson(Map<String, dynamic> json) {
    return CompensationSettlementModel(
      id: _asInt(json["id"]),
      periodStart: _asString(json["period_start"]),
      periodEnd: _asString(json["period_end"]),
      dueDate: _asNullableString(json["due_date"]),
      status: _asString(json["status"], fallback: "draft"),
      currency: _asString(json["currency"], fallback: "PLN"),
      earningsTotal: _asDouble(json["earnings_total"]),
      deductionsTotal: _asDouble(json["deductions_total"]),
      reimbursementsTotal: _asDouble(json["reimbursements_total"]),
      netToPay: _asDouble(json["net_to_pay"]),
      paidAmount: _asDouble(json["paid_amount"]),
      outstandingAmount: _asDouble(json["outstanding_amount"]),
      employerCost: _asDouble(json["employer_cost"]),
      visibleToEmployee: _asBool(json["visible_to_employee"]),
      publishedAt: _asNullableString(json["published_at"]),
      paidAt: _asNullableString(json["paid_at"]),
      lines: _asMapList(json["lines"])
          .map(CompensationSettlementLineModel.fromJson)
          .toList(),
      payouts: _asMapList(json["payouts"])
          .map(CompensationPayoutModel.fromJson)
          .toList(),
    );
  }
}

class EmployeeSettlementDashboardModel {
  final int employeeId;
  final String employeeName;
  final String employeeEmail;
  final String period;
  final String periodStart;
  final String periodEnd;
  final String currency;
  final EmployeeSettlementPermissionsModel permissions;
  final EmployeeSettlementSummaryModel summary;
  final CompensationAgreementModel? agreement;
  final CompensationSettlementModel? currentSettlement;
  final List<CompensationSettlementModel> history;
  final String? emptyStateCode;

  const EmployeeSettlementDashboardModel({
    required this.employeeId,
    required this.employeeName,
    required this.employeeEmail,
    required this.period,
    required this.periodStart,
    required this.periodEnd,
    required this.currency,
    required this.permissions,
    required this.summary,
    required this.agreement,
    required this.currentSettlement,
    required this.history,
    required this.emptyStateCode,
  });

  factory EmployeeSettlementDashboardModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final employee = _asMap(json["employee"]);
    final period = _asMap(json["period"]);
    final agreementJson = _asMapOrNull(json["agreement"]);
    final settlementJson = _asMapOrNull(json["current_settlement"]);

    return EmployeeSettlementDashboardModel(
      employeeId: _asInt(employee["id"]),
      employeeName: _asString(employee["name"], fallback: "Employee"),
      employeeEmail: _asString(employee["email"]),
      period: _asString(period["value"]),
      periodStart: _asString(period["start"]),
      periodEnd: _asString(period["end"]),
      currency: _asString(json["currency"], fallback: "PLN"),
      permissions: EmployeeSettlementPermissionsModel.fromJson(
        _asMap(json["permissions"]),
      ),
      summary: EmployeeSettlementSummaryModel.fromJson(
        _asMap(json["summary"]),
      ),
      agreement: agreementJson == null
          ? null
          : CompensationAgreementModel.fromJson(agreementJson),
      currentSettlement: settlementJson == null
          ? null
          : CompensationSettlementModel.fromJson(settlementJson),
      history: _asMapList(json["history"])
          .map(CompensationSettlementModel.fromJson)
          .toList(),
      emptyStateCode:
          _asNullableString(_asMap(json["empty_state"])["code"]),
    );
  }
}

class EmployeeSettlementDashboardNotifier
    extends StateNotifier<AsyncValue<EmployeeSettlementDashboardModel>> {
  final Ref ref;
  final EmployeeSettlementDashboardParams params;

  EmployeeSettlementDashboardNotifier(
    this.ref, {
    required this.params,
  }) : super(const AsyncValue.loading()) {
    Future.microtask(fetch);
  }

  Future<void> fetch({bool showLoading = true}) async {
    try {
      if (showLoading) state = const AsyncValue.loading();

      final response = await ApiServices.get(
        EmployeeCompensationUrls.dashboard,
        ref: ref,
        hasToken: true,
        queryParameters: params.toQueryParameters(),
      );

      if (response == null) {
        throw Exception(
          "Failed to fetch employee settlement dashboard",
        );
      }

      _ensureSuccess(
        response,
        "Failed to fetch employee settlement dashboard",
      );

      final responseData = response.data;

      state = AsyncValue.data(
        EmployeeSettlementDashboardModel.fromJson(
          _decodeResponse(responseData),
        ),
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  EmployeeSettlementDashboardModel? get _currentValue => state.asData?.value;

  Future<CompensationAgreementModel> saveAgreement(
    Map<String, dynamic> payload,
  ) async {
    final agreementId = _currentValue?.agreement?.id;
    final response = agreementId == null
        ? await ApiServices.post(
            EmployeeCompensationUrls.agreements,
            data: payload,
            ref: ref,
            hasToken: true,
          )
        : await ApiServices.patch(
            "${EmployeeCompensationUrls.agreements}$agreementId/",
            data: payload,
            ref: ref,
            hasToken: true,
          );

    if (response == null) {
      throw Exception(
        "Failed to save compensation agreement",
      );
    }

    _ensureSuccess(
      response,
      "Failed to save compensation agreement",
    );

    final savedAgreement = CompensationAgreementModel.fromJson(
      _decodeResponse(response.data),
    );

    await fetch(showLoading: false);
    return savedAgreement;
  }

  Future<void> saveRule(
    Map<String, dynamic> payload, {
    int? ruleId,
  }) async {
    final response = ruleId == null
        ? await ApiServices.post(
            EmployeeCompensationUrls.rules,
            data: payload,
            ref: ref,
            hasToken: true,
          )
        : await ApiServices.patch(
            "${EmployeeCompensationUrls.rules}$ruleId/",
            data: payload,
            ref: ref,
            hasToken: true,
          );
    _ensureSuccess(response, "Failed to save compensation rule");
    await fetch(showLoading: false);
  }

  Future<void> calculateSettlement() async {
    final agreement = _currentValue?.agreement;
    if (agreement == null) throw StateError("Agreement is required");

    final response = await ApiServices.post(
      "${EmployeeCompensationUrls.agreements}${agreement.id}/calculate/",
      data: {"period": params.period},
      ref: ref,
      hasToken: true,
    );
    _ensureSuccess(response, "Failed to calculate settlement");
    await fetch(showLoading: false);
  }

  Future<void> addManualLine(Map<String, dynamic> payload) async {
    final settlement = _currentValue?.currentSettlement;
    if (settlement == null) throw StateError("Settlement is required");

    final response = await ApiServices.post(
      "${EmployeeCompensationUrls.settlements}${settlement.id}/manual-line/",
      data: payload,
      ref: ref,
      hasToken: true,
    );
    _ensureSuccess(response, "Failed to add settlement line");
    await fetch(showLoading: false);
  }

  Future<void> publishSettlement() async {
    final settlement = _currentValue?.currentSettlement;
    if (settlement == null) throw StateError("Settlement is required");

    final response = await ApiServices.post(
      "${EmployeeCompensationUrls.settlements}${settlement.id}/publish/",
      data: const <String, dynamic>{},
      ref: ref,
      hasToken: true,
    );
    _ensureSuccess(response, "Failed to publish settlement");
    await fetch(showLoading: false);
  }

  Future<void> markAsPaid(Map<String, dynamic> payload) async {
    final settlement = _currentValue?.currentSettlement;
    if (settlement == null) throw StateError("Settlement is required");

    final response = await ApiServices.post(
      "${EmployeeCompensationUrls.settlements}${settlement.id}/mark-paid/",
      data: payload,
      ref: ref,
      hasToken: true,
    );
    _ensureSuccess(response, "Failed to register payment");
    await fetch(showLoading: false);
  }

  Future<void> acknowledgeSettlement() async {
    final settlement = _currentValue?.currentSettlement;
    if (settlement == null) return;

    final response = await ApiServices.post(
      "${EmployeeCompensationUrls.settlements}${settlement.id}/acknowledge/",
      data: const <String, dynamic>{},
      ref: ref,
      hasToken: true,
    );
    _ensureSuccess(response, "Failed to acknowledge settlement");
    await fetch(showLoading: false);
  }
}

final employeeSettlementDashboardProvider =
    StateNotifierProvider.autoDispose.family<
        EmployeeSettlementDashboardNotifier,
        AsyncValue<EmployeeSettlementDashboardModel>,
        EmployeeSettlementDashboardParams>(
  (ref, params) => EmployeeSettlementDashboardNotifier(
    ref,
    params: params,
  ),
);

Map<String, dynamic> _decodeResponse(dynamic data) {
  dynamic decoded = data;
  if (decoded is List<int>) decoded = jsonDecode(utf8.decode(decoded));
  if (decoded is String) decoded = jsonDecode(decoded);
  if (decoded is! Map) {
    throw Exception("Unexpected response format: ${decoded.runtimeType}");
  }
  return Map<String, dynamic>.from(decoded);
}

void _ensureSuccess(dynamic response, String message) {
  if (response == null ||
      response.statusCode == null ||
      response.statusCode < 200 ||
      response.statusCode >= 300) {
    throw Exception(message);
  }
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

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) {
    return double.tryParse(value.replaceAll(",", ".")) ?? 0;
  }
  return 0;
}

double? _asNullableDouble(dynamic value) {
  if (value == null || value.toString().trim().isEmpty) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString().replaceAll(",", "."));
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

int? _asNullableInt(dynamic value) {
  if (value == null || value.toString().trim().isEmpty) return null;
  final parsed = _asInt(value, fallback: -1);
  return parsed < 0 ? null : parsed;
}

String _asString(dynamic value, {String fallback = ""}) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? fallback : text;
}

String? _asNullableString(dynamic value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
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
