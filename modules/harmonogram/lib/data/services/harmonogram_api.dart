import 'package:dio/dio.dart';
import '../models/harmonogram_model.dart';

class HarmonogramApi {
  static const _base = 'http://127.0.0.1:8001/api/v1';
  static const _headers = {'X-Company-Id': '1'};

  final Dio _dio = Dio(BaseOptions(
    baseUrl: _base,
    headers: _headers,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 20),
  ));

  Future<TimelineData> timeline(int budowaId) async {
    final r = await _dio.get(
      '/harmonogram/timeline/',
      queryParameters: {'budowa': budowaId},
    );
    return TimelineData.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> autoGeneruj(int budowaId) async {
    await _dio.post(
      '/harmonogram/timeline/auto-generuj/',
      data: {'budowa_id': budowaId},
    );
  }

  Future<ZadanieModel> zadanie(int id) async {
    final r = await _dio.get('/harmonogram/$id/');
    return ZadanieModel.fromJson(r.data as Map<String, dynamic>);
  }

  Future<ZadanieModel> utworzZadanie(Map<String, dynamic> payload) async {
    final r = await _dio.post('/harmonogram/', data: payload);
    return ZadanieModel.fromJson(r.data as Map<String, dynamic>);
  }

  Future<ZadanieModel> edytujZadanie(int id, Map<String, dynamic> payload) async {
    final r = await _dio.patch('/harmonogram/$id/', data: payload);
    return ZadanieModel.fromJson(r.data as Map<String, dynamic>);
  }

  Future<ZadanieModel> aktualizujPostep(
    int id, {
    required int postepProcent,
    String? status,
  }) async {
    final r = await _dio.patch(
      '/harmonogram/$id/postep/',
      data: {
        'postep_procent': postepProcent,
        if (status != null) 'status': status,
      },
    );
    return ZadanieModel.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> usunZadanie(int id) async {
    await _dio.delete('/harmonogram/$id/');
  }

  Future<MilestoneModel> osiagnijMilestone(int id) async {
    final r = await _dio.post('/harmonogram-milestones/$id/osiagnij/');
    return MilestoneModel.fromJson(r.data as Map<String, dynamic>);
  }

  Future<MilestoneModel> utworzMilestone(Map<String, dynamic> payload) async {
    final r = await _dio.post('/harmonogram-milestones/', data: payload);
    return MilestoneModel.fromJson(r.data as Map<String, dynamic>);
  }
}

final harmonogramApi = HarmonogramApi();
