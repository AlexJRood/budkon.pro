import 'dart:convert';
import 'package:reports/reports_urls.dart';
import 'dart:typed_data';
import 'dart:developer' as developer;

import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:lottie/lottie.dart';
import 'package:reports/reports/all_report_page/model/report_list_model.dart';
import 'package:core/platform/api_services.dart';

import 'package:reports/reports/comparison_result_report/result_report_all.dart';

final compareReportsProvider = FutureProvider.family<
  List<ReportsListModel>,
  List<int>
>((ref, reportIds) async {
  developer.log(
    "🔍 [compareReportsProvider] Starting fetch for IDs: $reportIds",
    name: "CompareReportsProvider",
  );

  if (reportIds.isEmpty || reportIds.length > 3) {
    developer.log(
      "❌ Invalid number of report IDs: ${reportIds.length}. Must be 1-3 IDs.",
      name: "CompareReportsProvider",
    );
    throw Exception(
      'Invalid number of report IDs. Must provide 1-3 report IDs.',
    );
  }

  try {
    // Fetch each report individually
    List<ReportsListModel> reports = [];

    for (int reportId in reportIds) {
      final url = ReportsUrls.singleReport(reportId); // Assuming this URL exists

      developer.log(
        "📌 Fetching report ID: $reportId from URL: $url",
        name: "CompareReportsProvider",
      );

      final response = await ApiServices.get(ref: ref, url, hasToken: true);

      if (response == null) {
        developer.log(
          "❌ Response is null for report ID: $reportId",
          name: "CompareReportsProvider",
        );
        throw Exception('Null response from API for report ID: $reportId');
      }

      developer.log(
        "📄 Status Code: ${response.statusCode} for report ID: $reportId",
        name: "CompareReportsProvider",
      );

      ReportsListModel report;

      if (response.data is Uint8List) {
        developer.log(
          "📦 Data is Uint8List for report ID:  — decoding...",
          name: "CompareReportsProvider",
        );
        String jsonString = utf8.decode(response.data);
        final decodedJson = jsonDecode(jsonString) as Map<String, dynamic>;
        report = ReportsListModel.fromJson(decodedJson);
        developer.log(
          "decoded json ${decodedJson.toString()}",
          name: "CompareReportsProvider",
        );
      } else if (response.data is Map<String, dynamic>) {
        developer.log(
          "📦 Data is Map<String, dynamic> for report ID: $reportId",
          name: "CompareReportsProvider",
        );
        report = ReportsListModel.fromJson(response.data);
      } else {
        developer.log(
          "⚠️ Unexpected response data type for report ID: $reportId: ${response.data.runtimeType}",
          name: "CompareReportsProvider",
        );
        throw Exception('Unexpected response format for report ID: $reportId');
      }

      reports.add(report);
    }

    developer.log(
      "✅ Successfully fetched ${reports.length} reports",
      name: "CompareReportsProvider",
    );
    return reports;
  } catch (e, stack) {
    developer.log(
      "💥 Exception: $e",
      error: e,
      stackTrace: stack,
      name: "CompareReportsProvider",
    );
    rethrow;
  }
});

class ReportComparisonFetcher extends ConsumerWidget {
  final List<int> reportIds;

  const ReportComparisonFetcher({super.key, required this.reportIds});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Validate report IDs
    if (reportIds.isEmpty || reportIds.length > 3) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
               'invalid_report_ids'.tr,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                  reportIds.isEmpty
                    ? 'no_report_ids_provided'.tr
                    : 'too_many_report_ids'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Go Back'.tr),
              ),
            ],
          ),
        ),
      );
    }

    final reportsAsyncValue = ref.watch(compareReportsProvider(reportIds));

    return reportsAsyncValue.when(
      data: (reports) {
        developer.log(
          "🎯 Reports loaded successfully, passing to ResultReportPc",
          name: "ReportComparisonFetcher",
        );
        return ResultReportAll(reports: reports,reportIds: reportIds);
      },
      loading:
          () => BarManager(
            appModule: AppModule.portal,
            isTopAppBarHoveroverUI: true,
            sideMenuKey: GlobalKey<SideMenuState>(),
            childMobile: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset(
                    'assets/lottie/loading.json',
                    width: 120,
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'loading_reports_for_comparison'.tr,
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            childPc: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset(
                    'assets/lottie/loading.json',
                    width: 120,
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'loading_reports_for_comparison'.tr,
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
      error: (error, stack) {
        developer.log(
          "❌ Error in ReportComparisonFetcher: $error",
          name: "ReportComparisonFetcher",
        );
        return BarManager(
          appModule: AppModule.portal,
          isTopAppBarHoveroverUI: true,
          sideMenuKey: GlobalKey<SideMenuState>(),
          isChildExpanded: true,
          childPc: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.asset(
                  'assets/lottie/file_error.json',
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: 16),
                Text(
                 'error_loading_reports'.tr,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'failed_to_load_reports_for_comparison'.tr + error.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Go Back'.tr),
                ),
              ],
            ),
          ),
          childMobile: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.asset(
                  'assets/lottie/file_error.json',
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: 16),
                Text(
                 'error_loading_reports'.tr,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                 'failed_to_load_reports_for_comparison'.tr + error.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Go Back'.tr),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
