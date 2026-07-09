import 'dart:developer';
import 'package:reports/reports_urls.dart';

import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:reports/reports/create_report_page/providers/location_data_provider.dart';
import 'package:reports/reports/create_report_page/providers/providers_report.dart';
import 'package:reports/reports/create_report_page/widgets/additional_features_widget.dart';
import 'package:reports/reports/create_report_page/widgets/header_location_widget.dart';
import 'package:reports/reports/create_report_page/widgets/map_report_widget.dart';
import 'package:reports/reports/create_report_page/widgets/property_details_widget.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/ui/buttons/app_buttons.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/backgroundgradient.dart';
import 'package:core/theme/icons.dart';
import 'package:core/common/custom_error_handler.dart';
import 'package:get/get_utils/get_utils.dart';

class CreateReportPc extends ConsumerWidget {
  const CreateReportPc({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<bool> createReport(
      PropertyValuationFormState formState,
      BuildContext context,
    ) async {
      try {
        // Check for missing fields
        List<String> missingFields = [];

        // Basic required string or controller-based fields
        if (formState.country == null || formState.country!.name.isEmpty) {
          missingFields.add('Country');
        }
        if (formState.state == null || formState.state!.isEmpty) {
          missingFields.add('State');
        }
        if (formState.city == null || formState.city!.isEmpty) {
          missingFields.add('City');
        }
        if (formState.streetAddressController.text.trim().isEmpty) {
          missingFields.add('Street Address');
        }
        if (formState.zipcodeController.text.trim().isEmpty) {
          missingFields.add('Zipcode');
        }

        // Optional: Add checks for other critical fields (if you want)
        if (formState.propertyType == null || formState.propertyType!.isEmpty) {
          missingFields.add('Property Type');
        }
        if (formState.typeOfBuilding == null ||
            formState.typeOfBuilding!.isEmpty) {
          missingFields.add('Type of Building');
        }
        if (formState.buildingMaterial == null ||
            formState.buildingMaterial!.isEmpty) {
          missingFields.add('Building Material');
        }
        if (formState.heatingType == null || formState.heatingType!.isEmpty) {
          missingFields.add('Heating Type');
        }

        // If any fields are missing, show a warning and return
        if (missingFields.isNotEmpty) {
          final snackBar = Customsnackbar().showSnackBar(
            'missing_fields'.tr,
            'please_fill_in_the_following'.tr + missingFields.join(', '),
            "warning",
            () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
          );
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
          return false;
        }

        // Handle property type - if "All types" selected, use a default single type
        final propertyTypeValue =
            formState.propertyType == 'All types'
                ? 'House' // Default to House when All types is selected
                : formState.propertyType!;

        // Prepare request data
        final requestData = {
          "street_address": formState.streetAddressController.text,
          "city": formState.city,
          "state": formState.state,
          "country": formState.country!.name,
          "zipcode": formState.zipcodeController.text,
          "distance_filter": formState.distanceFilter,
          "property_type": propertyTypeValue,
          "type_of_building": formState.typeOfBuilding,
          "building_material": formState.buildingMaterial,
          "heating_type": formState.heatingType,
          "floor_area":
              double.tryParse(formState.floorAreaController.text) ?? 0,
          "year_built":
              int.tryParse(formState.yearBuiltController.text) ?? 2147483647,
          "floor_level":
              int.tryParse(formState.floorLevelController.text) ?? 2147483647,
          "bedrooms": formState.bedrooms,
          "bathrooms": formState.bathrooms,
          "has_balcony": formState.hasBalcony,
          "has_elevator": formState.hasElevator,
          "has_sauna": formState.hasSauna,
          "has_parking": formState.hasParking,
          "has_gym": formState.hasGym,
          "has_air_conditioning": formState.hasAirConditioning,
          "has_garden": formState.hasGarden,
          "has_basement": formState.hasBasement,
          "neighborhood":
              formState.neighborhoodController.text.isEmpty
                  ? "no"
                  : formState.neighborhoodController.text,
          "distance_to_public_transport":
              formState.distanceToPublicTransportController.text.isEmpty
                  ? "100"
                  : formState.distanceToPublicTransportController.text,
          "has_highways": formState.hasHighwayAccess,
          "boost_productivity": formState.boostProductivity ?? "No",
          "exclusive": formState.exclusiveController.text,
          "boost_productivity_facility":
              formState.boostProductivityFacilityController.text,

          // Additional fields to match example JSON
          "value_estimate": null,
          "recent_sales_data": null,
        };

        log('🔄 Request Data: $requestData');

        final response = await ApiServices.post(
          ReportsUrls.createReport,
          data: requestData,
          hasToken: true,
        );

        if (response != null &&
            (response.statusCode == 200 || response.statusCode == 201)) {
          log('✅ Report created successfully');
          final snackBar = Customsnackbar().showSnackBar(
            "Success".tr,
            'successfully_created_report'.tr,
            "success",
            () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
          );

          ScaffoldMessenger.of(context).showSnackBar(snackBar);

          ref.read(navigationService).pushNamedScreen(Routes.allReports);
          return true;
        } else {
          log('❌ Failed to create report');
          log('Status Code: ${response?.statusCode}');
          log('Response Data: ${response?.data}');
          final snackBar = Customsnackbar().showSnackBar(
            "Error".tr,
           'error_creating_report'.tr,
            "error",
            () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
          );
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        }
      } catch (e, stack) {
        log('❌ Exception during report creation');
        log('Error: $e');
        log('StackTrace: $stack');
        final snackBar = Customsnackbar().showSnackBar(
          "Error".tr,
          'unexpected_error_occurred'.tr,
          "error",
          () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }

      return false;
    }

    final formState = ref.watch(propertyValuationFormProvider);
    final sideMenuKey = GlobalKey<SideMenuState>();
    final screenWidth = MediaQuery.of(context).size.width;
    final theme = ref.watch(themeColorsProvider);
    final locationNotifier = ref.read(locationProviderReport.notifier);
    final ScrollController _scrollController = ScrollController();
    return 
       SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Row(
                    children: [
                      SizedBox(width: constraints.maxWidth * 0.1),

                      Container(
                        width: constraints.maxWidth * 0.8,
                        padding: const EdgeInsets.symmetric(
                          vertical: 40,
                          horizontal: 20,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 60),
                            Text(
                              'how_much_is_your_property_worth'.tr,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: CustomColors.mainBackgroundtextColor(
                                  context,
                                  ref,
                                ),
                              ),
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'get_property_report_description'.tr,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color:
                                          CustomColors.mainBackgroundtextColor(
                                            context,
                                            ref,
                                          ).withAlpha(153),
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () {},
                                  child: SizedBox(
                                    child: Row(
                                      children: [
                                        AppIcons.folder(
                                          color:
                                              CustomColors.mainBackgroundtextColor(
                                                context,
                                                ref,
                                              ),
                                        ),

                                        SizedBox(width: 5),
                                        Text(
                                          'sample_report'.tr,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color:
                                                CustomColors.mainBackgroundtextColor(
                                                  context,
                                                  ref,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20),

                            Container(
                              padding: EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: Theme.of(context).iconTheme.color!,
                                ),
                              ),
                              child: Column(
                                children: [
                                  HeaderLocationWidget(),
                                  PropertyDetailsWidget(),
                                  AdditionalFeaturesMapWidget(),
                                ],
                              ),
                            ),
                            SizedBox(height: 20),
                            MapaWidget(),
                            SizedBox(height: 10),

                            // Apply LayoutBuilder to the "Create A Report" button
                            Row(
                              children: [
                                Spacer(),
                                CustomElevatedButton(
                                  text: "Create A Report".tr,
                                  onTap: () async {
                                    bool succss = await createReport(
                                      formState,
                                      context,
                                    );

                                    if (succss) {
                                      // Clear the form state after successful report creation
                                      ref
                                          .read(
                                            propertyValuationFormProvider
                                                .notifier,
                                          )
                                          .resetFields();
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: constraints.maxWidth * 0.1),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      );
    
  }
}
