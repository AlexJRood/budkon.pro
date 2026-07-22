import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/budkon_api_client.dart';
import '../models/magazyn_model.dart';

class MagazynApi {
  final Dio _dio;
  MagazynApi(this._dio);

  Future<List<MagazynPozycjaModel>> fetchPozycje(int budowaId) async {
    final r = await _dio.get('/magazyn/pozycje/', queryParameters: {'budowa': budowaId});
    return (r.data as List).map((e) => MagazynPozycjaModel.fromJson(e)).toList();
  }

  Future<MagazynPozycjaModel> fetchPozycja(int id) async {
    final r = await _dio.get('/magazyn/pozycje/$id/');
    return MagazynPozycjaModel.fromJson(r.data);
  }

  Future<MagazynPozycjaModel> createPozycja(MagazynPozycjaModel p) async {
    final r = await _dio.post('/magazyn/pozycje/', data: p.toJson());
    return MagazynPozycjaModel.fromJson(r.data);
  }

  Future<MagazynPozycjaModel> updatePozycja(MagazynPozycjaModel p) async {
    final r = await _dio.patch('/magazyn/pozycje/${p.id}/', data: p.toJson());
    return MagazynPozycjaModel.fromJson(r.data);
  }

  Future<void> deletePozycja(int id) => _dio.delete('/magazyn/pozycje/$id/');

  Future<List<MagazynRuchModel>> fetchRuchy(int pozycjaId) async {
    final r = await _dio.get('/magazyn/ruchy/', queryParameters: {'pozycja': pozycjaId});
    return (r.data as List).map((e) => MagazynRuchModel.fromJson(e)).toList();
  }

  Future<List<MagazynRuchModel>> fetchRuchyBudowy(int budowaId) async {
    final r = await _dio.get('/magazyn/ruchy/', queryParameters: {'budowa': budowaId});
    return (r.data as List).map((e) => MagazynRuchModel.fromJson(e)).toList();
  }

  Future<MagazynRuchModel> addRuch(MagazynRuchModel ruch) async {
    final r = await _dio.post('/magazyn/ruchy/', data: ruch.toJson());
    return MagazynRuchModel.fromJson(r.data);
  }
}

final magazynApiProvider = Provider<MagazynApi>(
  (ref) => MagazynApi(ref.read(budkonDioProvider)),
);
