import 'package:core/platform/budkon_api_client.dart';
import 'package:dio/dio.dart';

import '../models/bzp_wynik_model.dart';

class PrzetargiApi {
  final Dio _dio = budkonDio(receiveTimeout: const Duration(seconds: 30));

  // ------------------------------------------------------------------ //
  // Przetargi                                                            //
  // ------------------------------------------------------------------ //

  Future<List<Map<String, dynamic>>> listPrzetargi({
    String? status,
    bool? czyWarto,
    String? q,
  }) async {
    final params = <String, dynamic>{};
    if (status != null) params['status'] = status;
    if (czyWarto != null) params['czy_warto'] = czyWarto.toString();
    if (q != null && q.isNotEmpty) params['q'] = q;

    final resp = await _dio.get('/przetargi/', queryParameters: params);
    final raw = resp.data is Map ? (resp.data['results'] as List? ?? []) : resp.data as List? ?? [];
    return List<Map<String, dynamic>>.from(raw);
  }

  Future<Map<String, dynamic>> getPrzetarg(int id) async {
    final resp = await _dio.get('/przetargi/$id/');
    return Map<String, dynamic>.from(resp.data as Map);
  }

  Future<Map<String, dynamic>> createPrzetarg(
      Map<String, dynamic> data) async {
    final resp = await _dio.post('/przetargi/', data: data);
    return Map<String, dynamic>.from(resp.data as Map);
  }

  Future<void> deletePrzetarg(int id) =>
      _dio.delete('/przetargi/$id/');

  // ------------------------------------------------------------------ //
  // Akcje                                                                //
  // ------------------------------------------------------------------ //

  Future<Map<String, dynamic>> fetch() async {
    final resp = await _dio.post('/przetargi/fetch/');
    return Map<String, dynamic>.from(resp.data as Map);
  }

  Future<Map<String, dynamic>> analizuj(int id) async {
    final resp = await _dio.post('/przetargi/$id/analizuj/');
    return Map<String, dynamic>.from(resp.data as Map);
  }

  Future<Map<String, dynamic>> generujKosztorys(int id) async {
    final resp = await _dio.post(
      '/przetargi/$id/generuj-kosztorys/',
      options: Options(receiveTimeout: const Duration(seconds: 120)),
    );
    return Map<String, dynamic>.from(resp.data as Map);
  }

  Future<void> zmienStatus(int id, String status) =>
      _dio.patch('/przetargi/$id/status/', data: {'status': status});

  // ------------------------------------------------------------------ //
  // Emma inbox                                                           //
  // ------------------------------------------------------------------ //

  Future<List<Map<String, dynamic>>> emmaInbox() async {
    final resp = await _dio.get('/emma-inbox/');
    final raw = resp.data is Map ? (resp.data['results'] as List? ?? []) : resp.data as List? ?? [];
    return List<Map<String, dynamic>>.from(raw);
  }

  Future<void> emmaAkceptuj(int id) =>
      _dio.post('/emma-inbox/$id/akceptuj/');

  Future<void> emmaOdrzuc(int id) =>
      _dio.post('/emma-inbox/$id/odrzuc/');

  // ------------------------------------------------------------------ //
  // Subskrypcje                                                          //
  // ------------------------------------------------------------------ //

  Future<List<Map<String, dynamic>>> listSubskrypcje() async {
    final resp = await _dio.get('/przetargi-subskrypcje/');
    final raw = resp.data is Map ? (resp.data['results'] as List? ?? []) : resp.data as List? ?? [];
    return List<Map<String, dynamic>>.from(raw);
  }

  Future<Map<String, dynamic>> createSubskrypcja(
      Map<String, dynamic> data) async {
    final resp = await _dio.post('/przetargi-subskrypcje/', data: data);
    return Map<String, dynamic>.from(resp.data as Map);
  }

  Future<Map<String, dynamic>> updateSubskrypcja(
      int id, Map<String, dynamic> data) async {
    final resp = await _dio.patch('/przetargi-subskrypcje/$id/', data: data);
    return Map<String, dynamic>.from(resp.data as Map);
  }

  Future<void> deleteSubskrypcja(int id) =>
      _dio.delete('/przetargi-subskrypcje/$id/');

  // ------------------------------------------------------------------ //
  // BZP na żywo                                                         //
  // ------------------------------------------------------------------ //

  Future<(List<BzpWynikModel>, int)> szukajBzp({
    String? fraza,
    String? cpv,
    int dniWstecz = 30,
    int strona = 1,
    int naStronie = 20,
  }) async {
    final params = <String, dynamic>{
      'na_stronie': naStronie,
      'strona': strona,
      'dni_wstecz': dniWstecz,
    };
    if (fraza != null && fraza.isNotEmpty) params['q'] = fraza;
    if (cpv != null && cpv.isNotEmpty) params['cpv'] = cpv;

    final resp = await _dio.get(
      '/przetargi/szukaj-bzp/',
      queryParameters: params,
      options: Options(receiveTimeout: const Duration(seconds: 60)),
    );

    final data = resp.data as Map<String, dynamic>;
    final total = data['count'] as int? ?? 0;
    final raw = (data['results'] as List?) ?? [];
    final wyniki = raw
        .cast<Map<String, dynamic>>()
        .map(BzpWynikModel.fromJson)
        .toList();
    return (wyniki, total);
  }
}
