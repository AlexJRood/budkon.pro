import 'dart:convert';

import 'package:crm/crm/finance/features/revenue/revenue_services_api.dart';
import 'package:crm/crm_urls.dart';
import 'package:crm/crm/finance/features/revenue/revenue_status_model.dart';
import 'package:crm/crm/finance/providers/finance_company_scope.dart';
import 'package:crm/crm/finance/providers/finance_filters_provider.dart';
import 'package:crm/shared/models/revenue_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';

class RevenueState {
  final List<AgentRevenueModel> transactions;
  final List<RevenueStatusModel> statuses;

  RevenueState({required this.transactions, required this.statuses});
}

final revenueProvider =
    StateNotifierProvider<TransactionNotifier, AsyncValue<RevenueState>>((ref) {
  final apiService = ref.watch(apiProviderRevenue);
  return TransactionNotifier(apiService, ref);
});

class TransactionNotifier extends StateNotifier<AsyncValue<RevenueState>> {
  final ApiServiceRevenue apiService;
  final Ref ref;

  TransactionNotifier(this.apiService, this.ref) : super(const AsyncLoading()) {
    // ✅ refresh when company scope changes
    ref.listen<int?>(financeCompanyIdProvider, (_, __) {
      fetchRevenueAndStatuses();
    });

    // ✅ refresh when filters change (popup)
    ref.listen(financeFiltersProvider(FinanceTxType.revenue), (_, __) {
      fetchRevenueAndStatuses();
    });

    fetchRevenueAndStatuses();
  }

  int? statusUserContact;

  // fallback legacy:
  String? sortUserContact;
  String? searchQueryUserContact;

  Future<void> fetchRevenueAndStatuses() async {
    try {
      final companyId = ref.read(financeCompanyIdProvider);
      final filters = ref.read(financeFiltersProvider(FinanceTxType.revenue));

      final queryParams = <String, dynamic>{
        if (statusUserContact != null) 'status': statusUserContact,

        // ✅ popup filters
        if (filters.sort.trim().isNotEmpty) 'sort': filters.sort.trim(),
        if (filters.search.trim().isNotEmpty) 'search': filters.search.trim(),

        // ✅ legacy fallback
        if ((filters.sort.trim().isEmpty) && sortUserContact != null) 'sort': sortUserContact,
        if ((filters.search.trim().isEmpty) && searchQueryUserContact != null) 'search': searchQueryUserContact,
      }..removeWhere((k, v) => v == null);

      // ✅ 1) Transactions (with company_id)
      final txUrl = withCompanyId(CrmUrls.financeAppRevenues, companyId);

      final transactionsResponse = await ApiServices.get(
        ref: ref,
        txUrl,
        queryParameters: queryParams,
        hasToken: true,
      );

      if (transactionsResponse == null) {
        if (kDebugMode) debugPrint('❌ Revenue tx response is null');
        state = AsyncValue.error('No transactions response', StackTrace.current);
        return;
      }

      final Uint8List txBytes = _asBytes(transactionsResponse.data);
      final decodedTransactionsBody = utf8.decode(txBytes);

      final decodedTxJson = json.decode(decodedTransactionsBody);

      final List<dynamic> txList =
          (decodedTxJson is List) ? decodedTxJson : (decodedTxJson['results'] as List? ?? <dynamic>[]);

      final transactions = txList
          .map((e) => AgentRevenueModel.fromJson(e as Map<String, dynamic>))
          .toList();

      // ✅ 2) Statuses (with company_id)
      final stUrl = withCompanyId(CrmUrls.financeAppRevenuesStatus, companyId);

      final statusesResponse = await ApiServices.get(
        ref: ref,
        stUrl,
        hasToken: true,
      );

      if (statusesResponse == null) {
        if (kDebugMode) debugPrint('❌ Revenue statuses response is null');
        state = AsyncValue.error('No statuses response', StackTrace.current);
        return;
      }

      final Uint8List stBytes = _asBytes(statusesResponse.data);
      final decodedStatusesBody = utf8.decode(stBytes);

      final decodedStatusesJson = json.decode(decodedStatusesBody);

      List<dynamic> decodeStatuses = [];

      if (decodedStatusesJson is List) {
        decodeStatuses = decodedStatusesJson;
      } else if (decodedStatusesJson is Map<String, dynamic>) {
        final results = decodedStatusesJson['results'];
        if (results is List) {
          decodeStatuses = results;
        } else if (decodedStatusesJson['data'] != null) {
          final dataBlock = decodedStatusesJson['data'];
          if (dataBlock is List) {
            decodeStatuses = dataBlock;
          } else if (dataBlock is Map && dataBlock['results'] is List) {
            decodeStatuses = dataBlock['results'] as List;
          }
        }
      }

      final statuses = decodeStatuses
          .map((s) => RevenueStatusModel.fromJson(s as Map<String, dynamic>))
          .toList();

      if (kDebugMode) {
        debugPrint('✅ Revenue: tx=${transactions.length}, statuses=${statuses.length}');
      }

      state = AsyncValue.data(
        RevenueState(transactions: transactions, statuses: statuses),
      );
    } catch (error, stack) {
      if (kDebugMode) debugPrint('❌ Error in fetchRevenueAndStatuses:\n$error');
      state = AsyncValue.error(error, stack);
    }
  }

  Future<void> refreshTransactions() async {
    await fetchRevenueAndStatuses();
  }

