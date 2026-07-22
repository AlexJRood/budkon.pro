import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/budkon_api_client.dart';
import '../models/ai_asystent_model.dart';

class AiAsystentApi {
  final Dio _dio;
  AiAsystentApi(this._dio);

  // ---- Dziennik głosowy ----

  Future<List<WpisDziennikModel>> fetchWpisy(int budowaId) async {
    final r = await _dio.get('/ai/dziennik/', queryParameters: {'budowa_id': budowaId});
    return (r.data as List).map((e) => WpisDziennikModel.fromJson(e)).toList();
  }

  Future<WpisDziennikModel> wyslijAudio(int budowaId, File audio) async {
    final form = FormData.fromMap({
      'budowa_id': budowaId,
      'audio': await MultipartFile.fromFile(audio.path),
    });
    final r = await _dio.post('/ai/dziennik/wyslij/', data: form);
    return WpisDziennikModel.fromJson(r.data);
  }

  Future<WpisDziennikModel> fetchWpis(int id) async {
    final r = await _dio.get('/ai/dziennik/$id/');
    return WpisDziennikModel.fromJson(r.data);
  }

  // ---- Analiza zdjęć ----

  Future<List<AnalizaZdjeciaModel>> fetchAnalizy(int budowaId) async {
    final r = await _dio.get('/ai/analiza-zdjec/', queryParameters: {'budowa_id': budowaId});
    return (r.data as List).map((e) => AnalizaZdjeciaModel.fromJson(e)).toList();
  }

  Future<AnalizaZdjeciaModel> analizujZdjecie(
      int budowaId, File zdjecie, TypAnalizy typ) async {
    final form = FormData.fromMap({
      'budowa_id': budowaId,
      'typ': typ.name,
      'zdjecie': await MultipartFile.fromFile(zdjecie.path),
    });
    final r = await _dio.post('/ai/analiza-zdjec/analizuj/', data: form);
    return AnalizaZdjeciaModel.fromJson(r.data);
  }

  // ---- Predykcja kosztów ----

  Future<PredykcjaKosztowModel> fetchPredykcja(int budowaId) async {
    final r = await _dio.get('/ai/predykcja-kosztow/$budowaId/');
    return PredykcjaKosztowModel.fromJson(r.data);
  }

  Future<PredykcjaKosztowModel> odswiezPredykcje(int budowaId) async {
    final r = await _dio.post('/ai/predykcja-kosztow/$budowaId/odswiez/');
    return PredykcjaKosztowModel.fromJson(r.data);
  }

  // ---- Chat ----

  Future<String> zapytaj(int budowaId, String pytanie,
      List<WiadomoscCzatModel> historia) async {
    final r = await _dio.post('/ai/czat/', data: {
      'budowa_id': budowaId,
      'pytanie': pytanie,
      'historia': historia
          .map((m) => {'rola': m.rola.name, 'tresc': m.tresc})
          .toList(),
    });
    return r.data['odpowiedz'] ?? '';
  }
}

final aiAsystentApiProvider = Provider<AiAsystentApi>(
  (ref) => AiAsystentApi(ref.read(budkonDioProvider)),
);
