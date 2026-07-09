import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:portal/screens/filter_landing_page/components/filters_components.dart';
import 'package:core/platform/values.dart';
import 'package:core/theme/design.dart';


class AdditionalInfoWidget extends StatelessWidget {
  final double dynamicBoxHeightGroup; //
  final double dynamicSpace; //
  const AdditionalInfoWidget({
    required this.dynamicBoxHeightGroup,
    required this.dynamicSpace,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    bool isLowerThen1200 = MediaQuery.of(context).size.width < 1200;
    bool isLowerThen1400 = MediaQuery.of(context).size.width < 1400;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              color: Colors.transparent,
              child: Text('additional_info'.tr,
                style: AppTextStyles.interSemiBold16.copyWith(
                  color: Theme.of(context).iconTheme.color,
                  fontSize: 16.sp,),
                ),
            ),
          ],
        ),
        SizedBox(height: dynamicBoxHeightGroup),
        GridView.builder(
          addAutomaticKeepAlives: false,
          addSemanticIndexes: false,
          cacheExtent: 160,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isLowerThen1200 ? 1 : 2, // 2 columns
            mainAxisSpacing: 8.0, // Vertical spacing
            crossAxisSpacing: 8.0, // Horizontal spacing
            childAspectRatio: isLowerThen1400 ? 3 : 4, // Adjust height based on your button size
          ),
          itemCount: additionalFilters.length,
          itemBuilder: (context, index) {
            final filter = additionalFilters[index];
            return AdditionalInfoFilterButton(
              text: filter['text']!,
              filterKey: filter['filterKey']!,
              quickFilter: true,
            );
          },
        )
      ],
    );
  }

  // Pamiętaj, aby zdefiniować metody `NetworkMonitoringAdditionalInfoFilterButton` lub zaimportować je, jeśli są w oddzielnym pliku.
}
