// crm/employee_panel/provider/employee_availability_provider.dart

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';

class EmployeeAvailabilityUrls {
  static const String workProfiles =
      'https://www.superbee.cloud/finance/compensation/work-profiles/';

  static const String availabilityRules =
      'https://www.superbee.cloud/finance/compensation/availability-rules/';

  static const String availabilityOverrides =
      'https://www.superbee.cloud/finance/compensation/availability-overrides/';

  static const String workTimeEntries =
      'https://www.superbee.cloud/finance/compensation/work-time-entries/';

  static const String bootstrapDefaults =
      'https://www.superbee.cloud/finance/compensation/availability/bootstrap-defaults/';

  /// Working endpoint used by employee management dashboard.
  static const String employeeManagementDashboard =
      'https://www.superbee.cloud/finance/compensation/employee-management-dashboard/';

  /// Full HR availability endpoint. It supports rules, overrides, time entries,
  /// absences and public holidays.
  static const String availabilityCalendar =
      'https://www.superbee.cloud/finance/compensation/availability/calendar/';

  /// Stable absence-only fallback used when the full endpoint is not deployed yet.
  static const String absenceAvailabilityFallback =
      'https://www.superbee.cloud/finance/compensation/absences/availability/';

  /// Kept for compatibility with existing calls.
  ///
  /// We intentionally point it to the working management dashboard instead of
  /// the old/broken /employees/<id>/availability-dashboard/ endpoint.
  static String employeeAvailabilityDashboard(int employeeId) {
    return employeeManagementDashboard;
  }

  static String workProfileGenerateDefaultRules(int id) =>
      '$workProfiles$id/generate_default_rules/';

  static String workTimeEntryApprove(int id) => '$workTimeEntries$id/approve/';

  static String workTimeEntryReject(int id) => '$workTimeEntries$id/reject/';
}

class EmployeeAvailabilityCalendarParams {
  final String start;
  final String end;
  final int? employeeId;
  final bool includePending;
  final bool includeRules;
  final bool includeAbsences;
  final bool includeOverrides;
  final bool includeTimeEntries;
  final bool includePublicHolidays;
  final bool skipRulesOnPublicHolidays;
  final String publicHolidayCountry;

  const EmployeeAvailabilityCalendarParams({
    required this.start,
    required this.end,
    this.employeeId,
    this.includePending = true,
    this.includeRules = true,
    this.includeAbsences = true,
    this.includeOverrides = true,
    this.includeTimeEntries = true,
    this.includePublicHolidays = true,
    this.skipRulesOnPublicHolidays = true,
    this.publicHolidayCountry = 'PL',
  });

  Map<String, String> toQueryParameters() => {
        'start': _dateOnly(start),
        'end': _dateOnly(end),
        'include_pending': includePending ? 'true' : 'false',
        'include_rules': includeRules ? 'true' : 'false',
        'include_absences': includeAbsences ? 'true' : 'false',
        'include_overrides': includeOverrides ? 'true' : 'false',
        'include_time_entries': includeTimeEntries ? 'true' : 'false',
        'include_public_holidays': includePublicHolidays ? 'true' : 'false',
        'skip_rules_on_public_holidays':
            skipRulesOnPublicHolidays ? 'true' : 'false',
        'public_holiday_country': publicHolidayCountry,
        if (employeeId != null) 'employee_id': employeeId.toString(),
      };

  @override
  bool operator ==(Object other) {
    return other is EmployeeAvailabilityCalendarParams &&
        other.start == start &&
        other.end == end &&
        other.employeeId == employeeId &&
        other.includePending == includePending &&
        other.includeRules == includeRules &&
        other.includeAbsences == includeAbsences &&
        other.includeOverrides == includeOverrides &&
        other.includeTimeEntries == includeTimeEntries &&
        other.includePublicHolidays == includePublicHolidays &&
        other.skipRulesOnPublicHolidays == skipRulesOnPublicHolidays &&
        other.publicHolidayCountry == publicHolidayCountry;
  }

  @override
  int get hashCode => Object.hash(
        start,
        end,
        employeeId,
        includePending,
        includeRules,
        includeAbsences,
        includeOverrides,
        includeTimeEntries,
        includePublicHolidays,
        skipRulesOnPublicHolidays,
        publicHolidayCountry,
      );
}

