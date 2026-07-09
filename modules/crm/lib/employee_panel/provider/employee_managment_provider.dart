// crm/employee_panel/provider/employee_managment_provider.dart

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';

class EmployeeManagementUrls {
  static const String dashboard =
      'https://www.superbee.cloud/finance/compensation/employee-management-dashboard/';

  static const String absenceTypes =
      'https://www.superbee.cloud/finance/compensation/absence-types/';

  static const String absences =
      'https://www.superbee.cloud/finance/compensation/absences/';

  static const String leaveBalances =
      'https://www.superbee.cloud/finance/compensation/leave-balances/';

  static const String availability =
      'https://www.superbee.cloud/finance/compensation/absences/availability/';

  static String employeeAbsenceDashboard(int employeeId) {
    return 'https://www.superbee.cloud/finance/compensation/employees/$employeeId/absence-dashboard/';
  }

  static String absenceApprove(int id) => '$absences$id/approve/';
  static String absenceReject(int id) => '$absences$id/reject/';
  static String absenceCancel(int id) => '$absences$id/cancel/';
}

class EmployeeManagementDashboardParams {
  final String period;
  final String currency;

  const EmployeeManagementDashboardParams({
    required this.period,
    this.currency = 'PLN',
  });

  Map<String, String> toQueryParameters() => {
        'period': period,
        'currency': currency,
      };

  @override
  bool operator ==(Object other) {
    return other is EmployeeManagementDashboardParams &&
        other.period == period &&
        other.currency == currency;
  }

  @override
  int get hashCode => Object.hash(period, currency);
}

class EmployeeAvailabilityParams {
  final String start;
  final String end;
  final int? employeeId;
  final bool includePending;

  const EmployeeAvailabilityParams({
    required this.start,
    required this.end,
    this.employeeId,
    this.includePending = true,
  });

  Map<String, String> toQueryParameters() => {
        'start': start,
        'end': end,
        'include_pending': includePending ? 'true' : 'false',
        if (employeeId != null) 'employee_id': employeeId.toString(),
      };

  @override
  bool operator ==(Object other) {
    return other is EmployeeAvailabilityParams &&
        other.start == start &&
        other.end == end &&
        other.employeeId == employeeId &&
        other.includePending == includePending;
  }

  @override
  int get hashCode => Object.hash(start, end, employeeId, includePending);
}

class EmployeeAbsenceDashboardParams {
  final int employeeId;
  final int year;

  const EmployeeAbsenceDashboardParams({
    required this.employeeId,
    required this.year,
  });

  Map<String, String> toQueryParameters() => {
        'year': year.toString(),
      };

  @override
  bool operator ==(Object other) {
    return other is EmployeeAbsenceDashboardParams &&
        other.employeeId == employeeId &&
        other.year == year;
  }

  @override
  int get hashCode => Object.hash(employeeId, year);
}

class EmployeeManagementCompanyModel {
  final int id;
  final String name;

  const EmployeeManagementCompanyModel({
    required this.id,
    required this.name,
  });

  factory EmployeeManagementCompanyModel.fromJson(Map<String, dynamic> json) {
    return EmployeeManagementCompanyModel(
      id: _asInt(json['id']),
      name: _asString(json['name']),
    );
  }
}

class EmployeeManagementOptionModel {
  final String value;
  final String label;

  const EmployeeManagementOptionModel({
    required this.value,
    required this.label,
  });

  factory EmployeeManagementOptionModel.fromJson(Map<String, dynamic> json) {
    return EmployeeManagementOptionModel(
      value: _asString(json['value']),
      label: _asString(json['label']),
    );
  }
}

class EmployeeManagementSummaryModel {
  final int employeesCount;
  final int activeCount;
  final int inactiveCount;
  final int managerCount;
  final int withAgreementCount;
  final int withoutAgreementCount;
  final int settlementsCount;
  final int pendingEventsCount;
  final double netToPay;
  final double paidAmount;
  final double outstandingAmount;
  final double employerCost;

  /// HR / absences.
  final int onLeaveTodayCount;
  final int pendingAbsencesCount;
  final double sickLeaveMonthDays;

  /// HR / availability and working hours.
  final int availableTodayCount;
  final int unavailableTodayCount;
  final int bookableEmployeesTodayCount;
  final int outsideAvailabilityTodayCount;
  final int bookableTodayCount;
  final int blockingTodayCount;

  const EmployeeManagementSummaryModel({
    required this.employeesCount,
    required this.activeCount,
    required this.inactiveCount,
    required this.managerCount,
    required this.withAgreementCount,
    required this.withoutAgreementCount,
    required this.settlementsCount,
    required this.pendingEventsCount,
    required this.netToPay,
    required this.paidAmount,
    required this.outstandingAmount,
    required this.employerCost,
    required this.onLeaveTodayCount,
    required this.pendingAbsencesCount,
    required this.sickLeaveMonthDays,
    required this.availableTodayCount,
    required this.unavailableTodayCount,
    required this.bookableEmployeesTodayCount,
    required this.outsideAvailabilityTodayCount,
    required this.bookableTodayCount,
    required this.blockingTodayCount,
  });

