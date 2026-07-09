import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';

class EmployeeLeaveEntitlementUrls {
  static const String leavePolicies =
      'https://www.superbee.cloud/finance/compensation/leave-policies/';
  static const String leaveCashouts =
      'https://www.superbee.cloud/finance/compensation/leave-cashouts/';
  static const String leaveLedger =
      'https://www.superbee.cloud/finance/compensation/leave-ledger/';

  static String employeeLeaveDashboard(int employeeId) =>
      'https://www.superbee.cloud/finance/compensation/employees/$employeeId/leave-dashboard/';

  static String employeeLeaveBackfill(int employeeId) =>
      'https://www.superbee.cloud/finance/compensation/employees/$employeeId/leave-backfill/';

  static String cashoutApprove(int id) => '$leaveCashouts$id/approve/';
  static String cashoutCancel(int id) => '$leaveCashouts$id/cancel/';
}

class EmployeeLeaveDashboardParams {
  final int employeeId;
  final int year;

  const EmployeeLeaveDashboardParams({
    required this.employeeId,
    required this.year,
  });

  Map<String, String> toQueryParameters() => {
        'year': year.toString(),
      };

  @override
  bool operator ==(Object other) {
    return other is EmployeeLeaveDashboardParams &&
        other.employeeId == employeeId &&
        other.year == year;
  }

  @override
  int get hashCode => Object.hash(employeeId, year);
}

class EmployeeLeavePolicyModel {
  final int? id;
  final int? agreement;
  final String validFrom;
  final String? validTo;
  final String entitlementMode;
  final String statutoryCountry;
  final double seniorityYearsAtStart;
  final double educationYearsCredit;
  final double customEntitlementDays;
  final double fullTimeEquivalent;
  final double annualEntitlementDays;
  final String accrualMethod;
  final String cashoutPolicy;
  final String cashoutDailyRateMode;
  final double cashoutCustomDailyRate;
  final bool carryOverEnabled;
  final bool usePublicHolidays;

  const EmployeeLeavePolicyModel({
    required this.id,
    required this.agreement,
    required this.validFrom,
    required this.validTo,
    required this.entitlementMode,
    required this.statutoryCountry,
    required this.seniorityYearsAtStart,
    required this.educationYearsCredit,
    required this.customEntitlementDays,
    required this.fullTimeEquivalent,
    required this.annualEntitlementDays,
    required this.accrualMethod,
    required this.cashoutPolicy,
    required this.cashoutDailyRateMode,
    required this.cashoutCustomDailyRate,
    required this.carryOverEnabled,
    required this.usePublicHolidays,
  });

  factory EmployeeLeavePolicyModel.fromJson(Map<String, dynamic> json) {
    return EmployeeLeavePolicyModel(
      id: _asNullableInt(json['id']),
      agreement: _asNullableInt(json['agreement']),
      validFrom: _asString(json['valid_from']),
      validTo: _asNullableString(json['valid_to']),
      entitlementMode: _asString(json['entitlement_mode'], fallback: 'statutory_pl'),
      statutoryCountry: _asString(json['statutory_country'], fallback: 'PL'),
      seniorityYearsAtStart: _asDouble(json['seniority_years_at_start']),
      educationYearsCredit: _asDouble(json['education_years_credit']),
      customEntitlementDays: _asDouble(json['custom_entitlement_days']),
      fullTimeEquivalent: _asDouble(json['full_time_equivalent'], fallback: 1),
      annualEntitlementDays: _asDouble(json['annual_entitlement_days']),
      accrualMethod: _asString(json['accrual_method'], fallback: 'monthly_prorated'),
      cashoutPolicy: _asString(json['cashout_policy'], fallback: 'termination_only'),
      cashoutDailyRateMode: _asString(json['cashout_daily_rate_mode'], fallback: 'base_amount'),
      cashoutCustomDailyRate: _asDouble(json['cashout_custom_daily_rate']),
      carryOverEnabled: _asBool(json['carry_over_enabled'], fallback: true),
      usePublicHolidays: _asBool(json['use_public_holidays'], fallback: true),
    );
  }
}

class EmployeeLeaveBalanceExtendedModel {
  final int id;
  final int employee;
  final int absenceType;
  final String absenceTypeKey;
  final String absenceTypeName;
  final int year;
  final double limitDays;
  final double accruedDays;
  final double usedDays;
  final double pendingDays;
  final double carriedOverDays;
  final double manualAdjustmentDays;
  final double cashedOutDays;
  final double availableDays;
  final String note;

  const EmployeeLeaveBalanceExtendedModel({
    required this.id,
    required this.employee,
    required this.absenceType,
    required this.absenceTypeKey,
    required this.absenceTypeName,
    required this.year,
    required this.limitDays,
    required this.accruedDays,
    required this.usedDays,
    required this.pendingDays,
    required this.carriedOverDays,
    required this.manualAdjustmentDays,
    required this.cashedOutDays,
    required this.availableDays,
    required this.note,
  });

