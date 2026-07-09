import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/url.dart';
import 'package:crm/crm_urls.dart';
import 'package:crm/shared/models/transaction/agent_transaction_model.dart';
import 'package:crm/shared/models/revenue/crm_revenue_upload_model.dart';
import 'package:core/platform/api_services.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

final crmRevenueProvider = StateNotifierProvider<CrmRevenueNotifier,
    AsyncValue<List<AgentTransactionModel>>>((ref) {
  return CrmRevenueNotifier();
});

class CrmRevenueNotifier
    extends StateNotifier<AsyncValue<List<AgentTransactionModel>>> {
  CrmRevenueNotifier() : super(const AsyncValue.loading()) {
    fetchRevenue();
  }

  Future<void> fetchRevenue(
      {List<int>? years, List<int>? months, String? ordering,dynamic ref}) async {
    try {
      final now = DateTime.now();
      // Use current year and month if no filter is provided
      final effectiveYears =
          (years == null || years.isEmpty) ? [now.year] : years;
      final effectiveMonths =
          (months == null || months.isEmpty) ? [now.month] : months;
      final queryParams = {
        'year': effectiveYears.join(','),
        'month': effectiveMonths.join(','),
        'sort': ordering ?? 'amount',
      };
      final response = await ApiServices.get(
        ref: ref,
        CrmUrls.agentTransactionsCrm,
        queryParameters: queryParams,
        hasToken: true,
      );

      if (response == null) {
        state = const AsyncValue.data([]);

        return;
      }
      final decodedDatabody = utf8.decode(response.data);
      final decodeData = json.decode(decodedDatabody) as List;
      final revenues = decodeData.map((revenue) => AgentTransactionModel.fromJson(revenue)).toList();
      
      state = AsyncValue.data(revenues);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addRevenue(CrmRevenueUploadModel revenue) async {
    try {
      final response = await ApiServices.post(
        CrmUrls.createCrm,
        data: revenue.toJson(),
        hasToken: true,
      );
      if (response != null && response.statusCode == 201) {
        fetchRevenue();
      } else {
        if (kDebugMode) print('Failed to create revenue: ');
      }
    } catch (error, stackTrace) {
      if (kDebugMode) print('Error adding revenue: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateRevenue(int id, AgentTransactionModel revenue) async {
    try {
      final response = await ApiServices.put(
        URLs.updateRevenuesCrm('$id'),
        data: revenue.toJson(),
        hasToken: true,
      );

      if (response == null) return;

      fetchRevenue();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteRevenue(int id) async {
    try {
      final response = await ApiServices.delete(
        CrmUrls.deleteRevenuesCrm('$id'),
        hasToken: true,
      );

      if (response == null) return;

      fetchRevenue();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
