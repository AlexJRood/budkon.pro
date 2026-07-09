// lib/data/clients/client_Hide_provider.dart
import 'dart:convert';
import 'package:crm/crm_urls.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';
import 'package:network_monitoring/models/monitoring_ads_model.dart';

@immutable
class HideScope {
  final int? transactionId;
  final int? clientId;
  const HideScope({this.transactionId, this.clientId});

  Map<String, dynamic> toQuery() => {
    if (transactionId != null) 'transaction_id': transactionId,
    if (clientId != null) 'client_id': clientId,
  };

  @override
  bool operator ==(Object o) =>
      o is HideScope &&
      o.transactionId == transactionId &&
      o.clientId == clientId;

  @override
  int get hashCode => Object.hash(transactionId, clientId);
}

/// Zwraca SET ID-ków polubionych w danym scope (do serduszek)
final nmHideScopedIdsProvider =
    FutureProvider.family<Set<int>, HideScope>((ref, scope) async {
  final resp = await ApiServices.get(
    ref: ref,
    CrmUrls.hideMonitoring,
    hasToken: true,
    queryParameters: scope.toQuery(),
  );
  if (resp == null || resp.statusCode != 200) {
    throw Exception('Failed to load Hideorites for scope: $scope');
  }

  final raw = resp.data;
  late final Map<String, dynamic> jsonMap;
  if (raw is Map) {
    jsonMap = Map<String, dynamic>.from(raw);
  } else if (raw is String) {
    jsonMap = json.decode(raw) as Map<String, dynamic>;
  } else if (raw is Uint8List) {
    jsonMap = json.decode(utf8.decode(raw)) as Map<String, dynamic>;
  } else if (raw is List<int>) {
    jsonMap = json.decode(utf8.decode(raw)) as Map<String, dynamic>;
  } else {
    throw Exception('Unsupported response data type: ${raw.runtimeType}');
  }

  final results = (jsonMap['results'] as List<dynamic>? ?? [])
      .map((e) => MonitoringAdsModel.fromJson(e as Map<String, dynamic>))
      .map((m) => m.id)
      .toSet();

  return results;
});

/// Pełne ogłoszenia polubione dla danej transakcji (tak jak używasz w HideListClient)
final clientHideProvider = FutureProvider.family<List<MonitoringAdsModel>, int>((ref, transactionId) async {
  final resp = await ApiServices.get(
    ref: ref,
    CrmUrls.hideMonitoring, // endpoint zwraca już tylko polubione
    hasToken: true,
    queryParameters: {'transaction_id': transactionId},
  );
  if (resp == null || resp.statusCode != 200) {
    throw Exception('Failed to load listings for transaction_id=$transactionId');
  }

  final raw = resp.data;
  late final Map<String, dynamic> jsonMap;
  if (raw is Map) {
    jsonMap = Map<String, dynamic>.from(raw);
  } else if (raw is String) {
    jsonMap = json.decode(raw) as Map<String, dynamic>;
  } else if (raw is Uint8List) {
    jsonMap = json.decode(utf8.decode(raw)) as Map<String, dynamic>;
  } else if (raw is List<int>) {
    jsonMap = json.decode(utf8.decode(raw)) as Map<String, dynamic>;
  } else {
    throw Exception('Unsupported response data type: ${raw.runtimeType}');
  }

  final list = (jsonMap['results'] as List<dynamic>? ?? [])
      .map((e) => MonitoringAdsModel.fromJson(e as Map<String, dynamic>))
      .toList();

  return list;
});

/// Helper do serduszka względem scope'u
bool isHideInScope(WidgetRef ref, int adId, HideScope scope) {
  final hideIdsAsync = ref.watch(nmHideScopedIdsProvider(scope));
  final hideIds = hideIdsAsync.maybeWhen(
    data: (s) => s,
    orElse: () => const <int>{},
  );
  return hideIds.contains(adId);
}


