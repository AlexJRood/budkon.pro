import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:core/platform/api_services.dart';

import '../config/automation_studio_config.dart';
import '../models/automation_catalog.dart';
import '../models/automation_common.dart';
import '../models/automation_event.dart';
import '../models/automation_run.dart';
import '../models/automation_workflow.dart';
import 'urls.dart';

class AutomationApiService {
  final AutomationStudioConfig config;

  /// WidgetRef/dynamic ref is passed into ApiServices so it can attach f-path
  /// and use your failed request queue.
  final dynamic ref;

  AutomationApiService({
    required this.config,
    this.ref,

    /// Backward-compatible constructor parameter. Requests are now routed
    /// through your shared ApiServices, not a local Dio instance.
    // ignore: avoid_unused_constructor_parameters
    Dio? dio,
  });

  Map<String, String> _headers() {
    return Map<String, String>.from(config.defaultHeaders);
  }

  bool get _hasToken => config.useTokenAuthHeader;

  dynamic _normalizeData(dynamic raw) {
    if (raw == null) return null;

    if (raw is Response) {
      return _normalizeData(raw.data);
    }

    if (raw is Map<String, dynamic>) {
      return raw;
    }

    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }

    if (raw is List) {
      return raw;
    }

    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return null;

      try {
        return _normalizeData(jsonDecode(trimmed));
      } catch (_) {
        return raw;
      }
    }

    if (raw is List<int>) {
      if (raw.isEmpty) return null;

      try {
        return _normalizeData(jsonDecode(utf8.decode(raw)));
      } catch (_) {
        return raw;
      }
    }

    return raw;
  }

  int? _statusCode(dynamic response) {
    if (response == null) return null;

    if (response is Response) {
      return response.statusCode;
    }

    if (response is Map) {
      final dynamic value = response['statusCode'] ?? response['status_code'];
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
    }

    return null;
  }

  String _errorMessageFromData(dynamic data, String fallback) {
    final normalized = _normalizeData(data);

    if (normalized is Map) {
      final dynamic detail =
          normalized['detail'] ?? normalized['error'] ?? normalized['message'];

      if (detail != null && detail.toString().trim().isNotEmpty) {
        return detail.toString();
      }

      final dynamic nonFieldErrors =
          normalized['non_field_errors'] ?? normalized['errors'];

      if (nonFieldErrors != null) {
        return nonFieldErrors.toString();
      }
    }

    return fallback;
  }

  dynamic _requireSuccess(dynamic response, String endpoint) {
    if (response == null) {
      throw Exception('Automation API request failed: $endpoint');
    }

    final statusCode = _statusCode(response);
    final data = _normalizeData(response);

    if (statusCode != null && statusCode >= 400) {
      throw Exception(
        _errorMessageFromData(
          data,
          'Automation API request failed with status $statusCode: $endpoint',
        ),
      );
    }

    return data;
  }

  Map<String, dynamic> _mapFrom(dynamic data, String endpoint) {
    final normalized = _normalizeData(data);

    if (normalized is Map<String, dynamic>) {
      return normalized;
    }

    if (normalized is Map) {
      return Map<String, dynamic>.from(normalized);
    }

    throw Exception('Automation API expected object response: $endpoint');
  }

  List<Map<String, dynamic>> _listFrom(dynamic data) {
    final normalized = _normalizeData(data);

    if (normalized is List) {
      return normalized
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    if (normalized is Map && normalized['results'] is List) {
      return (normalized['results'] as List)
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    if (normalized is Map && normalized['data'] is List) {
      return (normalized['data'] as List)
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    return const [];
  }

  Future<dynamic> _get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await ApiServices.get(
      endpoint,
      headers: _headers(),
      queryParameters: queryParameters,
      hasToken: _hasToken,
      responseType: ResponseType.json,
      ref: ref,
    );

    return _requireSuccess(response, endpoint);
  }

  Future<dynamic> _post(
    String endpoint, {
    Map<String, dynamic>? data,
  }) async {
    final response = await ApiServices.post(
      endpoint,
      headers: _headers(),
      data: data,
      hasToken: _hasToken,
      responseType: ResponseType.json,
      ref: ref,
    );

    return _requireSuccess(response, endpoint);
  }

  Future<dynamic> _patch(
    String endpoint, {
    dynamic data,
  }) async {
    final response = await ApiServices.patch(
      endpoint,
      headers: _headers(),
      data: data,
      hasToken: _hasToken,
      ref: ref,
    );

    return _requireSuccess(response, endpoint);
  }

  Future<dynamic> _delete(String endpoint) async {
    final response = await ApiServices.delete(
      endpoint,
      headers: _headers(),
      hasToken: _hasToken,
    );

    return _requireSuccess(response, endpoint);
  }

  Future<AutomationCatalog> fetchCatalog() async {
    final endpoint = AutomationURLs.catalog;
    final data = await _get(endpoint);

    return AutomationCatalog.fromJson(_mapFrom(data, endpoint));
  }

  Future<List<AutomationWorkflow>> fetchWorkflows({
    AutomationScopeType? scopeType,
    int? companyId,
    int? ownerId,
    String? status,
  }) async {
    final endpoint = AutomationURLs.workflows;

    final data = await _get(
      endpoint,
      queryParameters: {
        if (scopeType != null) 'scope_type': enumName(scopeType),
        if (companyId != null) 'company_id': companyId,
        if (ownerId != null) 'owner_id': ownerId,
        if (status != null) 'status': status,
      },
    );

    return _listFrom(data).map(AutomationWorkflow.fromJson).toList();
  }

  Future<AutomationWorkflow> fetchWorkflow(String id) async {
    final endpoint = AutomationURLs.workflowDetail(id);
    final data = await _get(endpoint);

    return AutomationWorkflow.fromJson(_mapFrom(data, endpoint));
  }

  Future<AutomationWorkflow> createWorkflow(
    AutomationWorkflow workflow,
  ) async {
    final endpoint = AutomationURLs.workflows;

    final data = await _post(
      endpoint,
      data: workflow.toJsonForSave(),
    );

    return AutomationWorkflow.fromJson(_mapFrom(data, endpoint));
  }

  Future<AutomationWorkflow> updateWorkflow(
    AutomationWorkflow workflow,
  ) async {
    final endpoint = AutomationURLs.workflowDetail(workflow.id);

    final data = await _patch(
      endpoint,
      data: workflow.toJsonForSave(),
    );

    return AutomationWorkflow.fromJson(_mapFrom(data, endpoint));
  }

  Future<AutomationWorkflow> activateWorkflow(String id) async {
    final endpoint = AutomationURLs.activateWorkflow(id);
    final data = await _post(endpoint);

    return AutomationWorkflow.fromJson(_mapFrom(data, endpoint));
  }

  Future<AutomationWorkflow> deactivateWorkflow(String id) async {
    final endpoint = AutomationURLs.deactivateWorkflow(id);
    final data = await _post(endpoint);

    return AutomationWorkflow.fromJson(_mapFrom(data, endpoint));
  }

  Future<void> deleteWorkflow(String id) async {
    await _delete(AutomationURLs.workflowDetail(id));
  }

  Future<Map<String, dynamic>> testWorkflow({
    required String id,
    String? signalKey,
    Map<String, dynamic> payload = const {},
  }) async {
    final endpoint = AutomationURLs.testWorkflow(id);

    final data = await _post(
      endpoint,
      data: {
        if (signalKey != null) 'signal_key': signalKey,
        'payload': payload,
      },
    );

    return _mapFrom(data, endpoint);
  }

  Future<List<AutomationRun>> fetchRuns({
    String? workflowId,
    int limit = 50,
  }) async {
    final endpoint = AutomationURLs.runs;

    final data = await _get(
      endpoint,
      queryParameters: {
        if (workflowId != null) 'workflow': workflowId,
        'limit': limit,
      },
    );

    return _listFrom(data).map(AutomationRun.fromJson).toList();
  }

  Future<AutomationRun> fetchRun(String runId) async {
    final data = await _get(AutomationURLs.runDetail(runId));
    return AutomationRun.fromJson(_mapFrom(data, AutomationURLs.runDetail(runId)));
  }

  Future<List<AutomationEventLog>> fetchEvents({
    String? signalKey,
    int limit = 50,
  }) async {
    final endpoint = AutomationURLs.events;

    final data = await _get(
      endpoint,
      queryParameters: {
        if (signalKey != null) 'signal_key': signalKey,
        'limit': limit,
      },
    );

    return _listFrom(data).map(AutomationEventLog.fromJson).toList();
  }

  Future<List<Map<String, dynamic>>> fetchApprovals({
    String status = 'pending',
  }) async {
    final endpoint = AutomationURLs.approvals;

    final data = await _get(
      endpoint,
      queryParameters: {
        'status': status,
      },
    );

    return _listFrom(data);
  }

  Future<Map<String, dynamic>> respondApproval({
    required String approvalId,
    required bool approved,
    Map<String, dynamic> responsePayload = const {},
  }) async {
    final endpoint = AutomationURLs.respondApproval(approvalId);

    final data = await _post(
      endpoint,
      data: {
        'status': approved ? 'approved' : 'rejected',
        'response_payload': responsePayload,
      },
    );

    return _mapFrom(data, endpoint);
  }
}