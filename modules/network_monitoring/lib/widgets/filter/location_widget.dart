import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:core/theme/design.dart';
import 'package:network_monitoring/widgets/filter/fileds.dart';

class LocationWidget extends StatelessWidget {
  final String? currentCountry;
  final TextEditingController cityController;
  final TextEditingController stateController;
  final TextEditingController streetController;
  final TextEditingController zipcodeController;
  final TextEditingController searchRadiusController;
  final dynamic ref;
  final double dynamicBoxHeightGroupSmall;
  final double dynamiSpacerBoxWidth;

  const LocationWidget({
    super.key,
    this.currentCountry,
    required this.cityController,
    required this.stateController,
    required this.streetController,
    required this.zipcodeController,
    required this.searchRadiusController,
    required this.ref,
    required this.dynamicBoxHeightGroupSmall,
    required this.dynamiSpacerBoxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Material(
              color: Colors.transparent,
              child: Text('Location'.tr, style: AppTextStyles.interSemiBold16.copyWith(color:  Theme.of(context).iconTheme.color)),
            ),
          ],
        ),
        SizedBox(height: dynamicBoxHeightGroupSmall),
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            BuildDropdownButtonFormField(
              currentValue: currentCountry,
              items:  [
                'poland'.tr,
                'germany'.tr,
                'czech_republic'.tr,
                'austria'.tr,
                'lithuania'.tr,
                'france'.tr
              ],
              labelText: 'Country'.tr,
              filterKey: 'country',
            ),
            SizedBox(height: dynamiSpacerBoxWidth),
            BuildTextField(
              controller: cityController,
              labelText: 'City'.tr,
              filterKey: 'city',
            ),
            SizedBox(height: dynamiSpacerBoxWidth),
            BuildTextField(
              controller: stateController,
              labelText: 'Voivodeship'.tr,
              filterKey: 'state',
            ),
          ],
        ),
        SizedBox(height: dynamicBoxHeightGroupSmall),
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            BuildTextField(
              controller: streetController,
              labelText: 'Street'.tr,
              filterKey: 'street',
            ),
            SizedBox(height: dynamiSpacerBoxWidth),
            BuildTextField(
              controller: zipcodeController,
              labelText: 'Zip code'.tr,
              filterKey: 'zip_code',
            ),
            SizedBox(height: dynamiSpacerBoxWidth),
            BuildTextField(
              controller: searchRadiusController,
              labelText: '+ 0km',
              filterKey: 'city',
            ),
          ],
        ),
      ],
    );
  }

  // Pamiętaj, aby zdefiniować metody `buildDropdownButtonFormField` i `buildTextField` lub zaimportować je, jeśli są w oddzielnym pliku.
}
