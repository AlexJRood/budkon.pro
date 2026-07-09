import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:portal/screens/filter_landing_page/providers/filter_cntrl.dart';
import 'package:core/platform/values.dart';
import 'package:core/theme/design.dart';
import 'package:portal/screens/filter_landing_page/components/filters_components.dart';

class FiltersWidget extends StatelessWidget {
  final LandingFilterControllers controllers;

  final double dynamicBoxHeightGroupSmall;
  final double dynamiSpacerBoxWidth;
  final double dynamicBoxHeightGroup;
  final double dynamicBoxHeight;
  final double dynamicSpace;
  final dynamic ref;

  const FiltersWidget({
    super.key,
    required this.controllers,

    required this.dynamicBoxHeightGroupSmall,
    required this.dynamiSpacerBoxWidth,
    required this.dynamicBoxHeightGroup,
    required this.dynamicBoxHeight,
    required this.dynamicSpace,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    bool isLowerThen1350 = MediaQuery.of(context).size.width < 1350;
    bool isLowerThen1000 = MediaQuery.of(context).size.width < 1000;
    bool isBtw800And1000 =
        MediaQuery.of(context).size.width < 1000 &&
        MediaQuery.of(context).size.width > 800;

    bool isBtw800And1200 =
        MediaQuery.of(context).size.width < 1200 &&
        MediaQuery.of(context).size.width > 800;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Material(
              color: Colors.transparent,
              child: Text(
                'Filters'.tr,
                style: AppTextStyles.interSemiBold16.copyWith(
                  color: Theme.of(context).iconTheme.color,
                  fontSize: 16.sp,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: dynamicBoxHeightGroupSmall),
        IntrinsicHeight(
          child: Column(
            children: [
              isLowerThen1350
                  ? Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      BuildNumberField(
                        controller: controllers.minSquareFootageController,
                        labelText: 'Area from'.tr,
                        filterKey: 'min_square_footage',
                      ),
                      SizedBox(height: dynamicBoxHeightGroup),
                      BuildNumberField(
                        controller: controllers.maxSquareFootageController,
                        labelText: 'Area to'.tr,
                        filterKey: 'max_square_footage',
                      ),
                    ],
                  )
                  : Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Expanded(
                        child: BuildNumberField(
                          controller: controllers.minSquareFootageController,
                          labelText: 'Area from'.tr,
                          filterKey: 'min_square_footage',
                        ),
                      ),
                      SizedBox(width: dynamiSpacerBoxWidth),
                      Expanded(
                        child: BuildNumberField(
                          controller: controllers.maxSquareFootageController,
                          labelText: 'Area to'.tr,
                          filterKey: 'max_square_footage',
                        ),
                      ),
                    ],
                  ),

              SizedBox(height: dynamicBoxHeightGroup),

              isLowerThen1350
                  ? Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      BuildNumberField(
                        controller: controllers.minPriceController,
                        labelText: 'Price from'.tr,
                        filterKey: 'min_price',
                      ),
                      SizedBox(height: dynamicBoxHeightGroup),
                      BuildNumberField(
                        controller: controllers.maxPriceController,
                        labelText: 'Price to'.tr,
                        filterKey: 'max_price',
                      ),
                    ],
                  )
                  : Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Expanded(
                        child: BuildNumberField(
                          controller: controllers.minPriceController,
                          labelText: 'Price from'.tr,
                          filterKey: 'min_price',
                        ),
                      ),
                      SizedBox(width: dynamiSpacerBoxWidth),
                      Expanded(
                        child: BuildNumberField(
                          controller: controllers.maxPriceController,
                          labelText: 'Price to'.tr,
                          filterKey: 'max_price',
                        ),
                      ),
                    ],
                  ),

              SizedBox(height: dynamicBoxHeight),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: Text(
                          'Room number'.tr,
                          style: AppTextStyles.interSemiBold16.copyWith(
                            color: Theme.of(context).iconTheme.color,
                            fontSize: 16.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: dynamicBoxHeightGroup),
                  SizedBox(
                    height: isBtw800And1000 ? 200 : 145,
                    child: GridView.builder(
                      addAutomaticKeepAlives: false,
                      addSemanticIndexes: false,
                      cacheExtent: 160,
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(), // Prevents nested scrolling issues
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount:
                            isLowerThen1000 || isBtw800And1200
                                ? 2
                                : 3, // 2 columns
                        crossAxisSpacing: 8.0, // Horizontal spacing
                        mainAxisSpacing: 8,
                        childAspectRatio: 2,
                      ),
                      itemCount: roomFilters.length,
                      itemBuilder: (context, index) {
                        final filter = roomFilters[index];
                        return FilterButton(
                          text: filter['text']!,
                          filterValue: filter['filterValue']!,
                          filterKey: 'rooms',
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
