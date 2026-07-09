import 'dart:convert';
import 'package:reports/reports_urls.dart';
import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:lottie/lottie.dart';
import 'package:reports/reports/all_report_page/model/report_list_model.dart';
import 'package:reports/reports/report_pdf_page/all_report_pdf_screen.dart';
import 'package:core/platform/api_services.dart';

Map<String, dynamic> _decodeResponseToMap(dynamic data) {
  if (data is Map<String, dynamic>) {
    return data;
  }

  if (data is Uint8List) {
    return jsonDecode(utf8.decode(data)) as Map<String, dynamic>;
  }

  if (data is String) {
    return jsonDecode(data) as Map<String, dynamic>;
  }

  if (data is Map) {
    return Map<String, dynamic>.from(data);
  }

  throw Exception('Unexpected response format: ${data.runtimeType}');
}

final pdfCompareReportsProvider =
    FutureProvider.family<List<ReportsListModel>, List<int>>((ref, reportIds) async {
  final uniqueIds = reportIds.toSet().toList();

  developer.log(
    '🔍 [pdfCompareReportsProvider] Starting fetch for IDs: $uniqueIds',
    name: 'PdfCompareReportsProvider',
  );

  if (uniqueIds.isEmpty) {
    throw Exception('No report IDs provided.');
  }

  final reports = <ReportsListModel>[];

  for (final reportId in uniqueIds) {
    final url = ReportsUrls.singleReport(reportId);

    developer.log(
      '📌 Fetching report ID: $reportId from URL: $url',
      name: 'PdfCompareReportsProvider',
    );

    final response = await ApiServices.get(
      url,
      ref: ref,
      hasToken: true,
    );

    if (response == null) {
      throw Exception('Null response from API for report ID: $reportId');
    }

    developer.log(
      '📄 Status Code: ${response.statusCode} for report ID: $reportId',
      name: 'PdfCompareReportsProvider',
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to fetch report ID: $reportId. Status: ${response.statusCode}',
      );
    }

    final decodedJson = _decodeResponseToMap(response.data);
    reports.add(ReportsListModel.fromJson(decodedJson));
  }

  developer.log(
    '✅ Successfully fetched ${reports.length} reports',
    name: 'PdfCompareReportsProvider',
  );

  return reports;
});

class ReportPdfFetcher extends ConsumerWidget {
  final List<int> reportIds;

  const ReportPdfFetcher({
    super.key,
    required this.reportIds,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (reportIds.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'invalid_reports_ids'.tr,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'no_reports_ids_provided'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Go Back'.tr),
              ),
            ],
          ),
        ),
      );
    }

    final reportsAsyncValue = ref.watch(pdfCompareReportsProvider(reportIds));

    return reportsAsyncValue.when(
      data: (reports) {
        return AllReportPdfScreen(
          reportIds: reportIds,
          reports: reports,
        );
      },
      loading: () => BarManager(
        appModule: AppModule.portal,
        isTopAppBarHoveroverUI: true,
        sideMenuKey: GlobalKey<SideMenuState>(),
        childMobile: _LoadingState(
         text: 'loading_pdf_report'.tr,
        ),
        childPc: _LoadingState(
          text: 'loading_reports'.tr,
        ),
      ),
      error: (error, stack) {
        developer.log(
          '❌ Error in ReportPdfFetcher: $error',
          name: 'ReportPdfFetcher',
          error: error,
          stackTrace: stack,
        );

        return BarManager(
          appModule: AppModule.portal,
          isTopAppBarHoveroverUI: true,
          sideMenuKey: GlobalKey<SideMenuState>(),
          isChildExpanded: true,
          childPc: _ErrorState(
            title: 'error_loading_reports'.tr,
            subtitle: '${'Failed to load reports'.tr}: $error',
          ),
          childMobile: _ErrorState(
            title: 'error_loading_reports'.tr,
            subtitle: '${'Failed to load reports'.tr}: $error',
          ),
        );
      },
    );
  }
}

class _LoadingState extends StatelessWidget {
  final String text;

  const _LoadingState({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/lottie/loading.json',
            width: 120,
            height: 120,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 16),
          Text(
            text,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String title;
  final String subtitle;

  const _ErrorState({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/lottie/file_error.json',
            width: 120,
            height: 120,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Go Back'.tr),
          ),
        ],
      ),
    );
  }
}