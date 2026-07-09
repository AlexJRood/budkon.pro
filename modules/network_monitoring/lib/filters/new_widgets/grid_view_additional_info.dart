

import 'package:flutter/material.dart';

import 'package:network_monitoring/filters/new_widgets/additional_info_filtered_button.dart';

class GridViewAdditionalInfo extends StatelessWidget {
  final List<Map<String, String>> additionalInfo;

  const GridViewAdditionalInfo({
    super.key,
    required this.additionalInfo,
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
        childAspectRatio: 3.5, // Adjust aspect ratio
      ),
      itemCount: additionalInfo.length,
      itemBuilder: (context, index) {
        final info = additionalInfo[index];
        return AdditionalInfoFilteredButton(
          text: info['text']!,
          filterKey: info['filterKey']!,
        );
      },
    );
  }
}
