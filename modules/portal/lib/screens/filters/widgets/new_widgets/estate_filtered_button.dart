import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:portal/screens/filter_landing_page/providers/filter_provider.dart';
import 'package:portal/screens/filter_landing_page/filters_landing_page.dart';

class EstateTypeFilteredButton extends ConsumerWidget {
  final String text;
  final String filterKey;
  final String filterValue;

  const EstateTypeFilteredButton({
    super.key,
    required this.text,
    required this.filterKey,
    required this.filterValue,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    /// Get selected value (only one allowed)
    final List<String> selectedValues = List<String>.from(
        ref.watch(filterButtonProvider.select((state) => state[filterKey] ?? [])));

    final bool isSelected = selectedValues.isNotEmpty && selectedValues.first == filterValue;

    const selectedBackgroundColor = Color.fromRGBO(200, 200, 200, 1);
    const selectedTextColor = Color.fromRGBO(35, 35, 35, 1);
    const unselectedTextColor = Color.fromRGBO(255, 255, 255, 1);

    return InkWell(
      onTap: () {
        List<String> newSelection = isSelected ? [] : [filterValue]; // ✅ Only one selection allowed

        ref.read(filterButtonProvider.notifier).updateFilter(filterKey, newSelection);
        ref.read(filterCacheProvider.notifier).addFilter(filterKey, newSelection.join(','));
      },
      child: Container(
        constraints: const BoxConstraints(minWidth: 175, minHeight: 48),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? selectedBackgroundColor : null,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? null : Border.all(color: Colors.grey),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            maxLines: 1,
            style: TextStyle(
              color: isSelected ? selectedTextColor : unselectedTextColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
