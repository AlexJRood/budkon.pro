import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:crm_agent/crm/models/transaction_summary_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/platform/url.dart';
import 'package:core/theme/apptheme.dart';

final transactionTypeSummaryProvider = StateNotifierProvider<
  TransactionTypeSummaryNotifier,
  AsyncValue<TransactionSummary>
>((ref) => TransactionTypeSummaryNotifier(ref));

class TransactionTypeSummaryNotifier
    extends StateNotifier<AsyncValue<TransactionSummary>> {
  final Ref ref;

  TransactionTypeSummaryNotifier(this.ref) : super(const AsyncLoading()) {
    fetchTransactionTypeSummary(); // fetch on init
  }

  String _rangeToParam(TimeRange r) {
    switch (r) {
      case TimeRange.thisMonth: return 'this_month';
      case TimeRange.lastMonth: return 'last_month';
      case TimeRange.thisYear:  return 'this_year';
    }
  }

  Future<void> fetchTransactionTypeSummary() async {
    try {
      state = const AsyncLoading();

      final range = ref.read(selectedRangeProvider);
      final rangeParam = _rangeToParam(range);

      // Prefer a queryParameters arg if your ApiServices supports it.
      // If not, fall back to appending to the URL.
      final url = Uri.parse(URLs.transactionSummary)
          .replace(queryParameters: {'range': rangeParam})
          .toString();

      final response = await ApiServices.get(
        url,                     // <-- use URL with ?range=...
        ref: ref,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200 && response.data != null) {
        final decodedBody = utf8.decode(response.data);
        final parsedData = json.decode(decodedBody);
        debugPrint('✅ API Response:\n$parsedData');
        final summary = TransactionSummary.fromJson(parsedData);
        state = AsyncData(summary);
      } else {
        throw Exception('${'invalid_response_or_status'.tr}: ${response?.statusCode}');
      }
    } catch (e, st) {
      debugPrint('❌ Error fetching transaction summary: $e');
      state = AsyncError(e, st);
    }
  }
}

final currentPageProvider = StateProvider<int>((ref) => 0);

final chartDataProvider = Provider<List<List<PieChartSectionData>>>((ref) {
  final summaryAsync = ref.watch(transactionTypeSummaryProvider);
  ref.watch(selectedRangeProvider); // <-- depend on dropdown state
  final theme = ref.watch(themeColorsProvider);

  return summaryAsync.when(
    data: (summary) {
      final revenueAmount = summary.revenues.fold<double>(0, (s, i) => s + i.totalAmount);
      final expenseAmount = summary.expenses.fold<double>(0, (s, i) => s + i.totalAmount);

      final total = revenueAmount + expenseAmount;
      if (total == 0) return [];

      final revenuePercent = (revenueAmount / total) * 100;
      final expensePercent = (expenseAmount / total) * 100;

      return [
        [
          PieChartSectionData(
            value: revenueAmount,
            color: theme.themeColor,
            title: '${revenuePercent.toStringAsFixed(1)}%',
            radius: 50,
            titleStyle: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          PieChartSectionData(
            value: expenseAmount, // <-- FIX: was revenuePercent before
            color: const Color.fromRGBO(166, 227, 184, 1),
            title: '${expensePercent.toStringAsFixed(1)}%',
            radius: 50,
            titleStyle: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ];
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// add near your providers
enum TimeRange { thisMonth, lastMonth, thisYear }

final selectedRangeProvider =
StateProvider<TimeRange>((ref) => TimeRange.thisMonth);
