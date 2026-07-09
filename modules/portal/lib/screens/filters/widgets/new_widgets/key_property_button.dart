import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:portal/screens/filter_landing_page/providers/filter_provider.dart';
import 'package:portal/screens/filter_landing_page/components/filters_components.dart';

class KeyPropertyButton extends ConsumerWidget {
  final String text;
  final String filterKey;
  final String filterValue;

  const KeyPropertyButton({
    super.key,
    required this.text,
    required this.filterKey,
    required this.filterValue,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const selectedBackgroundColor = Color.fromRGBO(200, 200, 200, 1);
    const selectedTextColor =Color.fromRGBO(35, 35, 35, 1);

    const unselectedTextColor = Color.fromRGBO(255, 255, 255, 1);
    final bool isSelected = ref.watch(filterButtonProvider
        .select((state) => state[filterKey] == filterValue));

    return InkWell(
      onTap: () {
        final filterNotifier = ref.read(filterCacheProvider.notifier);
        if (isSelected) {
          ref.read(filterButtonProvider.notifier).updateFilter(filterKey, null);
          filterNotifier.removeFilter(filterKey);
        } else {
          ref
              .read(filterButtonProvider.notifier)
              .updateFilter(filterKey, filterValue);
          filterNotifier.addFilter(filterKey, filterValue);
        }
      },
      child: Container(
        constraints: const BoxConstraints(
          minHeight: 48
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16), // Add padding for better spacing
        decoration: BoxDecoration(
          color: isSelected ? selectedBackgroundColor : null,
          borderRadius: BorderRadius.circular(8), // Add rounded corners
          border: isSelected ? null : Border.all(color: Colors.grey), // Border for unselected state
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? selectedTextColor : unselectedTextColor,
            fontWeight: FontWeight.bold, // Make text bold for better visibility
            fontSize: 14, // Set a readable font size
          ),
        ),
      ),

    );
  }
}
