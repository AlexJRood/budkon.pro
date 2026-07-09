import 'package:flutter/foundation.dart';
import 'package:crm_fliper/crm_fliper_urls.dart';
import 'package:crm_fliper/models/fliper_transaction_document_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';

final transactionDocumentProvider = StateNotifierProvider<
  TransactionDocumentNotifier,
  AsyncValue<TransactionDocumentResponse>
>((ref) => TransactionDocumentNotifier(ref));

class TransactionDocumentNotifier
    extends StateNotifier<AsyncValue<TransactionDocumentResponse>> {
  final Ref ref;

  TransactionDocumentNotifier(this.ref) : super(const AsyncLoading()) {
    fetchTransactionDocument();
  }

  /// ✅ Fetch all transaction documents
  Future<void> fetchTransactionDocument() async {
    try {
      final response = await ApiServices.get(
        CrmFliperUrls.fetchTransactionDocument,
        ref: ref,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        debugPrint('✅ Transaction document loaded successfully');
        final parsed = TransactionDocumentResponse.fromJson(response.data);
        state = AsyncData(parsed);
      } else {
        state = AsyncError(
          Exception(
            'Failed to fetch transaction documents: ${response?.statusCode}',
          ),
          StackTrace.current,
        );
      }
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  /// ✅ Create a new transaction document
  Future<void> createTransactionDocument({
    required String documentType,
    required String file,
    required int transaction,
    required int user,
    BuildContext? context, // optional for showing SnackBar
  }) async {
    try {
      final requestData = {
        "document_type": documentType,
        "transaction": transaction,
        "user": user,
      };

      final response = await ApiServices.post(
        CrmFliperUrls.fetchTransactionDocument,
        data: requestData,
        hasToken: true,
      );

      if (response != null && response.statusCode == 201) {
        debugPrint('✅ Transaction document added successfully');
        final created = FliperTransactionDocument.fromJson(response.data);

        final currentState = state;
        if (currentState is AsyncData<TransactionDocumentResponse>) {
          final updatedList = [created, ...currentState.value.results];
          state = AsyncData(
            TransactionDocumentResponse(
              count: currentState.value.count + 1,
              next: currentState.value.next,
              previous: currentState.value.previous,
              results: updatedList,
            ),
          );
        } else {
          state = AsyncData(
            TransactionDocumentResponse(
              count: 1,
              next: null,
              previous: null,
              results: [created],
            ),
          );
        }
      } else {
        debugPrint('❌ Failed to create transaction document: ${response?.statusCode}');
        final errorData = response?.data;

        if (errorData is Map<String, dynamic>) {
          debugPrint('❗ Validation errors:');
          errorData.forEach((field, value) {
            if (value is List) {
              for (final msg in value) {
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
          Exception('Validation error while creating transaction document'),
          StackTrace.current,
        );
      }
    } catch (e, stack) {
      debugPrint('❌ Exception: $e');
      state = AsyncError(e, stack);
    }
  }


  Future<FliperTransactionDocument?> fetchSingleTransactionDocument(
    String id,
  ) async {
    try {
      final response = await ApiServices.get(
        CrmFliperUrls.fetchSingleTransactionDocument(id),
        ref: ref,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        final json = response.data;
        final document = FliperTransactionDocument.fromJson(json);
        return document;
      } else {
        debugPrint('Failed to fetch document: ${response?.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching document: $e');
      return null;
    }
  }

  Future<FliperTransactionDocument?> editTransactionDocument({
    required String id,
    String? documentType,
    int? transaction,
    required int user,
  }) async {
    try {
      final requestData = {
        "document_type": documentType,
        "transaction": transaction,
        "user": user,
      };

      final response = await ApiServices.put(
        CrmFliperUrls.fetchSingleTransactionDocument(id),
        data: requestData,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        final updated = FliperTransactionDocument.fromJson(response.data);

        final currentState = state;
        if (currentState is AsyncData<TransactionDocumentResponse>) {
          final updatedList =
              currentState.value.results.map((doc) {
                return doc.id.toString() == id ? updated : doc;
              }).toList();

          final updatedResponse = TransactionDocumentResponse(
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
            'Failed to update transaction document: ${response?.statusCode}',
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

  Future<bool> deleteTransactionDocument(String id) async {
    try {
      final response = await ApiServices.delete(
        CrmFliperUrls.fetchSingleTransactionDocument(id),
        hasToken: true,
      );

      if (response != null && response.statusCode == 204) {
        final currentState = state;
        if (currentState is AsyncData<TransactionDocumentResponse>) {
          final updatedList =
              currentState.value.results
                  .where((doc) => doc.id.toString() != id)
                  .toList();

          final updatedResponse = TransactionDocumentResponse(
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
            'Failed to delete transaction document: ${response?.statusCode}',
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
