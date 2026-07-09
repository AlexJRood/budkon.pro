// crm/calendar/provider/member_calendar_layer_provider.dart

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';

class MemberCalendarLayerUrls {
  static String memberCalendarLayer(int memberId) {
    return 'https://www.superbee.cloud/event/event/member/$memberId/calendar-layer/';
  }

  static const String teamAvailabilityLayer =
      'https://www.superbee.cloud/event/event/team/availability-layer/';

  // Full HR availability endpoint used as the first fallback. It supports rules,
  // overrides, time entries, absences and public holidays.
  static const String hrFullAvailability =
      'https://www.superbee.cloud/finance/compensation/availability/calendar/';

  // Stable HR fallback endpoint used when /event/event/... layer is not deployed.
  static const String hrAbsenceAvailability =
      'https://www.superbee.cloud/finance/compensation/absences/availability/';

  // Stable HR dashboard fallback for today's availability summary.
  static const String employeeManagementDashboard =
      'https://www.superbee.cloud/finance/compensation/employee-management-dashboard/';
}

class MemberCalendarLayerParams {
  final int memberId;
  final DateTime rangeStart;
  final DateTime rangeEnd;
  final int? companyId;
  final bool includeEvents;
  final bool includeAvailability;
  final bool includePending;
  final bool includeRules;
  final bool includeAbsences;
  final bool includeOverrides;
  final bool includeTimeEntries;
  final bool includePublicHolidays;
  final bool skipRulesOnPublicHolidays;
  final String publicHolidayCountry;

