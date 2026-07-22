import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/budkon_api_client.dart';
import '../models/integracje_model.dart';

class IntegracjeApi {
  final Dio _dio;
  IntegracjeApi(this._dio);

  // ---- GUS / CEIDG ----
  Future<FirmaGusModel> szukajFirmyNIP(String nip) async {
    final r = await _dio.get('/integracje/gus/nip/', queryParameters: {'nip': nip});
    return FirmaGusModel.fromJson(r.data);
  }

  Future<List<FirmaGusModel>> szukajFirmyNazwa(String fraza) async {
    final r = await _dio.get('/integracje/gus/szukaj/', queryParameters: {'fraza': fraza});
    return (r.data as List).map((e) => FirmaGusModel.fromJson(e)).toList();
  }

  // ---- KSeF ----
  Future<KsefStatusModel> wyslijDoKsef(int fakturaId) async {
    final r = await _dio.post('/integracje/ksef/wyslij/', data: {'faktura_id': fakturaId});
    return KsefStatusModel.fromJson(r.data);
  }

  Future<KsefStatusModel> sprawdzStatusKsef(int fakturaId) async {
    final r = await _dio.get('/integracje/ksef/status/$fakturaId/');
    return KsefStatusModel.fromJson(r.data);
  }

  Future<List<KsefStatusModel>> fetchKsefHistory() async {
    final r = await _dio.get('/integracje/ksef/historia/');
    return (r.data as List).map((e) => KsefStatusModel.fromJson(e)).toList();
  }

  // ---- e-Zamówienia ----
  Future<List<PrzetargPublicznyModel>> szukajPrzetargow({
    String? fraza,
    String? cpv,
    int strona = 1,
  }) async {
    final r = await _dio.get('/integracje/ezamowienia/szukaj/', queryParameters: {
      if (fraza != null) 'fraza': fraza,
      if (cpv != null) 'cpv': cpv,
      'strona': strona,
    });
    return (r.data as List).map((e) => PrzetargPublicznyModel.fromJson(e)).toList();
  }
}

final integracjeApiProvider = Provider<IntegracjeApi>(
  (ref) => IntegracjeApi(ref.read(budkonDioProvider)),
);