class EmployeeAvailabilityDashboardParams {
  final int employeeId;
  final String? start;
  final String? end;

  const EmployeeAvailabilityDashboardParams({
    required this.employeeId,
    this.start,
    this.end,
  });

  Map<String, String> toQueryParameters() => {
        'period': _periodFromDate(start),
        'currency': 'PLN',
      };

  @override
  bool operator ==(Object other) {
    return other is EmployeeAvailabilityDashboardParams &&
        other.employeeId == employeeId &&
        other.start == start &&
        other.end == end;
  }

  @override
  int get hashCode => Object.hash(employeeId, start, end);
}

class EmployeeWorkProfileModel {
  final int id;
  final int employee;
  final String employeeName;
  final String workMode;
  final String timezone;
  final double weeklyHoursTarget;
  final String? defaultContactStart;
  final String? defaultContactEnd;
  final String? defaultPresentationStart;
  final String? defaultPresentationEnd;
  final bool allowEveningAppointments;
  final bool allowWeekendAppointments;
  final bool isTimeTrackingEnabled;
  final bool affectsSettlement;
  final String note;

  const EmployeeWorkProfileModel({
    required this.id,
    required this.employee,
    required this.employeeName,
    required this.workMode,
    required this.timezone,
    required this.weeklyHoursTarget,
    required this.defaultContactStart,
    required this.defaultContactEnd,
    required this.defaultPresentationStart,
    required this.defaultPresentationEnd,
    required this.allowEveningAppointments,
    required this.allowWeekendAppointments,
    required this.isTimeTrackingEnabled,
    required this.affectsSettlement,
    required this.note,
  });

  factory EmployeeWorkProfileModel.fromJson(Map<String, dynamic> json) {
    return EmployeeWorkProfileModel(
      id: _asInt(json['id']),
      employee: _asInt(json['employee']),
      employeeName: _asString(json['employee_name']),
      workMode: _asString(json['work_mode'], fallback: 'appointment_based'),
      timezone: _asString(json['timezone'], fallback: 'Europe/Warsaw'),
      weeklyHoursTarget: _asDouble(json['weekly_hours_target']),
      defaultContactStart: _asNullableString(json['default_contact_start']),
      defaultContactEnd: _asNullableString(json['default_contact_end']),
      defaultPresentationStart:
          _asNullableString(json['default_presentation_start']),
      defaultPresentationEnd:
          _asNullableString(json['default_presentation_end']),
      allowEveningAppointments:
          _asBool(json['allow_evening_appointments'], fallback: true),
      allowWeekendAppointments:
          _asBool(json['allow_weekend_appointments'], fallback: true),
      isTimeTrackingEnabled: _asBool(json['is_time_tracking_enabled']),
      affectsSettlement: _asBool(json['affects_settlement']),
      note: _asString(json['note']),
    );
  }
}

class EmployeeAvailabilityRuleModel {
  final int id;
  final int employee;
  final String employeeName;
  final int weekday;
  final String startTime;
  final String endTime;
  final String kind;
  final String title;
  final String color;
  final bool isBookable;
  final bool blocksBooking;
  final bool isActive;
  final int sortIndex;

  const EmployeeAvailabilityRuleModel({
    required this.id,
    required this.employee,
    required this.employeeName,
    required this.weekday,
    required this.startTime,
    required this.endTime,
    required this.kind,
    required this.title,
    required this.color,
    required this.isBookable,
    required this.blocksBooking,
    required this.isActive,
    required this.sortIndex,
  });

  factory EmployeeAvailabilityRuleModel.fromJson(Map<String, dynamic> json) {
    return EmployeeAvailabilityRuleModel(
      id: _asInt(json['id']),
      employee: _asInt(json['employee']),
      employeeName: _asString(json['employee_name']),
      weekday: _asInt(json['weekday']),
      startTime: _asString(json['start_time']),
      endTime: _asString(json['end_time']),
      kind: _asString(json['kind']),
      title: _asString(json['title']),
      color: _asString(json['color'], fallback: '#22C55E'),
      isBookable: _asBool(json['is_bookable'], fallback: true),
      blocksBooking: _asBool(json['blocks_booking']),
      isActive: _asBool(json['is_active'], fallback: true),
      sortIndex: _asInt(json['sort_index']),
    );
  }
}

