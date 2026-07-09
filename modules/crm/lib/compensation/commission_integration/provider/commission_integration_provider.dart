import "dart:convert";

import "package:crm/compensation/commission_integration/models/commission_integration_models.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:core/platform/api_services.dart";

class CommissionIntegrationUrls {
  static const String base =
      "/finance/compensation/real-estate/";

  static String syncTransaction(int transactionId) {
    return "${base}transactions/$transactionId/sync-commission/";
  }

  static String syncInvoice(int revenueId) {
    return "${base}invoices/$revenueId/sync-commission/";
  }

  static String assignInvoiceToTransaction(int revenueId) {
    return "${base}invoices/$revenueId/assign-transaction/";
  }
}

class CommissionIntegrationApi {
  final Ref ref;

  const CommissionIntegrationApi(this.ref);

  Future<CommissionSummaryModel> syncTransaction(
    int transactionId,
  ) async {
    final response = await ApiServices.post(
      CommissionIntegrationUrls.syncTransaction(transactionId),
      data: const <String, dynamic>{},
      ref: ref,
      hasToken: true,
    );

    final json = _responseMap(
      response?.data,
      statusCode: response?.statusCode,
    );

    return CommissionSummaryModel.fromJson(
      _asMap(json["commission_summary"]),
    );
  }

  Future<CommissionSummaryModel> syncInvoice(
    int revenueId,
  ) async {
    final response = await ApiServices.post(
      CommissionIntegrationUrls.syncInvoice(revenueId),
      data: const <String, dynamic>{},
      ref: ref,
      hasToken: true,
    );

    final json = _responseMap(
      response?.data,
      statusCode: response?.statusCode,
    );

    return CommissionSummaryModel.fromJson(
      _asMap(json["commission_summary"]),
    );
  }

  Future<CommissionSummaryModel> assignInvoiceToTransaction({
    required int revenueId,
    required int transactionId,
  }) async {
    final response = await ApiServices.post(
      CommissionIntegrationUrls.assignInvoiceToTransaction(revenueId),
      data: {
        "transaction_id": transactionId,
      },
      ref: ref,
      hasToken: true,
    );

    final json = _responseMap(
      response?.data,
      statusCode: response?.statusCode,
    );

    return CommissionSummaryModel.fromJson(
      _asMap(json["commission_summary"]),
    );
  }
}

final commissionIntegrationApiProvider =
    Provider<CommissionIntegrationApi>(
  (ref) => CommissionIntegrationApi(ref),
);

class CommissionActionState {
  final bool isLoading;
  final String? actionKey;
  final Object? error;

  const CommissionActionState({
    this.isLoading = false,
    this.actionKey,
    this.error,
  });

  CommissionActionState copyWith({
    bool? isLoading,
    String? actionKey,
    Object? error,
    bool clearError = false,
  }) {
    return CommissionActionState(
      isLoading: isLoading ?? this.isLoading,
      actionKey: actionKey ?? this.actionKey,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class CommissionActionNotifier
    extends StateNotifier<CommissionActionState> {
  final CommissionIntegrationApi api;

  CommissionActionNotifier(this.api)
      : super(const CommissionActionState());

  Future<CommissionSummaryModel> syncTransaction(
    int transactionId,
  ) {
    return _run(
      actionKey: "transaction:$transactionId",
      action: () => api.syncTransaction(transactionId),
    );
  }

  Future<CommissionSummaryModel> syncInvoice(
    int revenueId,
  ) {
    return _run(
      actionKey: "invoice:$revenueId",
      action: () => api.syncInvoice(revenueId),
    );
  }

  Future<CommissionSummaryModel> assignInvoiceToTransaction({
    required int revenueId,
    required int transactionId,
  }) {
    return _run(
      actionKey: "invoice-assignment:$revenueId",
      action: () => api.assignInvoiceToTransaction(
        revenueId: revenueId,
        transactionId: transactionId,
      ),
    );
  }

  Future<CommissionSummaryModel> _run({
    required String actionKey,
    required Future<CommissionSummaryModel> Function() action,
  }) async {
    state = CommissionActionState(
      isLoading: true,
      actionKey: actionKey,
    );

    try {
      final result = await action();
      state = const CommissionActionState();
      return result;
    } catch (error) {
      state = CommissionActionState(error: error);
      rethrow;
    }
  }
}

final commissionActionProvider = StateNotifierProvider<
    CommissionActionNotifier,
    CommissionActionState>(
  (ref) => CommissionActionNotifier(
    ref.watch(commissionIntegrationApiProvider),
  ),
);

Map<String, dynamic> _responseMap(
  dynamic raw, {
  required int? statusCode,
}) {
  dynamic normalized = raw;

  if (normalized is List<int>) {
    normalized = jsonDecode(utf8.decode(normalized));
  }

  if (normalized is String) {
    final value = normalized.trim();
    normalized = value.isEmpty ? <String, dynamic>{} : jsonDecode(value);
  }

  final map = _asMap(normalized);

  if (statusCode == null || statusCode < 200 || statusCode >= 300) {
    final detail = map["detail"] ?? map["error"] ?? map;
    throw Exception(detail.toString());
  }

  return map;
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }

  return <String, dynamic>{};
}
