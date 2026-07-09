import 'package:flutter/foundation.dart';
import 'package:crm_fliper/crm_fliper_urls.dart';
import 'package:crm_fliper/models/fliper_negotiation_history_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';


final negotiationHistoryProvider = StateNotifierProvider<
  NegotiationHistoryNotifier,
  AsyncValue<NegotiationHistoryResponse>
>((ref) => NegotiationHistoryNotifier(ref));

class NegotiationHistoryNotifier
    extends StateNotifier<AsyncValue<NegotiationHistoryResponse>> {
  final Ref ref;

  NegotiationHistoryNotifier(this.ref) : super(const AsyncLoading()) {
    fetchNegotiationHistory();
  }

  Future<void> fetchNegotiationHistory() async {
    try {
      final response = await ApiServices.get(
        CrmFliperUrls.fetchNegotiationHistory,
        ref: ref,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        debugPrint('✅ Negotiation history loaded Successfully');
        final json =
            response
                .data; // Assuming `ApiServices.get` returns a response with `.data`
        final parsed = NegotiationHistoryResponse.fromJson(json);
        state = AsyncData(parsed);
      } else {
        state = AsyncError(
          Exception('Failed to fetch data: ${response?.statusCode}'),
          StackTrace.current,
        );
      }
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  Future<void> createNegotiationHistory(
      FliperNegotiationHistory requestData,
      BuildContext context,
      ) async {
    try {
      final response = await ApiServices.post(
        CrmFliperUrls.createNegotiationHistory,
        data: requestData.toJson(), // ensure this is converted properly
        hasToken: true,
      );

      if (response != null && response.statusCode == 201) {
        debugPrint('Negotiation history added successfully');
        final json = response.data;
        final created = FliperNegotiationHistory.fromJson(json);

        final currentState = state;
        if (currentState is AsyncData<NegotiationHistoryResponse>) {
          final updatedList = [created, ...currentState.value.results];

          final updatedResponse = NegotiationHistoryResponse(
            count: currentState.value.count + 1,
            next: currentState.value.next,
            previous: currentState.value.previous,
            results: updatedList,
          );

          state = AsyncData(updatedResponse);
        } else {
          state = AsyncData(
            NegotiationHistoryResponse(
              count: 1,
              next: null,
              previous: null,
              results: [created],
            ),
          );
        }
      } else {
        final errors = response?.data;
        if (errors is Map<String, dynamic>) {
          debugPrint('❗ Validation errors:');
          errors.forEach((field, value) {
            final msg = value is List ? value.join(', ') : value.toString();
            debugPrint('• $field: $msg');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('• $field: $msg')),
            );
          });
        }
        state = AsyncError(
          Exception('Failed to create entry: ${response?.statusCode}'),
          StackTrace.current,
        );
      }
    } catch (e, stack) {
      debugPrint('❌ Exception in createNegotiationHistory: $e');
      state = AsyncError(e, stack);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unexpected error: $e')),
      );
    }
  }


  Future<FliperNegotiationHistory?> fetchSingleNegotiationHistory(
    String id,
  ) async {
    try {
      final response = await ApiServices.get(
        CrmFliperUrls.fetchSingleNegotiationHistory(id),
        ref: ref,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        final json = response.data;
        final history = FliperNegotiationHistory.fromJson(json);
        return history;
      } else {
        debugPrint(
          'Failed to fetch single negotiation history: ${response?.statusCode}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching single negotiation history: $e');
      return null;
    }
  }

  Future<void> editNegotiationHistory({
    required String id,
    required String initialPrice,
    required int transaction,
    String? sellerOffer,
    String? viewerOffer,
    String? renegotiationPrice,
    bool accepted = false,
  }) async {
    try {
      final requestData = {
        "initial_price": initialPrice,
        "transaction": transaction,
        "seller_offer": sellerOffer,
        "viewer_offer": viewerOffer,
        "renegotiation_price": renegotiationPrice,
        "accepted": accepted,
      };

      final response = await ApiServices.put(
        CrmFliperUrls.fetchSingleNegotiationHistory(id),
        data: requestData,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        final json = response.data;
        final updated = FliperNegotiationHistory.fromJson(json);

        final currentState = state;
        if (currentState is AsyncData<NegotiationHistoryResponse>) {
          final updatedList =
              currentState.value.results.map((item) {
                return item.id == updated.id ? updated : item;
              }).toList();

          final updatedResponse = NegotiationHistoryResponse(
            count: currentState.value.count,
            next: currentState.value.next,
            previous: currentState.value.previous,
            results: updatedList,
          );

          state = AsyncData(updatedResponse);
        }
      } else {
        state = AsyncError(
          Exception('Failed to update entry: ${response?.statusCode}'),
          StackTrace.current,
        );
      }
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  Future<void> deleteNegotiationHistory(String id) async {
    try {
      final response = await ApiServices.delete(
        CrmFliperUrls.fetchSingleNegotiationHistory(id),
        hasToken: true,
      );
      if (response != null && response.statusCode == 204) {
        debugPrint('Negotiation history deleted successfully');
      } else {
        debugPrint('Negotiation history deletion failed');
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}
