import 'package:flutter/foundation.dart';
import 'package:crm_fliper/crm_fliper_urls.dart';
import 'package:crm_fliper/models/fliper_renovation_schedule_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';

final renovationSchedulesProvider = StateNotifierProvider<
  RenovationSchedulesNotifier,
  AsyncValue<RenovationSchedulesResponse>
>((ref) => RenovationSchedulesNotifier(ref));

class RenovationSchedulesNotifier
    extends StateNotifier<AsyncValue<RenovationSchedulesResponse>> {
  final Ref ref;

  RenovationSchedulesNotifier(this.ref) : super(const AsyncLoading()) {
    fetchRenovationSchedules();
  }

  /// ✅ Fetch all renovation schedules
  Future<void> fetchRenovationSchedules() async {
    try {
      final response = await ApiServices.get(
        CrmFliperUrls.fetchRenovationSchedules,
        ref: ref,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        debugPrint('✅ Renovation schedule loaded successfully');

        final json = response.data;
        final parsed = RenovationSchedulesResponse.fromJson(json);
        state = AsyncData(parsed);
      } else {
        state = AsyncError(
          Exception(
            'Failed to fetch renovation schedules: ${response?.statusCode}',
          ),
          StackTrace.current,
        );
      }
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  /// ✅ Create a new renovation schedule
  Future<void> createRenovationSchedule({
    String? task,
    String? deadline,
    String? responsiblePerson,
    String? budget,
    String? actualCost,
    int? transaction,
  }) async {
    try {
      final requestData = {
        "task": task,
        "deadline": deadline,
        "responsible_person": responsiblePerson,
        "budget": budget,
        "actual_cost": actualCost,
        "transaction": transaction,
      };

      final response = await ApiServices.post(
        CrmFliperUrls.fetchRenovationSchedules,
        data: requestData,
        hasToken: true,
      );

      if (response != null && response.statusCode == 201) {
        final json = response.data;
        final created = FlierRenovationSchedule.fromJson(json);

        final currentState = state;
        if (currentState is AsyncData<RenovationSchedulesResponse>) {
          final updatedList = [created, ...currentState.value.results];

          final updatedResponse = RenovationSchedulesResponse(
            count: currentState.value.count + 1,
            next: currentState.value.next,
            previous: currentState.value.previous,
            results: updatedList,
          );

          state = AsyncData(updatedResponse);
        } else {
          state = AsyncData(
            RenovationSchedulesResponse(
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
            'Failed to create renovation schedule: ${response?.statusCode}',
          ),
          StackTrace.current,
        );
      }
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  Future<FlierRenovationSchedule?> fetchSingleRenovationSchedule(
    String id,
  ) async {
    try {
      final response = await ApiServices.get(
        CrmFliperUrls.fetchSingleRenovationSchedules(id),
        ref: ref,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        final json = response.data;
        final schedule = FlierRenovationSchedule.fromJson(json);
        return schedule;
      } else {
        debugPrint('Failed to fetch renovation schedule: ${response?.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching renovation schedule: $e');
      return null;
    }
  }

  /// ✅ Edit a renovation schedule
  Future<FlierRenovationSchedule?> editRenovationSchedule({
    required String id,
    String? task,
    String? deadline,
    String? responsiblePerson,
    String? budget,
    String? actualCost,
    int? transaction,
  }) async {
    try {
      final requestData = {
        "task": task,
        "deadline": deadline,
        "responsible_person": responsiblePerson,
        "budget": budget,
        "actual_cost": actualCost,
        "transaction": transaction,
      };

      final response = await ApiServices.put(
        CrmFliperUrls.fetchSingleRenovationSchedules(id),
        data: requestData,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        final json = response.data;
        final updated = FlierRenovationSchedule.fromJson(json);

        final currentState = state;
        if (currentState is AsyncData<RenovationSchedulesResponse>) {
          final updatedList =
              currentState.value.results.map((item) {
                return item.id.toString() == id ? updated : item;
              }).toList();

          final updatedResponse = RenovationSchedulesResponse(
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
            'Failed to update renovation schedule: ${response?.statusCode}',
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

  /// ✅ Delete a renovation schedule
  Future<bool> deleteRenovationSchedule(String id) async {
    try {
      final response = await ApiServices.delete(
        CrmFliperUrls.fetchSingleRenovationSchedules(id),
        hasToken: true,
      );

      if (response != null && response.statusCode == 204) {
        final currentState = state;
        if (currentState is AsyncData<RenovationSchedulesResponse>) {
          final updatedList =
              currentState.value.results
                  .where((item) => item.id.toString() != id)
                  .toList();

          final updatedResponse = RenovationSchedulesResponse(
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
            'Failed to delete renovation schedule: ${response?.statusCode}',
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
