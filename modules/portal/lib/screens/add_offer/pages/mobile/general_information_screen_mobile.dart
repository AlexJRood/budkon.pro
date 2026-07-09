import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';

import 'package:portal/screens/add_offer/provider/add_offer_provider.dart';
import 'package:portal/screens/add_offer/components/contact_detail_row.dart';
import 'package:core/common/shared_widgets/location_components.dart';
import 'package:portal/screens/add_offer/components/progress_indicator.dart';
import 'package:portal/screens/add_offer/pages/widgets/apartment_variant_mobile.dart';
import 'package:portal/screens/add_offer/pages/widgets/garage_varient_mobile.dart';
import 'package:portal/screens/add_offer/pages/widgets/location_widget.dart';
import 'package:portal/screens/add_offer/pages/widgets/plot_varient_mobile.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/ui/buttons/app_buttons.dart';
import 'package:core/common/custom_error_handler.dart';

import 'package:core/theme/apptheme.dart';

class GeneralInformationScreenMobile extends ConsumerStatefulWidget {
  final bool isMobile;

  const GeneralInformationScreenMobile({
    super.key,
    this.isMobile = false,
  });

  @override
  ConsumerState<GeneralInformationScreenMobile> createState() => _GeneralInformationScreenMobileState();
}

class _GeneralInformationScreenMobileState extends ConsumerState<GeneralInformationScreenMobile> {
  final FocusNode _priceFocusNode = FocusNode();
  final GlobalKey _priceFieldKey = GlobalKey();
  final FocusNode _surfaceFocusNode = FocusNode();
  @override
  void initState() {
    super.initState();

    _priceFocusNode.addListener(() {
      if (_priceFocusNode.hasFocus) {
        _scrollToField(_priceFieldKey);
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
    _priceFocusNode.dispose();
    _surfaceFocusNode.dispose();
    super.dispose();
  }
  void validateAddOfferFields(
      BuildContext context,
      AddOfferState addOfferState,
      WidgetRef ref,
      ) {
    final fieldsToCheck = <String, String?>{
      'Country'.tr: addOfferState.countryController.text.trim(),
      'City'.tr: addOfferState.cityController.text.trim(),
    };

    final missingFields = fieldsToCheck.entries
        .where((entry) => entry.value == null || entry.value!.isEmpty)
        .map((entry) => entry.key)
        .toList();

    if (missingFields.isNotEmpty) {
      final snackBarText = missingFields.length >= 5
          ? 'Missing required fields. Please fill all mandatory fields.'.tr
          : 'Missing: ${missingFields.join(', ')}';

      ref.read(navigationService).showSnackbar(
        Customsnackbar().showSnackBar(
          "Warning".tr,
          snackBarText,
          'warning'.tr,
          null,
        ),
      );
    } else {
      ref.read(progressProvider.notifier).state += 1;
    }
  }

  @override
  Widget build(BuildContext context,) {
    final addOfferState = ref.watch(addOfferProvider);
    final theme = ref.watch(themeColorsProvider);
    final screenWidth = MediaQuery.of(context).size.width;

    final double dynamicPadding = screenWidth <= 500 ? 15 : screenWidth / 8;

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
                  const SizedBox(height: 30),
                  Text(
                    'General Information'.tr,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryBackgroundTextColor,
                    ),
                  ),
                  Text(
                    'Searchers will appreciate detailed information about your property.'.tr,
                    style: TextStyle(
                      fontSize: 14,
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
                  HeaderLocationWidgetAddOffer(isMobile: true),
                  ContactDetailRow(isMobile: true),
                  const SizedBox(height: 40),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 12,
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
                        SizedBox(
                          width: screenWidth <= 360 ? 200 : 250,
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