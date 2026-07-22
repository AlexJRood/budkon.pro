import 'dart:convert';
import 'package:core/platform/budkon_api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/odbiory_model.dart';

final odbioryApiProvider = Provider((ref) => OdbioryApi(ref.watch(budkonDioProvider)));

class OdbioryApi {
  OdbioryApi(this._dio);
  final Dio _dio;

  Options get _opts => Options(headers: {'X-Company-Id': '1'});

  // ---- Protokoły ----

  Future<List<ProtokołOdbioruModel>> fetchProtokoly({int? budowaId}) async {
    final resp = await _dio.get(
      '/odbiory/',
      queryParameters: {if (budowaId != null) 'budowa': budowaId},
      options: _opts,
    );
    final results = resp.data['results'] as List? ?? resp.data as List? ?? [];
    return results
        .map((e) => ProtokołOdbioruModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ProtokołOdbioruModel> fetchProtokolOne(int id) async {
    final resp = await _dio.get('/odbiory/$id/', options: _opts);
    return ProtokołOdbioruModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<ProtokołOdbioruModel> createProtokol(ProtokołOdbioruModel p) async {
    final resp = await _dio.post('/odbiory/', data: jsonEncode(p.toJson()), options: _opts);
    return ProtokołOdbioruModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<ProtokołOdbioruModel> updateProtokol(int id, Map<String, dynamic> patch) async {
    final resp = await _dio.patch('/odbiory/$id/', data: jsonEncode(patch), options: _opts);
    return ProtokołOdbioruModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<void> deleteProtokol(int id) => _dio.delete('/odbiory/$id/', options: _opts);

  Future<ProtokołOdbioruModel> podpisz(int id, {required bool kierownik}) async {
    final field = kierownik ? 'podpisany_kierownik' : 'podpisany_inwestor';
    final resp = await _dio.post(
      '/odbiory/$id/podpisz/',
      data: jsonEncode({field: true}),
      options: _opts,
    );
    return ProtokołOdbioruModel.fromJson(resp.data as Map<String, dynamic>);
  }

  // ---- Punkty kontrolne ----

  Future<PunktKontrolnyModel> updatePunkt(int id, Map<String, dynamic> patch) async {
    final resp = await _dio.patch('/punkty-kontrolne/$id/', data: jsonEncode(patch), options: _opts);
    return PunktKontrolnyModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<List<PunktKontrolnyModel>> addPunktyZSzablonu(
      int protokolId, String szablon) async {
    final resp = await _dio.post(
      '/odbiory/$protokolId/dodaj-szablon/',
      data: jsonEncode({'szablon': szablon}),
      options: _opts,
    );
    final list = resp.data as List? ?? [];
    return list.map((e) => PunktKontrolnyModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ---- Usterki ----

  Future<List<UsterkaModel>> fetchUsterki({int? budowaId, int? protokolId}) async {
    final resp = await _dio.get(
      '/usterki/',
      queryParameters: {
        if (budowaId != null) 'budowa': budowaId,
        if (protokolId != null) 'protokol': protokolId,
      },
      options: _opts,
    );
    final results = resp.data['results'] as List? ?? resp.data as List? ?? [];
    return results.map((e) => UsterkaModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<UsterkaModel> createUsterka(UsterkaModel u) async {
    final resp = await _dio.post('/usterki/', data: jsonEncode(u.toJson()), options: _opts);
    return UsterkaModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<UsterkaModel> updateUsterkaStatus(int id, StatusUsterki status) async {
    final resp = await _dio.patch(
      '/usterki/$id/',
      data: jsonEncode({'status': status.apiValue}),
      options: _opts,
    );
    return UsterkaModel.fromJson(resp.data as Map<String, dynamic>);
  }
}
