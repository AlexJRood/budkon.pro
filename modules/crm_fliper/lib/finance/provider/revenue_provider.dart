import 'dart:convert';
import 'package:crm_fliper/crm_fliper_urls.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crm_fliper/finance/models/revenue_model.dart';
import 'package:crm_fliper/finance/models/revenue_response_model.dart';
import 'package:core/platform/api_services.dart';
import 'package:flutter/foundation.dart';

class RevenueNotifier extends StateNotifier<List<Revenue>> {
  RevenueNotifier() : super([]);

  Future<void> fetchRevenue(dynamic ref) async {
    try {
      final response = await ApiServices.get(
        CrmFliperUrls.fetchRevenues,
        ref: ref,
        hasToken: true,
      );
      if (response != null && response.statusCode == 200) {
        final responseString = utf8.decode(response.data);
        final jsonResponse = jsonDecode(responseString);
        final revenueResponse = RevenueResponse.fromJson(jsonResponse);
        state = revenueResponse.results;
        if (kDebugMode) debugPrint('Revenues fetched successfully. Count: ${state.length}');
        for (var revenue in state) {
          if (kDebugMode) {
            debugPrint(
              'Revenue ID: ${revenue.id}, Title: ${revenue.title}, Amount: ${revenue.amount}');
          }
        }
      } else {
        if (kDebugMode) debugPrint('Revenue fetch failed. Status code: ${response?.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching revenues: $e');
    }
  }

  Future<void> createRevenue(dynamic ref) async {
    try {
      final data = {
        "title": "Property Sale Revenue",
        "transaction": 1,
        "amount": 250000.00,
        "date": "2025-02-09"
      };
      final response = await ApiServices.post(CrmFliperUrls.createRevenue,
          hasToken: true, data: data);
      if (response != null && response.statusCode == 201) {
        if (kDebugMode) debugPrint('Revenue created successfully');
        await fetchRevenue(ref);
      } else {
        if (kDebugMode) debugPrint('Revenue creation failed. Status code: ${response?.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error creating revenue: $e');
    }
  }
}

final revenueProvider = StateNotifierProvider<RevenueNotifier, List<Revenue>>(
  (ref) => RevenueNotifier(),
);