  factory EmployeeManagementSummaryModel.fromJson(Map<String, dynamic> json) {
    return EmployeeManagementSummaryModel(
      employeesCount: _asInt(json['employees_count']),
      activeCount: _asInt(json['active_count']),
      inactiveCount: _asInt(json['inactive_count']),
      managerCount: _asInt(json['manager_count']),
      withAgreementCount: _asInt(json['with_agreement_count']),
      withoutAgreementCount: _asInt(json['without_agreement_count']),
      settlementsCount: _asInt(json['settlements_count']),
      pendingEventsCount: _asInt(json['pending_events_count']),
      netToPay: _asDouble(json['net_to_pay']),
      paidAmount: _asDouble(json['paid_amount']),
      outstandingAmount: _asDouble(json['outstanding_amount']),
      employerCost: _asDouble(json['employer_cost']),
      onLeaveTodayCount: _asInt(json['on_leave_today_count']),
      pendingAbsencesCount: _asInt(json['pending_absences_count']),
      sickLeaveMonthDays: _asDouble(json['sick_leave_month_days']),
      availableTodayCount: _asInt(json['available_today_count']),
      unavailableTodayCount: _asInt(json['unavailable_today_count']),
      bookableEmployeesTodayCount: _asInt(json['bookable_employees_today_count']),
      outsideAvailabilityTodayCount: _asInt(json['outside_availability_today_count']),
      bookableTodayCount: _asInt(json['bookable_today_count']),
      blockingTodayCount: _asInt(json['blocking_today_count']),
    );
  }
}
class EmployeeManagementUserModel {
  final int id;
  final String username;
  final String firstName;
  final String lastName;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String? avatar;
  final bool isActive;

  const EmployeeManagementUserModel({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.avatar,
    required this.isActive,
  });

  factory EmployeeManagementUserModel.fromJson(Map<String, dynamic> json) {
    return EmployeeManagementUserModel(
      id: _asInt(json['id']),
      username: _asString(json['username']),
      firstName: _asString(json['first_name']),
      lastName: _asString(json['last_name']),
      fullName: _asString(json['full_name']),
      email: _asString(json['email']),
      phoneNumber: _asString(json['phone_number']),
      avatar: _asNullableString(json['avatar']),
      isActive: _asBool(json['is_active'], fallback: true),
    );
  }
}

class EmployeeManagementMembershipModel {
  final int? id;
  final String role;
  final String status;
  final String? country;
  final DateTime? joinedAt;
  final bool isOwner;

  const EmployeeManagementMembershipModel({
    required this.id,
    required this.role,
    required this.status,
    required this.country,
    required this.joinedAt,
    required this.isOwner,
  });

  factory EmployeeManagementMembershipModel.fromJson(Map<String, dynamic> json) {
    return EmployeeManagementMembershipModel(
      id: _asNullableInt(json['id']),
      role: _asString(json['role'], fallback: 'employee'),
      status: _asString(json['status'], fallback: 'active'),
      country: _asNullableString(json['country']),
      joinedAt: _asDate(json['joined_at']),
      isOwner: _asBool(json['is_owner']),
    );
  }
}

class EmployeeManagementAgreementModel {
  final int id;
  final String title;
  final String relationshipType;
  final String compensationMode;
  final String payFrequency;
  final String status;
  final String currency;
  final String validFrom;
  final String? validTo;
  final double baseAmount;
  final double hourlyRate;
  final bool employeeCanViewRules;
  final bool employeeCanViewSources;
  final int documentsCount;

  const EmployeeManagementAgreementModel({
    required this.id,
    required this.title,
    required this.relationshipType,
    required this.compensationMode,
    required this.payFrequency,
    required this.status,
    required this.currency,
    required this.validFrom,
    required this.validTo,
    required this.baseAmount,
    required this.hourlyRate,
    required this.employeeCanViewRules,
    required this.employeeCanViewSources,
    required this.documentsCount,
  });

  factory EmployeeManagementAgreementModel.fromJson(Map<String, dynamic> json) {
    return EmployeeManagementAgreementModel(
      id: _asInt(json['id']),
      title: _asString(json['title']),
      relationshipType: _asString(json['relationship_type']),
      compensationMode: _asString(json['compensation_mode']),
      payFrequency: _asString(json['pay_frequency']),
      status: _asString(json['status']),
      currency: _asString(json['currency'], fallback: 'PLN'),
      validFrom: _asString(json['valid_from']),
      validTo: _asNullableString(json['valid_to']),
      baseAmount: _asDouble(json['base_amount']),
      hourlyRate: _asDouble(json['hourly_rate']),
      employeeCanViewRules: _asBool(json['employee_can_view_rules'], fallback: true),
      employeeCanViewSources: _asBool(json['employee_can_view_sources'], fallback: true),
      documentsCount: _asInt(json['documents_count']),
    );
  }
}

class EmployeeManagementSettlementModel {
  final int id;
  final String status;
  final String periodStart;
  final String periodEnd;
  final String currency;
  final double earningsTotal;
  final double deductionsTotal;
  final double reimbursementsTotal;
  final double netToPay;
  final double paidAmount;
  final double outstandingAmount;
  final double employerCost;
  final String? dueDate;
  final DateTime? paidAt;
  final bool visibleToEmployee;
  final DateTime? employeeAcknowledgedAt;
  final int linesCount;

  const EmployeeManagementSettlementModel({
    required this.id,
    required this.status,
    required this.periodStart,
    required this.periodEnd,
    required this.currency,
    required this.earningsTotal,
    required this.deductionsTotal,
    required this.reimbursementsTotal,
    required this.netToPay,
    required this.paidAmount,
    required this.outstandingAmount,
    required this.employerCost,
    required this.dueDate,
    required this.paidAt,
    required this.visibleToEmployee,
    required this.employeeAcknowledgedAt,
    required this.linesCount,
  });

