import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:core/platform/values.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:network_monitoring/widgets/filter/fileds.dart';


class FiltersWidget extends ConsumerStatefulWidget {
  final TextEditingController minSquareFootageController;
  final TextEditingController maxSquareFootageController;
  final TextEditingController minPriceController;
  final TextEditingController maxPriceController;
  final TextEditingController minPricePerMeterController;
  final TextEditingController maxPricePerMeterController;
  final TextEditingController minRoomsController;
  final TextEditingController maxRoomsController;
  final double dynamicBoxHeightGroupSmall;
  final double dynamiSpacerBoxWidth;
  final double dynamicBoxHeightGroup;
  final double dynamicBoxHeight;
  final double dynamicSpace;
  final bool isTablet;
  final dynamic ref;

  const FiltersWidget({
    super.key,
    required this.minSquareFootageController,
    required this.maxSquareFootageController,
    required this.minPriceController,
    required this.maxPriceController,
    required this.minPricePerMeterController,
    required this.maxPricePerMeterController,
    required this.minRoomsController,
    required this.maxRoomsController,
    required this.dynamicBoxHeightGroupSmall,
    required this.dynamiSpacerBoxWidth,
    required this.dynamicBoxHeightGroup,
    required this.dynamicBoxHeight,
    required this.dynamicSpace,
    this.isTablet = false,
    required this.ref,
  });

  @override
  ConsumerState<FiltersWidget> createState() => _FiltersWidgetState();
}

class _FiltersWidgetState extends ConsumerState<FiltersWidget> {

  final areaFromFocus = FocusNode();
  final areaToFocus = FocusNode();
  final priceFromFocus = FocusNode();
  final priceToFocus = FocusNode();

