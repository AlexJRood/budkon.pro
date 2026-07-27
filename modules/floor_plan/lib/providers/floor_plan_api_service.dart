import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:floor_plan/models/floor_plan_document.dart';
import 'package:floor_plan/providers/urls.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/api_services.dart';

final floorPlanApiServiceProvider = Provider<FloorPlanApiService>((ref) {
  return const FloorPlanApiService(
    baseUrl: URLsFloorPlan.baseUrl,
  );
});

class FloorPlanApiService {
  final String baseUrl;

  const FloorPlanApiService({
    required this.baseUrl,
  });

  String get _cleanBaseUrl {
    final trimmed = baseUrl.trim();
    return trimmed.endsWith('/') ? trimmed : '$trimmed/';
  }

  String get _projectsUrl => '${_cleanBaseUrl}projects/';

  String projectUrl(String projectId) {
    return '${_cleanBaseUrl}projects/${projectId.trim()}/';
  }

  String latestVersionUrl(String projectId) {
    return '${_cleanBaseUrl}projects/${projectId.trim()}/latest-version/';
  }

  String versionsUrl(String projectId) {
    return '${_cleanBaseUrl}projects/${projectId.trim()}/versions/';
  }

  String assetsUrl(String projectId) {
    return '${_cleanBaseUrl}projects/${projectId.trim()}/assets/';
  }

  String aiVectorizeUrl(String projectId) {
    return '${_cleanBaseUrl}projects/${projectId.trim()}/ai/vectorize/';
  }

  String aiFromPhotosUrl(String projectId) {
    return '${_cleanBaseUrl}projects/${projectId.trim()}/ai/from-photos/';
  }

