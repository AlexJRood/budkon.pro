import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/api_services.dart';
import 'package:dio/src/options.dart';

class InvoiceNumberApi {
  // Comments in English.
  Future<Map<String, dynamic>> preview({
    required Ref ref,
    required String kind,
  }) async {
    // Adjust path if your router differs:
    // e.g. /finance/invoices/invoice-numbers/preview/
    final res = await ApiServices.get(
      responseType: ResponseType.json,
      hasToken: true,
      ref: ref,
      'https://www.superbee.cloud/finance/invoice-numbers/preview/',
      queryParameters: {'kind': kind},
    );

    // ApiServices.get might return a nullable Response (or dynamic),
    // so we safely read .data.
    final dynamic data = res?.data;

    if (data is Map<String, dynamic>) {
      return data;
    }

    // Sometimes decoded JSON is Map<dynamic, dynamic>
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception('${'invalid_response_shape_for_invoice_preview'.tr}: ${data.runtimeType}');
  }
}
