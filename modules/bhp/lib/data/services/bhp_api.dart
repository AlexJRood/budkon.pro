import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/budkon_api_client.dart';
import '../models/bhp_model.dart';

class BhpApi {
  final Dio _dio;
  BhpApi(this._dio);

  Future<List<SzkolenieBhpModel>> fetchSzkolenia(int budowaId) async {
    final r = await _dio.get('/bhp/szkolenia/', queryParameters: {'budowa': budowaId});
    return (r.data as List).map((e) => SzkolenieBhpModel.fromJson(e)).toList();
  }

  Future<SzkolenieBhpModel> addSzkolenie(SzkolenieBhpModel s) async {
    final r = await _dio.post('/bhp/szkolenia/', data: s.toJson());
    return SzkolenieBhpModel.fromJson(r.data);
  }

  Future<List<WypadekModel>> fetchWypadki(int budowaId) async {
    final r = await _dio.get('/bhp/wypadki/', queryParameters: {'budowa': budowaId});
    return (r.data as List).map((e) => WypadekModel.fromJson(e)).toList();
  }

  Future<WypadekModel> addWypadek(WypadekModel w) async {
    final r = await _dio.post('/bhp/wypadki/', data: w.toJson());
    return WypadekModel.fromJson(r.data);
  }

  Future<WypadekModel> updateWypadekStatus(int id, StatusWypadku status) async {
    final r = await _dio.patch('/bhp/wypadki/$id/', data: {'status': status.apiValue});
    return WypadekModel.fromJson(r.data);
  }

  Future<List<InstrukcjaBhpModel>> fetchInstrukcje(int budowaId) async {
    final r = await _dio.get('/bhp/instrukcje/', queryParameters: {'budowa': budowaId});
    return (r.data as List).map((e) => InstrukcjaBhpModel.fromJson(e)).toList();
  }
}

final bhpApiProvider = Provider<BhpApi>(
  (ref) => BhpApi(ref.read(budkonDioProvider)),
);
