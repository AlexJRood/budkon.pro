import 'dart:convert';
import 'package:crm_fliper/crm_fliper_urls.dart';
import 'package:flutter/foundation.dart';
import 'package:crm_fliper/models/flipper_draft_advertisement_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';


final draftAdvertisementsProvider = StateNotifierProvider<
  DraftAdvertisementsNotifier,
  List<FlipperDraftAdvertisement>
>((ref) => DraftAdvertisementsNotifier(ref));

class DraftAdvertisementsNotifier
    extends StateNotifier<List<FlipperDraftAdvertisement>> {
  final Ref ref;

  DraftAdvertisementsNotifier(this.ref) : super([]);

  Future<void> getDraftAdvertisements() async {
    try {
      final response = await ApiServices.get(
        CrmFliperUrls.fetchDraftAdvertisements,
        ref: ref,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(
          utf8.decode(response.data),
        );
        final data = FlipperDraftAdvertisementResponse.fromJson(jsonData);
        state = data.results;
        debugPrint('✅ Drafts loaded: ${state.length}');
      } else {
        debugPrint(
          '❌ Failed to fetch draft advertisements: ${response?.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('❌ Exception in getDraftAdvertisements: $e');
    }
  }

  Future<void> createDraftAdvertisement(
      FlipperDraftAdvertisement ad,
      BuildContext context,
      ) async {
    try {
      final response = await ApiServices.post(
        CrmFliperUrls.fetchDraftAdvertisements,
        hasToken: true,
        data: ad.toJson(),
      );

      if (response != null && response.statusCode == 201) {
        final newAd = FlipperDraftAdvertisement.fromJson(response.data);
        state = [...state, newAd];
        debugPrint('✅ Draft advertisement created with ID: ${newAd.id}');
      } else if (response != null && response.statusCode == 400) {
        debugPrint('❌ Validation failed with status 400');
        final data = response.data;
        if (data is Map<String, dynamic>) {
          data.forEach((field, errors) {
            if (errors is List) {
              for (final msg in errors) {
                debugPrint('• $field: $msg');
                _showSnackBar(context, '$field: $msg');
              }
            } else {
              debugPrint('• $field: $errors');
              _showSnackBar(context, '$field: $errors');
            }
          });
        } else {
          debugPrint('⚠️ Unexpected error format: $data');
          _showSnackBar(context, 'Unexpected validation error.');
        }
      } else {
        debugPrint('❌ Unexpected status: ${response?.statusCode}');
        _showSnackBar(context, 'Unexpected server response.');
      }
    } catch (e, stack) {
      debugPrint('❌ Unexpected exception: $e');
      debugPrint(stack.toString());
      _showSnackBar(context, 'Unexpected error occurred.');
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
      if (scaffoldMessenger != null) {
        scaffoldMessenger.showSnackBar(SnackBar(content: Text(message),backgroundColor: Colors.red,));
      } else {
        debugPrint('⚠️ Could not find ScaffoldMessenger in context.');
      }
    });
  }


  Future<FlipperDraftAdvertisement?> fetchSingleDraftAdvertisement(
    String id,
  ) async {
    try {
      final response = await ApiServices.get(
        CrmFliperUrls.fetchSingleDraftAdvertisements(id),
        ref: ref,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(
          utf8.decode(response.data),
        );

        final ad = FlipperDraftAdvertisement.fromJson(jsonData);
        debugPrint('✅ Single draft advertisement fetched with ID: ${ad.id}');
        return ad;
      } else {
        debugPrint(
          '❌ Failed to fetch single draft advertisement: ${response?.statusCode}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('❌ Exception in fetchSingleDraftAdvertisement: $e');
      return null;
    }
  }

  Future<FlipperDraftAdvertisement?> editDraftAdvertisement(
    String id,
    Map<String, dynamic> requestData,
  ) async {
    try {
      final response = await ApiServices.put(
        CrmFliperUrls.fetchSingleDraftAdvertisements(id),
        hasToken: true,
        data: requestData,
      );

      if (response != null && response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(
          utf8.decode(response.data),
        );

        final updatedAd = FlipperDraftAdvertisement.fromJson(jsonData);
        debugPrint('✅ Draft advertisement edited successfully: ${updatedAd.id}');
        return updatedAd;
      } else {
        debugPrint('❌ Draft advertisement edit failed: ${response?.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Exception in editDraftAdvertisement: $e');
      return null;
    }
  }

  Future<void> deleteDraftAdvertisement(String id) async {
    try {
      final response = await ApiServices.delete(
        CrmFliperUrls.fetchSingleDraftAdvertisements(id),
        hasToken: true,
      );
      if (response != null && response.statusCode == 204) {
        debugPrint('Draft advertisement deleted successfully');
      } else {
        debugPrint('Draft advertisement delete failed');
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}