  const MemberCalendarLayerParams({
    required this.memberId,
    required this.rangeStart,
    required this.rangeEnd,
    this.companyId,
    this.includeEvents = true,
    this.includeAvailability = true,
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
        'range_start': rangeStart.toIso8601String(),
        'range_end': rangeEnd.toIso8601String(),
        'include_events': includeEvents ? 'true' : 'false',
        'include_availability': includeAvailability ? 'true' : 'false',
        'include_pending': includePending ? 'true' : 'false',
        'include_rules': includeRules ? 'true' : 'false',
        'include_absences': includeAbsences ? 'true' : 'false',
        'include_overrides': includeOverrides ? 'true' : 'false',
        'include_time_entries': includeTimeEntries ? 'true' : 'false',
        'include_public_holidays': includePublicHolidays ? 'true' : 'false',
        'skip_rules_on_public_holidays':
            skipRulesOnPublicHolidays ? 'true' : 'false',
        'public_holiday_country': publicHolidayCountry,
        if (companyId != null) 'company_id': companyId.toString(),
      };

  Map<String, String> toHrAvailabilityQueryParameters() => {
        'start': _dateOnly(rangeStart),
        'end': _dateOnly(rangeEnd),
        'include_pending': includePending ? 'true' : 'false',
        'include_rules': includeRules ? 'true' : 'false',
        'include_absences': includeAbsences ? 'true' : 'false',
        'include_overrides': includeOverrides ? 'true' : 'false',
        'include_time_entries': includeTimeEntries ? 'true' : 'false',
        'include_public_holidays': includePublicHolidays ? 'true' : 'false',
        'skip_rules_on_public_holidays':
            skipRulesOnPublicHolidays ? 'true' : 'false',
        'public_holiday_country': publicHolidayCountry,
        'employee_id': memberId.toString(),
      };

  @override
  bool operator ==(Object other) {
    return other is MemberCalendarLayerParams &&
        other.memberId == memberId &&
        other.rangeStart == rangeStart &&
        other.rangeEnd == rangeEnd &&
        other.companyId == companyId &&
        other.includeEvents == includeEvents &&
        other.includeAvailability == includeAvailability &&
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
        memberId,
        rangeStart,
        rangeEnd,
        companyId,
        includeEvents,
        includeAvailability,
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

class TeamAvailabilityLayerParams {
  final DateTime rangeStart;
  final DateTime rangeEnd;
  final int? companyId;
  final List<int> employeeIds;
  final bool bootstrapDefaults;
  final bool includePending;
  final bool includeRules;
  final bool includeAbsences;
  final bool includeOverrides;
  final bool includeTimeEntries;
  final bool includePublicHolidays;
  final bool skipRulesOnPublicHolidays;
  final String publicHolidayCountry;

  const TeamAvailabilityLayerParams({
    required this.rangeStart,
    required this.rangeEnd,
    this.companyId,
    this.employeeIds = const [],
    this.bootstrapDefaults = false,
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
        'range_start': rangeStart.toIso8601String(),
        'range_end': rangeEnd.toIso8601String(),
        'bootstrap_defaults': bootstrapDefaults ? 'true' : 'false',
        'include_pending': includePending ? 'true' : 'false',
        'include_rules': includeRules ? 'true' : 'false',
        'include_absences': includeAbsences ? 'true' : 'false',
        'include_overrides': includeOverrides ? 'true' : 'false',
        'include_time_entries': includeTimeEntries ? 'true' : 'false',
        'include_public_holidays': includePublicHolidays ? 'true' : 'false',
        'skip_rules_on_public_holidays':
            skipRulesOnPublicHolidays ? 'true' : 'false',
        'public_holiday_country': publicHolidayCountry,
        if (companyId != null) 'company_id': companyId.toString(),
        if (employeeIds.isNotEmpty) 'employee_ids': employeeIds.join(','),
      };

  Map<String, String> toHrAvailabilityQueryParameters() => {
        'start': _dateOnly(rangeStart),
        'end': _dateOnly(rangeEnd),
        'include_pending': includePending ? 'true' : 'false',
        'include_rules': includeRules ? 'true' : 'false',
        'include_absences': includeAbsences ? 'true' : 'false',
        'include_overrides': includeOverrides ? 'true' : 'false',
        'include_time_entries': includeTimeEntries ? 'true' : 'false',
        'include_public_holidays': includePublicHolidays ? 'true' : 'false',
        'skip_rules_on_public_holidays':
            skipRulesOnPublicHolidays ? 'true' : 'false',
        'public_holiday_country': publicHolidayCountry,
        if (employeeIds.length == 1) 'employee_id': employeeIds.first.toString(),
      };

  @override
  bool operator ==(Object other) {
    return other is TeamAvailabilityLayerParams &&
        other.rangeStart == rangeStart &&
        other.rangeEnd == rangeEnd &&
        other.companyId == companyId &&
        _sameIds(other.employeeIds, employeeIds) &&
        other.bootstrapDefaults == bootstrapDefaults &&
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
        rangeStart,
        rangeEnd,
        companyId,
        Object.hashAll(employeeIds),
        bootstrapDefaults,
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

class CalendarLayerItemModel {
  final String id;
  final String layer;
  final String source;
  final String? sourceId;
  final int? employeeId;
  final String employeeName;
  final String title;
  final String kind;
  final String status;
  final DateTime startAt;
  final DateTime endAt;
  final String color;
  final int priority;
  final bool blocksBooking;
  final bool isBookable;
  final bool canEdit;
  final String shareMode;
  final String tooltip;
  final Map<String, dynamic> metadata;
  final Map<String, dynamic> raw;

  const CalendarLayerItemModel({
    required this.id,
    required this.layer,
    required this.source,
    required this.sourceId,
    required this.employeeId,
    required this.employeeName,
    required this.title,
    required this.kind,
    required this.status,
    required this.startAt,
    required this.endAt,
    required this.color,
    required this.priority,
    required this.blocksBooking,
    required this.isBookable,
    required this.canEdit,
    required this.shareMode,
    required this.tooltip,
    required this.metadata,
    required this.raw,
  });

  bool get isEvent => layer == 'event';
  bool get isAvailability => layer == 'availability';
  bool get isAbsence => source == 'absence';
  bool get isRule => source == 'availability_rule';
  bool get isPublicHoliday => source == 'public_holiday' || kind == 'public_holiday';
  bool get isPrivateBusy => shareMode == 'busy';

  Color get displayColor => _hexToColor(color);

  factory CalendarLayerItemModel.fromJson(Map<String, dynamic> json) {
    final normalized = _normalizeLayerItemJson(json);

    final layer = _asString(
      normalized['layer'],
      fallback: _inferLayer(normalized),
    );

    final source = _asString(
      normalized['source'],
      fallback: _inferSource(normalized),
    );

    final startAt = _parseStartAt(normalized) ?? DateTime.now();
    final endAt = _parseEndAt(normalized, startAt) ??
        startAt.add(const Duration(hours: 1));

    final blocksBooking = _asBool(
      normalized['blocks_booking'] ?? normalized['blocks_availability'],
      fallback: _defaultBlocksBooking(layer: layer, source: source),
    );

    final isBookable = _asBool(
      normalized['is_bookable'],
      fallback: layer == 'availability' && !blocksBooking,
    );

    final title = _asString(
      normalized['title'] ??
          normalized['label'] ??
          normalized['absence_type_name'] ??
          normalized['absence_type_key'] ??
          normalized['name'],
      fallback: layer == 'event'
          ? 'Zajęty'
          : blocksBooking
              ? 'Niedostępny'
              : 'Dostępny',
    );

    final sourceId = _asNullableString(
      normalized['source_id'] ??
          normalized['source_pk'] ??
          normalized['object_id'] ??
          normalized['id'],
    );

    final id = _asString(
      normalized['id'],
      fallback:
          '$layer-$source-${sourceId ?? 'local'}-${startAt.toIso8601String()}',
    );

    final kind = _asString(
      normalized['kind'] ??
          normalized['availability_kind'] ??
          normalized['absence_type_key'] ??
          normalized['type'],
      fallback: layer == 'event'
          ? 'busy'
          : blocksBooking
              ? 'blocked'
              : 'available',
    );

    final color = _asString(
      normalized['color'] ?? normalized['calendar_color'],
      fallback: _defaultColor(
        layer: layer,
        source: source,
        blocksBooking: blocksBooking,
        isBookable: isBookable,
      ),
    );

    return CalendarLayerItemModel(
      id: id,
      layer: layer,
      source: source,
      sourceId: sourceId,
      employeeId: _asNullableInt(
        normalized['employee_id'] ?? normalized['employee'] ?? normalized['member_id'],
      ),
      employeeName: _asString(
        normalized['employee_name'] ??
            normalized['member_name'] ??
            normalized['user_name'],
      ),
      title: title,
      kind: kind,
      status: _asString(normalized['status'], fallback: 'confirmed'),
      startAt: startAt,
      endAt: endAt,
      color: color,
      priority: _asInt(
        normalized['priority'],
        fallback: _defaultPriority(layer: layer, source: source),
      ),
      blocksBooking: blocksBooking,
      isBookable: isBookable,
      canEdit: _asBool(normalized['can_edit']),
      shareMode: _asString(
        normalized['share_mode'],
        fallback: layer == 'event' ? 'busy' : '',
      ),
      tooltip: _asString(
        normalized['tooltip'] ?? normalized['note'] ?? normalized['description'],
        fallback: title,
      ),
      metadata: Map<String, dynamic>.from(
        normalized['metadata'] is Map ? normalized['metadata'] : const {},
      ),
      raw: Map<String, dynamic>.from(
        normalized['raw'] is Map ? normalized['raw'] : json,
      ),
    );
  }
}

class MemberCalendarLayerModel {
  final Map<String, dynamic> member;
  final Map<String, dynamic> company;
  final DateTime? rangeStart;
  final DateTime? rangeEnd;
  final List<CalendarLayerItemModel> events;
  final List<CalendarLayerItemModel> availability;
  final List<CalendarLayerItemModel> items;

  const MemberCalendarLayerModel({
    required this.member,
    required this.company,
    required this.rangeStart,
    required this.rangeEnd,
    required this.events,
    required this.availability,
    required this.items,
  });

  factory MemberCalendarLayerModel.empty({
    required int memberId,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    int? companyId,
  }) {
    return MemberCalendarLayerModel(
      member: {'id': memberId},
      company: {
        if (companyId != null) 'id': companyId,
      },
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
      events: const <CalendarLayerItemModel>[],
      availability: const <CalendarLayerItemModel>[],
      items: const <CalendarLayerItemModel>[],
    );
  }

  factory MemberCalendarLayerModel.fromJson(Map<String, dynamic> json) {
    final events = _decodeItems(
      json['events'],
      layerFallback: 'event',
      sourceFallback: 'event',
    );

    final availability = _decodeItems(
      json['availability'],
      layerFallback: 'availability',
      sourceFallback: 'availability',
    );

    final decodedItems = _decodeItems(json['items']);

    final items = decodedItems.isNotEmpty
        ? decodedItems
        : _sortItems([...events, ...availability]);

    return MemberCalendarLayerModel(
      member: Map<String, dynamic>.from(
        json['member'] is Map ? json['member'] : const {},
      ),
      company: Map<String, dynamic>.from(
        json['company'] is Map ? json['company'] : const {},
      ),
      rangeStart: _asDateTime(json['range_start']),
      rangeEnd: _asDateTime(json['range_end']),
      events: events,
      availability: availability,
      items: items,
    );
  }
}

class MemberCalendarLayerNotifier
    extends StateNotifier<AsyncValue<MemberCalendarLayerModel>> {
  final Ref ref;
  final MemberCalendarLayerParams params;

  MemberCalendarLayerNotifier(this.ref, this.params)
      : super(const AsyncValue.loading()) {
    Future.microtask(fetch);
  }

  Future<void> fetch({bool showLoading = true}) async {
    try {
      if (showLoading) state = const AsyncValue.loading();

      final model = await _fetchMemberCalendarLayer(
        ref: ref,
        params: params,
      );

      state = AsyncValue.data(model);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

class TeamAvailabilityLayerNotifier
    extends StateNotifier<AsyncValue<List<CalendarLayerItemModel>>> {
  final Ref ref;
  final TeamAvailabilityLayerParams params;

  TeamAvailabilityLayerNotifier(this.ref, this.params)
      : super(const AsyncValue.loading()) {
    Future.microtask(fetch);
  }

  Future<void> fetch({bool showLoading = true}) async {
    try {
      if (showLoading) state = const AsyncValue.loading();

      final items = await _fetchTeamAvailabilityLayer(
        ref: ref,
        params: params,
      );

      state = AsyncValue.data(items);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final memberCalendarLayerProvider = StateNotifierProvider.family<
    MemberCalendarLayerNotifier,
    AsyncValue<MemberCalendarLayerModel>,
    MemberCalendarLayerParams>(
  (ref, params) => MemberCalendarLayerNotifier(ref, params),
);

final teamAvailabilityLayerProvider = StateNotifierProvider.family<
    TeamAvailabilityLayerNotifier,
    AsyncValue<List<CalendarLayerItemModel>>,
    TeamAvailabilityLayerParams>(
  (ref, params) => TeamAvailabilityLayerNotifier(ref, params),
);

Future<MemberCalendarLayerModel> _fetchMemberCalendarLayer({
  required Ref ref,
  required MemberCalendarLayerParams params,
}) async {
  final layerDecoded = await _tryGetDecoded(
    ref: ref,
    url: MemberCalendarLayerUrls.memberCalendarLayer(params.memberId),
    queryParameters: params.toQueryParameters(),
  );

  final layerMap = _decodeMap(layerDecoded);

  if (_hasCalendarLayerData(layerMap)) {
    final model = MemberCalendarLayerModel.fromJson(layerMap);

    return _filterMemberModelByParams(
      model: model,
      params: params,
    );
  }

  if (params.includeAvailability) {
    var hrDecoded = await _tryGetDecoded(
      ref: ref,
      url: MemberCalendarLayerUrls.hrFullAvailability,
      queryParameters: params.toHrAvailabilityQueryParameters(),
    );

    var hrItems = _decodeItems(
      _extractItemList(hrDecoded),
      layerFallback: 'availability',
      sourceFallback: 'availability',
      employeeIdFallback: params.memberId,
      rangeStartFallback: params.rangeStart,
      rangeEndFallback: params.rangeEnd,
    );

    if (hrItems.isEmpty) {
      hrDecoded = await _tryGetDecoded(
        ref: ref,
        url: MemberCalendarLayerUrls.hrAbsenceAvailability,
        queryParameters: params.toHrAvailabilityQueryParameters(),
      );

      hrItems = _decodeItems(
        _extractItemList(hrDecoded),
        layerFallback: 'availability',
        sourceFallback: 'absence',
        employeeIdFallback: params.memberId,
        rangeStartFallback: params.rangeStart,
        rangeEndFallback: params.rangeEnd,
      );
    }

    if (hrItems.isNotEmpty) {
      final availability = _filterItemsByMemberAndRange(
        items: hrItems,
        memberId: params.memberId,
        rangeStart: params.rangeStart,
        rangeEnd: params.rangeEnd,
      );

      return MemberCalendarLayerModel(
        member: {'id': params.memberId},
        company: {
          if (params.companyId != null) 'id': params.companyId,
        },
        rangeStart: params.rangeStart,
        rangeEnd: params.rangeEnd,
        events: const <CalendarLayerItemModel>[],
        availability: availability,
        items: _sortItems(availability),
      );
    }

    final dashboardDecoded = await _tryGetDecoded(
      ref: ref,
      url: MemberCalendarLayerUrls.employeeManagementDashboard,
      queryParameters: {
        'period': _periodFromDate(params.rangeStart),
        'currency': 'PLN',
      },
    );

    final dashboardModel = _buildMemberModelFromDashboard(
      decoded: dashboardDecoded,
      params: params,
    );

    if (dashboardModel.items.isNotEmpty) {
      return dashboardModel;
    }
  }

  return MemberCalendarLayerModel.empty(
    memberId: params.memberId,
    rangeStart: params.rangeStart,
    rangeEnd: params.rangeEnd,
    companyId: params.companyId,
  );
}

Future<List<CalendarLayerItemModel>> _fetchTeamAvailabilityLayer({
  required Ref ref,
  required TeamAvailabilityLayerParams params,
}) async {
  final layerDecoded = await _tryGetDecoded(
    ref: ref,
    url: MemberCalendarLayerUrls.teamAvailabilityLayer,
    queryParameters: params.toQueryParameters(),
  );

  final layerItems = _decodeItems(
    _extractItemList(layerDecoded),
    layerFallback: 'availability',
    sourceFallback: 'availability',
  );

  if (layerItems.isNotEmpty) {
    return _filterItemsByEmployeesAndRange(
      items: layerItems,
      employeeIds: params.employeeIds,
      rangeStart: params.rangeStart,
      rangeEnd: params.rangeEnd,
    );
  }

  var hrDecoded = await _tryGetDecoded(
    ref: ref,
    url: MemberCalendarLayerUrls.hrFullAvailability,
    queryParameters: params.toHrAvailabilityQueryParameters(),
  );

  var hrItems = _decodeItems(
    _extractItemList(hrDecoded),
    layerFallback: 'availability',
    sourceFallback: 'availability',
    rangeStartFallback: params.rangeStart,
    rangeEndFallback: params.rangeEnd,
  );

  if (hrItems.isEmpty) {
    hrDecoded = await _tryGetDecoded(
      ref: ref,
      url: MemberCalendarLayerUrls.hrAbsenceAvailability,
      queryParameters: params.toHrAvailabilityQueryParameters(),
    );

    hrItems = _decodeItems(
      _extractItemList(hrDecoded),
      layerFallback: 'availability',
      sourceFallback: 'absence',
      rangeStartFallback: params.rangeStart,
      rangeEndFallback: params.rangeEnd,
    );
  }

  return _filterItemsByEmployeesAndRange(
    items: hrItems,
    employeeIds: params.employeeIds,
    rangeStart: params.rangeStart,
    rangeEnd: params.rangeEnd,
  );
}

Future<dynamic> _tryGetDecoded({
  required Ref ref,
  required String url,
  Map<String, dynamic>? queryParameters,
}) async {
  try {
    final response = await ApiServices.get(
      url,
      ref: ref,
      hasToken: true,
      responseType: ResponseType.json,
      queryParameters: queryParameters,
    );

    if (!_isSuccessResponse(response)) {
      return null;
    }

    return _decodeDynamic(response?.data);
  } catch (_) {
    return null;
  }
}

MemberCalendarLayerModel _filterMemberModelByParams({
  required MemberCalendarLayerModel model,
  required MemberCalendarLayerParams params,
}) {
  final events = params.includeEvents
      ? _filterItemsByMemberAndRange(
          items: model.events,
          memberId: params.memberId,
          rangeStart: params.rangeStart,
          rangeEnd: params.rangeEnd,
        )
      : const <CalendarLayerItemModel>[];

  final availability = params.includeAvailability
      ? _filterItemsByMemberAndRange(
          items: model.availability,
          memberId: params.memberId,
          rangeStart: params.rangeStart,
          rangeEnd: params.rangeEnd,
        )
      : const <CalendarLayerItemModel>[];

  final allItems = model.items.isNotEmpty
      ? _filterItemsByMemberAndRange(
          items: model.items.where((item) {
            if (item.isEvent && !params.includeEvents) return false;
            if (item.isAvailability && !params.includeAvailability) return false;
            return true;
          }).toList(growable: false),
          memberId: params.memberId,
          rangeStart: params.rangeStart,
          rangeEnd: params.rangeEnd,
        )
      : _sortItems([...events, ...availability]);

  return MemberCalendarLayerModel(
    member: model.member.isNotEmpty ? model.member : {'id': params.memberId},
    company: model.company.isNotEmpty
        ? model.company
        : {
            if (params.companyId != null) 'id': params.companyId,
          },
    rangeStart: model.rangeStart ?? params.rangeStart,
    rangeEnd: model.rangeEnd ?? params.rangeEnd,
    events: events,
    availability: availability,
    items: allItems,
  );
}

MemberCalendarLayerModel _buildMemberModelFromDashboard({
  required dynamic decoded,
  required MemberCalendarLayerParams params,
}) {
  final data = _decodeMap(decoded);
  final employeeJson = _findEmployeeJson(data, params.memberId);

  if (employeeJson.isEmpty) {
    return MemberCalendarLayerModel.empty(
      memberId: params.memberId,
      rangeStart: params.rangeStart,
      rangeEnd: params.rangeEnd,
      companyId: params.companyId,
    );
  }

  final today = DateTime.now();
  final todayStart = DateTime(today.year, today.month, today.day);
  final todayEnd = todayStart.add(const Duration(days: 1));

  if (!_rangesOverlap(
    startA: params.rangeStart,
    endA: params.rangeEnd,
    startB: todayStart,
    endB: todayEnd,
  )) {
    return MemberCalendarLayerModel.empty(
      memberId: params.memberId,
      rangeStart: params.rangeStart,
      rangeEnd: params.rangeEnd,
      companyId: params.companyId,
    );
  }

  final userJson = _asMap(employeeJson['user']);
  final employeeName = _resolveEmployeeName(
    userJson: userJson,
    employeeJson: employeeJson,
  );

  final availabilitySummary = _asMap(employeeJson['availability_summary']);

  final blockingToday = _decodeItems(
    availabilitySummary['blocking_today'],
    layerFallback: 'availability',
    sourceFallback: 'availability_summary',
    employeeIdFallback: params.memberId,
    employeeNameFallback: employeeName,
    rangeStartFallback: todayStart,
    rangeEndFallback: todayEnd,
  );

  final bookableToday = _decodeItems(
    availabilitySummary['bookable_today'],
    layerFallback: 'availability',
    sourceFallback: 'availability_summary',
    employeeIdFallback: params.memberId,
    employeeNameFallback: employeeName,
    rangeStartFallback: todayStart,
    rangeEndFallback: todayEnd,
  );

  final availability = _sortItems([...blockingToday, ...bookableToday]);

  return MemberCalendarLayerModel(
    member: {
      'id': params.memberId,
      'name': employeeName,
      ...userJson,
    },
    company: _asMap(data['company']).isNotEmpty
        ? _asMap(data['company'])
        : {
            if (params.companyId != null) 'id': params.companyId,
          },
    rangeStart: params.rangeStart,
    rangeEnd: params.rangeEnd,
    events: const <CalendarLayerItemModel>[],
    availability: availability,
    items: params.includeAvailability ? availability : const <CalendarLayerItemModel>[],
  );
}

Map<String, dynamic> _findEmployeeJson(
  Map<String, dynamic> dashboardData,
  int memberId,
) {
  final employees = _asList(dashboardData['employees']);

  for (final item in employees) {
    if (item is! Map) continue;

    final json = Map<String, dynamic>.from(item);
    final userJson = _asMap(json['user']);

    final userId = _asNullableInt(userJson['id']);
    final employeeId = _asNullableInt(
      json['employee_id'] ?? json['member_id'] ?? json['id'],
    );

    if (userId == memberId || employeeId == memberId) {
      return json;
    }
  }

  return <String, dynamic>{};
}

String _resolveEmployeeName({
  required Map<String, dynamic> userJson,
  required Map<String, dynamic> employeeJson,
}) {
  final fullName = _asString(userJson['full_name']);
  if (fullName.isNotEmpty) return fullName;

  final firstName = _asString(userJson['first_name']);
  final lastName = _asString(userJson['last_name']);
  final joined = '$firstName $lastName'.trim();
  if (joined.isNotEmpty) return joined;

  final username = _asString(userJson['username']);
  if (username.isNotEmpty) return username;

  final email = _asString(userJson['email']);
  if (email.isNotEmpty) return email;

  final directName = _asString(
    employeeJson['employee_name'] ?? employeeJson['member_name'] ?? employeeJson['name'],
  );
  if (directName.isNotEmpty) return directName;

  return '';
}

List<CalendarLayerItemModel> collapseCalendarAvailabilityRules(
  List<CalendarLayerItemModel> items,
) {
  return items.where((item) {
    if (!item.isRule) return true;

    return !items.any((other) {
      final appliesToSameEmployee =
          other.employeeId == item.employeeId || other.isPublicHoliday;
      if (!appliesToSameEmployee) return false;
      if (other.priority <= item.priority) return false;
      if (!other.blocksBooking) return false;

      return other.startAt.isBefore(item.endAt) &&
          other.endAt.isAfter(item.startAt);
    });
  }).toList(growable: false);
}

List<CalendarLayerItemModel> _decodeItems(
  dynamic value, {
  String? layerFallback,
  String? sourceFallback,
  int? employeeIdFallback,
  String? employeeNameFallback,
  DateTime? rangeStartFallback,
  DateTime? rangeEndFallback,
}) {
  final list = value is List ? value : const [];

  return _sortItems(
    list.whereType<Map>().map((item) {
      final json = Map<String, dynamic>.from(item);

      if (layerFallback != null) {
        json['layer'] ??= layerFallback;
      }

      if (sourceFallback != null) {
        json['source'] ??= sourceFallback;
      }

      if (employeeIdFallback != null) {
        json['employee_id'] ??= employeeIdFallback;
        json['employee'] ??= employeeIdFallback;
      }

      if (employeeNameFallback != null && employeeNameFallback.isNotEmpty) {
        json['employee_name'] ??= employeeNameFallback;
      }

      if (rangeStartFallback != null) {
        json['start_at'] ??= rangeStartFallback.toIso8601String();
        json['start_time'] ??= rangeStartFallback.toIso8601String();
      }

      if (rangeEndFallback != null) {
        json['end_at'] ??= rangeEndFallback.toIso8601String();
        json['end_time'] ??= rangeEndFallback.toIso8601String();
      }

      return CalendarLayerItemModel.fromJson(json);
    }).toList(growable: false),
  );
}

List<CalendarLayerItemModel> _filterItemsByMemberAndRange({
  required List<CalendarLayerItemModel> items,
  required int memberId,
  required DateTime rangeStart,
  required DateTime rangeEnd,
}) {
  return _sortItems(
    items.where((item) {
      final belongsToMember = item.employeeId == null || item.employeeId == memberId;

      if (!belongsToMember) return false;

      return _rangesOverlap(
        startA: item.startAt,
        endA: item.endAt,
        startB: rangeStart,
        endB: rangeEnd,
      );
    }).toList(growable: false),
  );
}

List<CalendarLayerItemModel> _filterItemsByEmployeesAndRange({
  required List<CalendarLayerItemModel> items,
  required List<int> employeeIds,
  required DateTime rangeStart,
  required DateTime rangeEnd,
}) {
  return _sortItems(
    items.where((item) {
      final belongsToEmployee = employeeIds.isEmpty ||
          item.employeeId == null ||
          employeeIds.contains(item.employeeId);

      if (!belongsToEmployee) return false;

      return _rangesOverlap(
        startA: item.startAt,
        endA: item.endAt,
        startB: rangeStart,
        endB: rangeEnd,
      );
    }).toList(growable: false),
  );
}

List<CalendarLayerItemModel> _sortItems(List<CalendarLayerItemModel> items) {
  final sorted = _dedupeItems(items);

  sorted.sort((a, b) {
    final startCompare = a.startAt.compareTo(b.startAt);
    if (startCompare != 0) return startCompare;

    return b.priority.compareTo(a.priority);
  });

  return sorted;
}

List<CalendarLayerItemModel> _dedupeItems(List<CalendarLayerItemModel> items) {
  final seen = <String>{};
  final result = <CalendarLayerItemModel>[];

  for (final item in items) {
    final key = [
      item.id,
      item.layer,
      item.source,
      item.sourceId ?? '',
      item.employeeId?.toString() ?? '',
      item.startAt.toIso8601String(),
      item.endAt.toIso8601String(),
    ].join('|');

    if (seen.add(key)) {
      result.add(item);
    }
  }

  return result;
}

List<dynamic> _extractItemList(dynamic decoded) {
  final value = _unwrapData(decoded);

  if (value is List) return value;

  if (value is Map) {
    final map = Map<String, dynamic>.from(value);

    for (final key in const [
      'items',
      'results',
      'events',
      'availability',
      'blocks',
      'data',
    ]) {
      final candidate = map[key];

      if (candidate is List) return candidate;

      if (candidate is Map) {
        final nested = _extractItemList(candidate);
        if (nested.isNotEmpty) return nested;
      }
    }

    final flattened = <dynamic>[];

    for (final entry in map.values) {
      if (entry is List && entry.whereType<Map>().isNotEmpty) {
        flattened.addAll(entry);
      }

      if (entry is Map) {
        final nested = _extractItemList(entry);
        if (nested.isNotEmpty) flattened.addAll(nested);
      }
    }

    return flattened;
  }

  return const [];
}

Map<String, dynamic> _decodeMap(dynamic data) {
  final decoded = _unwrapData(_decodeDynamic(data));

  if (decoded is Map<String, dynamic>) return decoded;
  if (decoded is Map) return Map<String, dynamic>.from(decoded);

  return <String, dynamic>{};
}

dynamic _decodeDynamic(dynamic data) {
  if (data == null) return null;

  if (data is List<int>) {
    try {
      return jsonDecode(utf8.decode(data));
    } catch (_) {
      return null;
    }
  }

  if (data is String) {
    final trimmed = data.trim();

    if (trimmed.isEmpty) return null;

    try {
      return jsonDecode(trimmed);
    } catch (_) {
      return data;
    }
  }

  return data;
}

dynamic _unwrapData(dynamic data) {
  if (data is Map && data['data'] != null) {
    return data['data'];
  }

  return data;
}

bool _hasCalendarLayerData(Map<String, dynamic> data) {
  if (data.isEmpty) return false;

  final items = _asList(data['items']);
  final events = _asList(data['events']);
  final availability = _asList(data['availability']);

  return items.isNotEmpty || events.isNotEmpty || availability.isNotEmpty;
}

bool _isSuccessResponse(dynamic response) {
  final code = response?.statusCode;

  return code != null && code >= 200 && code < 300;
}

Map<String, dynamic> _normalizeLayerItemJson(Map<String, dynamic> json) {
  final normalized = Map<String, dynamic>.from(json);

  normalized['employee_id'] ??=
      normalized['employee'] ?? normalized['member_id'] ?? normalized['user_id'];

  normalized['employee_name'] ??=
      normalized['member_name'] ?? normalized['user_name'] ?? normalized['name'];

  normalized['start_at'] ??=
      normalized['start_time'] ?? normalized['start'] ?? normalized['starts_at'];

  normalized['end_at'] ??=
      normalized['end_time'] ?? normalized['end'] ?? normalized['ends_at'];

  normalized['start_at'] ??= normalized['start_date'];
  normalized['end_at'] ??= normalized['end_date'];

  normalized['title'] ??=
      normalized['label'] ??
      normalized['absence_type_name'] ??
      normalized['absence_type_key'];

  normalized['kind'] ??=
      normalized['availability_kind'] ??
      normalized['absence_type_key'] ??
      normalized['event_type'];

  normalized['color'] ??= normalized['calendar_color'];

  normalized['blocks_booking'] ??= normalized['blocks_availability'];

  if (normalized['is_bookable'] == null &&
      normalized['blocks_booking'] != null) {
    normalized['is_bookable'] = !_asBool(normalized['blocks_booking']);
  }

  normalized['metadata'] ??= <String, dynamic>{};
  normalized['raw'] ??= json;

  return normalized;
}

String _inferLayer(Map<String, dynamic> json) {
  final source = _asString(json['source']).toLowerCase();

  if (source.contains('event') ||
      json.containsKey('event_id') ||
      json.containsKey('start_time')) {
    return 'event';
  }

  return 'availability';
}

String _inferSource(Map<String, dynamic> json) {
  if (json.containsKey('absence_type_key') ||
      json.containsKey('absence_type_name') ||
      json.containsKey('absence')) {
    return 'absence';
  }

  if (json.containsKey('weekday') || json.containsKey('availability_rule')) {
    return 'availability_rule';
  }

  if (json.containsKey('event_id') || json.containsKey('start_time')) {
    return 'event';
  }

  return 'availability';
}

bool _defaultBlocksBooking({
  required String layer,
  required String source,
}) {
  if (layer == 'event') return true;
  if (source == 'absence') return true;
  if (source == 'work_time_entry') return true;

  return false;
}

String _defaultColor({
  required String layer,
  required String source,
  required bool blocksBooking,
  required bool isBookable,
}) {
  if (layer == 'event') return '#A855F7';
  if (source == 'absence') return '#F59E0B';
  if (isBookable) return '#22C55E';
  if (blocksBooking) return '#F59E0B';

  return '#64748B';
}

int _defaultPriority({
  required String layer,
  required String source,
}) {
  if (layer == 'event') return 100;
  if (source == 'absence') return 80;
  if (source == 'availability_rule') return 10;

  return 50;
}

DateTime? _parseStartAt(Map<String, dynamic> json) {
  final value = json['start_at'] ??
      json['start_time'] ??
      json['start'] ??
      json['start_date'];

  return _asDateTime(value);
}

DateTime? _parseEndAt(
  Map<String, dynamic> json,
  DateTime startAt,
) {
  final value = json['end_at'] ??
      json['end_time'] ??
      json['end'] ??
      json['end_date'];

  final parsed = _asDateTime(value);

  if (parsed == null) return null;

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

  if (!parsed.isAfter(startAt)) {
    return startAt.add(const Duration(hours: 1));
  }

  return parsed;
}

bool _rangesOverlap({
  required DateTime startA,
  required DateTime endA,
  required DateTime startB,
  required DateTime endB,
}) {
  return startA.isBefore(endB) && endA.isAfter(startB);
}

String _dateOnly(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');

  return '${value.year}-$month-$day';
}

String _periodFromDate(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');

  return '${value.year}-$month';
}

bool _looksLikeDateOnly(String value) {
  return RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value.trim());
}

bool _sameIds(List<int> a, List<int> b) {
  if (a.length != b.length) return false;

  for (var i = 0; i < a.length; i += 1) {
    if (a[i] != b[i]) return false;
  }

  return true;
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

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();

  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

int? _asNullableInt(dynamic value) {
  if (value == null) return null;

  final text = value.toString().trim();
  if (text.isEmpty) return null;

  return int.tryParse(text);
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

  final text = value.toString().trim();

  if (text.isEmpty) return null;

  return DateTime.tryParse(text);
}

Color _hexToColor(String value) {
  var hex = value.trim();

  if (hex.isEmpty) {
    return const Color(0xFF64748B);
  }

  if (!hex.startsWith('#')) hex = '#$hex';

  if (hex.length == 4) {
    final r = hex[1];
    final g = hex[2];
    final b = hex[3];
    hex = '#$r$r$g$g$b$b';
  }

  try {
    if (hex.length == 7) {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    }

    if (hex.length == 9) {
      return Color(int.parse(hex.replaceFirst('#', '0x')));
    }
  } catch (_) {}

  return const Color(0xFF64748B);
}