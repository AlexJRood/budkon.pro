import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/url.dart';
import 'package:core/platform/api_services.dart';
import 'dart:convert';

import 'package:get/get_utils/get_utils.dart';

final transactionTypeProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    final response = await ApiServices.get(
      ref: ref,
      URLs.transactionSummary,
      hasToken: true,
    );

    if (response == null || response.data == null) {
      throw Exception("No response or invalid data from API".tr);
    }

    final decodedBody = utf8.decode(response.data);
    final parsedData = json.decode(decodedBody);

    if (parsedData is Map<String, dynamic>) {
      // Weryfikujemy, czy dane zawierają klucze 'expenses' i 'revenues'
      final expenses = List<Map<String, dynamic>>.from(
          parsedData['expenses'] ?? const []);
      final revenues = List<Map<String, dynamic>>.from(
          parsedData['revenues'] ?? const []);

      return {
        "expenses": expenses,
        "revenues": revenues,
      };
    } else {
      throw Exception("Unexpected data structure".tr);
    }
  } catch (error) {
    throw Exception("Failed to fetch transaction summary: $error".tr);
  }
});