  factory EmployeeManagementSettlementModel.fromJson(Map<String, dynamic> json) {
    return EmployeeManagementSettlementModel(
      id: _asInt(json['id']),
      status: _asString(json['status']),
      periodStart: _asString(json['period_start']),
      periodEnd: _asString(json['period_end']),
      currency: _asString(json['currency'], fallback: 'PLN'),
      earningsTotal: _asDouble(json['earnings_total']),
      deductionsTotal: _asDouble(json['deductions_total']),
      reimbursementsTotal: _asDouble(json['reimbursements_total']),
      netToPay: _asDouble(json['net_to_pay']),
      paidAmount: _asDouble(json['paid_amount']),
      outstandingAmount: _asDouble(json['outstanding_amount']),
      employerCost: _asDouble(json['employer_cost']),
      dueDate: _asNullableString(json['due_date']),
      paidAt: _asDate(json['paid_at']),
      visibleToEmployee: _asBool(json['visible_to_employee']),
      employeeAcknowledgedAt: _asDate(json['employee_acknowledged_at']),
      linesCount: _asInt(json['lines_count']),
    );
  }
}

class EmployeeManagementActiveAbsenceModel {
  final int id;
  final String absenceTypeKey;
  final String absenceTypeName;
  final String availabilityKind;
  final String calendarColor;
  final String startDate;
  final String endDate;
  final String status;

  const EmployeeManagementActiveAbsenceModel({
    required this.id,
    required this.absenceTypeKey,
    required this.absenceTypeName,
    required this.availabilityKind,
    required this.calendarColor,
    required this.startDate,
    required this.endDate,
    required this.status,
  });

  factory EmployeeManagementActiveAbsenceModel.fromJson(Map<String, dynamic> json) {
    return EmployeeManagementActiveAbsenceModel(
      id: _asInt(json['id']),
      absenceTypeKey: _asString(json['absence_type_key']),
      absenceTypeName: _asString(json['absence_type_name']),
      availabilityKind: _asString(json['availability_kind']),
      calendarColor: _asString(json['calendar_color'], fallback: '#F59E0B'),
      startDate: _asString(json['start_date']),
      endDate: _asString(json['end_date']),
      status: _asString(json['status']),
    );
  }
}

class EmployeeManagementAnnualLeaveModel {
  final double limitDays;
  final double usedDays;
  final double pendingDays;
  final double availableDays;
  final double carriedOverDays;

  const EmployeeManagementAnnualLeaveModel({
    required this.limitDays,
    required this.usedDays,
    required this.pendingDays,
    required this.availableDays,
    required this.carriedOverDays,
  });

  factory EmployeeManagementAnnualLeaveModel.fromJson(Map<String, dynamic> json) {
    return EmployeeManagementAnnualLeaveModel(
      limitDays: _asDouble(json['limit_days']),
      usedDays: _asDouble(json['used_days']),
      pendingDays: _asDouble(json['pending_days']),
      availableDays: _asDouble(json['available_days']),
      carriedOverDays: _asDouble(json['carried_over_days']),
    );
  }
}

class EmployeeManagementAbsenceSummaryModel {
  final String todayStatus;
  final EmployeeManagementActiveAbsenceModel? activeAbsence;
  final double currentMonthAbsenceDays;
  final double currentMonthSickLeaveDays;
  final int pendingRequestsCount;
  final int upcomingAbsencesCount;
  final EmployeeManagementAnnualLeaveModel annualLeave;

  const EmployeeManagementAbsenceSummaryModel({
    required this.todayStatus,
    required this.activeAbsence,
    required this.currentMonthAbsenceDays,
    required this.currentMonthSickLeaveDays,
    required this.pendingRequestsCount,
    required this.upcomingAbsencesCount,
    required this.annualLeave,
  });

  factory EmployeeManagementAbsenceSummaryModel.empty() {
    return EmployeeManagementAbsenceSummaryModel(
      todayStatus: 'available',
      activeAbsence: null,
      currentMonthAbsenceDays: 0,
      currentMonthSickLeaveDays: 0,
      pendingRequestsCount: 0,
      upcomingAbsencesCount: 0,
      annualLeave: EmployeeManagementAnnualLeaveModel.fromJson(const {}),
    );
  }

  factory EmployeeManagementAbsenceSummaryModel.fromJson(Map<String, dynamic> json) {
    final active = json['active_absence'];
    return EmployeeManagementAbsenceSummaryModel(
      todayStatus: _asString(json['today_status'], fallback: 'available'),
      activeAbsence: active is Map
          ? EmployeeManagementActiveAbsenceModel.fromJson(Map<String, dynamic>.from(active))
          : null,
      currentMonthAbsenceDays: _asDouble(json['current_month_absence_days']),
      currentMonthSickLeaveDays: _asDouble(json['current_month_sick_leave_days']),
      pendingRequestsCount: _asInt(json['pending_requests_count']),
      upcomingAbsencesCount: _asInt(json['upcoming_absences_count']),
      annualLeave: EmployeeManagementAnnualLeaveModel.fromJson(
        _asMap(json['annual_leave']),
      ),
    );
  }

  bool get isAvailableToday => todayStatus == 'available' || activeAbsence == null;
}

