import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:core/theme/design.dart';
import 'package:portal/screens/filter_landing_page/components/filters_components.dart';

class MarketFiltersWidget extends StatelessWidget {
  final String? currentCountry;
  final double dynamicBoxHeightGroup;
  final double dynamicBoxHeightGroupSmall;
  final dynamic ref;

  const MarketFiltersWidget({
    super.key,
    required this.currentCountry,
    required this.dynamicBoxHeightGroup,
    required this.dynamicBoxHeightGroupSmall,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    bool isLowerThen1400 = MediaQuery.of(context).size.width < 1400;
    bool isLowerThen1200 = MediaQuery.of(context).size.width < 1200;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              'Market type'.tr,
              style: AppTextStyles.interSemiBold16.copyWith(
                color: Theme.of(context).iconTheme.color,
                fontSize: 16.sp,
              ),
            ),
          ],
        ),
        SizedBox(height: dynamicBoxHeightGroupSmall),

        isLowerThen1200
            ? Column(
              children: [
                AspectRatio(
                  aspectRatio: 3,
                  child: FilterButton(
                    text: 'Primary market'.tr,
                    filterValue: 'primary',
                    filterKey: 'market_type',
                  ),
                ),
                SizedBox(height: 8),

                AspectRatio(
                  aspectRatio: 3,
                  child: FilterButton(
                    text: 'Secondary market'.tr,
                    filterValue: 'secondary',
                    filterKey: 'market_type',
                  ),
                ),
              ],
            )
            : Row(
              children: [
                Expanded(
                  child: AspectRatio(
                    aspectRatio: isLowerThen1400 ? 3 : 4,
                    child: FilterButton(
                      text: 'Primary market'.tr,
                      filterValue: 'primary',
                      filterKey: 'market_type',
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: AspectRatio(
                    aspectRatio: isLowerThen1400 ? 3 : 4,
                    child: FilterButton(
                      text: 'Secondary market'.tr,
                      filterValue: 'secondary',
                      filterKey: 'market_type',
                    ),
                  ),
                ),
              ],
            ),
      ],
    );
  }
}