  factory EmployeeLeaveBalanceExtendedModel.fromJson(Map<String, dynamic> json) {
    return EmployeeLeaveBalanceExtendedModel(
      id: _asInt(json['id']),
      employee: _asInt(json['employee']),
      absenceType: _asInt(json['absence_type']),
      absenceTypeKey: _asString(json['absence_type_key']),
      absenceTypeName: _asString(json['absence_type_name']),
      year: _asInt(json['year']),
      limitDays: _asDouble(json['limit_days']),
      accruedDays: _asDouble(json['accrued_days'], fallback: _asDouble(json['limit_days'])),
      usedDays: _asDouble(json['used_days']),
      pendingDays: _asDouble(json['pending_days']),
      carriedOverDays: _asDouble(json['carried_over_days']),
      manualAdjustmentDays: _asDouble(json['manual_adjustment_days']),
      cashedOutDays: _asDouble(json['cashed_out_days']),
      availableDays: _asDouble(json['available_days']),
      note: _asString(json['note']),
    );
  }
}

class EmployeeLeaveCashoutModel {
  final int id;
  final int employee;
  final int? agreement;
  final int? policy;
  final int year;
  final double days;
  final double dailyRate;
  final double amount;
  final String currency;
  final String status;
  final String reason;
  final String? terminationDate;
  final int? compensationEvent;
  final DateTime? createdAt;

  const EmployeeLeaveCashoutModel({
    required this.id,
    required this.employee,
    required this.agreement,
    required this.policy,
    required this.year,
    required this.days,
    required this.dailyRate,
    required this.amount,
    required this.currency,
    required this.status,
    required this.reason,
    required this.terminationDate,
    required this.compensationEvent,
    required this.createdAt,
  });

  factory EmployeeLeaveCashoutModel.fromJson(Map<String, dynamic> json) {
    return EmployeeLeaveCashoutModel(
      id: _asInt(json['id']),
      employee: _asInt(json['employee']),
      agreement: _asNullableInt(json['agreement']),
      policy: _asNullableInt(json['policy']),
      year: _asInt(json['year']),
      days: _asDouble(json['days']),
      dailyRate: _asDouble(json['daily_rate']),
      amount: _asDouble(json['amount']),
      currency: _asString(json['currency'], fallback: 'PLN'),
      status: _asString(json['status'], fallback: 'draft'),
      reason: _asString(json['reason']),
      terminationDate: _asNullableString(json['termination_date']),
      compensationEvent: _asNullableInt(json['compensation_event']),
      createdAt: _asDate(json['created_at']),
    );
  }
}

class EmployeePublicHolidayModel {
  final String date;
  final String name;

  const EmployeePublicHolidayModel({required this.date, required this.name});

  factory EmployeePublicHolidayModel.fromJson(Map<String, dynamic> json) {
    return EmployeePublicHolidayModel(
      date: _asString(json['date']),
      name: _asString(json['name']),
    );
  }
}

class EmployeeLeaveDashboardModel {
  final int employeeId;
  final String employeeName;
  final int year;
  final EmployeeLeavePolicyModel? policy;
  final EmployeeLeaveBalanceExtendedModel balance;
  final List<EmployeeLeaveCashoutModel> cashouts;
  final List<EmployeePublicHolidayModel> holidays;

  const EmployeeLeaveDashboardModel({
    required this.employeeId,
    required this.employeeName,
    required this.year,
    required this.policy,
    required this.balance,
    required this.cashouts,
    required this.holidays,
  });

  factory EmployeeLeaveDashboardModel.fromJson(Map<String, dynamic> json) {
    return EmployeeLeaveDashboardModel(
      employeeId: _asInt(json['employee_id']),
      employeeName: _asString(json['employee_name']),
      year: _asInt(json['year']),
      policy: json['policy'] is Map
          ? EmployeeLeavePolicyModel.fromJson(Map<String, dynamic>.from(json['policy']))
          : null,
      balance: EmployeeLeaveBalanceExtendedModel.fromJson(_asMap(json['balance'])),
      cashouts: _asList(json['cashouts'])
          .whereType<Map>()
          .map((item) => EmployeeLeaveCashoutModel.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false),
      holidays: _asList(json['holidays'])
          .whereType<Map>()
          .map((item) => EmployeePublicHolidayModel.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false),
    );
  }
}

