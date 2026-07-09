import 'package:dio/dio.dart';
import '../models/kontakty_model.dart';

class KontaktyApi {
  static const _base = 'http://127.0.0.1:8001/api/v1';
  static const _headers = {'X-Company-Id': '1'};

  final Dio _dio = Dio(BaseOptions(
    baseUrl: _base,
    headers: _headers,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 20),
  ));

  Future<List<KontrahentListItem>> lista({String? q, String? branza}) async {
    final params = <String, dynamic>{};
    if (q != null && q.isNotEmpty) params['q'] = q;
    if (branza != null) params['branza'] = branza;
    final r = await _dio.get('/kontakty/', queryParameters: params);
    final data = r.data is Map ? r.data['results'] ?? r.data : r.data;
    return (data as List)
        .map((e) => KontrahentListItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<KontrahentDetail> szczegol(int id) async {
    final r = await _dio.get('/kontakty/$id/');
    return KontrahentDetail.fromJson(r.data as Map<String, dynamic>);
  }

  Future<KontrahentDetail> utworz(Map<String, dynamic> payload) async {
    final r = await _dio.post('/kontakty/', data: payload);
    return KontrahentDetail.fromJson(r.data as Map<String, dynamic>);
  }

  Future<KontrahentDetail> edytuj(int id, Map<String, dynamic> payload) async {
    final r = await _dio.patch('/kontakty/$id/', data: payload);
    return KontrahentDetail.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> usun(int id) async {
    await _dio.delete('/kontakty/$id/');
  }
}

final kontaktyApi = KontaktyApi();
