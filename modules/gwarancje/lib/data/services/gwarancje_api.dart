import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/budkon_api_client.dart';
import '../models/gwarancje_model.dart';

class GwarancjeApi {
  final Dio _dio;
  GwarancjeApi(this._dio);

  Future<List<GwarancjaModel>> fetchGwarancje(int budowaId) async {
    final r = await _dio.get('/gwarancje/', queryParameters: {'budowa': budowaId});
    return (r.data as List).map((e) => GwarancjaModel.fromJson(e)).toList();
  }

  Future<GwarancjaModel> createGwarancja(GwarancjaModel g) async {
    final r = await _dio.post('/gwarancje/', data: g.toJson());
    return GwarancjaModel.fromJson(r.data);
  }

  Future<List<ZgloszenieSerwisowModel>> fetchZgloszenia(int budowaId) async {
    final r = await _dio.get('/gwarancje/zgloszenia/', queryParameters: {'budowa': budowaId});
    return (r.data as List).map((e) => ZgloszenieSerwisowModel.fromJson(e)).toList();
  }

  Future<ZgloszenieSerwisowModel> addZgloszenie(ZgloszenieSerwisowModel z) async {
    final r = await _dio.post('/gwarancje/zgloszenia/', data: z.toJson());
    return ZgloszenieSerwisowModel.fromJson(r.data);
  }

  Future<ZgloszenieSerwisowModel> updateZgloszenieStatus(
      int id, StatusZgloszenia status, {String? odpowiedz}) async {
    final r = await _dio.patch('/gwarancje/zgloszenia/$id/', data: {
      'status': status.apiValue,
      if (odpowiedz != null) 'odpowiedz': odpowiedz,
      if (status == StatusZgloszenia.zrealizowane)
        'data_realizacji': DateTime.now().toIso8601String(),
    });
    return ZgloszenieSerwisowModel.fromJson(r.data);
  }
}

final gwarancjeApiProvider = Provider<GwarancjeApi>(
  (ref) => GwarancjeApi(ref.read(budkonDioProvider)),
);
