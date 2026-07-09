import 'dart:convert';
import 'package:crm_fliper/crm_fliper_urls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crm_fliper/sale/models/sale_model.dart';
import 'package:crm_fliper/sale/models/sale_response_model.dart';
import 'package:core/platform/api_services.dart';
import 'package:flutter/foundation.dart';

class SalesNotifier extends StateNotifier<List<Sale>> {
  SalesNotifier() : super([]);

  Future<void> fetchSales(dynamic ref) async {
    try {
      final response = await ApiServices.get(
        CrmFliperUrls.fetchFlipperSales,
        ref: ref,
        hasToken: true,
      );
      if (response != null && response.statusCode == 200) {
        final responseString = utf8.decode(response.data);
        final jsonResponse = jsonDecode(responseString);
        final salesResponse = SalesResponse.fromJson(jsonResponse);
        state = salesResponse.results;
        if (kDebugMode) debugPrint('Sales fetched successfully. Count: ${state.length}');
        for (var sale in state) {
          if (kDebugMode) {
            debugPrint(
              'Sale ID: ${sale.id}, Sale Price: ${sale.salePrice}, Status: ${sale.status}');
          }
        }
      } else {
        if (kDebugMode) debugPrint('Sales fetch failed. Status code: ${response?.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching sales: $e');
    }
  }

  Future<void> createSales({
    required int transaction,
    required int agent,
    required int client,
    required double salePrice,
    required double profitPotential,
    required String status,
    required String saleDate, // Format: YYYY-MM-DD
    required String createdAt, // Format: ISO 8601
    dynamic ref,
    BuildContext? context,
  }) async {
    try {
      final data = {
        "transaction": transaction,
        "agent": agent,
        "client": client,
        "sale_price": salePrice,
        "profit_potential": profitPotential,
        "status": status,
        "sale_date": saleDate,
        "created_at": createdAt,
      };

      final response = await ApiServices.post(
        CrmFliperUrls.createFlipperSale,
        hasToken: true,
        data: data,
      );

      if (response != null && response.statusCode == 201) {
        if (kDebugMode) debugPrint('Sale created successfully');
        await fetchSales(ref);
      } else {
        if (kDebugMode) debugPrint('Sale creation failed. Status code: ${response?.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error creating sale: $e');
    }
  }
}

final salesProvider = StateNotifierProvider<SalesNotifier, List<Sale>>(
  (ref) => SalesNotifier(),
);
