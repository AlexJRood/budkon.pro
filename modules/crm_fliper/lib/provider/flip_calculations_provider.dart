import 'dart:convert';
import 'package:crm_fliper/crm_fliper_urls.dart';
import 'package:flutter/foundation.dart';
import 'package:crm_fliper/models/flip_calculation_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';

final flipCalculationsProvider =
    StateNotifierProvider<FlipCalculationsNotifier, List<FlipCalculation>>(
      (ref) => FlipCalculationsNotifier(ref),
    );

class FlipCalculationsNotifier extends StateNotifier<List<FlipCalculation>> {
  final Ref ref;

  FlipCalculationsNotifier(this.ref) : super([]);

  Future<void> fetchFlipCalculations() async {
    try {
      final response = await ApiServices.get(
        CrmFliperUrls.fetchFlipCalculation,
        ref: ref,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(
          utf8.decode(response.data),
        );
        final data = FlipCalculationResponse.fromJson(jsonData);
        state = data.results;
        debugPrint('✅ Flip calculations fetched: ${state.length}');
      } else {
        debugPrint('❌ Failed to fetch flip calculations: ${response?.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Exception in fetchFlipCalculations: $e');
    }
  }

  Future<void> createFlipCalculation(
      FlipCalculation requestData,
      BuildContext context,
      ) async {
    try {
      final response = await ApiServices.post(
        CrmFliperUrls.fetchFlipCalculation,
        hasToken: true,
        data: requestData.toJson(), // Ensure this sends as a proper map
      );

      if (response != null && response.statusCode == 201) {
        final newCalculation = FlipCalculation.fromJson(response.data);
        state = [...state, newCalculation];
        debugPrint('✅ Flip calculation created with ID: ${newCalculation.id}');
      } else if (response != null && response.statusCode == 400) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          data.forEach((field, errors) {
            if (errors is List) {
              for (final msg in errors) {
                debugPrint('⚠️ $field: $msg');
                _showSnackBar(context, '$field: $msg');
              }
            } else {
              debugPrint('⚠️ $field: $errors');
              _showSnackBar(context, '$field: $errors');
            }
          });
        } else {
          debugPrint('⚠️ Unknown error format: $data');
          _showSnackBar(context, 'Unknown error occurred.');
        }
      } else {
        debugPrint('❌ Unexpected status: ${response?.statusCode}');
        _showSnackBar(context, 'Unexpected server error.');
      }
    } catch (e, stack) {
      debugPrint('❌ Exception in createFlipCalculation: $e');
      debugPrint(stack.toString());
      _showSnackBar(context, 'Exception during calculation.');
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<FlipCalculation?> fetchSingleFlipCalculation(String id) async {
    try {
      final response = await ApiServices.get(
        CrmFliperUrls.fetchSingleFlipCalculation(id),
        ref: ref,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(
          utf8.decode(response.data),
        );
        final model = FlipCalculation.fromJson(jsonData);
        debugPrint('✅ Single flip calculation fetched: ID ${model.id}');
        return model;
      } else {
        debugPrint('❌ Single flip calculation failed: ${response?.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Exception in fetchSingleFlipCalculation: $e');
      return null;
    }
  }

  Future<void> editFlipCalculation(
    String id,
    Map<String, dynamic> updateData,
  ) async {
    try {
      final response = await ApiServices.put(
        CrmFliperUrls.fetchSingleFlipCalculation(id),
        hasToken: true,
        data: updateData,
      );

      if (response != null && response.statusCode == 200) {
        debugPrint('✅ Flip calculation edited successfully');
      } else {
        debugPrint('❌ Failed to edit flip calculation: ${response?.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Exception in editFlipCalculation: $e');
    }
  }

  Future<void> deleteFlipCalculation(String id) async {
    try {
      final response = await ApiServices.delete(
        CrmFliperUrls.fetchSingleFlipCalculation(id),
        hasToken: true,
      );

      if (response != null && response.statusCode == 204) {
        debugPrint('Flip calculation deleted successfully');
      } else {
        debugPrint('Flip calculation deletion failed');
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}