  Future<List<FloorPlanProjectDto>> listProjects({
    required WidgetRef ref,
    String? targetObjectId,
    String? status,
    String? sourceType,
  }) async {
    final query = <String, dynamic>{
      if (_hasValue(targetObjectId)) 'target_object_id': targetObjectId!.trim(),
      if (_hasValue(status)) 'status': status!.trim(),
      if (_hasValue(sourceType)) 'source_type': sourceType!.trim(),
    };

    final response = await ApiServices.get(
      _projectsUrl,
      hasToken: true,
      ref: ref,
      queryParameters: query,
      responseType: ResponseType.json,
    );

    final payload = _extractPayload(
      response,
      context: 'FloorPlanApiService.listProjects',
    );

    _throwIfHttpError(
      response,
      payload,
      context: 'FloorPlanApiService.listProjects',
    );

    final list = _extractList(payload);

    return list
        .whereType<Map>()
        .map(
          (item) => FloorPlanProjectDto.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .where((project) => project.id.trim().isNotEmpty)
        .toList();
  }

  Future<FloorPlanProjectDto> getProject({
    required WidgetRef ref,
    required String projectId,
  }) async {
    final cleanProjectId = _requiredId(projectId, 'projectId');

    final response = await ApiServices.get(
      projectUrl(cleanProjectId),
      hasToken: true,
      ref: ref,
      responseType: ResponseType.json,
    );

    final data = _extractMap(
      response,
      context: 'FloorPlanApiService.getProject',
    );

    final project = FloorPlanProjectDto.fromJson(data);

    if (project.id.trim().isEmpty) {
      throw Exception(
        '${'api_list_projects_no_id_error'.tr}'
        'Payload: ${_previewObject(data)}',
      );
    }

    return project;
  }

  Future<FloorPlanProjectDto> createProject({
    required WidgetRef ref,
    required String title,
    String sourceType = 'manual',
    String? targetObjectId,
    String? targetAppLabel,
    String? targetModel,
    Map<String, dynamic>? metadata,
  }) async {
    final cleanTitle = title.trim().isEmpty ? 'property_plan_default_title'.tr : title.trim();

    final response = await ApiServices.post(
      _projectsUrl,
      hasToken: true,
      ref: ref,
      responseType: ResponseType.json,
      data: {
        'title': cleanTitle,
        'source_type': sourceType.trim().isEmpty ? 'manual' : sourceType.trim(),
        if (_hasValue(targetObjectId))
          'target_object_id': targetObjectId!.trim(),
        if (_hasValue(targetAppLabel))
          'target_app_label': targetAppLabel!.trim(),
        if (_hasValue(targetModel)) 'target_model': targetModel!.trim(),
        'metadata': metadata ?? <String, dynamic>{},
      },
    );

    final data = _extractMap(
      response,
      context: 'FloorPlanApiService.createProject',
    );

    final project = FloorPlanProjectDto.fromJson(data);

    if (project.id.trim().isEmpty) {
      throw Exception(
        '${'api_create_project_no_id_error'.tr}'
        'This would break WebSocket path. Payload: ${_previewObject(data)}',
      );
    }

    return project;
  }

  Future<FloorPlanVersionDto> getLatestVersion({
    required WidgetRef ref,
    required String projectId,
  }) async {
    final cleanProjectId = _requiredId(projectId, 'projectId');

    final response = await ApiServices.get(
      latestVersionUrl(cleanProjectId),
      hasToken: true,
      ref: ref,
      responseType: ResponseType.json,
    );

    final data = _extractMap(
      response,
      context: 'FloorPlanApiService.getLatestVersion',
    );

    return FloorPlanVersionDto.fromJson(data);
  }

  Future<FloorPlanVersionDto> createVersion({
    required WidgetRef ref,
    required String projectId,
    required FloorPlanDocument document,
    String? changeNote,
    String? previewImageUrl,
    bool aiGenerated = false,
    double confidenceScore = 0,
    Map<String, dynamic>? metadata,
  }) async {
    final cleanProjectId = _requiredId(projectId, 'projectId');

    final response = await ApiServices.post(
      versionsUrl(cleanProjectId),
      hasToken: true,
      ref: ref,
      responseType: ResponseType.json,
      data: {
        'plan_json': document.toJson(),
        if (_hasValue(previewImageUrl))
          'preview_image_url': previewImageUrl!.trim(),
        'ai_generated': aiGenerated,
        'confidence_score': confidenceScore,
        'change_note': _hasValue(changeNote)
            ? changeNote!.trim()
            : 'manual_save_change_note'.tr,
        'metadata': metadata ?? <String, dynamic>{},
      },
    );

    final data = _extractMap(
      response,
      context: 'FloorPlanApiService.createVersion',
    );

    return FloorPlanVersionDto.fromJson(data);
  }

  Future<void> deleteProject({
    required WidgetRef ref,
    required String projectId,
  }) async {
    final cleanProjectId = _requiredId(projectId, 'projectId');

    final response = await ApiServices.delete(
      projectUrl(cleanProjectId),
      hasToken: true,
    );

    final statusCode = _statusCodeFrom(response);

    if (statusCode == 204) {
      return;
    }

    final payload = _extractPayload(
      response,
      context: 'FloorPlanApiService.deleteProject',
    );

    _throwIfHttpError(
      response,
      payload,
      context: 'FloorPlanApiService.deleteProject',
    );
  }

  Future<FloorPlanAiJobDto> startVectorizeJob({
    required WidgetRef ref,
    required String projectId,
    required List<String> assetIds,
    Map<String, dynamic>? inputPayload,
  }) async {
    final cleanProjectId = _requiredId(projectId, 'projectId');

    final response = await ApiServices.post(
      aiVectorizeUrl(cleanProjectId),
      hasToken: true,
      ref: ref,
      responseType: ResponseType.json,
      data: {
        'asset_ids': assetIds,
        'input_payload': inputPayload ?? <String, dynamic>{},
      },
    );

    final data = _extractMap(
      response,
      context: 'FloorPlanApiService.startVectorizeJob',
    );

    return FloorPlanAiJobDto.fromJson(data);
  }

  Future<FloorPlanAiJobDto> startFromPhotosJob({
    required WidgetRef ref,
    required String projectId,
    required List<String> assetIds,
    Map<String, dynamic>? inputPayload,
  }) async {
    final cleanProjectId = _requiredId(projectId, 'projectId');

    final response = await ApiServices.post(
      aiFromPhotosUrl(cleanProjectId),
      hasToken: true,
      ref: ref,
      responseType: ResponseType.json,
      data: {
        'asset_ids': assetIds,
        'input_payload': inputPayload ?? <String, dynamic>{},
      },
    );

    final data = _extractMap(
      response,
      context: 'FloorPlanApiService.startFromPhotosJob',
    );

    return FloorPlanAiJobDto.fromJson(data);
  }

  Map<String, dynamic> _extractMap(
    dynamic response, {
    required String context,
  }) {
    final payload = _extractPayload(
      response,
      context: context,
    );

    _throwIfHttpError(
      response,
      payload,
      context: context,
    );

    if (payload is Map<String, dynamic>) {
      return payload;
    }

    if (payload is Map) {
      return Map<String, dynamic>.from(payload);
    }

    throw Exception(
      '$context expected JSON object, got ${payload.runtimeType}. '
      'Payload: ${_previewObject(payload)}',
    );
  }

  dynamic _extractPayload(
    dynamic response, {
    required String context,
  }) {
    if (response == null) {
      return <String, dynamic>{};
    }

    if (response is Response) {
      return _normalizePayload(
        response.data,
        context: context,
        statusCode: response.statusCode,
        contentType: _contentTypeFrom(response),
      );
    }

    return _normalizePayload(
      response,
      context: context,
      statusCode: _statusCodeFrom(response),
      contentType: _contentTypeFrom(response),
    );
  }

  dynamic _normalizePayload(
    dynamic data, {
    required String context,
    int? statusCode,
    String? contentType,
  }) {
    if (data == null) {
      return <String, dynamic>{};
    }

    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    if (data is List) {
      return data;
    }

    if (data is List<int>) {
      final text = utf8.decode(data);
      return _decodeStringPayload(
        text,
        context: context,
        statusCode: statusCode,
        contentType: contentType,
      );
    }

    if (data is String) {
      return _decodeStringPayload(
        data,
        context: context,
        statusCode: statusCode,
        contentType: contentType,
      );
    }

    return data;
  }

  dynamic _decodeStringPayload(
    String raw, {
    required String context,
    int? statusCode,
    String? contentType,
  }) {
    final text = raw.trim();

    if (text.isEmpty) {
      return <String, dynamic>{};
    }

    final lowerText = text.toLowerCase();
    final lowerContentType = contentType?.toLowerCase() ?? '';

    final looksLikeHtml = lowerText.startsWith('<!doctype html') ||
        lowerText.startsWith('<html') ||
        lowerText.startsWith('<!doctype') ||
        lowerContentType.contains('text/html');

    if (looksLikeHtml) {
      debugPrint('[$context] HTML response instead of JSON.');
      debugPrint('[$context] HTTP status: ${statusCode ?? 'unknown'}');
      debugPrint('[$context] Content-Type: ${contentType ?? 'unknown'}');
      debugPrint('[$context] Body preview: ${_previewText(text)}');

      throw Exception(
        '$context returned HTML instead of JSON. '
        'Check URL/domain/proxy/auth. '
        'HTTP status: ${statusCode ?? 'unknown'}, '
        'Content-Type: ${contentType ?? 'unknown'}.',
      );
    }

    try {
      final decoded = jsonDecode(text);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }

      if (decoded is List) {
        return decoded;
      }

      return decoded;
    } catch (e, stack) {
      debugPrint('[$context] JSON decode error: $e\n$stack');
      debugPrint('[$context] HTTP status: ${statusCode ?? 'unknown'}');
      debugPrint('[$context] Content-Type: ${contentType ?? 'unknown'}');
      debugPrint('[$context] Body preview: ${_previewText(text)}');

      throw Exception(
        '$context returned invalid JSON. '
        'HTTP status: ${statusCode ?? 'unknown'}, '
        'Content-Type: ${contentType ?? 'unknown'}.',
      );
    }
  }

