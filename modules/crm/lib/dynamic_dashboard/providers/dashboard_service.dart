import 'dart:convert';
import 'package:crm/shared/models/clients_model.dart';
import 'package:crm/crm_urls.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/platform/url.dart';
import 'package:crm/dynamic_dashboard/models/agent_dashboard_model.dart';



class DashboardService {
  static Future<DashboardMetrics?> getDashboard({
    required Ref ref,
    String period = 'month',
    int? year,
    int? month,
    bool compareToPrevious = true,
    int? viewerTypeId,
  }) async {
    final now = DateTime.now();
    final params = {
      'period': period,
      'year': (year ?? now.year).toString(),
      if (period == 'month') 'month': (month ?? now.month).toString(),
      'compare_to_previous': compareToPrevious.toString(),
      if (viewerTypeId != null) 'viewer_type_id': viewerTypeId.toString(),
    };

    final response = await ApiServices.get(
      CrmUrls.agentDashboard,
      queryParameters: params,
      ref: ref,
      hasToken: true,
    );

    if (response?.data != null) {
      dynamic decoded;
      if (response!.data is List<int>) {
        final utf8Body = utf8.decode(response.data);
        decoded = jsonDecode(utf8Body);
      } else {
        decoded = response.data;
      }

      return DashboardMetrics.fromJson(decoded);
    }

    return null;
  }

  static Future<DashboardSettings?> updateDashboardSettings({
    required DashboardSettings settings,
  }) async {
    final response = await ApiServices.patch(
      CrmUrls.agentDashboard,
      data: settings.toJson(),
      hasToken: true,
    );

    if (response?.data != null) {
      dynamic decoded;
      if (response!.data is List<int>) {
        final utf8Body = utf8.decode(response.data);
        decoded = jsonDecode(utf8Body);
      } else {
        decoded = response.data;
      }

      return DashboardSettings.fromJson(decoded['settings']);
    }

    return null;
  }
}



final recentContactsProvider = FutureProvider<List<UserContactModel>>((ref) async {
  final response = await ApiServices.get(
    URLs.userContacts,
    queryParameters: {
      'sort': '-created_at',
      'page_size': '10',
    },
    hasToken: true,
    ref: ref,
  );

  dynamic decoded;
  if (response?.data is List<int>) {
    final utf8Body = utf8.decode(response!.data);
    decoded = jsonDecode(utf8Body);
  } else {
    decoded = response?.data;
  }

  final List<dynamic> results = decoded?['results'] ?? [];
  return results.map((json) => UserContactModel.fromJson(json)).toList();
});
