// provider.dart

import 'dart:convert';
import 'package:crm/crm_urls.dart';

import 'package:crm/crm/finance/features/revenue/revenue_status_model.dart';
import 'package:crm/crm/finance/features/revenue/revenue_services_api.dart';
import 'package:crm/shared/models/revenue_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';

final selectedInvoiceStatusProvider = StateProvider<String>((ref) => 'All');

class InvoiceState {
  final List<AgentRevenueModel> transactions;
  final List<RevenueStatusModel> statuses;

  InvoiceState({required this.transactions, required this.statuses});
}

final invoiceProvider = StateNotifierProvider.family<
    InvoiceNotifier,
    AsyncValue<InvoiceState>,
    int>((ref, clientId) {
  final apiService = ref.watch(apiProviderRevenue);
  return InvoiceNotifier(apiService, ref, clientId);
});

class InvoiceNotifier extends StateNotifier<AsyncValue<InvoiceState>> {
  final ApiServiceRevenue apiService;
  final Ref ref;
  final int clientId;

  InvoiceNotifier(this.apiService, this.ref, this.clientId)
      : super(const AsyncLoading()) {
    fetchInvoicesAndStatuses();
  }

  int? statusUserContact;
  String? sortUserContact;
  String? searchQuery;

  Future<void> fetchInvoicesAndStatuses() async {
    try {
      final queryParams = <String, dynamic>{
        'client': clientId,
        if (statusUserContact != null) 'status': statusUserContact,
        if (sortUserContact != null) 'sort': sortUserContact,
        if (searchQuery != null && searchQuery!.isNotEmpty) 'search': searchQuery,
      };

      final transactionsResponse = await ApiServices.get(
        ref: ref,
        CrmUrls.financeAppRevenues,
        queryParameters: queryParams,
        hasToken: true,
      );

      if (transactionsResponse == null) {
        state = AsyncValue.error('No invoices response', StackTrace.current);
        return;
      }

      final decodedTransactionsBody = utf8.decode(transactionsResponse.data);
      final decodedJson = json.decode(decodedTransactionsBody);
      final decodeData =
          (decodedJson is List) ? decodedJson : (decodedJson['results'] as List);

      final transactions =
          decodeData.map((r) => AgentRevenueModel.fromJson(r)).toList();

      final statusesResponse = await ApiServices.get(
        ref: ref,
        CrmUrls.financeAppRevenuesStatus,
        hasToken: true,
      );

      if (statusesResponse == null) {
        state = AsyncValue.data(
          InvoiceState(transactions: transactions, statuses: []),
        );
        return;
      }

      final decodedStatusesBody = utf8.decode(statusesResponse.data);
      final decodedStatusesJson = json.decode(decodedStatusesBody);

      List<dynamic> decodeStatuses = [];
      if (decodedStatusesJson is List) {
        decodeStatuses = decodedStatusesJson;
      } else if (decodedStatusesJson is Map<String, dynamic>) {
        if (decodedStatusesJson.containsKey('results')) {
          decodeStatuses = decodedStatusesJson['results'] as List;
        } else if (decodedStatusesJson.containsKey('data')) {
          final dataBlock = decodedStatusesJson['data'];
          if (dataBlock is List) decodeStatuses = dataBlock;
          if (dataBlock is Map && dataBlock.containsKey('results')) {
            decodeStatuses = dataBlock['results'] as List;
          }
        }
      }

      final statuses = decodeStatuses
          .map((s) => RevenueStatusModel.fromJson(s as Map<String, dynamic>))
          .toList();

      state = AsyncValue.data(
        InvoiceState(transactions: transactions, statuses: statuses),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async => fetchInvoicesAndStatuses();

  void setSearch(String value) {
    searchQuery = value;
    fetchInvoicesAndStatuses();
  }

  // ✅ NOWE: zmiana statusu faktury (txId) na liście
  Future<void> changeInvoiceStatus({
    required int transactionId,
    required String newStatusName,
  }) async {
    final current = state;
    if (current is! AsyncData<InvoiceState>) return;

    final data = current.value;

    // nie ma statusów => nic nie zrobimy
    if (data.statuses.isEmpty) return;

    final oldStatus = data.statuses.firstWhere(
      (s) => s.transactionIndex.contains(transactionId),
      orElse: () => data.statuses.first,
    );

    final newStatus = data.statuses.firstWhere(
      (s) => s.statusName == newStatusName,
      orElse: () => oldStatus,
    );

    if (oldStatus.id == newStatus.id) return;

    // --- 1) lokalnie: przerzuć id między kolumnami ---
    final updatedStatuses = data.statuses.map((s) {
      if (s.id == oldStatus.id) {
        final next = List<int>.from(s.transactionIndex);
        next.remove(transactionId);
        return RevenueStatusModel(
          id: s.id,
          statusName: s.statusName,
          statusIndex: s.statusIndex,
          transactionIndex: next,
        );
      }
      if (s.id == newStatus.id) {
        final next = List<int>.from(s.transactionIndex);
        if (!next.contains(transactionId)) next.add(transactionId);
        return RevenueStatusModel(
          id: s.id,
          statusName: s.statusName,
          statusIndex: s.statusIndex,
          transactionIndex: next,
        );
      }
      return s;
    }).toList();

    state = AsyncValue.data(
      InvoiceState(transactions: data.transactions, statuses: updatedStatuses),
    );

    // --- 2) backend: wyślij update dla obu statusów ---
    try {
      final oldUpdated = updatedStatuses.firstWhere((s) => s.id == oldStatus.id);
      final newUpdated = updatedStatuses.firstWhere((s) => s.id == newStatus.id);

      final statusesToUpdate = [
        {'id': oldUpdated.id, 'transaction_index': oldUpdated.transactionIndex},
        {'id': newUpdated.id, 'transaction_index': newUpdated.transactionIndex},
      ];

      await apiService.updateRevenuesStatuses(statusesToUpdate);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ changeInvoiceStatus API error: $e');
      }
      // opcjonalnie: rollback albo refresh
      // await fetchInvoicesAndStatuses();
    }
  }
}
