import 'package:core/platform/budkon_api_client.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/budowa_model.dart';

final budowaApiProvider = Provider((ref) => BudowaApi(ref.watch(budkonDioProvider)));

class BudowaApi {
  BudowaApi(this._dio);
  final Dio _dio;

  Options get _opts => Options(headers: {
        'X-Company-Id': '1', // TODO: read from userSessionProvider
      });

  Future<List<BudowaModel>> fetchList() async {
    final resp = await _dio.get('/budowy/', options: _opts);
    final results = resp.data['results'] as List? ?? [];
    return results.map((e) => BudowaModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<BudowaModel> fetchOne(int id) async {
    final resp = await _dio.get('/budowy/$id/', options: _opts);
    return BudowaModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<BudowaModel> create(BudowaModel budowa, {int? companyId, int? createdBy}) async {
    final payload = {
      ...budowa.toJson(),
      if (companyId != null) 'company_id': companyId,
      if (createdBy != null) 'created_by': createdBy,
    };
    final resp = await _dio.post('/budowy/', data: jsonEncode(payload), options: _opts);
    return BudowaModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<BudowaModel> update(int id, Map<String, dynamic> patch) async {
    final resp = await _dio.patch('/budowy/$id/', data: jsonEncode(patch), options: _opts);
    return BudowaModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<void> delete(int id) => _dio.delete('/budowy/$id/', options: _opts);

  Future<EtapBudowyModel> addEtap(int budowaId, EtapBudowyModel etap) async {
    final resp = await _dio.post(
      '/budowy/$budowaId/etapy/',
      data: jsonEncode(etap.toJson()),
      options: _opts,
    );
    return EtapBudowyModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<EtapBudowyModel> updateEtap(int etapId, Map<String, dynamic> patch) async {
    final resp = await _dio.patch('/etapy/$etapId/', data: jsonEncode(patch), options: _opts);
    return EtapBudowyModel.fromJson(resp.data as Map<String, dynamic>);
  }
}
