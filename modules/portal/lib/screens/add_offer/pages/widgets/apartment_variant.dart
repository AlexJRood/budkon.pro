import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:portal/screens/add_offer/provider/add_offer_provider.dart';
import 'package:portal/screens/add_offer/components/general_information_screen_components.dart';
import 'package:core/common/shared_widgets/location_components.dart';
import 'package:portal/screens/add_offer/components/property_type_selector.dart';
import 'package:portal/screens/add_offer/components/secondary_textfield.dart';
import 'package:portal/screens/edit_offer/components/edit_fileds.dart';
import 'package:core/platform/filters/filters_const.dart';
import 'package:core/theme/apptheme.dart';

class ApartmentVariant extends ConsumerWidget {
  const ApartmentVariant({super.key});

  // Calculate price per meter when total price or surface changes
  void _calculatePricePerMeter(WidgetRef ref, dynamic addOfferState) {
    final totalPriceText = addOfferState.priceController.text;
    final surfaceText = addOfferState.surfaceController.text;

    if (totalPriceText.isNotEmpty && surfaceText.isNotEmpty) {
      try {
        final totalPrice = double.parse(totalPriceText.replaceAll(RegExp(r'[^\d.]'), ''));
        final surface = double.parse(surfaceText.replaceAll(RegExp(r'[^\d.]'), ''));

        if (surface > 0) {
          final pricePerMeter = totalPrice / surface;
          addOfferState.squareFootageController.text = pricePerMeter.toStringAsFixed(2);
        }
      } catch (e) {
        // Handle parsing errors silently
      }
    }
  }

  // Calculate total price when price per meter or surface changes
  void _calculateTotalPrice(WidgetRef ref, dynamic addOfferState) {
    final pricePerMeterText = addOfferState.squareFootageController.text;
    final surfaceText = addOfferState.surfaceController.text;

    if (pricePerMeterText.isNotEmpty && surfaceText.isNotEmpty) {
      try {
        final pricePerMeter = double.parse(pricePerMeterText.replaceAll(RegExp(r'[^\d.]'), ''));
        final surface = double.parse(surfaceText.replaceAll(RegExp(r'[^\d.]'), ''));

        if (surface > 0 && pricePerMeter > 0) {
          final totalPrice = pricePerMeter * surface;
          addOfferState.priceController.text = totalPrice.toStringAsFixed(0);
        }
      } catch (e) {
        // Handle parsing errors silently
      }
    }
  }

