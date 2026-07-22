import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/budkon_api_client.dart';
import '../models/analytics_model.dart';

class AnalyticsApi {
  final Dio _dio;
  AnalyticsApi(this._dio);

  Future<FirmoweKpiModel> fetchKpi() async {
    final r = await _dio.get('/analytics/kpi/');
    return FirmoweKpiModel.fromJson(r.data);
  }

  Future<List<BudowaKartaModel>> fetchBudowy() async {
    final r = await _dio.get('/analytics/budowy/');
    return (r.data as List).map((e) => BudowaKartaModel.fromJson(e)).toList();
  }

  Future<List<RaportMiesiecznyModel>> fetchRaportyMiesieczne({
    int? rok,
  }) async {
    final r = await _dio.get('/analytics/raporty/', queryParameters: {
      if (rok != null) 'rok': rok,
    });
    return (r.data as List)
        .map((e) => RaportMiesiecznyModel.fromJson(e))
        .toList();
  }

  Future<List<TrendPunktModel>> fetchTrendPrzychodu({int ostatnieMiesiace = 12}) async {
    final r = await _dio.get('/analytics/trend/przychod/',
        queryParameters: {'ostatnie': ostatnieMiesiace});
    return (r.data as List).map((e) => TrendPunktModel.fromJson(e)).toList();
  }

  Future<List<TrendPunktModel>> fetchTrendMarzy({int ostatnieMiesiace = 12}) async {
    final r = await _dio.get('/analytics/trend/marza/',
        queryParameters: {'ostatnie': ostatnieMiesiace});
    return (r.data as List).map((e) => TrendPunktModel.fromJson(e)).toList();
  }
}

final analyticsApiProvider = Provider<AnalyticsApi>(
  (ref) => AnalyticsApi(ref.read(budkonDioProvider)),
);
