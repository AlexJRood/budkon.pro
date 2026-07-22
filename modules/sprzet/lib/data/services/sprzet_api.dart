import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/budkon_api_client.dart';
import '../models/sprzet_model.dart';

class SprzetApi {
  final Dio _dio;
  SprzetApi(this._dio);

  Future<List<SprzetModel>> fetchSprzet({int? budowaId}) async {
    final r = await _dio.get('/sprzet/',
        queryParameters: budowaId != null ? {'budowa': budowaId} : null);
    return (r.data as List).map((e) => SprzetModel.fromJson(e)).toList();
  }

  Future<SprzetModel> fetchSprzetOne(int id) async {
    final r = await _dio.get('/sprzet/$id/');
    return SprzetModel.fromJson(r.data);
  }

  Future<SprzetModel> createSprzet(SprzetModel s) async {
    final r = await _dio.post('/sprzet/', data: s.toJson());
    return SprzetModel.fromJson(r.data);
  }

  Future<SprzetModel> updateSprzet(SprzetModel s) async {
    final r = await _dio.patch('/sprzet/${s.id}/', data: s.toJson());
    return SprzetModel.fromJson(r.data);
  }

  Future<SprzetModel> updateStatus(int id, StatusSprzetu status) async {
    final r = await _dio.patch('/sprzet/$id/', data: {'status': status.apiValue});
    return SprzetModel.fromJson(r.data);
  }

  Future<List<WypozyczenieModel>> fetchWypozyczenia({int? sprzetId, int? budowaId}) async {
    final r = await _dio.get('/sprzet/wypozyczenia/', queryParameters: {
      if (sprzetId != null) 'sprzet': sprzetId,
      if (budowaId != null) 'budowa': budowaId,
    });
    return (r.data as List).map((e) => WypozyczenieModel.fromJson(e)).toList();
  }

  Future<WypozyczenieModel> wypozycz(WypozyczenieModel w) async {
    final r = await _dio.post('/sprzet/wypozyczenia/', data: w.toJson());
    return WypozyczenieModel.fromJson(r.data);
  }

  Future<WypozyczenieModel> zwroc(int id) async {
    final r = await _dio.patch('/sprzet/wypozyczenia/$id/', data: {
      'data_do': DateTime.now().toIso8601String(),
    });
    return WypozyczenieModel.fromJson(r.data);
  }
}

final sprzetApiProvider = Provider<SprzetApi>(
  (ref) => SprzetApi(ref.read(budkonDioProvider)),
);
