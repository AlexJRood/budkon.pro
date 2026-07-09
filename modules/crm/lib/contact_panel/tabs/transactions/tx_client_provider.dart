import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:crm/crm_urls.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crm/shared/models/transaction/agent_transaction_model.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/platform/url.dart';

// =========================
// Selection
// =========================
final selectedTransactionIdProvider = StateProvider.family<int?, int>(
  (ref, clientId) => null,
);

final selectedTransactionProvider =
    Provider.family<AgentTransactionModel?, int>((ref, clientId) {
      final list = ref.watch(transactionListProvider(clientId)).value;
      final selId = ref.watch(selectedTransactionIdProvider(clientId));
      if (list == null || selId == null) return null;
      return list.firstWhereOrNull((t) => t.id == selId);
    });

// =========================
// Filters
// =========================
class TransactionListFilter {
  static const String defaultOrdering = '-date_create';

  static const String roleAll = 'all';
  static const String roleSeller = 'seller';
  static const String roleBuyer = 'buyer';

  final bool includeArchived;
  final bool includeCompleted;
  final bool includeClosed;
  final bool onlyCompleted;
  final bool onlyMine;
  final String search;
  final String role;
  final String ordering;

  const TransactionListFilter({
    this.includeArchived = false,
    this.includeCompleted = false,
    this.includeClosed = false,
    this.onlyCompleted = false,
    this.onlyMine = false,
    this.search = '',
    this.role = roleAll,
    this.ordering = defaultOrdering,
  });

  TransactionListFilter copyWith({
    bool? includeArchived,
    bool? includeCompleted,
    bool? includeClosed,
    bool? onlyCompleted,
    bool? onlyMine,
    String? search,
    String? role,
    String? ordering,
  }) {
    return TransactionListFilter(
      includeArchived: includeArchived ?? this.includeArchived,
      includeCompleted: includeCompleted ?? this.includeCompleted,
      includeClosed: includeClosed ?? this.includeClosed,
      onlyCompleted: onlyCompleted ?? this.onlyCompleted,
      onlyMine: onlyMine ?? this.onlyMine,
      search: search ?? this.search,
      role: role ?? this.role,
      ordering: ordering ?? this.ordering,
    );
  }

  bool get hasAnyFilter => activeCount > 0;

  int get activeCount {
    int count = 0;
    if (includeArchived) count++;
    if (includeCompleted) count++;
    if (includeClosed) count++;
    if (onlyCompleted) count++;
    if (onlyMine) count++;
    if (search.trim().isNotEmpty) count++;
    if (role != roleAll) count++;
    if (ordering != defaultOrdering) count++;
    return count;
  }

  Map<String, String> toQueryParameters() {
    final includeCompletedEffective = includeCompleted || onlyCompleted;
    final includeClosedEffective = includeClosed || onlyCompleted;

    return <String, String>{
      if (includeArchived) 'include_archived': 'true',
      if (includeCompletedEffective) 'include_completed': 'true',
      if (includeClosedEffective) 'include_closed': 'true',
      if (onlyCompleted) 'only_completed': 'true',
      if (onlyMine) 'only_mine': 'true',
      if (search.trim().isNotEmpty) 'search': search.trim(),
      if (role == roleSeller) 'is_seller': 'true',
      if (role == roleBuyer) 'is_buyer': 'true',
      'ordering': ordering,
    };
  }

  @override
  String toString() {
    return 'TransactionListFilter('
        'includeArchived: $includeArchived, '
        'includeCompleted: $includeCompleted, '
        'includeClosed: $includeClosed, '
        'onlyCompleted: $onlyCompleted, '
        'onlyMine: $onlyMine, '
        'search: $search, '
        'role: $role, '
        'ordering: $ordering'
        ')';
  }
}

final transactionListFilterProvider =
    StateProvider.family<TransactionListFilter, int>(
      (ref, clientId) => const TransactionListFilter(),
    );

// =========================
// List
// =========================
final transactionListProvider = StateNotifierProvider.family<
  TransactionListNotifier,
  AsyncValue<List<AgentTransactionModel>>,
  int
>((ref, clientId) {
  final filters = ref.watch(transactionListFilterProvider(clientId));
  return TransactionListNotifier(ref, clientId, filters)..fetch();
});

