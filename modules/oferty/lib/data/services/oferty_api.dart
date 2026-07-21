import 'package:core/platform/budkon_api_client.dart';
import 'package:core/platform/url.dart';
import 'package:dio/dio.dart';
import '../models/oferty_model.dart';

final _dio = budkonDio();

class OfertyApi {
  Future<List<OfertyListItem>> lista({int? budowaId, String? status}) async {
    final r = await _dio.get('/oferty/', queryParameters: {
      if (budowaId != null) 'budowa': budowaId,
      if (status != null) 'status': status,
    });
    final list = r.data is Map ? (r.data['results'] as List? ?? []) : r.data as List? ?? [];
    return list
        .map((e) => OfertyListItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<OfertyDetail> szczegol(int id) async {
    final r = await _dio.get('/oferty/$id/');
    return OfertyDetail.fromJson(r.data as Map<String, dynamic>);
  }

  Future<OfertyDetail> zKosztorysu(Map<String, dynamic> dane) async {
    final r = await _dio.post('/oferty/z-kosztorysu/', data: dane);
    return OfertyDetail.fromJson(r.data as Map<String, dynamic>);
  }

  Future<OfertyDetail> aktualizuj(int id, Map<String, dynamic> dane) async {
    final r = await _dio.patch('/oferty/$id/', data: dane);
    return OfertyDetail.fromJson(r.data as Map<String, dynamic>);
  }

  Future<OfertyDetail> zmienStatus(int id, String status,
      {String uwagi = ''}) async {
    final r = await _dio.patch('/oferty/$id/status/', data: {
      'status': status,
      if (uwagi.isNotEmpty) 'uwagi': uwagi,
    });
    return OfertyDetail.fromJson(r.data as Map<String, dynamic>);
  }

  Future<OfertyDetail> duplikuj(int id) async {
    final r = await _dio.post('/oferty/$id/duplikuj/');
    return OfertyDetail.fromJson(r.data as Map<String, dynamic>);
  }

  /// Zwraca URL do PDF (inline view lub download).
  String pdfUrl(int id, {bool download = false}) =>
      '${URLs.baseUrl}/api/v1/oferty/$id/pdf/'
      '?X-Company-Id=1${download ? '&download=1' : ''}';

  /// Wyzwala (re)generowanie PDF na backendzie.
  Future<void> generujPdf(int id) async {
    await _dio.post('/oferty/$id/pdf/');
  }
}

final ofertyApi = OfertyApi();
