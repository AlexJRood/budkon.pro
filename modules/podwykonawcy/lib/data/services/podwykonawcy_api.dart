import 'package:core/platform/budkon_api_client.dart';
import 'package:dio/dio.dart';
import '../models/podwykonawcy_model.dart';

class PodwykonawcyApi {
  final Dio _dio = budkonDio(receiveTimeout: const Duration(seconds: 20));

  // ---- Kontrahenci --------------------------------------------------------

  Future<List<KontrahentModel>> szukajKontrahentow(String q) async {
    final r = await _dio.get(
      '/kontakty/szukaj/',
      queryParameters: {'q': q, 'limit': 30},
    );
    final list0 = r.data is Map ? (r.data['results'] as List? ?? []) : r.data as List? ?? [];
    return list0
        .map((e) => KontrahentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<KontrahentModel> utworzKontrahenta(
      Map<String, dynamic> payload) async {
    final r = await _dio.post('/kontakty/', data: payload);
    return KontrahentModel.fromJson(r.data as Map<String, dynamic>);
  }

  Future<KontrahentModel> edytujKontrahenta(
      int id, Map<String, dynamic> payload) async {
    final r = await _dio.patch('/kontakty/$id/', data: payload);
    return KontrahentModel.fromJson(r.data as Map<String, dynamic>);
  }

  // ---- Powiązania --------------------------------------------------------

  Future<List<PowiazanieModel>> listaPowiazanBudowy(int budowaId) async {
    final r = await _dio.get(
      '/podwykonawcy/',
      queryParameters: {'budowa': budowaId},
    );
    final list1 = r.data is Map ? (r.data['results'] as List? ?? []) : r.data as List? ?? [];
    return list1
        .map((e) => PowiazanieModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PowiazanieModel> dodajPowiazanie(Map<String, dynamic> payload) async {
    final r = await _dio.post('/podwykonawcy/', data: payload);
    return PowiazanieModel.fromJson(r.data as Map<String, dynamic>);
  }

  Future<PowiazanieModel> edytujPowiazanie(
      int id, Map<String, dynamic> payload) async {
    final r = await _dio.patch('/podwykonawcy/$id/', data: payload);
    return PowiazanieModel.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> usunPowiazanie(int id) async {
    await _dio.delete('/podwykonawcy/$id/');
  }

  Future<PowiazanieModel> zmienStatus(int id, String status) async {
    final r =
        await _dio.patch('/podwykonawcy/$id/status/', data: {'status': status});
    return PowiazanieModel.fromJson(r.data as Map<String, dynamic>);
  }
}

final podwykonawcyApi = PodwykonawcyApi();