class TransactionListNotifier
    extends StateNotifier<AsyncValue<List<AgentTransactionModel>>> {
  final Ref ref;
  final int clientId;
  final TransactionListFilter filters;

  TransactionListNotifier(this.ref, this.clientId, this.filters)
    : super(const AsyncLoading());

  String _buildUrlWithFilters(String baseUrl) {
    final uri = Uri.parse(baseUrl);
    final mergedQuery = <String, String>{
      ...uri.queryParameters,
      ...filters.toQueryParameters(),
    };

    return uri.replace(
      queryParameters: mergedQuery.isEmpty ? null : mergedQuery,
    ).toString();
  }

  Future<void> fetch() async {
    try {
      final url = _buildUrlWithFilters(
        CrmUrls.agentTransactionByUserContact('$clientId'),
      );

      final resp = await ApiServices.get(ref: ref, url, hasToken: true);

      if (resp == null || resp.statusCode != 200) {
        throw Exception('HTTP ${resp?.statusCode}');
      }

      final decoded = utf8.decode(resp.data);
      final list =
          (json.decode(decoded) as List<dynamic>)
              .map((e) => AgentTransactionModel.fromJson(e))
              .toList();

      debugPrint(
        '[transactionListProvider] clientId=$clientId '
        'loaded=${list.length} '
        'filters=$filters '
        'ids=${list.map((e) => e.id).toList()}',
      );

      state = AsyncData(list);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> refresh() => fetch();

  void upsert(AgentTransactionModel tx) {
    final cur = state.value ?? const <AgentTransactionModel>[];
    final idx = cur.indexWhere((t) => t.id == tx.id);
    final next = [...cur];

    if (idx >= 0) {
      next[idx] = tx;
    } else {
      next.insert(0, tx);
    }

    state = AsyncData(next);
  }

  void removeById(int id) {
    final cur = state.value ?? const <AgentTransactionModel>[];
    state = AsyncData(cur.where((t) => t.id != id).toList());
  }

  void replaceAll(List<AgentTransactionModel> next) {
    state = AsyncData([...next]);
  }

  void updateLocal(
    int id,
    AgentTransactionModel Function(AgentTransactionModel) updater,
  ) {
    final cur = state.value ?? const <AgentTransactionModel>[];
    final idx = cur.indexWhere((t) => t.id == id);
    if (idx < 0) return;

    final next = [...cur];
    next[idx] = updater(next[idx]);
    state = AsyncData(next);
  }

  void updatePartialLocal(int id, Map<String, dynamic> partial) {
    final cur = state.value ?? const <AgentTransactionModel>[];
    final idx = cur.indexWhere((t) => t.id == id);
    if (idx < 0) return;

    final original = cur[idx];
    final baseMap = Map<String, dynamic>.from(original.toJson());
    baseMap.addAll(partial);
    final merged = AgentTransactionModel.fromJson(baseMap);

    final next = [...cur];
    next[idx] = merged;
    state = AsyncData(next);
  }

  void updateManyLocal(
    bool Function(AgentTransactionModel) test,
    AgentTransactionModel Function(AgentTransactionModel) updater,
  ) {
    final cur = state.value ?? const <AgentTransactionModel>[];
    if (cur.isEmpty) return;

    final next = [for (final t in cur) test(t) ? updater(t) : t];
    state = AsyncData(next);
  }

  void reorderLocal(int oldIndex, int newIndex) {
    final cur = state.value ?? const <AgentTransactionModel>[];
    if (oldIndex < 0 || oldIndex >= cur.length) return;

    final next = [...cur];
    final item = next.removeAt(oldIndex);
    final insertAt = newIndex > oldIndex ? newIndex - 1 : newIndex;
    next.insert(insertAt.clamp(0, next.length), item);
    state = AsyncData(next);
  }

  Future<void> patchAndUpsert({
    required int id,
    required Map<String, dynamic> payload,
  }) async {
    final snapshot = state;
    updatePartialLocal(id, payload);

    try {
      final url = URLs.updateRevenuesCrm(id.toString());
      final resp = await ApiServices.patch(url, hasToken: true, data: payload);
      final sc = resp?.statusCode ?? 0;

      if (resp == null || sc >= 300) {
        throw Exception('HTTP $sc');
      }
    } catch (e, st) {
      state = snapshot;
      throw AsyncError(e, st);
    }
  }
}