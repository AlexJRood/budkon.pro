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
import 'package:core/theme/apptheme.dart';

class ApartmentVariantMobile extends ConsumerStatefulWidget {
  final FocusNode? externalSurfaceFocusNode;
  const ApartmentVariantMobile({super.key,
    this.externalSurfaceFocusNode,
  });

  @override
  ConsumerState<ApartmentVariantMobile> createState() =>
      _ApartmentVariantMobileState();
}

class _ApartmentVariantMobileState
    extends ConsumerState<ApartmentVariantMobile> {
  final FocusNode _surfaceFocusNode = FocusNode();
  final FocusNode _yearFocusNode = FocusNode();
  final FocusNode _pricePerM2FocusNode = FocusNode();
  final FocusNode _apartmentNumberFocusNode = FocusNode();

  final GlobalKey _surfaceKey = GlobalKey();
  final GlobalKey _yearKey = GlobalKey();
  final GlobalKey _pricePerM2Key = GlobalKey();
  final GlobalKey _apartmentNumberKey = GlobalKey();
  FocusNode get _effectiveSurfaceFocusNode =>
      widget.externalSurfaceFocusNode ?? _surfaceFocusNode;

  @override
  void initState() {
    super.initState();

    _effectiveSurfaceFocusNode.addListener(() {
      if (_effectiveSurfaceFocusNode.hasFocus) {
        _scrollToField(_surfaceKey);
      }
    });

    _yearFocusNode.addListener(() {
      if (_yearFocusNode.hasFocus) {
        _scrollToField(_yearKey);
      }
    });

    _pricePerM2FocusNode.addListener(() {
      if (_pricePerM2FocusNode.hasFocus) {
        _scrollToField(_pricePerM2Key);
      }
    });

    _apartmentNumberFocusNode.addListener(() {
      if (_apartmentNumberFocusNode.hasFocus) {
        _scrollToField(_apartmentNumberKey);
      }
    });
  }

  void _scrollToField(GlobalKey key) {
    final fieldContext = key.currentContext;
    if (fieldContext == null) return;

    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;

      Scrollable.ensureVisible(
        fieldContext,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );
    });
  }

  @override
  void dispose() {
    if (widget.externalSurfaceFocusNode == null) {
      _surfaceFocusNode.dispose();
    }
    _yearFocusNode.dispose();
    _pricePerM2FocusNode.dispose();
    _apartmentNumberFocusNode.dispose();
    super.dispose();
  }
  void _calculatePricePerMeter(dynamic addOfferState) {
    final totalPriceText = addOfferState.priceController.text;
    final surfaceText = addOfferState.surfaceController.text;

    if (totalPriceText.isNotEmpty && surfaceText.isNotEmpty) {
      try {
        final totalPrice = double.parse(
          totalPriceText.replaceAll(RegExp(r'[^\d.]'), ''),
        );
        final surface = double.parse(
          surfaceText.replaceAll(RegExp(r'[^\d.]'), ''),
        );

        if (surface > 0) {
          final pricePerMeter = totalPrice / surface;
          addOfferState.squareFootageController.text =
              pricePerMeter.toStringAsFixed(2);
        }
      } catch (_) {}
    }
  }

  void _calculateTotalPrice(dynamic addOfferState) {
    final pricePerMeterText = addOfferState.squareFootageController.text;
    final surfaceText = addOfferState.surfaceController.text;

    if (pricePerMeterText.isNotEmpty && surfaceText.isNotEmpty) {
      try {
        final pricePerMeter = double.parse(
          pricePerMeterText.replaceAll(RegExp(r'[^\d.]'), ''),
        );
        final surface = double.parse(
          surfaceText.replaceAll(RegExp(r'[^\d.]'), ''),
        );

        if (surface > 0 && pricePerMeter > 0) {
          final totalPrice = pricePerMeter * surface;
          addOfferState.priceController.text = totalPrice.toStringAsFixed(0);
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final addOfferState = ref.watch(addOfferProvider);
    final theme = ref.watch(themeColorsProvider);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        FocusScope.of(context).unfocus();
      },
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
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  key: _surfaceKey,
                  child: SecondaryTextfield(
                    hintText: "Surface".tr,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    controller: addOfferState.surfaceController,
                    focusNode: widget.externalSurfaceFocusNode ?? _surfaceFocusNode,
                    reqNode: _yearFocusNode,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) {
                      _calculatePricePerMeter(addOfferState);
                    },
                    onSubmitted: (_) {
                      FocusScope.of(context).requestFocus(_yearFocusNode);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  key: _yearKey,
                  child: SecondaryTextfield(
                    hintText: "Year of construction".tr,
                    controller: addOfferState.buildYearController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    focusNode: _yearFocusNode,
                    reqNode: _pricePerM2FocusNode,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) {
                      FocusScope.of(context).requestFocus(_pricePerM2FocusNode);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  key: _pricePerM2Key,
                  child: SecondaryTextfield(
                    hintText: "Price per m2".tr,
                    controller: addOfferState.squareFootageController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    focusNode: _pricePerM2FocusNode,
                    reqNode: _apartmentNumberFocusNode,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) {
                      FocusScope.of(context).requestFocus(_apartmentNumberFocusNode);
                    },
                    onChanged: (_) {
                      _calculateTotalPrice(addOfferState);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  key: _apartmentNumberKey,
                  child: SecondaryTextfield(
                    hintText: "Apartment Number".tr,
                    controller: addOfferState.appartmentNumberController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    focusNode: _apartmentNumberFocusNode,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) {
                      FocusScope.of(context).unfocus();
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          PropertyTypeSelector(
            updateField: 'rooms',
            controller: addOfferState.roomsController,
            isWidthFixed: true,
            options: [
              ButtonOption('1', '1'),
              ButtonOption('2', '2'),
              ButtonOption('3', '3'),
              ButtonOption('4', '4'),
              ButtonOption('5', '5'),
              ButtonOption('6', '6'),
              ButtonOption('7+', '7'),
            ],
            labelText: 'Rooms'.tr,
          ),
          const SizedBox(height: 20),
          PropertyTypeSelector(
            updateField: 'bathrooms',
            controller: addOfferState.bathroomsController,
            isWidthFixed: true,
            options: [
              ButtonOption('1', '1'),
              ButtonOption('2', '2'),
              ButtonOption('3', '3'),
              ButtonOption('4', '4'),
              ButtonOption('5', '5'),
              ButtonOption('6', '6'),
              ButtonOption('7+', '7'),
            ],
            labelText: 'Bathrooms'.tr,
          ),
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
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
              const SizedBox(height: 20),
              Text(
                'Advanced Filters',
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
                      value: addOfferState.buildingTypeController.text,
                      selectedItem: addOfferState.buildingTypeController.text,
                      items: [
                        'apartment_block'.tr,
                        'apartment_building'.tr,
                        'townhouse'.tr,
                        'tenement'.tr,
                        'high_rise'.tr,
                        'loft'.tr,
                      ],
                      onChanged: (value) {
                        ref
                            .watch(addOfferProvider.notifier)
                            .updateField('buildingType', value);
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
                      value: addOfferState.buildingMaterialController.text,
                      selectedItem: addOfferState.buildingMaterialController.text,
                      items: [
                        'brick'.tr,
                        'large_panel'.tr,
                        'silicate'.tr,
                        'concrete'.tr,
                        'aerated_concrete'.tr,
                        'hollow_block'.tr,
                        'reinforced_concrete'.tr,
                        'ceramsite'.tr,
                        'wood'.tr,
                        'other'.tr,
                      ],
                      onChanged: (value) {
                        ref
                            .watch(addOfferProvider.notifier)
                            .updateField('building_material', value);
                      },
                      hintText: 'filter_label_building_material'.tr,
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
              const SizedBox(height: 10),
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
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: GradientDropdownAddOffer(
                      isPc: true,
                      value: addOfferState.floorController.text,
                      selectedItem: addOfferState.floorController.text,
                      items: List<String>.generate(
                        200,
                            (index) => (index + 1).toString(),
                      ),
                      hintText: 'Floor'.tr,
                      onChanged: (value) {
                        ref
                            .watch(addOfferProvider.notifier)
                            .updateField('floor', value);
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
                      items: List<String>.generate(
                        200,
                            (index) => (index + 1).toString(),
                      ),
                      hintText: 'number_of_floors'.tr,
                      onChanged: (value) {
                        ref
                            .watch(addOfferProvider.notifier)
                            .updateField('totalFloors', value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
          Text(
            'Additional Features'.tr,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: theme.primaryBackgroundTextColor,
            ),
          ),
          const SizedBox(height: 10),
          const AdditionalFeaturesMobile(),
        ],
      ),
    );
  }
}

class AdditionalFeaturesMobile extends ConsumerWidget {
  const AdditionalFeaturesMobile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addOfferState = ref.watch(addOfferProvider);
    final addOfferNotifier = ref.read(addOfferProvider.notifier);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: CustomDropdownNoBackground(
                options: ['Balcony', 'Taras', 'None'],
                onChanged:
                    (value) => addOfferNotifier.updateField('balcony', value),
                controller: addOfferState.balconyController,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ToggleButtonOptionAddOffer(
                label: 'Elevator'.tr,
                value: addOfferState.elevatorController.text,
                onPressed: () => addOfferNotifier.toggleFeature('elevator'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ToggleButtonOptionAddOffer(
                label: 'Sauna'.tr,
                value: addOfferState.saunaController.text,
                onPressed: () => addOfferNotifier.toggleFeature('sauna'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CustomDropdownNoBackground(
                options: ['Parking'.tr, 'Garage'.tr, 'Street'.tr],
                controller: addOfferState.parkingSpaceController,
                onChanged:
                    (value) =>
                    addOfferNotifier.updateField('parkingSpace', value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ToggleButtonOptionAddOffer(
                label: 'Gym'.tr,
                value: addOfferState.garageController.text,
                onPressed: () => addOfferNotifier.toggleFeature('gym'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ToggleButtonOptionAddOffer(
                label: 'Air conditioning'.tr,
                value: addOfferState.airConditioningController.text,
                onPressed:
                    () => addOfferNotifier.toggleFeature('airConditioning'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ToggleButtonOptionAddOffer(
                label: 'Garden'.tr,
                value: addOfferState.gardenController.text,
                onPressed: () => addOfferNotifier.toggleFeature('garden'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ToggleButtonOptionAddOffer(
                label: 'Basement'.tr,
                value: addOfferState.basementController.text,
                onPressed: () => addOfferNotifier.toggleFeature('basement'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}