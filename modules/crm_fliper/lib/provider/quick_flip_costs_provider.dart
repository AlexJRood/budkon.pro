import 'package:flutter/foundation.dart';
import 'package:crm_fliper/crm_fliper_urls.dart';
import 'package:crm_fliper/models/fliper_quick_flip_cost_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';

final quickFlipCostsProvider = StateNotifierProvider<
  QuickFlipCostsNotifier,
  AsyncValue<QuickFlipCostsResponse>
>((ref) => QuickFlipCostsNotifier(ref));

class QuickFlipCostsNotifier
    extends StateNotifier<AsyncValue<QuickFlipCostsResponse>> {
  final Ref ref;

  QuickFlipCostsNotifier(this.ref) : super(const AsyncLoading()) {
    fetchQuickFlipCosts();
  }

  Future<void> fetchQuickFlipCosts() async {
    try {
      final response = await ApiServices.get(
        CrmFliperUrls.fetchQuickFlipCosts,
        ref: ref,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        debugPrint('✅ Quick flip costs loaded successfully');
        final json = response.data;
        final parsed = QuickFlipCostsResponse.fromJson(json);
        state = AsyncData(parsed);
      } else {
        state = AsyncError(
          Exception(
            'Failed to fetch quick flip costs: ${response?.statusCode}',
          ),
          StackTrace.current,
        );
      }
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  Future<void> createQuickFlipCost({
    String? painting,
    String? cleaning,
    String? clearing,
    String? listingPreparation,
    String? photoSession,
    String? homeStaging,
    dynamic other,
    required String summary,
    int? transaction,
    int? renovation,
    required int user,
    BuildContext? context, // optional for showing SnackBar
  }) async {
    try {
      final requestData = {
        "painting": painting,
        "cleaning": cleaning,
        "clearing": clearing,
        "listing_preparation": listingPreparation,
        "photo_session": photoSession,
        "homestaging": homeStaging,
        "other": other,
        "summary": summary,
        "transaction": transaction,
        "renovation": renovation,
        "user": user,
      };

      final response = await ApiServices.post(
        CrmFliperUrls.fetchQuickFlipCosts,
        data: requestData,
        hasToken: true,
      );

      if (response != null && response.statusCode == 201) {
        debugPrint('✅ Quick flip costs created successfully');

        final created = FliperQuickFlipCost.fromJson(response.data);

        final currentState = state;
        if (currentState is AsyncData<QuickFlipCostsResponse>) {
          final updatedList = [created, ...currentState.value.results];
          state = AsyncData(
            QuickFlipCostsResponse(
              count: currentState.value.count + 1,
              next: currentState.value.next,
              previous: currentState.value.previous,
              results: updatedList,
            ),
          );
        } else {
          state = AsyncData(
            QuickFlipCostsResponse(
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
          debugPrint('⚠️ Unexpected error body: ${response?.data}');
          if (context != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Unexpected error occurred')),
            );
          }
        }

        state = AsyncError(
          Exception('Failed to create quick flip cost'),
          StackTrace.current,
        );
      }
    } catch (e, stack) {
      debugPrint('❌ Exception: $e');
      state = AsyncError(e, stack);
    }
  }

  Future<FliperQuickFlipCost?> fetchSingleQuickFlipCost(String id) async {
    try {
      final response = await ApiServices.get(
        CrmFliperUrls.fetchSingleQuickFlipCosts(id),
        ref: ref,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        final json = response.data;
        final quickFlipCost = FliperQuickFlipCost.fromJson(json);
        return quickFlipCost;
      } else {
        debugPrint('Failed to fetch quick flip cost: ${response?.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching quick flip cost: $e');
      return null;
    }
  }

  Future<FliperQuickFlipCost?> editQuickFlipCost({
    required String id,
    String? painting,
    String? cleaning,
    String? clearing,
    String? listingPreparation,
    String? photoSession,
    String? homestaging,
    dynamic other, // Replace with proper model if needed
    required String summary,
    int? transaction,
    int? renovation,
    required int user,
  }) async {
    try {
      final requestData = {
        "painting": painting,
        "cleaning": cleaning,
        "clearing": clearing,
        "listing_preparation": listingPreparation,
        "photo_session": photoSession,
        "homestaging": homestaging,
        "other": other,
        "summary": summary,
        "transaction": transaction,
        "renovation": renovation,
        "user": user,
      };

      final response = await ApiServices.put(
        CrmFliperUrls.fetchSingleQuickFlipCosts(id),
        data: requestData,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        final json = response.data;
        final updated = FliperQuickFlipCost.fromJson(json);

        final currentState = state;
        if (currentState is AsyncData<QuickFlipCostsResponse>) {
          final updatedList =
              currentState.value.results.map((item) {
                return item.id == updated.id ? updated : item;
              }).toList();

          final updatedResponse = QuickFlipCostsResponse(
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
            'Failed to update quick flip cost: ${response?.statusCode}',
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

  Future<bool> deleteQuickFlipCost(String id) async {
    try {
      final response = await ApiServices.delete(
        CrmFliperUrls.fetchSingleQuickFlipCosts(id),
        hasToken: true,
      );

      if (response != null && response.statusCode == 204) {
        // Update local state by removing the deleted item
        final currentState = state;
        if (currentState is AsyncData<QuickFlipCostsResponse>) {
          final updatedList =
              currentState.value.results
                  .where((item) => item.id.toString() != id)
                  .toList();

          final updatedResponse = QuickFlipCostsResponse(
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
            'Failed to delete quick flip cost: ${response?.statusCode}',
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
