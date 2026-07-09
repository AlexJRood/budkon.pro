import 'package:crm/crm/finance/dashboard/model_dashboard.dart';
import 'package:crm/crm/finance/providers/finance_company_scope.dart';
import 'package:crm/crm_urls.dart';
import 'package:crm/shared/models/transaction/transaction_expenses_model.dart';
import 'package:crm/shared/models/revenue_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';

final unifiedTypeFilterProvider =
    StateProvider<String>((ref) => 'all'); // all | revenue | expense
final unifiedSearchProvider = StateProvider<String>((ref) => '');
final unifiedSortProvider = StateProvider<String>((ref) => 'date_create_desc');
final unifiedPageProvider = StateProvider<int>((ref) => 1);
final unifiedPageSizeProvider = StateProvider<int>((ref) => 1000);

final unifiedTransactionsProvider =
    FutureProvider.autoDispose<List<UnifiedTransactionModel>>((ref) async {
  final type = ref.watch(unifiedTypeFilterProvider);
  final search = ref.watch(unifiedSearchProvider);
  final sort = ref.watch(unifiedSortProvider);
  final page = ref.watch(unifiedPageProvider);
  final pageSize = ref.watch(unifiedPageSizeProvider);

  // ✅ IMPORTANT: use resolved companyId (never null if user has at least one entity in scope)
  final companyId = ref.watch(financeResolvedCompanyIdProvider);

  // If scope required and not available yet -> return empty (UI can show loader elsewhere)
  if (companyId == null) {
    return [];
  }

  // 1) revenues
  List<AgentRevenueModel> revenues = [];
  if (type == 'all' || type == 'revenue') {
    final url = withCompanyId(CrmUrls.financeAppRevenues, companyId);

    final resp = await ApiServices.get(
      url,
      hasToken: true,
      ref: ref,
      responseType: ResponseType.json,
      queryParameters: {
        'search': search.trim().isEmpty ? null : search.trim(),
        'sort': _mapSortToBackend(sort),

        // ✅ pagination (prevents "only first page" issue)
        'page': page,
        'page_size': pageSize,
      }..removeWhere((k, v) => v == null),
    );

    if (resp != null && resp.statusCode == 200) {
      final list = _extractList(resp.data);
      revenues = list
          .whereType<Map<String, dynamic>>()
          .map((e) => AgentRevenueModel.fromJson(e))
          .toList();
    }
  }

  // 2) expenses
  List<TransactionExpensesModel> expenses = [];
  if (type == 'all' || type == 'expense') {
    final url = withCompanyId(CrmUrls.financeAppExpenses, companyId);

    final resp = await ApiServices.get(
      url,
      hasToken: true,
      ref: ref,
      responseType: ResponseType.json,
      queryParameters: {
        'search': search.trim().isEmpty ? null : search.trim(),
        'sort': _mapSortToBackend(sort),

        // ✅ pagination
        'page': page,
        'page_size': pageSize,
      }..removeWhere((k, v) => v == null),
    );

    if (resp != null && resp.statusCode == 200) {
      final list = _extractList(resp.data);
      expenses = list
          .whereType<Map<String, dynamic>>()
          .map((e) => TransactionExpensesModel.fromJson(e))
          .toList();
    }
  }

  // 3) unified
  final List<UnifiedTransactionModel> unified = [
    ...revenues.map(UnifiedTransactionModel.fromRevenue),
    ...expenses.map(UnifiedTransactionModel.fromExpense),
  ];

  // 4) local sort fallback (by paymentDate desc)
  unified.sort((a, b) {
    final ad = a.paymentDateRaw ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bd = b.paymentDateRaw ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bd.compareTo(ad);
  });

  // 5) local pagination fallback (kept, but backend pagination is already applied)
  final start = (page - 1) * pageSize;
  final end = (start + pageSize).clamp(0, unified.length);
  if (start >= unified.length) return [];
  return unified.sublist(start, end);
});

List<dynamic> _extractList(dynamic data) {
  if (data is List) return data;
  if (data is Map<String, dynamic>) {
    final results = data['results'];
    if (results is List) return results;

    final dataBlock = data['data'];
    if (dataBlock is List) return dataBlock;
    if (dataBlock is Map && dataBlock['results'] is List) {
      return dataBlock['results'] as List;
    }
  }
  return <dynamic>[];
}

String _mapSortToBackend(String sort) {
  switch (sort) {
    case 'amount_asc':
      return 'amount_asc';
    case 'amount_desc':
      return 'amount_desc';
    case 'date_create_asc':
      return 'date_create_asc';
    case 'date_create_desc':
    default:
      return 'date_create_desc';
  }
}

final upcomingUnpaidTransactionsProvider =
    FutureProvider.autoDispose<List<UnifiedTransactionModel>>((ref) async {
  final all = await ref.watch(unifiedTransactionsProvider.future);
  final now = DateTime.now();

  final unpaid = all.where((tx) => tx.isPaid == false).toList();

  unpaid.sort((a, b) {
    final ad = a.paymentDateRaw ?? now.add(const Duration(days: 365 * 50));
    final bd = b.paymentDateRaw ?? now.add(const Duration(days: 365 * 50));
    return ad.compareTo(bd);
  });

  return unpaid;
});
