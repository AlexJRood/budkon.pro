import 'dart:developer';
import 'package:reports/reports_urls.dart';

import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:core/ui/device_type_util.dart';
import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:reports/reports/create_report_page/providers/location_data_provider.dart';
import 'package:reports/reports/create_report_page/providers/providers_report.dart';
import 'package:reports/reports/create_report_page/widgets/header_location_widget.dart';
import 'package:reports/reports/create_report_page/widgets/mobile/additional_features_mobile.dart';
import 'package:reports/reports/create_report_page/widgets/mobile/bedroom_and_bathroom.dart';
import 'package:reports/reports/create_report_page/widgets/mobile/property_details_mobile.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/ui/buttons/app_buttons.dart';
import 'package:core/theme/backgroundgradient.dart';
import 'package:core/theme/icons.dart';
import 'package:core/common/custom_error_handler.dart';

class CreateReportMobile extends ConsumerWidget {
  const CreateReportMobile({super.key});

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
            "Missing Fields",
            "Please fill in the following: ${missingFields.join(', ')}",
            "warning".tr,
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
            "Success",
            "Successfully Created Report",
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
            "Error",
            "An error occurred while creating the report.",
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
          "Error",
          "An unexpected error occurred.",
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

    final locationNotifier = ref.read(locationProviderReport.notifier);
    return Column(
      children: [
        SizedBox(height: TopAppBarSize.resolve(context)),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 40,
                                horizontal: 20,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 50),
                                  Text(
                                    "How much is your property worth?",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          CustomColors.mainBackgroundtextColor(
                                            context,
                                            ref,
                                          ),
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            flex: 5,
                                            child: Text(
                                              "Get a property report including recent sales in your neighbourhood and a property value estimate.",
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
                                          Expanded(child: SizedBox(width: 10)),
                                        ],
                                      ),
                                      SizedBox(height: 10),
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
                                                "Sample Report",
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
                                      SizedBox(height: 15),
                                      DottedLine(
                                        dashColor:
                                            CustomColors.secondaryWidgetTextColor(
                                              context,
                                              ref,
                                            ),
                                      ),
                                      SizedBox(height: 15),
                                      HeaderLocationWidget(isMobile: true),
                                      SizedBox(height: 15),
                                      DottedLine(
                                        dashColor:
                                            CustomColors.secondaryWidgetTextColor(
                                              context,
                                              ref,
                                            ),
                                      ),
                                      SizedBox(height: 15),
                                      PropertyDetailsMobile(),
                                      SizedBox(height: 15),
                                      DottedLine(
                                        dashColor:
                                            CustomColors.secondaryWidgetTextColor(
                                              context,
                                              ref,
                                            ),
                                      ),
                                      SizedBox(height: 15),
                                      BedroomAndBathroomMobile(),
                                      SizedBox(height: 15),
                                      DottedLine(
                                        dashColor:
                                            CustomColors.secondaryWidgetTextColor(
                                              context,
                                              ref,
                                            ),
                                      ),
                                      SizedBox(height: 15),
                                      AdditionalFeaturesMobile(),
                                      DottedLine(
                                        dashColor:
                                            CustomColors.secondaryWidgetTextColor(
                                              context,
                                              ref,
                                            ),
                                      ),
                                      SizedBox(height: 15),

                                      Row(
                                        children: [
                                          Expanded(
                                            child: SizedBox(
                                              height: 50,
                                              child: CustomElevatedButton(
                                                fontSize: 15,
                                                text: "Create Report",
                                                onTap: () async {
                                                  bool succss =
                                                      await createReport(
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
                                                    FocusScope.of(
                                                      context,
                                                    ).unfocus();
                                                  }
                                                },
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 40),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: TopAppBarSize.withTopAppBar(context)),
      ],
    );
  }
}