  void reorderTransaction(int oldIndex, int newIndex, String statusName) {
    if (kDebugMode) {
      debugPrint('Reordering revenue tx for status: $statusName');
      debugPrint('Old Index: $oldIndex, New Index: $newIndex');
    }

    state = state.whenData((data) {
      final status = data.statuses.firstWhere((s) => s.statusName == statusName);

      final list = List<int>.from(status.transactionIndex);

      if (oldIndex < 0 || oldIndex >= list.length) return data;
      if (newIndex < 0) newIndex = 0;
      if (newIndex > list.length) newIndex = list.length;

      final removed = list.removeAt(oldIndex);
      if (newIndex > oldIndex) newIndex -= 1;
      list.insert(newIndex, removed);

      final updatedStatuses = [
        for (final s in data.statuses)
          if (s.id == status.id)
            RevenueStatusModel(
              id: s.id,
              statusName: s.statusName,
              statusIndex: s.statusIndex,
              transactionIndex: list,
            )
          else
            s,
      ];

      return RevenueState(
        transactions: data.transactions,
        statuses: updatedStatuses,
      );
    });
  }

  void moveTransaction(
    AgentRevenueModel transaction,
    String newStatusName,
    int? newIndex,
  ) {
    state = state.whenData((data) {
      final oldStatus = data.statuses.firstWhere(
        (s) => s.transactionIndex.contains(transaction.id),
      );
      final newStatus = data.statuses.firstWhere(
        (s) => s.statusName == newStatusName,
      );

      oldStatus.transactionIndex.remove(transaction.id);

      if (newIndex != null && newIndex <= newStatus.transactionIndex.length) {
        newStatus.transactionIndex.insert(newIndex, transaction.id);
      } else {
        newStatus.transactionIndex.add(transaction.id);
      }

      final updatedState = RevenueState(
        transactions: data.transactions,
        statuses: data.statuses,
      );

      try {
        final statusesToUpdate = [
          {'id': oldStatus.id, 'transaction_index': oldStatus.transactionIndex},
          {'id': newStatus.id, 'transaction_index': newStatus.transactionIndex},
        ];
        apiService.updateRevenuesStatuses(statusesToUpdate);
      } catch (e) {
        if (kDebugMode) debugPrint("Failed to update revenue statuses: $e");
      }

      return updatedState;
    });
  }

  void reorderStatuses(List<RevenueStatusModel> updatedStatuses) {
    state = state.whenData((data) {
      final newState = RevenueState(
        transactions: data.transactions,
        statuses: updatedStatuses,
      );

      try {
        final columnIds = updatedStatuses.map((s) => s.id).toList();
        apiService.updateColumnIndexes(columnIds);
      } catch (e) {
        if (kDebugMode) debugPrint("Failed to update revenue column indexes: $e");
      }

      return newState;
    });
  }

  void addTransaction(AgentRevenueModel transaction) {
    state = state.whenData(
      (data) => RevenueState(
        transactions: [...data.transactions, transaction],
        statuses: data.statuses,
      ),
    );
  }

  // ------------------------------------------------------------
  // Status CRUD
  // ------------------------------------------------------------

  Future<void> addStatus(RevenueStatusModel status) async {
    try {
      final companyId = ref.read(financeCompanyIdProvider);
      final url = withCompanyId(_ensureTrailingSlash(CrmUrls.financeAppRevenuesStatus), companyId);

      await ApiServices.post(
        url,
        data: {'name': status.statusName, 'index': status.statusIndex},
        hasToken: true,
        ref: ref,
      );

      await fetchRevenueAndStatuses();
    } catch (e) {
      if (kDebugMode) debugPrint("addStatus error: $e");
    }
  }

  Future<RevenueStatusModel> createRevenueStatusModel(RevenueStatusModel status) async {
    final companyId = ref.read(financeCompanyIdProvider);
    final url = withCompanyId(_ensureTrailingSlash(CrmUrls.financeAppRevenuesStatus), companyId);

    final response = await ApiServices.post(
      url,
      data: status.toJson(),
      hasToken: true,
      ref: ref,
    );

    await fetchRevenueAndStatuses();
    return RevenueStatusModel.fromJson(response!.data);
  }

  Future<RevenueStatusModel> updateRevenueStatusModel(RevenueStatusModel status) async {
    final companyId = ref.read(financeCompanyIdProvider);

    final base = _ensureTrailingSlash(CrmUrls.financeAppRevenuesStatus);
    final url = withCompanyId('$base${status.id}/', companyId);

    final response = await ApiServices.patch(
      url,
      data: status.toJson(),
      hasToken: true,
      ref: ref,
    );

    await fetchRevenueAndStatuses();
    return RevenueStatusModel.fromJson(response!.data);
  }

  Future<void> deleteRevenueStatusModel(int id) async {
    final companyId = ref.read(financeCompanyIdProvider);

    final base = _ensureTrailingSlash(CrmUrls.financeAppRevenuesStatus);
    final url = withCompanyId('$base$id/', companyId);

    await ApiServices.delete(
      url,
      hasToken: true,
    );

    await fetchRevenueAndStatuses();
  }

  // ------------------------------------------------------------
  // Utils
  // ------------------------------------------------------------

  static Uint8List _asBytes(dynamic data) {
    if (data is Uint8List) return data;
    if (data is List<int>) return Uint8List.fromList(data);
    return Uint8List.fromList(List<int>.from(data as Iterable));
  }

  static String _ensureTrailingSlash(String url) {
    return url.endsWith('/') ? url : '$url/';
  }
}
