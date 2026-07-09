import 'dart:developer';

import 'package:core/ui/device_type_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:portal/screens/add_offer/provider/add_offer_provider.dart';
import 'package:portal/screens/add_offer/components/progress_indicator.dart';
import 'package:portal/screens/add_offer/components/property_type_selector.dart';
import 'package:portal/screens/add_offer/components/tariff_tile.dart';
import 'package:portal/screens/add_offer/components/type_selector_widget.dart';
import 'package:portal/screens/edit_offer/components/edit_fileds.dart';
import 'package:core/platform/route_constant.dart';

import 'package:core/ui/buttons/app_buttons.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/user/login/login/login_navigation.dart';
import 'package:core/user/user/user_provider.dart';

class OfferTypeSelectorMobile extends ConsumerWidget {
  const OfferTypeSelectorMobile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addOfferState = ref.watch(addOfferProvider); // Watch the
    final addOfferStateNotifier = ref.watch(
      addOfferProvider.notifier,
    ); // Watch the provider
    final offerType = addOfferState.offerTypeController.text; // Get offerType
    double dynamicPadding =
        MediaQuery.of(context).size.width <= 500
            ? 15
            : MediaQuery.of(context).size.width / 8;
    final theme = ref.watch(themeColorsProvider);

    log(offerType);
    log(MediaQuery.of(context).size.width.toString());
    final isUserLoggedIn = ref.watch(authStateProvider);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: dynamicPadding),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SizedBox(
            //   height: TopAppBarSize.resolve(context),
            // ),
            SizedBox(height: 30),
            Text(
              'Add An Ad'.tr,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.primaryBackgroundTextColor,
              ),
            ),
            Text(
              'Follow These Steps To Add An Ad'.tr,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: theme.primaryBackgroundTextColor,
              ),
            ),
            SizedBox(height: 25),
            Text(
              'Offer Type'.tr,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: theme.primaryBackgroundTextColor,
              ),
            ),
            const SizedBox(height: 12),
            TypeSelectorWidget(labelText: "Select an option".tr, isMobile: true),
            SizedBox(height: 10),
            Row(
              children: [
                Spacer(),
                TextButton(
                  onPressed: () {
                    showBottomSheet(
                      context: context,
                      builder: (BuildContext context) {
                        return Container(
                          height: MediaQuery.of(context).size.height * 0.9,
                          color: theme.secondaryWidgetColor,
                          padding: EdgeInsets.all(10),

                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Spacer(),
                                  Container(
                                    height: 10,
                                    width: 30,

                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  Spacer(),
                                ],
                              ),
                              SizedBox(height: 16),
                              TariffPlansWidget(isMobile: true),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  child: Text(
                    "View tariff".tr,
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Spacer(),
              ],
            ),
            SizedBox(height: 40),
            if (offerType.isNotEmpty) ...[
              PropertyTypeSelectorMobile(
                updateField: 'estateType',
                controller: addOfferState.estateTypeController,
                options: [
                 ButtonOption('apartment_option'.tr, 'Flat'.tr),
                 ButtonOption('studio_flat'.tr, 'Studio'.tr),
                 ButtonOption('apartment_buildings'.tr, 'Apartment'.tr),
                 ButtonOption('single_family_house'.tr, 'House'.tr),
                 ButtonOption('semi_detached_house'.tr, 'Twin house'.tr),
                 ButtonOption('townhouse'.tr, 'Row house'.tr),
                 ButtonOption('investments'.tr, 'Invest'.tr),
                 ButtonOption('plots'.tr, 'Lot'.tr),
                 ButtonOption('commercial_premises'.tr, 'Commercial'.tr),
                 ButtonOption('halls_and_warehouses'.tr, 'Warehouse'.tr),
                 ButtonOption('Rooms'.tr, 'Room'.tr),
                 ButtonOption('garages'.tr, 'Garage'.tr),
               ],
                labelText: 'property_type_label'.tr,
              ),
            ],
            SizedBox(height: 80),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
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
                          log("user is  not loggedin");
                          pushLoginNative(ref);
                        }
                      },
                      text: "Continue".tr,
                      isDisabled:
                          offerType.isEmpty ||
                          addOfferState.estateTypeController.text.isEmpty,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 40),
            SizedBox(
              height: TopAppBarSize.withTopAppBar(context),
            ),
          ],
        ),
      ),
    );
  }
}
