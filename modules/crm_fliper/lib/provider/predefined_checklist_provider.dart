import 'package:flutter/foundation.dart';
import 'package:crm_fliper/crm_fliper_urls.dart';
import 'package:crm_fliper/models/predefined_fliper_checklist_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';

final predefinedChecklistProvider = StateNotifierProvider<
  PredefinedChecklistNotifier,
  AsyncValue<PredefinedChecklistResponse>
>((ref) => PredefinedChecklistNotifier(ref));

class PredefinedChecklistNotifier
    extends StateNotifier<AsyncValue<PredefinedChecklistResponse>> {
  final Ref ref;

  PredefinedChecklistNotifier(this.ref) : super(const AsyncLoading()) {
    fetchPredefinedChecklist();
  }

  Future<void> fetchPredefinedChecklist() async {
    try {
      final response = await ApiServices.get(
        CrmFliperUrls.fetchPredefinedChecklist,
        ref: ref,
        hasToken: true
      );
      if (response != null && response.statusCode == 200) {
        debugPrint('✅ Predefine checklist loaded successfully');
        final json = response.data;
        final parsed = PredefinedChecklistResponse.fromJson(json);
        state = AsyncData(parsed);
      } else {
        state = AsyncError(
          Exception('Failed to fetch checklist: ${response?.statusCode}'),
          StackTrace.current,
        );
      }
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  Future<void> createPredefinedChecklist({
    required String title,
    required String description,
    dynamic checklist,
    required int user,
  }) async {
    try {
      final requestData = {
        "title": title,
        "description": description,
        "checklist": checklist,
        "user": user,
      };

      final response = await ApiServices.post(
        CrmFliperUrls.fetchPredefinedChecklist,
        data: requestData,
        hasToken: true,
      );

      if (response != null && response.statusCode == 201) {
        debugPrint('Predefine checklist created successfully');
        final json = response.data;
        final created = PredefinedFliperCheckList.fromJson(json);

        final currentState = state;
        if (currentState is AsyncData<PredefinedChecklistResponse>) {
          final updatedList = [created, ...currentState.value.results];

          final updatedResponse = PredefinedChecklistResponse(
            count: currentState.value.count + 1,
            next: currentState.value.next,
            previous: currentState.value.previous,
            results: updatedList,
          );

          state = AsyncData(updatedResponse);
        } else {
          state = AsyncData(
            PredefinedChecklistResponse(
              count: 1,
              next: null,
              previous: null,
              results: [created],
            ),
          );
        }
      } else {
        state = AsyncError(
          Exception('Failed to create checklist: ${response?.statusCode}'),
          StackTrace.current,
        );
      }
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  Future<PredefinedFliperCheckList?> fetchSinglePredefinedChecklist(
    String id,
  ) async {
    try {
      final response = await ApiServices.get(
        CrmFliperUrls.fetchSinglePredefinedChecklist(id),
        ref: ref,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        final json = response.data;
        final checklist = PredefinedFliperCheckList.fromJson(json);
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

  Future<PredefinedFliperCheckList?> editPredefinedChecklist({
    required String id,
    required String title,
    required String description,
    dynamic checklist,
    required int user,
  }) async {
    try {
      final requestData = {
        "title": title,
        "description": description,
        "checklist": checklist,
        "user": user,
      };

      final response = await ApiServices.put(
        CrmFliperUrls.fetchSinglePredefinedChecklist(id),
        data: requestData,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        final json = response.data;
        final updated = PredefinedFliperCheckList.fromJson(json);

        final currentState = state;
        if (currentState is AsyncData<PredefinedChecklistResponse>) {
          final updatedList =
              currentState.value.results.map((item) {
                return item.id == updated.id ? updated : item;
              }).toList();

          final updatedResponse = PredefinedChecklistResponse(
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
          Exception('Failed to update checklist: ${response?.statusCode}'),
          StackTrace.current,
        );
        return null;
      }
    } catch (e, stack) {
      state = AsyncError(e, stack);
      return null;
    }
  }

  Future<void> deletePredefinedChecklist(String id) async {
    try {
      final response = await ApiServices.delete(
        CrmFliperUrls.fetchSinglePredefinedChecklist(id),
        hasToken: true,
      );

      if (response != null && response.statusCode == 204) {
        debugPrint('Predefined checklist deleted successfully');
      } else {
        debugPrint('Predefined checklist deletion failed');
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}
