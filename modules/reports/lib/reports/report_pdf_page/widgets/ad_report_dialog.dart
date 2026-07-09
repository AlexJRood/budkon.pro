import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:printing/printing.dart';
import 'package:reports/reports/report_pdf_page/provider/ad_report_dialog_provider.dart';
import 'package:reports/reports/report_pdf_page/services/pdf_generator_service.dart';
import 'package:reports/reports/report_pdf_page/widgets/report_preview_widget.dart';
import 'package:reports/reports/report_pdf_page/widgets/report_preview_widget_mobile.dart';
import 'package:core/ui/buttons/app_buttons.dart';
import 'package:core/theme/backgroundgradient.dart';

class AdReportDialog extends ConsumerStatefulWidget {
  final int advertisementId;
  final bool isNm;
  final int? nmAdid;

  const AdReportDialog({
    super.key,
    required this.advertisementId,
    this.isNm = false,
    this.nmAdid,
  });

  @override
  ConsumerState<AdReportDialog> createState() => _AdReportDialogState();
}

class _AdReportDialogState extends ConsumerState<AdReportDialog> {
  int get _effectiveSourceId {
    if (widget.isNm) {
      if ((widget.nmAdid ?? 0) > 0) {
        return widget.nmAdid!;
      }
      return widget.advertisementId;
    }
    return widget.advertisementId;
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sourceId = _effectiveSourceId;

      ref.read(adReportDialogProvider.notifier).createAndFetchReport(
            sourceId,
            isNm: widget.isNm,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adReportDialogProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 800;
    final canDownloadPdf = state.isSuccess && state.pdfReportData != null;

    final dialogWidth = (screenWidth * 0.92).clamp(320.0, 1250.0);
    final dialogHeight = (screenHeight * 0.9).clamp(420.0, 900.0);

    return Container(
      width: dialogWidth,
      height: dialogHeight,
      decoration: BoxDecoration(
        color: CustomColors.secondaryWidgetColor(context, ref),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Text(
                  'Property Report'.tr,
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 20,
                    fontWeight: FontWeight.w700,
                    color: CustomColors.secondaryWidgetTextColor(context, ref),
                  ),
                ),
                const Spacer(),
                if (canDownloadPdf)
                  SettingsButton(
                    isPc: true,
                    buttonheight: 34,
                    onTap: () async {
                      try {
                        final pdfBytes = await PdfGeneratorService()
                            .generateReportPdf(state.pdfReportData!);
                        await Printing.sharePdf(
                          bytes: pdfBytes,
                          filename:
                              'property_report_${state.reportId ?? "preview"}.pdf',
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('error_generating_pdf'.trParams({'error': e.toString()})),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    text: "Download PDF".tr,
                  ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close,
                    color: CustomColors.secondaryWidgetTextColor(context, ref),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildContent(state, isMobile),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AdReportDialogState state, bool isMobile) {
    if (state.isCreatingReport) {
      return _buildLoadingState(
        'creating_report'.tr,
        'Please wait while we generate your property report.'.tr,
        isMobile,
      );
    }

    if (state.isFetchingPdfData) {
      return _buildLoadingState(
        'Fetching report data...'.tr,
        'Loading detailed report information.'.tr,
        isMobile,
      );
    }

    if (state.hasError) {
      return _buildErrorState(
        state.errorMessage ?? 'An error occurred'.tr,
        isMobile,
      );
    }

    if (state.isSuccess && state.pdfReportData != null) {
      if (isMobile) {
        return ReportPreviewWidgetMobile(
          reportData: state.pdfReportData!,
          isDialog: true,
        );
      }

      return ReportPreviewWidget(
        reportData: state.pdfReportData!,
        isDialog: true,
        onClose: () => Navigator.of(context).pop(),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildLoadingState(String title, String subtitle, bool isMobile) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5FCDD9)),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: isMobile ? 18 : 20,
                fontWeight: FontWeight.w700,
                color: CustomColors.secondaryWidgetTextColor(context, ref),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF6B6B6B),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String errorMessage, bool isMobile) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: isMobile ? 64 : 80,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Something went wrong'.tr,
              style: TextStyle(
                fontSize: isMobile ? 20 : 24,
                fontWeight: FontWeight.bold,
                color: CustomColors.secondaryWidgetTextColor(context, ref),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF6B6B6B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(adReportDialogProvider.notifier).createAndFetchReport(
                      _effectiveSourceId,
                      isNm: widget.isNm,
                    );
              },
              icon: const Icon(Icons.refresh),
              label: Text('Retry'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5FCDD9),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}