  final areaFromKey = GlobalKey();
  final areaToKey = GlobalKey();
  final priceFromKey = GlobalKey();
  final priceToKey = GlobalKey();
  void _scrollToField(GlobalKey key) {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      final fieldContext = key.currentContext;
      if (fieldContext == null) return;

      Scrollable.ensureVisible(
        fieldContext,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
        alignment: 0.15,
        alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
      );
    });
  }

  @override
  void initState() {
    super.initState();

    areaFromFocus.addListener(() {
      if (areaFromFocus.hasFocus) _scrollToField(areaFromKey);
    });
    areaToFocus.addListener(() {
      if (areaToFocus.hasFocus) _scrollToField(areaToKey);
    });
    priceFromFocus.addListener(() {
      if (priceFromFocus.hasFocus) _scrollToField(priceFromKey);
    });
    priceToFocus.addListener(() {
      if (priceToFocus.hasFocus) _scrollToField(priceToKey);
    });
  }

  @override
  void dispose() {
    areaFromFocus.dispose();
    areaToFocus.dispose();
    priceFromFocus.dispose();
    priceToFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.ref.read(themeColorsProvider);

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
                style: (widget.isTablet
                        ? AppTextStyles.interSemiBold
                        : AppTextStyles.interSemiBold16)
                    .copyWith(color: theme.textColor),
              ),
            ),
          ],
        ),
        SizedBox(height: widget.isTablet ? 4 : widget.dynamicBoxHeightGroupSmall),
        Column(
          children: [
            widget.isTablet
                ? Column(
                  spacing: 8,
                  children: [
                    BuildNumberField(
                      controller: widget.minSquareFootageController,
                      labelText: 'Area from'.tr,
                      filterKey: 'min_square_footage',
                      isTablet: widget.isTablet,
                    ),
                    BuildNumberField(
                      controller: widget.maxSquareFootageController,
                      labelText: 'Area to'.tr,
                      filterKey: 'max_square_footage',
                      isTablet: widget.isTablet,
                    ),
                  ],
                )
                : Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Expanded(
                    child: Container(
                      key: areaFromKey,
                        child: BuildNumberField(
                          controller: widget.minSquareFootageController,
                          labelText: 'area_from'.tr,
                          filterKey: 'min_square_footage',
                        focusNode: areaFromFocus,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => areaToFocus.requestFocus(),
                        isTablet: widget.isTablet,
                      ),
                          
                      ),
                    ),
                    SizedBox(width: widget.dynamiSpacerBoxWidth),
                    Expanded(
                    child: Container(
                      key: areaToKey,
                        child: BuildNumberField(
                          controller: widget.maxSquareFootageController,
                          labelText: 'area_to'.tr,
                          filterKey: 'max_square_footage',
                        focusNode: areaToFocus,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => priceFromFocus.requestFocus(),
                        isTablet: widget.isTablet,
                      ),
                        
                      ),
                    ),
                  ],
                ),
            SizedBox(height: widget.isTablet ? 4 : widget.dynamicBoxHeightGroup),
            widget.isTablet
                ? Column(
                  spacing: 8,
                  children: [
                    BuildNumberField(
                      controller:widget.minPriceController,
                      labelText: 'Price from'.tr,
                      filterKey: 'min_price',
                      isTablet: widget.isTablet,
                    ),
                    BuildNumberField(
                      controller: widget.maxPriceController,
                      labelText: 'Price to'.tr,
                      filterKey: 'max_price',
                      isTablet: widget.isTablet,
                    ),
                  ],
                )
                : Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        key: priceFromKey,
                        child: BuildNumberField(
                          controller: widget.minPriceController,
                          labelText: 'price_from'.tr,
                          filterKey: 'min_price',
                          focusNode: priceFromFocus,
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) => priceToFocus.requestFocus(),
                          isTablet: widget.isTablet,
                        ),
                      ),
                    ),
                    SizedBox(width: widget.dynamiSpacerBoxWidth),
                    Expanded(
                      child: Container(
                        key: priceToKey,
                        child: BuildNumberField(
                          controller: widget.maxPriceController,
                          labelText: 'price_to'.tr,
                          filterKey: 'max_price',
                          focusNode: priceToFocus,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => priceToFocus.unfocus(),
                        ),
                      ),
                    ),
                  ],
                ),
                ],
              ),
              // SizedBox(height: dynamicBoxHeightGroup),
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.start,
              //   children: [
              //     Expanded(
              //       child: BuildNumberField(
              //         controller: minPricePerMeterController,
              //         labelText: 'Cena za metr od'.tr,
              //         filterKey: 'min_price_per_meter',
              //       ),
              //     ),
              //     SizedBox(width: dynamiSpacerBoxWidth),
              //     Expanded(
              //       child: BuildNumberField(
              //         controller: maxPricePerMeterController,
              //         labelText: 'Cena za metr do'.tr,
              //         filterKey: 'max_price_per_meter',
              //       ),
              //     ),
              //   ],
              // ),
              // SizedBox(height: dynamicBoxHeightGroup),
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.start,
              //   children: [
              //     Expanded(
              //       child: BuildNumberField(
              //         controller: minRoomsController,
              //         labelText: 'Rok budowy od'.tr,
              //         filterKey: 'min_build_year',
              //       ),
              //     ),
              //     SizedBox(width: dynamiSpacerBoxWidth),
              //     Expanded(
              //       child: BuildNumberField(
              //         controller: maxRoomsController,
              //         labelText: 'Rok budowy do'.tr,
              //         filterKey: 'max_build_year',
              //       ),
              //     ),
              //   ],
              // ),
              SizedBox(height: widget.dynamicBoxHeight),
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
                          'room_number'.tr,

                  style: AppTextStyles.interSemiBold16
                      .copyWith(color: theme.textColor)),
                      ),
                    ],
                  ),
                  SizedBox(height: widget.dynamicBoxHeightGroup),
                  AutoHeightGrid(
                    itemCount: roomFilters.length,
                    crossAxisCount: 6,
                    crossAxisSpacing: 8.0,
                    childAspectRatio: 1,
                    itemBuilder: (context, index) {
                      final filter = roomFilters[index];
                      return NetworkMonitoringEstateTypeFilterButton(
                        text: filter['text']!,
                        filterValue: filter['filterValue']!,
                        filterKey: 'rooms',
                      );
                    },
                  )

                ],
              ),
            ],
          
        
      
    );
  }
}

class AutoHeightGrid extends StatelessWidget {
  const AutoHeightGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.crossAxisCount = 6,
    this.crossAxisSpacing = 8.0,
    this.mainAxisSpacing = 8.0,
    this.childAspectRatio = 1.0,
    this.padding = EdgeInsets.zero,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final double childAspectRatio;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pad = padding.resolve(Directionality.of(context));
        final usableWidth = constraints.maxWidth - pad.horizontal;
        final itemWidth =
            (usableWidth - (crossAxisCount - 1) * crossAxisSpacing) /
            crossAxisCount;
        final itemHeight = itemWidth / childAspectRatio;

        final rows = (itemCount + crossAxisCount - 1) ~/ crossAxisCount;
        final gridHeight =
            pad.vertical + rows * itemHeight + (rows - 1) * mainAxisSpacing;

        return SizedBox(
          height: gridHeight,
          child: GridView.builder(
            padding: padding,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: crossAxisSpacing,
              mainAxisSpacing: mainAxisSpacing,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: itemCount,
            itemBuilder: itemBuilder,
          ),
        );
      },
    );
  }
}
