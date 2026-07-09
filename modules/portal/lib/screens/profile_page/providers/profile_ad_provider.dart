//your_add_provider

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/url.dart';
import 'package:portal/models/your_ads_listview_model.dart';
import 'package:core/user/user/user_provider.dart';
import 'package:core/platform/api_services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Uwzględnienie wszystkich innych potrzebnych importów

class YourAdsLogicNotifier
    extends StateNotifier<AsyncValue<List<YourAdsListViewModel>>> {
  final Ref ref;

  YourAdsLogicNotifier(this.ref) : super(const AsyncValue.loading()) {
    _loadYourAds();
  }

  Map<String, dynamic> filters = {};
  String searchQuery = '';
  String excludeQuery = '';
  String sortOrder = '';

  Future<void> _loadYourAds() async {
    final prefs = await SharedPreferences.getInstance();
    searchQuery = prefs.getString('searchQuery') ?? '';
    excludeQuery = prefs.getString('excludeQuery') ?? '';
    // Załaduj inne filtry, jeśli są potrzebne

    // Po załadowaniu filtrów zastosuj je
    applyYourAdsFilters();
  }

  Future<void> _saveYourAdsFilters() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('searchQuery', searchQuery);
    await prefs.setString('excludeQuery', excludeQuery);
    // Zapisz inne filtry, jeśli są potrzebne
  }

  void setSortYourAdsOrder(String order) {
    sortOrder = order;
    _saveYourAdsFilters();
    applyYourAdsFilters();
  }

  void setSearchYourAdsQuery(String query) {
    searchQuery = query;
    _saveYourAdsFilters();
    applyYourAdsFilters();
  }

  void setExcludeYourAdsQuery(String query) {
    excludeQuery = query;
    _saveYourAdsFilters();
    applyYourAdsFilters();
  }

  void addYourAdsFilter(String key, dynamic value) {
    if (value != null && value.toString().isNotEmpty) {
      filters[key] = value;
    } else {
      filters.remove(key);
    }
    _saveYourAdsFilters();
    applyYourAdsFilters();
  }

  void removeYourAdsFilter(String key) {
    filters.remove(key);
    _saveYourAdsFilters();
    applyYourAdsFilters();
  }

  void clearYourAdsFilters() {
    filters.clear();
    searchQuery = '';
    excludeQuery = '';
    _saveYourAdsFilters();
    applyYourAdsFilters();
  }

  Future<void> applyYourAdsFilters() async {
    state = const AsyncValue.loading();
    
    final user = ref.read(userStateProvider);

    final iDUser = user?.userId;

    final queryParameters = {
      ...filters,
      if (searchQuery.isNotEmpty) 'search': searchQuery,
      if (excludeQuery.isNotEmpty) 'exclude': excludeQuery,
      if (sortOrder.isNotEmpty) 'sort': sortOrder,
    };

    try {
      final response = await ApiServices.get(
        ref: ref,
        URLs.advertiseBaseUser('$iDUser'),
        queryParameters: queryParameters,
      );

      if (response != null && response.statusCode == 200) {

        
    final decodedBody = utf8.decode(response.data);
    final listingsJson = json.decode(decodedBody) as Map<dynamic, dynamic>;
    final newList = listingsJson['results'] as List<dynamic>;
         
        final ads = newList.map((item) =>YourAdsListViewModel.fromJson(item as Map<String, dynamic>)).toList();
        state = AsyncValue.data(ads);
      } else {
        state = AsyncValue.error(
            'Failed to load advertisements', StackTrace.current);
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  void removeAdFromList(int adId) {
    final current = state.valueOrNull ?? [];

    final updated = current
        .where((ad) => ad.id.toString() != adId.toString())
        .toList();

    state = AsyncValue.data(updated);
  }
}

final yourAdsFilterProvider = StateNotifierProvider<YourAdsLogicNotifier,
    AsyncValue<List<YourAdsListViewModel>>>((ref) {
  return YourAdsLogicNotifier(ref);
});
