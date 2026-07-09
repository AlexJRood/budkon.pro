import 'package:flutter/foundation.dart';
import 'package:crm_fliper/crm_fliper_urls.dart';
import 'package:crm_fliper/models/fliper_sale_client_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';

final saleClientsProvider =
    StateNotifierProvider<SaleClientsNotifier, AsyncValue<SaleClientsResponse>>(
      (ref) => SaleClientsNotifier(ref),
    );

class SaleClientsNotifier
    extends StateNotifier<AsyncValue<SaleClientsResponse>> {
  final Ref ref;

  SaleClientsNotifier(this.ref) : super(const AsyncLoading()) {
    fetchSaleClients();
  }

  Future<void> fetchSaleClients() async {
    try {
      final response = await ApiServices.get(
        CrmFliperUrls.fetchSaleClients,
        ref: ref,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        debugPrint('✅ Sale clients loaded successfully');
        final data = SaleClientsResponse.fromJson(response.data);
        state = AsyncData(data);
      } else {
        state = AsyncError(
          Exception('Failed to fetch sale clients: ${response?.statusCode}'),
          StackTrace.current,
        );
      }
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  Future<void> createSaleClient({
    int? user,
    required String fullName,
    required String email,
    String? phoneNumber,
    BuildContext? context, // Optional for showing snackbar
  }) async {
    try {
      final requestData = {
        "user": user,
        "full_name": fullName,
        "email": email,
        "phone_number": phoneNumber,
      };

      final response = await ApiServices.post(
        CrmFliperUrls.fetchSaleClients,
        data: requestData,
        hasToken: true,
      );

      if (response != null && response.statusCode == 201) {
        debugPrint('✅ Sale client added successfully');
        final json = response.data;
        final createdClient = FliperSaleClient.fromJson(json);

        final currentState = state;
        if (currentState is AsyncData<SaleClientsResponse>) {
          final updatedList = [createdClient, ...currentState.value.results];

          final updatedResponse = SaleClientsResponse(
            count: currentState.value.count + 1,
            next: currentState.value.next,
            previous: currentState.value.previous,
            results: updatedList,
          );

          state = AsyncData(updatedResponse);
        } else {
          state = AsyncData(
            SaleClientsResponse(
              count: 1,
              next: null,
              previous: null,
              results: [createdClient],
            ),
          );
        }
      } else {
        debugPrint('❌ Failed to create sale client: ${response?.statusCode}');
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
          Exception('Validation error while creating sale client'),
          StackTrace.current,
        );
      }
    } catch (e, stack) {
      debugPrint('❌ Exception: $e');
      state = AsyncError(e, stack);
    }
  }


  Future<FliperSaleClient?> fetchSingleSaleClient(String id) async {
    try {
      final response = await ApiServices.get(
        CrmFliperUrls.fetchSingleSaleClients(id),
        ref: ref,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        final json = response.data;
        final client = FliperSaleClient.fromJson(json);
        return client;
      } else {
        debugPrint('Failed to fetch sale client: ${response?.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching sale client: $e');
      return null;
    }
  }

  Future<FliperSaleClient?> editSaleClient({
    required String id,
    int? user,
    required String fullName,
    required String email,
    String? phoneNumber,
  }) async {
    try {
      final requestData = {
        "user": user,
        "full_name": fullName,
        "email": email,
        "phone_number": phoneNumber,
      };

      final response = await ApiServices.put(
        CrmFliperUrls.fetchSingleSaleClients(id),
        data: requestData,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        final json = response.data;
        final updated = FliperSaleClient.fromJson(json);

        final currentState = state;
        if (currentState is AsyncData<SaleClientsResponse>) {
          final updatedList =
              currentState.value.results.map((item) {
                return item.id.toString() == id ? updated : item;
              }).toList();

          final updatedResponse = SaleClientsResponse(
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
          Exception('Failed to update sale client: ${response?.statusCode}'),
          StackTrace.current,
        );
        return null;
      }
    } catch (e, stack) {
      state = AsyncError(e, stack);
      return null;
    }
  }

  Future<bool> deleteSaleClient(String id) async {
    try {
      final response = await ApiServices.delete(
        CrmFliperUrls.fetchSingleSaleClients(id),
        hasToken: true,
      );

      if (response != null && response.statusCode == 204) {
        final currentState = state;
        if (currentState is AsyncData<SaleClientsResponse>) {
          final updatedList =
              currentState.value.results
                  .where((item) => item.id.toString() != id)
                  .toList();

          final updatedResponse = SaleClientsResponse(
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
          Exception('Failed to delete sale client: ${response?.statusCode}'),
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
