import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:printing/printing.dart';
import 'package:core/ui/buttons/app_buttons.dart';
import 'package:core/theme/backgroundgradient.dart';

import '../../all_report_page/model/report_list_model.dart';
import '../models/sample_data.dart';
import '../provider/report_pdf_provider.dart';
import '../services/pdf_generator_service.dart';
import '../widgets/pdf_report_tile.dart';
import '../widgets/report_preview_widget.dart';

class ReportPdfScreenTablet extends ConsumerStatefulWidget {
  final List<int>? reportIds;
  final List<ReportsListModel>? reports;
  final bool isSampleData;

  const ReportPdfScreenTablet({
    super.key,
    this.reportIds,
    this.reports,
    this.isSampleData = false,
  });

  @override
  ConsumerState<ReportPdfScreenTablet> createState() =>
      _ReportPdfScreenTabletState();
}

class _ReportPdfScreenTabletState
    extends ConsumerState<ReportPdfScreenTablet> {

  List<ReportsListModel>? _effectiveReports;

  @override
  void initState() {
    super.initState();
    _syncReports();
    _selectFirstReport();
  }

  @override
  void didUpdateWidget(covariant ReportPdfScreenTablet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reports != widget.reports ||
        oldWidget.isSampleData != widget.isSampleData) {
      _syncReports();
      _selectFirstReport();
    }
  }

  void _syncReports() {
    if (widget.isSampleData) {
      _effectiveReports = SampleReportData.getSampleReportsList();
    } else {
      _effectiveReports = widget.reports;
    }
  }

  void _selectFirstReport() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final reports = _effectiveReports;
      if (reports == null || reports.isEmpty) return;

      final firstId = reports.first.id;
      if (firstId == null) return;

      if (widget.isSampleData) {
        final samplePdfReports = SampleReportData.getSamplePdfReports();
        if (samplePdfReports.isNotEmpty) {
          ref.read(reportPdfProvider.notifier).setSampleData(
            firstId,
            samplePdfReports.first,
          );
        }
      } else {
        ref.read(reportPdfProvider.notifier).fetchPdfReport(firstId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final reportState = ref.watch(reportPdfProvider);
    final textColor = CustomColors.secondaryWidgetTextColor(context, ref);

    return Row(
      children: [
        Container(
          width: 320,
          decoration: BoxDecoration(
            color: CustomColors.secondaryWidgetColor(context, ref),
            border: Border(
              right: BorderSide(
                color: textColor.withOpacity(0.08),
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: textColor),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Reports'.tr,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_effectiveReports?.length ?? 0} ${'available_reports'.tr}',
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor.withOpacity(0.65),
                        ),
                      ),
                    ),
                    SettingsButton(
                      isPc: false,
                      buttonheight: 32,
                      onTap: () => reportState.pdfReportData == null
                          ? null
                          : () async {
                        final pdfBytes = await PdfGeneratorService()
                            .generateReportPdf(reportState.pdfReportData!);
                        await Printing.sharePdf(
                          bytes: pdfBytes,
                          filename:
                          'report_${reportState.selectedReportId ?? "preview"}.pdf',
                        );
                      },
                      text: "Download PDF".tr,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _effectiveReports == null || _effectiveReports!.isEmpty
                    ? Center(
                  child: Text(
                    'No reports available'.tr,
                    style: TextStyle(
                      color: textColor.withOpacity(0.6),
                    ),
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _effectiveReports!.length,
                  itemBuilder: (context, index) {
                    final report = _effectiveReports![index];
                    final isSelected =
                        reportState.selectedReportId == report.id;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: PdfReportTile(
                        model: report,
                        isSelected: isSelected,
                        onTap: () {
                          if (report.id == null) return;

                          if (widget.isSampleData) {
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
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: _buildPreviewPanel(reportState, textColor),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewPanel(ReportPdfState reportState, Color textColor) {
    if (reportState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (reportState.errorMessage != null) {
      return Center(child: Text(reportState.errorMessage!));
    }

    if (reportState.pdfReportData == null) {
      return Center(
        child: Text(
          'select_a_report_to_view_details'.tr,
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ReportPreviewWidget(
          reportData: reportState.pdfReportData!,
        ),
      ),
    );
  }
}