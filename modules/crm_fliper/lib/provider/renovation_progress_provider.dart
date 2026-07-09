import 'package:flutter/foundation.dart';
import 'package:crm_fliper/crm_fliper_urls.dart';
import 'package:crm_fliper/models/fliper_renovation_progress_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';

final renovationProgressProvider = StateNotifierProvider<
  RenovationProgressNotifier,
  AsyncValue<RenovationProgressResponse>
>((ref) => RenovationProgressNotifier(ref));

class RenovationProgressNotifier
    extends StateNotifier<AsyncValue<RenovationProgressResponse>> {
  final Ref ref;

  RenovationProgressNotifier(this.ref) : super(const AsyncLoading()) {
    fetchRenovationProgress();
  }

  /// ✅ Fetch all renovation progress items
  Future<void> fetchRenovationProgress() async {
    try {
      final response = await ApiServices.get(
        CrmFliperUrls.fetchRenovationProgress,
        ref: ref,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        debugPrint('✅ Renovation progress loaded successfully');
        final json = response.data;
        final parsed = RenovationProgressResponse.fromJson(json);
        state = AsyncData(parsed);
      } else {
        state = AsyncError(
          Exception(
            'Failed to fetch renovation progress: ${response?.statusCode}',
          ),
          StackTrace.current,
        );
      }
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  /// ✅ Create a new renovation progress item
  Future<void> createRenovationProgress({
    required int task,
    String? plannedStartDate,
    String? plannedEndDate,
    String? actualStartDate,
    String? actualEndDate,
    required String status,
    BuildContext? context, // <-- optional for SnackBar display
  }) async {
    try {
      final requestData = {
        "task": task,
        "planned_start_date": plannedStartDate,
        "planned_end_date": plannedEndDate,
        "actual_start_date": actualStartDate,
        "actual_end_date": actualEndDate,
        "status": status,
      };

      final response = await ApiServices.post(
        CrmFliperUrls.fetchRenovationProgress,
        data: requestData,
        hasToken: true,
      );

      if (response != null && response.statusCode == 201) {
        debugPrint('✅ Renovation progress created successfully');

        final created = FliperRenovationProgress.fromJson(response.data);

        final currentState = state;
        if (currentState is AsyncData<RenovationProgressResponse>) {
          final updatedList = [created, ...currentState.value.results];

          state = AsyncData(
            RenovationProgressResponse(
              count: currentState.value.count + 1,
              next: currentState.value.next,
              previous: currentState.value.previous,
              results: updatedList,
            ),
          );
        } else {
          state = AsyncData(
            RenovationProgressResponse(
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
          Exception('Failed to create renovation progress'),
          StackTrace.current,
        );
      }
    } catch (e, stack) {
      debugPrint('❌ Exception in createRenovationProgress: $e');
      state = AsyncError(e, stack);
    }
  }


  Future<FliperRenovationProgress?> fetchSingleRenovationProgress(
    String id,
  ) async {
    try {
      final response = await ApiServices.get(
        CrmFliperUrls.fetchSingleRenovationProgress(id),
        ref: ref,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        final json = response.data;
        final progress = FliperRenovationProgress.fromJson(json);
        return progress;
      } else {
        debugPrint('Failed to fetch renovation progress: ${response?.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching renovation progress: $e');
      return null;
    }
  }

  Future<FliperRenovationProgress?> editRenovationProgress({
    required String id,
    required int task,
    String? plannedStartDate,
    String? plannedEndDate,
    String? actualStartDate,
    String? actualEndDate,
    required String status,
  }) async {
    try {
      final requestData = {
        "task": task,
        "planned_start_date": plannedStartDate,
        "planned_end_date": plannedEndDate,
        "actual_start_date": actualStartDate,
        "actual_end_date": actualEndDate,
        "status": status,
      };

      final response = await ApiServices.put(
        CrmFliperUrls.fetchSingleRenovationProgress(id),
        data: requestData,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        final json = response.data;
        final updated = FliperRenovationProgress.fromJson(json);

        final currentState = state;
        if (currentState is AsyncData<RenovationProgressResponse>) {
          final updatedList =
              currentState.value.results.map((item) {
                return item.id.toString() == id ? updated : item;
              }).toList();

          final updatedResponse = RenovationProgressResponse(
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
            'Failed to update renovation progress: ${response?.statusCode}',
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

  Future<bool> deleteRenovationProgress(String id) async {
    try {
      final response = await ApiServices.delete(
        CrmFliperUrls.fetchSingleRenovationProgress(id),
        hasToken: true,
      );

      if (response != null && response.statusCode == 204) {
        final currentState = state;
        if (currentState is AsyncData<RenovationProgressResponse>) {
          final updatedList =
              currentState.value.results
                  .where((item) => item.id.toString() != id)
                  .toList();

          final updatedResponse = RenovationProgressResponse(
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
            'Failed to delete renovation progress: ${response?.statusCode}',
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
