import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/filters/filters_const.dart';
import 'package:portal/screens/filters/widgets/new_widgets/custom-drop_down.dart';
import 'package:portal/screens/filters/widgets/new_widgets/filltered_button.dart';
import 'package:portal/screens/filters/widgets/new_widgets/filtered_slider.dart';
import 'package:get/get_utils/get_utils.dart';


class PcFiltersWidget extends ConsumerWidget {
  const PcFiltersWidget({super.key});

  @override
  Widget build(BuildContext context,WidgetRef ref) {
    final dropdownValues = ref.watch(dropdownProvider);

    return Column(
      spacing: 12,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filter'.tr,
          style: TextStyle(
              color: Color.fromRGBO(255, 255, 255, 1),
              fontSize: 20,
              fontWeight: FontWeight.w700),
        ),
        Row(
          mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: CustomDropdown(
                label: 'Advertiser'.tr,
                options:
                FilterPopConst.advertiserOptions,
                value: dropdownValues['advertiser_type']!.value,
                onChanged: (newValue) {
                  ref
                      .read(dropdownProvider.notifier)
                      .updateValue(
                      'advertiser_type', newValue!);
                },
                width: 166,
                height: 32,
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: SizedBox(
                  width: 15,
                  child: Divider(
                    color: Color.fromRGBO(
                        145, 145, 145, 1),
                  )),
            ),
            Expanded(
              child: CustomDropdown(
                label: 'Advertiser'.tr,
                options:
                FilterPopConst.advertiserOptions,
                value: dropdownValues['advertiser_type']!.value,
                onChanged: (newValue) {
                  ref
                      .read(dropdownProvider.notifier)
                      .updateValue(
                      'advertiser_type', newValue!);
                },
                width: 166,
                height: 32,
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: CustomDropdown(
                label: 'Advertiser'.tr,
                options:
                FilterPopConst.advertiserOptions,
                value: dropdownValues['advertiser_type']!.value,
                onChanged: (newValue) {
                  ref
                      .read(dropdownProvider.notifier)
                      .updateValue(
                      'advertiser_type', newValue!);
                },
                width: 166,
                height: 32,
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: SizedBox(
                  width: 15,
                  child: Divider(
                    color: Color.fromRGBO(
                        145, 145, 145, 1),
                  )),
            ),
            Expanded(
              child: CustomDropdown(
                label: 'Advertiser'.tr,
                options:
                FilterPopConst.advertiserOptions,
                value: dropdownValues['advertiser_type']!.value,
                onChanged: (newValue) {
                  ref
                      .read(dropdownProvider.notifier)
                      .updateValue(
                      'advertiser_type', newValue!);
                },
                width: 166,
                height: 32,
              ),
            ),
          ],
        ),
        Text(
          'Floor area'.tr,
          style: TextStyle(
              color: Color.fromRGBO(255, 255, 255, 1),
              fontSize: 20,
              fontWeight: FontWeight.w700),
        ),
        const FilteredSlider(filterKey: 'floors'),
        Row(
          mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
          children: [
            Container(
              height: 32,
              width: 100,
              decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2E),
                  borderRadius:
                  BorderRadius.circular(6)),
              child: const Center(
                child: Text(
                  'Min, m2',
                  style: TextStyle(
                    color: Color.fromRGBO(
                        145, 145, 145, 1),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            Container(
              height: 32,
              width: 100,
              decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2E),
                  borderRadius:
                  BorderRadius.circular(6)),
              child: const Center(
                child: Text(
                  'Max, m2',
                  style: TextStyle(
                    color: Color.fromRGBO(
                        145, 145, 145, 1),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
        Row(
          spacing: 8,
          mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'rooms'.tr,
              style: TextStyle(
                  color:
                  Color.fromRGBO(255, 255, 255, 1)),
            ),
            Wrap(
              spacing: 2,
              children: [
                FilteredButton(
                  text: 'Any'.tr,
                  filterValue: 'any',
                  filterKey: 'rooms',
                ),
                FilteredButton(
                  text: '1',
                  filterValue: '1',
                  filterKey: 'rooms',
                ),
                FilteredButton(
                  text: '2',
                  filterValue: '2',
                  filterKey: 'rooms',
                ),
                FilteredButton(
                  text: '3',
                  filterValue: '3',
                  filterKey: 'rooms',
                ),
                FilteredButton(
                  text: '4',
                  filterValue: '4',
                  filterKey: 'rooms',
                ),
                FilteredButton(
                  text: '5',
                  filterValue: '5',
                  filterKey: 'rooms',
                ),
                FilteredButton(
                  text: '6+',
                  filterValue: '6+',
                  filterKey: 'rooms',
                ),
              ],
            )
          ],
        ),
        Row(
          mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Bathrooms'.tr,
              style: TextStyle(
                  color:
                  Color.fromRGBO(255, 255, 255, 1)),
            ),
            Wrap(
              direction: Axis.horizontal,
              spacing: 2,
              children: [
                FilteredButton(
                  text: 'Any'.tr,
                  filterValue: 'any',
                  filterKey: 'bathrooms',
                ),
                FilteredButton(
                  text: '1',
                  filterValue: '1',
                  filterKey: 'bathrooms',
                ),
                FilteredButton(
                  text: '2',
                  filterValue: '2',
                  filterKey: 'bathrooms',
                ),
                FilteredButton(
                  text: '3',
                  filterValue: '3',
                  filterKey: 'bathrooms',
                ),
                FilteredButton(
                  text: '4',
                  filterValue: '4',
                  filterKey: 'bathrooms',
                ),
                FilteredButton(
                  text: '5',
                  filterValue: '5',
                  filterKey: 'bathrooms',
                ),
                FilteredButton(
                  text: '6+',
                  filterValue: '6+',
                  filterKey: 'bathrooms',
                ),
              ],
            )
          ],
        )
      ],
    );
  }
}
