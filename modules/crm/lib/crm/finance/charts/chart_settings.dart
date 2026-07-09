// finance/charts/chart_settings.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';

enum FinanceChartRange { week, month, year }
enum FinanceChartGroupBy { day, week, month }
enum FinanceChartType { line, bar, pie }
enum FinanceChartMetric { sumAmount, countTransactions }

Color _colorFromHex(String? hex, Color fallback) {
  if (hex == null || hex.isEmpty) return fallback;
  final buffer = StringBuffer();
  if (hex.length == 6 || hex.length == 7) buffer.write('ff');
  buffer.write(hex.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}

String _colorToHex(Color color) {
  // Format: #RRGGBB
  return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
}

@immutable
class FinanceChartSettings {
  final FinanceChartRange range;
  final FinanceChartGroupBy groupBy;
  final FinanceChartType chartType;
  final FinanceChartMetric metric;

  final bool showRevenuePaid;
  final bool showRevenueUnpaid;
  final bool showExpensePaid;
  final bool showExpenseUnpaid;

  final bool smoothLines;
  final bool showDots;

  final String? transactionTypeFilter;

  /// Colors for each series
  final Color revenuePaidColor;
  final Color revenueUnpaidColor;
  final Color expensePaidColor;
  final Color expenseUnpaidColor;

  const FinanceChartSettings({
    this.range = FinanceChartRange.week,
    this.groupBy = FinanceChartGroupBy.day,
    this.chartType = FinanceChartType.line,
    this.metric = FinanceChartMetric.sumAmount,
    this.showRevenuePaid = true,
    this.showRevenueUnpaid = true,
    this.showExpensePaid = true,
    this.showExpenseUnpaid = true,
    this.smoothLines = true,
    this.showDots = false,
    this.transactionTypeFilter,
    this.revenuePaidColor = Colors.green,
    this.revenueUnpaidColor = Colors.greenAccent,
    this.expensePaidColor = Colors.red,
    this.expenseUnpaidColor = Colors.orange,
  });

  FinanceChartSettings copyWith({
    FinanceChartRange? range,
    FinanceChartGroupBy? groupBy,
    FinanceChartType? chartType,
    FinanceChartMetric? metric,
    bool? showRevenuePaid,
    bool? showRevenueUnpaid,
    bool? showExpensePaid,
    bool? showExpenseUnpaid,
    bool? smoothLines,
    bool? showDots,
    String? transactionTypeFilter,
    bool clearTransactionTypeFilter = false,
    Color? revenuePaidColor,
    Color? revenueUnpaidColor,
    Color? expensePaidColor,
    Color? expenseUnpaidColor,
  }) {
    return FinanceChartSettings(
      range: range ?? this.range,
      groupBy: groupBy ?? this.groupBy,
      chartType: chartType ?? this.chartType,
      metric: metric ?? this.metric,
      showRevenuePaid: showRevenuePaid ?? this.showRevenuePaid,
      showRevenueUnpaid: showRevenueUnpaid ?? this.showRevenueUnpaid,
      showExpensePaid: showExpensePaid ?? this.showExpensePaid,
      showExpenseUnpaid: showExpenseUnpaid ?? this.showExpenseUnpaid,
      smoothLines: smoothLines ?? this.smoothLines,
      showDots: showDots ?? this.showDots,
      transactionTypeFilter: clearTransactionTypeFilter
          ? null
          : (transactionTypeFilter ?? this.transactionTypeFilter),
      revenuePaidColor: revenuePaidColor ?? this.revenuePaidColor,
      revenueUnpaidColor: revenueUnpaidColor ?? this.revenueUnpaidColor,
      expensePaidColor: expensePaidColor ?? this.expensePaidColor,
      expenseUnpaidColor: expenseUnpaidColor ?? this.expenseUnpaidColor,
    );
  }

  Map<String, dynamic> toJson() => {
        'range': range.name,
        'groupBy': groupBy.name,
        'chartType': chartType.name,
        'metric': metric.name,
        'showRevenuePaid': showRevenuePaid,
        'showRevenueUnpaid': showRevenueUnpaid,
        'showExpensePaid': showExpensePaid,
        'showExpenseUnpaid': showExpenseUnpaid,
        'smoothLines': smoothLines,
        'showDots': showDots,
        'transactionTypeFilter': transactionTypeFilter,
        'revenuePaidColor': _colorToHex(revenuePaidColor),
        'revenueUnpaidColor': _colorToHex(revenueUnpaidColor),
        'expensePaidColor': _colorToHex(expensePaidColor),
        'expenseUnpaidColor': _colorToHex(expenseUnpaidColor),
      };

  factory FinanceChartSettings.fromJson(Map<String, dynamic> json) {
    FinanceChartRange parseRange(String? v) =>
        FinanceChartRange.values.firstWhere(
          (e) => e.name == v,
          orElse: () => FinanceChartRange.week,
        );
    FinanceChartGroupBy parseGroupBy(String? v) =>
        FinanceChartGroupBy.values.firstWhere(
          (e) => e.name == v,
          orElse: () => FinanceChartGroupBy.day,
        );
    FinanceChartType parseType(String? v) =>
        FinanceChartType.values.firstWhere(
          (e) => e.name == v,
          orElse: () => FinanceChartType.line,
        );
    FinanceChartMetric parseMetric(String? v) =>
        FinanceChartMetric.values.firstWhere(
          (e) => e.name == v,
          orElse: () => FinanceChartMetric.sumAmount,
        );

    return FinanceChartSettings(
      range: parseRange(json['range'] as String?),
      groupBy: parseGroupBy(json['groupBy'] as String?),
      chartType: parseType(json['chartType'] as String?),
      metric: parseMetric(json['metric'] as String?),
      showRevenuePaid: json['showRevenuePaid'] as bool? ?? true,
      showRevenueUnpaid: json['showRevenueUnpaid'] as bool? ?? true,
      showExpensePaid: json['showExpensePaid'] as bool? ?? true,
      showExpenseUnpaid: json['showExpenseUnpaid'] as bool? ?? true,
      smoothLines: json['smoothLines'] as bool? ?? true,
      showDots: json['showDots'] as bool? ?? false,
      transactionTypeFilter: json['transactionTypeFilter'] as String?,
      revenuePaidColor: _colorFromHex(
          json['revenuePaidColor'] as String?, Colors.green),
      revenueUnpaidColor: _colorFromHex(
          json['revenueUnpaidColor'] as String?, Colors.greenAccent),
      expensePaidColor:
          _colorFromHex(json['expensePaidColor'] as String?, Colors.red),
      expenseUnpaidColor:
          _colorFromHex(json['expenseUnpaidColor'] as String?, Colors.orange),
    );
  }
}


// ... tu Twoje enumy + klasa FinanceChartSettings (nie wklejam ponownie)

// ---------------------- NOTIFIER ----------------------

class FinanceChartSettingsNotifier
    extends StateNotifier<FinanceChartSettings> {
  FinanceChartSettingsNotifier(this.ref)
      : super(const FinanceChartSettings());

  /// Riverpod Ref – dzięki temu mamy dostęp do providera i możemy go
  /// przekazać do ApiServices (który tego wymaga).
  final Ref ref;

  /// Dashboard default preset
  void applyDashboardPreset() {
    state = const FinanceChartSettings(
      range: FinanceChartRange.week,
      groupBy: FinanceChartGroupBy.day,
      chartType: FinanceChartType.line,
      metric: FinanceChartMetric.sumAmount,
      showRevenuePaid: true,
      showRevenueUnpaid: true,
      showExpensePaid: true,
      showExpenseUnpaid: true,
      smoothLines: true,
      showDots: false,
    );
  }

  void updateRange(FinanceChartRange range) {
    state = state.copyWith(range: range);
  }

  void updateChartType(FinanceChartType type) {
    state = state.copyWith(chartType: type);
  }

  void updateMetric(FinanceChartMetric metric) {
    state = state.copyWith(metric: metric);
  }

  void updateGroupBy(FinanceChartGroupBy groupBy) {
    state = state.copyWith(groupBy: groupBy);
  }

  void toggleRevenuePaid() {
    state = state.copyWith(showRevenuePaid: !state.showRevenuePaid);
  }

  void toggleRevenueUnpaid() {
    state =
        state.copyWith(showRevenueUnpaid: !state.showRevenueUnpaid);
  }

  void toggleExpensePaid() {
    state = state.copyWith(showExpensePaid: !state.showExpensePaid);
  }

  void toggleExpenseUnpaid() {
    state =
        state.copyWith(showExpenseUnpaid: !state.showExpenseUnpaid);
  }

  void toggleSmoothLines() {
    state = state.copyWith(smoothLines: !state.smoothLines);
  }

  void toggleShowDots() {
    state = state.copyWith(showDots: !state.showDots);
  }

  void setTransactionTypeFilter(String? value) {
    if (value == null || value.isEmpty) {
      state = state.copyWith(clearTransactionTypeFilter: true);
    } else {
      state = state.copyWith(transactionTypeFilter: value);
    }
  }

  // Jeśli dodałeś kolory:
  void updateRevenuePaidColor(Color color) {
    state = state.copyWith(revenuePaidColor: color);
  }

  void updateRevenueUnpaidColor(Color color) {
    state = state.copyWith(revenueUnpaidColor: color);
  }

  void updateExpensePaidColor(Color color) {
    state = state.copyWith(expensePaidColor: color);
  }

  void updateExpenseUnpaidColor(Color color) {
    state = state.copyWith(expenseUnpaidColor: color);
  }

  /// Zapis ustawień wykresu do backendu
  Future<void> saveSettingsToBackend() async {
    try {
      await ApiServices.patch(
        '/api/finance/chart/settings/',
        hasToken: true,
        ref: ref,
        data: {
          'settings': state.toJson(),
        },
      );
    } catch (e) {
      // tu możesz dodać log / snackbar
    }
  }

  /// Odczyt ustawień wykresu z backendu
  Future<void> loadSettingsFromBackend() async {
    try {
      final resp = await ApiServices.get(
        'https://www.superbee.cloud/finance/chart/settings/',
        hasToken: true,
        ref: ref,
        responseType:
            ResponseType.json, // ważne, bo domyślnie masz bytes
      );

      if (resp == null) return;

      final data = resp.data as Map<String, dynamic>;
      final settingsJson =
          data['settings'] as Map<String, dynamic>? ?? {};

      state = FinanceChartSettings.fromJson(settingsJson);
    } catch (e) {
      // If error – zostawiamy domyślne ustawienia
    }
  }
}

/// Provider – tu wstrzykujemy Ref do notifiers
final financeChartSettingsProvider =
    StateNotifierProvider<FinanceChartSettingsNotifier, FinanceChartSettings>(
  (ref) => FinanceChartSettingsNotifier(ref),
);
