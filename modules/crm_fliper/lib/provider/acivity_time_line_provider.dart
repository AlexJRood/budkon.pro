import 'dart:convert';
import 'package:crm_fliper/crm_fliper_urls.dart';
import 'package:flutter/foundation.dart';
import 'package:crm_fliper/models/flipper_activity_timeline_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';

final activityTimeLineProvider = StateNotifierProvider<
  ActivityTimeLineNotifier,
  List<FlipperActivityTimeline>
>((ref) {
  return ActivityTimeLineNotifier(ref);
});

class ActivityTimeLineNotifier
    extends StateNotifier<List<FlipperActivityTimeline>> {
  final Ref ref;

  ActivityTimeLineNotifier(this.ref) : super([]);

  Future<List<FlipperActivityTimeline>> getFlipperActivityTimeLine() async {
    try {
      final response = await ApiServices.get(
        CrmFliperUrls.fetchActivityTimeLine,
        ref: ref,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(
          utf8.decode(response.data),
        );
        final data = FlipperActivityTimelineResponse.fromJson(jsonData);
        state = data.results;
        debugPrint('✅ Fetched Activity Timeline: ${state.length}');
        return state;
      } else {
        debugPrint('❌ Failed to fetch activity timeline: ${response?.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Exception in getFlipperActivityTimeLine: $e');
      return [];
    }
  }

  Future<void> postFlipperActivityTimeLine({
    required int transactionId,
    required String action,
  }) async {
    try {
      final requestData = {
        "transaction": transactionId,
        "action": action,
      };

      debugPrint('📤 Sending to: ${CrmFliperUrls.fetchActivityTimeLine}');
      debugPrint('🔎 Payload: $requestData');

      final response = await ApiServices.post(
        CrmFliperUrls.fetchActivityTimeLine,
        hasToken: true,
        data: requestData,
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final responseData = response.data;

        debugPrint('✅ Response received: $responseData');

        if (responseData is Map<String, dynamic>) {
          final newEntry = FlipperActivityTimeline.fromJson(responseData);
          state = [...state, newEntry];
          debugPrint('✅ POST success: Entry added to timeline.');
        } else if (responseData is int) {
          // Fallback: server only returned an ID
          final newEntry = FlipperActivityTimeline(id: responseData, action: action);
          state = [...state, newEntry];
          debugPrint('⚠️ Partial POST success: Only ID received: $responseData');
        } else {
          debugPrint('❌ Unexpected response type: ${responseData.runtimeType}');
        }
      } else {
        debugPrint('❌ POST failed with status: ${response?.statusCode}');
        debugPrint('❌ Response body: ${response?.data}');
      }
    } catch (e, stack) {
      debugPrint('❌ Exception in postFlipperActivityTimeLine: $e');
      debugPrint(stack.toString());
    }
  }

  Future<FlipperActivityTimeline?> getSingleFlipperActivityTimeLineById(
    String id,
  ) async {
    try {
      final response = await ApiServices.get(
        CrmFliperUrls.fetchActivityTimeLineById(id),
        ref: ref,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(
          utf8.decode(response.data),
        );
        final timeline = FlipperActivityTimeline.fromJson(jsonData);
        debugPrint('✅ Time line fetched correctly: ID ${timeline.id}');
        return timeline;
      } else {
        debugPrint('❌ Time line fetch failed with status: ${response?.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Exception in getSingleFlipperActivityTimeLineById: $e');
      return null;
    }
  }

  Future<void> editFlipperActivityTimeLine({
    required String id,
    required int transactionId,
    required String action,
  }) async {
    try {
      final requestData = {"transaction": transactionId, "action": action};

      final response = await ApiServices.put(
        CrmFliperUrls.fetchActivityTimeLineById(id),
        data: requestData,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        debugPrint('✅ Flipper activity timeline edited correctly');
      } else {
        debugPrint(
          '❌ Flipper activity timeline edit failed: ${response?.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('❌ Exception in editFlipperActivityTimeLine: $e');
    }
  }

  Future<void> deleteFlipperActivityTimeLine(String id) async {
    try {
      final response = await ApiServices.delete(
        CrmFliperUrls.fetchActivityTimeLineById(id),
        hasToken: true,
      );

      if (response != null && response.statusCode == 204) {
        debugPrint('Flipper activity timeline deleted successfully');
      } else {
        debugPrint('Flipper activity timeline delete failed');
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}
