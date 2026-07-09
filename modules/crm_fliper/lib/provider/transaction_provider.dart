import 'package:flutter/foundation.dart';
import 'package:crm_fliper/crm_fliper_urls.dart';
import 'package:crm_fliper/models/fliper_transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';

final transactionsProvider = StateNotifierProvider<
  TransactionsNotifier,
  AsyncValue<TransactionsResponse>
>((ref) => TransactionsNotifier(ref));

class TransactionsNotifier
    extends StateNotifier<AsyncValue<TransactionsResponse>> {
  final Ref ref;

  TransactionsNotifier(this.ref) : super(const AsyncLoading()) {
    fetchTransactions();
  }

  /// ✅ Fetch all transactions
  Future<void> fetchTransactions() async {
    try {
      final response = await ApiServices.get(
        CrmFliperUrls.fetchTransactions,
        ref: ref,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        debugPrint('✅ Transaction loaded successfully');
        final data = TransactionsResponse.fromJson(response.data);
        state = AsyncData(data);
      } else {
        state = AsyncError(
          Exception('Failed to fetch transactions: ${response?.statusCode}'),
          StackTrace.current,
        );
      }
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  /// ✅ Create a new transaction
  Future<void> createTransaction({
    String? title,
    String? address,
    String? area,
    int? rooms,
    String? technicalCondition,
    String? description,
    String? note,
    dynamic checklist,
    int? transaction,
    int? transactionNetworkMonitoring,
    int? transactionHously,
    required int user,
    required int client,
    BuildContext? context,
  }) async {
    try {
      // Only include non-null fields
      final Map<String, dynamic> requestData = {
        "title": title,
        "address": address,
        "area": area,
        "rooms": rooms,
        "technical_condition": technicalCondition,
        "description": description,
        "note": note,
        "checklist": checklist,
        "transaction": transaction,
        "transaction_network_monitoring": transactionNetworkMonitoring,
        "transaction_hously": transactionHously,
        "user": user,
        "client": client,
      }..removeWhere((_, v) => v == null);

      debugPrint('📦 Sending request: $requestData');

      final response = await ApiServices.post(
        CrmFliperUrls.fetchTransactions,
        data: requestData,
        hasToken: true,
      );

      if (response != null && response.statusCode == 201) {
        debugPrint('✅ Transaction created successfully');
        final created = FliperTransaction.fromJson(response.data);

        final currentState = state;
        if (currentState is AsyncData<TransactionsResponse>) {
          final updatedList = [created, ...currentState.value.results];
          final updatedResponse = TransactionsResponse(
            count: currentState.value.count + 1,
            next: currentState.value.next,
            previous: currentState.value.previous,
            results: updatedList,
          );
          state = AsyncData(updatedResponse);
        } else {
          state = AsyncData(
            TransactionsResponse(
              count: 1,
              next: null,
              previous: null,
              results: [created],
            ),
          );
        }
      } else {
        debugPrint('❌ Failed to create transaction: ${response?.statusCode}');
        final errorData = response?.data;

        if (errorData is Map<String, dynamic>) {
          debugPrint('❗ Validation errors:');
          errorData.forEach((field, value) {
            if (value is List) {
              for (var msg in value) {
                debugPrint('• $field: $msg');
                if (context != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$field: $msg')),
                  );
                }
              }
            } else {
              debugPrint('• $field: $value');
              if (context != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$field: $value')),
                );
              }
            }
          });
        } else if (errorData is String && errorData.contains('<html')) {
          debugPrint('⚠️ Server HTML error response received.');
          if (context != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Server error (500). Please contact support.'),
              ),
            );
          }
        } else {
          debugPrint('⚠️ Unexpected error response: $errorData');
        }

        state = AsyncError(
          Exception('Failed to create transaction: ${response?.statusCode}'),
          StackTrace.current,
        );
      }
    } catch (e, stack) {
      debugPrint('❌ Exception: $e');
      state = AsyncError(e, stack);
    }
  }


  Future<FliperTransaction?> fetchSingleTransaction(String id) async {
    try {
      final response = await ApiServices.get(
        CrmFliperUrls.fetchSingleTransactions(id),
        ref: ref,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        final data = response.data;
        final transaction = FliperTransaction.fromJson(data);
        return transaction;
      } else {
        debugPrint('Failed to fetch transaction: ${response?.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching transaction: $e');
      return null;
    }
  }

  Future<FliperTransaction?> editTransaction({
    required String id,
    String? title,
    String? address,
    String? area,
    int? rooms,
    String? technicalCondition,
    String? description,
    String? note,
    dynamic checklist,
    int? transaction,
    int? transactionNetworkMonitoring,
    int? transactionHously,
    required int user,
    required int client,
  }) async {
    try {
      final requestData = {
        "title": title,
        "address": address,
        "area": area,
        "rooms": rooms,
        "technical_condition": technicalCondition,
        "description": description,
        "note": note,
        "checklist": checklist,
        "transaction": transaction,
        "transaction_network_monitoring": transactionNetworkMonitoring,
        "transaction_hously": transactionHously,
        "user": user,
        "client": client,
      };

      final response = await ApiServices.put(
        CrmFliperUrls.fetchSingleTransactions(id),
        data: requestData,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        final updated = FliperTransaction.fromJson(response.data);

        final currentState = state;
        if (currentState is AsyncData<TransactionsResponse>) {
          final updatedList =
              currentState.value.results.map((item) {
                return item.id.toString() == id ? updated : item;
              }).toList();

          final updatedResponse = TransactionsResponse(
            count: currentState.value.count,
            next: currentState.value.next,
            previous: currentState.value.previous,
            results: updatedList,
          );

          state = AsyncData(updatedResponse);
        }

        return updated;
      } else {
        state = AsyncError(
          Exception('Failed to update transaction: ${response?.statusCode}'),
          StackTrace.current,
        );
        return null;
      }
    } catch (e, stack) {
      state = AsyncError(e, stack);
      return null;
    }
  }

  Future<bool> deleteTransaction(String id) async {
    try {
      final response = await ApiServices.delete(
        CrmFliperUrls.fetchSingleTransactions(id),
        hasToken: true,
      );

      if (response != null && response.statusCode == 204) {
        final currentState = state;
        if (currentState is AsyncData<TransactionsResponse>) {
          final updatedList =
              currentState.value.results
                  .where((item) => item.id.toString() != id)
                  .toList();

          final updatedResponse = TransactionsResponse(
            count: currentState.value.count - 1,
            next: currentState.value.next,
            previous: currentState.value.previous,
            results: updatedList,
          );

          state = AsyncData(updatedResponse);
        }

        return true;
      } else {
        state = AsyncError(
          Exception('Failed to delete transaction: ${response?.statusCode}'),
          StackTrace.current,
        );
        return false;
      }
    } catch (e, stack) {
      state = AsyncError(e, stack);
      return false;
    }
  }
}