class EmployeeAvailabilityBlockModel {
  final String id;
  final int employeeId;
  final String employeeName;
  final DateTime startAt;
  final DateTime endAt;
  final String kind;
  final String title;
  final String source;
  final int? sourceId;
  final String color;
  final bool isBookable;
  final bool blocksBooking;
  final int priority;
  final String status;
  final String tooltip;
  final Map<String, dynamic> metadata;

  const EmployeeAvailabilityBlockModel({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.startAt,
    required this.endAt,
    required this.kind,
    required this.title,
    required this.source,
    required this.sourceId,
    required this.color,
    required this.isBookable,
    required this.blocksBooking,
    required this.priority,
    required this.status,
    required this.tooltip,
    required this.metadata,
  });

  bool get isPublicHoliday => source == 'public_holiday' || kind == 'public_holiday';

  bool occursOn(DateTime day) {
    final normalized = DateTime(day.year, day.month, day.day);
    final startDay = DateTime(startAt.year, startAt.month, startAt.day);
    final endDay = DateTime(endAt.year, endAt.month, endAt.day);
    return !normalized.isBefore(startDay) && !normalized.isAfter(endDay);
  }

  factory EmployeeAvailabilityBlockModel.fromJson(Map<String, dynamic> json) {
    final normalized = _normalizeBlockJson(json);

    final startAt = _parseBlockStart(normalized) ?? DateTime.now();
    final endAt = _parseBlockEnd(normalized) ?? startAt;

    final blocksBooking = _asBool(
      normalized['blocks_booking'] ?? normalized['blocks_availability'],
      fallback: false,
    );

    final isBookable = _asBool(
      normalized['is_bookable'],
      fallback: !blocksBooking,
    );

    final sourceId = _asNullableInt(
      normalized['source_id'] ?? normalized['id'],
    );

    final kind = _asString(
      normalized['kind'] ??
          normalized['availability_kind'] ??
          normalized['absence_type_key'],
      fallback: blocksBooking ? 'blocked' : 'available',
    );

    final title = _asString(
      normalized['title'] ??
          normalized['label'] ??
          normalized['absence_type_name'] ??
          normalized['absence_type_key'],
      fallback: blocksBooking ? 'Niedostępny' : 'Dostępny',
    );

    return EmployeeAvailabilityBlockModel(
      id: _asString(
        normalized['id'],
        fallback:
            '${_asString(normalized['source'], fallback: 'availability')}-$sourceId-${startAt.toIso8601String()}',
      ),
      employeeId: _asInt(
        normalized['employee_id'] ?? normalized['employee'],
      ),
      employeeName: _asString(normalized['employee_name']),
      startAt: startAt,
      endAt: endAt,
      kind: kind,
      title: title,
      source: _asString(normalized['source'], fallback: 'availability'),
      sourceId: sourceId,
      color: _asString(
        normalized['color'] ?? normalized['calendar_color'],
        fallback: blocksBooking ? '#F59E0B' : '#22C55E',
      ),
      isBookable: isBookable,
      blocksBooking: blocksBooking,
      priority: _asInt(normalized['priority']),
      status: _asString(normalized['status']),
      tooltip: _asString(
        normalized['tooltip'],
        fallback: title,
      ),
      metadata: Map<String, dynamic>.from(
        normalized['metadata'] is Map ? normalized['metadata'] : const {},
      ),
    );
  }
}

class EmployeeTodayStatusModel {
  final String key;
  final String label;
  final String color;
  final bool blocksBooking;

  const EmployeeTodayStatusModel({
    required this.key,
    required this.label,
    required this.color,
    required this.blocksBooking,
  });

  factory EmployeeTodayStatusModel.fromJson(Map<String, dynamic> json) {
    return EmployeeTodayStatusModel(
      key: _asString(json['key'], fallback: 'outside_availability'),
      label: _asString(
        json['label'],
        fallback: 'Poza standardową dostępnością',
      ),
      color: _asString(json['color'], fallback: '#64748B'),
      blocksBooking: _asBool(json['blocks_booking']),
    );
  }
}

class EmployeeAvailabilityDashboardModel {
  final int employeeId;
  final String employeeName;
  final EmployeeWorkProfileModel? profile;
  final EmployeeTodayStatusModel todayStatus;
  final List<EmployeeAvailabilityBlockModel> blockingToday;
  final List<EmployeeAvailabilityBlockModel> bookableToday;
  final List<EmployeeAvailabilityBlockModel> upcomingBlocks;
  final double totalHours;

