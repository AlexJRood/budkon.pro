import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:portal/models/ad_list_view_model.dart';
import 'package:crm/crm/clients/components/buy_from_filter_components.dart';
import 'package:flutter/foundation.dart';

final crmOfferHoveredPropertyProvider = StateProvider<AdsListViewModel?>((ref) => null);

final buyOfferFilterCacheProvider = StateNotifierProvider<BuyOfferFilterCacheNotifier, Map<String, dynamic>>((ref) {
  return BuyOfferFilterCacheNotifier();
});



class BuyOfferFilterCacheNotifier extends StateNotifier<Map<String, dynamic>> {
  BuyOfferFilterCacheNotifier() : super({});

  Map<String, dynamic> filters = {};
  Map<String, dynamic> savedSearchMeta = {
    'title': '',
    'description': '',
    'tags': '',
    'search_query': '',
  };

  void setSavedSearchField(String key, dynamic value) {
    savedSearchMeta[key] = value ?? '';
    _updateSavedSearchState();
  }
  void prefillFilterButtons(Map<String, dynamic> filters) {
    filters.forEach((key, value) {
      if (value != null) setSavedSearchField(key, value);
    });
  }

  void addFilter(String key, dynamic value) {
    if (value != null && value.toString().isNotEmpty) {
      filters[key] = value;
    } else {
      filters.remove(key);
    }
    _updateSavedSearchState();
  }

  void removeFilter(String key) {
    filters.remove(key);
    _updateSavedSearchState();
  }

  void clearFilters(WidgetRef ref) {
    filters.clear();
    savedSearchMeta = {
      'title': '',
      'description': '',
      'tags': '',
      'search_query': '',
    };
    state = {};
    ref.read(buyOfferfilterButtonProvider.notifier).clearUiFilters();
  }

  void _updateSavedSearchState() {
    state = {
      ...state,
      'saved_search': {
        ...savedSearchMeta,
        'filters': filters,
      },
    };
    if (kDebugMode) print(state);
  }
}
