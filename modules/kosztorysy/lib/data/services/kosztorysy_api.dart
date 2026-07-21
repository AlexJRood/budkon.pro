import 'package:core/platform/budkon_api_client.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/kosztorys_model.dart';

final kosztorysyApiProvider =
    Provider((ref) => KosztorysyApi(ref.watch(budkonDioProvider)));

class KosztorysyApi {
  KosztorysyApi(this._dio);
  final Dio _dio;

  Options get _opts =>
      Options(headers: {'X-Company-Id': '1'}); // TODO: z userSessionProvider

  // ── Kosztorysy ──────────────────────────────────────────────────────────────

  Future<List<KosztorysListItemModel>> fetchList({int? budowaId}) async {
    final resp = await _dio.get(
      '/kosztorysy/',
      queryParameters: budowaId != null ? {'budowa': budowaId} : null,
      options: _opts,
    );
    final results = resp.data['results'] as List? ?? [];
    return results
        .map((e) =>
            KosztorysListItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<KosztorysModel> fetchOne(int id) async {
    final resp = await _dio.get('/kosztorysy/$id/', options: _opts);
    return KosztorysModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<KosztorysModel> create(Map<String, dynamic> data) async {
    final resp = await _dio.post('/kosztorysy/', data: jsonEncode(data), options: _opts);
    return KosztorysModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<KosztorysModel> update(int id, Map<String, dynamic> patch) async {
    final resp =
        await _dio.patch('/kosztorysy/$id/', data: jsonEncode(patch), options: _opts);
    return KosztorysModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<void> delete(int id) => _dio.delete('/kosztorysy/$id/', options: _opts);

  // ── AI generate ─────────────────────────────────────────────────────────────

  Future<KosztorysModel> aiGenerate(
    int id, {
    required String opis,
    Map<String, dynamic>? obmiar,
  }) async {
    final resp = await _dio.post(
      '/kosztorysy/$id/ai-generate/',
      data: jsonEncode({'opis': opis, 'obmiar': obmiar ?? {}}),
      options: Options(
        headers: {'X-Company-Id': '1'},
        receiveTimeout: const Duration(seconds: 120),
      ),
    );
    return KosztorysModel.fromJson(resp.data as Map<String, dynamic>);
  }

  // ── Pozycje (inline edit) ──────────────────────────────────────────────────

  Future<KosztorysPozycjaModel> updatePozycja(
      int id, Map<String, dynamic> patch) async {
    final resp = await _dio.patch(
      '/kosztorysy-pozycje/$id/',
      data: jsonEncode(patch),
      options: _opts,
    );
    return KosztorysPozycjaModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<KosztorysPozycjaModel> createPozycja(
      Map<String, dynamic> data) async {
    final resp = await _dio.post(
      '/kosztorysy-pozycje/',
      data: jsonEncode(data),
      options: _opts,
    );
    return KosztorysPozycjaModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<void> deletePozycja(int id) =>
      _dio.delete('/kosztorysy-pozycje/$id/', options: _opts);

  // ── Import pozycji z projektu ───────────────────────────────────────────────

  Future<void> importProjektPozycje(
    int kosztorysId,
    List<Map<String, dynamic>> pozycje,
  ) async {
    await _dio.post(
      '/kosztorysy/$kosztorysId/import-pozycje/',
      data: {'pozycje': pozycje},
      options: Options(
        headers: {'X-Company-Id': '1'},
        receiveTimeout: const Duration(seconds: 60),
      ),
    );
  }

  // ── KNR search ──────────────────────────────────────────────────────────────

  Future<List<KnrPozycjaModel>> searchKnr(String q) async {
    final resp = await _dio.get(
      '/knr/pozycje/',
      queryParameters: {'q': q},
      options: _opts,
    );
    final results = resp.data['results'] as List? ?? [];
    return results
        .map((e) => KnrPozycjaModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
