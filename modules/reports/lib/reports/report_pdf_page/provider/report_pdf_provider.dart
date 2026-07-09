import 'dart:convert';
import 'package:reports/reports_urls.dart';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reports/reports/report_pdf_page/models/pdf_report_model.dart';
import 'package:core/platform/api_services.dart';
import 'package:get/get_utils/get_utils.dart';

class ReportPdfState {
  final int? selectedReportId;
  final PdfReportModel? pdfReportData;
  final bool isLoading;
  final String? errorMessage;

  const ReportPdfState({
    this.selectedReportId,
    this.pdfReportData,
    this.isLoading = false,
    this.errorMessage,
  });

  static const Object _unset = Object();

  ReportPdfState copyWith({
    int? selectedReportId,
    Object? pdfReportData = _unset,
    bool? isLoading,
    Object? errorMessage = _unset,
  }) {
    return ReportPdfState(
      selectedReportId: selectedReportId ?? this.selectedReportId,
      pdfReportData: identical(pdfReportData, _unset)
          ? this.pdfReportData
          : pdfReportData as PdfReportModel?,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

Map<String, dynamic> _decodeResponseToMap(dynamic data) {
  if (data is Map<String, dynamic>) {
    return data;
  }

  if (data is Uint8List) {
    return json.decode(utf8.decode(data)) as Map<String, dynamic>;
  }

  if (data is String) {
    return json.decode(data) as Map<String, dynamic>;
  }

  if (data is Map) {
    return Map<String, dynamic>.from(data);
  }

  throw Exception('Unsupported response format: ${data.runtimeType}');
}

class ReportPdfNotifier extends StateNotifier<ReportPdfState> {
  final Ref ref;

  ReportPdfNotifier(this.ref) : super(const ReportPdfState());

  Future<void> fetchPdfReport(int reportId) async {
    state = state.copyWith(
      selectedReportId: reportId,
      isLoading: true,
      errorMessage: null,
    );

    try {
      final response = await ApiServices.get(
        ReportsUrls.singlePdfReport(reportId),
        hasToken: true,
        ref: ref,
      );

      if (response != null && response.statusCode == 200) {
        final jsonData = _decodeResponseToMap(response.data);
        final pdfReport = PdfReportModel.fromJson(jsonData);

        state = state.copyWith(
          pdfReportData: pdfReport,
          isLoading: false,
          errorMessage: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
            errorMessage: '${'failed_to_load_report_data_status'.tr} ${response?.statusCode ?? 'Unknown'.tr}',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '${'error_loading_report'.tr} $e',
      );
    }
  }

  Future<void> refresh() async {
    final reportId = state.selectedReportId;
    if (reportId == null) return;
    await fetchPdfReport(reportId);
  }

  void selectReport(int reportId) {
    if (state.selectedReportId != reportId) {
      fetchPdfReport(reportId);
    }
  }

  void setSampleData(int reportId, PdfReportModel pdfReportData) {
    state = state.copyWith(
      selectedReportId: reportId,
      pdfReportData: pdfReportData,
      isLoading: false,
      errorMessage: null,
    );
  }

  void clear() {
    state = const ReportPdfState();
  }
}

final reportPdfProvider =
    StateNotifierProvider<ReportPdfNotifier, ReportPdfState>((ref) {
  return ReportPdfNotifier(ref);
});