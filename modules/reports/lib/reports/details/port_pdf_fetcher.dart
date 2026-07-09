import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reports/reports/details/report_details.dart';
import 'package:reports/reports/details/single_report_pdf_fetcher.dart';

class SingleReportPdfFetcher extends ConsumerWidget {
  final int reportId;

  const SingleReportPdfFetcher({
    super.key,
    required this.reportId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(singleReportPdfProvider(reportId));

    return asyncData.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        body: Center(
          child: Text('Error loading report: $error'),
        ),
      ),
      data: (data) {
        return SingleReportResultAll(
          reportId: reportId,
          reportPdfData: data,
        );
      },
    );
  }
}