import 'package:flutter/foundation.dart';
import 'package:crm_fliper/crm_fliper_urls.dart';
import 'package:crm_fliper/models/fliper_negotiation_status_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';

final negotiationStatusesProvider = StateNotifierProvider<
  NegotiationStatusesNotifier,
  AsyncValue<NegotiationStatusesResponse>
>((ref) => NegotiationStatusesNotifier(ref));

class NegotiationStatusesNotifier
    extends StateNotifier<AsyncValue<NegotiationStatusesResponse>> {
  final Ref ref;

  NegotiationStatusesNotifier(this.ref) : super(const AsyncLoading()) {
    fetchNegotiationStatuses();
  }

  Future<void> fetchNegotiationStatuses() async {
    try {
      final response = await ApiServices.get(
        CrmFliperUrls.fetchNegotiationStatuses,
        ref: ref,
        hasToken: true
      );
      if (response != null && response.statusCode == 200) {
        debugPrint('✅ Negotiation statuses loaded successfully');
        final json = response.data;
        final parsed = NegotiationStatusesResponse.fromJson(json);
        state = AsyncData(parsed);
      } else {
        state = AsyncError(
          Exception('Failed to load statuses: ${response?.statusCode}'),
          StackTrace.current,
        );
      }
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  Future<void> createNegotiationStatus({
    required String statusName,
    required int statusIndex,
    required List<int> transactionIndex, // Replace with proper model if needed
    bool isCalculations = false,
    bool isNegotiations = false,
    bool isFinalization = false,
    required int user,
  }) async {
    try {
      final requestData = {
        "status_name": statusName,
        "status_index": statusIndex,
        "transaction_index": transactionIndex,
        "is_calculations": isCalculations,
        "is_negotiations": isNegotiations,
        "is_finalization": isFinalization,
        "user": user,
      };

      final response = await ApiServices.post(
        CrmFliperUrls.fetchNegotiationStatuses,
        data: requestData,
        hasToken: true,
      );

      if (response != null && (response.statusCode == 201 || response.statusCode == 200)) {
        debugPrint('✅ Negotiation status created successfully.');
        final created = FliperNegotiationStatus.fromJson(response.data);

        final currentState = state;
        if (currentState is AsyncData<NegotiationStatusesResponse>) {
          final updatedList = [created, ...currentState.value.results];

          final updatedResponse = NegotiationStatusesResponse(
            count: currentState.value.count + 1,
            next: currentState.value.next,
            previous: currentState.value.previous,
            results: updatedList,
          );

          state = AsyncData(updatedResponse);
        } else {
          state = AsyncData(
            NegotiationStatusesResponse(
              count: 1,
              next: null,
              previous: null,
              results: [created],
            ),
          );
        }

      } else {
        debugPrint('❌ Failed to create status: ${response?.statusCode}');
        final errorData = response?.data;

        if (errorData is Map<String, dynamic>) {
          errorData.forEach((field, value) {
            if (value is List) {
              for (final msg in value) {
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
          Exception('Failed to create status'),
          StackTrace.current,
        );
      }
    } catch (e, stack) {
      debugPrint('❌ Exception: $e');
      state = AsyncError(e, stack);
    }
  }


  Future<FliperNegotiationStatus?> fetchSingleNegotiationStatuses(
    String id,
  ) async {
    try {
      final response = await ApiServices.get(
        CrmFliperUrls.fetchSingleNegotiationStatuses(id),
        ref: ref,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        final json = response.data;
        final status = FliperNegotiationStatus.fromJson(json);
        return status;
      } else {
        debugPrint(
          'Failed to fetch single negotiation status: ${response?.statusCode}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching single negotiation status: $e');
      return null;
    }
  }

  Future<FliperNegotiationStatus?> editNegotiationStatuses({
    required String id,
    required String statusName,
    required int statusIndex,
    dynamic transactionIndex, // Replace with a proper model if needed
    bool isCalculations = false,
    bool isNegotiations = false,
    bool isFinalization = false,
    required int user,
  }) async {
    try {
      final requestData = {
        "status_name": statusName,
        "status_index": statusIndex,
        "transaction_index": transactionIndex,
        "is_calculations": isCalculations,
        "is_negotiations": isNegotiations,
        "is_finalization": isFinalization,
        "user": user,
      };

      final response = await ApiServices.put(
        CrmFliperUrls.fetchSingleNegotiationStatuses(id),
        data: requestData,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        final json = response.data;
        final updatedStatus = FliperNegotiationStatus.fromJson(json);

        // Update current state if needed
        final currentState = state;
        if (currentState is AsyncData<NegotiationStatusesResponse>) {
          final updatedList =
              currentState.value.results.map((item) {
                return item.id == updatedStatus.id ? updatedStatus : item;
              }).toList();

          final updatedResponse = NegotiationStatusesResponse(
            count: currentState.value.count,
            next: currentState.value.next,
            previous: currentState.value.previous,
            results: updatedList,
          );

          state = AsyncData(updatedResponse);
        }

        return updatedStatus;
      } else {
        state = AsyncError(
          Exception('Failed to update status: ${response?.statusCode}'),
          StackTrace.current,
        );
        return null;
      }
    } catch (e, stack) {
      state = AsyncError(e, stack);
      return null;
    }
  }

  Future<void> deleteNegotiationStatuses(String id) async {
    try {
      final response = await ApiServices.delete(
        CrmFliperUrls.fetchSingleNegotiationStatuses(id),
        hasToken: true,
      );

      if (response != null && response.statusCode == 204) {
        debugPrint('Negotiation statuses deleted successfully');
      } else {
        debugPrint('Negotiation status deletion failed');
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}