  List<dynamic> _extractList(dynamic payload) {
    if (payload is List) {
      return payload;
    }

    if (payload is Map) {
      if (payload['results'] is List) return payload['results'] as List;
      if (payload['data'] is List) return payload['data'] as List;
      if (payload['items'] is List) return payload['items'] as List;
      if (payload['objects'] is List) return payload['objects'] as List;
    }

    return const [];
  }

  void _throwIfHttpError(
    dynamic response,
    dynamic payload, {
    required String context,
  }) {
    final statusCode = _statusCodeFrom(response);

    if (statusCode == null || statusCode < 400) {
      return;
    }

    throw Exception(
      '$context failed with HTTP $statusCode: ${_errorMessageFromPayload(payload)}',
    );
  }

  int? _statusCodeFrom(dynamic response) {
    if (response is Response) {
      return response.statusCode;
    }

    try {
      final dynamic rawStatus = response?.statusCode;
      if (rawStatus is int) return rawStatus;
      if (rawStatus is num) return rawStatus.toInt();
      return int.tryParse(rawStatus?.toString() ?? '');
    } catch (_) {
      return null;
    }
  }

  String? _contentTypeFrom(dynamic response) {
    if (response is Response) {
      return response.headers.value(Headers.contentTypeHeader);
    }

    try {
      final dynamic headers = response?.headers;
      final dynamic value = headers?['content-type'] ?? headers?['Content-Type'];
      return value?.toString();
    } catch (_) {
      return null;
    }
  }

