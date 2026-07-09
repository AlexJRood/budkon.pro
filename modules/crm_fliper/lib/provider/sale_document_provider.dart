import 'package:flutter/foundation.dart';
import 'package:crm_fliper/crm_fliper_urls.dart';
import 'package:crm_fliper/models/fliper_sale_document_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';

final saleDocumentProvider = StateNotifierProvider<
  SaleDocumentNotifier,
  AsyncValue<SaleDocumentResponse>
>((ref) => SaleDocumentNotifier(ref));

class SaleDocumentNotifier
    extends StateNotifier<AsyncValue<SaleDocumentResponse>> {
  final Ref ref;

  SaleDocumentNotifier(this.ref) : super(const AsyncLoading()) {
    fetchSaleDocument();
  }

  /// ✅ Fetch all sale documents
  Future<void> fetchSaleDocument() async {
    try {
      final response = await ApiServices.get(
        CrmFliperUrls.fetchSaleDocument,
        ref: ref,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        debugPrint('✅ Sale document loaded successfully');
        final data = SaleDocumentResponse.fromJson(response.data);
        state = AsyncData(data);
      } else {
        state = AsyncError(
          Exception('Failed to fetch sale documents: ${response?.statusCode}'),
          StackTrace.current,
        );
      }
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  /// ✅ Create a new sale document
  Future<void> createSaleDocument({
    required String documentName,
    required int saleId,
    BuildContext? context,
  }) async {
    try {
      final requestData = {
        "sale": saleId,
        "document_name": documentName,
        // no file included
      };

      final response = await ApiServices.post(
        CrmFliperUrls.fetchSaleDocument,
        data: requestData,
        hasToken: true,
      );

      if (response != null && response.statusCode == 201) {
        debugPrint('✅ Sale document created successfully');
        final created = FliperSaleDocument.fromJson(response.data);

        final currentState = state;
        if (currentState is AsyncData<SaleDocumentResponse>) {
          final updatedList = [created, ...currentState.value.results];

          state = AsyncData(
            SaleDocumentResponse(
              count: currentState.value.count + 1,
              next: currentState.value.next,
              previous: currentState.value.previous,
              results: updatedList,
            ),
          );
        } else {
          state = AsyncData(
            SaleDocumentResponse(
              count: 1,
              next: null,
              previous: null,
              results: [created],
            ),
          );
        }
      } else {
        debugPrint('❌ Failed to create sale document: ${response?.statusCode}');
        final errorData = response?.data;

        if (errorData is Map<String, dynamic>) {
          debugPrint('❗ Validation errors:');
          errorData.forEach((field, value) {
            if (value is List) {
              for (final msg in value) {
                debugPrint('• $field: $msg');
                if (context != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$field: $msg')));
                }
              }
            } else {
              debugPrint('• $field: $value');
              if (context != null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$field: $value')));
              }
            }
          });
        } else {
          debugPrint('⚠️ Unexpected error body: ${response?.data}');
          if (context != null) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unexpected error occurred')));
          }
        }

        state = AsyncError(
          Exception('Validation error while creating sale document'),
          StackTrace.current,
        );
      }
    } catch (e, stack) {
      debugPrint('❌ Exception: $e');
      state = AsyncError(e, stack);
    }
  }



  Future<FliperSaleDocument?> fetchSingleSaleDocument(String id) async {
    try {
      final response = await ApiServices.get(
        CrmFliperUrls.fetchSingleSaleDocument(id),
        ref: ref,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        final json = response.data;
        final document = FliperSaleDocument.fromJson(json);
        return document;
      } else {
        debugPrint('Failed to fetch sale document: ${response?.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching sale document: $e');
      return null;
    }
  }

  Future<FliperSaleDocument?> editSaleDocument({
    required String id,
    required int sale,
    required String documentName,
  }) async {
    try {
      final requestData = {"sale": sale, "document_name": documentName};

      final response = await ApiServices.put(
        CrmFliperUrls.fetchSingleSaleDocument(id),
        data: requestData,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        final json = response.data;
        final updated = FliperSaleDocument.fromJson(json);

        final currentState = state;
        if (currentState is AsyncData<SaleDocumentResponse>) {
          final updatedList =
              currentState.value.results.map((item) {
                return item.id.toString() == id ? updated : item;
              }).toList();

          final updatedResponse = SaleDocumentResponse(
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
          Exception('Failed to update sale document: ${response?.statusCode}'),
          StackTrace.current,
        );
        return null;
      }
    } catch (e, stack) {
      state = AsyncError(e, stack);
      return null;
    }
  }

  Future<bool> deleteSaleDocument(String id) async {
    try {
      final response = await ApiServices.delete(
        CrmFliperUrls.fetchSingleSaleDocument(id),
        hasToken: true,
      );

      if (response != null && response.statusCode == 204) {
        final currentState = state;
        if (currentState is AsyncData<SaleDocumentResponse>) {
          final updatedList =
              currentState.value.results
                  .where((item) => item.id.toString() != id)
                  .toList();

          final updatedResponse = SaleDocumentResponse(
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
          Exception('Failed to delete sale document: ${response?.statusCode}'),
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
