import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crm/crm_urls.dart';
import 'package:core/platform/api_services.dart';
import 'dart:convert';

import 'package:get/get_utils/get_utils.dart';

final financialPlansProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final response = await ApiServices.get(
    ref: ref,
    CrmUrls.summaryFinancialPlans,
    hasToken: true,
    queryParameters: {
      'year': DateTime.now().year,
    },
  );

  if (response == null || response.data == null) {
    throw Exception("No response or invalid data from API".tr);
  }

  final decodedBody = utf8.decode(response.data);
  final parsedData = json.decode(decodedBody);

  if (parsedData is Map<String, dynamic>) {
    // Upewnij się, że klucze "expenses" i "revenues" są obsługiwane
    final expenses = List<Map<String, dynamic>>.from(parsedData['expenses'] ?? []);
    final revenues = List<Map<String, dynamic>>.from(parsedData['revenues'] ?? []);

    // Obsłuż przypadki, gdy "expenses" lub "revenues" są puste
    return {
      'expenses': expenses,
      'revenues': revenues,
    };
  } else {
    throw Exception("Unexpected data structure".tr);
  }
});