  String _errorMessageFromPayload(dynamic payload) {
    if (payload is Map) {
      final detail = payload['detail'] ??
          payload['error'] ??
          payload['message'] ??
          payload['non_field_errors'];

      if (detail != null && detail.toString().trim().isNotEmpty) {
        return detail.toString();
      }

      return _previewObject(payload);
    }

    if (payload is String) {
      return _previewText(payload);
    }

    return payload?.toString() ?? 'Unknown error.';
  }
}

class FloorPlanProjectDto {
  final String id;
  final String title;
  final String sourceType;
  final String status;
  final String? targetObjectId;
  final FloorPlanVersionDto? latestVersion;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const FloorPlanProjectDto({
    required this.id,
    required this.title,
    required this.sourceType,
    required this.status,
    this.targetObjectId,
    this.latestVersion,
    this.createdAt,
    this.updatedAt,
  });

  factory FloorPlanProjectDto.fromJson(Map<String, dynamic> json) {
    final latestRaw = json['latest_version'] ?? json['latestVersion'];

    return FloorPlanProjectDto(
      id: _stringFromAny(json['id'] ?? json['uuid']),
      title: _stringFromAny(json['title']).trim().isEmpty
          ? 'Plan nieruchomości'
          : _stringFromAny(json['title']),
      sourceType: _stringFromAny(json['source_type'] ?? json['sourceType'])
              .trim()
              .isEmpty
          ? 'manual'
          : _stringFromAny(json['source_type'] ?? json['sourceType']),
      status: _stringFromAny(json['status']).trim().isEmpty
          ? 'draft'
          : _stringFromAny(json['status']),
      targetObjectId: _nullableString(json['target_object_id'] ?? json['targetObjectId']),
      latestVersion: latestRaw is Map
          ? FloorPlanVersionDto.fromJson(
              Map<String, dynamic>.from(latestRaw),
            )
          : null,
      createdAt: _dateTimeFromAny(json['created_at'] ?? json['createdAt']),
      updatedAt: _dateTimeFromAny(json['updated_at'] ?? json['updatedAt']),
    );
  }
}

class FloorPlanVersionDto {
  final String id;
  final String projectId;
  final int versionNumber;
  final FloorPlanDocument document;
  final bool aiGenerated;
  final double confidenceScore;
  final String? changeNote;
  final DateTime? createdAt;

  const FloorPlanVersionDto({
    required this.id,
    required this.projectId,
    required this.versionNumber,
    required this.document,
    required this.aiGenerated,
    required this.confidenceScore,
    this.changeNote,
    this.createdAt,
  });

  factory FloorPlanVersionDto.fromJson(Map<String, dynamic> json) {
    return FloorPlanVersionDto(
      id: _stringFromAny(json['id'] ?? json['uuid']),
      projectId: _projectIdFromAny(json['project'] ?? json['project_id'] ?? json['projectId']),
      versionNumber: _intFromAny(json['version_number'] ?? json['versionNumber'], fallback: 1),
      document: _documentFromAny(
        json['plan_json'] ??
            json['planJson'] ??
            json['document'] ??
            json['plan'],
      ),
      aiGenerated: _boolFromAny(json['ai_generated'] ?? json['aiGenerated']),
      confidenceScore: _doubleFromAny(
        json['confidence_score'] ?? json['confidenceScore'],
      ),
      changeNote: _nullableString(json['change_note'] ?? json['changeNote']),
      createdAt: _dateTimeFromAny(json['created_at'] ?? json['createdAt']),
    );
  }
}

