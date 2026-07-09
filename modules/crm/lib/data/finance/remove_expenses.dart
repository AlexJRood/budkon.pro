// ignore_for_file: unused_result

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crm/crm_urls.dart';
import 'dio_provider.dart';
import 'package:core/platform/api_services.dart';

final removeCrmExpensesProvider =
    Provider((ref) => RemoveCrmExpensesProvider(ref));

class RemoveCrmExpensesProvider {
  final Ref ref;
  RemoveCrmExpensesProvider(this.ref);

  Future<void> removeCrmExpenses(int crmRevenueId) async {
    var response = await ApiServices.delete(
      CrmUrls.deleteFinanceAppExpenses('$crmRevenueId'),
      hasToken: true,
    );

    if (response != null && response.statusCode == 204) {
      //tutaj dodaj odświeżenie listy zapisanych wyszukiwań
      ref.invalidate(crmRevenueProvider);
    }
  }
}
