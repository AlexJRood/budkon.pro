import 'package:flutter/foundation.dart';
import 'package:crm_fliper/crm_fliper_urls.dart';
import 'package:crm_fliper/models/fliper_sale_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';

final salesProvider =
    StateNotifierProvider<SalesNotifier, AsyncValue<SalesResponse>>(
      (ref) => SalesNotifier(ref),
    );

class SalesNotifier extends StateNotifier<AsyncValue<SalesResponse>> {
  final Ref ref;

  SalesNotifier(this.ref) : super(const AsyncLoading()) {
    fetchSales();
  }

  Future<void> fetchSales() async {
    try {
      final response = await ApiServices.get(
        CrmFliperUrls.fetchSales,
        ref: ref,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        debugPrint('✅ Sales loaded successfully');
        final parsed = SalesResponse.fromJson(response.data);
        state = AsyncData(parsed);
      } else {
        state = AsyncError(
          Exception('Failed to fetch sales: ${response?.statusCode}'),
          StackTrace.current,
        );
      }
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  Future<void> createSale({
    required int transaction,
    required int agent,
    required int client,
    required String salePrice,
    String? profitPotential,
    required String status,
    String? saleDate,
  }) async {
    try {
      final requestData = {
        "transaction": transaction,
        "agent": agent,
        "client": client,
        "sale_price": salePrice,
        "profit_potential": profitPotential,
        "status": status,
        "sale_date": saleDate,
      };

      final response = await ApiServices.post(
        CrmFliperUrls.fetchSales,
        data: requestData,
        hasToken: true,
      );

      if (response != null && response.statusCode == 201) {
        final created = FliperSale.fromJson(response.data);

        final currentState = state;
        if (currentState is AsyncData<SalesResponse>) {
          final updatedList = [created, ...currentState.value.results];

          final updatedResponse = SalesResponse(
            count: currentState.value.count + 1,
            next: currentState.value.next,
            previous: currentState.value.previous,
            results: updatedList,
          );

          state = AsyncData(updatedResponse);
        } else {
          state = AsyncData(
            SalesResponse(
              count: 1,
              next: null,
              previous: null,
              results: [created],
            ),
          );
        }
      } else {
        state = AsyncError(
          Exception('Failed to create sale: ${response?.statusCode}'),
          StackTrace.current,
        );
      }
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  Future<FliperSale?> fetchSingleSale(String id) async {
    try {
      final response = await ApiServices.get(
        CrmFliperUrls.fetchSingleSales(id),
        ref: ref,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        final json = response.data;
        final sale = FliperSale.fromJson(json);
        return sale;
      } else {
        debugPrint('Failed to fetch sale: ${response?.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching sale: $e');
      return null;
    }
  }

  Future<FliperSale?> editSale({
    required String id,
    required int transaction,
    required int agent,
    required int client,
    required String salePrice,
    String? profitPotential,
    required String status,
    String? saleDate,
  }) async {
    try {
      final requestData = {
        "transaction": transaction,
        "agent": agent,
        "client": client,
        "sale_price": salePrice,
        "profit_potential": profitPotential,
        "status": status,
        "sale_date": saleDate,
      };

      final response = await ApiServices.put(
        CrmFliperUrls.fetchSingleSales(id),
        data: requestData,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        final updated = FliperSale.fromJson(response.data);

        final currentState = state;
        if (currentState is AsyncData<SalesResponse>) {
          final updatedList =
              currentState.value.results.map((sale) {
                return sale.id.toString() == id ? updated : sale;
              }).toList();

          final updatedResponse = SalesResponse(
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
          Exception('Failed to update sale: ${response?.statusCode}'),
          StackTrace.current,
        );
        return null;
      }
    } catch (e, stack) {
      state = AsyncError(e, stack);
      return null;
    }
  }

  Future<bool> deleteSale(String id) async {
    try {
      final response = await ApiServices.delete(
        CrmFliperUrls.fetchSingleSales(id),
        hasToken: true,
      );

      if (response != null && response.statusCode == 204) {
        final currentState = state;
        if (currentState is AsyncData<SalesResponse>) {
          final updatedList =
              currentState.value.results
                  .where((sale) => sale.id.toString() != id)
                  .toList();

          final updatedResponse = SalesResponse(
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
          Exception('Failed to delete sale: ${response?.statusCode}'),
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
