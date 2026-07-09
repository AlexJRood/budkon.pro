import 'dart:convert';
import 'package:crm_fliper/crm_fliper_urls.dart';
import 'package:flutter/foundation.dart';
import 'package:crm_fliper/models/flipper_expenses_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';

final flipperExpensesProvider =
    StateNotifierProvider<FlipperExpensesNotifier, List<FlipperExpense>>(
      (ref) => FlipperExpensesNotifier(ref),
    );

class FlipperExpensesNotifier extends StateNotifier<List<FlipperExpense>> {
  final Ref ref;

  FlipperExpensesNotifier(this.ref) : super([]);

  Future<void> fetchFlipperExpenses() async {
    try {
      final response = await ApiServices.get(
        CrmFliperUrls.fetchExpenses,
        ref: ref,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(
          utf8.decode(response.data),
        );
        final data = FlipperExpenseResponse.fromJson(jsonData);
        state = data.results;
        debugPrint('✅ Expenses loaded: ${state.length}');
      } else {
        debugPrint('❌ Failed to fetch expenses: ${response?.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Exception in fetchFlipperExpenses: $e');
    }
  }

  Future<void> createFlipperExpenses({
    required String title,
    required String amount,
    required String date,
    required int transaction,
  }) async {
    try {
      final requestData = {
        'title': title,
        'amount': amount,
        'date': date,
        'transaction': transaction,
      };

      final response = await ApiServices.post(
        CrmFliperUrls.fetchExpenses,
        hasToken: true,
        data: requestData,
      );

      if (response != null && response.statusCode == 201) {
        final newExpense = FlipperExpense.fromJson(response.data);
        state = [...state, newExpense];
        debugPrint('✅ Expense created with ID: ${newExpense.id}');
      } else {
        debugPrint('❌ Failed to create expense: ${response?.statusCode}');

        final errors = response?.data;
        if (errors is Map<String, dynamic>) {
          debugPrint('❗ Validation errors:');
          errors.forEach((field, messages) {
            if (messages is List) {
              for (final msg in messages) {
                debugPrint('• $field: $msg');
              }
            } else {
              debugPrint('• $field: $messages');
            }
          });
        } else {
          debugPrint('⚠️ Raw response: ${response?.data}');
        }
      }
    } catch (e, stack) {
      debugPrint('❌ Exception in createFlipperExpenses: $e');
      debugPrint(stack.toString());
    }
  }


  Future<FlipperExpense?> fetchSingleFlipperExpenses(String id) async {
    try {
      final response = await ApiServices.get(
        CrmFliperUrls.fetchSingleExpenses(id),
        ref: ref,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(
          utf8.decode(response.data),
        );
        final expense = FlipperExpense.fromJson(jsonData);
        debugPrint('✅ Single flipper expense fetched: ${expense.id}');
        return expense;
      } else {
        debugPrint(
          '❌ Failed to fetch single flipper expense: ${response?.statusCode}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('❌ Exception in fetchSingleFlipperExpenses: $e');
      return null;
    }
  }

  Future<void> editFlipperExpenses({
    required String id,
    required String title,
    required String amount,
    required String date,
    required int transaction,
    int? createdBy,
  }) async {
    try {
      final requestData = {
        "title": title,
        "amount": amount,
        "date": date,
        "transaction": transaction,
        if (createdBy != null) "created_by": createdBy,
      };

      final response = await ApiServices.put(
        CrmFliperUrls.fetchSingleExpenses(id),
        hasToken: true,
        data: requestData,
      );

      if (response != null && response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(
          utf8.decode(response.data),
        );
        final updatedExpense = FlipperExpense.fromJson(jsonData);
        debugPrint('✅ Expenses edited successfully: ${updatedExpense.id}');
      } else {
        debugPrint('❌ Expenses edit failed: ${response?.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Exception in editFlipperExpenses: $e');
    }
  }

  Future<void> deleteFlipperExpenses(String id) async {
    try {
      final response = await ApiServices.delete(
        CrmFliperUrls.fetchSingleExpenses(id),
        hasToken: true,
      );
      if (response != null && response.statusCode == 204) {
        debugPrint('Expenses deleted successfully');
      } else {
        debugPrint('Expenses delete failed ${response?.statusCode}');
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}
