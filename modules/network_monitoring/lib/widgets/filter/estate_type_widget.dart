import 'package:flutter/material.dart';
import 'package:core/platform/values.dart';
import 'package:core/theme/design.dart';
import 'package:network_monitoring/widgets/filter/fileds.dart';
import 'package:get/get_utils/get_utils.dart';

class EstateTypeWidget extends StatelessWidget {
  final double dynamicSpace;
  final double dynamicBoxHeightGroupSmall;
  final bool isTablet;

  const EstateTypeWidget({
    super.key,
    required this.dynamicSpace,
    required this.dynamicBoxHeightGroupSmall,
    this.isTablet = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              color: Colors.transparent,
              child: Text(
                'property_type'.tr,
                style: (isTablet
                        ? AppTextStyles.interSemiBold
                        : AppTextStyles.interSemiBold16)
                    .copyWith(color: Theme.of(context).iconTheme.color),
              ),
            ),
          ],
        ),
        SizedBox(height: isTablet ? 8 : dynamicBoxHeightGroupSmall),
        GridView.builder(
          addAutomaticKeepAlives: false,
          addSemanticIndexes: false,
          cacheExtent: 160,
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(), // Prevents nested scrolling issues
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isTablet ? 1 : 2, // 1 column on tablet, 2 otherwise
            mainAxisSpacing: isTablet ? 8.0 : 8.0, // Vertical spacing
            crossAxisSpacing: 8.0, // Horizontal spacing
            childAspectRatio:
                isTablet ? 6 : 4, // Adjust height based on button size
          ),
          itemCount: estateFilters.length,
          itemBuilder: (context, index) {
            final filter = estateFilters[index];
            return NetworkMonitoringEstateTypeFilterButton(
              text: filter['text']!.tr,
              filterValue: filter['filterValue']!,
              filterKey: 'estate_type',
              isTablet: isTablet,
            );
          },
        ),
      ],
    );
  }
}