class EmployeeManagementAvailabilitySummaryBlockModel {
  final String id;
  final String title;
  final String kind;
  final String source;
  final int? sourceId;
  final String color;
  final bool isBookable;
  final bool blocksBooking;
  final int priority;
  final String status;
  final String tooltip;
  final DateTime? startAt;
  final DateTime? endAt;
  final Map<String, dynamic> metadata;

  const EmployeeManagementAvailabilitySummaryBlockModel({
    required this.id,
    required this.title,
    required this.kind,
    required this.source,
    required this.sourceId,
    required this.color,
    required this.isBookable,
    required this.blocksBooking,
    required this.priority,
    required this.status,
    required this.tooltip,
    required this.startAt,
    required this.endAt,
    required this.metadata,
  });

  factory EmployeeManagementAvailabilitySummaryBlockModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return EmployeeManagementAvailabilitySummaryBlockModel(
      id: _asString(json['id'], fallback: _asString(json['source_id'])),
      title: _asString(json['title'], fallback: _asString(json['label'])),
      kind: _asString(json['kind'], fallback: _asString(json['availability_kind'])),
      source: _asString(json['source']),
      sourceId: _asNullableInt(json['source_id']),
      color: _asString(json['color'], fallback: '#64748B'),
      isBookable: _asBool(json['is_bookable']),
      blocksBooking: _asBool(json['blocks_booking']),
      priority: _asInt(json['priority']),
      status: _asString(json['status']),
      tooltip: _asString(json['tooltip']),
      startAt: _asDate(json['start_at']),
      endAt: _asDate(json['end_at']),
      metadata: Map<String, dynamic>.from(
        json['metadata'] is Map ? json['metadata'] : const {},
      ),
    );
  }
}

class EmployeeManagementAvailabilitySummaryModel {
  final String todayStatusKey;
  final String todayStatusLabel;
  final String todayStatusColor;
  final bool blocksBooking;
  final String workMode;
  final String timezone;
  final bool allowEveningAppointments;
  final bool allowWeekendAppointments;
  final bool isTimeTrackingEnabled;
  final List<EmployeeManagementAvailabilitySummaryBlockModel> bookableToday;
  final List<EmployeeManagementAvailabilitySummaryBlockModel> blockingToday;

  const EmployeeManagementAvailabilitySummaryModel({
    required this.todayStatusKey,
    required this.todayStatusLabel,
    required this.todayStatusColor,
    required this.blocksBooking,
    required this.workMode,
    required this.timezone,
    required this.allowEveningAppointments,
    required this.allowWeekendAppointments,
    required this.isTimeTrackingEnabled,
    required this.bookableToday,
    required this.blockingToday,
  });

  factory EmployeeManagementAvailabilitySummaryModel.empty() {
    return const EmployeeManagementAvailabilitySummaryModel(
      todayStatusKey: 'outside_availability',
      todayStatusLabel: 'Poza standardową dostępnością',
      todayStatusColor: '#64748B',
      blocksBooking: false,
      workMode: 'appointment_based',
      timezone: 'Europe/Warsaw',
      allowEveningAppointments: true,
      allowWeekendAppointments: true,
      isTimeTrackingEnabled: false,
      bookableToday: [],
      blockingToday: [],
    );
  }

  factory EmployeeManagementAvailabilitySummaryModel.fromJson(
    Map<String, dynamic> json,
  ) {
    if (json.isEmpty) {
      return EmployeeManagementAvailabilitySummaryModel.empty();
    }

    return EmployeeManagementAvailabilitySummaryModel(
      todayStatusKey: _asString(
        json['today_status_key'],
        fallback: 'outside_availability',
      ),
      todayStatusLabel: _asString(
        json['today_status_label'],
        fallback: 'Poza standardową dostępnością',
      ),
      todayStatusColor: _asString(
        json['today_status_color'],
        fallback: '#64748B',
      ),
      blocksBooking: _asBool(json['blocks_booking']),
      workMode: _asString(
        json['work_mode'],
        fallback: 'appointment_based',
      ),
      timezone: _asString(
        json['timezone'],
        fallback: 'Europe/Warsaw',
      ),
      allowEveningAppointments: _asBool(
        json['allow_evening_appointments'],
        fallback: true,
      ),
      allowWeekendAppointments: _asBool(
        json['allow_weekend_appointments'],
        fallback: true,
      ),
      isTimeTrackingEnabled: _asBool(json['is_time_tracking_enabled']),
      bookableToday: _decodeAvailabilitySummaryBlocks(json['bookable_today']),
      blockingToday: _decodeAvailabilitySummaryBlocks(json['blocking_today']),
    );
  }

  bool get isAvailableToday => !blocksBooking;
  bool get hasBookableToday => bookableToday.isNotEmpty;
  bool get hasBlockingToday => blockingToday.isNotEmpty;
}

class EmployeeManagementEmployeeModel {
  final EmployeeManagementUserModel user;
  final EmployeeManagementMembershipModel membership;
  final EmployeeManagementAgreementModel? agreement;
  final EmployeeManagementSettlementModel? settlement;
  final EmployeeManagementAbsenceSummaryModel absenceSummary;
  final EmployeeManagementAvailabilitySummaryModel availabilitySummary;
  final int pendingEventsCount;
  final int documentsCount;
  final String quickStatus;

