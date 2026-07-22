import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/budkon_api_client.dart';
import '../models/pod_rozliczenia_model.dart';

class PodRozliczeniaApi {
  final Dio _dio;
  PodRozliczeniaApi(this._dio);

  Future<List<FakturaPodwykonawcyModel>> fetchFaktury(int budowaId) async {
    final r = await _dio.get('/pod-rozliczenia/faktury/', queryParameters: {'budowa': budowaId});
    return (r.data as List).map((e) => FakturaPodwykonawcyModel.fromJson(e)).toList();
  }

  Future<FakturaPodwykonawcyModel> createFaktura(FakturaPodwykonawcyModel f) async {
    final r = await _dio.post('/pod-rozliczenia/faktury/', data: f.toJson());
    return FakturaPodwykonawcyModel.fromJson(r.data);
  }

  Future<FakturaPodwykonawcyModel> updateStatus(
      int id, StatusRozliczeniaPod status) async {
    final r = await _dio.patch('/pod-rozliczenia/faktury/$id/', data: {
      'status': status.apiValue,
      if (status == StatusRozliczeniaPod.oplacone)
        'data_oplaty': DateTime.now().toIso8601String(),
    });
    return FakturaPodwykonawcyModel.fromJson(r.data);
  }

  Future<List<ZwrotKaucjiModel>> fetchZwroty(int budowaId) async {
    final r = await _dio.get('/pod-rozliczenia/zwroty/', queryParameters: {'budowa': budowaId});
    return (r.data as List).map((e) => ZwrotKaucjiModel.fromJson(e)).toList();
  }

  Future<ZwrotKaucjiModel> zwrocKaucje(int fakturaId, double kwota) async {
    final r = await _dio.post('/pod-rozliczenia/zwroty/', data: {
      'faktura': fakturaId,
      'kwota': kwota,
      'data_zwrotu': DateTime.now().toIso8601String(),
    });
    return ZwrotKaucjiModel.fromJson(r.data);
  }

  Future<List<PodwykonawcaRozliczeniaStats>> fetchStats(int budowaId) async {
    final r = await _dio.get('/pod-rozliczenia/stats/', queryParameters: {'budowa': budowaId});
    return (r.data as List).map((e) => PodwykonawcaRozliczeniaStats.fromJson(e)).toList();
  }
}

final podRozliczeniaApiProvider = Provider<PodRozliczeniaApi>(
  (ref) => PodRozliczeniaApi(ref.read(budkonDioProvider)),
);
