
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crm/crm_urls.dart';
import 'package:core/platform/api_services.dart';



import 'package:get/get_utils/get_utils.dart';

final apiProviderUserContactsStatuses = Provider<ApiServiceUserContactsStatuses>((ref) => ApiServiceUserContactsStatuses());

class ApiServiceUserContactsStatuses{
  ApiServiceUserContactsStatuses();

  Future<void> updateColumnIndexes(List<int> columnIds) async {
    final response = await ApiServices.patch(
      CrmUrls.userContactStatusUpdateStatusesIndexes,
      data: {'columns': columnIds},
      hasToken: true,
    );

    if (response != null && response.statusCode != 200) {
      throw Exception('failed_to_update_column_indexes'.tr);
    }
  }

  Future<void> updateUserContactStatuses(
      List<Map<String, dynamic>> statuses) async {
    final response = await ApiServices.patch(
      CrmUrls.userContactStatusUpdateColumns,
      data: {'statuses': statuses},
      hasToken: true,
    );

    if (response != null && response.statusCode != 200) {
      throw Exception('failed_to_update_user_contact_statuses'.tr);
    }
  }
}