  const EmployeeManagementEmployeeModel({
    required this.user,
    required this.membership,
    required this.agreement,
    required this.settlement,
    required this.absenceSummary,
    required this.availabilitySummary,
    required this.pendingEventsCount,
    required this.documentsCount,
    required this.quickStatus,
  });

  bool get isActive => membership.status == 'active' && user.isActive;
  bool get hasAgreement => agreement != null;
  bool get hasUnpaidSettlement => (settlement?.outstandingAmount ?? 0) > 0;
  bool get hasPendingEvents => pendingEventsCount > 0;
  bool get isOnLeaveToday => !absenceSummary.isAvailableToday;
  bool get hasPendingAbsences => absenceSummary.pendingRequestsCount > 0;
  bool get isBlockedByAvailability => availabilitySummary.blocksBooking;
  bool get hasBookableAvailabilityToday => availabilitySummary.hasBookableToday;
  String get displayName => user.fullName.isNotEmpty ? user.fullName : user.email;

  factory EmployeeManagementEmployeeModel.fromJson(Map<String, dynamic> json) {
    final agreement = json['agreement'];
    final settlement = json['settlement'];

    return EmployeeManagementEmployeeModel(
      user: EmployeeManagementUserModel.fromJson(_asMap(json['user'])),
      membership: EmployeeManagementMembershipModel.fromJson(_asMap(json['membership'])),
      agreement: agreement is Map
          ? EmployeeManagementAgreementModel.fromJson(Map<String, dynamic>.from(agreement))
          : null,
      settlement: settlement is Map
          ? EmployeeManagementSettlementModel.fromJson(Map<String, dynamic>.from(settlement))
          : null,
      absenceSummary: EmployeeManagementAbsenceSummaryModel.fromJson(
        _asMap(json['absence_summary']),
      ),
      availabilitySummary: EmployeeManagementAvailabilitySummaryModel.fromJson(
        _asMap(json['availability_summary']),
      ),
      pendingEventsCount: _asInt(json['pending_events_count']),
      documentsCount: _asInt(json['documents_count']),
      quickStatus: _asString(json['quick_status'], fallback: 'ok'),
    );
  }
}
class EmployeeManagementDashboardModel {
  final EmployeeManagementCompanyModel company;
  final String period;
  final String periodStart;
  final String periodEnd;
  final String currency;
  final EmployeeManagementSummaryModel summary;
  final List<EmployeeManagementOptionModel> roleOptions;
  final List<EmployeeManagementOptionModel> statusOptions;
  final List<EmployeeManagementEmployeeModel> employees;

  const EmployeeManagementDashboardModel({
    required this.company,
    required this.period,
    required this.periodStart,
    required this.periodEnd,
    required this.currency,
    required this.summary,
    required this.roleOptions,
    required this.statusOptions,
    required this.employees,
  });

