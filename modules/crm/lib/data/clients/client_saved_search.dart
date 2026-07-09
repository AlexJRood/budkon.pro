import 'dart:convert';
import 'package:crm/crm_urls.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';

import 'package:network_monitoring/models/saved_search_model.dart';
import 'package:core/platform/api_services.dart';

// --------------------
// helpers
// --------------------

String normalizeTitle(String input) {
  // keeps spaces, just collapses multiple whitespace into single space
  return input.replaceAll(RegExp(r'\s+'), ' ').trim();
}

List<dynamic> _extractList(dynamic raw) {
  dynamic body = raw;

  if (raw is List<int>) {
    body = json.decode(utf8.decode(raw));
  } else if (raw is String) {
    body = json.decode(raw);
  }

  if (body is List) return body;

  if (body is Map) {
    if (body['results'] is List) return List<dynamic>.from(body['results']);
    if (body['data'] is List) return List<dynamic>.from(body['data']);
    if (body['error'] != null) return const [];
  }

  return const [];
}

List<SavedSearchModel> _toModels(List<dynamic> list) {
  return list
      .whereType<Map>()
      .map((m) => SavedSearchModel.fromJson(Map<String, dynamic>.from(m)))
      .toList();
}

Future<List<SavedSearchModel>> _fetchSavedSearches(
  Ref ref,
  String url,
) async {
  final resp = await ApiServices.get(ref: ref, url, hasToken: true);

  if (resp == null) return const [];

  final sc = resp.statusCode ?? 0;
  if (sc == 204 || sc == 404) return const [];

  if (sc >= 300) {
    throw Exception('Failed to load saved searches'.tr);
  }

  final list = _extractList(resp.data);
  return _toModels(list);
}

// --------------------
// NOTIFIERS (LIVE LIST)
// --------------------

class ClientSavedSearchesNotifier
    extends StateNotifier<AsyncValue<List<SavedSearchModel>>> {
  final Ref ref;
  final int clientId;

  ClientSavedSearchesNotifier(this.ref, this.clientId)
      : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final list = await _fetchSavedSearches(ref, CrmUrls.clientSearches('$clientId'));
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void upsert(SavedSearchModel model) {
    final current = state.value ?? <SavedSearchModel>[];

    final idx = current.indexWhere((e) => e.id == model.id);
    final updated = List<SavedSearchModel>.from(current);

    if (idx >= 0) {
      updated[idx] = model;
    } else {
      updated.insert(0, model); // new on top
    }

    state = AsyncValue.data(updated);
  }

  void removeById(int id) {
    final current = state.value ?? <SavedSearchModel>[];
    state = AsyncValue.data(current.where((e) => e.id != id).toList());
  }
}

class TransactionSavedSearchesNotifier
    extends StateNotifier<AsyncValue<List<SavedSearchModel>>> {
  final Ref ref;
  final int transactionId;

  TransactionSavedSearchesNotifier(this.ref, this.transactionId)
      : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final list =
          await _fetchSavedSearches(ref, CrmUrls.transactionSearches('$transactionId'));
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void upsert(SavedSearchModel model) {
    final current = state.value ?? <SavedSearchModel>[];

    final idx = current.indexWhere((e) => e.id == model.id);
    final updated = List<SavedSearchModel>.from(current);

    if (idx >= 0) {
      updated[idx] = model;
    } else {
      updated.insert(0, model);
    }

    state = AsyncValue.data(updated);
  }

  void removeById(int id) {
    final current = state.value ?? <SavedSearchModel>[];
    state = AsyncValue.data(current.where((e) => e.id != id).toList());
  }
}

// --------------------
// Providers (API-compatible with old usage)
// --------------------
// Old: FutureProvider.family<List<SavedSearchModel>, int>
// New: StateNotifierProvider.family<..., AsyncValue<List<SavedSearchModel>>, int>
// ✅ UI usage stays the same: ref.watch(provider).when(...)

final clientSavedSearchesProvider = StateNotifierProvider.family<
    ClientSavedSearchesNotifier,
    AsyncValue<List<SavedSearchModel>>,
    int>((ref, clientId) {
  return ClientSavedSearchesNotifier(ref, clientId);
});

final transactionSavedSearchesProvider = StateNotifierProvider.family<
    TransactionSavedSearchesNotifier,
    AsyncValue<List<SavedSearchModel>>,
    int>((ref, transactionId) {
  return TransactionSavedSearchesNotifier(ref, transactionId);
});

/// Helper: call this after save/update to update lists instantly
void upsertSavedSearchEverywhere({
  required WidgetRef ref,
  required SavedSearchModel model,
  int? clientId,
  int? transactionId,
}) {
  if (clientId != null) {
    ref.read(clientSavedSearchesProvider(clientId).notifier).upsert(model);
  }
  if (transactionId != null) {
    ref
        .read(transactionSavedSearchesProvider(transactionId).notifier)
        .upsert(model);
  }
}
