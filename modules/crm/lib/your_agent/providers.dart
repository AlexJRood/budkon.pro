import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';
import 'urls.dart';
import 'models.dart';
import 'package:dio/dio.dart';


Map<String, dynamic> _decodeToMap(dynamic rawData) {
  if (rawData is Map) {
    return rawData.cast<String, dynamic>();
  }

  if (rawData is String) {
    final decoded = jsonDecode(rawData);
    if (decoded is Map) return decoded.cast<String, dynamic>();
  }

  if (rawData is Uint8List || rawData is List<int>) {
    final bytes = rawData is Uint8List
        ? rawData
        : Uint8List.fromList(rawData as List<int>);
    final jsonString = utf8.decode(bytes);
    final decoded = jsonDecode(jsonString);
    if (decoded is Map) return decoded.cast<String, dynamic>();
  }

  throw Exception('Invalid map response type: ${rawData.runtimeType}');
}




final clientPortalCaseDetailProvider =
    FutureProvider.family<ClientPortalCaseDetail, String>((ref, portalId) async {
  final resp = await ApiServices.get(
    URLsClientPortal.clientPortalCaseDetail(portalId),
    hasToken: true,
    ref: ref,
  );

  if (resp == null) {
    throw Exception('No response from your-agent case detail');
  }

  final rawData = resp.data;

  // 1) Jeśli już jest Mapą – super
  if (rawData is Map) {
    final map = Map<String, dynamic>.from(rawData);
    return ClientPortalCaseDetail.fromJson(map);
  }

  // 2) Jeśli to String – dekodujemy JSON
  if (rawData is String) {
    final decoded = jsonDecode(rawData);
    if (decoded is Map) {
      final map = Map<String, dynamic>.from(decoded);
      return ClientPortalCaseDetail.fromJson(map);
    }
  }

  // 3) Jeśli to bajty (Uint8List / List<int>) – najpierw na String, potem JSON
  if (rawData is Uint8List || rawData is List<int>) {
    final bytes = rawData is Uint8List ? rawData : Uint8List.fromList(rawData as List<int>);
    final jsonString = utf8.decode(bytes);
    final decoded = jsonDecode(jsonString);

    if (decoded is Map) {
      final map = Map<String, dynamic>.from(decoded);
      return ClientPortalCaseDetail.fromJson(map);
    }
  }

  // (opcjonalnie: możesz tu dodać print(rawData); żeby zobaczyć dokładną treść)
  throw Exception(
    'Invalid response from your-agent case detail (type: ${rawData.runtimeType})',
  );
});


final clientPortalInviteStatusProvider =
    FutureProvider.family.autoDispose<ClientPortalInviteStatusResponse, String>((
  ref,
  token,
) async {
  final resp = await ApiServices.get(
    URLsClientPortal.inviteStatus(token),
    hasToken: false,
    ref: ref,
  );

  if (resp == null) {
    throw Exception('No response from your-agent invite status');
  }

  final map = _decodeToMap(resp.data);
  return ClientPortalInviteStatusResponse.fromJson(map);
});


class ClientPortalEventTypes {
  static const String portalVisit = 'portal_visit';
  static const String listingView = 'listing_view';
  static const String documentsView = 'documents_view';
  static const String presentationsView = 'presentations_view';

  static const String presentationsListView = 'presentations_list_view';
  static const String presentationItemOpen = 'presentation_item_open';
  static const String presentationEventOpen = 'presentation_event_open';
}


final clientPortalActionsProvider = Provider<ClientPortalActions>((ref) {
  return ClientPortalActions(ref);
});

class ClientPortalActions {
  final Ref ref;

  ClientPortalActions(this.ref);

  Future<void> trackEvent({
    required String portalId,
    required String eventType,
    Map<String, dynamic>? metadata,
  }) async {
    final resp = await ApiServices.post(
      URLsClientPortal.clientPortalTrackEvent(portalId),
      data: {
        'event_type': eventType,
        if (metadata != null) 'metadata': metadata,
      },
      hasToken: true,
      ref: ref,
    );

    if (resp == null) {
      throw Exception('Track event failed');
    }

    final statusCode = resp.statusCode ?? 500;
    if (statusCode >= 400) {
      throw Exception('Track event failed: $statusCode');
    }
  }
}

final agentPortalStatusProvider =
    FutureProvider.family<AgentPortalStatusModel, int>((ref, transactionId) async {
  final resp = await ApiServices.get(
    URLsAgentClientPortal.statusPortal(transactionId.toString()),
    hasToken: true,
    ref: ref,
    responseType: ResponseType.json,
  );

  if (resp == null) {
    throw Exception('No response from agent portal status endpoint');
  }

  final map = _decodeToMap(resp.data);
  return AgentPortalStatusModel.fromJson(map);
});


final clientPortalInviteActionsProvider =
    Provider<ClientPortalInviteActions>((ref) {
  return ClientPortalInviteActions(ref);
});

class ClientPortalInviteActions {
  final Ref ref;

  ClientPortalInviteActions(this.ref);

  Future<ClientPortalInviteStatusResponse> bindInvite({
    required String token,
  }) async {
    final resp = await ApiServices.post(
      URLsClientPortal.inviteBind(token),
      data: const {},
      hasToken: true,
      ref: ref,
    );

    if (resp == null) {
      throw Exception('Binding invite failed');
    }

    final map = _decodeToMap(resp.data);
    final result = ClientPortalInviteStatusResponse.fromJson(map);

    ref.invalidate(clientPortalInviteStatusProvider(token));
    return result;
  }
}