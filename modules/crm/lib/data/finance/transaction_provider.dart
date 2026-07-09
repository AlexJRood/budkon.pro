import 'dart:convert';

import 'package:crm/data/finance/transaction_filters_provider.dart';
import 'package:crm/crm_urls.dart';
import 'package:crm/data/finance/transaction_services_api.dart';
import 'package:crm/shared/models/transaction/agent_transaction_model.dart';
import 'package:crm/shared/models/transaction/transaction_status_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';

class TransactionState {
  final List<AgentTransactionModel> transactions;
  final List<TransactionStatus> statuses;

  TransactionState({
    required this.transactions,
    required this.statuses,
  });
}

final transactionProvider =
    StateNotifierProvider<TransactionNotifier, AsyncValue<TransactionState>>(
  (ref) {
    final apiService = ref.watch(apiProviderTransaction);
    return TransactionNotifier(apiService, ref);
  },
);

class TransactionNotifier extends StateNotifier<AsyncValue<TransactionState>> {
  final ApiServiceTransaction apiService;

  TransactionNotifier(this.apiService, dynamic ref)
      : super(const AsyncValue.loading()) {
    fetchTransactionsAndStatuses(ref);
  }

  // ✅ One entrypoint used by dialog Apply
  Future<void> applyFiltersAndFetch(dynamic ref) async {
    await fetchTransactionsAndStatuses(ref);
  }

  Future<void> clearFiltersAndFetch(dynamic ref) async {
    ref.read(transactionFiltersProvider.notifier).clearAll();
    await fetchTransactionsAndStatuses(ref);
  }

  // ============================================================
  // Fetch (query comes ONLY from transactionFiltersProvider)
  // ============================================================

  Future<void> fetchTransactionsAndStatuses(dynamic ref) async {
    try {
      if (kDebugMode) print("📡 fetchTransactionsAndStatuses...");

      final filters = ref.read(transactionFiltersProvider);
      final queryParams = filters.toQueryParams();

      if (kDebugMode) print("🔍 Query params: $queryParams");

      // Transactions
      final transactionsResponse = await ApiServices.get(
        ref: ref,
        CrmUrls.agentTransactionsCrm,
        queryParameters: queryParams,
        hasToken: true,
      );

      if (transactionsResponse == null) {
        if (kDebugMode) print("❌ Transactions API response is null");
        return;
      }

      final decodedDatabody = utf8.decode(transactionsResponse.data);
      final decodedJson = json.decode(decodedDatabody);

      final decodeData = (decodedJson is List)
          ? decodedJson
          : (decodedJson['results'] as List? ?? []);

      final transactions = decodeData
          .map((tx) => AgentTransactionModel.fromJson(tx))
          .toList();

      // Statuses
      final statusesResponse = await ApiServices.get(
        ref: ref,
        CrmUrls.getAgentTransactionStatus,
        hasToken: true,
      );

      if (statusesResponse == null) {
        if (kDebugMode) print("❌ Statuses API response is null");
        return;
      }

      final decodedStatusesBody = utf8.decode(statusesResponse.data);
      final listingsJson = json.decode(decodedStatusesBody);

      final decodeStatuses = (listingsJson is List)
          ? listingsJson
          : (listingsJson['results'] as List? ?? []);

      final statuses = decodeStatuses
          .map((s) => TransactionStatus.fromJson(s as Map<String, dynamic>))
          .toList();

      state = AsyncValue.data(
        TransactionState(transactions: transactions, statuses: statuses),
      );
    } catch (error, stack) {
      if (kDebugMode) print("❌ fetchTransactionsAndStatuses error: $error");
      state = AsyncValue.error(error, stack);
    }
  }

  Future<void> refreshTransactions(dynamic ref) async {
    await fetchTransactionsAndStatuses(ref);
  }

  // ============================================================
  // Local patch update (unchanged)
  // ============================================================

  Future<void> applyPartialUpdateLocally(
    int txId,
    Map<String, dynamic> patch,
  ) async {
    state = state.whenData((data) {
      final updated = [
        for (final t in data.transactions)
          if (t.id == txId)
            t.copyWith(
              name: patch['name'] as String? ?? t.name,
              amount: patch['amount'] as String? ?? t.amount,
              commission: patch['commission'] as String? ?? t.commission,
              currency: patch['currency'] as String? ?? t.currency,
              paymentMethods: patch['payment_methods'] as String? ?? t.paymentMethods,
              isCommisssionPercentage:
                  patch['isCommisssionPercentage'] as bool? ?? t.isCommisssionPercentage,
            )
          else
            t,
      ];

      return TransactionState(transactions: updated, statuses: data.statuses);
    });
  }

