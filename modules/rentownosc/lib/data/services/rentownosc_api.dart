import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/budkon_api_client.dart';
import '../models/rentownosc_model.dart';

class RentownoscApi {
  final Dio _dio;
  RentownoscApi(this._dio);

  Future<RentownoscBudowyModel> fetchAnaliza(int budowaId) async {
    final r = await _dio.get('/rentownosc/analiza/', queryParameters: {'budowa': budowaId});
    return RentownoscBudowyModel.fromJson(r.data);
  }

  Future<List<KosztModel>> fetchKoszty(int budowaId) async {
    final r = await _dio.get('/rentownosc/koszty/', queryParameters: {'budowa': budowaId});
    return (r.data as List).map((e) => KosztModel.fromJson(e)).toList();
  }

  Future<KosztModel> addKoszt(KosztModel k) async {
    final r = await _dio.post('/rentownosc/koszty/', data: k.toJson());
    return KosztModel.fromJson(r.data);
  }

  Future<void> deleteKoszt(int id) => _dio.delete('/rentownosc/koszty/$id/');
}

final rentownoscApiProvider = Provider<RentownoscApi>(
  (ref) => RentownoscApi(ref.read(budkonDioProvider)),
);
