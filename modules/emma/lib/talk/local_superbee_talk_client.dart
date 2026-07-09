import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:emma/provider/urls.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final localSuperbeeTalkTokenProvider = StateProvider<String>((ref) => '');

final localSuperbeeTalkClientProvider = Provider<LocalSuperbeeTalkClient>((ref) {
  return LocalSuperbeeTalkClient(
    tokenResolver: () => ref.read(localSuperbeeTalkTokenProvider),
  );
});

class LocalSuperbeeTalkEvent {
  const LocalSuperbeeTalkEvent({
    required this.event,
    required this.data,
  });

  final String event;
  final Map<String, dynamic> data;

  String get delta => (data['delta'] ?? '').toString();
  String get text => (data['text'] ?? '').toString();
  String get content => (data['content'] ?? '').toString();
  String get audioUrl => (data['audio_url'] ?? '').toString();
  String get error => (data['error'] ?? '').toString();

  factory LocalSuperbeeTalkEvent.fromJson(Map<String, dynamic> json) {
    return LocalSuperbeeTalkEvent(
      event: (json['event'] ?? '').toString(),
      data: json,
    );
  }
}

class LocalSuperbeeTalkClient {
  LocalSuperbeeTalkClient({
    Dio? dio,
    String Function()? tokenResolver,
  })  : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 5),
                sendTimeout: const Duration(seconds: 30),
                receiveTimeout: Duration.zero,
              ),
            ),
        _tokenResolver = tokenResolver;

  final Dio _dio;
  final String Function()? _tokenResolver;

  Future<Map<String, dynamic>> health() async {
    final response = await _dio.get(
      URLsEmma.superbeeTalkHealth,
      options: _jsonOptions(),
    );

    return _asMap(response.data);
  }

  Stream<LocalSuperbeeTalkEvent> streamTalk({
    required String input,
    List<Map<String, String>>? messages,
    required String ttsModel,
    required String voice,
    required String language,
    required bool normalizeTts,
    String referenceAudioPath = '',
    bool includeThinking = false,
    int chunkMinChars = 60,
    int chunkMaxChars = 260,
    Map<String, dynamic>? llmOptions,
  }) async* {
    final payload = <String, dynamic>{
      if (messages != null && messages.isNotEmpty) 'messages': messages,
      if ((messages == null || messages.isEmpty)) 'input': input,
      'tts_model': ttsModel,
      'voice': voice,
      'language': language,
      'format': 'wav',
      'auto_load_tts': true,
      'normalize_tts': normalizeTts,
      'include_thinking': includeThinking,
      'chunk_min_chars': chunkMinChars,
      'chunk_max_chars': chunkMaxChars,
      'style': 'assistant',
      if (referenceAudioPath.trim().isNotEmpty)
        'reference_audio_path': referenceAudioPath.trim(),
      if (llmOptions != null && llmOptions.isNotEmpty)
        'llm_options': llmOptions,
    };

    final response = await _dio.post<ResponseBody>(
      URLsEmma.superbeeTalkStream,
      data: payload,
      options: Options(
        responseType: ResponseType.stream,
        receiveTimeout: Duration.zero,
        headers: _headers(
          accept: 'application/x-ndjson, application/json, text/plain, */*',
          contentType: 'application/json; charset=utf-8',
        ),
      ),
    );

    final stream = response.data?.stream;

    if (stream == null) {
      throw StateError('Empty stream from local Talk endpoint.');
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

      yield LocalSuperbeeTalkEvent.fromJson(
        Map<String, dynamic>.from(decoded),
      );
    }
  }

  Options _jsonOptions() {
    return Options(
      headers: _headers(
        accept: 'application/json, text/plain, */*',
        contentType: 'application/json; charset=utf-8',
      ),
    );
  }

  Map<String, String> _headers({
    required String accept,
    required String contentType,
  }) {
    final token = (_tokenResolver?.call() ?? '').trim();

    return {
      'Accept': accept,
      'Content-Type': contentType,
      if (token.isNotEmpty) 'X-Superbee-Token': token,
    };
  }

  Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);

    if (raw is String) {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }

    throw StateError('Unexpected Talk response: $raw');
  }
}