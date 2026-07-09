import 'package:get/get_utils/get_utils.dart';
import 'package:crm/crm_urls.dart';

// providers/api_servises_expenses.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crm/data/finance/filter_plans.dart';
import 'package:core/platform/api_services.dart';
import 'dart:convert';

import 'package:core/common/models/expenses_plan_model.dart';

final expensesPlanProvider = StateNotifierProvider<ExpensesPlanNotifier,
    AsyncValue<List<ExpensesPlanModel>>>((ref) {
  return ExpensesPlanNotifier();
});

class ExpensesPlanNotifier
    extends StateNotifier<AsyncValue<List<ExpensesPlanModel>>> {
  ExpensesPlanNotifier() : super(const AsyncValue.loading()) {
    fetchExpensesPlans();
  }

  Future<void> fetchExpensesPlans(
      {List<int>? years, List<int>? months, String? ordering,dynamic ref}) async {
    try {
      final now = DateTime.now();
      // Użyj bieżącego roku, jeśli `years` jest puste lub null
      final effectiveYears =
          (years == null || years.isEmpty) ? [now.year] : years;
      // Użyj bieżącego miesiąca, jeśli `months` jest puste lub null
      final effectiveMonths =
          (months == null || months.isEmpty) ? [now.month] : months;
      final queryParams = {
        'year': effectiveYears.join(','),
        'month': effectiveMonths.join(','),
        'ordering': ordering ?? 'amount',
      };
      final response = await ApiServices.get(
        ref: ref,
        CrmUrls.expensesFinancialPlans,
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
      final plans = decodeData.map((plan) => ExpensesPlanModel.fromJson(plan)).toList();

      state = AsyncValue.data(plans);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> createExpensePlan(ExpensesPlanModel newPlan) async {
    try {
      final response = await ApiServices.post(
        CrmUrls.expensesFinancialPlans,
        hasToken: true,
        data: {
          'amount': newPlan.amount,
          'currency': newPlan.currency,
          'status': newPlan.status,
          'date_create': newPlan.dateCreate,
          'year': newPlan.year,
          'month': newPlan.month,
        },
      );

      if (response == null) {
        throw Exception('Token not found'.tr);
      }
      if (response.statusCode == 201) {
        fetchExpensesPlans();
      } else {
        throw Exception('Failed to create plan'.tr);
      }
    } catch (error) {
      throw Exception('Failed to create expense plan: $error'.tr);
    }
  }

  Future<void> updateExpensePlan(ExpensesPlanModel updatedPlan) async {
    try {
      final response = await ApiServices.put(
        CrmUrls.singleExpensesFinancialPlans('${updatedPlan.id}'),
        hasToken: true,
        data: {
          'amount': updatedPlan.amount,
          'currency': updatedPlan.currency,
          'status': updatedPlan.status,
          'year': updatedPlan.year,
          'month': updatedPlan.month,
        },
      );

      if (response == null) return;

      if (response.statusCode == 200) {
        fetchExpensesPlans();
      } else {
        throw Exception('Failed to update plan'.tr);
      }
    } catch (error) {
      throw Exception('Failed to update expense plan: $error'.tr);
    }
  }

  Future<void> deleteExpensePlan(int planId) async {
    try {
      final response = await ApiServices.delete(
        CrmUrls.singleExpensesFinancialPlans('$planId'),
        hasToken: true,
      );

      if (response == null) return;
      if (response.statusCode == 204) {
        fetchExpensesPlans();
      } else {
        throw Exception('Failed to delete plan'.tr);
      }
    } catch (error) {
      throw Exception('Failed to delete expense plan: $error'.tr);
    }
  }

  Future<void> addPlanToExpense(int planId) async {
    try {
      final response = await ApiServices.post(
        CrmUrls.addPlanExpenseFinancialPlans('$planId'),
        hasToken: true,
      );

      if (response == null) return;
      if (response.statusCode == 200) {
        // Z powodzeniem dodano plan do wydatku
      } else {
        throw Exception('Failed to add plan to expense'.tr);
      }
    } catch (error) {
      throw Exception('Failed to add plan to expense: $error'.tr);
    }
  }

  Future<void> togglePaymentStatusForPlans(List<int> planIds) async {
    try {
      final response = await ApiServices.post(
        CrmUrls.payedStatusExpensesFinancialPlans,
        data: {'plan_ids': planIds},
        hasToken: true,
      );

      if (response == null) return;
      if (response.statusCode == 200) {
        final filters = state.value != null ? _currentFilters() : null;
        // Refresh the list with the current filters
        fetchExpensesPlans(
          years: filters?.years,
          months: filters?.months,
          ordering: filters?.ordering,
        );
      } else {
        // Handle error
        throw Exception('Failed to update payment status'.tr);
      }
    } catch (error) {
      // Handle error
      throw Exception('Error updating payment status: $error'.tr);
    }
  }

  Filters? _currentFilters() {
    // This method should retrieve the current filters from the state or wherever they are stored
    // Example placeholder logic, replace with actual filter retrieval logic
    return Filters(
      years: [2024],
      months: [9],
      ordering: 'amount',
    );
  }
}

final availableYearsExpensesPlansProvider = FutureProvider<List<int>>((ref) async {
  final response = await ApiServices.get(
    ref: ref,
    CrmUrls.availableYearsExpensesFinancialPlans, // Endpoint do pobierania dostępnych lat
    hasToken: true,
  );

  if (response == null) return [];
      final decodedDatabody = utf8.decode(response.data);
      final decodeData = json.decode(decodedDatabody) as List;
  return decodeData.map((year) => year as int).toList();
});
