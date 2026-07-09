import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:portal/models/ad_list_view_model.dart';
import 'package:crm_agent/add_client_form/components/buy/buy_from_filter_components.dart';
import 'package:flutter/foundation.dart';

final crmOfferHoveredPropertyProvider = StateProvider<AdsListViewModel?>((ref) => null);
final showUserContactsProvider = StateProvider<bool>((ref) => false);

final agentTransactionCacheProvider =
    StateNotifierProvider<AgentTransactionCacheNotifier, Map<String, dynamic>>((ref) {
  return AgentTransactionCacheNotifier();
});


class AgentTransactionCacheNotifier extends StateNotifier<Map<String, dynamic>> {
  AgentTransactionCacheNotifier() : super({});

  Map<String, dynamic> filters = {};
  

  void addTransactionData(String key, dynamic value) {
    if (value != null && value.toString().isNotEmpty) {
      filters[key] = value;
      if (kDebugMode) print(filters);
    } else {
      filters.remove(key);
    }
    state = {...state, 'transaction': filters};
    if (kDebugMode) print(state);
  }

  void removeTransactionData(String key) {
    filters.remove(key);
    state = {...state, 'transaction': filters};
  }

  void clearTransactionData(WidgetRef ref) {
    filters.clear();
    state = {};
    ref.read(buyOfferfilterButtonProvider.notifier).clearUiFilters();
  }
}