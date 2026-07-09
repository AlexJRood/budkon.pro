import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:core/platform/api_services.dart';

import '../models/automation_code_block.dart';
import '../models/automation_governance.dart';
import '../models/automation_template.dart';
import '../models/automation_workflow.dart';
import 'automation_api_service.dart';
import 'urls_new_features.dart';

extension AutomationApiServiceNewFeatures on AutomationApiService {
  Future<Map<String, dynamic>> assessWorkflowRisk(String id) async {
    final endpoint = AutomationNewFeatureURLs.workflowAssessRisk(id);
    return _nfMapFrom(await _nfPost(this, endpoint), endpoint);
  }

  Future<AutomationDryRunPlan> dryRunWorkflow(
    String id, {
    Map<String, dynamic> payload = const {},
  }) async {
    final endpoint = AutomationNewFeatureURLs.workflowDryRun(id);
    return AutomationDryRunPlan.fromJson(
      _nfMapFrom(
        await _nfPost(this, endpoint, data: {'payload': payload}),
        endpoint,
      ),
    );
  }

  Future<Map<String, dynamic>> requestWorkflowReview(String id, {String note = ''}) async {
    final endpoint = AutomationNewFeatureURLs.workflowRequestReview(id);
    return _nfMapFrom(await _nfPost(this, endpoint, data: {'note': note}), endpoint);
  }

  Future<Map<String, dynamic>> approveWorkflowReview(String id, {String note = ''}) async {
    final endpoint = AutomationNewFeatureURLs.workflowApproveReview(id);
    return _nfMapFrom(await _nfPost(this, endpoint, data: {'note': note}), endpoint);
  }

  Future<Map<String, dynamic>> rejectWorkflowReview(String id, {String note = ''}) async {
    final endpoint = AutomationNewFeatureURLs.workflowRejectReview(id);
    return _nfMapFrom(await _nfPost(this, endpoint, data: {'note': note}), endpoint);
  }

  Future<List<AutomationWorkflowReviewRequest>> fetchWorkflowReviews({
    String status = 'pending',
    int? companyId,
  }) async {
    final data = await _nfGet(
      this,
      AutomationNewFeatureURLs.workflowReviews,
      queryParameters: {
        'status': status,
        if (companyId != null) 'company': companyId,
      },
    );

    return _nfListFrom(data).map(AutomationWorkflowReviewRequest.fromJson).toList();
  }

  Future<Map<String, dynamic>> respondWorkflowReview({
    required String reviewId,
    required bool approved,
    String note = '',
  }) async {
    final endpoint = AutomationNewFeatureURLs.respondWorkflowReview(reviewId);
    return _nfMapFrom(
      await _nfPost(
        this,
        endpoint,
        data: {
          'approved': approved,
          'status': approved ? 'approved' : 'rejected',
          'note': note,
        },
      ),
      endpoint,
    );
  }

  Future<List<AutomationCompanyPolicy>> fetchCompanyPolicies({int? companyId}) async {
    final data = await _nfGet(
      this,
      AutomationNewFeatureURLs.companyPolicies,
      queryParameters: {
        if (companyId != null) 'company': companyId,
      },
    );

    return _nfListFrom(data).map(AutomationCompanyPolicy.fromJson).toList();
  }

  Future<AutomationCompanyPolicy> saveCompanyPolicy(AutomationCompanyPolicy policy) async {
    final endpoint = policy.id.isEmpty
        ? AutomationNewFeatureURLs.companyPolicies
        : AutomationNewFeatureURLs.companyPolicyDetail(policy.id);

    final raw = policy.id.isEmpty
        ? await _nfPost(this, endpoint, data: policy.toJson())
        : await _nfPatch(this, endpoint, data: policy.toJson());

    return AutomationCompanyPolicy.fromJson(_nfMapFrom(raw, endpoint));
  }

  Future<List<AutomationTemplate>> fetchTemplates({int? companyId, String? category}) async {
    final data = await _nfGet(
      this,
      AutomationNewFeatureURLs.templates,
      queryParameters: {
        if (companyId != null) 'company': companyId,
        if (category != null) 'category': category,
      },
    );

    return _nfListFrom(data).map(AutomationTemplate.fromJson).toList();
  }

  Future<AutomationWorkflow> createWorkflowFromTemplate(
    String templateId, {
    int? companyId,
    String? name,
  }) async {
    final endpoint = AutomationNewFeatureURLs.createWorkflowFromTemplate(templateId);
    final data = await _nfPost(
      this,
      endpoint,
      data: {
        if (companyId != null) 'company': companyId,
        if (name != null) 'name': name,
      },
    );

    return AutomationWorkflow.fromJson(_nfMapFrom(data, endpoint));
  }

  Future<List<AutomationCodeBlock>> fetchCodeBlocks({
    String? workflowId,
    int? companyId,
    String? status,
  }) async {
    final data = await _nfGet(
      this,
      AutomationNewFeatureURLs.codeBlocks,
      queryParameters: {
        if (workflowId != null) 'workflow': workflowId,
        if (companyId != null) 'company': companyId,
        if (status != null) 'status': status,
      },
    );

    return _nfListFrom(data).map(AutomationCodeBlock.fromJson).toList();
  }

