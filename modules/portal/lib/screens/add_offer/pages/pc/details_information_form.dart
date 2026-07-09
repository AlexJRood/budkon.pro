import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:core/common/shared_widgets/location_components.dart';
import 'package:portal/screens/add_offer/pages/widgets/apartment_variant_mobile.dart';
import 'package:portal/screens/add_offer/pages/widgets/garage_varient_mobile.dart';
import 'package:portal/screens/add_offer/pages/widgets/plot_varient_mobile.dart';
import 'package:portal/screens/add_offer/provider/add_offer_provider.dart';
import 'package:portal/screens/add_offer/components/progress_indicator.dart';
import 'package:portal/screens/add_offer/pages/widgets/apartment_variant.dart';
import 'package:portal/screens/add_offer/pages/widgets/garage_varient.dart';
import 'package:portal/screens/add_offer/pages/widgets/plot_varient.dart';
import 'package:core/ui/forms/form_fields.dart';
import 'package:core/ui/buttons/app_buttons.dart';
import 'package:core/common/custom_error_handler.dart';
import 'package:core/theme/apptheme.dart';

class DetailsInformationForm extends ConsumerStatefulWidget {
  final bool isMobile;
  const DetailsInformationForm({super.key,this.isMobile = false});

  @override
  ConsumerState<DetailsInformationForm> createState() => _DetailsInformationFormState();
}

class _DetailsInformationFormState extends ConsumerState<DetailsInformationForm> {
  final FocusNode priceFocusNode = FocusNode();
  final FocusNode surfaceFocusNode = FocusNode();

  void _calculatePricePerMeter(WidgetRef ref, AddOfferState addOfferState) {
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
      } catch (e) {
        // Handle parsing errors silently
      }
    }
  }

  bool _isApartmentType(String estateType) {
    final normalized = estateType.trim().toLowerCase();

    final apartmentTypes = [
      'studio',
      'flat',
      'house',
      'twin house',
      'row house',
      'invest',
      'commercial',
      'room',
      'apartment',
      'studio'.tr.toLowerCase(),
      'flat'.tr.toLowerCase(),
      'house'.tr.toLowerCase(),
      'twin house'.tr.toLowerCase(),
      'row house'.tr.toLowerCase(),
      'invest'.tr.toLowerCase(),
      'commercial'.tr.toLowerCase(),
      'room'.tr.toLowerCase(),
      'apartment'.tr.toLowerCase(),
    ];

    return apartmentTypes.contains(normalized);
  }

  bool _isLotType(String estateType) {
    final normalized = estateType.trim().toLowerCase();
    return normalized == 'lot' || normalized == 'lots' || normalized == 'lot'.tr.toLowerCase();
  }

  bool _isGarageWarehouseType(String estateType) {
    final normalized = estateType.trim().toLowerCase();
    return normalized == 'garage' ||
        normalized == 'warehouse' ||
        normalized == 'garage'.tr.toLowerCase() ||
        normalized == 'warehouse'.tr.toLowerCase();
  }

  void validateDetailsInformationFields(
      BuildContext context,
      AddOfferState addOfferState,
      WidgetRef ref,
      ) {
    final estateType = addOfferState.estateTypeController.text.trim();

    final garageWarehouseFields = <String, String?>{
      'Surface'.tr: addOfferState.surfaceController.text.trim(),
    };

    final lotFields = <String, String?>{
      'Surface'.tr: addOfferState.surfaceController.text.trim(),
    };

    final additionalStudioFields = <String, String?>{
      'Rooms'.tr: addOfferState.roomsController.text.trim(),
      'Surface'.tr: addOfferState.surfaceController.text.trim(),
    };

    final Map<String, String?> fieldsToCheck = {};

    if (_isApartmentType(estateType)) {
      fieldsToCheck.addAll(additionalStudioFields);
    } else if (_isGarageWarehouseType(estateType)) {
      fieldsToCheck.addAll(garageWarehouseFields);
    } else if (_isLotType(estateType)) {
      fieldsToCheck.addAll(lotFields);
    }

    final missingFields = fieldsToCheck.entries
        .where((entry) => entry.value == null || entry.value!.isEmpty)
        .map((entry) => entry.key)
        .toList();

    debugPrint('estateType: ${addOfferState.estateTypeController.text}');
    debugPrint('rooms: ${addOfferState.roomsController.text}');
    debugPrint('surface: ${addOfferState.surfaceController.text}');
    debugPrint('missingFields: $missingFields');

    if (missingFields.isNotEmpty) {
      final snackBarText = missingFields.length >= 5
          ? 'Missing required fields. Please fill all mandatory fields.'.tr
          : 'Missing: ${missingFields.join(', ')}';

      final snackBar = Customsnackbar().showSnackBar(
        "Warning".tr,
        snackBarText,
        'warning'.tr,
            () {},
      );

      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } else {
      ref.read(progressProvider.notifier).state += 1;
    }
  }

  @override
  void dispose() {
    priceFocusNode.dispose();
    surfaceFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final addOfferState = ref.watch(addOfferProvider);
    final theme = ref.watch(themeColorsProvider);
    final estateType = addOfferState.estateTypeController.text.trim();

    double dynamicPadding = widget.isMobile? 15 : MediaQuery.of(context).size.width / 7;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: dynamicPadding),
      child: Row(
        children: [
          Expanded(
            flex: 8,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Text(
                    'Details Information'.tr,
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryBackgroundTextColor,
                    ),
                  ),
                  Text(
                    'Searchers will appreciate detailed information about your property.'.tr,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryBackgroundTextColor,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'Pricing Information'.tr,
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
                        flex: widget.isMobile ? 2 : 1,
                        child: GradientDropdownAddOffer(
                          isPc: true,
                          value: addOfferState.currencyController.text,
                          selectedItem: addOfferState.currencyController.text,
                          items: const ['PLN', 'EUR', 'GBP', 'USD', 'CZK'],
                          onChanged: (value) {
                            ref
                                .read(addOfferProvider.notifier)
                                .updateField('currency', value);
                          },
                          hintText: 'Currency'.tr,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: widget.isMobile ? 4 : 5,
                        child: GradientTextField(
                          focusNode: priceFocusNode,
                          reqNode: surfaceFocusNode,
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.number,
                          controller: addOfferState.priceController,
                          hintText: 'Price'.tr,
                          onChanged: (value) {
                            _calculatePricePerMeter(ref, addOfferState);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_isApartmentType(estateType)) ...[
                    if(widget.isMobile)...[
                      ApartmentVariantMobile(),
                    ]else...[
                      ApartmentVariant(),
                    ]
                  ],
                  if (_isLotType(estateType)) ...[
                    if(widget.isMobile)...[
                      PlotVarientMobile()
                    ]else...[
                      PlotVariant(),
                    ]
                  ],
                  if (_isGarageWarehouseType(estateType)) ...[
                    if(widget.isMobile)...[
                      GarageVarientMobile()
                    ]else...[
                      GarageVarient(),
                    ]
                  ],
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          ref.read(progressProvider.notifier).state -= 1;
                        },
                        child: Text(
                          'Back'.tr,
                          style: TextStyle(
                            color: theme.primaryBackgroundTextColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      SizedBox(
                        width: 250,
                        child: SettingsButton(
                          isPc: true,
                          buttonheight: 50,
                          onTap: () {
                            validateDetailsInformationFields(
                              context,
                              addOfferState,
                              ref,
                            );
                          },
                          text: "Continue".tr,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}