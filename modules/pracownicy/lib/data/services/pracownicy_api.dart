import 'package:core/platform/budkon_api_client.dart';
import 'package:dio/dio.dart';
import '../models/pracownicy_model.dart';

final _dio = budkonDio();

class PracownicyApi {
  Future<List<PracownikListItem>> lista({String? q, String? specjalizacja}) async {
    final r = await _dio.get('/pracownicy/', queryParameters: {
      if (q != null && q.isNotEmpty) 'q': q,
      if (specjalizacja != null) 'specjalizacja': specjalizacja,
      'aktywni': '1',
    });
    final list = r.data is Map ? (r.data['results'] as List? ?? []) : r.data as List? ?? [];
    return list
        .map((e) => PracownikListItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PracownikDetail> szczegol(int id) async {
    final r = await _dio.get('/pracownicy/$id/');
    return PracownikDetail.fromJson(r.data as Map<String, dynamic>);
  }

  Future<PracownikDetail> utworz(Map<String, dynamic> dane) async {
    final r = await _dio.post('/pracownicy/', data: dane);
    return PracownikDetail.fromJson(r.data as Map<String, dynamic>);
  }

  Future<PracownikDetail> aktualizuj(int id, Map<String, dynamic> dane) async {
    final r = await _dio.patch('/pracownicy/$id/', data: dane);
    return PracownikDetail.fromJson(r.data as Map<String, dynamic>);
  }

  Future<List<PracownikDetail>> doBudowy(int budowaId) async {
    final r = await _dio.get('/pracownicy/do-budowy/',
        queryParameters: {'budowa_id': budowaId});
    final dlist = r.data is Map ? (r.data['results'] as List? ?? []) : r.data as List? ?? [];
    return dlist
        .map((e) => PracownikDetail.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<UmiejetnoscModel> dodajUmiejetnosc(
      int pracownikId, Map<String, dynamic> dane) async {
    final r = await _dio.post(
        '/pracownicy/$pracownikId/umiejetnosci/', data: dane);
    return UmiejetnoscModel.fromJson(r.data as Map<String, dynamic>);
  }

  Future<UmiejetnoscModel> edytujUmiejetnosc(
      int pracownikId, int umId, Map<String, dynamic> dane) async {
    final r = await _dio.patch(
        '/pracownicy/$pracownikId/umiejetnosci/$umId/', data: dane);
    return UmiejetnoscModel.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> usunUmiejetnosc(int pracownikId, int umId) =>
      _dio.delete('/pracownicy/$pracownikId/umiejetnosci/$umId/');

  Future<void> dodajStawke(
      int pracownikId, double stawka, String dataOd) async {
    await _dio.post('/pracownicy/$pracownikId/stawka/', data: {
      'stawka_godz': stawka,
      'data_od': dataOd,
    });
  }

  /// AI endpoint — dobierz pracowników do pozycji KNR
  Future<List<Map<String, dynamic>>> dobierzDoKnr({
    required String specjalizacja,
    int? budowaId,
    int ilosc = 1,
  }) async {
    final r = await _dio.get('/pracownicy/dobierz-do-knr/', queryParameters: {
      'specjalizacja': specjalizacja,
      if (budowaId != null) 'budowa_id': budowaId,
      'ilosc': ilosc,
    });
    return (r.data as List).cast<Map<String, dynamic>>();
  }

  Future<void> przypiszDoBudowy({
    required int pracownikId,
    required int budowaId,
    String rola = '',
    String? dataOd,
  }) async {
    await _dio.post('/pracownicy-na-budowie/', data: {
      'pracownik_id': pracownikId,
      'budowa_id': budowaId,
      'rola_na_budowie': rola,
      if (dataOd != null) 'data_od': dataOd,
    });
  }
}

final pracownicyApi = PracownicyApi();
