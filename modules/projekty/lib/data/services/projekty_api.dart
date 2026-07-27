import 'dart:typed_data';
import 'package:core/platform/budkon_api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/projekt_budowlany_model.dart';
import '../models/pipeline_model.dart';

class ProjektyApi {
  final Dio _dio = budkonDio(
    receiveTimeout: const Duration(seconds: 60),
    connectTimeout: const Duration(seconds: 15),
  );

  Future<List<ProjektBudowlanyListModel>> fetchList() async {
    final resp = await _dio.get('/projekty/');
    final data = resp.data;
    final list = data is Map ? (data['results'] as List<dynamic>) : (data as List<dynamic>);
    return list
        .map((e) => ProjektBudowlanyListModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ProjektBudowlanyDetailModel> fetchDetail(String projektId) async {
    final resp = await _dio.get('/projekty/$projektId/');
    return ProjektBudowlanyDetailModel.fromJson(
        resp.data as Map<String, dynamic>);
  }

  Future<KosztorysApiModel> fetchKosztorys(String projektId) async {
    final resp = await _dio.get('/projekty/$projektId/kosztorys/pozycje/');
    return KosztorysApiModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<KosztorysPodsumowanieModel> fetchKosztorysSummary(String projektId) async {
    final resp = await _dio.get('/projekty/$projektId/kosztorys/');
    return KosztorysPodsumowanieModel.fromJson(resp.data as Map<String, dynamic>);
  }

  /// Aktualizacja cen jednostkowych. [ceny] = {lp: {cena_jedn_netto: X}}
  Future<KosztorysPodsumowanieModel> patchCeny(
      String projektId, Map<String, Map<String, double>> ceny) async {
    final resp = await _dio.patch(
      '/projekty/$projektId/ceny/',
      data: {'ceny': ceny},
    );
    return KosztorysPodsumowanieModel.fromJson(
        (resp.data as Map<String, dynamic>)['podsumowanie']
            as Map<String, dynamic>);
  }

  Future<String> createFromParsed({
    required String nazwa,
    required List<Map<String, dynamic>> pomieszczenia,
    required List<Map<String, dynamic>> pozycje,
  }) async {
    final resp = await _dio.post('/projekty/create/', data: {
      'nazwa': nazwa,
      'pomieszczenia': pomieszczenia,
      'pozycje': pozycje,
    });
    return (resp.data as Map<String, dynamic>)['projekt_id'] as String;
  }

  Future<Map<String, dynamic>> syncDb(String projektId) async {
    final resp = await _dio.post('/projekty/$projektId/sync/');
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchScene(String projektId) async {
    final resp = await _dio.get('/projekty/$projektId/scene/');
    return resp.data as Map<String, dynamic>;
  }

  String exportPdfUrl(String projektId) =>
      '${_dio.options.baseUrl}/projekty/$projektId/export/pdf/';

  String exportExcelUrl(String projektId) =>
      '${_dio.options.baseUrl}/projekty/$projektId/export/excel/';

  Future<PipelineStartResult> startPipeline(Uint8List bytes, String fileName) async {
    final form = FormData.fromMap({
      'plik': MultipartFile.fromBytes(bytes, filename: fileName),
    });
    final resp = await _dio.post(
      '/projekty-pipeline/start/',
      data: form,
      options: Options(receiveTimeout: const Duration(seconds: 120)),
    );
    return PipelineStartResult.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<PipelineStatusModel> fetchPipelineStatus(int pipelineId) async {
    final resp = await _dio.get('/projekty-pipeline/$pipelineId/status/');
    return PipelineStatusModel.fromJson(resp.data as Map<String, dynamic>);
  }
}

final projektyApiProvider = Provider<ProjektyApi>((ref) => ProjektyApi());
