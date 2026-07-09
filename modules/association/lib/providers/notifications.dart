// Association Notifications Screen (Flutter Web/Desktop)
// Uses Riverpod. Plug into your routing as a standalone page.
// Comments are in English as requested.


import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:association/models/notifications_model.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/platform/secure_storage.dart';


class AssocNotifApi {
  AssocNotifApi(this.baseUrl, {required this.ref});
  final String baseUrl; // np. https://www.superbee.cloud
  final Ref ref;

  String _url(String path) => '$baseUrl$path';



Future<List<AssociationNotificationCampaign>> listCampaigns({
  required int associationId,
}) async {
  final res = await ApiServices.get(
    _url('/association/notifications/campaigns/'),
    queryParameters: {'association_id': associationId.toString()},
    hasToken: true,
    responseType: ResponseType.json,
    ref: ref,
  );
  if (res == null) {
    throw Exception('List failed: no response');
  }
  if (res.statusCode != 200) {
    throw Exception('List failed: ${res.statusCode} ${res.data}');
  }

  final root = res.data;
  List<dynamic> rawList;

  if (root is List) {
    rawList = root;
  } else if (root is Map) {
    if (root['results'] is List) {
      rawList = root['results'] as List;
    } else if (root['items'] is List) {
      rawList = root['items'] as List;
    } else if (root['data'] is List) {
      rawList = root['data'] as List;
    } else {
      throw FormatException(
        'Expected a List at top-level or in "results/items/data", got ${root.runtimeType}',
      );
    }
  } else {
    throw FormatException('Unexpected response type: ${root.runtimeType}');
  }

  return rawList
      .map((e) => AssociationNotificationCampaign.fromListJson(
            Map<String, dynamic>.from(e as Map),
          ))
      .toList();
}


  Future<AssociationNotificationCampaign> getCampaign(String id) async {
    final res = await ApiServices.get(
      _url('/association/notifications/campaigns/$id/'),
      hasToken: true,
      responseType: ResponseType.json,
      ref: ref,
    );
    if (res == null) {
      throw Exception('Detail failed: no response');
    }
    if (res.statusCode != 200) {
      throw Exception('Detail failed: ${res.statusCode} ${res.data}');
    }
    final data = Map<String, dynamic>.from(res.data as Map);
    return AssociationNotificationCampaign.fromDetailJson(data);
  }

  Future<int> dryRun({
    required int associationId,
    required String title,
    required String text,
    String? image,
    List<String>? memberStatuses,
    List<String>? includeMemberIds,
    List<String>? excludeMemberIds,
    bool respectConsent = true,
  }) async {
    final body = {
      'association_id': associationId,
      'title': title,
      'text': text,
      if (image != null && image.isNotEmpty) 'image': image,
      if (memberStatuses != null) 'member_statuses': memberStatuses,
      if (includeMemberIds != null) 'include_member_ids': includeMemberIds,
      if (excludeMemberIds != null) 'exclude_member_ids': excludeMemberIds,
      'respect_consent': respectConsent,
    };

    final res = await ApiServices.post(
      _url('/association/notifications/campaigns/dry-run/'),
      data: body,
      hasToken: true,
      ref: ref,
    );

    if (res == null) {
      throw Exception('Dry-run failed: no response');
    }
    if (res.statusCode != 200) {
      throw Exception('Dry-run failed: ${res.statusCode} ${res.data}');
    }
    final data = Map<String, dynamic>.from(res.data as Map);
    return (data['prospective_recipients'] as num?)?.toInt() ?? 0;
  }

  Future<String> createCampaign({
    required int associationId,
    required String title,
    required String text,
    String? image,
    List<Map<String, dynamic>>? actions,
    List<String>? memberStatuses,
    List<String>? includeMemberIds,
    List<String>? excludeMemberIds,
    bool respectConsent = true,
    DateTime? scheduledAt,
    bool sendNow = false,
  }) async {
    final body = {
      'association_id': associationId,
      'title': title,
      'text': text,
      if (image != null && image.isNotEmpty) 'image': image,
      if (actions != null) 'actions': actions,
      if (memberStatuses != null) 'member_statuses': memberStatuses,
      if (includeMemberIds != null) 'include_member_ids': includeMemberIds,
      if (excludeMemberIds != null) 'exclude_member_ids': excludeMemberIds,
      'respect_consent': respectConsent,
      if (scheduledAt != null) 'scheduled_at': scheduledAt.toIso8601String(),
      'send_now': sendNow,
    };

    final res = await ApiServices.post(
      _url('/association/notifications/campaigns/'),
      data: body,
      hasToken: true,
      ref: ref,
    );

    if (res == null) {
      throw Exception('Create failed: no response');
    }
    if (res.statusCode != 201) {
      throw Exception('Create failed: ${res.statusCode} ${res.data}');
    }
    final data = Map<String, dynamic>.from(res.data as Map);
    return data['id']?.toString() ?? '';
  }

  Future<void> sendNow(String id) async {
    final res = await ApiServices.post(
      _url('/association/notifications/campaigns/$id/send-now/'),
      hasToken: true,
      ref: ref,
    );
    if (res == null) throw Exception('Send-now failed: no response');
    if (res.statusCode != 200) {
      throw Exception('Send-now failed: ${res.statusCode} ${res.data}');
    }
  }

  Future<void> cancelCampaign(String id) async {
    final res = await ApiServices.post(
      _url('/association/notifications/campaigns/$id/cancel/'),
      hasToken: true,
      ref: ref,
    );
    if (res == null) throw Exception('Cancel failed: no response');
    if (res.statusCode != 200) {
      throw Exception('Cancel failed: ${res.statusCode} ${res.data}');
    }
  }
}







// =====================
// 3) PROVIDERS
// =====================

final authTokenProvider = Provider<Future<String?> Function()>((ref) {
  return () async => SecureStorage().getToken();
});

final assocNotifApiProvider = Provider.family<AssocNotifApi, String>((ref, baseUrl) {
  return AssocNotifApi(baseUrl, ref:ref);
});

class CampaignListState {
  final List<AssociationNotificationCampaign> items;
  final bool loading;
  final String? error;
  final String? selectedId;
  CampaignListState({
    this.items = const [],
    this.loading = false,
    this.error,
    this.selectedId,
  });

  CampaignListState copyWith({
    List<AssociationNotificationCampaign>? items,
    bool? loading,
    String? error,
    String? selectedId,
  }) => CampaignListState(
        items: items ?? this.items,
        loading: loading ?? this.loading,
        error: error,
        selectedId: selectedId ?? this.selectedId,
      );
}

class CampaignListNotifier extends StateNotifier<CampaignListState> {
  CampaignListNotifier(this._api, this.associationId) : super(CampaignListState());
  final AssocNotifApi _api;
  final int associationId;

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final list = await _api.listCampaigns(associationId: associationId);
      state = state.copyWith(items: list, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void select(String? id) {
    state = state.copyWith(selectedId: id);
  }
}

final campaignListProvider = StateNotifierProvider.family<CampaignListNotifier, CampaignListState, ({String baseUrl, int associationId})>((ref, args) {
  final api = ref.read(assocNotifApiProvider(args.baseUrl));
  return CampaignListNotifier(api, args.associationId);
});

final campaignDetailProvider = FutureProvider.family<AssociationNotificationCampaign?, ({String baseUrl, String id})>((ref, args) async {
  final api = ref.read(assocNotifApiProvider(args.baseUrl));
  return api.getCampaign(args.id);
});


