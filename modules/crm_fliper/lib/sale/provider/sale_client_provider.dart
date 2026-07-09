import 'dart:convert';
import 'package:crm_fliper/crm_fliper_urls.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crm_fliper/sale/models/sale_client_model.dart';
import 'package:crm_fliper/sale/models/sale_client_response_model.dart';
import 'package:core/platform/api_services.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:flutter/foundation.dart';

class SaleClientNotifier extends StateNotifier<List<SaleClient>> {
  SaleClientNotifier() : super([]);

  Future<void> fetchSaleClient(dynamic ref) async {
    try {
      final response = await ApiServices.get(
        CrmFliperUrls.fetchSaleClient,
        ref: ref,
        hasToken: true,
      );
      if (response != null && response.statusCode == 200) {
        final responseString = utf8.decode(response.data);
        final jsonResponse = jsonDecode(responseString);
        final saleClientResponse = SaleClientResponse.fromJson(jsonResponse);
        state = saleClientResponse.results;
        if (kDebugMode) debugPrint('Sale clients fetched successfully. Count: ${state.length}');
        for (var client in state) {
          if (kDebugMode) {
            debugPrint(
              'Client ID: ${client.id}, Full Name: ${client.fullName}, Email: ${client.email}');
          }
        }
      } else {
        if (kDebugMode) {
          debugPrint(
            'Sale clients fetch failed. Status code: ${response?.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching sale clients: $e');
    }
  }

  Future<void> createSaleClient(dynamic ref) async {
    try {
      final body = {
        "user": 1,
        "full_name": "John Doe".tr,
        "email": "younis@example.com",
        "phone_number": "+1234567890"
      };
      final response = await ApiServices.post(CrmFliperUrls.createSaleClient,
          hasToken: true, data: body);
      if (response != null && response.statusCode == 201) {
        if (kDebugMode) debugPrint('Sale client created successfully');
        await fetchSaleClient(ref);
      } else {
        if (kDebugMode) {
          debugPrint(
            'Sale client creation failed. Status code: ${response?.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error creating sale client: $e');
    }
  }
}

final saleClientProvider =
    StateNotifierProvider<SaleClientNotifier, List<SaleClient>>(
  (ref) => SaleClientNotifier(),
);
