import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

class SuperbeeLocalEngineException implements Exception {
  final String message;
  final Object? cause;

  SuperbeeLocalEngineException(this.message, {this.cause});

  @override
  String toString() => 'SuperbeeLocalEngineException: $message';
}

class SuperbeeStreamEvent {
  final Map<String, dynamic> raw;

  const SuperbeeStreamEvent(this.raw);

  String get event => (raw['event'] ?? raw['type'] ?? '').toString();

  String get delta => (raw['delta'] ?? '').toString();

  bool get done => raw['done'] == true || event == 'done';

  String get content => (raw['content'] ?? '').toString();

  String get thinking => (raw['thinking'] ?? '').toString();

  List<Map<String, dynamic>> get audioChunks {
    final value = raw['audio_chunks'];
    if (value is! List) return const [];

    return value
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Map<String, dynamic>? get audioChunk {
    if (event != 'tts_chunk_ready') return null;
    return raw;
  }
}

class SuperbeeLocalEngineClient {
  final Dio dio;
  final String baseUrl;
  final String token;

  SuperbeeLocalEngineClient({
    Dio? dio,
    this.baseUrl = 'http://127.0.0.1:43890',
    required this.token,
  }) : dio = dio ?? Dio();

  Options get _authJsonOptions => Options(
        headers: {
          'X-Superbee-Token': token,
          'Content-Type': 'application/json; charset=utf-8',
        },
      );

  Options get _authStreamOptions => Options(
        responseType: ResponseType.stream,
        headers: {
          'X-Superbee-Token': token,
          'Content-Type': 'application/json; charset=utf-8',
        },
      );

  Future<Map<String, dynamic>> health() async {
    final response = await dio.get('$baseUrl/llm/health');
    return Map<String, dynamic>.from(response.data);
  }

  Future<Map<String, dynamic>> talkHealth() async {
    final response = await dio.get(
      '$baseUrl/talk/health/',
      options: _authJsonOptions,
    );
    return Map<String, dynamic>.from(response.data);
  }

  Future<Map<String, dynamic>> loadLlmModel({
    required String modelPath,
    int nCtx = 4096,
    int nGpuLayers = 35,
    int? nThreads,
    bool verbose = true,
  }) async {
    final response = await dio.post(
      '$baseUrl/llm/models/load',
      options: _authJsonOptions,
      data: {
        'model_path': modelPath,
        'n_ctx': nCtx,
        'n_gpu_layers': nGpuLayers,
        if (nThreads != null) 'n_threads': nThreads,
        'verbose': verbose,
      },
    );

    return Map<String, dynamic>.from(response.data);
  }

  Stream<SuperbeeStreamEvent> streamLlmChat({
    required List<Map<String, dynamic>> messages,
    required Map<String, dynamic> options,
    Map<String, dynamic> metadata = const {},
  }) {
    return _postNdjson(
      path: '/llm/chat/stream',
      payload: {
        'messages': messages,
        'options': options,
        'metadata': metadata,
      },
    );
  }

  Stream<SuperbeeStreamEvent> streamTalk({
    required String input,
    required List<Map<String, dynamic>> messages,
    required Map<String, dynamic> llmOptions,
    String ttsModel = 'piper-pl-female',
    String voice = 'default',
    String language = 'pl',
    String format = 'wav',
    bool includeThinking = false,
    bool autoLoadTts = true,
    bool normalizeTts = true,
    int chunkMinChars = 60,
    int chunkMaxChars = 260,
    Map<String, dynamic> metadata = const {},
  }) {
    return _postNdjson(
      path: '/talk/stream/',
      payload: {
        'input': input,

        // W talk backendzie dodamy obsługę tego pola.
        // Jeśli messages istnieje, talk ma użyć gotowego promptu z Emmy,
        // zamiast budować własny prosty prompt.
        'messages': messages,

        'include_thinking': includeThinking,
        'tts_model': ttsModel,
        'voice': voice,
        'language': language,
        'format': format,
        'auto_load_tts': autoLoadTts,
        'normalize_tts': normalizeTts,
        'chunk_min_chars': chunkMinChars,
        'chunk_max_chars': chunkMaxChars,
        'llm_options': llmOptions,
        'metadata': metadata,
      },
    );
  }

  Stream<SuperbeeStreamEvent> _postNdjson({
    required String path,
    required Map<String, dynamic> payload,
  }) async* {
    try {
      final response = await dio.post<ResponseBody>(
        '$baseUrl$path',
        options: _authStreamOptions,
        data: payload,
      );

      final stream = response.data?.stream;

      if (stream == null) {
        throw SuperbeeLocalEngineException('Empty stream from local engine.');
      }

      final lines = stream
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in lines) {
        final trimmed = line.trim();

        if (trimmed.isEmpty) continue;

        final decoded = jsonDecode(trimmed);

        if (decoded is! Map) continue;

        yield SuperbeeStreamEvent(
          Map<String, dynamic>.from(decoded),
        );
      }
    } catch (e) {
      throw SuperbeeLocalEngineException(
        'Local Superbee stream failed.',
        cause: e,
      );
    }
  }
}