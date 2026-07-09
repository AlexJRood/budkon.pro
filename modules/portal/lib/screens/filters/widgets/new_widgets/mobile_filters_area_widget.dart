import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:core/platform/filters/filters_const.dart';
import 'package:portal/screens/filters/widgets/new_widgets/custom-drop_down.dart';
import 'package:portal/screens/filters/widgets/new_widgets/filltered_button.dart';
import 'package:portal/screens/filters/widgets/new_widgets/filtered_slider.dart';
import 'package:get/get_utils/get_utils.dart';

class MobileFiltersAreaWidget extends ConsumerWidget {
  final String lineSpacer;
  const MobileFiltersAreaWidget({super.key, required this.lineSpacer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomDropdown(
              label: 'Advertiser'.tr,
              options: FilterPopConst.advertiserOptions,
              value: dropdownValues['advertiser_type']!.value,
              onChanged: (newValue) {
                ref
                    .read(dropdownProvider.notifier)
                    .updateValue('advertiser_type', newValue!);
              },
              width: 161,
              height: 48,
            ),
            const SizedBox(
                width: 20,
                child: Divider(
                  color: Color.fromRGBO(145, 145, 145, 1),
                )),
            CustomDropdown(
              label: 'Advertiser'.tr,
              options: FilterPopConst.advertiserOptions,
              value: dropdownValues['advertiser_type']!.value,
              onChanged: (newValue) {
                ref
                    .read(dropdownProvider.notifier)
                    .updateValue('advertiser_type', newValue!);
              },
              width: 161,
              height: 48,
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomDropdown(
              label: 'Advertiser',
              options: FilterPopConst.advertiserOptions,
              value: dropdownValues['advertiser_type']!.value,
              onChanged: (newValue) {
                ref
                    .read(dropdownProvider.notifier)
                    .updateValue('advertiser_type', newValue!);
              },
              width: 161,
              height: 48,
            ),
            const SizedBox(
                width: 20,
                child: Divider(
                  color: Color.fromRGBO(145, 145, 145, 1),
                )),
            CustomDropdown(
              label: 'Advertiser'.tr,
              options: FilterPopConst.advertiserOptions,
              value: dropdownValues['advertiser_type']!.value,
              onChanged: (newValue) {
                ref
                    .read(dropdownProvider.notifier)
                    .updateValue('advertiser_type', newValue!);
              },
              width: 161,
              height: 48,
            ),
          ],
        ),
        Text(
          lineSpacer,
          style: const TextStyle(color: Color.fromRGBO(90, 90, 90, 1)),
          maxLines: 1,
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              height: 40,
              width: 120,
              decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2E),
                  borderRadius: BorderRadius.circular(6)),
              child: const Center(
                child: Text(
                  'Min, m2',
                  style: TextStyle(
                    color: Color.fromRGBO(145, 145, 145, 1),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            Container(
              height: 40,
              width: 120,
              decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2E),
                  borderRadius: BorderRadius.circular(6)),
              child: const Center(
                child: Text(
                  'Max, m2',
                  style: TextStyle(
                    color: Color.fromRGBO(145, 145, 145, 1),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
        Text(
          lineSpacer,
          style: const TextStyle(color: Color.fromRGBO(90, 90, 90, 1)),
          maxLines: 1,
        ),
        Column(
          spacing: 12,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Rooms'.tr,
              style: TextStyle(color: Color.fromRGBO(255, 255, 255, 1)),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FilteredButton(
                  text: 'Any'.tr,
                  filterValue: 'any',
                  filterKey: 'rooms',
                  minHeight: 40,
                  minWidth: 60,
                  alignment: Alignment.center,
                ),
                FilteredButton(
                  text: '1',
                  filterValue: '1',
                  filterKey: 'rooms',
                  minHeight: 40,
                  minWidth: 40,
                  alignment: Alignment.center,
                ),
                FilteredButton(
                  text: '2',
                  filterValue: '2',
                  filterKey: 'rooms',
                  minHeight: 40,
                  minWidth: 40,
                  alignment: Alignment.center,
                ),
                FilteredButton(
                  text: '3',
                  filterValue: '3',
                  filterKey: 'rooms',
                  minHeight: 40,
                  minWidth: 40,
                  alignment: Alignment.center,
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
                  minHeight: 40,
                  minWidth: 40,
                  alignment: Alignment.center,
                ),
                FilteredButton(
                  text: '6+',
                  filterValue: '6+',
                  filterKey: 'rooms',
                  minHeight: 40,
                  minWidth: 40,
                  alignment: Alignment.center,
                ),
              ],
            )
          ],
        ),
        Column(
          spacing: 12,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Bathrooms'.tr,
              style: TextStyle(color: Color.fromRGBO(255, 255, 255, 1)),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FilteredButton(
                  text: 'Any'.tr,
                  filterValue: 'any',
                  filterKey: 'rooms',
                  minHeight: 40,
                  minWidth: 60,
                  alignment: Alignment.center,
                ),
                FilteredButton(
                  text: '1',
                  filterValue: '1',
                  filterKey: 'rooms',
                  minHeight: 40,
                  minWidth: 40,
                  alignment: Alignment.center,
                ),
                FilteredButton(
                  text: '2',
                  filterValue: '2',
                  filterKey: 'rooms',
                  minHeight: 40,
                  minWidth: 40,
                  alignment: Alignment.center,
                ),
                FilteredButton(
                  text: '3',
                  filterValue: '3',
                  filterKey: 'rooms',
                  minHeight: 40,
                  minWidth: 40,
                  alignment: Alignment.center,
                ),
                FilteredButton(
                  text: '4',
                  filterValue: '4',
                  filterKey: 'rooms',
                  minHeight: 40,
                  minWidth: 40,
                  alignment: Alignment.center,
                ),
                FilteredButton(
                  text: '5',
                  filterValue: '5',
                  filterKey: 'rooms',
                  minHeight: 40,
                  minWidth: 40,
                  alignment: Alignment.center,
                ),
                FilteredButton(
                  text: '6+',
                  filterValue: '6+',
                  filterKey: 'rooms',
                  minHeight: 40,
                  minWidth: 40,
                  alignment: Alignment.center,
                ),
              ],
            )
          ],
        )
      ],
    );
  }
}
