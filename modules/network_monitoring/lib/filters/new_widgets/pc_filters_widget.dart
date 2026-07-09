import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_monitoring/filters/new_widgets/filtered_multi_button.dart';
import 'package:network_monitoring/filters/new_widgets/filtered_slider.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:network_monitoring/widgets/filter/controllers.dart';
import 'package:network_monitoring/widgets/filter/fileds.dart';
import 'package:core/theme/apptheme.dart';

class PcFiltersWidget extends ConsumerWidget {
  const PcFiltersWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(nmControllersProvider);
    final theme = ref.watch(themeColorsProvider);

    return Column(
      spacing: 12,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filter'.tr,
          style: TextStyle(
            color: theme.textColor,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),

        // Row(
        //   mainAxisAlignment:
        //   MainAxisAlignment.spaceBetween,
        //   children: [
        //     Expanded(
        //       child: CustomDropdown(
        //         label: 'Advertiser',
        //         options:
        //         FilterPopConst.advertiserOptions,
        //         value: dropdownValues['advertiser_type']!,
        //         onChanged: (newValue) {
        //           ref
        //               .read(dropdownProvider.notifier)
        //               .updateValue(
        //               'advertiser_type', newValue!);
        //         },
        //         width: 166,
        //         height: 32,
        //       ),
        //     ),
        //     const Padding(
        //       padding: EdgeInsets.all(12.0),
        //       child: SizedBox(
        //           width: 15,
        //           child: Divider(
        //             color: Color.fromRGBO(
        //                 145, 145, 145, 1),
        //           )),
        //     ),
        //     Expanded(
        //       child: CustomDropdown(
        //         label: 'Advertiser',
        //         options:
        //         FilterPopConst.advertiserOptions,
        //         value: dropdownValues['advertiser_type']!,
        //         onChanged: (newValue) {
        //           ref
        //               .read(dropdownProvider.notifier)
        //               .updateValue(
        //               'advertiser_type', newValue!);
        //         },
        //         width: 166,
        //         height: 32,
        //       ),
        //     ),
        //   ],
        // ),
        // Row(
        //   mainAxisAlignment:
        //   MainAxisAlignment.spaceBetween,
        //   children: [
        //     Expanded(
        //       child: CustomDropdown(
        //         label: 'Advertiser',
        //         options:
        //         FilterPopConst.advertiserOptions,
        //         value: dropdownValues['advertiser_type']!,
        //         onChanged: (newValue) {
        //           ref
        //               .read(dropdownProvider.notifier)
        //               .updateValue(
        //               'advertiser_type', newValue!);
        //         },
        //         width: 166,
        //         height: 32,
        //       ),
        //     ),
        //     const Padding(
        //       padding: EdgeInsets.all(12.0),
        //       child: SizedBox(
        //           width: 15,
        //           child: Divider(
        //             color: Color.fromRGBO(
        //                 145, 145, 145, 1),
        //           )),
        //     ),
        //     Expanded(
        //       child: CustomDropdown(
        //         label: 'Advertiser',
        //         options:
        //         FilterPopConst.advertiserOptions,
        //         value: dropdownValues['advertiser_type']!,
        //         onChanged: (newValue) {
        //           ref
        //               .read(dropdownProvider.notifier)
        //               .updateValue(
        //               'advertiser_type', newValue!);
        //         },
        //         width: 166,
        //         height: 32,
        //       ),
        //     ),
        //   ],
        // ),
        Text(
          'Floor area'.tr,
          style: TextStyle(
            color: theme.textColor,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),

        Row(
          children: [
            Expanded(
              child: BuildNumberField(
                controller: c.minSquareFootageController,
                labelText: 'area_from'.tr,
                filterKey: 'min_square_footage',
              ),
            ),
            SizedBox(width: 20),
            Expanded(
              child: BuildNumberField(
                controller: c.maxSquareFootageController,
                labelText: 'area_to'.tr,
                filterKey: 'max_square_footage',
              ),
            ),
          ],
        ),

        Text(
          'Year of build'.tr,
          style: TextStyle(
            color: theme.textColor,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),

        Row(
          children: [
            Expanded(
              child: BuildNumberField(
                controller: c.minYearBuildController,
                labelText: 'Year from'.tr,
                filterKey: 'min_build_year',
              ),
            ),
            SizedBox(width: 20),
            Expanded(
              child: BuildNumberField(
                controller: c.maxYearBuildController,
                labelText: 'Year to'.tr,
                filterKey: 'max_build_year',
              ),
            ),
          ],
        ),


        Text(
          'Price'.tr,
          style: TextStyle(
            color: theme.textColor,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),

        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: BuildDropdownButtonFormField(
                filterKey: 'currency',
                items: ['PLN', 'EUR', 'USD'],
                labelText: 'Currency'.tr,
                currentValue: 'PLN',
              ),
            ),
            SizedBox(width: 20),
            Expanded(
              child: BuildNumberField(
                controller: c.minPriceController,
                labelText: 'price_from'.tr,
                filterKey: 'min_price',
              ),
            ),
            SizedBox(width: 20),
            Expanded(
              child: BuildNumberField(
                controller: c.maxPriceController,
                labelText: 'price_to'.tr,
                filterKey: 'max_price',
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),
        Text(
          'Floor number'.tr,
          style: TextStyle(
            color: theme.textColor,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const FilteredSlider(filterKey: 'floors'),
        const SizedBox(height: 10),



Row(
  spacing: 8,
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Text('Rooms'.tr, style: TextStyle(color: theme.textColor)),
    Wrap(
      spacing: 2,
      children: [
        FilteredMultiButton(text: 'Any'.tr, filterValue: 'any', filterKey: 'rooms'),
        FilteredMultiButton(text: '1', filterValue: '1', filterKey: 'rooms'),
        FilteredMultiButton(text: '2', filterValue: '2', filterKey: 'rooms'),
        FilteredMultiButton(text: '3', filterValue: '3', filterKey: 'rooms'),
        FilteredMultiButton(text: '4', filterValue: '4', filterKey: 'rooms'),
        FilteredMultiButton(text: '5', filterValue: '5', filterKey: 'rooms'),
        FilteredMultiButton(text: '6+', filterValue: '6+', filterKey: 'rooms'),
      ],
    ),
  ],
),

Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Text('Bathrooms'.tr, style: TextStyle(color: theme.textColor)),
    Wrap(
      spacing: 2,
      children: [
        FilteredMultiButton(text: 'Any'.tr, filterValue: 'any', filterKey: 'bathrooms'),
        FilteredMultiButton(text: '1', filterValue: '1', filterKey: 'bathrooms'),
        FilteredMultiButton(text: '2', filterValue: '2', filterKey: 'bathrooms'),
        FilteredMultiButton(text: '3', filterValue: '3', filterKey: 'bathrooms'),
        FilteredMultiButton(text: '4', filterValue: '4', filterKey: 'bathrooms'),
        FilteredMultiButton(text: '5', filterValue: '5', filterKey: 'bathrooms'),
        FilteredMultiButton(text: '6+', filterValue: '6+', filterKey: 'bathrooms'),
      ],
    ),
  ],
),
      ],
      
    );
  }
}
