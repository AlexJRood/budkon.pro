import 'package:core/platform/budkon_api_client.dart';
import 'package:dio/dio.dart';
import '../models/dziennik_model.dart';

class DziennikApi {
  final Dio _dio = budkonDio(receiveTimeout: const Duration(seconds: 30));

  // ---- Lista wpisów -------------------------------------------------------

  Future<List<WpisListItem>> lista({
    required int budowaId,
    int? rok,
    int? miesiac,
  }) async {
    final params = <String, dynamic>{'budowa': budowaId};
    if (rok != null) params['rok'] = rok;
    if (miesiac != null) params['miesiac'] = miesiac;

    final r = await _dio.get('/dziennik/', queryParameters: params);
    final list = r.data is Map ? (r.data['results'] as List? ?? []) : r.data as List? ?? [];
    return list
        .map((e) => WpisListItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ---- Szczegół -----------------------------------------------------------

  Future<WpisDetail> szczegol(int id) async {
    final r = await _dio.get('/dziennik/$id/');
    return WpisDetail.fromJson(r.data as Map<String, dynamic>);
  }

  // ---- Auto-uzupełnianie --------------------------------------------------

  Future<AutoUzupelnijData> autoUzupelnij({
    required int budowaId,
    String? data,
  }) async {
    final params = <String, dynamic>{'budowa': budowaId};
    if (data != null) params['data'] = data;

    final r = await _dio.get(
      '/dziennik/auto-uzupelnij/',
      queryParameters: params,
    );
    return AutoUzupelnijData.fromJson(r.data as Map<String, dynamic>);
  }

  // ---- Tworzenie ----------------------------------------------------------

  Future<WpisDetail> utwoz(Map<String, dynamic> payload) async {
    final r = await _dio.post('/dziennik/', data: payload);
    return WpisDetail.fromJson(r.data as Map<String, dynamic>);
  }

  // ---- Edycja -------------------------------------------------------------

  Future<WpisDetail> edytuj(int id, Map<String, dynamic> payload) async {
    final r = await _dio.patch('/dziennik/$id/', data: payload);
    return WpisDetail.fromJson(r.data as Map<String, dynamic>);
  }

  // ---- Usuwanie -----------------------------------------------------------

  Future<void> usun(int id) async {
    await _dio.delete('/dziennik/$id/');
  }

  // ---- Zdjęcia ------------------------------------------------------------

  Future<ZdjecieModel> dodajZdjecie(
    int wpisId,
    MultipartFile plik, {
    String opis = '',
  }) async {
    final form = FormData.fromMap({'plik': plik, 'opis': opis});
    final r = await _dio.post('/dziennik/$wpisId/dodaj-zdjecie/', data: form);
    return ZdjecieModel.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> usunZdjecie(int wpisId, int zdjecieId) async {
    await _dio.delete('/dziennik/$wpisId/zdjecia/$zdjecieId/');
  }

  // ---- Markety ------------------------------------------------------------

  Future<({double budowaLat, double budowaLon, List<MarketBudowlany> markety})>
      marketyBudowlane({
    required int budowaId,
    int radiusM = 15000,
  }) async {
    final r = await _dio.get(
      '/dziennik/markety-budowlane/',
      queryParameters: {'budowa': budowaId, 'radius': radiusM},
    );
    final data = r.data as Map<String, dynamic>;
    return (
      budowaLat: (data['budowa_lat'] as num).toDouble(),
      budowaLon: (data['budowa_lon'] as num).toDouble(),
      markety: (data['wyniki'] as List)
          .map((e) => MarketBudowlany.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  // ---- Statystyki ---------------------------------------------------------

  Future<Map<String, dynamic>> statystyki(int budowaId) async {
    final r = await _dio.get(
      '/dziennik/statystyki/',
      queryParameters: {'budowa': budowaId},
    );
    return r.data as Map<String, dynamic>;
  }
}

final dziennikApi = DziennikApi();
