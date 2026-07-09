import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:core/platform/values.dart';
import 'package:core/theme/design.dart';
import 'package:portal/screens/filter_landing_page/components/filters_components.dart';

class EstateTypeWidget extends StatelessWidget {
  final double dynamicSpace;
  final double dynamicBoxHeightGroupSmall;

  const EstateTypeWidget({
    super.key,
    required this.dynamicSpace,
    required this.dynamicBoxHeightGroupSmall,
  });

  @override
  Widget build(BuildContext context) {
    bool isLowerThen1200 = MediaQuery.of(context).size.width < 1200;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              color: Colors.transparent,
              child: Text('property_type'.tr,
                style: AppTextStyles.interSemiBold16.copyWith(
                  color: Theme.of(context).iconTheme.color,
                  fontSize: 16.sp,),
                ),
            ),
          ],
        ),
        SizedBox(height: dynamicBoxHeightGroupSmall),
        GridView.builder(
          addAutomaticKeepAlives: false,
          addSemanticIndexes: false,
          cacheExtent: 160,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isLowerThen1200 ? 1 : 2,
            mainAxisSpacing: 8.0,
            crossAxisSpacing: 8.0,
            mainAxisExtent: 40,
          ),
          itemCount: estateFilters.length,
          itemBuilder: (context, index) {
            final filter = estateFilters[index];
            return EstateTypeFilterButton(
              quickFilter: true,
              text: filter['text']!.tr,
              filterValue: filter['filterValue']!,
              filterKey: 'estate_type',
            );
          },
        )
      ],
    );
  }
}