  const EmployeeAvailabilityDashboardModel({
    required this.employeeId,
    required this.employeeName,
    required this.profile,
    required this.todayStatus,
    required this.blockingToday,
    required this.bookableToday,
    required this.upcomingBlocks,
    required this.totalHours,
  });

  factory EmployeeAvailabilityDashboardModel.empty({
    required int employeeId,
    String employeeName = '',
  }) {
    return EmployeeAvailabilityDashboardModel(
      employeeId: employeeId,
      employeeName: employeeName,
      profile: null,
      todayStatus: const EmployeeTodayStatusModel(
        key: 'outside_availability',
        label: 'Brak danych dostępności',
        color: '#64748B',
        blocksBooking: false,
      ),
      blockingToday: const [],
      bookableToday: const [],
      upcomingBlocks: const [],
      totalHours: 0,
    );
  }

  factory EmployeeAvailabilityDashboardModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return EmployeeAvailabilityDashboardModel(
      employeeId: _asInt(json['employee_id']),
      employeeName: _asString(json['employee_name']),
      profile: json['profile'] is Map
          ? EmployeeWorkProfileModel.fromJson({
              'id': json['profile']['id'],
              'employee': json['employee_id'],
              'employee_name': json['employee_name'],
              ...Map<String, dynamic>.from(json['profile']),
            })
          : null,
      todayStatus: EmployeeTodayStatusModel.fromJson(
        Map<String, dynamic>.from(
          json['today_status'] is Map ? json['today_status'] : const {},
        ),
      ),
      blockingToday: _decodeBlockList(json['blocking_today']),
      bookableToday: _decodeBlockList(json['bookable_today']),
      upcomingBlocks: _decodeBlockList(json['upcoming_blocks']),
      totalHours: _asDouble(
        json['work_time'] is Map ? json['work_time']['total_hours'] : 0,
      ),
    );
  }
}

