import 'dart:convert';
import 'dart:typed_data';

import 'package:crm/your_agent/providers.dart';
import 'package:dio/dio.dart';
import 'package:crm/your_agent/models.dart';
import 'package:crm/your_agent/urls.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';

final agentPortalManageProvider =
    FutureProvider.family<AgentPortalManageResponse, int>((ref, transactionId) async {
  final resp = await ApiServices.get(
    URLsAgentClientPortal.managePortal(transactionId.toString()),
    hasToken: true,
    ref: ref,
    responseType: ResponseType.plain,
  );

  if (resp == null) {
    throw Exception('No response from agent portal manage endpoint');
  }

  final map = _decodeToMap(resp.data);
  return AgentPortalManageResponse.fromJson(map);
});

final agentPortalPreviewProvider =
    FutureProvider.family<ClientPortalCaseDetail, int>((ref, transactionId) async {
  final resp = await ApiServices.get(
    URLsAgentClientPortal.previewPortal(transactionId.toString()),
    hasToken: true,
    ref: ref,
    responseType: ResponseType.plain,
  );

  if (resp == null) {
    throw Exception('No response from agent portal preview endpoint');
  }

  final map = _decodeToMap(resp.data);
  return ClientPortalCaseDetail.fromJson(map);
});

final agentPortalSuggestionsProvider =
    FutureProvider.family<List<AgentPortalSuggestionModel>, int>((ref, transactionId) async {
  final resp = await ApiServices.get(
    URLsAgentClientPortal.suggestions(transactionId.toString()),
    hasToken: true,
    ref: ref,
    responseType: ResponseType.plain,
  );

  if (resp == null) {
    throw Exception('No response from agent portal suggestions endpoint');
  }

  final rawList = _decodeToList(resp.data);

  debugPrint(
    '🟡 agentPortalSuggestionsProvider tx=$transactionId rawCount=${rawList.length}',
  );

  final parsed = rawList.map((item) {
    final map = _toStringKeyedMap(item);
    return AgentPortalSuggestionModel.fromJson(map);
  }).toList();

  debugPrint(
    '✅ agentPortalSuggestionsProvider tx=$transactionId parsed=${parsed.length}',
  );

  return parsed;
});

final agentPortalActionsProvider = Provider<AgentPortalActions>((ref) {
  return AgentPortalActions(ref);
});

class AgentPortalActions {
  final Ref ref;

  AgentPortalActions(this.ref);

  Future<void> savePortal({
    required int transactionId,
    required bool exists,
    required Map<String, dynamic> payload,
  }) async {
    final url = URLsAgentClientPortal.managePortal(transactionId.toString());

    final resp = exists
        ? await ApiServices.patch(
            url,
            data: payload,
            hasToken: true,
            ref: ref,
          )
        : await ApiServices.post(
            url,
            data: payload,
            hasToken: true,
            ref: ref,
          );

    if (resp == null) {
      throw Exception('Saving portal failed');
    }

    ref.invalidate(agentPortalManageProvider(transactionId));
    ref.invalidate(agentPortalPreviewProvider(transactionId));
    ref.invalidate(agentPortalSuggestionsProvider(transactionId));
    ref.invalidate(agentPortalStatusProvider(transactionId));
  }

  Future<void> resendInvite({
    required int transactionId,
    bool regenerateInvite = false,
  }) async {
    final resp = await ApiServices.post(
      URLsAgentClientPortal.resendInvite(transactionId.toString()),
      data: {
        'regenerate_invite': regenerateInvite,
      },
      hasToken: true,
      ref: ref,
    );

    if (resp == null) {
      throw Exception('Resending invite failed');
    }

    ref.invalidate(agentPortalManageProvider(transactionId));
    ref.invalidate(agentPortalStatusProvider(transactionId));
  }

  Future<void> reviewSuggestion({
    required int transactionId,
    required int suggestionId,
    required String action,
    String? reviewNote,
  }) async {
    final resp = await ApiServices.post(
      URLsAgentClientPortal.reviewSuggestion(
        transactionId.toString(),
        suggestionId.toString(),
      ),
      data: {
        'action': action,
        if (reviewNote != null && reviewNote.trim().isNotEmpty)
          'review_note': reviewNote.trim(),
      },
      hasToken: true,
      ref: ref,
    );

    if (resp == null) {
      throw Exception('Suggestion review failed');
    }

    ref.invalidate(agentPortalManageProvider(transactionId));
    ref.invalidate(agentPortalPreviewProvider(transactionId));
    ref.invalidate(agentPortalSuggestionsProvider(transactionId));
    ref.invalidate(agentPortalStatusProvider(transactionId));
  }
}

dynamic _decodeJsonPayload(dynamic rawData) {
  if (rawData == null) {
    throw Exception('Response payload is null');
  }

  if (rawData is Map || rawData is List) {
    return rawData;
  }

  if (rawData is String) {
    final text = rawData.trim();
    if (text.isEmpty) {
      throw Exception('Response payload is empty');
    }
    return jsonDecode(text);
  }

  if (rawData is Uint8List || rawData is List<int>) {
    final bytes = rawData is Uint8List
        ? rawData
        : Uint8List.fromList(List<int>.from(rawData));
    final text = utf8.decode(bytes).trim();
    if (text.isEmpty) {
      throw Exception('Response payload is empty');
    }
    return jsonDecode(text);
  }

  throw Exception('Unsupported payload type: ${rawData.runtimeType}');
}

Map<String, dynamic> _decodeToMap(dynamic rawData) {
  final decoded = _decodeJsonPayload(rawData);

  if (decoded is Map<String, dynamic>) {
    return decoded;
  }

  if (decoded is Map) {
    return Map<String, dynamic>.from(decoded);
  }

  throw Exception('Expected map, got: ${decoded.runtimeType}');
}

List<dynamic> _decodeToList(dynamic rawData) {
  final decoded = _decodeJsonPayload(rawData);

  if (decoded is List) {
    return decoded;
  }

  if (decoded is Map) {
    if (decoded['results'] is List) return List<dynamic>.from(decoded['results']);
    if (decoded['data'] is List) return List<dynamic>.from(decoded['data']);
    if (decoded['items'] is List) return List<dynamic>.from(decoded['items']);
  }

  throw Exception('Expected list, got: ${decoded.runtimeType}');
}

Map<String, dynamic> _toStringKeyedMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return value.map(
      (key, val) => MapEntry(
        key.toString(),
        _normalizeJsonValue(val),
      ),
    );
  }

  throw Exception('Expected map item, got: ${value.runtimeType}');
}

dynamic _normalizeJsonValue(dynamic value) {
  if (value is Map) {
    return value.map(
      (key, val) => MapEntry(
        key.toString(),
        _normalizeJsonValue(val),
      ),
    );
  }

  if (value is List) {
    return value.map(_normalizeJsonValue).toList();
  }

  return value;
}