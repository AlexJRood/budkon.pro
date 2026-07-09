import 'dart:convert';

import 'package:crm/dynamic_dashboard/models/dashboard_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';
import 'package:crm/dynamic_dashboard/utils/urls_dashboard.dart';

final dashboardLayoutApiProvider = Provider<DashboardLayoutApi>((ref) {
  return DashboardLayoutApi(ref);
});

class DashboardRemoteCheckResult {
  final bool hasChanges;
  final int revision;
  final String? updatedAt;

  const DashboardRemoteCheckResult({
    required this.hasChanges,
    required this.revision,
    required this.updatedAt,
  });

  factory DashboardRemoteCheckResult.fromJson(Map<String, dynamic> json) {
    return DashboardRemoteCheckResult(
      hasChanges: json['has_changes'] as bool? ?? true,
      revision: (json['revision'] as num?)?.toInt() ?? 0,
      updatedAt: json['updated_at']?.toString(),
    );
  }
}

class DashboardLayoutApi {
  DashboardLayoutApi(this.ref);

  final Ref ref;

  String _endpoint(String dashboardKey) {
    return '${DashboardURLs.dashboardLayoutBase}$dashboardKey/';
  }

  String _checkEndpoint(
    String dashboardKey, {
    String? lastCheckIso,
    int? localRevision,
  }) {
    final params = <String, String>{};

    if (lastCheckIso != null && lastCheckIso.isNotEmpty) {
      params['last_check'] = lastCheckIso;
    }

    if (localRevision != null) {
      params['local_revision'] = '$localRevision';
    }

    final query = params.entries
        .map(
          (e) =>
              '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}',
        )
        .join('&');

    if (query.isEmpty) {
      return '${DashboardURLs.dashboardLayoutBase}$dashboardKey/check/';
    }

    return '${DashboardURLs.dashboardLayoutBase}$dashboardKey/check/?$query';
  }

  String _resetEndpoint(String dashboardKey) {
    return '${DashboardURLs.dashboardLayoutBase}$dashboardKey/reset/';
  }

  Future<DashboardRemoteCheckResult> checkRemoteChanges({
    required String dashboardKey,
    String? lastCheckIso,
    int? localRevision,
  }) async {
    final response = await ApiServices.get(
      _checkEndpoint(
        dashboardKey,
        lastCheckIso: lastCheckIso,
        localRevision: localRevision,
      ),
      hasToken: true,
      ref: ref,
      responseType: ResponseType.json,
    );

    if (response == null) {
      return const DashboardRemoteCheckResult(
        hasChanges: true,
        revision: 0,
        updatedAt: null,
      );
    }

    final map = _normalizeResponse(response) ?? <String, dynamic>{};
    return DashboardRemoteCheckResult.fromJson(map);
  }

  Future<DashboardConfig?> fetchLayout(String dashboardKey) async {
    final response = await ApiServices.get(
      _endpoint(dashboardKey),
      hasToken: true,
      ref: ref,
      responseType: ResponseType.json,
    );

    if (response == null) return null;
    if (response.statusCode == 404) return null;

    final jsonMap = _normalizeResponse(response);
    if (jsonMap == null || jsonMap.isEmpty) return null;

    return DashboardConfig.fromJson(jsonMap);
  }

  Future<DashboardConfig> saveLayout({
    required String dashboardKey,
    required DashboardConfig config,
  }) async {
    final response = await ApiServices.put(
      _endpoint(dashboardKey),
      hasToken: true,
      data: config.toJson(),
      headers: const {
        'Content-Type': 'application/json',
      },
    );

    if (response == null) {
      return config;
    }

    final map = _normalizeResponse(response);
    if (map == null || map.isEmpty) {
      return config;
    }

    return DashboardConfig.fromJson(map);
  }

  Future<void> resetLayout(String dashboardKey) async {
    await ApiServices.post(
      _resetEndpoint(dashboardKey),
      hasToken: true,
      ref: ref,
      data: const <String, dynamic>{},
      headers: const {
        'Content-Type': 'application/json',
      },
    );
  }

  Map<String, dynamic>? _normalizeResponse(dynamic response) {
    final raw = response is Response ? response.data : response;
    if (raw == null) return null;

    try {
      if (raw is Map<String, dynamic>) {
        return raw;
      }

      if (raw is Map) {
        return Map<String, dynamic>.from(raw);
      }

      if (raw is List<int>) {
        final text = utf8.decode(raw, allowMalformed: true).trim();
        if (text.isEmpty) return null;

        final decoded = jsonDecode(text);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      }

      if (raw is String) {
        final text = raw.trim();
        if (text.isEmpty) return null;

        final decoded = jsonDecode(text);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      }
    } catch (_) {
      return null;
    }

    return null;
  }
}