  Future<AutomationCodeBlock> saveCodeBlock(AutomationCodeBlock block) async {
    final endpoint = block.id.isEmpty
        ? AutomationNewFeatureURLs.codeBlocks
        : AutomationNewFeatureURLs.codeBlockDetail(block.id);

    final data = block.id.isEmpty
        ? await _nfPost(this, endpoint, data: block.toJsonForSave())
        : await _nfPatch(this, endpoint, data: block.toJsonForSave());

    return AutomationCodeBlock.fromJson(_nfMapFrom(data, endpoint));
  }

  Future<Map<String, dynamic>> validateCodeBlock(String id) async {
    final endpoint = AutomationNewFeatureURLs.validateCodeBlock(id);
    return _nfMapFrom(await _nfPost(this, endpoint), endpoint);
  }

  Future<AutomationCodeExecution> dryRunCodeBlock(
    String id, {
    Map<String, dynamic> input = const {},
  }) async {
    final endpoint = AutomationNewFeatureURLs.dryRunCodeBlock(id);
    return AutomationCodeExecution.fromJson(
      _nfMapFrom(
        await _nfPost(this, endpoint, data: {'input': input}),
        endpoint,
      ),
    );
  }

  Future<Map<String, dynamic>> requestCodeBlockReview(String id, {String note = ''}) async {
    final endpoint = AutomationNewFeatureURLs.requestCodeBlockReview(id);
    return _nfMapFrom(await _nfPost(this, endpoint, data: {'note': note}), endpoint);
  }

  Future<Map<String, dynamic>> createIftttWorkflow({
    required String name,
    required String signalKey,
    required Map<String, dynamic> condition,
    required String thenActionKey,
    required Map<String, dynamic> thenConfig,
    int? companyId,
  }) async {
    final endpoint = AutomationNewFeatureURLs.ifttt;
    return _nfMapFrom(
      await _nfPost(
        this,
        endpoint,
        data: {
          'name': name,
          'signal_key': signalKey,
          'condition': condition,
          'then_action_key': thenActionKey,
          'then_config': thenConfig,
          if (companyId != null) 'company': companyId,
        },
      ),
      endpoint,
    );
  }

  Future<Map<String, dynamic>> emitApiEvent({
    required String signalKey,
    Map<String, dynamic> body = const {},
    String method = 'POST',
  }) async {
    final endpoint = AutomationNewFeatureURLs.emitApiEvent(signalKey);
    return _nfMapFrom(
      await _nfPost(
        this,
        endpoint,
        data: {
          'method': method,
          ...body,
        },
      ),
      endpoint,
    );
  }
}

Map<String, String> _nfHeaders(AutomationApiService api) {
  return Map<String, String>.from(api.config.defaultHeaders);
}

bool _nfHasToken(AutomationApiService api) => api.config.useTokenAuthHeader;

dynamic _nfNormalizeData(dynamic raw) {
  if (raw == null) return null;

  if (raw is Response) {
    return _nfNormalizeData(raw.data);
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
      return _nfNormalizeData(jsonDecode(trimmed));
    } catch (_) {
      return raw;
    }
  }

  if (raw is List<int>) {
    if (raw.isEmpty) return null;

    try {
      return _nfNormalizeData(jsonDecode(utf8.decode(raw)));
    } catch (_) {
      return raw;
    }
  }

  return raw;
}

int? _nfStatusCode(dynamic response) {
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

String _nfErrorMessageFromData(dynamic data, String fallback) {
  final normalized = _nfNormalizeData(data);

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

dynamic _nfRequireSuccess(dynamic response, String endpoint) {
  if (response == null) {
    throw Exception('Automation API request failed: $endpoint');
  }

  final statusCode = _nfStatusCode(response);
  final data = _nfNormalizeData(response);

  if (statusCode != null && statusCode >= 400) {
    throw Exception(
      _nfErrorMessageFromData(
        data,
        'Automation API request failed with status $statusCode: $endpoint',
      ),
    );
  }

  return data;
}

Map<String, dynamic> _nfMapFrom(dynamic data, String endpoint) {
  final normalized = _nfNormalizeData(data);

  if (normalized is Map<String, dynamic>) {
    return normalized;
  }

  if (normalized is Map) {
    return Map<String, dynamic>.from(normalized);
  }

  throw Exception('Automation API expected object response: $endpoint');
}

List<Map<String, dynamic>> _nfListFrom(dynamic data) {
  final normalized = _nfNormalizeData(data);

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

Future<dynamic> _nfGet(
  AutomationApiService api,
  String endpoint, {
  Map<String, dynamic>? queryParameters,
}) async {
  final response = await ApiServices.get(
    endpoint,
    headers: _nfHeaders(api),
    queryParameters: queryParameters,
    hasToken: _nfHasToken(api),
    responseType: ResponseType.json,
    ref: api.ref,
  );

  return _nfRequireSuccess(response, endpoint);
}

Future<dynamic> _nfPost(
  AutomationApiService api,
  String endpoint, {
  Map<String, dynamic>? data,
}) async {
  final response = await ApiServices.post(
    endpoint,
    headers: _nfHeaders(api),
    data: data,
    hasToken: _nfHasToken(api),
    responseType: ResponseType.json,
    ref: api.ref,
  );

  return _nfRequireSuccess(response, endpoint);
}

Future<dynamic> _nfPatch(
  AutomationApiService api,
  String endpoint, {
  dynamic data,
}) async {
  final response = await ApiServices.patch(
    endpoint,
    headers: _nfHeaders(api),
    data: data,
    hasToken: _nfHasToken(api),
    ref: api.ref,
  );

  return _nfRequireSuccess(response, endpoint);
}
