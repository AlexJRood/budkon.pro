import 'dart:convert';
import 'dart:developer';
import 'package:crm/crm_urls.dart';

import 'package:crm/crm/finance/providers/finance_company_scope.dart';
import 'package:crm/crm/finance/providers/finance_filters_provider.dart';
import 'package:crm/data/finance/expenses_services_api.dart';
import 'package:crm/shared/models/expense/crm_expenses_download_model.dart';
import 'package:crm/shared/models/expense/expenses_status_model.dart';
import 'package:crm/shared/models/transaction/transaction_expenses_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';

class ExpensesState {
  final List<TransactionExpensesModel> transactions;
  final List<ExpensesStatusModel> statuses;

  ExpensesState({required this.transactions, required this.statuses});
}

final expensesTransactionProvider =
    StateNotifierProvider<ExpensesNotifier, AsyncValue<ExpensesState>>((ref) {
      final apiService = ref.watch(apiProvider);
      return ExpensesNotifier(apiService, ref);
    });

class ExpensesNotifier extends StateNotifier<AsyncValue<ExpensesState>> {
  final ApiServiceExpenses apiService;
  final Ref ref;

  ExpensesNotifier(this.apiService, this.ref)
    : super(const AsyncValue.loading()) {
    // ✅ refresh when company scope changes
    ref.listen<int?>(financeCompanyIdProvider, (_, __) {
      fetchExpensesAndStatuses();
    });

    // ✅ refresh when filters change (popup)
    ref.listen(financeFiltersProvider(FinanceTxType.expense), (_, __) {
      fetchExpensesAndStatuses();
    });

    fetchExpensesAndStatuses();
  }

  int? statusUserContact;

  // (zostawiamy, ale w praktyce sort/search bierze z popup provider)
  String? sortUserContact;
  String? searchQueryUserContact;

  Future<void> fetchExpensesAndStatuses() async {
    try {
    final companyId = ref.read(financeCompanyIdProvider);
    final filters = ref.read(financeFiltersProvider(FinanceTxType.expense));

    final queryParams = <String, dynamic>{
      if (statusUserContact != null) 'status': statusUserContact,

      // ✅ popup filters (priorytet)
      if (filters.sort.trim().isNotEmpty) 'sort': filters.sort.trim(),
      if (filters.search.trim().isNotEmpty) 'search': filters.search.trim(),

      // ✅ legacy fallback (jeśli ktoś w kodzie jeszcze ustawia te pola)
      if ((filters.sort.trim().isEmpty) && sortUserContact != null)
        'sort': sortUserContact,
      if ((filters.search.trim().isEmpty) && searchQueryUserContact != null)
        'search': searchQueryUserContact,
    }..removeWhere((k, v) => v == null);

    // ✅ Transactions (with company_id)
    final txUrl = withCompanyId(CrmUrls.financeAppExpenses, companyId);
    final transactionsResponse = await ApiServices.get(
      ref: ref,
      txUrl,
      queryParameters: queryParams,
      hasToken: true,
    );
    if (transactionsResponse == null) return;

    final Uint8List bodyBytes = _asBytes(transactionsResponse.data);
    final decodedDatabody = utf8.decode(bodyBytes);
    final decodedTxJson = json.decode(decodedDatabody);

    // backend bywa listą lub paginated mapą
    final List<dynamic> txList =
        (decodedTxJson is List)
            ? decodedTxJson
            : (decodedTxJson['results'] as List? ?? <dynamic>[]);
    log("ansaf test ${txList.toString()}");
    final transactions =
        txList
            .map(
              (e) =>
                  CrmExpensesDownloadModel.fromJson(e as Map<String, dynamic>),
            )
            .map((e) => TransactionExpensesModel.fromCrmExpensesDownload(e))
            .toList();

    // ✅ Statuses (with company_id)
    final stUrl = withCompanyId(CrmUrls.financeAppExpensesStatus, companyId);
    final statusesResponse = await ApiServices.get(
      ref: ref,
      stUrl,
      hasToken: true,
    );
    if (statusesResponse == null) return;

    final Uint8List stBytes = _asBytes(statusesResponse.data);
    final decodedStatusesBody = utf8.decode(stBytes);
    final decodedStatusesJson = json.decode(decodedStatusesBody);

    List<dynamic> listRaw = [];
    if (decodedStatusesJson is List) {
      listRaw = decodedStatusesJson;
    } else if (decodedStatusesJson is Map<String, dynamic>) {
      final results = decodedStatusesJson['results'];
      if (results is List) listRaw = results;
    }

    final statuses =
        listRaw
            .map((s) => ExpensesStatusModel.fromJson(s as Map<String, dynamic>))
            .toList();

    state = AsyncValue.data(
      ExpensesState(transactions: transactions, statuses: statuses),
    );
    } catch (error, st) {
      state = AsyncValue.error(error, st);
    }
  }

