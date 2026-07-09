import 'dart:convert';
import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reports/reports/all_report_page/model/report_list_model.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/platform/url.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';

// State for compare reports
class CompareReportsState {
  final List<ReportsListModel> reports;
  final bool isLoading;
  final String? error;

  CompareReportsState({
    this.reports = const [],
    this.isLoading = false,
    this.error,
  });

  CompareReportsState copyWith({
    List<ReportsListModel>? reports,
    bool? isLoading,
    String? error,
  }) {
    return CompareReportsState(
      reports: reports ?? this.reports,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Provider for compare reports API
final compareReportsProvider =
    StateNotifierProvider<CompareReportsNotifier, CompareReportsState>((ref) {
  return CompareReportsNotifier(ref);
});

class CompareReportsNotifier extends StateNotifier<CompareReportsState> {
  final Ref ref;

  CompareReportsNotifier(this.ref) : super(CompareReportsState());

  /// Fetch compare reports by list of IDs (min 1, max 3)
  Future<void> fetchCompareReports(List<int> reportIds) async {
    if (reportIds.isEmpty || reportIds.length > 3) {
      state = state.copyWith(
        error: 'please_select_between_1_and_3_reports_to_compare'.tr,
        isLoading: false,
      );
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      log('Fetching compare reports for IDs: $reportIds');
      
      final url = URLs.buildCompareReportUrl(reportIds);
      log('Compare reports URL: $url');
      
      final response = await ApiServices.get(ref: ref, url, hasToken: true);

      if (response != null && response.statusCode == 200) {
        final decodedBody = utf8.decode(response.data);
        final List<dynamic> reportsJson = json.decode(decodedBody) as List<dynamic>;
        
        log('Compare reports API response: ${reportsJson.length} reports found');
        
        final reports = reportsJson
            .map((json) => ReportsListModel.fromJson(json as Map<String, dynamic>))
            .toList();
        
        state = state.copyWith(
          reports: reports,
          isLoading: false,
          error: null,
        );
        
        log('Successfully loaded ${reports.length} compare reports');
      } else {
       final errorMessage = 'failed_to_load_compare_reports_status'.tr + (response?.statusCode?.toString() ?? '');
        log(errorMessage);
        state = state.copyWith(
          error: errorMessage,
          isLoading: false,
        );
      }
    } catch (error, stackTrace) {
      log('Exception in fetchCompareReports: $error', stackTrace: stackTrace);
      state = state.copyWith(
        error: 'error_loading_compare_reports_exception'.tr + error.toString(),
        isLoading: false,
      );
    }
  }

  /// Set reports data directly (for pre-fetched data)
  void setReports(List<ReportsListModel> reports) {
    state = state.copyWith(
      reports: reports,
      isLoading: false,
      error: null,
    );
  }

  /// Clear compare reports data
  void clearReports() {
    state = CompareReportsState();
  }

  /// Refresh compare reports with same IDs
  Future<void> refresh() async {
    if (state.reports.isNotEmpty) {
      final reportIds = state.reports.map((r) => r.id!).toList();
      await fetchCompareReports(reportIds);
    }
  }
}

/// Convenience provider for getting selected report IDs from compare popup
final selectedCompareReportIdsProvider = StateProvider<List<int>>((ref) => []);

/// Provider for fetching compare reports based on selected IDs
final autoCompareReportsProvider = Provider<AsyncValue<List<ReportsListModel>>>((ref) {
  final selectedIds = ref.watch(selectedCompareReportIdsProvider);
  final compareState = ref.watch(compareReportsProvider);
  
  if (selectedIds.isEmpty) {
    return const AsyncValue.data([]);
  }
  
  if (compareState.isLoading) {
    return const AsyncValue.loading();
  }
  
  if (compareState.error != null) {
    return AsyncValue.error(compareState.error!, StackTrace.current);
  }
  
  return AsyncValue.data(compareState.reports);
});
