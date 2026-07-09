// lib/crm/finance/charts/remote_data.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:core/platform/api_services.dart';

/// Typ grupowania
enum FinanceRemoteGroupBy { day, week, month }

/// Metryka
enum FinanceRemoteMetric { sumTotalAmount, count }

/// Konfiguracja jednej serii (to co user sobie wybierze)
@immutable
class FinanceChartSeriesConfig {
  final String name;                // np. "Przychody opłacone"
  final String kind;                // "revenue" | "expense"
  final bool? isPaid;              // true / false / null
  final String? transactionType;    // np. "subscription"
  final String? paymentMethods;     // np. "card"
  final List<String> tags;          // JSONField contains

  /// Pro Ultra Emma:
  /// - visible: czy seria ma być rysowana
  /// - colorHex: wymuszony kolor, np. "#00FF00"
  /// - factor: mnożnik (np. 1000, 0.001)
  /// - invert: jeśli true -> odwróć znak (× -1)
  final bool visible;
  final String? colorHex;
  final double? factor;
  final bool invert;

  const FinanceChartSeriesConfig({
    required this.name,
    required this.kind,
    this.isPaid,
    this.transactionType,
    this.paymentMethods,
    this.tags = const [],
    this.visible = true,
    this.colorHex,
    this.factor,
    this.invert = false,
  });

  FinanceChartSeriesConfig copyWith({
    String? name,
    String? kind,
    bool? isPaid,
    bool clearIsPayed = false,
    String? transactionType,
    bool clearTransactionType = false,
    String? paymentMethods,
    bool clearPaymentMethods = false,
    List<String>? tags,
    bool? visible,
    String? colorHex,
    double? factor,
    bool clearFactor = false,
    bool? invert,
  }) {
    return FinanceChartSeriesConfig(
      name: name ?? this.name,
      kind: kind ?? this.kind,
      isPaid: clearIsPayed ? null : (isPaid ?? this.isPaid),
      transactionType: clearTransactionType
          ? null
          : (transactionType ?? this.transactionType),
      paymentMethods: clearPaymentMethods
          ? null
          : (paymentMethods ?? this.paymentMethods),
      tags: tags ?? this.tags,
      visible: visible ?? this.visible,
      colorHex: colorHex ?? this.colorHex,
      factor: clearFactor ? null : (factor ?? this.factor),
      invert: invert ?? this.invert,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'kind': kind,
        'is_paid': isPaid,
        'transaction_type': transactionType,
        'payment_methods': paymentMethods,
        'tags': tags,
        'visible': visible,
        'color_hex': colorHex,
        'factor': factor,
        'invert': invert,
      };

  factory FinanceChartSeriesConfig.fromJson(Map<String, dynamic> json) {
    return FinanceChartSeriesConfig(
      name: json['name'] as String? ?? 'Series',
      kind: json['kind'] as String? ?? 'revenue',
      isPaid: json['is_paid'] as bool?,
      transactionType: json['transaction_type'] as String?,
      paymentMethods: json['payment_methods'] as String?,
      tags: (json['tags'] as List?)?.cast<String>() ?? const [],
      visible: json['visible'] as bool? ?? true,
      colorHex: json['color_hex'] as String?,
      factor: (json['factor'] is num)
          ? (json['factor'] as num).toDouble()
          : null,
      invert: json['invert'] as bool? ?? false,
    );
  }
}

/// Główny config wysyłany do `/api/finance/chart/` jako "data_config"
@immutable
class FinanceChartDataConfig {
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final FinanceRemoteGroupBy groupBy;
  final FinanceRemoteMetric metric;
  final int? companyId; // filters.company_id
  final List<FinanceChartSeriesConfig> series;

  const FinanceChartDataConfig({
    this.dateFrom,
    this.dateTo,
    this.groupBy = FinanceRemoteGroupBy.day,
    this.metric = FinanceRemoteMetric.sumTotalAmount,
    this.companyId,
    this.series = const [],
  });

