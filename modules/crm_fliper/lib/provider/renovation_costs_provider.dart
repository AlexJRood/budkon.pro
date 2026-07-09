import 'package:flutter/foundation.dart';
import 'package:crm_fliper/crm_fliper_urls.dart';
import 'package:crm_fliper/models/fliper_renovation_cost_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';

final renovationCostsProvider = StateNotifierProvider<
  RenovationCostsNotifier,
  AsyncValue<RenovationCostsResponse>
>((ref) => RenovationCostsNotifier(ref));

class RenovationCostsNotifier
    extends StateNotifier<AsyncValue<RenovationCostsResponse>> {
  final Ref ref;

  RenovationCostsNotifier(this.ref) : super(const AsyncLoading()) {
    fetchRenovationCosts();
  }

  Future<void> fetchRenovationCosts() async {
    try {
      final response = await ApiServices.get(
        CrmFliperUrls.fetchRenovationCosts,
        ref: ref,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        debugPrint('✅ Renovation costs loaded successfully');
        final json = response.data;
        final parsed = RenovationCostsResponse.fromJson(json);
        state = AsyncData(parsed);
      } else {
        state = AsyncError(
          Exception(
            'Failed to fetch renovation costs: ${response?.statusCode}',
          ),
          StackTrace.current,
        );
      }
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  Future<void> createRenovationCost({
    required dynamic renovationCosts, // Replace with a proper model if available
    required String renovationSummary,
    int? transaction,
    required int user,
    BuildContext? context, // Optional for SnackBar
  }) async {
    try {
      final requestData = {
        "renovation_costs": renovationCosts,
        "renovation_summary": renovationSummary,
        "transaction": transaction,
        "user": user,
      };

      final response = await ApiServices.post(
        CrmFliperUrls.fetchRenovationCosts,
        data: requestData,
        hasToken: true,
      );

      if (response != null && response.statusCode == 201) {
        debugPrint('✅ Renovation costs created successfully');
        final created = FliperRenovationCost.fromJson(response.data);

        final currentState = state;
        if (currentState is AsyncData<RenovationCostsResponse>) {
          final updatedList = [created, ...currentState.value.results];
          state = AsyncData(
            RenovationCostsResponse(
              count: currentState.value.count + 1,
              next: currentState.value.next,
              previous: currentState.value.previous,
              results: updatedList,
            ),
          );
        } else {
          state = AsyncData(
            RenovationCostsResponse(
              count: 1,
              next: null,
              previous: null,
              results: [created],
            ),
          );
        }
      } else {
        debugPrint('❌ Failed with status: ${response?.statusCode}');
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
          debugPrint('⚠️ Unexpected error: ${response?.data}');
          if (context != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Unexpected error occurred.')),
            );
          }
        }

        state = AsyncError(
          Exception('Failed to create renovation cost.'),
          StackTrace.current,
        );
      }
    } catch (e, stack) {
      debugPrint('❌ Exception in createRenovationCost: $e');
      state = AsyncError(e, stack);
    }
  }


  Future<FliperRenovationCost?> fetchSingleRenovationCosts(String id) async {
    try {
      final response = await ApiServices.get(
        CrmFliperUrls.fetchSingleRenovationCosts(id),
        ref: ref,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        final json = response.data;
        final renovationCost = FliperRenovationCost.fromJson(json);
        return renovationCost;
      } else {
        debugPrint('Failed to fetch renovation cost: ${response?.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching renovation cost: $e');
      return null;
    }
  }

  Future<FliperRenovationCost?> editRenovationCost({
    required String id,
    required dynamic renovationCosts,
    required String renovationSummary,
    int? transaction,
    required int user,
  }) async {
    try {
      final requestData = {
        "renovation_costs": renovationCosts,
        "renovation_summary": renovationSummary,
        "transaction": transaction,
        "user": user,
      };

      final response = await ApiServices.put(
        CrmFliperUrls.fetchSingleRenovationCosts(id),
        data: requestData,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        final json = response.data;
        final updated = FliperRenovationCost.fromJson(json);

        final currentState = state;
        if (currentState is AsyncData<RenovationCostsResponse>) {
          final updatedList =
              currentState.value.results.map((item) {
                return item.id.toString() == id ? updated : item;
              }).toList();

          final updatedResponse = RenovationCostsResponse(
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
            'Failed to update renovation cost: ${response?.statusCode}',
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

  Future<bool> deleteRenovationCost(String id) async {
    try {
      final response = await ApiServices.delete(
        CrmFliperUrls.fetchSingleRenovationCosts(id),
        hasToken: true,
      );

      if (response != null && response.statusCode == 204) {
        final currentState = state;
        if (currentState is AsyncData<RenovationCostsResponse>) {
          final updatedList =
              currentState.value.results
                  .where((item) => item.id.toString() != id)
                  .toList();

          final updatedResponse = RenovationCostsResponse(
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
            'Failed to delete renovation cost: ${response?.statusCode}',
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
