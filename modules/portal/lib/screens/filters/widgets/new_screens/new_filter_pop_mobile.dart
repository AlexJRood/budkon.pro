import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:portal/screens/filters/widgets/new_widgets/custom-drop_down.dart';
import 'package:portal/screens/filters/widgets/new_widgets/filltered_button.dart';
import 'package:portal/screens/filters/widgets/new_widgets/grid_view_additional_info.dart';
import 'package:portal/screens/filters/widgets/new_widgets/grid_view_state_type.dart';
import 'package:portal/screens/filters/widgets/new_widgets/key_property_button.dart';
import 'package:portal/screens/filters/widgets/new_widgets/mobile_filters_area_widget.dart';
import 'package:core/theme/icons.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:core/platform/filters/filters_const.dart';
import 'package:core/theme/design.dart';
import 'package:get/get_utils/get_utils.dart';

class NewFilterPopMobile extends ConsumerWidget {
  const NewFilterPopMobile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dropdownValues = ref.watch(dropdownProvider);
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;
    const lineSpacer = '- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - ';
    return Stack(
      children: [
        BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            color: AppColors.dark75,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        Center(
            child: Container(
              width: screenWidth,
              height: math.max(screenHeight * 0.91, 400),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(50, 50, 50, 1),
                borderRadius: BorderRadius.circular(6.0),
              ),
              child: SingleChildScrollView(
                child: Column(
                  spacing: 12,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10.0, vertical: 10),
                      child: Column(
                        spacing: 12,
                        children: [
                          // TODO: finish flow
                          // Row(
                          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          //   children: [
                          //     Expanded(
                          //       child: TextField(
                          //         style: const TextStyle(
                          //             color: Colors.white), // For text color
                          //         cursorColor: Colors.white, // Cursor color
                          //         decoration: InputDecoration(
                          //           filled: true,
                          //           fillColor: const Color.fromRGBO(45, 45, 45,
                          //               1), // Match the dark background color
                          //           hintText:
                          //           'Search region, suburb or postcode'.tr, // Add placeholder text
                          //           hintStyle: const TextStyle(
                          //               color: Color.fromRGBO(145, 145, 145, 1),
                          //               fontSize: 14), // Placeholder text color
                          //           contentPadding: const EdgeInsets.symmetric(
                          //               horizontal: 16, vertical: 14),
                          //           border: OutlineInputBorder(
                          //             borderRadius: BorderRadius.circular(
                          //                 8), // Rounded corners
                          //             borderSide: BorderSide.none, // No border
                          //           ),
                          //           suffixIcon: AppIcons.search(height: 18,
                          //               width: 18,
                          //               color: const Color.fromRGBO(
                          //                   145, 145, 145, 1)), // Add search icon
                          //         ),
                          //       ),
                          //     ),
                          //     const SizedBox(width: 20),
                          //     IconButton(
                          //         onPressed: () {},
                          //         icon: const Icon(
                          //           Icons.favorite_border,
                          //           color: Color.fromRGBO(255, 255, 255, 1),
                          //         ))
                          //   ],
                          // ),
                          Row(
                            spacing: 10,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: FilteredButton(
                                  text: 'offer_type_sell'.tr,
                                  filterValue: 'sell',
                                  filterKey: 'offer_type',
                                  minHeight: 48,
                                ),
                              ),
                              Expanded(
                                child: FilteredButton(
                                  text: 'offer_type_rent'.tr,
                                  filterValue: 'rent',
                                  filterKey: 'offer_type',
                                  minHeight: 48,
                                ),
                              )
                            ],
                          ),
                          const Text(lineSpacer,
                            style:
                            TextStyle(color: Color.fromRGBO(90, 90, 90, 1)),
                            maxLines: 1,
                          ),
                          Column(
                            spacing: 10,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'property_type'.tr,
                                style: TextStyle(
                                    color: Color.fromRGBO(255, 255, 255, 1),
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700),
                              ),
                              GridViewEstateTypes(
                                  estateTypes: FilterPopConst.estateTypes),
                              Column(
                                spacing: 16,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Key Property Features'.tr,
                                    style: TextStyle(
                                        color: Color.fromRGBO(255, 255, 255, 1),
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700),
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: KeyPropertyButton(
                                            text: 'Primary'.tr,
                                            filterValue: 'primary',
                                            filterKey: 'market_type'),
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: KeyPropertyButton(
                                            text: 'Secondary'.tr,
                                            filterValue: 'secondary',
                                            filterKey: 'market_type'),
                                      )
                                    ],
                                  ),
                                  CustomDropdown(
                                    label: 'Type of building'.tr,
                                    options: FilterPopConst.typeOfBuildingOptions,
                                    value: dropdownValues['building_type']!.value,
                                    onChanged: (newValue) {
                                      ref
                                          .read(dropdownProvider.notifier)
                                          .updateValue(
                                          'buiding_type', newValue!);
                                    },
                                    width: screenWidth,
                                    height: 46,
                                  ),
                                  CustomDropdown(
                                    label: 'Building Material'.tr,
                                    options:
                                    FilterPopConst.buildingMaterialOptions,
                                    value: dropdownValues['building_material']!.value,
                                    onChanged: (newValue) {
                                      ref
                                          .read(dropdownProvider.notifier)
                                          .updateValue(
                                          'building_material', newValue!);
                                    },
                                    width: screenWidth,
                                    height: 46,
                                  ),
                                  CustomDropdown(
                                    label: 'Heating type'.tr,
                                    options: FilterPopConst.heatingTypeOptions,
                                    value: dropdownValues['heating_type']!.value,
                                    onChanged: (newValue) {
                                      ref
                                          .read(dropdownProvider.notifier)
                                          .updateValue('heating_type', newValue!);
                                    },
                                    width: screenWidth,
                                    height: 46,
                                  ),
                                  CustomDropdown(
                                    label: 'Advertiser'.tr,
                                    options: FilterPopConst.advertiserOptions,
                                    value: dropdownValues['advertiser_type']!.value,
                                    onChanged: (newValue) {
                                      ref
                                          .read(dropdownProvider.notifier)
                                          .updateValue('advertiser_type', newValue!);
                                    },
                                    width: screenWidth,
                                    height: 46,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Text(lineSpacer,
                            style:
                            TextStyle(color: Color.fromRGBO(90, 90, 90, 1)),
                            maxLines: 1,
                          ),
                          const MobileFiltersAreaWidget(lineSpacer: lineSpacer),
                          const Text(lineSpacer,
                            style:
                            TextStyle(color: Color.fromRGBO(90, 90, 90, 1)),
                            maxLines: 1,
                          ),
                          Column(
                            spacing: 10,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                'Additional Features'.tr,
                                style: TextStyle(
                                    color: Color.fromRGBO(255, 255, 255, 1),
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700),
                              ),
                              GridViewAdditionalInfo(
                                  additionalInfo: FilterPopConst.additionalInfo)
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                        height: 68,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(6),
                                topRight: Radius.circular(6))),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                height: 48,
                                width: 152,
                                color: Colors.transparent,
                                child: Center(
                                  child: Text(
                                    'Advanced filters'.tr,
                                    style: TextStyle(
                                        color: AppColors.light,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  Container(
                                    height: 48,
                                    width: 55,
                                    color: Colors.transparent,
                                    child: Center(
                                      child: Text('Clear'.tr,
                                          style: TextStyle(
                                            color: AppColors.light50,
                                          )),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Container(
                                    height: 48,
                                    width: 65,
                                    decoration: BoxDecoration(
                                        color: const Color.fromRGBO(
                                            87, 148, 221, 0.2),
                                        borderRadius: BorderRadius.circular(6)),
                                    child: Center(
                                      child: Text('Search'.tr,
                                          style: TextStyle(
                                            color: AppColors.light50,
                                          )),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ))
                  ],
                ),
              ),
            ))
      ],
    );
  }
}


