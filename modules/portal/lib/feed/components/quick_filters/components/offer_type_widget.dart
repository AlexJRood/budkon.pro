import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:core/theme/design.dart';
import 'package:portal/screens/filter_landing_page/components/filters_components.dart';

class OfferTypeWidget extends StatelessWidget {
  final double dynamicBoxHeightGroupSmall;
  const OfferTypeWidget({required this.dynamicBoxHeightGroupSmall, super.key});

  @override
  Widget build(BuildContext context) {
    bool isLowerThen1200 = MediaQuery.of(context).size.width < 1200;

    return Column(
      spacing: dynamicBoxHeightGroupSmall,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Material(
              color: Colors.transparent,
              child: Text(
                'Typ oferty'.tr,
                style: AppTextStyles.interSemiBold16.copyWith(
                  color: Theme.of(context).iconTheme.color,
                  fontSize: 16.sp,
                ),
              ),
            ),
          ],
        ),
        isLowerThen1200
            ? Column(
              children: [
                SizedBox(
                  height: 40,
                  child: FilterButton(
                    text: 'offer_type_sell'.tr,
                    filterValue: 'sell',
                    filterKey: 'offer_type',
                  ),
                ),
                SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: FilterButton(
                    text: 'offer_type_rent'.tr,
                    filterValue: 'rent',
                    filterKey: 'offer_type',
                  ),
                ),
              ],
            )
            : Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: FilterButton(
                      text: 'offer_type_sell'.tr,
                      filterValue: 'sell',
                      filterKey: 'offer_type',
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: FilterButton(
                      text: 'offer_type_rent'.tr,
                      filterValue: 'rent',
                      filterKey: 'offer_type',
                    ),
                  ),
                ),
              ],
            ),
      ],
    );
  }
}
