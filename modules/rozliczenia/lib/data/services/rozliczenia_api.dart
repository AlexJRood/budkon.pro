import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/budkon_api_client.dart';
import '../models/rozliczenia_model.dart';

class RozliczeniaApi {
  final Dio _dio;
  RozliczeniaApi(this._dio);

  Future<List<FakturaModel>> fetchFaktury(int budowaId) async {
    final r = await _dio.get('/rozliczenia/faktury/', queryParameters: {'budowa': budowaId});
    return (r.data as List).map((e) => FakturaModel.fromJson(e)).toList();
  }

  Future<FakturaModel> fetchFaktura(int id) async {
    final r = await _dio.get('/rozliczenia/faktury/$id/');
    return FakturaModel.fromJson(r.data);
  }

  Future<FakturaModel> createFaktura(FakturaModel f) async {
    final r = await _dio.post('/rozliczenia/faktury/', data: f.toJson());
    return FakturaModel.fromJson(r.data);
  }

  Future<FakturaModel> updateStatus(int id, StatusFaktury status) async {
    final r = await _dio.patch('/rozliczenia/faktury/$id/', data: {'status': status.apiValue});
    return FakturaModel.fromJson(r.data);
  }

  Future<FakturaModel> oznaczOplacona(int id) async {
    final r = await _dio.post('/rozliczenia/faktury/$id/oplac/', data: {
      'data_oplaty': DateTime.now().toIso8601String(),
    });
    return FakturaModel.fromJson(r.data);
  }

  Future<BudowaRozliczeniaStats> fetchStats(int budowaId) async {
    final r = await _dio.get('/rozliczenia/stats/', queryParameters: {'budowa': budowaId});
    return BudowaRozliczeniaStats.fromJson(r.data);
  }
}

final rozliczeniaApiProvider = Provider<RozliczeniaApi>(
  (ref) => RozliczeniaApi(ref.read(budkonDioProvider)),
);
