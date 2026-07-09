import 'package:flutter/material.dart';

import 'package:network_monitoring/filters/new_widgets/estate_filtered_button.dart';

class GridViewEstateTypes extends StatelessWidget {
  final List<Map<String, String>> estateTypes;

  const GridViewEstateTypes({
    super.key,
    required this.estateTypes,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      addAutomaticKeepAlives: false,
      addSemanticIndexes: false,
      cacheExtent: 160,
      shrinkWrap: true,
      padding: const EdgeInsets.all(0),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // Two items per row
        crossAxisSpacing: 12, // Spacing between columns
        mainAxisSpacing: 12, // Spacing between rows
        childAspectRatio: 3.5, // Adjust aspect ratio to match the screenshot
      ),
      itemCount: estateTypes.length,
      itemBuilder: (context, index) {
        final estateType = estateTypes[index];
        return EstateTypeFilteredButton(
          text: estateType['text']!,
          filterKey: 'estate_type',
          filterValue: estateType['filterValue']!,
        );
      },
    );
  }
}
