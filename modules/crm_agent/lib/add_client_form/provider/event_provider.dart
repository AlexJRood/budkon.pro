import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:portal/models/ad_list_view_model.dart';
import 'package:crm_agent/add_client_form/components/sell/sell_data_components.dart';
import 'package:flutter/foundation.dart';

final crmOfferHoveredPropertyProvider = StateProvider<AdsListViewModel?>((ref) => null);

final sellOfferFilterCacheProvider =
    StateNotifierProvider<SellOfferFilterCacheNotifier, Map<String, dynamic>>((ref) {
  return SellOfferFilterCacheNotifier();
});


class SellOfferFilterCacheNotifier extends StateNotifier<Map<String, dynamic>> {
  SellOfferFilterCacheNotifier() : super({});

  Map<String, dynamic> adDraft = {};
  

  void addEventData(String key, dynamic value) {
    if (value != null && value.toString().isNotEmpty) {
      adDraft[key] = value;
      if (kDebugMode) print(adDraft);
    } else {
      adDraft.remove(key);
    }
    state = {...state, 'filters': adDraft};
    if (kDebugMode) print(state);
  }

  void removeEventData(String key) {
    adDraft.remove(key);
    state = {...state, 'filters': adDraft};
  }

  void clearEventData(WidgetRef ref) {
    adDraft.clear();
    state = {};
    ref.read(sellOfferfilterButtonProvider.notifier).clearUiFilters();
  }
}