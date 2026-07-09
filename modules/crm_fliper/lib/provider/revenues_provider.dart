import 'package:flutter/foundation.dart';
import 'package:crm_fliper/crm_fliper_urls.dart';
import 'package:crm_fliper/models/fliper_revenue_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';

final revenuesProvider =
    StateNotifierProvider<RevenuesNotifier, AsyncValue<RevenuesResponse>>(
      (ref) => RevenuesNotifier(ref),
    );

class RevenuesNotifier extends StateNotifier<AsyncValue<RevenuesResponse>> {
  final Ref ref;

  RevenuesNotifier(this.ref) : super(const AsyncLoading()) {
    fetchRevenues();
  }

  Future<void> fetchRevenues() async {
    try {
      final response = await ApiServices.get(
        CrmFliperUrls.fetchRevenues,
        ref: ref,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        debugPrint('✅ Revenues loaded successfully');
        final json = response.data;
        final parsed = RevenuesResponse.fromJson(json);
        state = AsyncData(parsed);
      } else {
        state = AsyncError(
          Exception('Failed to fetch revenues: ${response?.statusCode}'),
          StackTrace.current,
        );
      }
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  Future<void> createRevenue({
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
        "created_by": createdBy,
      };

      final response = await ApiServices.post(
        CrmFliperUrls.fetchRevenues,
        data: requestData,
        hasToken: true,
      );

      if (response != null && response.statusCode == 201) {
        debugPrint('Revenues added successfully');
        final json = response.data;
        final created = FliperRevenue.fromJson(json);

        final currentState = state;
        if (currentState is AsyncData<RevenuesResponse>) {
          final updatedList = [created, ...currentState.value.results];

          state = AsyncData(
            RevenuesResponse(
              count: currentState.value.count + 1,
              next: currentState.value.next,
              previous: currentState.value.previous,
              results: updatedList,
            ),
          );
        } else {
          state = AsyncData(
            RevenuesResponse(
              count: 1,
              next: null,
              previous: null,
              results: [created],
            ),
          );
        }
      } else {
        debugPrint('❌ Failed to create revenue: ${response?.statusCode}');
        final errorData = response?.data;

        if (errorData is Map<String, dynamic>) {
          debugPrint('❗ Validation errors:');
          errorData.forEach((field, value) {
            if (value is List) {
              for (var msg in value) {
                debugPrint('• $field: $msg');
              }
            } else {
              debugPrint('• $field: $value');
            }
          });
        } else {
          debugPrint('⚠️ Unexpected error body: ${response?.data}');
        }

        state = AsyncError(
          Exception('Validation error while creating revenue'),
          StackTrace.current,
        );
      }
    } catch (e, stack) {
      debugPrint('❌ Exception: $e');
      state = AsyncError(e, stack);
    }
  }


  Future<FliperRevenue?> fetchSingleRevenue(String id) async {
    try {
      final response = await ApiServices.get(
        CrmFliperUrls.fetchSingleRevenues(id),
        ref: ref,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        final json = response.data;
        final revenue = FliperRevenue.fromJson(json);
        return revenue;
      } else {
        debugPrint('Failed to fetch revenue: ${response?.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching revenue: $e');
      return null;
    }
  }

  Future<FliperRevenue?> editRevenue({
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
        "created_by": createdBy,
      };

      final response = await ApiServices.put(
        CrmFliperUrls.fetchSingleRevenues(id),
        data: requestData,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        final json = response.data;
        final updated = FliperRevenue.fromJson(json);

        final currentState = state;
        if (currentState is AsyncData<RevenuesResponse>) {
          final updatedList =
              currentState.value.results.map((item) {
                return item.id.toString() == id ? updated : item;
              }).toList();

          final updatedResponse = RevenuesResponse(
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
          Exception('Failed to update revenue: ${response?.statusCode}'),
          StackTrace.current,
        );
        return null;
      }
    } catch (e, stack) {
      state = AsyncError(e, stack);
      return null;
    }
  }

  Future<bool> deleteRevenue(String id) async {
    try {
      final response = await ApiServices.delete(
        CrmFliperUrls.fetchSingleRevenues(id),
        hasToken: true,
      );

      if (response != null && response.statusCode == 204) {
        final currentState = state;
        if (currentState is AsyncData<RevenuesResponse>) {
          final updatedList =
              currentState.value.results
                  .where((item) => item.id.toString() != id)
                  .toList();

          final updatedResponse = RevenuesResponse(
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
          Exception('Failed to delete revenue: ${response?.statusCode}'),
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
