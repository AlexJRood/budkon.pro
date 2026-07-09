import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:portal/screens/add_offer/components/progress_indicator.dart';
import 'package:portal/screens/add_offer/components/property_type_selector.dart';
import 'package:portal/screens/add_offer/components/tariff_tile.dart';
import 'package:portal/screens/add_offer/components/type_selector_widget.dart';
import 'package:portal/screens/add_offer/provider/add_offer_provider.dart';
import 'package:portal/screens/edit_offer/components/edit_fileds.dart';
import 'package:core/platform/filters/filters_const.dart';
import 'package:core/ui/buttons/app_buttons.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/user/login/login/login_pc_dialog.dart';
import 'package:core/user/user/user_provider.dart';

class OfferTypeSelector extends ConsumerWidget {
  final bool isTablet;
  const OfferTypeSelector({super.key, this.isTablet=false});

  /// Maps the new shared filter values to the legacy values
  /// currently expected in the add-offer flow.
  static String _legacyEstateTypeValue(String sharedValue) {
    switch (sharedValue) {
      case 'flat':
        return 'Flat';
      case 'house':
        return 'House';
      case 'lots':
        return 'Lot';
      case 'commercial':
        return 'Commercial';
      case 'warehouse':
        return 'Warehouse';
      case 'garage':
        return 'Garage';
      default:
        return sharedValue;
    }
  }

  /// Single source of truth first:
  /// uses FilterPopConst.estateTypes where possible,
  /// then appends legacy-only items that do not yet exist there.
  static List<ButtonOption> _propertyTypeOptions() {
    final sharedOptions = FilterPopConst.estateTypes
        .map(
          (item) => ButtonOption(
            item['text'] ?? '',
            _legacyEstateTypeValue(item['filterValue'] ?? ''),
          ),
        )
        .toList();

    // final legacyExtras = <ButtonOption>[
    //   ButtonOption('Kawalerka'.tr, 'Studio'),
    //   ButtonOption('Apartament'.tr, 'Apartment'),
    //   ButtonOption('Bliźniak'.tr, 'Twin house'),
    //   ButtonOption('Szeregowiec'.tr, 'Row house'),
    //   ButtonOption('Inwestycje'.tr, 'Invest'),
    //   ButtonOption('Pokoje'.tr, 'Room'),
    // ];

    return [
      ...sharedOptions,
      // ...legacyExtras,
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addOfferState = ref.watch(addOfferProvider);
    final offerType = addOfferState.offerTypeController.text;
    final screenWidth = MediaQuery.of(context).size.width;
    final double dynamicPadding = isTablet
    ? screenWidth / 15 : screenWidth / 7 ;
    final theme = ref.watch(themeColorsProvider);
    final isUserLoggedIn = ref.watch(authStateProvider);

    log(offerType);
    log(screenWidth.toString());

    return SingleChildScrollView(
      child: Padding(
      padding: EdgeInsets.symmetric(horizontal: dynamicPadding, vertical: 20),
      child: Flex(
        direction: isTablet?Axis.vertical:Axis.horizontal,
        children: [
          Expanded(
            flex:isTablet? 0: 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 SizedBox(height: 10),
                Text(
                  'Add An Ad'.tr,
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    color: theme.primaryBackgroundTextColor,
                  ),
                ),
                Text(
                  'Follow These Steps To Add An Ad'.tr,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.primaryBackgroundTextColor,
                  ),
                ),
                 SizedBox(height: 25),
                Text(
                  'Offer Type'.tr,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: theme.primaryBackgroundTextColor,
                  ),
                ),
                const SizedBox(height: 12),
                TypeSelectorWidget(labelText: 'Select an option'.tr),
                const SizedBox(height: 10),
                if (offerType.isNotEmpty) ...[
                  PropertyTypeSelector(
                    updateField: 'estateType',
                    controller: addOfferState.estateTypeController,
                    options: _propertyTypeOptions(),
                    labelText: 'property_type'.tr,
                  ),
                ],
                const SizedBox(height: 40),
                SizedBox(
                  width: 250,
                  child: SettingsButton(
                    isPc: true,
                    buttonheight: 50,
                    onTap: () {
                      if (isUserLoggedIn) {
                        log(isUserLoggedIn.toString());
                        ref.read(progressProvider.notifier).state += 1;
                      } else {
                        log(isUserLoggedIn.toString());
                        log('user is not loggedin');
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return const LoginDialog();
                          },
                        );
                      }
                    },
                    text: 'Continue'.tr,
                    isDisabled:
                        offerType.isEmpty ||
                        addOfferState.estateTypeController.text.isEmpty,
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
          if(!isTablet)Expanded(flex: 2, child: SizedBox()),
           Expanded(flex: isTablet? 0 : 6, child: TariffPlansWidget(isTablet: isTablet)),
        ],
      ),
    )
    );
  }
}