import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:portal/screens/add_offer/pages/widgets/location_widget.dart';

import 'package:portal/screens/add_offer/provider/add_offer_provider.dart';
import 'package:portal/screens/add_offer/components/contact_detail_row.dart';
import 'package:core/common/shared_widgets/location_components.dart';
import 'package:portal/screens/add_offer/components/progress_indicator.dart';
import 'package:portal/screens/add_offer/pages/widgets/map_widget_add_offer.dart';
import 'package:core/ui/buttons/app_buttons.dart';
import 'package:core/common/custom_error_handler.dart';
import 'package:core/theme/apptheme.dart';

class GeneralInformationForm extends ConsumerWidget {
  const GeneralInformationForm({super.key});

  void validateAddOfferFields(
      BuildContext context,
      AddOfferState addOfferState,
      WidgetRef ref,
      ) {
    final fieldsToCheck = <String, String?>{
      // 'Market Type'.tr: addOfferState.marketTypeController.text.trim(),
      'Country'.tr: addOfferState.countryController.text.trim(),
      'City'.tr: addOfferState.cityController.text.trim(),
    };

    final missingFields = fieldsToCheck.entries
        .where((entry) => entry.value == null || entry.value!.isEmpty)
        .map((entry) => entry.key)
        .toList();

    // debugPrint('marketType: ${addOfferState.marketTypeController.text}');
    debugPrint('country: ${addOfferState.countryController.text}');
    debugPrint('city: ${addOfferState.cityController.text}');
    debugPrint('missingFields: $missingFields');

    if (missingFields.isNotEmpty) {
      final snackBarText = missingFields.length >= 5
          ? 'Missing required fields. Please fill all mandatory fields.'.tr
          : 'Missing: ${missingFields.join(', ')}';

      debugPrint("Younis: $snackBarText");
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
  Widget build(BuildContext context, WidgetRef ref) {
    final addOfferState = ref.watch(addOfferProvider);
    final theme = ref.watch(themeColorsProvider);

    double dynamicPadding = MediaQuery.of(context).size.width / 7;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: dynamicPadding),
      child: Row(
        children: [
          Expanded(
            flex: 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Text(
                  'General Information'.tr,
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
                  'Location'.tr,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: theme.primaryBackgroundTextColor,
                  ),
                ),
                const SizedBox(height: 10),
                HeaderLocationWidgetAddOffer(),
                MapaWidgetAddOffer(),
                const SizedBox(height: 30),
                ContactDetailRow(),
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
                          validateAddOfferFields(context, addOfferState, ref);
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
        ],
      ),
    );
  }
}