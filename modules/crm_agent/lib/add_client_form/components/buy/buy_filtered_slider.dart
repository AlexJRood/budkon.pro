import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:portal/screens/filter_landing_page/providers/filter_provider.dart';
import 'package:portal/screens/filter_landing_page/components/filters_components.dart';
import 'package:core/theme/apptheme.dart';

class CrmAddFilteredSlider extends ConsumerWidget {
  final String filterKey;
  final double min;
  final double max;

  const CrmAddFilteredSlider({
    super.key,
    required this.filterKey,
    this.min = -1,
    this.max = 50,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch current filter state
    final rangeValues = ref.watch(
      filterButtonProvider.select(
        (state) => state[filterKey] ?? RangeValues(min, max),
      ),
    );
    final theme = ref.watch(themeColorsProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Display the start value
        Text(
          rangeValues.start.round().toString(),
          style: TextStyle(color: theme.textColor),
        ),

        // RangeSlider widget in the middle
        Expanded(
          child: RangeSlider(
            activeColor: theme.themeColor,
            values: rangeValues,
            min: min,
            max: max,
            divisions: (max - min).toInt(),
            onChanged: (RangeValues values) {
              // Calculate the difference between the selected start and end values
              final floorDifference = (values.end - values.start).round();

              // Create a map to store min, max, and the calculated difference
              final floorRange = {
                'min': values.start.round(),
                'max': values.end.round(),
                'difference': floorDifference,
              };

              // Update the provider with the new range values
              ref
                  .read(filterButtonProvider.notifier)
                  .updateFilter(filterKey, values);

              final filterNotifier = ref.read(filterCacheProvider.notifier);
              // Add the floor range map to the filter cache with the specified filterKey
              filterNotifier.addFilter(filterKey, floorRange);

              // Print the updated filter value for debugging
            },
          ),
        ),

        // Display the end value
        Text(
          rangeValues.end.round().toString(),
          style: TextStyle(color: theme.textColor),
        ),
      ],
    );
  }
}
