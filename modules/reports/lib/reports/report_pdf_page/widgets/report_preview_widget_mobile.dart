import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reports/reports/report_pdf_page/models/pdf_report_model.dart';
import 'package:reports/reports/report_pdf_page/widgets/report_preview_widget.dart';

class ReportPreviewWidgetMobile extends ConsumerWidget {
  final PdfReportModel reportData;
  final bool isDialog;
  final VoidCallback? onClose;

  const ReportPreviewWidgetMobile({
    super.key,
    required this.reportData,
    this.isDialog = false,
    this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ReportPreviewWidget(
      reportData: reportData,
      isDialog: isDialog,
      onClose: onClose,
      forceMobileLayout: true,
    );
  }
}