import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:portal/screens/filter_landing_page/providers/filter_provider.dart';
import 'package:portal/screens/filter_landing_page/filters_landing_page.dart';

class AdditionalInfoFilteredButton extends ConsumerWidget {
  final String text;
  final String filterKey;

  const AdditionalInfoFilteredButton({
    super.key,
    required this.text,
    required this.filterKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Constants for selected and unselected states
    const selectedBackgroundColor = Color.fromRGBO(200, 200, 200, 1);
    const selectedTextColor = Color.fromRGBO(35, 35, 35, 1);
    const unselectedTextColor = Color.fromRGBO(255, 255, 255, 1);

    final bool isSelected = ref.watch(
      filterButtonProvider.select((state) => state[filterKey] ?? false),
    );

    return InkWell(
      onTap: () {
        final filterNotifier = ref.read(filterCacheProvider.notifier);
        if (isSelected) {
          ref.read(filterButtonProvider.notifier).updateFilter(filterKey, false);
          filterNotifier.removeFilter(filterKey);
        } else {
          ref.read(filterButtonProvider.notifier).updateFilter(filterKey, true);
          filterNotifier.addFilter(filterKey, 'true');
        }
      },
      child: Container(
        constraints: const BoxConstraints(
          minWidth: 120,
          minHeight: 48
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? selectedBackgroundColor : null,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? null : Border.all(color: Colors.grey),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? selectedTextColor : unselectedTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