  FinanceChartDataConfig copyWith({
    DateTime? dateFrom,
    bool clearDateFrom = false,
    DateTime? dateTo,
    bool clearDateTo = false,
    FinanceRemoteGroupBy? groupBy,
    FinanceRemoteMetric? metric,
    int? companyId,
    bool clearCompanyId = false,
    List<FinanceChartSeriesConfig>? series,
  }) {
    return FinanceChartDataConfig(
      dateFrom: clearDateFrom ? null : (dateFrom ?? this.dateFrom),
      dateTo: clearDateTo ? null : (dateTo ?? this.dateTo),
      groupBy: groupBy ?? this.groupBy,
      metric: metric ?? this.metric,
      companyId:
          clearCompanyId ? null : (companyId ?? this.companyId),
      series: series ?? this.series,
    );
  }

  Map<String, dynamic> toJson() {
    String? _fmt(DateTime? dt) =>
        dt != null ? dt.toIso8601String().substring(0, 10) : null;

    return {
      'date_from': _fmt(dateFrom),
      'date_to': _fmt(dateTo),
      'group_by': switch (groupBy) {
        FinanceRemoteGroupBy.day => 'day',
        FinanceRemoteGroupBy.week => 'week',
        FinanceRemoteGroupBy.month => 'month',
      },
      'metric': switch (metric) {
        FinanceRemoteMetric.sumTotalAmount => 'sum_total_amount',
        FinanceRemoteMetric.count => 'count',
      },
      'filters': {
        if (companyId != null) 'company_id': companyId,
      },
      'series': series.map((s) => s.toJson()).toList(),
    };
  }

  factory FinanceChartDataConfig.fromJson(Map<String, dynamic> json) {
    DateTime? _parse(String? v) =>
        (v == null || v.isEmpty) ? null : DateTime.parse(v);

    final filters = (json['filters'] as Map?) ?? {};

    FinanceRemoteGroupBy parseGroupBy(String? v) {
      switch (v) {
        case 'day':
          return FinanceRemoteGroupBy.day;
        case 'week':
          return FinanceRemoteGroupBy.week;
        case 'month':
          return FinanceRemoteGroupBy.month;
        default:
          return FinanceRemoteGroupBy.day;
      }
    }

    FinanceRemoteMetric parseMetric(String? v) {
      switch (v) {
        case 'sum_total_amount':
          return FinanceRemoteMetric.sumTotalAmount;
        case 'count':
          return FinanceRemoteMetric.count;
        default:
          return FinanceRemoteMetric.sumTotalAmount;
      }
    }

    return FinanceChartDataConfig(
      dateFrom: _parse(json['date_from'] as String?),
      dateTo: _parse(json['date_to'] as String?),
      groupBy: parseGroupBy(json['group_by'] as String?),
      metric: parseMetric(json['metric'] as String?),
      companyId: filters['company_id'] as int?,
      series: (json['series'] as List? ?? [])
          .map((e) => FinanceChartSeriesConfig.fromJson(
              (e as Map).cast<String, dynamic>()))
          .toList(),
    );
  }

  /// Prosty preset: ostatnie 7 dni, dwie serie (przychody / wydatki opłacone)
  factory FinanceChartDataConfig.defaultLast7Days() {
    final now = DateTime.now();
    final from = now.subtract(const Duration(days: 6));
    return FinanceChartDataConfig(
      dateFrom: from,
      dateTo: now,
      groupBy: FinanceRemoteGroupBy.day,
      metric: FinanceRemoteMetric.sumTotalAmount,
      series: [
        FinanceChartSeriesConfig(
          name: 'paid_revenues_label'.tr,
          kind: 'revenue',
          isPaid: true,
        ),
        FinanceChartSeriesConfig(
          name: 'paid_expenses_label'.tr,
          kind: 'expense',
          isPaid: true,
        ),
      ],
    );
  }
}

/// Jedna seria w odpowiedzi z API
@immutable
class FinanceChartSeriesResult {
  final String name;
  final List<double> values;

