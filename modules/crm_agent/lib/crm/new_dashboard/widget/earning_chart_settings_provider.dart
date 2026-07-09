import 'dart:async';
import 'package:crm_agent/crm_agent_urls.dart';
import 'dart:convert';

import 'package:crm/crm/finance/charts/chart_settings.dart';
import 'package:crm/crm/finance/charts/remote_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:core/platform/api_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kSettingsKey = 'earning_chart_widget_settings';
const _kShowBgKey = 'earning_chart_widget_show_bg';

// ── Background visibility (persisted) ────────────────────────────────────────

class EarningChartShowBgNotifier extends StateNotifier<bool> {
  EarningChartShowBgNotifier() : super(true);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) state = prefs.getBool(_kShowBgKey) ?? true;
  }

  void set(bool value) {
    state = value;
    SharedPreferences.getInstance()
        .then((prefs) => prefs.setBool(_kShowBgKey, value));
  }
}

final earningChartShowBackgroundProvider =
    StateNotifierProvider<EarningChartShowBgNotifier, bool>((ref) {
  final n = EarningChartShowBgNotifier();
  unawaited(n.load());
  return n;
});

// ── Chart settings (persisted) ────────────────────────────────────────────────

class _DashboardEarningChartNotifier extends FinanceChartSettingsNotifier {
  _DashboardEarningChartNotifier(super.ref) {
    addListener((s) => unawaited(_save(s)), fireImmediately: false);
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kSettingsKey);
    if (raw == null || raw.isEmpty) {
      applyDashboardPreset();
      return;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        if (mounted) state = FinanceChartSettings.fromJson(decoded);
        return;
      }
    } catch (_) {}
    applyDashboardPreset();
  }

  Future<void> _save(FinanceChartSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSettingsKey, jsonEncode(settings.toJson()));
  }
}

final dashboardEarningChartSettingsProvider =
    StateNotifierProvider<FinanceChartSettingsNotifier, FinanceChartSettings>(
  (ref) {
    final n = _DashboardEarningChartNotifier(ref);
    unawaited(n.load());
    return n;
  },
);

final dashboardEarningChartRemoteProvider =
    FutureProvider<FinanceChartRemoteResponse>((ref) async {
  final settings = ref.watch(dashboardEarningChartSettingsProvider);

  final now = DateTime.now();
  final DateTime dateFrom;
  switch (settings.range) {
    case FinanceChartRange.week:
      dateFrom = now.subtract(const Duration(days: 6));
    case FinanceChartRange.month:
      dateFrom = DateTime(now.year, now.month, 1);
    case FinanceChartRange.year:
      dateFrom = DateTime(now.year, 1, 1);
  }

  final groupBy = switch (settings.groupBy) {
    FinanceChartGroupBy.day => 'day',
    FinanceChartGroupBy.week => 'week',
    FinanceChartGroupBy.month => 'month',
  };

  final metric = switch (settings.metric) {
    FinanceChartMetric.sumAmount => 'sum_total_amount',
    FinanceChartMetric.countTransactions => 'count',
  };

  final series = <Map<String, dynamic>>[];
  if (settings.showRevenuePaid) {
    series.add({
      'name': 'paid_revenues_label'.tr,
      'kind': 'revenue',
      'is_paid': true,
    });
  }
  if (settings.showRevenueUnpaid) {
    series.add({
      'name': 'unpaid_revenues_label'.tr,
      'kind': 'revenue',
      'is_paid': false,
    });
  }
  if (settings.showExpensePaid) {
    series.add({
      'name': 'paid_expenses_label'.tr,
      'kind': 'expense',
      'is_paid': true,
    });
  }
  if (settings.showExpenseUnpaid) {
    series.add({
      'name': 'unpaid_expenses_label'.tr,
      'kind': 'expense',
      'is_paid': false,
    });
  }

  final resp = await ApiServices.post(
    CrmAgentUrls.financeChartData,
    hasToken: true,
    ref: ref,
    data: {
      'data_config': {
        'date_from': _fmt(dateFrom),
        'date_to': _fmt(now),
        'group_by': groupBy,
        'metric': metric,
        'series': series,
      },
    },
  );

  if (resp == null) throw Exception('No response from /finance/chart/');

  final data = resp.data;
  if (data is! Map<String, dynamic>) {
    throw Exception('Invalid response from /finance/chart/');
  }

  return FinanceChartRemoteResponse.fromJson(data);
});

String _fmt(DateTime dt) => dt.toIso8601String().substring(0, 10);
