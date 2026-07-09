import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sortButtonProvider =
    StateNotifierProvider<SortButtonNotifier, Map<String, dynamic>>((ref) {
  return SortButtonNotifier();
});

class SortButtonNotifier extends StateNotifier<Map<String, dynamic>> {
  SortButtonNotifier() : super({});
  void updateFilter(String key, dynamic value) {
    state = {...state, key: value};
  }

  void updateRangeFilter(String key, RangeValues values) {
    state = {...state, key: values};
  }

  void clearUiFilters() {
    state = {};
  }
}

