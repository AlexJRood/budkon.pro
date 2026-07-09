import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:portal/screens/add_offer/provider/add_offer_provider.dart';
import 'package:core/common/shared_widgets/location_components.dart';
import 'package:portal/screens/add_offer/components/property_type_selector.dart';
import 'package:portal/screens/add_offer/components/secondary_textfield.dart';
import 'package:portal/screens/edit_offer/components/edit_fileds.dart';
import 'package:core/theme/apptheme.dart';

class GarageVarientMobile extends ConsumerWidget {
  const GarageVarientMobile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addOfferState = ref.watch(addOfferProvider); // Watch the provider

    double dynamicPadding = MediaQuery.of(context).size.width / 7;
    final theme = ref.watch(themeColorsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Details'.tr,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: theme.primaryBackgroundTextColor,
          ),
        ),
        SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              flex: 1,
              child: GradientDropdownAddOffer(
                isPc: true,
                value: addOfferState.designController.text,
                selectedItem: addOfferState.designController.text,
                items: ['Modern'.tr, 'Traditional'.tr, 'Industrial'.tr, 'Custom'.tr],
                onChanged: (value) {
                  ref
                      .watch(addOfferProvider.notifier)
                      .updateField('design', value);
                },
                hintText: 'Design'.tr,
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              flex: 1,
              child: GradientDropdownAddOffer(
                isPc: true,
                value: addOfferState.positionController.text,
                selectedItem: addOfferState.positionController.text,
                items: ['Corner'.tr, 'Middle'.tr, 'End'.tr, 'Standalone'.tr],
                onChanged: (value) {
                  ref
                      .watch(addOfferProvider.notifier)
                      .updateField('position', value);
                },
                hintText: 'Position'.tr,
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              flex: 1,
              child: GradientDropdownAddOffer(
                isPc: true,
                value: addOfferState.lightningController.text,
                selectedItem: addOfferState.lightningController.text,
                items: ['Natural'.tr, 'Artificial'.tr, 'Mixed'.tr, 'None'.tr],
                onChanged: (value) {
                  ref
                      .watch(addOfferProvider.notifier)
                      .updateField('lightning', value);
                },
                hintText: 'Lightning'.tr,
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              flex: 1,
              child: GradientDropdownAddOffer(
                isPc: true,
                value: addOfferState.heatingTypeController.text,
                selectedItem: addOfferState.heatingTypeController.text,
                items: [
                  'gas'.tr,
                  'electric'.tr,
                  'district'.tr,
                  'heat_pump'.tr,
                  'oil'.tr,
                  'all_types'.tr,
                  'not_specified'.tr,
                ],
                hintText: 'heating_type'.tr,
                onChanged: (value) {
                  ref
                      .watch(addOfferProvider.notifier)
                      .updateField('heating_type', value);
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 20),
        Text(
          'Filters'.tr,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: theme.primaryBackgroundTextColor,
          ),
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: SecondaryTextfield(
                hintText: "Surface".tr,
                controller: addOfferState.surfaceController,
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: SecondaryTextfield(
                hintText: "Build Year".tr,
                controller: addOfferState.buildYearController,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              flex: 1,
              child: GradientDropdownAddOffer(
                isPc: true,
                value: addOfferState.energyCertificateController.text,
                selectedItem: addOfferState.energyCertificateController.text,
                items: ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'Not specified'],
                onChanged: (value) {
                  ref
                      .watch(addOfferProvider.notifier)
                      .updateField('energyCertificate', value);
                },
                hintText: 'Energy Certificate'.tr,
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              flex: 1,
              child: GradientDropdownAddOffer(
                isPc: true,
                value: addOfferState.advertiserTypeController.text,
                selectedItem: addOfferState.advertiserTypeController.text,
                items: ['Private'.tr, 'Agency'.tr, 'Developer'.tr],
                onChanged: (value) {
                  ref
                      .watch(addOfferProvider.notifier)
                      .updateField('advertiser_type', value);
                },
                hintText: 'advertiser_type'.tr,
              ),
            ),
          ],
        ),
        SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Left side - red container with form

            /// Right side - blue container
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PropertyTypeSelector(
                    isExpanded: true,
                    updateField: 'marketType',
                    controller: addOfferState.marketTypeController,
                    options: [
                      ButtonOption('Primary Market'.tr, 'Primary Market'.tr),
                      ButtonOption('Secondary Market'.tr, 'Secondary Market'.tr),
                    ],
                    labelText: 'Market'.tr,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
