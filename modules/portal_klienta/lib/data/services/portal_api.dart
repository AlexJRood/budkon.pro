import 'package:core/platform/budkon_api_client.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/portal_model.dart';

final portalApiProvider = Provider((ref) => PortalApi(ref.watch(budkonDioProvider)));

class PortalApi {
  PortalApi(this._dio);
  final Dio _dio;

  Options get _opts => Options(headers: {'X-Company-Id': '1'});

  Future<List<PortalKlientaModel>> fetchList({int? budowaId}) async {
    final resp = await _dio.get(
      '/portale/',
      queryParameters: budowaId != null ? {'budowa': budowaId} : null,
      options: _opts,
    );
    final results = resp.data['results'] as List? ?? resp.data as List? ?? [];
    return results.map((e) => PortalKlientaModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<PortalKlientaModel> create(PortalKlientaModel portal) async {
    final resp = await _dio.post('/portale/', data: jsonEncode(portal.toJson()), options: _opts);
    return PortalKlientaModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<PortalKlientaModel> update(int id, Map<String, dynamic> patch) async {
    final resp = await _dio.patch('/portale/$id/', data: jsonEncode(patch), options: _opts);
    return PortalKlientaModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<void> dezaktywuj(int id) async {
    await _dio.post('/portale/$id/dezaktywuj/', options: _opts);
  }

  Future<PortalKlientaModel> regenerujToken(int id) async {
    final resp = await _dio.post('/portale/$id/regeneruj-token/', options: _opts);
    return PortalKlientaModel.fromJson(resp.data as Map<String, dynamic>);
  }
}
