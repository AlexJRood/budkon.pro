import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/analytics_model.dart';
import '../services/analytics_api.dart';

final kpiProvider = FutureProvider.autoDispose<FirmoweKpiModel>((ref) {
  return ref.read(analyticsApiProvider).fetchKpi();
});

final budowyAnalyticsProvider =
    FutureProvider.autoDispose<List<BudowaKartaModel>>((ref) {
  return ref.read(analyticsApiProvider).fetchBudowy();
});

final rankingRentownosciProvider =
    FutureProvider.autoDispose<List<BudowaKartaModel>>((ref) async {
  final budowy = await ref.read(analyticsApiProvider).fetchBudowy();
  final sorted = [...budowy]..sort((a, b) => b.marza.compareTo(a.marza));
  return sorted;
});

final raportMiesiecznyProvider =
    FutureProvider.autoDispose.family<List<RaportMiesiecznyModel>, int?>(
        (ref, rok) {
  return ref.read(analyticsApiProvider).fetchRaportyMiesieczne(rok: rok);
});

final trendPrzychoduProvider =
    FutureProvider.autoDispose<List<TrendPunktModel>>((ref) {
  return ref.read(analyticsApiProvider).fetchTrendPrzychodu();
});

final trendMarzyProvider =
    FutureProvider.autoDispose<List<TrendPunktModel>>((ref) {
  return ref.read(analyticsApiProvider).fetchTrendMarzy();
});
