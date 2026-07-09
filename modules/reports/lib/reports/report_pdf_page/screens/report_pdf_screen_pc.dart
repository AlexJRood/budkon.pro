import 'package:core/ui/anchors/anchor_target.dart';
import 'package:core/ui/anchors/anchor_spec.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:printing/printing.dart';
import 'package:reports/emma/anchors/anchors_reports.dart';
import 'package:reports/reports/all_report_page/model/report_list_model.dart';
import 'package:reports/reports/report_pdf_page/models/sample_data.dart';
import 'package:reports/reports/report_pdf_page/provider/report_pdf_provider.dart';
import 'package:reports/reports/report_pdf_page/services/pdf_generator_service.dart';
import 'package:reports/reports/report_pdf_page/widgets/pdf_report_tile.dart';
import 'package:reports/reports/report_pdf_page/widgets/report_preview_widget.dart';
import 'package:reports/reports/report_pdf_page/widgets/report_share_bottom_sheet.dart';
import 'package:reports/reports/report_pdf_page/widgets/report_share_dialog.dart';
import 'package:reports/reports/report_editor/provider/report_template_provider.dart';
import 'package:reports/reports/report_editor/report_editor_all.dart';
import 'package:core/ui/buttons/app_buttons.dart';
import 'package:core/theme/backgroundgradient.dart';

class ReportPdfScreenPc extends ConsumerStatefulWidget {
  final List<int>? reportIds;
  final List<ReportsListModel>? reports;
  final bool isSampleData;

  const ReportPdfScreenPc({
    super.key,
    this.reportIds,
    this.reports,
    this.isSampleData = false,
  });

  @override
  ConsumerState<ReportPdfScreenPc> createState() => _ReportPdfScreenPcState();
}

class _ReportPdfScreenPcState extends ConsumerState<ReportPdfScreenPc> {
  List<ReportsListModel>? _effectiveReports;

  @override
  void initState() {
    super.initState();
    _syncReports();
    _selectFirstReport();
  }

  @override
  void didUpdateWidget(covariant ReportPdfScreenPc oldWidget) {
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

    return EmmaUiAnchorTarget(
      // @emma-backend: EmmaAnchors.reportsPdfRoot
      anchorKey: EmmaAnchors.reportsPdfRoot.anchorKey,

      spec: EmmaAnchors.reportsPdfRoot,
      runtimeMode: EmmaUiAnchorRuntimeMode.always,
      tapMode: EmmaUiAnchorTapMode.disabled,
      child: Row(
      children: [
        Container(
          width: 460,
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
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: textColor),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Reports'.tr,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_effectiveReports?.length ?? 0} ${'available_reports'.tr}',
                        style: TextStyle(
                          fontSize: 13,
                          color: textColor.withOpacity(0.65),
                        ),
                      ),
                    ),
                    if (reportState.pdfReportData != null &&
                        reportState.selectedReportId != null) ...[
                      EmmaUiAnchorTarget(
                        // @emma-backend: EmmaAnchors.reportsPdfShareButton
                        anchorKey: EmmaAnchors.reportsPdfShareButton.anchorKey,

                        spec: EmmaAnchors.reportsPdfShareButton,
                        tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
                        child: _ShareButton(
                          reportId: reportState.selectedReportId!,
                          reportState: reportState,
                          onShareClient: () => ReportShareDialog.show(
                            context,
                            reportState.selectedReportId!,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    EmmaUiAnchorTarget(
                      // @emma-backend: EmmaAnchors.reportsPdfDownloadButton
                      anchorKey: EmmaAnchors.reportsPdfDownloadButton.anchorKey,

                      spec: EmmaAnchors.reportsPdfDownloadButton,
                      tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
                      child: SettingsButton(
                      isPc: true,
                      buttonheight: 34,
                      onTap: () => reportState.pdfReportData == null
                          ? null
                          : () async {
                              try {
                                final template = ref.read(activeReportTemplateProvider).valueOrNull;
                                final pdfBytes = await PdfGeneratorService()
                                    .generateReportPdf(
                                  reportState.pdfReportData!,
                                  template: template,
                                );
                                await Printing.sharePdf(
                                  bytes: pdfBytes,
                                  filename:
                                      'report_${reportState.selectedReportId ?? "preview"}.pdf',
                                );
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('error_generating_pdf'.trParams({'error': e.toString()})),
                                  ),
                                );
                              }
                            },
                      text: "Download PDF".tr,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'customize_report'.tr,
                      icon: Icon(Icons.tune, color: textColor),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ReportEditorAll(),
                        ),
                      ),
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
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _effectiveReports!.length,
                        itemBuilder: (context, index) {
                          final report = _effectiveReports![index];
                          final isSelected =
                              reportState.selectedReportId == report.id;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
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
            padding: const EdgeInsets.all(12),
            child: _buildPreviewPanel(reportState, textColor),
          ),
        ),
      ],
      ),
    );
  }

  Widget _buildPreviewPanel(ReportPdfState reportState, Color textColor) {
    if (reportState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (reportState.errorMessage != null) {
      return Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: textColor.withOpacity(0.08),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.redAccent.withOpacity(0.8),
              ),
              const SizedBox(height: 16),
              Text(
                'error_loading_report'.tr,
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
                  color: textColor.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () {
                  ref.read(reportPdfProvider.notifier).refresh();
                },
                icon: const Icon(Icons.refresh),
                label: Text('Retry'.tr),
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
              color: textColor.withOpacity(0.25),
            ),
            const SizedBox(height: 16),
            Text(
              'select_a_report_to_view_details'.tr,
              style: TextStyle(
                fontSize: 16,
                color: textColor.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980),
        child: ReportPreviewWidget(
          reportData: reportState.pdfReportData!,
        ),
      ),
    );
  }
}

// ── share button ─────────────────────────────────────────────────────────────

class _ShareButton extends ConsumerWidget {
  final int reportId;
  final ReportPdfState reportState;
  final VoidCallback? onShareClient;

  const _ShareButton({
    required this.reportId,
    required this.reportState,
    this.onShareClient,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Original share button (e.g. share PDF via OS)
        GestureDetector(
          onTap: () {
            if (reportState.pdfReportData == null) return;
            showReportShareSheet(
              context,
              ref,
              reportId: reportId,
              reportData: reportState.pdfReportData!,
            );
          },
          child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF5FCDD9).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF5FCDD9).withOpacity(0.3),
          ),
        ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.share_outlined, size: 16, color: Color(0xFF2FB8C6)),
              const SizedBox(width: 6),
              Text(
                'Share'.tr,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2FB8C6)),
              ),
            ],
          ),
        ),
      ),
      // Client share link button
      if (onShareClient != null) ...[
        const SizedBox(width: 6),
        GestureDetector(
          onTap: onShareClient,
          child: Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF5FCDD9).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF5FCDD9).withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.link, size: 16, color: Color(0xFF2FB8C6)),
                const SizedBox(width: 6),
                Text(
                  'share_with_client'.tr,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2FB8C6)),
                ),
              ],
            ),
          ),
        ),
      ],
    ]);
  }
}