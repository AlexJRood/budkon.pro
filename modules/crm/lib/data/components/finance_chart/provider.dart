import 'package:crm/shared/models/expense/crm_expenses_download_model.dart';
import 'package:crm/shared/models/revenue_model.dart';
import 'package:crm/crm_urls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';
import 'dart:convert';
import 'package:get/get_utils/get_utils.dart';

final revenueAndExpensesProvider = StateNotifierProvider<
    RevenueAndExpensesNotifier, AsyncValue<Map<String, List>>>((ref) {
  return RevenueAndExpensesNotifier(ref);
});

final prevMonthRevenueAndExpensesProvider = StateNotifierProvider<
    RevenueAndExpensesNotifier, AsyncValue<Map<String, List>>>((ref) {
  return RevenueAndExpensesNotifier(ref, monthOffset: -1);
});

class RevenueAndExpensesNotifier
    extends StateNotifier<AsyncValue<Map<String, List>>> {
  final Ref ref;
  final int monthOffset;

  RevenueAndExpensesNotifier(this.ref, {this.monthOffset = 0})
      : super(const AsyncValue.loading()) {
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      Map<String, dynamic>? queryParams;
      if (monthOffset != 0) {
        final now = DateTime.now();
        final target = DateTime(now.year, now.month + monthOffset);
        queryParams = {
          'year': target.year.toString(),
          'month': target.month.toString(),
        };
      }

      final response = await ApiServices.get(
        ref: ref,
        CrmUrls.financeAppExpenses,
        hasToken: true,
        queryParameters: queryParams,
      );

      if (response == null || response.data == null) {
        state = AsyncValue.error(
          Exception('Invalid response'.tr),
          StackTrace.current,
        );
        return;
      }

      final decodedBody = utf8.decode(response.data);
      final parsedData = json.decode(decodedBody) as Map<String, dynamic>;

      debugPrint('✅ API Response: $parsedData');

      final expensesList = parsedData['expenses'] as List? ?? [];
      final expenses = expensesList
          .map((expense) => CrmExpensesDownloadModel.fromJson(expense))
          .toList();

      final revenuesList = parsedData['revenues'] as List? ?? [];
      final revenues = revenuesList
          .map((revenue) => AgentRevenueModel.fromJson(revenue))
          .toList();

      state = AsyncValue.data({
        'expenses': expenses,
        'revenues': revenues,
      });
    } catch (error, stackTrace) {
      debugPrint('❌ Error in fetchData: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
