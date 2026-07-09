import 'package:get/get_utils/get_utils.dart';

// providers/api_servises_expenses.dart

import 'package:crm/shared/models/expense/expenses_model_new.dart';
import 'package:crm/crm_urls.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/url.dart';
import 'package:core/platform/api_services.dart';
import 'dart:convert';

final expensesProvider = StateNotifierProvider<ExpensesPlanNotifier,
    AsyncValue<List<ExpenseModelNew>>>((ref) {
  return ExpensesPlanNotifier();
});

class ExpensesPlanNotifier extends StateNotifier<AsyncValue<List<ExpenseModelNew>>> {
  ExpensesPlanNotifier() : super(const AsyncValue.loading()) {
    fetchExpenses();
  }

  Future<void> fetchExpenses({List<int>? years, List<int>? months, String? ordering,dynamic ref}) async {
    try {
      final now = DateTime.now();
      // Użyj bieżącego roku, jeśli `years` jest puste lub null
      final effectiveYears = (years == null || years.isEmpty) ? [now.year] : years;
      // Użyj bieżącego miesiąca, jeśli `months` jest puste lub null
      final effectiveMonths = (months == null || months.isEmpty) ? [now.month] : months;
      final queryParams = {
        'year': effectiveYears.join(','),
        'month': effectiveMonths.join(','),
        'ordering': ordering ?? 'amount',
      };
      final response = await ApiServices.get(
        ref: ref,
        CrmUrls.financeAppExpenses,
        hasToken: true,
        queryParameters: queryParams,
      );

      if (response == null) {
        state =
            AsyncValue.error(Exception('Invalid request'.tr), StackTrace.current);
        return;
      }

      final decodedDatabody = utf8.decode(response.data);
      final decodeData = json.decode(decodedDatabody) as List;
      final expesnes = decodeData.map((plan) => ExpenseModelNew.fromJson(plan)).toList();

      state = AsyncValue.data(expesnes);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }



  Future<void> createExpense(ExpenseModelNew newPlan) async {
    try {
      final response = await ApiServices.post(
        CrmUrls.addFinanceAppExpenses,
        hasToken: true,
        data: {
          'clients': newPlan.clientId,
          'amount': newPlan.amount,
          'currency': newPlan.currency,
          'status': newPlan.status,
          'date_create': newPlan.dateCreate,
        },
      );

      if (response == null) {
        throw Exception('Token not found'.tr);
      }
      if (response.statusCode == 201) {
        fetchExpenses();
      } else {
        throw Exception('Failed to create plan'.tr);
      }
    } catch (error) {
      throw Exception('Failed to create expense plan: $error'.tr);
    }
  }




  Future<void> updateExpens(ExpenseModelNew updatedPlan) async {
    try {
      final response = await ApiServices.put(
        CrmUrls.updateFinanceAppExpenses('${updatedPlan.id}'),
        hasToken: true,
        data: {
          'amount': updatedPlan.amount,
          'currency': updatedPlan.currency,
          'status': updatedPlan.status,
        },
      );

      if (response == null) return;

      if (response.statusCode == 200) {
        fetchExpenses();
      } else {
        throw Exception('Failed to update plan'.tr);
      }
    } catch (error) {
      throw Exception('Failed to update expense plan: $error'.tr);
    }
  }


  Future<void> deleteExpense(int planId) async {
    try {
      final response = await ApiServices.delete(
        CrmUrls.deleteFinanceAppExpenses('$planId'),
        hasToken: true,
      );

      if (response == null) return;
      if (response.statusCode == 204) {
        fetchExpenses();
      } else {
        throw Exception('Failed to delete plan'.tr);
      }
    } catch (error) {
      throw Exception('Failed to delete expense plan: $error'.tr);
    }
  }
}

//   Future<void> togglePaymentStatusFor(List<int> planIds) async {
//     try {
//       final response = await ApiServices.post(
//         URLs.payedStatusExpensesFinancial,
//         data: {'plan_ids': planIds},
//         hasToken: true,
//       );

//       if (response == null) return;
//       if (response.statusCode == 200) {
//         final filters = state.value != null ? _currentFilters() : null;
//         // Refresh the list with the current filters
//         fetchExpenses(
//           years: filters?.years,
//           months: filters?.months,
//           ordering: filters?.ordering,
//         );
//       } else {
//         // Handle error
//         throw Exception('Failed to update payment status'.tr);
//       }
//     } catch (error) {
//       // Handle error
//       throw Exception('Error updating payment status: $error'.tr);
//     }
//   }

//   Filters? _currentFilters() {
//     // This method should retrieve the current filters from the state or wherever they are stored
//     // Example placeholder logic, replace with actual filter retrieval logic
//     return Filters(
//       years: [2024],
//       months: [9],
//       ordering: 'amount',
//     );
//   }
// }

// final availableYearsExpensesProvider = FutureProvider<List<int>>((ref) async {
//   final response = await ApiServices.get(
//     ref: ref,
//     URLs.availableYearsExpensesFinancial, // Endpoint do pobierania dostępnych lat
//     hasToken: true,
//   );

//   if (response == null) return [];
//       final decodedDatabody = utf8.decode(response.data);
//       final decodeData = json.decode(decodedDatabody) as List;
//   return decodeData.map((year) => year as int).toList();
// });
