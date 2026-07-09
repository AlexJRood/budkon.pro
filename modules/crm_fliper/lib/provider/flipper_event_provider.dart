import 'dart:convert';
import 'package:crm_fliper/crm_fliper_urls.dart';
import 'package:flutter/foundation.dart';
import 'package:crm_fliper/models/flipper_event_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';

final flipperEventProvider =
    StateNotifierProvider<FlipperEventNotifier, List<FlipperEvent>>(
      (ref) => FlipperEventNotifier(ref),
    );

class FlipperEventNotifier extends StateNotifier<List<FlipperEvent>> {
  final Ref ref;

  FlipperEventNotifier(this.ref) : super([]);

  /// Fetch list of events
  Future<List<FlipperEvent>> fetchFlipperEvents() async {
    try {
      final response = await ApiServices.get(
        CrmFliperUrls.fetchFlipperEvents,
        ref: ref,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(
          utf8.decode(response.data),
        );
        final data = FlipperEventResponse.fromJson(jsonData);
        state = data.results;
        debugPrint('✅ Events loaded: ${state.length}');
        return data.results;
      } else {
        debugPrint('❌ Failed to fetch events: ${response?.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Exception in fetchFlipperEvents: $e');
      return [];
    }
  }

  /// Fetch single event by ID
  Future<FlipperEvent?> fetchSingleFlipperEvent(String id) async {
    try {
      final response = await ApiServices.get(
        CrmFliperUrls.fetchSingleFlipperEvents(id),
        ref: ref,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(
          utf8.decode(response.data),
        );
        final event = FlipperEvent.fromJson(jsonData);
        debugPrint('✅ Single event fetched: ${event.title}');
        return event;
      } else {
        debugPrint('❌ Failed to fetch single event: ${response?.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Exception in fetchSingleFlipperEvent: $e');
      return null;
    }
  }
}