class EmployeeAvailabilityCalendarNotifier
    extends StateNotifier<AsyncValue<List<EmployeeAvailabilityBlockModel>>> {
  final Ref ref;
  final EmployeeAvailabilityCalendarParams params;

  EmployeeAvailabilityCalendarNotifier(this.ref, this.params)
      : super(const AsyncValue.loading()) {
    Future.microtask(fetch);
  }

  Future<void> fetch({bool showLoading = true}) async {
    try {
      if (showLoading) state = const AsyncValue.loading();

      final blocks = await _fetchCalendarBlocks(
        ref: ref,
        params: params,
      );

      state = AsyncValue.data(blocks);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

class EmployeeAvailabilityDashboardNotifier
    extends StateNotifier<AsyncValue<EmployeeAvailabilityDashboardModel>> {
  final Ref ref;
  final EmployeeAvailabilityDashboardParams params;

  EmployeeAvailabilityDashboardNotifier(this.ref, this.params)
      : super(const AsyncValue.loading()) {
    Future.microtask(fetch);
  }

  Future<void> fetch({bool showLoading = true}) async {
    try {
      if (showLoading) state = const AsyncValue.loading();

      final rangeStart = _rangeStartFromDashboardParams(params);
      final rangeEnd = _rangeEndFromDashboardParams(params);

      final dashboardData = await _tryGetJson(
        ref: ref,
        url: EmployeeAvailabilityUrls.employeeAvailabilityDashboard(
          params.employeeId,
        ),
        queryParameters: params.toQueryParameters(),
        errorMessage: 'Failed to fetch employee availability dashboard',
      );

      final calendarBlocks = await _fetchCalendarBlocks(
        ref: ref,
        params: EmployeeAvailabilityCalendarParams(
          start: rangeStart.toIso8601String(),
          end: rangeEnd.toIso8601String(),
          employeeId: params.employeeId,
          includePending: true,
        ),
      );

      final model = _buildDashboardModel(
        employeeId: params.employeeId,
        dashboardData: dashboardData,
        calendarBlocks: calendarBlocks,
      );

      state = AsyncValue.data(model);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

class EmployeeAvailabilityActionsNotifier
    extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  EmployeeAvailabilityActionsNotifier(this.ref)
      : super(const AsyncValue.data(null));

  Future<void> bootstrapDefaults({List<int> employeeIds = const []}) async {
    state = const AsyncValue.loading();

    try {
      final response = await ApiServices.post(
        EmployeeAvailabilityUrls.bootstrapDefaults,
        ref: ref,
        hasToken: true,
        data: {'employee_ids': employeeIds},
      );

      _ensureSuccess(response, 'Failed to bootstrap availability defaults');

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> createOverride({
    required int employeeId,
    required DateTime startAt,
    required DateTime endAt,
    required String kind,
    required String title,
    String note = '',
    bool? isBookable,
    bool? blocksBooking,
  }) async {
    state = const AsyncValue.loading();

    try {
      final response = await ApiServices.post(
        EmployeeAvailabilityUrls.availabilityOverrides,
        ref: ref,
        hasToken: true,
        data: {
          'employee': employeeId,
          'start_at': startAt.toIso8601String(),
          'end_at': endAt.toIso8601String(),
          'kind': kind,
          'title': title,
          'note': note,
          if (isBookable != null) 'is_bookable': isBookable,
          if (blocksBooking != null) 'blocks_booking': blocksBooking,
        },
      );

      _ensureSuccess(response, 'Failed to create availability override');

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> createTimeEntry({
    required int employeeId,
    required DateTime startAt,
    required DateTime endAt,
    required String kind,
    required String title,
    String note = '',
    bool affectsSettlement = false,
    bool blocksBooking = true,
  }) async {
    state = const AsyncValue.loading();

    try {
      final response = await ApiServices.post(
        EmployeeAvailabilityUrls.workTimeEntries,
        ref: ref,
        hasToken: true,
        data: {
          'employee': employeeId,
          'start_at': startAt.toIso8601String(),
          'end_at': endAt.toIso8601String(),
          'kind': kind,
          'title': title,
          'note': note,
          'affects_settlement': affectsSettlement,
          'blocks_booking': blocksBooking,
        },
      );

      _ensureSuccess(response, 'Failed to create work time entry');

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}

final employeeAvailabilityCalendarProvider = StateNotifierProvider.family<
    EmployeeAvailabilityCalendarNotifier,
    AsyncValue<List<EmployeeAvailabilityBlockModel>>,
    EmployeeAvailabilityCalendarParams>(
  (ref, params) => EmployeeAvailabilityCalendarNotifier(ref, params),
);

final employeeAvailabilityDashboardProvider = StateNotifierProvider.family<
    EmployeeAvailabilityDashboardNotifier,
    AsyncValue<EmployeeAvailabilityDashboardModel>,
    EmployeeAvailabilityDashboardParams>(
  (ref, params) => EmployeeAvailabilityDashboardNotifier(ref, params),
);

final employeeAvailabilityActionsProvider =
    StateNotifierProvider<EmployeeAvailabilityActionsNotifier, AsyncValue<void>>(
  (ref) => EmployeeAvailabilityActionsNotifier(ref),
);

Future<List<EmployeeAvailabilityBlockModel>> _fetchCalendarBlocks({
  required Ref ref,
  required EmployeeAvailabilityCalendarParams params,
}) async {
  Map<String, dynamic>? data;

  try {
    data = await _tryGetJson(
      ref: ref,
      url: EmployeeAvailabilityUrls.availabilityCalendar,
      queryParameters: params.toQueryParameters(),
      errorMessage: 'Failed to fetch employee availability calendar',
    );
  } catch (_) {
    // Keep older deployments alive. The fallback is absence-only, so it will not
    // include rules, overrides, time entries or public holidays.
    data = await _tryGetJson(
      ref: ref,
      url: EmployeeAvailabilityUrls.absenceAvailabilityFallback,
      queryParameters: params.toQueryParameters(),
      errorMessage: 'Failed to fetch employee absence availability fallback',
    );
  }

  if (data == null || data.isEmpty) {
    return const [];
  }

  final rawItems = _firstListValue(data, const [
    'events',
    'results',
    'availability',
    'items',
    'blocks',
  ]);

  final blocks = _decodeBlockListWithDefaults(
    rawItems,
    employeeId: params.employeeId,
  );

  if (params.employeeId == null) {
    return blocks;
  }

  return blocks
      .where((item) => item.employeeId == params.employeeId || item.isPublicHoliday)
      .toList(growable: false);
}

Future<Map<String, dynamic>?> _tryGetJson({
  required Ref ref,
  required String url,
  required String errorMessage,
  Map<String, dynamic>? queryParameters,
}) async {
  final response = await ApiServices.get(
    url,
    ref: ref,
    hasToken: true,
    responseType: ResponseType.json,
    queryParameters: queryParameters,
  );

  if (response == null) {
    return null;
  }

  _ensureSuccess(response, errorMessage);

  return _decodeResponse(response.data);
}

EmployeeAvailabilityDashboardModel _buildDashboardModel({
  required int employeeId,
  required Map<String, dynamic>? dashboardData,
  required List<EmployeeAvailabilityBlockModel> calendarBlocks,
}) {
  final employeeJson = _findEmployeeJson(dashboardData, employeeId);
  final userJson = _asMap(employeeJson['user']);
  final availabilitySummary = _asMap(employeeJson['availability_summary']);

  final employeeName = _resolveEmployeeName(
    userJson: userJson,
    employeeJson: employeeJson,
    calendarBlocks: calendarBlocks,
  );

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));

  final summaryBlockingToday = _decodeBlockListWithDefaults(
    availabilitySummary['blocking_today'],
    employeeId: employeeId,
    employeeName: employeeName,
    defaultStartAt: today,
    defaultEndAt: tomorrow,
  );

  final summaryBookableToday = _decodeBlockListWithDefaults(
    availabilitySummary['bookable_today'],
    employeeId: employeeId,
    employeeName: employeeName,
    defaultStartAt: today,
    defaultEndAt: tomorrow,
  );

  final calendarToday = calendarBlocks
      .where((block) => block.occursOn(today))
      .toList(growable: false);

  final blockingToday = summaryBlockingToday.isNotEmpty
      ? summaryBlockingToday
      : calendarToday
          .where((block) => block.blocksBooking)
          .toList(growable: false);

  final bookableToday = summaryBookableToday.isNotEmpty
      ? summaryBookableToday
      : calendarToday
          .where((block) => block.isBookable && !block.blocksBooking)
          .toList(growable: false);

  final upcomingBlocks = calendarBlocks
      .where((block) => block.endAt.isAfter(now) && !block.occursOn(today))
      .toList()
    ..sort((a, b) => a.startAt.compareTo(b.startAt));

  final profileJson = _asMap(
    employeeJson['profile'] ??
        employeeJson['work_profile'] ??
        availabilitySummary['profile'],
  );

  final profile = profileJson.isNotEmpty
      ? EmployeeWorkProfileModel.fromJson({
          'id': profileJson['id'],
          'employee': employeeId,
          'employee_name': employeeName,
          ...profileJson,
        })
      : null;

  return EmployeeAvailabilityDashboardModel(
    employeeId: employeeId,
    employeeName: employeeName,
    profile: profile,
    todayStatus: _buildTodayStatus(
      availabilitySummary: availabilitySummary,
      blockingToday: blockingToday,
      bookableToday: bookableToday,
    ),
    blockingToday: blockingToday,
    bookableToday: bookableToday,
    upcomingBlocks: upcomingBlocks.take(30).toList(growable: false),
    totalHours: _asDouble(
      _asMap(employeeJson['work_time'])['total_hours'] ??
          availabilitySummary['total_hours'],
    ),
  );
}

Map<String, dynamic> _findEmployeeJson(
  Map<String, dynamic>? dashboardData,
  int employeeId,
) {
  if (dashboardData == null || dashboardData.isEmpty) {
    return <String, dynamic>{};
  }

  final employees = _asList(dashboardData['employees']);

  for (final item in employees) {
    if (item is! Map) continue;

    final employeeJson = Map<String, dynamic>.from(item);
    final userJson = _asMap(employeeJson['user']);

    final userId = _asInt(userJson['id']);
    final directId = _asInt(
      employeeJson['employee_id'] ?? employeeJson['id'],
      fallback: -1,
    );

    if (userId == employeeId || directId == employeeId) {
      return employeeJson;
    }
  }

  return <String, dynamic>{};
}

String _resolveEmployeeName({
  required Map<String, dynamic> userJson,
  required Map<String, dynamic> employeeJson,
  required List<EmployeeAvailabilityBlockModel> calendarBlocks,
}) {
  final fullName = _asString(userJson['full_name']);
  if (fullName.isNotEmpty) return fullName;

  final firstName = _asString(userJson['first_name']);
  final lastName = _asString(userJson['last_name']);
  final joinedName = '$firstName $lastName'.trim();
  if (joinedName.isNotEmpty) return joinedName;

  final username = _asString(userJson['username']);
  if (username.isNotEmpty) return username;

  final email = _asString(userJson['email']);
  if (email.isNotEmpty) return email;

  final directName = _asString(
    employeeJson['employee_name'] ?? employeeJson['name'],
  );
  if (directName.isNotEmpty) return directName;

  if (calendarBlocks.isNotEmpty) {
    return calendarBlocks.first.employeeName;
  }

  return 'Employee';
}

EmployeeTodayStatusModel _buildTodayStatus({
  required Map<String, dynamic> availabilitySummary,
  required List<EmployeeAvailabilityBlockModel> blockingToday,
  required List<EmployeeAvailabilityBlockModel> bookableToday,
}) {
  final summaryKey = _asString(availabilitySummary['today_status_key']);
  final summaryLabel = _asString(availabilitySummary['today_status_label']);
  final summaryColor = _asString(availabilitySummary['today_status_color']);
  final summaryBlocksBooking = _asBool(availabilitySummary['blocks_booking']);

  if (summaryKey.isNotEmpty || summaryLabel.isNotEmpty) {
    return EmployeeTodayStatusModel(
      key: summaryKey.isNotEmpty ? summaryKey : 'outside_availability',
      label: summaryLabel.isNotEmpty
          ? summaryLabel
          : 'Poza standardową dostępnością',
      color: summaryColor.isNotEmpty ? summaryColor : '#64748B',
      blocksBooking: summaryBlocksBooking,
    );
  }

  if (blockingToday.isNotEmpty) {
    final block = blockingToday.first;
    return EmployeeTodayStatusModel(
      key: block.kind.isNotEmpty ? block.kind : 'blocked',
      label: block.title.isNotEmpty ? block.title : 'Niedostępny',
      color: block.color,
      blocksBooking: true,
    );
  }

  if (bookableToday.isNotEmpty) {
    final block = bookableToday.first;
    return EmployeeTodayStatusModel(
      key: block.kind.isNotEmpty ? block.kind : 'available',
      label: block.title.isNotEmpty ? block.title : 'Dostępny',
      color: block.color,
      blocksBooking: false,
    );
  }

  return const EmployeeTodayStatusModel(
    key: 'outside_availability',
    label: 'Poza standardową dostępnością',
    color: '#64748B',
    blocksBooking: false,
  );
}

List<EmployeeAvailabilityBlockModel> _decodeBlockList(dynamic value) {
  return _decodeBlockListWithDefaults(value);
}

List<EmployeeAvailabilityBlockModel> _decodeBlockListWithDefaults(
  dynamic value, {
  int? employeeId,
  String? employeeName,
  DateTime? defaultStartAt,
  DateTime? defaultEndAt,
}) {
  return _asList(value)
      .whereType<Map>()
      .map((item) {
        final json = Map<String, dynamic>.from(item);

        if (employeeId != null) {
          json['employee_id'] ??= employeeId;
          json['employee'] ??= employeeId;
        }

        if (employeeName != null && employeeName.isNotEmpty) {
          json['employee_name'] ??= employeeName;
        }

        if (defaultStartAt != null) {
          json['start_at'] ??= defaultStartAt.toIso8601String();
        }

        if (defaultEndAt != null) {
          json['end_at'] ??= defaultEndAt.toIso8601String();
        }

        return EmployeeAvailabilityBlockModel.fromJson(json);
      })
      .toList(growable: false);
}

Map<String, dynamic> _decodeResponse(dynamic data) {
  dynamic decoded = data;

  if (decoded is List<int>) {
    decoded = jsonDecode(utf8.decode(decoded));
  }

  if (decoded is String && decoded.trim().isNotEmpty) {
    decoded = jsonDecode(decoded);
  }

  if (decoded is Map && decoded['data'] is Map) {
    decoded = decoded['data'];
  }

  if (decoded is Map<String, dynamic>) return decoded;
  if (decoded is Map) return Map<String, dynamic>.from(decoded);

  return <String, dynamic>{};
}

List<dynamic> _firstListValue(
  Map<String, dynamic> data,
  List<String> keys,
) {
  for (final key in keys) {
    final value = data[key];

    if (value is List) return value;

    if (value is String && value.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) return decoded;
      } catch (_) {}
    }
  }

  return const [];
}

List<dynamic> _asList(dynamic value) {
  if (value is List) return value;

  if (value is String && value.trim().isNotEmpty) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is List) return decoded;
    } catch (_) {}
  }

  return const [];
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

Map<String, dynamic> _normalizeBlockJson(Map<String, dynamic> json) {
  final normalized = Map<String, dynamic>.from(json);

  normalized['employee_id'] ??= normalized['employee'];
  normalized['employee_name'] ??= normalized['user_name'];
  normalized['start_at'] ??= normalized['start'];
  normalized['end_at'] ??= normalized['end'];

  normalized['start_at'] ??= normalized['start_date'];
  normalized['end_at'] ??= normalized['end_date'];

  normalized['kind'] ??= normalized['availability_kind'];
  normalized['kind'] ??= normalized['absence_type_key'];

  normalized['title'] ??= normalized['label'];
  normalized['title'] ??= normalized['absence_type_name'];
  normalized['title'] ??= normalized['absence_type_key'];

  normalized['color'] ??= normalized['calendar_color'];

  if (normalized['blocks_booking'] == null &&
      normalized['blocks_availability'] != null) {
    normalized['blocks_booking'] = normalized['blocks_availability'];
  }

  if (normalized['is_bookable'] == null &&
      normalized['blocks_booking'] != null) {
    normalized['is_bookable'] = !_asBool(normalized['blocks_booking']);
  }

  return normalized;
}

DateTime? _parseBlockStart(Map<String, dynamic> json) {
  final value = json['start_at'] ?? json['start_date'] ?? json['start'];
  final parsed = _asDateTime(value);
  if (parsed != null) return parsed;

  final dateText = _asString(json['start_date']);
  if (dateText.isNotEmpty) {
    return DateTime.tryParse('${_dateOnly(dateText)}T00:00:00');
  }

  return null;
}

DateTime? _parseBlockEnd(Map<String, dynamic> json) {
  final value = json['end_at'] ?? json['end_date'] ?? json['end'];
  final parsed = _asDateTime(value);
  if (parsed != null) {
    final text = value?.toString() ?? '';

    if (_looksLikeDateOnly(text)) {
      return DateTime(
        parsed.year,
        parsed.month,
        parsed.day,
        23,
        59,
        59,
      );
    }

    return parsed;
  }

  final dateText = _asString(json['end_date']);
  if (dateText.isNotEmpty) {
    final date = DateTime.tryParse('${_dateOnly(dateText)}T23:59:59');
    if (date != null) return date;
  }

  return null;
}

void _ensureSuccess(dynamic response, String message) {
  final code = response?.statusCode ?? 0;

  if (code < 200 || code >= 300) {
    throw Exception('$message. Status code: $code');
  }
}

DateTime _rangeStartFromDashboardParams(
  EmployeeAvailabilityDashboardParams params,
) {
  final parsed = _asDateTime(params.start);

  if (parsed != null) {
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

DateTime _rangeEndFromDashboardParams(
  EmployeeAvailabilityDashboardParams params,
) {
  final parsed = _asDateTime(params.end);

  if (parsed != null) {
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  return _rangeStartFromDashboardParams(params).add(const Duration(days: 30));
}

String _periodFromDate(String? value) {
  final parsed = _asDateTime(value) ?? DateTime.now();

  final month = parsed.month.toString().padLeft(2, '0');
  return '${parsed.year}-$month';
}

String _dateOnly(String value) {
  final trimmed = value.trim();

  if (trimmed.length >= 10) {
    return trimmed.substring(0, 10);
  }

  return trimmed;
}

bool _looksLikeDateOnly(String value) {
  final trimmed = value.trim();
  return RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(trimmed);
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

int? _asNullableInt(dynamic value) {
  if (value == null || value.toString().isEmpty) return null;
  return _asInt(value);
}

double _asDouble(dynamic value, {double fallback = 0}) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

bool _asBool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;

  final text = value?.toString().trim().toLowerCase();

  if (text == 'true' || text == '1' || text == 'yes' || text == 'on') {
    return true;
  }

  if (text == 'false' || text == '0' || text == 'no' || text == 'off') {
    return false;
  }

  return fallback;
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

DateTime? _asDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value == null) return null;

  return DateTime.tryParse(value.toString());
}