  // ------------------------------------------------------------
  // Drag helpers
  // ------------------------------------------------------------

  void reorderTransaction(int oldIndex, int newIndex, String statusName) {
    if (kDebugMode) {
      debugPrint('Reordering expense tx for status: $statusName');
      debugPrint('Old Index: $oldIndex, New Index: $newIndex');
    }

    state = state.whenData((data) {
      final status = data.statuses.firstWhere(
        (s) => s.statusName == statusName,
      );

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
            ExpensesStatusModel(
              id: s.id,
              statusName: s.statusName,
              statusIndex: s.statusIndex,
              transactionIndex: list,
            )
          else
            s,
      ];

      return ExpensesState(
        transactions: data.transactions,
        statuses: updatedStatuses,
      );
    });
  }

  void moveTransaction(
    TransactionExpensesModel transaction,
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

      final updatedState = ExpensesState(
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
        if (kDebugMode) debugPrint("Failed to update expense statuses: $e");
      }

      return updatedState;
    });
  }

  void reorderStatuses(List<ExpensesStatusModel> updatedStatuses) {
    state = state.whenData((data) {
      final newState = ExpensesState(
        transactions: data.transactions,
        statuses: updatedStatuses,
      );

      try {
        final columnIds = updatedStatuses.map((s) => s.id).toList();
        apiService.updateColumnIndexes(columnIds);
      } catch (e) {
        if (kDebugMode) debugPrint("Failed to update expense column indexes: $e");
      }

      return newState;
    });
  }

  void addTransaction(TransactionExpensesModel transaction) {
    state = state.whenData(
      (data) => ExpensesState(
        transactions: [...data.transactions, transaction],
        statuses: data.statuses,
      ),
    );
  }

  // ------------------------------------------------------------
  // Status CRUD
  // ------------------------------------------------------------

  Future<void> addStatus(ExpensesStatusModel status) async {
    try {
      final companyId = ref.read(financeCompanyIdProvider);
      final url = withCompanyId(
        _ensureTrailingSlash(CrmUrls.financeAppExpensesStatus),
        companyId,
      );

      await ApiServices.post(
        url,
        hasToken: true,
        ref: ref,
        data: {'name': status.statusName, 'index': status.statusIndex},
      );

      await fetchExpensesAndStatuses();
    } catch (e) {
      if (kDebugMode) debugPrint("addStatus error: $e");
    }
  }

  Future<ExpensesStatusModel> createTransactionStatus(
    ExpensesStatusModel status,
  ) async {
    final companyId = ref.read(financeCompanyIdProvider);
    final url = withCompanyId(
      _ensureTrailingSlash(CrmUrls.financeAppExpensesStatus),
      companyId,
    );

    final response = await ApiServices.post(
      url,
      data: status.toJson(),
      hasToken: true,
      ref: ref,
    );

    await fetchExpensesAndStatuses();
    return ExpensesStatusModel.fromJson(response!.data);
  }

  Future<ExpensesStatusModel> updateTransactionStatus(
    ExpensesStatusModel status,
  ) async {
    final companyId = ref.read(financeCompanyIdProvider);

    final base = _ensureTrailingSlash(CrmUrls.financeAppExpensesStatus);
    final url = withCompanyId('$base${status.id}/', companyId);

    final response = await ApiServices.patch(
      url,
      data: status.toJson(),
      hasToken: true,
      ref: ref,
    );

    await fetchExpensesAndStatuses();
    return ExpensesStatusModel.fromJson(response!.data);
  }

  Future<void> deleteTransactionStatus(int id) async {
    final companyId = ref.read(financeCompanyIdProvider);

    final base = _ensureTrailingSlash(CrmUrls.financeAppExpensesStatus);
    final url = withCompanyId('$base$id/', companyId);

    await ApiServices.delete(url, hasToken: true);

    await fetchExpensesAndStatuses();
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