  const FinanceChartSeriesResult({
    required this.name,
    required this.values,
  });

  factory FinanceChartSeriesResult.fromJson(Map<String, dynamic> json) {
    final raw = (json['values'] as List? ?? []);
    final vals = raw
        .map((e) => (e is num) ? e.toDouble() : 0.0)
        .toList(growable: false);

    return FinanceChartSeriesResult(
      name: json['name'] as String? ?? 'Series',
      values: vals,
    );
  }
}

/// Cała odpowiedź z /api/finance/chart/
@immutable
class FinanceChartRemoteResponse {
  final List<String> labels; // np. ["2025-01-01", ...]
  final List<FinanceChartSeriesResult> series;

  const FinanceChartRemoteResponse({
    required this.labels,
    required this.series,
  });

  factory FinanceChartRemoteResponse.fromJson(Map<String, dynamic> json) {
    final xAxis = (json['x_axis'] as Map?) ?? {};
    final labels = (xAxis['labels'] as List? ?? [])
        .map((e) => e.toString())
        .toList(growable: false);

    final seriesList = (json['series'] as List? ?? [])
        .map((e) => FinanceChartSeriesResult.fromJson(
            (e as Map).cast<String, dynamic>()))
        .toList(growable: false);

    return FinanceChartRemoteResponse(
      labels: labels,
      series: seriesList,
    );
  }
}

/// Notifier trzymający aktualny data_config
class FinanceChartDataConfigNotifier
    extends StateNotifier<FinanceChartDataConfig> {
  FinanceChartDataConfigNotifier()
      : super(FinanceChartDataConfig.defaultLast7Days());

  void setDateRange(DateTime? from, DateTime? to) {
    state = state.copyWith(dateFrom: from, dateTo: to);
  }

  void setGroupBy(FinanceRemoteGroupBy groupBy) {
    state = state.copyWith(groupBy: groupBy);
  }

  void setMetric(FinanceRemoteMetric metric) {
    state = state.copyWith(metric: metric);
  }

  void setCompanyId(int? companyId) {
    state = state.copyWith(
      companyId: companyId,
      clearCompanyId: companyId == null,
    );
  }

  void setSeries(List<FinanceChartSeriesConfig> series) {
    state = state.copyWith(series: series);
  }

  void addSeries(FinanceChartSeriesConfig series) {
    final copy = [...state.series, series];
    state = state.copyWith(series: copy);
  }

  void updateSeries(int index, FinanceChartSeriesConfig series) {
    if (index < 0 || index >= state.series.length) return;
    final copy = [...state.series];
    copy[index] = series;
    state = state.copyWith(series: copy);
  }

    void toggleSeriesVisibility(int index) {
    if (index < 0 || index >= state.series.length) return;
    final current = state.series[index];
    final updated = current.copyWith(visible: !current.visible);
    updateSeries(index, updated);
  }


  void removeSeries(int index) {
    if (index < 0 || index >= state.series.length) return;
    final copy = [...state.series]..removeAt(index);
    state = state.copyWith(series: copy);
  }
}

/// Provider na config
final financeChartDataConfigProvider = StateNotifierProvider<
    FinanceChartDataConfigNotifier, FinanceChartDataConfig>(
  (ref) => FinanceChartDataConfigNotifier(),
);

/// Provider, który strzela w backend i zwraca dane pod wykres
final financeChartRemoteProvider =
    FutureProvider<FinanceChartRemoteResponse>((ref) async {
  final cfg = ref.watch(financeChartDataConfigProvider);

  final Response? resp = await ApiServices.post(
    'https://www.superbee.cloud/finance/chart/',
    hasToken: true,
    ref: ref,
    data: {
      'data_config': cfg.toJson(),
    },
  );

  if (resp == null) {
    throw Exception('No response from /finance/chart/');
  }

  final data = resp.data;
  if (data is! Map<String, dynamic>) {
    throw Exception('Invalid response format for /finance/chart/');
  }

  return FinanceChartRemoteResponse.fromJson(data);
});
