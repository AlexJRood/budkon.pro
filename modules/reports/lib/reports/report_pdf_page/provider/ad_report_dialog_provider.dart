import 'dart:convert';
import 'package:reports/reports_urls.dart';
import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:reports/reports/report_pdf_page/models/pdf_report_model.dart';
import 'package:core/platform/api_services.dart';

enum AdReportDialogStatus {
  idle,
  creatingReport,
  fetchingPdfData,
  success,
  error,
}

class AdReportDialogState {
  final AdReportDialogStatus status;
  final int? reportId;
  final PdfReportModel? pdfReportData;
  final String? errorMessage;

  const AdReportDialogState({
    this.status = AdReportDialogStatus.idle,
    this.reportId,
    this.pdfReportData,
    this.errorMessage,
  });

  bool get isCreatingReport => status == AdReportDialogStatus.creatingReport;
  bool get isFetchingPdfData => status == AdReportDialogStatus.fetchingPdfData;
  bool get isLoading => isCreatingReport || isFetchingPdfData;
  bool get hasError => status == AdReportDialogStatus.error;
  bool get isSuccess => status == AdReportDialogStatus.success;

  static const Object _unset = Object();

  AdReportDialogState copyWith({
    AdReportDialogStatus? status,
    int? reportId,
    Object? pdfReportData = _unset,
    Object? errorMessage = _unset,
  }) {
    return AdReportDialogState(
      status: status ?? this.status,
      reportId: reportId ?? this.reportId,
      pdfReportData: identical(pdfReportData, _unset)
          ? this.pdfReportData
          : pdfReportData as PdfReportModel?,
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

class AdReportDialogNotifier extends StateNotifier<AdReportDialogState> {
  final Ref ref;

  bool _requestInFlight = false;

  AdReportDialogNotifier(this.ref) : super(const AdReportDialogState());

  Future<void> createAndFetchReport(
    int sourceId, {
    bool isNm = false,
  }) async {
    if (_requestInFlight) {
      log('[REPORTS]: createAndFetchReport skipped: request already in flight');
      return;
    }

    if (sourceId <= 0) {
      state = state.copyWith(
        status: AdReportDialogStatus.error,
        errorMessage:
            isNm
             ? 'invalid_network_monitoring_advertisement_id'.tr
             : 'invalid_advertisement_id'.tr,
        pdfReportData: null,
      );
      return;
    }

    _requestInFlight = true;

    log('=== createAndFetchReport START ===');
    log('[REPORTS]: Source id: $sourceId | isNm: $isNm');

    state = state.copyWith(
      status: AdReportDialogStatus.creatingReport,
      errorMessage: null,
      pdfReportData: null,
    );

    try {
      final url = isNm ? ReportsUrls.createNmReport : ReportsUrls.createAdreport;
      final data =
          isNm ? {'ads_network_id': sourceId} : {'advertisement_id': sourceId};

      final createResponse = await ApiServices.post(
        url,
        hasToken: true,
        ref: ref,
        data: data,
      );

      if (createResponse == null ||
          (createResponse.statusCode != 200 &&
              createResponse.statusCode != 201)) {
          state = state.copyWith(
          status: AdReportDialogStatus.error,
          errorMessage: 'failed_to_create_report_status'.trParams({
          'statusCode': '${createResponse?.statusCode ?? 'Unknown'.tr}' 
        }),
        );
        return;
      }

      final createJsonData = _decodeResponseToMap(createResponse.data);
      final reportId = createJsonData['id'] as int?;

      if (reportId == null || reportId <= 0) {
        state = state.copyWith(
          status: AdReportDialogStatus.error,
          errorMessage: 'report_id_not_found_in_response'.tr,
        );
        return;
      }

      state = state.copyWith(
        status: AdReportDialogStatus.fetchingPdfData,
        reportId: reportId,
      );

      final pdfResponse = await ApiServices.get(
        ReportsUrls.singlePdfReport(reportId),
        hasToken: true,
        ref: ref,
      );

      if (pdfResponse == null || pdfResponse.statusCode != 200) {
        state = state.copyWith(
          status: AdReportDialogStatus.error,
         errorMessage: 'failed_to_fetch_report_data_status'.trParams({
        'statusCode': '${pdfResponse?.statusCode ?? 'Unknown'.tr}'
}),
        );
        return;
      }

      final pdfJsonData = _decodeResponseToMap(pdfResponse.data);

      log('[REPORTS]: PDF JSON keys: ${pdfJsonData.keys.toList()}');
      log('[REPORTS]: PDF report raw: ${pdfJsonData['report']}');
      log('[REPORTS]: PDF estimation raw: ${pdfJsonData['estimation']}');
      log('[REPORTS]: PDF comparable raw count: ${(pdfJsonData['comparable'] as List?)?.length ?? 0}');

      final pdfReport = PdfReportModel.fromJson(pdfJsonData);
      state = state.copyWith(
        status: AdReportDialogStatus.success,
        pdfReportData: pdfReport,
        errorMessage: null,
      );

      log('=== createAndFetchReport SUCCESS ===');
    } catch (e, stack) {
      log('[REPORTS]: ERROR during createAndFetchReport(): $e');
      log('[REPORTS]: Stack trace: $stack');

      state = state.copyWith(
        status: AdReportDialogStatus.error,
        errorMessage: '${'Error'.tr}: $e',
      );
    } finally {
      _requestInFlight = false;
    }
  }

  void reset() {
    state = const AdReportDialogState();
    _requestInFlight = false;
  }
}

final adReportDialogProvider = StateNotifierProvider.autoDispose<
    AdReportDialogNotifier, AdReportDialogState>((ref) {
  return AdReportDialogNotifier(ref);
});