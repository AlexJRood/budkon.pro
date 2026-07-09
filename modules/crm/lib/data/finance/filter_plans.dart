import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';


class Filters {
  final List<int> years;
  final List<int> months;
  final String ordering;
  final String selectedList;

  Filters({
    this.years = const [],
    this.months = const [],
    this.ordering = 'amount',
    String? selectedList,           // accept nullable
  }) : selectedList = selectedList ?? 'Revenue'.tr;  // evaluate at runtime



  Filters copyWith({
    List<int>? years,
    List<int>? months,
    String? ordering,
    String? selectedList, // Include selectedList in copyWith
  }) {
    return Filters(
      years: years ?? this.years,
      months: months ?? this.months,
      ordering: ordering ?? this.ordering,
      selectedList: selectedList ?? this.selectedList,
    );
  }
}

final filtersPlansProvider =
    StateNotifierProvider<FiltersNotifier, Filters>((ref) {
  return FiltersNotifier();
});

class FiltersNotifier extends StateNotifier<Filters> {
  FiltersNotifier() : super(_initialFilters()) {
    // Inicjalizacja z bieżącym rokiem i miesiącem
  }

  static Filters _initialFilters() {
    final now = DateTime.now();
    return Filters(
      years: [now.year],
      months: [now.month],
      ordering: 'amount', // Domyślne sortowanie, jeśli potrzebne
    );
  }

  void toggleYear(int year) {
    if (state.years.contains(year)) {
      state =
          state.copyWith(years: state.years.where((y) => y != year).toList());
    } else {
      state = state.copyWith(years: [...state.years, year]);
    }
  }

  void setYear(int year) {
    state = state.copyWith(years: [year]);
  }

  void toggleMonth(int month) {
    if (state.months.contains(month)) {
      state = state.copyWith(
          months: state.months.where((m) => m != month).toList());
    } else {
      state = state.copyWith(months: [...state.months, month]);
    }
  }

  void setMonth(int month) {
    state = state.copyWith(months: [month]);
  }

  void setOrdering(String ordering) {
    state = state.copyWith(ordering: ordering);
  }

  void clearYears() {
    state = state.copyWith(years: []);
  }

  void clearMonths() {
    state = state.copyWith(months: []);
  }

  void clearFilters() {
    final now = DateTime.now();
    state = Filters(
      years: [now.year],
      months: [now.month],
      ordering: 'amount',
    );
  }

  void setSelectedList(String list) {
    state = state.copyWith(selectedList: list);
  }
}
