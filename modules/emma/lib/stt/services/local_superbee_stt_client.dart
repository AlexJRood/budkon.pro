// emma/stt/services/local_superbee_stt_client.dart

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:emma/provider/urls.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

final localSuperbeeSttClientProvider = Provider<LocalSuperbeeSttClient>((ref) {
  return LocalSuperbeeSttClient();
});

class LocalSuperbeeSttResult {
  final String text;
  final String model;
  final String language;
  final double? languageProbability;
  final int durationMs;
  final List<Map<String, dynamic>> segments;

  const LocalSuperbeeSttResult({
    required this.text,
    required this.model,
    required this.language,
    required this.languageProbability,
    required this.durationMs,
    required this.segments,
  });

  factory LocalSuperbeeSttResult.fromJson(Map<String, dynamic> json) {
    final rawSegments = json['segments'];

    return LocalSuperbeeSttResult(
      text: (json['text'] ?? '').toString(),
      model: (json['model'] ?? '').toString(),
      language: (json['language'] ?? '').toString(),
      languageProbability: _toDoubleOrNull(json['language_probability']),
      durationMs: _toInt(json['duration_ms']),
      segments: rawSegments is List
          ? rawSegments
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : const [],
    );
  }

  static double? _toDoubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse((value ?? '').toString()) ?? 0;
  }
}

class LocalSuperbeeSttClient {
  LocalSuperbeeSttClient({
    Dio? dio,
  }) : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 5),
                sendTimeout: const Duration(minutes: 2),
                receiveTimeout: const Duration(minutes: 5),
              ),
            );

  final Dio _dio;

  Future<Map<String, dynamic>> health() async {
    final response = await _dio.get(URLsEmma.superbeeSttHealth);
    return _asMap(response.data);
  }

  Future<List<Map<String, dynamic>>> models() async {
    final response = await _dio.get(URLsEmma.superbeeSttModels);
    final data = _asMap(response.data);
    final models = data['models'];

    if (models is! List) return const [];

    return models
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<Map<String, dynamic>> loadModel(String model) async {
    final response = await _dio.post(
      URLsEmma.superbeeSttModelLoad,
      data: {
        'model': model,
      },
      options: Options(
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
        },
      ),
    );

    return _asMap(response.data);
  }

  Future<LocalSuperbeeSttResult> transcribeFile({
    required String filePath,
    required String model,
    required String language,
    String task = 'transcribe',
    bool autoLoad = true,
    bool vadFilter = true,
    bool wordTimestamps = false,
    bool returnSegments = true,
    int beamSize = 5,
    String initialPrompt = '',
  }) async {
    final file = File(filePath);

    if (!await file.exists()) {
      throw StateError('Audio file does not exist: $filePath');
    }

    final formData = FormData.fromMap({
      'model': model,
      'language': language,
      'task': task,
      'auto_load': autoLoad.toString(),
      'vad_filter': vadFilter.toString(),
      'word_timestamps': wordTimestamps.toString(),
      'return_segments': returnSegments.toString(),
      'beam_size': beamSize.toString(),
      'initial_prompt': initialPrompt,
      'audio': await MultipartFile.fromFile(
        filePath,
        filename: p.basename(filePath),
      ),
    });

    final response = await _dio.post(
      URLsEmma.superbeeSttTranscribe,
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        headers: {
          'Accept': 'application/json, text/plain, */*',
        },
      ),
    );

    final data = _asMap(response.data);

    if ((data['status'] ?? '').toString() != 'success') {
      throw StateError(
        (data['error'] ?? 'STT returned non-success status.').toString(),
      );
    }

    return LocalSuperbeeSttResult.fromJson(data);
  }

  Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);

    if (raw is String) {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }

    throw StateError('Unexpected STT response: $raw');
  }
}