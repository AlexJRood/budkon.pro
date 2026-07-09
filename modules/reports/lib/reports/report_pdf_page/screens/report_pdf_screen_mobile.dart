import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:reports/reports/all_report_page/model/report_list_model.dart';
import 'package:reports/reports/report_pdf_page/models/sample_data.dart';
import 'package:reports/reports/report_pdf_page/provider/report_pdf_provider.dart';
import 'package:reports/reports/report_pdf_page/services/pdf_generator_service.dart';
import 'package:reports/reports/report_pdf_page/widgets/pdf_report_tile.dart';
import 'package:reports/reports/report_pdf_page/widgets/report_preview_widget_mobile.dart';
import 'package:core/theme/backgroundgradient.dart';

class ReportPdfScreenMobile extends ConsumerStatefulWidget {
  final List<int>? reportIds;
  final List<ReportsListModel>? reports;
  final bool isSampleData;

  const ReportPdfScreenMobile({
    super.key,
    this.reportIds,
    this.reports,
    this.isSampleData = false,
  });

  @override
  ConsumerState<ReportPdfScreenMobile> createState() =>
      _ReportPdfScreenMobileState();
}

class _ReportPdfScreenMobileState extends ConsumerState<ReportPdfScreenMobile> {
  List<ReportsListModel>? _effectiveReports;

  @override
  void initState() {
    super.initState();

    // // Use sample data if isSampleData is true
    // if (widget.isSampleData) {
    //   _effectiveReports = SampleReportData.getSampleReportsList();
    // } else {
    //   _effectiveReports = widget.reports;
    // }

    // Auto-select first report on initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_effectiveReports != null && _effectiveReports!.isNotEmpty) {
        final firstId = _effectiveReports!.first.id;
        if (firstId != null) {
          if (widget.isSampleData) {
            // For sample data, load the corresponding PDF report directly
            final samplePdfReports = SampleReportData.getSamplePdfReports();
            if (samplePdfReports.isNotEmpty) {
              ref
                  .read(reportPdfProvider.notifier)
                  .setSampleData(firstId, samplePdfReports.first);
            }
          } else {
            ref.read(reportPdfProvider.notifier).fetchPdfReport(firstId);
          }
          // Show preview bottom sheet for first report
          //  _showPreviewBottomSheet(context, firstId);
        }
      }
    });
  }

  void _showPreviewBottomSheet(BuildContext context, int reportId) {
    final textColor = CustomColors.secondaryWidgetTextColor(context, ref);

    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder:
            (context) => Consumer(
              builder: (context, ref, child) {
                final reportState = ref.watch(reportPdfProvider);

                return Scaffold(
                  backgroundColor: CustomColors.secondaryWidgetColor(
                    context,
                    ref,
                  ),
                  appBar: AppBar(
                    backgroundColor: CustomColors.secondaryWidgetColor(
                      context,
                      ref,
                    ),
                    elevation: 0,
                    leading: IconButton(
                      icon: Icon(Icons.close, color: textColor),
                      onPressed: () => Navigator.pop(context),
                    ),
                    title: Text(
                      'Report Preview',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    actions: [
                      IconButton(
                        icon: Icon(Icons.download, color: textColor),
                        onPressed: () async {
                          if (reportState.pdfReportData != null) {
                            try {
                              final pdfBytes = await PdfGeneratorService()
                                  .generateReportPdf(
                                    reportState.pdfReportData!,
                                  );
                              await Printing.sharePdf(
                                bytes: pdfBytes,
                                filename: 'report_$reportId.pdf',
                              );
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error generating PDF: $e'),
                                  ),
                                );
                              }
                            }
                          }
                        },
                        tooltip: 'Download Report',
                      ),
                    ],
                  ),
                  body: _buildPreviewContent(
                    reportState,
                    textColor,
                    ScrollController(),
                  ),
                );
              },
            ),
      ),
    );
  }

  Widget _buildPreviewContent(
    ReportPdfState reportState,
    Color textColor,
    ScrollController scrollController,
  ) {
    if (reportState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (reportState.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: textColor.withAlpha(76),
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading report',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                reportState.errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: textColor.withAlpha(153),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (reportState.pdfReportData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: textColor.withAlpha(76),
            ),
            const SizedBox(height: 16),
            Text(
              'Select a report to view details',
              style: TextStyle(fontSize: 16, color: textColor.withAlpha(153)),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      controller: scrollController,
      child: ReportPreviewWidgetMobile(reportData: reportState.pdfReportData!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = CustomColors.secondaryWidgetTextColor(context, ref);

    return Padding(
      padding: const EdgeInsets.only(top: 50.0),
      child: _buildReportsList(textColor),
    );
  }

  Widget _buildReportsList(Color textColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      child:
          _effectiveReports == null || _effectiveReports!.isEmpty
              ? Center(
                child: Text(
                  'No reports available',
                  style: TextStyle(color: textColor.withAlpha(153)),
                ),
              )
              : ListView.builder(
                itemCount: _effectiveReports!.length,
                itemBuilder: (context, index) {
                  final report = _effectiveReports![index];
                  final reportState = ref.watch(reportPdfProvider);
                  final isSelected = reportState.selectedReportId == report.id;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: PdfReportTile(
                      model: report,
                      isSelected: isSelected,
                      onTap: () {
                        if (report.id != null) {
                          if (widget.isSampleData) {
                            // For sample data, load the corresponding PDF report
                            final samplePdfReports =
                                SampleReportData.getSamplePdfReports();
                            if (index < samplePdfReports.length) {
                              ref
                                  .read(reportPdfProvider.notifier)
                                  .setSampleData(
                                    report.id!,
                                    samplePdfReports[index],
                                  );
                            }
                          } else {
                            ref
                                .read(reportPdfProvider.notifier)
                                .selectReport(report.id!);
                          }
                          // Show bottom sheet with preview
                          _showPreviewBottomSheet(context, report.id!);
                        }
                      },
                    ),
                  );
                },
              ),
    );
  }
}