class EmployeeLeaveDashboardNotifier
    extends StateNotifier<AsyncValue<EmployeeLeaveDashboardModel>> {
  final Ref ref;
  final EmployeeLeaveDashboardParams params;

  EmployeeLeaveDashboardNotifier(this.ref, this.params)
      : super(const AsyncValue.loading()) {
    Future.microtask(fetch);
  }

  Future<void> fetch({bool showLoading = true}) async {
    try {
      if (showLoading) state = const AsyncValue.loading();
      final response = await ApiServices.get(
        EmployeeLeaveEntitlementUrls.employeeLeaveDashboard(params.employeeId),
        ref: ref,
        hasToken: true,
        queryParameters: params.toQueryParameters(),
      );
      _ensureSuccess(response, 'Failed to fetch leave dashboard');
      state = AsyncValue.data(
        EmployeeLeaveDashboardModel.fromJson(_decodeResponse(response?.data)),
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

class EmployeeLeaveActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  EmployeeLeaveActionsNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<void> backfill({
    required int employeeId,
    required int year,
    double? usedDays,
    double? carriedOverDays,
    double? manualAdjustmentDays,
    String note = '',
  }) async {
    state = const AsyncValue.loading();
    try {
      final response = await ApiServices.post(
        EmployeeLeaveEntitlementUrls.employeeLeaveBackfill(employeeId),
        ref: ref,
        hasToken: true,
        data: {
          'year': year,
          if (usedDays != null) 'used_days': usedDays,
          if (carriedOverDays != null) 'carried_over_days': carriedOverDays,
          if (manualAdjustmentDays != null) 'manual_adjustment_days': manualAdjustmentDays,
          'note': note,
        },
      );
      _ensureSuccess(response, 'Failed to backfill leave data');
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<EmployeeLeaveCashoutModel> createCashout({
    required int employeeId,
    int? agreementId,
    int? policyId,
    required int year,
    required double days,
    String? terminationDate,
    String reason = '',
    bool approveNow = false,
    bool overrideLegalWarning = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      final response = await ApiServices.post(
        EmployeeLeaveEntitlementUrls.leaveCashouts,
        ref: ref,
        hasToken: true,
        data: {
          'employee': employeeId,
          if (agreementId != null) 'agreement': agreementId,
          if (policyId != null) 'policy': policyId,
          'year': year,
          'days': days,
          if (terminationDate != null) 'termination_date': terminationDate,
          'reason': reason,
          'approve_now': approveNow,
          'override_legal_warning': overrideLegalWarning,
        },
      );
      _ensureSuccess(response, 'Failed to create leave cashout');
      final model = EmployeeLeaveCashoutModel.fromJson(_decodeResponse(response?.data));
      state = const AsyncValue.data(null);
      return model;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> approveCashout(int id) async {
    await _postAction(EmployeeLeaveEntitlementUrls.cashoutApprove(id));
  }

  Future<void> cancelCashout(int id) async {
    await _postAction(EmployeeLeaveEntitlementUrls.cashoutCancel(id));
  }

  Future<void> _postAction(String url) async {
    state = const AsyncValue.loading();
    try {
      final response = await ApiServices.post(
        url,
        ref: ref,
        hasToken: true,
        data: const {},
      );
      _ensureSuccess(response, 'Failed to update leave cashout');
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}

final employeeLeaveDashboardProvider = StateNotifierProvider.family<
    EmployeeLeaveDashboardNotifier,
    AsyncValue<EmployeeLeaveDashboardModel>,
    EmployeeLeaveDashboardParams>(
  (ref, params) => EmployeeLeaveDashboardNotifier(ref, params),
);

final employeeLeaveActionsProvider =
    StateNotifierProvider<EmployeeLeaveActionsNotifier, AsyncValue<void>>(
  (ref) => EmployeeLeaveActionsNotifier(ref),
);

Map<String, dynamic> _decodeResponse(dynamic data) {
  dynamic decoded = data;
  if (decoded is List<int>) decoded = jsonDecode(utf8.decode(decoded));
  if (decoded is String && decoded.isNotEmpty) decoded = jsonDecode(decoded);
  if (decoded is Map && decoded['data'] is Map) decoded = decoded['data'];
  if (decoded is Map) return Map<String, dynamic>.from(decoded);
  return <String, dynamic>{};
}

void _ensureSuccess(dynamic response, String message) {
  final code = response?.statusCode ?? 0;
  if (code < 200 || code >= 300) {
    throw Exception('$message. Status code: $code');
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

List<dynamic> _asList(dynamic value) {
  if (value is List) return value;
  return const [];
}

String _asString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  final text = value.toString();
  return text.isEmpty ? fallback : text;
}

String? _asNullableString(dynamic value) {
  if (value == null) return null;
  final text = value.toString();
  return text.isEmpty ? null : text;
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

int? _asNullableInt(dynamic value) {
  if (value == null || value.toString().isEmpty) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double _asDouble(dynamic value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

bool _asBool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value?.toString().toLowerCase();
  if (text == 'true' || text == '1' || text == 'yes') return true;
  if (text == 'false' || text == '0' || text == 'no') return false;
  return fallback;
}

DateTime? _asDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
