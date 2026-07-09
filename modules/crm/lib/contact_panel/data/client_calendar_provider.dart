import 'dart:convert';
import 'package:crm/crm_urls.dart';

import 'package:crm/shared/models/transaction/agent_transaction_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';

class CalendarTransActionByClientNotifier
    extends StateNotifier<List<AgentTransactionModel>> {
  final Ref ref;
  CalendarTransActionByClientNotifier(this.ref) : super([]);

  Future<void> getTransActionByClient(
    String clientId, {
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final String url = CrmUrls.transActionByClient(clientId);
      final response = await ApiServices.get(
        url,
        ref: ref,
        hasToken: true,
        queryParameters: queryParams ?? {},
      );
      if (response != null && response.statusCode == 200) {
        if (response.data == null || response.data.isEmpty) {
          state = [];
          return;
        }
        try {
          final decoded = jsonDecode(utf8.decode(response.data));
          state = decoded is List ? AgentTransactionModel.fromList(decoded) : [];
        } catch (_) {
          state = [];
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('CalendarTransActionByClient error: $e');
    }
  }
}

final calendarTransActionByClientProvider = StateNotifierProvider<
    CalendarTransActionByClientNotifier,
    List<AgentTransactionModel>>(
  (ref) => CalendarTransActionByClientNotifier(ref),
);