class FloorPlanAiJobDto {
  final String id;
  final String projectId;
  final String jobType;
  final String status;
  final double confidenceScore;
  final String? errorMessage;

  const FloorPlanAiJobDto({
    required this.id,
    required this.projectId,
    required this.jobType,
    required this.status,
    required this.confidenceScore,
    this.errorMessage,
  });

  factory FloorPlanAiJobDto.fromJson(Map<String, dynamic> json) {
    return FloorPlanAiJobDto(
      id: _stringFromAny(json['id'] ?? json['uuid']),
      projectId: _projectIdFromAny(json['project'] ?? json['project_id'] ?? json['projectId']),
      jobType: _stringFromAny(json['job_type'] ?? json['jobType']),
      status: _stringFromAny(json['status']).trim().isEmpty
          ? 'pending'
          : _stringFromAny(json['status']),
      confidenceScore: _doubleFromAny(
        json['confidence_score'] ?? json['confidenceScore'],
      ),
      errorMessage: _nullableString(json['error_message'] ?? json['errorMessage']),
    );
  }
}

bool _hasValue(String? value) {
  return value != null && value.trim().isNotEmpty;
}

String _requiredId(String value, String fieldName) {
  final clean = value.trim();

  if (clean.isEmpty) {
    throw ArgumentError('$fieldName cannot be empty.');
  }

  return clean;
}

String _stringFromAny(dynamic value) {
  if (value == null) return '';

  if (value is Map) {
    final id = value['id'] ?? value['uuid'];
    return id?.toString() ?? '';
  }

  return value.toString();
}

String? _nullableString(dynamic value) {
  if (value == null) return null;

  final text = value.toString().trim();

  if (text.isEmpty || text.toLowerCase() == 'null') {
    return null;
  }

  return text;
}

String _projectIdFromAny(dynamic value) {
  if (value == null) return '';

  if (value is Map) {
    return _stringFromAny(value['id'] ?? value['uuid']);
  }

  return value.toString();
}

int _intFromAny(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();

  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double _doubleFromAny(dynamic value, {double fallback = 0}) {
  if (value is double) return value;
  if (value is num) return value.toDouble();

  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

bool _boolFromAny(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;

  final text = value?.toString().trim().toLowerCase();

  if (text == 'true' || text == '1' || text == 'yes') return true;
  if (text == 'false' || text == '0' || text == 'no') return false;

  return fallback;
}

DateTime? _dateTimeFromAny(dynamic value) {
  final text = value?.toString().trim();

  if (text == null || text.isEmpty || text.toLowerCase() == 'null') {
    return null;
  }

  return DateTime.tryParse(text);
}

FloorPlanDocument _documentFromAny(dynamic value) {
  if (value is Map<String, dynamic>) {
    return FloorPlanDocument.fromJson(value);
  }

  if (value is Map) {
    return FloorPlanDocument.fromJson(
      Map<String, dynamic>.from(value),
    );
  }

  if (value is String && value.trim().isNotEmpty) {
    try {
      final decoded = jsonDecode(value);

      if (decoded is Map<String, dynamic>) {
        return FloorPlanDocument.fromJson(decoded);
      }

      if (decoded is Map) {
        return FloorPlanDocument.fromJson(
          Map<String, dynamic>.from(decoded),
        );
      }
    } catch (_) {
      return FloorPlanDocument.empty();
    }
  }

  return FloorPlanDocument.empty();
}

String _previewText(String text, {int maxLength = 700}) {
  final compact = text.replaceAll(RegExp(r'\s+'), ' ').trim();

  if (compact.length <= maxLength) {
    return compact;
  }

  return '${compact.substring(0, maxLength)}...';
}

String _previewObject(dynamic value, {int maxLength = 700}) {
  try {
    return _previewText(jsonEncode(value), maxLength: maxLength);
  } catch (_) {
    return _previewText(value?.toString() ?? '', maxLength: maxLength);
  }
}