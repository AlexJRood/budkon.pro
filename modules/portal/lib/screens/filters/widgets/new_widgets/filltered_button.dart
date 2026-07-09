import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:portal/screens/filter_landing_page/providers/filter_provider.dart';
import 'package:portal/screens/filter_landing_page/components/filters_components.dart';

class FilteredButton extends ConsumerWidget {
  final String text;
  final String filterKey;
  final String filterValue;
  final double? minHeight;
  final double? minWidth;
  final AlignmentGeometry? alignment;

  const FilteredButton({
    super.key,
    required this.text,
    required this.filterKey,
    required this.filterValue,
    this.minHeight,
    this.minWidth,
    this.alignment,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const selectedBackgroundColor = Color.fromRGBO(200, 200, 200, 1);
    const selectedTextColor = Color.fromRGBO(35, 35, 35, 1);

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
        constraints: (minHeight != null || minWidth != null)
            ? BoxConstraints(
          minHeight: minHeight ?? 0,
          minWidth: minWidth ?? 0,
        )
            : null,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
        alignment: alignment ?? Alignment.centerLeft,
        decoration: BoxDecoration(
          color: isSelected ? selectedBackgroundColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.grey : Colors.grey,
          ),
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
