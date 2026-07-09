import 'package:flutter/foundation.dart';
import 'package:crm_fliper/crm_fliper_urls.dart';
import 'package:crm_fliper/models/fliper_transaction_checklist_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/platform/url.dart';

final transactionChecklistProvider = StateNotifierProvider<
  TransactionChecklistNotifier,
  AsyncValue<TransactionChecklistResponse>
>((ref) => TransactionChecklistNotifier(ref));

class TransactionChecklistNotifier
    extends StateNotifier<AsyncValue<TransactionChecklistResponse>> {
  final Ref ref;

  TransactionChecklistNotifier(this.ref) : super(const AsyncLoading()) {
    fetchTransactionChecklist();
  }

  /// ✅ Fetch all checklists
  Future<void> fetchTransactionChecklist() async {
    try {
      final response = await ApiServices.get(
        URLs.fetchTransactionChecklist,
        ref: ref,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        debugPrint('✅ Transaction checklist loaded successfully');
        final parsed = TransactionChecklistResponse.fromJson(response.data);
        state = AsyncData(parsed);
      } else {
        state = AsyncError(
          Exception(
            'Failed to fetch transaction checklist: ${response?.statusCode}',
          ),
          StackTrace.current,
        );
      }
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  /// ✅ Create a checklist
  Future<void> createTransactionChecklist({
    required String title,
    required String description,
    dynamic checklist,
    int? transaction,
    int? predefined,
    required int user,
    BuildContext? context, // Optional for showing SnackBar
  }) async {
    try {
      final requestData = {
        "title": title,
        "description": description,
        "checklist": checklist,
        "transaction": transaction,
        "Predefined": predefined,
        "user": user,
      };

      final response = await ApiServices.post(
        URLs.fetchTransactionChecklist,
        data: requestData,
        hasToken: true,
      );

      if (response != null && response.statusCode == 201) {
        debugPrint('✅ Transaction checklist created successfully');
        final created = FliperTransactionCheckList.fromJson(response.data);

        final currentState = state;
        if (currentState is AsyncData<TransactionChecklistResponse>) {
          final updatedList = [created, ...currentState.value.results];

          final updatedResponse = TransactionChecklistResponse(
            count: currentState.value.count + 1,
            next: currentState.value.next,
            previous: currentState.value.previous,
            results: updatedList,
          );

          state = AsyncData(updatedResponse);
        } else {
          state = AsyncData(
            TransactionChecklistResponse(
              count: 1,
              next: null,
              previous: null,
              results: [created],
            ),
          );
        }
      } else {
        debugPrint('❌ Failed to create transaction checklist: ${response?.statusCode}');

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
        } else {
          debugPrint('⚠️ Unexpected error body: ${response?.data}');
          if (context != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Unexpected error occurred')),
            );
          }
        }

        state = AsyncError(
          Exception('Validation error while creating transaction checklist'),
          StackTrace.current,
        );
      }
    } catch (e, stack) {
      debugPrint('❌ Exception: $e');
      state = AsyncError(e, stack);
    }
  }


  Future<void> createTransactionChecklistCopyPredefined({
    required String title,
    required String description,
    dynamic checklist,
    int? transaction,
    int? predefined,
    required int user,
  }) async {
    try {
      final requestData = {
        "title": title,
        "description": description,
        "checklist": checklist,
        "transaction": transaction,
        "Predefined": predefined,
        "user": user,
      };

      final response = await ApiServices.post(
        CrmFliperUrls.createTransactionChecklistCopyPredefined,
        data: requestData,
        hasToken: true,
      );

      if (response != null && response.statusCode == 201) {
        final created = FliperTransactionCheckList.fromJson(response.data);

        final currentState = state;
        if (currentState is AsyncData<TransactionChecklistResponse>) {
          final updatedList = [created, ...currentState.value.results];

          final updatedResponse = TransactionChecklistResponse(
            count: currentState.value.count + 1,
            next: currentState.value.next,
            previous: currentState.value.previous,
            results: updatedList,
          );

          state = AsyncData(updatedResponse);
        } else {
          state = AsyncData(
            TransactionChecklistResponse(
              count: 1,
              next: null,
              previous: null,
              results: [created],
            ),
          );
        }
      } else {
        state = AsyncError(
          Exception(
            'Failed to create checklist from predefined: ${response?.statusCode}',
          ),
          StackTrace.current,
        );
      }
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  Future<FliperTransactionCheckList?> fetchSingleTransactionChecklist(
    String id,
  ) async {
    try {
      final response = await ApiServices.get(
        URLs.fetchSingleTransactionChecklist(id),
        ref: ref,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        final json = response.data;
        final checklist = FliperTransactionCheckList.fromJson(json);
        return checklist;
      } else {
        debugPrint('Failed to fetch checklist: ${response?.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching checklist: $e');
      return null;
    }
  }

  Future<FliperTransactionCheckList?> editTransactionChecklist({
    required String id,
    required String title,
    required String description,
    dynamic checklist,
    int? transaction,
    int? predefined,
    required int user,
  }) async {
    try {
      final requestData = {
        "title": title,
        "description": description,
        "checklist": checklist,
        "transaction": transaction,
        "Predefined": predefined,
        "user": user,
      };

      final response = await ApiServices.put(
        URLs.fetchSingleTransactionChecklist(id),
        data: requestData,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        final updated = FliperTransactionCheckList.fromJson(response.data);

        final currentState = state;
        if (currentState is AsyncData<TransactionChecklistResponse>) {
          final updatedList =
              currentState.value.results.map((item) {
                return item.id.toString() == id ? updated : item;
              }).toList();

          final updatedResponse = TransactionChecklistResponse(
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
          Exception(
            'Failed to update transaction checklist: ${response?.statusCode}',
          ),
          StackTrace.current,
        );
        return null;
      }
    } catch (e, stack) {
      state = AsyncError(e, stack);
      return null;
    }
  }

  Future<bool> deleteTransactionChecklist(String id) async {
    try {
      final response = await ApiServices.delete(
        URLs.fetchSingleTransactionChecklist(id),
        hasToken: true,
      );

      if (response != null && response.statusCode == 204) {
        final currentState = state;
        if (currentState is AsyncData<TransactionChecklistResponse>) {
          final updatedList =
              currentState.value.results
                  .where((item) => item.id.toString() != id)
                  .toList();

          final updatedResponse = TransactionChecklistResponse(
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
          Exception(
            'Failed to delete transaction checklist: ${response?.statusCode}',
          ),
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