  // ============================================================
  // Drag & drop logic (unchanged)
  // ============================================================

  void reorderTransaction(int oldIndex, int newIndex, String statusName) {
    if (kDebugMode) print('Reordering transaction for status: $statusName');

    state = state.whenData((data) {
      final status =
          data.statuses.firstWhere((status) => status.statusName == statusName);

      final newTransactionIndex = List<int>.from(status.transactionIndex);

      final updatedState = TransactionState(
        transactions: data.transactions,
        statuses: [
          for (final s in data.statuses)
            if (s.statusName == status.statusName)
              TransactionStatus(
                id: s.id,
                statusName: s.statusName,
                statusIndex: s.statusIndex,
                transactionIndex: newTransactionIndex,
              )
            else
              s,
        ],
      );

      return updatedState;
    });
  }

  void moveTransaction(
    AgentTransactionModel transaction,
    String newStatusName,
    int? newIndex,
  ) {
    state = state.whenData((data) {
      final oldStatus = data.statuses.firstWhere(
        (status) => status.transactionIndex.contains(transaction.id),
      );
      final newStatus = data.statuses.firstWhere(
        (status) => status.statusName == newStatusName,
      );

      oldStatus.transactionIndex.remove(transaction.id);

      if (newIndex != null && newIndex <= newStatus.transactionIndex.length) {
        newStatus.transactionIndex.insert(newIndex, transaction.id);
      } else {
        newStatus.transactionIndex.add(transaction.id);
      }

      final updatedState = TransactionState(
        transactions: data.transactions,
        statuses: data.statuses,
      );

      try {
        final statusesToUpdate = [
          {'id': oldStatus.id, 'transaction_index': oldStatus.transactionIndex},
          {'id': newStatus.id, 'transaction_index': newStatus.transactionIndex},
        ];
        apiService.updateTransactionStatuses(statusesToUpdate);
      } catch (e) {
        if (kDebugMode) print("Failed to update transaction statuses: $e");
      }

      return updatedState;
    });
  }

  void reorderStatuses(List<TransactionStatus> updatedStatuses) async {
    state = state.whenData((data) {
      final newState = TransactionState(
        transactions: data.transactions,
        statuses: updatedStatuses,
      );

      try {
        final columnIds = updatedStatuses.map((status) => status.id).toList();
        apiService.updateColumnIndexes(columnIds);
      } catch (e) {
        if (kDebugMode) print("Failed to update column indexes: $e");
      }

      return newState;
    });
  }

  // ============================================================
  // Status CRUD (your existing endpoints)
  // ============================================================

  Future<void> addStatus(TransactionStatus status, dynamic ref) async {
    try {
      await ApiServices.post(
        CrmUrls.getAgentTransactionStatus,
        data: {
          'name': status.statusName,
          'index': status.statusIndex,
        },
        hasToken: true,
        ref: ref,
      );
      fetchTransactionsAndStatuses(ref);
    } catch (e) {
      if (kDebugMode) print("addStatus error: $e");
    }
  }

  Future<TransactionStatus> createTransactionStatus(
    TransactionStatus status,
    dynamic ref,
  ) async {
    final response = await ApiServices.post(
      CrmUrls.getAgentTransactionStatus,
      data: status.toJson(),
      hasToken: true,
      ref: ref,
    );

    fetchTransactionsAndStatuses(ref);
    return TransactionStatus.fromJson(response!.data);
  }

  Future<TransactionStatus> updateTransactionStatus(
    TransactionStatus status,
    dynamic ref,
  ) async {
    final response = await ApiServices.patch(
      '${CrmUrls.getAgentTransactionStatus}${status.id}/',
      data: status.toJson(),
      hasToken: true,
      ref: ref,
    );

    fetchTransactionsAndStatuses(ref);
    return TransactionStatus.fromJson(response!.data);
  }

  Future<void> deleteTransactionStatus(int id, dynamic ref) async {
    await ApiServices.delete(
      '${CrmUrls.getAgentTransactionStatus}$id/',
      hasToken: true,
    );
    fetchTransactionsAndStatuses(ref);
  }
}
