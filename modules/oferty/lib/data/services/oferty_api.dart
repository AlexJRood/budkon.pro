import 'package:dio/dio.dart';
import '../models/oferty_model.dart';

final _dio = Dio(BaseOptions(
  baseUrl: 'http://127.0.0.1:8001/api/v1',
  headers: {'X-Company-Id': '1'},
));

class OfertyApi {
  Future<List<OfertyListItem>> lista({int? budowaId, String? status}) async {
    final r = await _dio.get('/oferty/', queryParameters: {
      if (budowaId != null) 'budowa': budowaId,
      if (status != null) 'status': status,
    });
    return (r.data as List)
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
      'http://127.0.0.1:8001/api/v1/oferty/$id/pdf/'
      '?X-Company-Id=1${download ? '&download=1' : ''}';

  /// Wyzwala (re)generowanie PDF na backendzie.
  Future<void> generujPdf(int id) async {
    await _dio.post('/oferty/$id/pdf/');
  }
}

final ofertyApi = OfertyApi();
