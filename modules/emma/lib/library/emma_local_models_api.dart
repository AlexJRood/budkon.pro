import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/api_services.dart';

import 'emma_local_models_models.dart';

class EmmaLocalModelsApi {
  const EmmaLocalModelsApi({
    required this.baseUrl,
  });

  final String baseUrl;

  String _url(String path) {
    final cleanBase = baseUrl.trim().endsWith('/')
        ? baseUrl.trim().substring(0, baseUrl.trim().length - 1)
        : baseUrl.trim();

    final cleanPath = path.startsWith('/') ? path : '/$path';

    return '$cleanBase$cleanPath';
  }

  String _modelPath(String modelId, String suffix) {
    final encodedModelId = Uri.encodeComponent(modelId.trim());
    final cleanSuffix = suffix.startsWith('/') ? suffix : '/$suffix';

    return '/models/$encodedModelId$cleanSuffix';
  }

  Future<List<EmmaLocalModelDto>> catalog({
    required dynamic ref,
    String? taskType,
    String? runtime,
    String? modelFormat,
    String? sourceType,
    bool? featured,
    String? q,
  }) async {
    final query = <String, dynamic>{};

    void addQuery(String key, String? value) {
      final cleaned = value?.trim();
      if (cleaned != null && cleaned.isNotEmpty) {
        query[key] = cleaned;
      }
    }

    addQuery('task_type', taskType);
    addQuery('runtime', runtime);
    addQuery('model_format', modelFormat);
    addQuery('source_type', sourceType);
    addQuery('q', q);

    if (featured == true) {
      query['featured'] = 'true';
    }

    final data = await ApiServices.getJson(
      _url('/models/catalog/'),
      hasToken: true,
      ref: ref,
      queryParameters: query,
    );

    final rawResults = data['results'] ?? data['data'];

    if (rawResults is List) {
      return rawResults
          .whereType<Map>()
          .map(
            (item) => EmmaLocalModelDto.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    }

    return <EmmaLocalModelDto>[];
  }

  Future<EmmaLocalModelDto> detail({
    required dynamic ref,
    required String modelId,
  }) async {
    final cleanedModelId = modelId.trim();

    if (cleanedModelId.isEmpty) {
      throw ArgumentError('modelId cannot be empty.');
    }

    final data = await ApiServices.getJson(
      _url(_modelPath(cleanedModelId, '/')),
      hasToken: true,
      ref: ref,
    );

    if (data.isEmpty) {
      throw Exception('failed_to_fetch_model_details'.tr);
    }

    return EmmaLocalModelDto.fromJson(data);
  }

  Future<void> acceptLicense({
    required dynamic ref,
    required String modelId,
  }) async {
    final cleanedModelId = modelId.trim();

    if (cleanedModelId.isEmpty) {
      throw ArgumentError('modelId cannot be empty.');
    }

    final response = await ApiServices.post(
      _url(_modelPath(cleanedModelId, '/accept-license/')),
      hasToken: true,
      ref: ref,
      responseType: ResponseType.json,
      data: const {
        'accepted': true,
      },
    );

    _assertOkResponse(
      response,
      fallbackMessage: 'failed_to_accept_license'.tr,
    );
  }

  Future<EmmaLocalResolveDownloadResponse> resolveDownload({
    required dynamic ref,
    required String modelId,
    String? fileId,
    String platform = 'unknown',
  }) async {
    final cleanedModelId = modelId.trim();

    if (cleanedModelId.isEmpty) {
      throw ArgumentError('modelId cannot be empty.');
    }

    final cleanedFileId = fileId?.trim();

    final response = await ApiServices.post(
      _url(_modelPath(cleanedModelId, '/resolve-download/')),
      hasToken: true,
      ref: ref,
      responseType: ResponseType.json,
      data: {
        if (cleanedFileId != null && cleanedFileId.isNotEmpty)
          'file_id': cleanedFileId,
        'platform': platform.trim().isEmpty ? 'unknown' : platform.trim(),
      },
    );

    final data = _assertOkResponse(
      response,
      fallbackMessage: 'failed_to_prepare_download'.tr,
    );

    if (data['model'] is! Map || data['file'] is! Map || data['download'] is! Map) {
      throw Exception('invalid_download_data_format'.tr);
    }

    return EmmaLocalResolveDownloadResponse.fromJson(data);
  }
}

Map<String, dynamic> _assertOkResponse(
  Response? response, {
  required String fallbackMessage,
}) {
  if (response == null) {
    throw Exception(fallbackMessage);
  }

  final statusCode = response.statusCode ?? 0;
  final data = _responseMap(response);

  if (statusCode < 200 || statusCode >= 300) {
    throw Exception(_extractErrorMessage(data, fallbackMessage));
  }

  return data;
}

String _extractErrorMessage(
  Map<String, dynamic> data,
  String fallbackMessage,
) {
  final direct = data['detail'] ?? data['error'] ?? data['message'];

  if (direct != null && direct.toString().trim().isNotEmpty) {
    return direct.toString();
  }

  if (data['non_field_errors'] is List) {
    final errors = data['non_field_errors'] as List;
    if (errors.isNotEmpty) return errors.first.toString();
  }

  final fieldErrors = <String>[];

  for (final entry in data.entries) {
    final value = entry.value;

    if (value is List && value.isNotEmpty) {
      fieldErrors.add('${entry.key}: ${value.join(', ')}');
    } else if (value is String && value.trim().isNotEmpty) {
      fieldErrors.add('${entry.key}: $value');
    }
  }

  if (fieldErrors.isNotEmpty) {
    return fieldErrors.join('\n');
  }

  return fallbackMessage;
}

Map<String, dynamic> _responseMap(Response? response) {
  if (response == null) return <String, dynamic>{};

  final data = response.data;

  if (data is Map<String, dynamic>) {
    return data;
  }

  if (data is Map) {
    return Map<String, dynamic>.from(data);
  }

  if (data is String && data.trim().isNotEmpty) {
    try {
      final decoded = jsonDecode(data);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      return <String, dynamic>{
        'message': data,
      };
    }
  }

  if (data is List<int> && data.isNotEmpty) {
    try {
      final decodedText = utf8.decode(data);
      final decoded = jsonDecode(decodedText);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  return <String, dynamic>{};
}