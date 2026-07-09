import 'package:flutter/foundation.dart';
import 'package:crm_fliper/crm_fliper_urls.dart';
import 'package:crm_fliper/models/fliper_viewer_status_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';

final viewerStatusProvider = StateNotifierProvider<
  ViewerStatusNotifier,
  AsyncValue<ViewerStatusResponse>
>((ref) => ViewerStatusNotifier(ref));

class ViewerStatusNotifier
    extends StateNotifier<AsyncValue<ViewerStatusResponse>> {
  final Ref ref;

  ViewerStatusNotifier(this.ref) : super(const AsyncLoading()) {
    fetchViewerStatus();
  }

  /// ✅ Fetch viewer statuses
  Future<void> fetchViewerStatus() async {
    try {
      final response = await ApiServices.get(
        CrmFliperUrls.fetchViewerStatus,
        ref: ref,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        debugPrint('✅ Viewer status loaded successfully');
        final parsed = ViewerStatusResponse.fromJson(response.data);
        state = AsyncData(parsed);
      } else {
        state = AsyncError(
          Exception('Failed to fetch viewer status: ${response?.statusCode}'),
          StackTrace.current,
        );
      }
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  /// ✅ Create viewer status
  Future<void> createViewerStatus({
    required String statusName,
    required int statusIndex,
    dynamic transactionIndex,
    required bool isView,
    required bool isNegotiations,
    required bool isFinalization,
    required int user,
  }) async {
    try {
      final requestData = {
        "status_name": statusName,
        "status_index": statusIndex,
        "transaction_index": transactionIndex,
        "is_view": isView,
        "is_negotiations": isNegotiations,
        "is_finalization": isFinalization,
        "user": user,
      };

      final response = await ApiServices.post(
        CrmFliperUrls.fetchViewerStatus,
        data: requestData,
        hasToken: true,
      );

      if (response != null && response.statusCode == 201) {
        final created = FliperViewerStatus.fromJson(response.data);

        final currentState = state;
        if (currentState is AsyncData<ViewerStatusResponse>) {
          final updatedList = [created, ...currentState.value.results];

          final updatedResponse = ViewerStatusResponse(
            count: currentState.value.count + 1,
            next: currentState.value.next,
            previous: currentState.value.previous,
            results: updatedList,
          );

          state = AsyncData(updatedResponse);
        } else {
          state = AsyncData(
            ViewerStatusResponse(
              count: 1,
              next: null,
              previous: null,
              results: [created],
            ),
          );
        }
      } else {
        state = AsyncError(
          Exception('Failed to create viewer status: ${response?.statusCode}'),
          StackTrace.current,
        );
      }
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  Future<FliperViewerStatus?> fetchSingleViewerStatus(String id) async {
    try {
      final response = await ApiServices.get(
        CrmFliperUrls.fetchSingleViewerStatus(id),
        ref: ref,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        final data = response.data;
        final viewerStatus = FliperViewerStatus.fromJson(data);
        return viewerStatus;
      } else {
        debugPrint('Failed to fetch viewer status: ${response?.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching viewer status: $e');
      return null;
    }
  }

  Future<FliperViewerStatus?> editViewerStatus({
    required String id,
    required String statusName,
    required int statusIndex,
    dynamic transactionIndex,
    required bool isView,
    required bool isNegotiations,
    required bool isFinalization,
    required int user,
  }) async {
    try {
      final requestData = {
        "status_name": statusName,
        "status_index": statusIndex,
        "transaction_index": transactionIndex,
        "is_view": isView,
        "is_negotiations": isNegotiations,
        "is_finalization": isFinalization,
        "user": user,
      };

      final response = await ApiServices.put(
        CrmFliperUrls.fetchSingleViewerStatus(id),
        data: requestData,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        final updated = FliperViewerStatus.fromJson(response.data);

        final currentState = state;
        if (currentState is AsyncData<ViewerStatusResponse>) {
          final updatedList =
              currentState.value.results.map((item) {
                return item.id.toString() == id ? updated : item;
              }).toList();

          final updatedResponse = ViewerStatusResponse(
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
          Exception('Failed to update viewer status: ${response?.statusCode}'),
          StackTrace.current,
        );
        return null;
      }
    } catch (e, stack) {
      state = AsyncError(e, stack);
      return null;
    }
  }

  Future<bool> deleteViewerStatus(String id) async {
    try {
      final response = await ApiServices.delete(
        CrmFliperUrls.fetchSingleViewerStatus(id),
        hasToken: true,
      );

      if (response != null && response.statusCode == 204) {
        final currentState = state;
        if (currentState is AsyncData<ViewerStatusResponse>) {
          final updatedList =
              currentState.value.results
                  .where((item) => item.id.toString() != id)
                  .toList();

          final updatedResponse = ViewerStatusResponse(
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
          Exception('Failed to delete viewer status: ${response?.statusCode}'),
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
