import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:portal/screens/add_offer/provider/add_offer_provider.dart';
import 'package:portal/screens/add_offer/components/general_information_screen_components.dart';
import 'package:core/common/shared_widgets/location_components.dart';
import 'package:portal/screens/add_offer/components/secondary_textfield.dart';
import 'package:core/theme/apptheme.dart';

class PlotVariant extends ConsumerWidget {
  const PlotVariant({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final addOfferState = ref.watch(addOfferProvider);
    final addOfferNotifier = ref.read(addOfferProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Left Column: Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Details'.tr, style: sectionTitle(theme)),
                  SizedBox(height: 10),
                  SecondaryTextfield(
                    hintText: "Surface".tr,
                    controller: addOfferState.surfaceController,
                  ),
                  SizedBox(height: 10),
                  SecondaryTextfield(
                    hintText: "Price per m2".tr,
                    controller: addOfferState.pricePerM2Controller,
                  ),
                  SizedBox(height: 10),
                  SecondaryTextfield(
                    hintText: "Dimensions [m]".tr,
                    controller: addOfferState.dimensionsController,
                  ),
                ],
              ),
            ),

            SizedBox(width: 20),

            /// Right Column: Filters
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Filters'.tr, style: sectionTitle(theme)),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: GradientDropdownAddOffer(
                          isPc: true,
                          value: addOfferState.plotTypeController.text,
                          selectedItem: addOfferState.plotTypeController.text,
                          items: ['Agricultural'.tr, 'Residential'.tr, 'Commercial'.tr],
                          hintText: 'Plot type'.tr,
                          onChanged: (value) {
                            ref
                                .watch(addOfferProvider.notifier)
                                .updateField('plotType', value);
                          },
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
                          value: addOfferState.fenceController.text,
                          selectedItem: addOfferState.fenceController.text,
                          items: ['Yes'.tr, 'No'.tr],
                          hintText: 'Fence'.tr,
                          onChanged: (value) {
                            ref
                                .watch(addOfferProvider.notifier)
                                .updateField('fence', value);
                          },
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
                          items: ['Corner'.tr, 'Central'.tr, 'End'.tr],
                          hintText: 'Position'.tr,
                          onChanged: (value) {
                            ref
                                .watch(addOfferProvider.notifier)
                                .updateField('position', value);
                          },
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
                          selectedItem:
                              addOfferState.advertiserTypeController.text,
                          items: ['Private'.tr, 'Agency'.tr, 'Developer'.tr],
                          hintText: 'Advertiser type'.tr,
                          onChanged: (value) {
                            ref
                                .watch(addOfferProvider.notifier)
                                .updateField('advertiser_type', value);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        SizedBox(height: 30),

        /// Additional Features
        Text('Additional Features'.tr, style: sectionTitle(theme)),
        SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            spacing: 10,
            children: [
              CustomDropdownNoBackground(
                options: ['Access'.tr, 'Yes'.tr, 'No'.tr],
                controller: addOfferState.accessController,
                onChanged:
                    (value) => addOfferNotifier.updateField('access', value),
              ),

              CustomDropdownNoBackground(
                options: ['Area'.tr, 'Urban'.tr, 'Rural'.tr],
                controller: addOfferState.areaController,
                onChanged:
                    (value) => addOfferNotifier.updateField('area', value),
              ),
              ToggleButtonOptionAddOffer(
                label: 'Current'.tr,
                value: addOfferState.currentController.text,
                onPressed: () => addOfferNotifier.toggleFeature('current'),
              ),

              ToggleButtonOptionAddOffer(
                label: 'Gas'.tr,
                value: addOfferState.gasController.text,
                onPressed: () => addOfferNotifier.toggleFeature('gas'),
              ),

              ToggleButtonOptionAddOffer(
                label: 'Sewers'.tr,
                value: addOfferState.sewersController.text,
                onPressed: () => addOfferNotifier.toggleFeature('sewers'),
              ),

              ToggleButtonOptionAddOffer(
                label: 'Water'.tr,
                value: addOfferState.waterController.text,
                onPressed: () => addOfferNotifier.toggleFeature('water'),
              ),

              ToggleButtonOptionAddOffer(
                label: 'Phone'.tr,
                value: addOfferState.phoneController.text,
                onPressed: () => addOfferNotifier.toggleFeature('phone'),
              ),

              ToggleButtonOptionAddOffer(
                label: 'Cesspool'.tr,
                value: addOfferState.cesspoolController.text,
                onPressed: () => addOfferNotifier.toggleFeature('cesspool'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  TextStyle sectionTitle(ThemeColors theme) => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.bold,
    color: theme.primaryBackgroundTextColor,
  );
}