  @override
  Widget build(BuildContext context, ref) {
    final addOfferState = ref.watch(addOfferProvider); // Watch the provider
    final theme = ref.watch(themeColorsProvider);

    final marketOptions = [
      ButtonOption('Primary Market'.tr, 'Primary Market'.tr),
      ButtonOption('Secondary Market'.tr, 'Secondary Market'.tr),
    ];

    final selectedBuildingTypeText =
        FilterPopConst.typeOfBuildingOptions
            .firstWhere(
              (e) =>
          e['filterKey'] ==
              addOfferState.buildingTypeController.text,
          orElse: () => {'text': '', 'filterKey': ''},
        )['text'] ??
            '';

    final selectedBuildingMaterialText =
        FilterPopConst.buildingMaterialOptions
            .firstWhere(
              (e) =>
          e['filterKey'] ==
              addOfferState.buildingMaterialController.text,
          orElse: () => {'text': '', 'filterKey': ''},
        )['text'] ??
            '';

    final selectedHeatingTypeText =
        FilterPopConst.heatingTypeOptions
            .firstWhere(
              (e) =>
          e['filterKey'] ==
              addOfferState.heatingTypeController.text,
          orElse: () => {'text': '', 'filterKey': ''},
        )['text'] ??
            '';

    final selectedAdvertiserTypeText =
        FilterPopConst.advertiserOptions
            .firstWhere(
              (e) =>
          e['filterKey'] ==
              addOfferState.advertiserTypeController.text,
          orElse: () => {'text': '', 'filterKey': ''},
        )['text'] ??
            '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Left side - red container with form
            Expanded(
              child: Container(
                // height: 500,
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                            onChanged: (value) {
                              _calculatePricePerMeter(ref, addOfferState);
                            },
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: SecondaryTextfield(
                            hintText: "Year of construction".tr,
                            controller: addOfferState.buildYearController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: SecondaryTextfield(
                            hintText: "Price per m2".tr,
                            controller: addOfferState.squareFootageController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                            onChanged: (value) {
                              _calculateTotalPrice(ref, addOfferState);
                            },
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: SecondaryTextfield(
                            hintText: "Apartment Number".tr,
                            controller: addOfferState.appartmentNumberController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 20),

                    PropertyTypeSelector(
                      isBig: true,
                      isWidthFixed: true,
                      updateField: 'rooms',
                      controller: addOfferState.roomsController,
                      options: [
                        ButtonOption('1', '1'),
                        ButtonOption('2', '2'),
                        ButtonOption('3', '3'),
                        ButtonOption('4', '4'),
                        ButtonOption('5', '5'),
                        ButtonOption('6', '6'),
                        ButtonOption('7+', '7'),
                      ],
                      // Lista opcji
                      labelText: 'Rooms'.tr,
                    ),
                    SizedBox(height: 20),
                    PropertyTypeSelector(
                      isBig: true,
                      isWidthFixed: true,
                      updateField: 'bathrooms',
                      controller: addOfferState.bathroomsController,
                      options: [
                        ButtonOption('1', '1'),
                        ButtonOption('2', '2'),
                        ButtonOption('3', '3'),
                        ButtonOption('4', '4'),
                        ButtonOption('5', '5'),
                        ButtonOption('6', '6'),
                        ButtonOption('7+', '7'),
                      ],
                      // Lista opcji
                      labelText: 'Bathrooms'.tr,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 20),

            /// Right side - blue container
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 10),
                    PropertyTypeSelector(
                      isExpanded: true,
                      updateField: 'marketType',
                      controller: addOfferState.marketTypeController,
                      options: marketOptions,
                      labelText: 'Market'.tr,
                    ),

                    const SizedBox(height: 20),
                    Text(
                      'Advanced Filters'.tr,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: theme.primaryBackgroundTextColor,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: GradientDropdownAddOffer(
                            isPc: true,
                            value: selectedBuildingTypeText,
                            selectedItem: selectedBuildingTypeText,
                            items: FilterPopConst.typeOfBuildingOptions
                                .map((e) => e['text'] ?? '')
                                .where((e) => e.isNotEmpty)
                                .toList(),
                            onChanged: (value) {
                              final selected = FilterPopConst.typeOfBuildingOptions.firstWhere(
                                    (e) => e['text'] == value,
                                orElse: () => {'text': '', 'filterKey': ''},
                              );

                              ref
                                  .read(addOfferProvider.notifier)
                                  .updateField('buildingType', selected['filterKey']);
                            },
                            hintText: 'filter_label_building_type'.tr,
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
                            value: selectedBuildingMaterialText,
                            selectedItem: selectedBuildingMaterialText,
                            items: FilterPopConst.buildingMaterialOptions
                                .map((e) => e['text'] ?? '')
                                .where((e) => e.isNotEmpty)
                                .toList(),
                            onChanged: (value) {
                              final selected = FilterPopConst.buildingMaterialOptions
                                  .firstWhere(
                                    (e) => e['text'] == value,
                                orElse: () => {'text': '', 'filterKey': ''},
                              );

                              ref
                                  .read(addOfferProvider.notifier)
                                  .updateField('buildingMaterial', selected['filterKey']);
                            },
                            hintText: 'Building material'.tr,
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
                            value: selectedHeatingTypeText,
                            selectedItem: selectedHeatingTypeText,
                            items: FilterPopConst.heatingTypeOptions
                                .map((e) => e['text'] ?? '')
                                .where((e) => e.isNotEmpty)
                                .toList(),
                            hintText: 'Heating type'.tr,
                            onChanged: (value) {
                              final selected = FilterPopConst.heatingTypeOptions.firstWhere(
                                    (e) => e['text'] == value,
                                orElse: () => {'text': '', 'filterKey': ''},
                              );

                              ref
                                  .read(addOfferProvider.notifier)
                                  .updateField('heatingType', selected['filterKey']);
                            },
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
                            value: selectedAdvertiserTypeText,
                            selectedItem: selectedAdvertiserTypeText,
                            items: FilterPopConst.advertiserOptions
                                .map((e) => e['text'] ?? '')
                                .where((e) => e.isNotEmpty)
                                .toList(),
                            onChanged: (value) {
                              final selected = FilterPopConst.advertiserOptions.firstWhere(
                                    (e) => e['text'] == value,
                                orElse: () => {'text': '', 'filterKey': ''},
                              );
                              debugPrint('selected advertiser filterKey: ${selected['filterKey']}');
                              debugPrint('controller before: ${addOfferState.advertiserTypeController.text}');
                              ref
                                  .read(addOfferProvider.notifier)
                                  .updateField('advertiser', selected['filterKey']);
                            },
                            hintText: 'advertiser_type'.tr,
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
                            value: addOfferState.floorController.text,
                            selectedItem: addOfferState.floorController.text,
                            items: List<String>.generate(200, (index) => (index + 1).toString()),
                            hintText: 'Floor'.tr,
                            onChanged: (value) {
                              ref.read(addOfferProvider.notifier).updateField('floor', value);
                            },
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
                            value: addOfferState.totalFloorsController.text,
                            selectedItem: addOfferState.totalFloorsController.text,
                            items: List<String>.generate(200, (index) => (index + 1).toString()),
                            hintText: 'Floor number'.tr,
                            onChanged: (value) {
                              ref
                                  .read(addOfferProvider.notifier)
                                  .updateField('totalFloors', value);
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 30),
        Text(
          'Additional Features'.tr,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: theme.primaryBackgroundTextColor,
          ),
        ),
        SizedBox(height: 10),
        AdditionalFeaturesRow(),
      ],
    );
  }
}

// Assuming AddOfferState and AddOfferNotifier are defined elsewhere
class AdditionalFeaturesRow extends ConsumerWidget {
  const AdditionalFeaturesRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addOfferState = ref.watch(addOfferProvider);
    final addOfferNotifier = ref.read(addOfferProvider.notifier);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          SizedBox(width: 10),
          CustomDropdownNoBackground(
            options: ['Balcony', 'Terrace'.tr, 'None'.tr],
            onChanged:
                (value) => addOfferNotifier.updateField('balcony', value),
            controller: addOfferState.balconyController,
          ),
          SizedBox(width: 10),
          ToggleButtonOptionAddOffer(
            label: 'Elevator'.tr,
            value: addOfferState.elevatorController.text,
            onPressed: () => addOfferNotifier.toggleFeature('elevator'),
          ),
          SizedBox(width: 10),
          ToggleButtonOptionAddOffer(
            label: 'Sauna'.tr,
            value: addOfferState.saunaController.text,
            onPressed: () => addOfferNotifier.toggleFeature('sauna'),
          ),
          SizedBox(width: 10),
          CustomDropdownNoBackground(
            options: ['Parking'.tr, 'Garage'.tr, 'Street'.tr],
            controller: addOfferState.parkingSpaceController,
            onChanged:
                (value) => addOfferNotifier.updateField('parkingSpace', value),
          ),
          SizedBox(width: 10),
          ToggleButtonOptionAddOffer(
            label: 'Gym'.tr,
            value: addOfferState.garageController.text,
            onPressed: () => addOfferNotifier.toggleFeature('gym'),
          ),
          SizedBox(width: 10),
          ToggleButtonOptionAddOffer(
            label: 'Air conditioning'.tr,
            value: addOfferState.airConditioningController.text,
            onPressed: () => addOfferNotifier.toggleFeature('airConditioning'),
          ),
          SizedBox(width: 10),
          ToggleButtonOptionAddOffer(
            label: 'Garden'.tr,
            value: addOfferState.gardenController.text,
            onPressed: () => addOfferNotifier.toggleFeature('garden'),
          ),
          SizedBox(width: 10),
          ToggleButtonOptionAddOffer(
            label: 'Basement'.tr,
            value: addOfferState.basementController.text,
            onPressed: () => addOfferNotifier.toggleFeature('basement'),
          ),
        ],
      ),
    );
  }
}