  factory EmployeeManagementDashboardModel.fromJson(Map<String, dynamic> json) {
    return EmployeeManagementDashboardModel(
      company: EmployeeManagementCompanyModel.fromJson(_asMap(json['company'])),
      period: _asString(json['period']),
      periodStart: _asString(json['period_start']),
      periodEnd: _asString(json['period_end']),
      currency: _asString(json['currency'], fallback: 'PLN'),
      summary: EmployeeManagementSummaryModel.fromJson(_asMap(json['summary'])),
      roleOptions: _asList(json['role_options'])
          .whereType<Map>()
          .map((item) => EmployeeManagementOptionModel.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      statusOptions: _asList(json['status_options'])
          .whereType<Map>()
          .map((item) => EmployeeManagementOptionModel.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      employees: _asList(json['employees'])
          .whereType<Map>()
          .map((item) => EmployeeManagementEmployeeModel.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}

class EmployeeAbsenceTypeModel {
  final int id;
  final String key;
  final String name;
  final String availabilityKind;
  final String calendarColor;
  final bool isPaid;
  final bool requiresApproval;
  final bool requiresDocument;
  final bool affectsSettlement;
  final bool blocksAvailability;
  final bool reducesLeaveBalance;
  final double settlementMultiplier;

  const EmployeeAbsenceTypeModel({
    required this.id,
    required this.key,
    required this.name,
    required this.availabilityKind,
    required this.calendarColor,
    required this.isPaid,
    required this.requiresApproval,
    required this.requiresDocument,
    required this.affectsSettlement,
    required this.blocksAvailability,
    required this.reducesLeaveBalance,
    required this.settlementMultiplier,
  });

  factory EmployeeAbsenceTypeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeAbsenceTypeModel(
      id: _asInt(json['id']),
      key: _asString(json['key']),
      name: _asString(json['name']),
      availabilityKind: _asString(json['availability_kind']),
      calendarColor: _asString(json['calendar_color'], fallback: '#F59E0B'),
      isPaid: _asBool(json['is_paid']),
      requiresApproval: _asBool(json['requires_approval'], fallback: true),
      requiresDocument: _asBool(json['requires_document']),
      affectsSettlement: _asBool(json['affects_settlement'], fallback: true),
      blocksAvailability: _asBool(json['blocks_availability'], fallback: true),
      reducesLeaveBalance: _asBool(json['reduces_leave_balance'], fallback: true),
      settlementMultiplier: _asDouble(json['settlement_multiplier'], fallback: 1),
    );
  }
}

class EmployeeAbsenceModel {
  final int id;
  final int employee;
  final String employeeName;
  final String employeeEmail;
  final int absenceType;
  final String absenceTypeKey;
  final String absenceTypeName;
  final String availabilityKind;
  final String calendarColor;
  final String startDate;
  final String endDate;
  final double daysCount;
  final String halfDayMode;
  final String status;
  final String reason;
  final String managerNote;
  final String? attachmentUrl;
  final bool blocksAvailability;

  const EmployeeAbsenceModel({
    required this.id,
    required this.employee,
    required this.employeeName,
    required this.employeeEmail,
    required this.absenceType,
    required this.absenceTypeKey,
    required this.absenceTypeName,
    required this.availabilityKind,
    required this.calendarColor,
    required this.startDate,
    required this.endDate,
    required this.daysCount,
    required this.halfDayMode,
    required this.status,
    required this.reason,
    required this.managerNote,
    required this.attachmentUrl,
    required this.blocksAvailability,
  });

  factory EmployeeAbsenceModel.fromJson(Map<String, dynamic> json) {
    return EmployeeAbsenceModel(
      id: _asInt(json['id']),
      employee: _asInt(json['employee']),
      employeeName: _asString(json['employee_name']),
      employeeEmail: _asString(json['employee_email']),
      absenceType: _asInt(json['absence_type']),
      absenceTypeKey: _asString(json['absence_type_key']),
      absenceTypeName: _asString(json['absence_type_name']),
      availabilityKind: _asString(json['availability_kind']),
      calendarColor: _asString(json['calendar_color'], fallback: '#F59E0B'),
      startDate: _asString(json['start_date']),
      endDate: _asString(json['end_date']),
      daysCount: _asDouble(json['days_count']),
      halfDayMode: _asString(json['half_day_mode'], fallback: 'none'),
      status: _asString(json['status'], fallback: 'pending'),
      reason: _asString(json['reason']),
      managerNote: _asString(json['manager_note']),
      attachmentUrl: _asNullableString(json['attachment_url']),
      blocksAvailability: _asBool(json['blocks_availability']),
    );
  }
}

class EmployeeLeaveBalanceModel {
  final int id;
  final int employee;
  final int absenceType;
  final String absenceTypeKey;
  final String absenceTypeName;
  final int year;
  final double limitDays;
  final double usedDays;
  final double pendingDays;
  final double carriedOverDays;
  final double manualAdjustmentDays;
  final double availableDays;

  const EmployeeLeaveBalanceModel({
    required this.id,
    required this.employee,
    required this.absenceType,
    required this.absenceTypeKey,
    required this.absenceTypeName,
    required this.year,
    required this.limitDays,
    required this.usedDays,
    required this.pendingDays,
    required this.carriedOverDays,
    required this.manualAdjustmentDays,
    required this.availableDays,
  });

  factory EmployeeLeaveBalanceModel.fromJson(Map<String, dynamic> json) {
    return EmployeeLeaveBalanceModel(
      id: _asInt(json['id']),
      employee: _asInt(json['employee']),
      absenceType: _asInt(json['absence_type']),
      absenceTypeKey: _asString(json['absence_type_key']),
      absenceTypeName: _asString(json['absence_type_name']),
      year: _asInt(json['year']),
      limitDays: _asDouble(json['limit_days']),
      usedDays: _asDouble(json['used_days']),
      pendingDays: _asDouble(json['pending_days']),
      carriedOverDays: _asDouble(json['carried_over_days']),
      manualAdjustmentDays: _asDouble(json['manual_adjustment_days']),
      availableDays: _asDouble(json['available_days']),
    );
  }
}

class EmployeeAbsenceDashboardModel {
  final int employeeId;
  final int year;
  final EmployeeManagementActiveAbsenceModel? todayStatus;
  final int pendingRequestsCount;
  final double sickLeaveDaysYear;
  final List<EmployeeLeaveBalanceModel> balances;
  final List<EmployeeAbsenceModel> upcoming;

  const EmployeeAbsenceDashboardModel({
    required this.employeeId,
    required this.year,
    required this.todayStatus,
    required this.pendingRequestsCount,
    required this.sickLeaveDaysYear,
    required this.balances,
    required this.upcoming,
  });

  factory EmployeeAbsenceDashboardModel.fromJson(Map<String, dynamic> json) {
    final today = json['today_status'];
    final summary = _asMap(json['summary']);
    return EmployeeAbsenceDashboardModel(
      employeeId: _asInt(json['employee_id']),
      year: _asInt(json['year']),
      todayStatus: today is Map
          ? EmployeeManagementActiveAbsenceModel.fromJson(Map<String, dynamic>.from(today))
          : null,
      pendingRequestsCount: _asInt(summary['pending_requests_count']),
      sickLeaveDaysYear: _asDouble(summary['sick_leave_days_year']),
      balances: _asList(json['balances'])
          .whereType<Map>()
          .map((item) => EmployeeLeaveBalanceModel.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      upcoming: _asList(json['upcoming'])
          .whereType<Map>()
          .map((item) => EmployeeAbsenceModel.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}

class EmployeeAvailabilityEventModel {
  final int id;
  final String source;
  final int employeeId;
  final String employeeName;
  final String employeeEmail;
  final String title;
  final String startDate;
  final String endDate;
  final bool allDay;
  final String status;
  final String absenceTypeKey;
  final String absenceTypeName;
  final String availabilityKind;
  final bool blocksAvailability;
  final String calendarColor;
  final bool isPending;
  final String tooltip;

  const EmployeeAvailabilityEventModel({
    required this.id,
    required this.source,
    required this.employeeId,
    required this.employeeName,
    required this.employeeEmail,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.allDay,
    required this.status,
    required this.absenceTypeKey,
    required this.absenceTypeName,
    required this.availabilityKind,
    required this.blocksAvailability,
    required this.calendarColor,
    required this.isPending,
    required this.tooltip,
  });

  factory EmployeeAvailabilityEventModel.fromJson(Map<String, dynamic> json) {
    return EmployeeAvailabilityEventModel(
      id: _asInt(json['id']),
      source: _asString(json['source']),
      employeeId: _asInt(json['employee_id']),
      employeeName: _asString(json['employee_name']),
      employeeEmail: _asString(json['employee_email']),
      title: _asString(json['title']),
      startDate: _asString(json['start_date']),
      endDate: _asString(json['end_date']),
      allDay: _asBool(json['all_day'], fallback: true),
      status: _asString(json['status']),
      absenceTypeKey: _asString(json['absence_type_key']),
      absenceTypeName: _asString(json['absence_type_name']),
      availabilityKind: _asString(json['availability_kind']),
      blocksAvailability: _asBool(json['blocks_availability']),
      calendarColor: _asString(json['calendar_color'], fallback: '#F59E0B'),
      isPending: _asBool(json['is_pending']),
      tooltip: _asString(json['tooltip']),
    );
  }
}


List<EmployeeManagementAvailabilitySummaryBlockModel> _decodeAvailabilitySummaryBlocks(dynamic value) {
  return _asList(value)
      .whereType<Map>()
      .map(
        (item) => EmployeeManagementAvailabilitySummaryBlockModel.fromJson(
          Map<String, dynamic>.from(item),
        ),
      )
      .toList(growable: false);
}

class EmployeeManagementDashboardNotifier
    extends StateNotifier<AsyncValue<EmployeeManagementDashboardModel>> {
  final Ref ref;
  final EmployeeManagementDashboardParams params;

  EmployeeManagementDashboardNotifier(
    this.ref, {
    required this.params,
  }) : super(const AsyncValue.loading()) {
    Future.microtask(fetch);
  }

  Future<void> fetch({bool showLoading = true}) async {
    try {
      if (showLoading) state = const AsyncValue.loading();

      final response = await ApiServices.get(
        EmployeeManagementUrls.dashboard,
        ref: ref,
        hasToken: true,
        queryParameters: params.toQueryParameters(),
      );

      if (response == null) {
        throw Exception('Failed to fetch employee management dashboard');
      }

      _ensureSuccess(response, 'Failed to fetch employee management dashboard');

      state = AsyncValue.data(
        EmployeeManagementDashboardModel.fromJson(_decodeResponse(response.data)),
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

class EmployeeAbsenceTypesNotifier
    extends StateNotifier<AsyncValue<List<EmployeeAbsenceTypeModel>>> {
  final Ref ref;

  EmployeeAbsenceTypesNotifier(this.ref) : super(const AsyncValue.loading()) {
    Future.microtask(fetch);
  }

  Future<void> fetch({bool showLoading = true}) async {
    try {
      if (showLoading) state = const AsyncValue.loading();
      final response = await ApiServices.get(
        EmployeeManagementUrls.absenceTypes,
        ref: ref,
        hasToken: true,
        queryParameters: const {'active': 'true'},
      );
      _ensureSuccess(response, 'Failed to fetch absence types');
      state = AsyncValue.data(
        _decodeList(response?.data)
            .whereType<Map>()
            .map((item) => EmployeeAbsenceTypeModel.fromJson(Map<String, dynamic>.from(item)))
            .toList(),
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

class EmployeeAbsenceDashboardNotifier
    extends StateNotifier<AsyncValue<EmployeeAbsenceDashboardModel>> {
  final Ref ref;
  final EmployeeAbsenceDashboardParams params;

  EmployeeAbsenceDashboardNotifier(this.ref, this.params) : super(const AsyncValue.loading()) {
    Future.microtask(fetch);
  }

  Future<void> fetch({bool showLoading = true}) async {
    try {
      if (showLoading) state = const AsyncValue.loading();
      final response = await ApiServices.get(
        EmployeeManagementUrls.employeeAbsenceDashboard(params.employeeId),
        ref: ref,
        hasToken: true,
        queryParameters: params.toQueryParameters(),
      );
      _ensureSuccess(response, 'Failed to fetch employee absence dashboard');
      state = AsyncValue.data(
        EmployeeAbsenceDashboardModel.fromJson(_decodeResponse(response?.data)),
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

class EmployeeAvailabilityNotifier
    extends StateNotifier<AsyncValue<List<EmployeeAvailabilityEventModel>>> {
  final Ref ref;
  final EmployeeAvailabilityParams params;

  EmployeeAvailabilityNotifier(this.ref, this.params) : super(const AsyncValue.loading()) {
    Future.microtask(fetch);
  }

  Future<void> fetch({bool showLoading = true}) async {
    try {
      if (showLoading) state = const AsyncValue.loading();
      final response = await ApiServices.get(
        EmployeeManagementUrls.availability,
        ref: ref,
        hasToken: true,
        queryParameters: params.toQueryParameters(),
      );
      _ensureSuccess(response, 'Failed to fetch employee availability');
      final data = _decodeResponse(response?.data);
      state = AsyncValue.data(
        _asList(data['events'])
            .whereType<Map>()
            .map((item) => EmployeeAvailabilityEventModel.fromJson(Map<String, dynamic>.from(item)))
            .toList(),
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

class EmployeeAbsenceActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  EmployeeAbsenceActionsNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<EmployeeAbsenceModel> requestAbsence({
    required int employeeId,
    required int absenceTypeId,
    required String startDate,
    required String endDate,
    String halfDayMode = 'none',
    String reason = '',
    String attachmentUrl = '',
  }) async {
    state = const AsyncValue.loading();
    try {
      final response = await ApiServices.post(
        EmployeeManagementUrls.absences,
        ref: ref,
        hasToken: true,
        data: {
          'employee': employeeId,
          'absence_type': absenceTypeId,
          'start_date': startDate,
          'end_date': endDate,
          'half_day_mode': halfDayMode,
          'reason': reason,
          'attachment_url': attachmentUrl,
        },
      );
      _ensureSuccess(response, 'Failed to request absence');
      final model = EmployeeAbsenceModel.fromJson(_decodeResponse(response?.data));
      state = const AsyncValue.data(null);
      return model;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<EmployeeAbsenceModel> approve(int absenceId, {String note = ''}) async {
    return _action(EmployeeManagementUrls.absenceApprove(absenceId), {'note': note});
  }

  Future<EmployeeAbsenceModel> reject(int absenceId, {String note = ''}) async {
    return _action(EmployeeManagementUrls.absenceReject(absenceId), {'note': note});
  }

  Future<EmployeeAbsenceModel> cancel(int absenceId, {String note = ''}) async {
    return _action(EmployeeManagementUrls.absenceCancel(absenceId), {'note': note});
  }

  Future<EmployeeAbsenceModel> _action(String url, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      final response = await ApiServices.post(
        url,
        ref: ref,
        hasToken: true,
        data: data,
      );
      _ensureSuccess(response, 'Failed to update absence');
      final model = EmployeeAbsenceModel.fromJson(_decodeResponse(response?.data));
      state = const AsyncValue.data(null);
      return model;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}

final employeeManagementDashboardProvider = StateNotifierProvider.family<
    EmployeeManagementDashboardNotifier,
    AsyncValue<EmployeeManagementDashboardModel>,
    EmployeeManagementDashboardParams>(
  (ref, params) => EmployeeManagementDashboardNotifier(ref, params: params),
);

final employeeAbsenceTypesProvider = StateNotifierProvider<
    EmployeeAbsenceTypesNotifier,
    AsyncValue<List<EmployeeAbsenceTypeModel>>>(
  (ref) => EmployeeAbsenceTypesNotifier(ref),
);

final employeeAbsenceDashboardProvider = StateNotifierProvider.family<
    EmployeeAbsenceDashboardNotifier,
    AsyncValue<EmployeeAbsenceDashboardModel>,
    EmployeeAbsenceDashboardParams>(
  (ref, params) => EmployeeAbsenceDashboardNotifier(ref, params),
);

final employeeAvailabilityProvider = StateNotifierProvider.family<
    EmployeeAvailabilityNotifier,
    AsyncValue<List<EmployeeAvailabilityEventModel>>,
    EmployeeAvailabilityParams>(
  (ref, params) => EmployeeAvailabilityNotifier(ref, params),
);

final employeeAbsenceActionsProvider = StateNotifierProvider<
    EmployeeAbsenceActionsNotifier,
    AsyncValue<void>>(
  (ref) => EmployeeAbsenceActionsNotifier(ref),
);

Map<String, dynamic> _decodeResponse(dynamic data) {
  dynamic decoded = data;

  if (decoded is List<int>) {
    decoded = jsonDecode(utf8.decode(decoded));
  }

  if (decoded is String) {
    decoded = jsonDecode(decoded);
  }

  if (decoded is Map && decoded['data'] is Map) {
    decoded = decoded['data'];
  }

  if (decoded is! Map) {
    throw Exception('Unexpected employee management response: ${decoded.runtimeType}');
  }

  return Map<String, dynamic>.from(decoded);
}

List<dynamic> _decodeList(dynamic data) {
  dynamic decoded = data;

  if (decoded is List<int>) {
    decoded = jsonDecode(utf8.decode(decoded));
  }

  if (decoded is String) {
    decoded = jsonDecode(decoded);
  }

  if (decoded is Map && decoded['results'] is List) {
    decoded = decoded['results'];
  }

  if (decoded is! List) {
    throw Exception('Unexpected employee management list response: ${decoded.runtimeType}');
  }

  return decoded;
}

void _ensureSuccess(dynamic response, String message) {
  final statusCode = response?.statusCode ?? 0;
  if (statusCode < 200 || statusCode >= 300) {
    throw Exception(message);
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
  return value.toString();
}

String? _asNullableString(dynamic value) {
  if (value == null) return null;
  final text = value.toString();
  return text.isEmpty ? null : text;
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value.toString()) ?? fallback;
}

int? _asNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value.toString());
}

double _asDouble(dynamic value, {double fallback = 0}) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? fallback;
}

bool _asBool(dynamic value, {bool fallback = false}) {
  if (value == null) return fallback;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final normalized = value.toString().trim().toLowerCase();
  if (['1', 'true', 'yes', 'y', 'on'].contains(normalized)) return true;
  if (['0', 'false', 'no', 'n', 'off'].contains(normalized)) return false;
  return fallback;
}

DateTime? _asDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
