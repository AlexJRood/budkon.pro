import 'dart:convert';
import 'package:network_monitoring/network_monitoring_urls.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';

import '../models/active_check_queued_response.dart';

class ActiveCheckNotifier extends StateNotifier<bool> {
  final Ref ref;

  ActiveCheckNotifier(this.ref) : super(false);

  Future<void> requestActiveCheck({
    required String url,
    String? source,
    String? reason,
    DateTime? detectedAt,
  }) async {
    if (url.trim().isEmpty) return;

    state = true;

    try {
      final response = await ApiServices.post(
        NetworkMonitoringUrls.requestActiveCheck,
        ref: ref,
        hasToken: true,
        data: {
          "url": url,
          "source": source ?? "mobile",
          "reason": reason,
          "detected_at": (detectedAt ?? DateTime.now())
              .toUtc()
              .toIso8601String(),
        },
      );

      if (response != null && response.statusCode == 202) {
        dynamic jsonData = response.data;

        if (jsonData is Uint8List) {
          jsonData = jsonDecode(utf8.decode(jsonData));
        }

        final parsed = ActiveCheckQueuedResponse.fromJson(jsonData);
        debugPrint('Active check queued');
        debugPrint('URL: ${parsed.url}');
        debugPrint('Task ID: ${parsed.taskId}');
      } else {
        debugPrint('Active check request failed: ${response?.statusCode}');
        if (response?.data != null) {
          debugPrint('Response data: ${response?.data}');
        }
      }
    } catch (e) {
      debugPrint('Exception while requesting active check: $e');
    } finally {
      state = false;
    }
  }
}

final activeCheckProvider =
StateNotifierProvider<ActiveCheckNotifier, bool>((ref) {
  return ActiveCheckNotifier(ref);
});