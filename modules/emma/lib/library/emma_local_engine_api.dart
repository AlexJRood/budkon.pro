import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:get/get_utils/get_utils.dart';

class EmmaLocalEngineApi {
  EmmaLocalEngineApi({
    required this.baseUrl,
    required this.token,
    Dio? dio,
  }) : _dio = dio ?? Dio();

  final String baseUrl;
  final String token;
  final Dio _dio;

  String _url(String path) {
    final cleanBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    final cleanPath = path.startsWith('/') ? path : '/$path';

    return '$cleanBase$cleanPath';
  }

  Options _options({
    ResponseType? responseType,
  }) {
    return Options(
      responseType: responseType ?? ResponseType.json,
      headers: {
        'X-Superbee-Token': token,
        'Accept': 'application/json, text/plain, */*',
        'Content-Type': 'application/json; charset=utf-8',
      },
      validateStatus: (status) {
        return status != null && status >= 200 && status < 500;
      },
    );
  }

  Future<Map<String, dynamic>> ttsSpeech({
    required String input,
    String model = 'default-local-tts',
    String voice = 'default',
    String language = 'pl',
    String format = 'wav',
    bool autoLoad = true,
    bool normalize = true,
    String style = 'assistant',
    bool normalizerDebug = false,
    String referenceAudioPath = '',
    String actionPolicy = 'queue',
    String clientJobId = '',
    String sourceMessageId = '',
    String source = '',
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.post(
      _url('/tts/speech/'),
      data: {
        'input': input,
        'model': model,
        'voice': voice,
        'language': language,
        'format': format,
        'auto_load': autoLoad,
        'normalize': normalize,
        'style': style,
        'normalizer_debug': normalizerDebug,
        'reference_audio_path': referenceAudioPath,
        'action_policy': actionPolicy,
        'client_job_id': clientJobId,
        'source_message_id': sourceMessageId,
        'source': source,
      },
      cancelToken: cancelToken,
      options: _options(),
    );

    return _assertOk(response, 'failed_to_generate_speech'.tr);
  }

  Future<Map<String, dynamic>> sttHealth() async {
    final response = await _dio.get(
      _url('/stt/health/'),
      options: _options(),
    );

    return _assertOk(response,'local_stt_not_responding'.tr);
  }

  Future<Map<String, dynamic>> sttModels() async {
    final response = await _dio.get(
      _url('/stt/models/'),
      options: _options(),
    );

    return _assertOk(response, 'failed_to_fetch_stt_models'.tr);
  }

  Future<Map<String, dynamic>> loadSttModel({
    required String model,
  }) async {
    final response = await _dio.post(
      _url('/stt/models/load/'),
      data: {
        'model': model,
      },
      options: _options(),
    );

    return _assertOk(response, 'failed_to_load_stt_model'.tr);
  }

  Future<Map<String, dynamic>> unloadSttModel({
    required String model,
  }) async {
    final response = await _dio.post(
      _url('/stt/models/unload/'),
      data: {
        'model': model,
      },
      options: _options(),
    );

    return _assertOk(response, 'failed_to_unload_stt_model'.tr);
  }

  Future<Map<String, dynamic>> unloadAllSttModels() async {
    final response = await _dio.post(
      _url('/stt/models/unload-all/'),
      data: const {},
      options: _options(),
    );

    return _assertOk(response, 'failed_to_unload_stt_models'.tr);
  }

  Future<Map<String, dynamic>> ttsHealth() async {
    final response = await _dio.get(
      _url('/tts/health/'),
      options: _options(),
    );

    return _assertOk(response, 'local_tts_not_responding'.tr);
  }

  Future<Map<String, dynamic>> ttsModels() async {
    final response = await _dio.get(
      _url('/tts/models/'),
      options: _options(),
    );

    return _assertOk(response, 'failed_to_fetch_tts_models'.tr);
  }

  Future<Map<String, dynamic>> loadTtsModel({
    required String model,
  }) async {
    final response = await _dio.post(
      _url('/tts/models/load/'),
      data: {
        'model': model,
      },
      options: _options(),
    );

    return _assertOk(response, 'failed_to_load_tts_model'.tr);
  }

  Future<Map<String, dynamic>> unloadTtsModel({
    required String model,
  }) async {
    final response = await _dio.post(
      _url('/tts/models/unload/'),
      data: {
        'model': model,
      },
      options: _options(),
    );

    return _assertOk(response, 'failed_to_unload_tts_models'.tr);
  }

  Future<Map<String, dynamic>> unloadAllTtsModels() async {
    final response = await _dio.post(
      _url('/tts/models/unload-all/'),
      data: const {},
      options: _options(),
    );

    return _assertOk(response, 'failed_to_unload_tts_models'.tr);
  }

  Future<Map<String, dynamic>> health() async {
    final response = await _dio.get(
      _url('/llm/health'),
      options: _options(),
    );

    return _assertOk(response, 'local_engine_not_responding_api'.tr);
  }

  Future<Map<String, dynamic>> settings() async {
    final response = await _dio.get(
      _url('/llm/settings'),
      options: _options(),
    );

    return _assertOk(response, 'failed_to_fetch_engine_settings'.tr);
  }

  Future<Map<String, dynamic>> patchSettings(
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.patch(
      _url('/llm/settings'),
      data: data,
      options: _options(),
    );

    return _assertOk(response,'failed_to_save_engine_settings'.tr);
  }

  Future<Map<String, dynamic>> models() async {
    final response = await _dio.get(
      _url('/llm/models'),
      options: _options(),
    );

    return _assertOk(response, 'failed_to_fetch_local_models'.tr);
  }

  Future<Map<String, dynamic>> loadModel({
    required String modelPath,
    int? nCtx,
    int? nGpuLayers,
    int? nThreads,
    String? chatFormat,
    bool verbose = true,
  }) async {
    final response = await _dio.post(
      _url('/llm/models/load'),
      data: {
        'model_path': modelPath,
        if (nCtx != null) 'n_ctx': nCtx,
        if (nGpuLayers != null) 'n_gpu_layers': nGpuLayers,
        if (nThreads != null) 'n_threads': nThreads,
        if (chatFormat != null) 'chat_format': chatFormat,
        'verbose': verbose,
      },
      options: _options(),
    );

    return _assertOk(response, 'failed_to_load_model'.tr);
  }

  Future<Map<String, dynamic>> unloadModel() async {
    final response = await _dio.post(
      _url('/llm/models/unload'),
      data: const {},
      options: _options(),
    );

    return _assertOk(response, 'failed_to_unload_model'.tr);
  }

  Map<String, dynamic> _assertOk(
    Response response,
    String fallbackMessage,
  ) {
    final status = response.statusCode ?? 0;
    final data = _responseMap(response.data);

    if (status < 200 || status >= 300) {
      throw Exception(
        data['detail'] ??
            data['error'] ??
            data['message'] ??
            fallbackMessage,
      );
    }

    return data;
  }

  Map<String, dynamic> _responseMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);

    if (data is String && data.trim().isNotEmpty) {
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }

    if (data is List<int> && data.isNotEmpty) {
      final decoded = jsonDecode(utf8.decode(data));
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }

    return <String, dynamic>{};
  }
}