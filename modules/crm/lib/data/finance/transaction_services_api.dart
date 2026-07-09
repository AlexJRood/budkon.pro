import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crm/crm_urls.dart';
import 'package:core/platform/api_services.dart';

import 'package:get/get_utils/get_utils.dart';

final apiProviderTransaction = Provider<ApiServiceTransaction>((ref) => ApiServiceTransaction());

class ApiServiceTransaction {
  ApiServiceTransaction();

  Future<void> updateColumnIndexes(List<int> columnIds) async {
    final response = await ApiServices.patch(
      CrmUrls.agentTransactionUpdateColumnIndexes,
      data: {'columns': columnIds},
      hasToken: true,
    );

    if (response != null && response.statusCode != 200) {
      throw Exception('Failed to update column indexes'.tr);
    }
  }

  Future<void> updateTransactionStatuses(
      List<Map<String, dynamic>> statuses) async {
    final response = await ApiServices.patch(
      CrmUrls.updateAgentTransactionStatus,
      data: {'statuses': statuses},
      hasToken: true,
    );

    if (response != null && response.statusCode != 200) {
      throw Exception('Failed to update transaction statuses'.tr);
    }
  }
}
