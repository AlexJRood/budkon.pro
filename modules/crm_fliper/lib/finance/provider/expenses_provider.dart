import 'dart:convert';
import 'package:crm_fliper/crm_fliper_urls.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crm_fliper/finance/models/expense_model.dart';
import 'package:crm_fliper/finance/models/expenses_response_model.dart';
import 'package:core/platform/api_services.dart';
import 'package:flutter/foundation.dart';

class ExpensesNotifier extends StateNotifier<List<Expense>> {
  ExpensesNotifier() : super([]);

  Future<void> fetchExpenses(dynamic ref) async {
    try {
      final response = await ApiServices.get(
        CrmFliperUrls.fetchExpenses,
        ref: ref,
        hasToken: true,
      );
      if (response != null && response.statusCode == 200) {
        final responseString = utf8.decode(response.data);
        final jsonResponse = jsonDecode(responseString);
        final expensesResponse = ExpensesResponse.fromJson(jsonResponse);
        state = expensesResponse.results;
        if (kDebugMode) debugPrint('Expenses fetched successfully. Count: ${state.length}');
        for (var expense in state) {
          if (kDebugMode) {
            debugPrint(
              'Expense ID: ${expense.id}, Title: ${expense.title}, Amount: ${expense.amount}');
          }
        }
      } else {
        if (kDebugMode) debugPrint('Expenses fetch failed. Status code: ${response?.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching expenses: $e');
    }
  }

  Future<void> createExpenses(dynamic ref) async {
    try {
      final data = {
        "title": "Renovation Cost",
        "transaction": 1,
        "amount": 50000.00,
        "date": "2025-02-09"
      };
      final response = await ApiServices.post(CrmFliperUrls.createExpenses,
          hasToken: true, data: data);
      if (response != null && response.statusCode == 201) {
        if (kDebugMode) debugPrint('Expense created successfully');
        await fetchExpenses(ref);
      } else {
        if (kDebugMode) debugPrint('Expense creation failed. Status code: ${response?.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error creating expense: $e');
    }
  }
}

final expensesProvider = StateNotifierProvider<ExpensesNotifier, List<Expense>>(
  (ref) => ExpensesNotifier(),
);
