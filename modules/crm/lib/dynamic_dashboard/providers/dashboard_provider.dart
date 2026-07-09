import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crm/crm_urls.dart';
import 'package:crm/shared/models/clients_model.dart';
import 'package:crm/dynamic_dashboard/models/agent_dashboard_model.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/platform/url.dart';

/// Service remains unchanged
class DashboardService {
  static Future<DashboardMetrics?> getDashboard({
    required Ref ref,
    String period = 'month',
    int? year,
    int? month,
    bool compareToPrevious = true,
    int? viewerTypeId,
    String? transactionStatusFilter,
    String? commissionDisplay,
  }) async {
    final now = DateTime.now();
    final params = {
      'period': period,
      'year': (year ?? now.year).toString(),
      if (period == 'month') 'month': (month ?? now.month).toString(),
      'compare_to_previous': compareToPrevious.toString(),
      if (viewerTypeId != null) 'viewer_type_id': viewerTypeId.toString(),
      if (transactionStatusFilter != null) 'transaction_status_filter': transactionStatusFilter,
      if (commissionDisplay != null) 'commission_display': commissionDisplay,
    };

    final response = await ApiServices.get(
      CrmUrls.agentDashboard,
      queryParameters: params,
      ref: ref,
      hasToken: true,
    );

    if (response?.data != null) {
      final decoded = response!.data is List<int>
          ? jsonDecode(utf8.decode(response.data))
          : response.data;
      return DashboardMetrics.fromJson(decoded);
    }
    return null;
  }
}

/// ✅ DashboardParams model
class DashboardParams {
  final String period;
  final int year;
  final int? month;
  final bool compareToPrevious;
  final int? viewerTypeId;
  final String? transactionStatusFilter;
  final String? commissionDisplay;

  DashboardParams({
    required this.period,
    required this.year,
    this.month,
    this.compareToPrevious = true,
    this.viewerTypeId,
    this.transactionStatusFilter,
    this.commissionDisplay,
  });
}

/// ✅ Dashboard Params State Provider
final dashboardParamsProvider = StateProvider<DashboardParams>((ref) {
  final now = DateTime.now();
  return DashboardParams(
    period: 'month',
    year: now.year,
    month: now.month,
  );
});

/// ✅ Dashboard Data Provider
final dashboardProvider = FutureProvider<DashboardMetrics?>((ref) async {
  final params = ref.watch(dashboardParamsProvider);
  return DashboardService.getDashboard(
    ref: ref,
    period: params.period,
    year: params.year,
    month: params.month,
    compareToPrevious: params.compareToPrevious,
    viewerTypeId: params.viewerTypeId,
    transactionStatusFilter: params.transactionStatusFilter,
    commissionDisplay: params.commissionDisplay,
  );
});

/// ✅ Recent Contacts Provider (unchanged)
final recentContactsProvider = FutureProvider<List<UserContactModel>>((ref) async {
  final response = await ApiServices.get(
    URLs.userContacts,
    queryParameters: {'sort': '-created_at', 'page_size': '4'},
    hasToken: true,
    ref: ref,
  );

  final decoded = response?.data is List<int>
      ? jsonDecode(utf8.decode(response!.data))
      : response?.data;

  final List<dynamic> results = decoded?['results'] ?? [];
  return results.map((json) => UserContactModel.fromJson(json)).toList();
});
