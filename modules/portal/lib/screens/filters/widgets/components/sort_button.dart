import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:portal/screens/filter_landing_page/providers/filter_provider.dart';
import 'package:core/theme/apptheme.dart';

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

class FilterSortButton extends ConsumerWidget {
  final String text;
  final String filterKey;
  final String filterValue;
  final IconData icon;

  const FilterSortButton({
    super.key,
    required this.text,
    required this.filterKey,
    required this.filterValue,
    required this.icon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final bool isSelected = ref.watch(
        sortButtonProvider.select((state) => state[filterKey] == filterValue));

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon,
            color: isSelected ? theme.themeColor : theme.textColor),
        label: Text(text,
            style: TextStyle(
                color: isSelected ? theme.themeColor : theme.textColor)),
        onPressed: () {
          ref
              .read(sortButtonProvider.notifier)
              .updateFilter(filterKey, filterValue);
          ref
              .read(filterCacheProvider.notifier)
              .addFilter(filterKey, filterValue);
          ref.read(filterCacheProvider.notifier).setSortOrder(filterValue);
          ref
              .read(filterProvider.notifier)
              .applyFiltersFromCache(
                  ref.read(filterCacheProvider.notifier), ref);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(0)),
          side: isSelected
              ? BorderSide(color: theme.themeColor, width: 2)
              : BorderSide.none,
        ),
      ),
    );
  }
}
