import 'package:core/platform/budkon_api_client.dart';
import 'package:dio/dio.dart';
import '../models/materialy_model.dart';

final _dio = budkonDio();

class MaterialyApi {
  // ---- Materiały (katalog) ------------------------------------------------

  Future<List<MaterialModel>> listaMaterialow({
    String? q,
    String? kategoria,
  }) async {
    final r = await _dio.get('/materialy/', queryParameters: {
      if (q != null && q.isNotEmpty) 'q': q,
      if (kategoria != null) 'kategoria': kategoria,
    });
    final list = r.data is Map ? (r.data['results'] as List? ?? []) : r.data as List? ?? [];
    return list
        .map((e) => MaterialModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<MaterialModel> szczegolMaterialu(int id) async {
    final r = await _dio.get('/materialy/$id/');
    return MaterialModel.fromJson(r.data as Map<String, dynamic>);
  }

  Future<MaterialModel> utworzMaterial(Map<String, dynamic> dane) async {
    final r = await _dio.post('/materialy/', data: dane);
    return MaterialModel.fromJson(r.data as Map<String, dynamic>);
  }

  Future<MaterialModel> edytujMaterial(
      int id, Map<String, dynamic> dane) async {
    final r = await _dio.patch('/materialy/$id/', data: dane);
    return MaterialModel.fromJson(r.data as Map<String, dynamic>);
  }

  Future<MaterialModel> dodajCene(
    int materialId, {
    required double cenaNetto,
    String zrodlo = 'reczne',
    String uwagi = '',
  }) async {
    final r = await _dio.post('/materialy/$materialId/cena/', data: {
      'cena_netto': cenaNetto,
      'zrodlo': zrodlo,
      if (uwagi.isNotEmpty) 'uwagi': uwagi,
    });
    return MaterialModel.fromJson(r.data as Map<String, dynamic>);
  }

  Future<List<HistoriaCenyModel>> historiaCen(int materialId,
      {int dni = 90}) async {
    final r = await _dio.get(
      '/materialy/$materialId/historia/',
      queryParameters: {'dni': dni},
    );
    final hlist = r.data is Map ? (r.data['results'] as List? ?? []) : r.data as List? ?? [];
    return hlist
        .map((e) => HistoriaCenyModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Map<String, dynamic>>> trendy() async {
    final r = await _dio.get('/materialy/trendy/');
    return (r.data as List).cast<Map<String, dynamic>>();
  }

  // ---- Pozycje zamówień ---------------------------------------------------

  Future<List<PozycjaZamowieniaModel>> listaPozycji({
    int? budowaId,
    int? kosztorysId,
    String? status,
  }) async {
    final r = await _dio.get('/zamowienia-pozycje/', queryParameters: {
      if (budowaId != null) 'budowa': budowaId,
      if (kosztorysId != null) 'kosztorys': kosztorysId,
      if (status != null) 'status': status,
    });
    final plist = r.data is Map ? (r.data['results'] as List? ?? []) : r.data as List? ?? [];
    return plist
        .map((e) =>
            PozycjaZamowieniaModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PozycjaZamowieniaModel> zmienStatus(
      int id, String nowyStatus) async {
    final r = await _dio.patch(
      '/zamowienia-pozycje/$id/status/',
      data: {'status': nowyStatus},
    );
    return PozycjaZamowieniaModel.fromJson(r.data as Map<String, dynamic>);
  }

  Future<PozycjaZamowieniaModel> aktualizujDostawe(
      int id, double iloscDostarczona) async {
    final r = await _dio.patch(
      '/zamowienia-pozycje/$id/dostawa/',
      data: {'ilosc_dostarczona': iloscDostarczona},
    );
    return PozycjaZamowieniaModel.fromJson(r.data as Map<String, dynamic>);
  }

  Future<List<PozycjaZamowieniaModel>> importujZKosztorysu({
    required int budowaId,
    required int kosztorysId,
    required List<Map<String, dynamic>> pozycje,
  }) async {
    final r = await _dio.post('/zamowienia-pozycje/z-kosztorysu/', data: {
      'budowa_id': budowaId,
      'kosztorys_id': kosztorysId,
      'pozycje': pozycje,
    });
    final ilist = r.data is Map ? (r.data['results'] as List? ?? []) : r.data as List? ?? [];
    return ilist
        .map((e) =>
            PozycjaZamowieniaModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final materialyApi = MaterialyApi();
