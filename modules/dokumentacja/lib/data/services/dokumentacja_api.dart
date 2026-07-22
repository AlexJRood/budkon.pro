import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/budkon_api_client.dart';
import '../models/dokumentacja_model.dart';

class DokumentacjaApi {
  final Dio _dio;
  DokumentacjaApi(this._dio);

  Future<List<DokumentModel>> fetchDokumenty(int budowaId) async {
    final r = await _dio.get('/dokumentacja/', queryParameters: {'budowa': budowaId});
    return (r.data as List).map((e) => DokumentModel.fromJson(e)).toList();
  }

  Future<DokumentModel> createDokument(DokumentModel d) async {
    final r = await _dio.post('/dokumentacja/', data: d.toJson());
    return DokumentModel.fromJson(r.data);
  }

  Future<DokumentModel> updateDokument(DokumentModel d) async {
    final r = await _dio.patch('/dokumentacja/${d.id}/', data: d.toJson());
    return DokumentModel.fromJson(r.data);
  }

  Future<void> deleteDokument(int id) => _dio.delete('/dokumentacja/$id/');
}

final dokumentacjaApiProvider = Provider<DokumentacjaApi>(
  (ref) => DokumentacjaApi(ref.read(budkonDioProvider)),
);
