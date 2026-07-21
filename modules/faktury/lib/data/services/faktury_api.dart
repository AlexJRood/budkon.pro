import 'package:core/platform/budkon_api_client.dart';
import 'package:dio/dio.dart';
import '../models/faktury_model.dart';

class FakturyApi {
  final Dio _dio = budkonDio(receiveTimeout: const Duration(seconds: 20));

  Future<List<FakturaListItem>> lista({int? budowaId, String? status}) async {
    final params = <String, dynamic>{};
    if (budowaId != null) params['budowa'] = budowaId;
    if (status != null) params['status'] = status;
    final r = await _dio.get('/faktury/', queryParameters: params);
    final data = r.data is Map ? r.data['results'] ?? r.data : r.data;
    return (data as List)
        .map((e) => FakturaListItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<FakturaDetail> szczegol(int id) async {
    final r = await _dio.get('/faktury/$id/');
    return FakturaDetail.fromJson(r.data as Map<String, dynamic>);
  }

  Future<FakturaDetail> utworz(Map<String, dynamic> payload) async {
    final r = await _dio.post('/faktury/', data: payload);
    return FakturaDetail.fromJson(r.data as Map<String, dynamic>);
  }

  Future<FakturaDetail> zOferty(int ofertaId, Map<String, dynamic> wystawca) async {
    final r = await _dio.post('/faktury/z-oferty/', data: {
      'oferta_id': ofertaId,
      ...wystawca,
    });
    return FakturaDetail.fromJson(r.data as Map<String, dynamic>);
  }

  Future<FakturaListItem> wyslij(int id) async {
    final r = await _dio.post('/faktury/$id/wyslij/');
    return FakturaListItem.fromJson(r.data as Map<String, dynamic>);
  }

  Future<FakturaListItem> oznaczOplacona(int id, {String? dataOplacenia}) async {
    final r = await _dio.post('/faktury/$id/oplacona/', data: {
      if (dataOplacenia != null) 'data_oplacenia': dataOplacenia,
    });
    return FakturaListItem.fromJson(r.data as Map<String, dynamic>);
  }

  Future<List<FakturaListItem>> doOplacenia() async {
    final r = await _dio.get('/faktury/do-oplacenia/');
    return (r.data as List)
        .map((e) => FakturaListItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final fakturyApi = FakturyApi();
