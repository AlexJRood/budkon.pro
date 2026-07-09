import 'package:flutter/foundation.dart';
import 'package:crm_fliper/crm_fliper_urls.dart';
import 'package:crm_fliper/models/fliper_renovation_task_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';

final renovationTaskProvider = StateNotifierProvider<
  RenovationTaskNotifier,
  AsyncValue<RenovationTaskResponse>
>((ref) => RenovationTaskNotifier(ref));

class RenovationTaskNotifier
    extends StateNotifier<AsyncValue<RenovationTaskResponse>> {
  final Ref ref;

  RenovationTaskNotifier(this.ref) : super(const AsyncLoading()) {
    fetchRenovationTask();
  }

  Future<void> fetchRenovationTask() async {
    try {
      final response = await ApiServices.get(
        CrmFliperUrls.fetchRenovationTask,
        ref: ref,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        debugPrint('✅ Renovation task loaded successfully');
        final json = response.data;
        final parsed = RenovationTaskResponse.fromJson(json);
        state = AsyncData(parsed);
      } else {
        state = AsyncError(
          Exception(
            'Failed to fetch renovation tasks: ${response?.statusCode}',
          ),
          StackTrace.current,
        );
      }
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  Future<void> createRenovationTask({
    required int transaction,
    required String taskName,
    List<Map<String, String>>? budget,
    String? actualCost,
    BuildContext? context, // optional for SnackBar feedback
  }) async {
    try {
      final requestData = {
        "transaction": transaction,
        "task_name": taskName,
        "budget": budget,
        "actual_cost": actualCost,
      };

      final response = await ApiServices.post(
        CrmFliperUrls.fetchRenovationTask,
        data: requestData,
        hasToken: true,
      );

      if (response != null && response.statusCode == 201) {
        debugPrint('✅ Renovation task created successfully');

        final created = FliperRenovationTask.fromJson(response.data);

        final currentState = state;
        if (currentState is AsyncData<RenovationTaskResponse>) {
          final updatedList = [created, ...currentState.value.results];

          state = AsyncData(
            RenovationTaskResponse(
              count: currentState.value.count + 1,
              next: currentState.value.next,
              previous: currentState.value.previous,
              results: updatedList,
            ),
          );
        } else {
          state = AsyncData(
            RenovationTaskResponse(
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
          debugPrint('⚠️ Unexpected response body: ${response?.data}');
          if (context != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Unexpected error occurred')),
            );
          }
        }

        state = AsyncError(
          Exception('Failed to create renovation task'),
          StackTrace.current,
        );
      }
    } catch (e, stack) {
      debugPrint('❌ Exception in createRenovationTask: $e');
      state = AsyncError(e, stack);
    }
  }


  Future<FliperRenovationTask?> fetchSingleRenovationTask(String id) async {
    try {
      final response = await ApiServices.get(
        CrmFliperUrls.fetchSingleRenovationTask(id),
        ref: ref,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        final json = response.data;
        final task = FliperRenovationTask.fromJson(json);
        return task;
      } else {
        debugPrint('Failed to fetch renovation task: ${response?.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching renovation task: $e');
      return null;
    }
  }

  Future<FliperRenovationTask?> editRenovationTask({
    required String id,
    required int transaction,
    required String taskName,
    List<Map<String, String>>? budget,
    String? actualCost,
  }) async {
    try {
      final requestData = {
        "transaction": transaction,
        "task_name": taskName,
        "budget": budget,
        "actual_cost": actualCost,
      };

      final response = await ApiServices.put(
        CrmFliperUrls.fetchSingleRenovationTask(id),
        data: requestData,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        final json = response.data;
        final updated = FliperRenovationTask.fromJson(json);

        final currentState = state;
        if (currentState is AsyncData<RenovationTaskResponse>) {
          final updatedList =
              currentState.value.results.map((item) {
                return item.id.toString() == id ? updated : item;
              }).toList();

          final updatedResponse = RenovationTaskResponse(
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
            'Failed to update renovation task: ${response?.statusCode}',
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

  Future<bool> deleteRenovationTask(String id) async {
    try {
      final response = await ApiServices.delete(
        CrmFliperUrls.fetchSingleRenovationTask(id),
        hasToken: true,
      );

      if (response != null && response.statusCode == 204) {
        final currentState = state;
        if (currentState is AsyncData<RenovationTaskResponse>) {
          final updatedList =
              currentState.value.results
                  .where((item) => item.id.toString() != id)
                  .toList();

          final updatedResponse = RenovationTaskResponse(
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
            'Failed to delete renovation task: ${response?.statusCode}',
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
