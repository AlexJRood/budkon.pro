import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:core/theme/icons.dart';
import 'package:core/theme/design.dart';
import 'package:core/common/custom_error_handler.dart';
import 'package:crm/data/add_field/sell_offer_provider.dart';

import 'package:get/get_utils/get_utils.dart';

// ignore: must_be_immutable
class AddOfferCrm extends ConsumerWidget {
  double addOfferFontSize = 14;
  double dynamiBoxHeigth = 25;
  double dynamicSpacer = 15;
  AddOfferCrm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addOfferState = ref.watch(crmAddSellOfferProvider);
    double screenWidth = MediaQuery.of(context).size.width;

    return SizedBox(
      width: double.infinity, // Zajmuje całą szerokość ekranu
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          if (addOfferState.imagesData.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'your_main_photo_label'.tr,
                style: AppTextStyles.interMedium.copyWith(
                  fontSize: 18,
                  color: AppColors.light,
                ),
              ),
            ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: addOfferState.imagesData.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      int indexToSet = addOfferState.mainImageIndex ?? 0;
                      ref
                          .read(crmAddSellOfferProvider.notifier)
                          .setMainImageIndex(indexToSet);
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.memory(
                          addOfferState
                              .imagesData[addOfferState.mainImageIndex ?? 0],
                          width: double.infinity,
                          height: screenWidth * (650 / 1200) / 2,
                          fit: BoxFit.cover,
                        ),
                        if (addOfferState.mainImageIndex != null)
                          const Positioned(
                            top: 0,
                            right: 0,
                            child: Icon(Icons.star, color: AppColors.light),
                          ),
                      ],
                    ),
                  )
                : Container(),
          ),
          const SizedBox(height: 7),
          if (addOfferState.imagesData.isNotEmpty &&
              addOfferState.imagesData.length > 1)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'remaining_photos'.tr,
                    style: AppTextStyles.interMedium.copyWith(
                      fontSize: 18,
                      color: AppColors.light,
                    ),
                  ),
                  Text(
                    'select_main_photo_by_clicking_on_thumbnail'.tr,
                    style: AppTextStyles.interMedium.copyWith(
                      fontSize: 12,
                      color: AppColors.light,
                    ),
                  ),
                ],
              ),
            ),
          // Użyj Wrap lub Column zamiast GridView.builder
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (int index = 0;
                  index < addOfferState.imagesData.length;
                  index++)
                GestureDetector(
                  onTap: () {
                    ref
                        .read(crmAddSellOfferProvider.notifier)
                        .setMainImageIndex(index);
                  },
                  child: Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: MemoryImage(addOfferState.imagesData[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          icon:
                              AppIcons.delete(color: AppColors.light),
                          onPressed: () {
                            if (addOfferState.imagesData.length > 4) {
                              ref
                                  .read(crmAddSellOfferProvider.notifier)
                                  .removeImage(index);
                            } else {
                              final snackBar = Customsnackbar().showSnackBar(
                                  "Warning".tr,
                                  'must_add_at_least_4_photos'.tr,
                                  "warning".tr, () {
                                ScaffoldMessenger.of(context)
                                    .hideCurrentSnackBar();
                              });
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(snackBar);
                            }
                          },
                        ),
                      ),
                      if (index == addOfferState.mainImageIndex)
                        const Positioned(
                          top: 0,
                          left: 0,
                          child: Icon(Icons.star, color: AppColors.light),
                        ),
                    ],
                  ),
                ),
              // Przycisk dodawania zdjęcia
              GestureDetector(
                onTap: () =>
                    ref.read(crmAddSellOfferProvider.notifier).pickImage(),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.light),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.add,
                      color: AppColors.light,
                      size: 48,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: dynamiBoxHeigth),
          // Inne elementy interfejsu
          selectButtonsOptions(
            controller: ref.watch(crmAddSellOfferProvider).offerTypeController,
            options: [
              ButtonOption('want_to_sell_option'.tr, 'sell'),
              ButtonOption('want_to_rent_option'.tr, 'rent'),
            ],
            labelText: 'what_do_you_want_to_do_with_property'.tr,
            context: context,
          ),
          SizedBox(height: dynamiBoxHeigth),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'property_address_question'.tr,
                style: AppTextStyles.interRegular
                    .copyWith(fontSize: 14, color: AppColors.light),
              ),
              SizedBox(height: dynamicSpacer),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: buildDropdownButtonFormField(
                      controller:
                          ref.watch(crmAddSellOfferProvider).countryController,
                      items: ['poland'.tr, 'country_2'.tr, 'country_3'.tr],
                      labelText: 'country'.tr,
                      ref: ref,
                    ),
                  ),
                  SizedBox(width: dynamicSpacer),
                ],
              ),
              SizedBox(height: dynamicSpacer),
              Row(
                children: [
                  SizedBox(width: dynamiBoxHeigth),
                  Expanded(
                    flex: 2,
                    child: buildDropdownButtonFormField(
                      controller:
                          ref.watch(crmAddSellOfferProvider).zipcodeController,
                      items: ['71204', '75488', '12345'],
                      labelText: 'postal_code'.tr,
                      ref: ref,
                    ),
                  ),
                  const Spacer(flex: 1),
                ],
              ),
            ],
          ),
          SizedBox(height: dynamiBoxHeigth),
          selectButtonsOptions(
            controller: ref.watch(crmAddSellOfferProvider).estateTypeController,
            options: [
              ButtonOption('apartment_option'.tr, 'Flat'.tr),
              ButtonOption('studio_flat'.tr, 'Studio'.tr),
              ButtonOption('apartment_buildings'.tr, 'Apartment'.tr),
              ButtonOption('house_type_option'.tr, 'House'.tr),
              ButtonOption('semi_detached_type_option'.tr, 'Twin house'.tr),
              ButtonOption('townhouse_type_option'.tr, 'Row house'.tr),
              ButtonOption('investments_type_option'.tr, 'Invest'.tr),
              ButtonOption('plots_type_option'.tr, 'Lot'.tr),
              ButtonOption('commercial_type_option'.tr, 'Commercial'.tr),
              ButtonOption('warehouse_type_option'.tr, 'Warehouse'.tr),
              ButtonOption('rooms_type_option'.tr, 'Room'.tr),
              ButtonOption('garages_type_option'.tr, 'Garage'.tr),
            ],
            labelText: 'property_type'.tr,
            context: context,
          ),
          SizedBox(height: dynamiBoxHeigth),
          SizedBox(height: dynamiBoxHeigth),
          Text(
            'what_do_you_want_to_tell_others_about_your_property'.tr,
            style: AppTextStyles.interRegular
                .copyWith(fontSize: 14, color: AppColors.light),
          ),
          SizedBox(height: dynamiBoxHeigth),
          buildTextField(
            controller: ref.watch(crmAddSellOfferProvider).titleController,
            labelText: 'ad_title'.tr,
            context: context,
            maxLines: 1,
          ),
          SizedBox(height: dynamicSpacer),
          buildTextFieldDes(
            controller:
                ref.watch(crmAddSellOfferProvider).descriptionController,
            labelText: 'listing_description_label'.tr,
            context: context,
          ),
          SizedBox(height: dynamiBoxHeigth),
          SizedBox(height: dynamiBoxHeigth),
          Text(
            'what_is_property_price'.tr,
            style: AppTextStyles.interRegular
                .copyWith(fontSize: 14, color: AppColors.light),
          ),
          SizedBox(height: dynamiBoxHeigth),
          Column(
            children: [
              buildDropdownButtonFormField(
                controller:
                    ref.watch(crmAddSellOfferProvider).currencyController,
                items: ['PLN', 'EUR', 'GBP', 'USD', 'CZK'],
                labelText: 'Currency'.tr,
                ref: ref,
              ),
              SizedBox(height: dynamicSpacer),
              buildNumberTextField(
                controller: ref.watch(crmAddSellOfferProvider).priceController,
                labelText: 'how_much_sell_property'.tr,
                context: context,
                unit: '',
              ),
            ],
          ),
          SizedBox(height: dynamiBoxHeigth),
          SizedBox(height: dynamiBoxHeigth),
          Text(
            'add_property_information'.tr,
            style: AppTextStyles.interRegular
                .copyWith(fontSize: 14, color: AppColors.light),
          ),
          SizedBox(height: dynamicSpacer),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          children: [
                            buildSelectableButtonsFormField(
                              controller: ref
                                  .watch(crmAddSellOfferProvider)
                                  .roomsController,
                              options: ['1', '2', '3', '4', '5', '6', '7+'],
                              labelText: 'room_number'.tr,
                              context: context,
                            ),
                          ],
                        ),
                        SizedBox(height: dynamicSpacer),
                        Wrap(
                          children: [
                            buildSelectableButtonsFormField(
                              controller: ref
                                  .watch(crmAddSellOfferProvider)
                                  .bathroomsController,
                              options: ['1', '2', '3', '4', '5', '6', '7+'],
                              labelText: 'bathroom_number_label'.tr,
                              context: context,
                            ),
                          ],
                        ),
                        SizedBox(height: dynamicSpacer * 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: buildNumberTextField(
                                controller: ref
                                    .watch(crmAddSellOfferProvider)
                                    .floorController,
                                labelText: 'Floor'.tr,
                                context: context,
                                unit: 'Piętro',
                              ),
                            ),
                            SizedBox(width: dynamicSpacer),
                            Expanded(
                              flex: 2,
                              child: buildNumberTextField(
                                controller: ref
                                    .watch(crmAddSellOfferProvider)
                                    .totalFloorsController,
                                labelText: 'number_of_floors_label'.tr,
                                context: context,
                                unit: 'Pięter',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(width: dynamicSpacer),
              Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Column(
                        children: [
                          SizedBox(height: dynamicSpacer),
                          buildDropdownButtonFormField(
                            controller: ref
                                .watch(crmAddSellOfferProvider)
                                .buildingTypeController,
                            items: [
                              'apartment_block'.tr,
                              'apartment_building'.tr,
                              'townhouse'.tr,
                              'tenement'.tr,
                              'high_rise'.tr,
                              'loft'.tr
                            ],
                            labelText: 'Rodzaj zabudowy'.tr,
                            ref: ref,
                          ),
                          SizedBox(height: dynamicSpacer),
                          buildDropdownButtonFormField(
                            controller: ref
                                .watch(crmAddSellOfferProvider)
                                .heatingTypeController,
                            items: [
                              'Gas'.tr,
                              'Electric'.tr,
                              'Municipal'.tr,
                              'Heat Pump'.tr,
                              'Oil Heating'.tr,
                              'All'.tr,
                              'No Information Provided'.tr
                            ],
                            labelText: 'Heating type'.tr,
                            ref: ref,
                          ),
                          SizedBox(height: dynamicSpacer),
                          buildDropdownButtonFormField(
                            controller: ref
                                .watch(crmAddSellOfferProvider)
                                .buildingMaterialController,
                            items: [
                              'building_material_option_brick'.tr,
                              'building_material_option_panel'.tr,
                              'silicate'.tr,
                              'concrete'.tr,
                              'aerated_concrete'.tr,
                              'hollow_block'.tr,
                              'reinforced_concrete'.tr,
                              'ceramsite'.tr,
                              'wood'.tr,
                              'other_gender'.tr
                            ],
                            labelText: 'building_material_label'.tr,
                            ref: ref,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: dynamiBoxHeigth),
          SizedBox(height: dynamiBoxHeigth),
          Text(
            'property_information_label'.tr,
            style: AppTextStyles.interRegular
                .copyWith(fontSize: 14, color: AppColors.light),
          ),
          SizedBox(height: dynamicSpacer),
          Column(
            children: [
              buildNumberTextField(
                controller:
                    ref.watch(crmAddSellOfferProvider).buildYearController,
                labelText: 'year_of_build_label'.tr,
                context: context,
                unit: '',
              ),
              SizedBox(height: dynamicSpacer),
              buildNumberTextField(
                controller:
                    ref.watch(crmAddSellOfferProvider).squareFootageController,
                labelText: 'what_is_the_square_footage_of_your_property'.tr,
                context: context,
                unit: 'm²',
              ),
            ],
          ),
          SizedBox(height: dynamiBoxHeigth),
          SizedBox(height: dynamiBoxHeigth),
          Text(
            'additional_information_title'.tr,
            style: AppTextStyles.interRegular
                .copyWith(fontSize: 14, color: AppColors.light),
          ),
          SizedBox(height: dynamicSpacer),

          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              AdditionalInfoFilterButton(
                text: 'Balcony'.tr,
                controller:
                    ref.watch(crmAddSellOfferProvider).balconyController,
              ),
              AdditionalInfoFilterButton(
                text: 'Taras'.tr,
                controller:
                    ref.watch(crmAddSellOfferProvider).terraceController,
              ),
              AdditionalInfoFilterButton(
                text: 'Sauna'.tr,
                controller: ref.watch(crmAddSellOfferProvider).saunaController,
              ),
              AdditionalInfoFilterButton(
                text: 'Jacuzzi',
                controller:
                    ref.watch(crmAddSellOfferProvider).jacuzziController,
              ),
              AdditionalInfoFilterButton(
                text: 'Basement'.tr,
                controller:
                    ref.watch(crmAddSellOfferProvider).basementController,
              ),
              AdditionalInfoFilterButton(
                text: 'Parking space'.tr,
                controller:
                    ref.watch(crmAddSellOfferProvider).parkingSpaceController,
              ),
              AdditionalInfoFilterButton(
                text: 'Garage'.tr,
                controller: ref.watch(crmAddSellOfferProvider).garageController,
              ),
              AdditionalInfoFilterButton(
                text: 'Elevator'.tr,
                controller:
                    ref.watch(crmAddSellOfferProvider).elevatorController,
              ),
              AdditionalInfoFilterButton(
                text: 'Garden'.tr,
                controller: ref.watch(crmAddSellOfferProvider).gardenController,
              ),
              AdditionalInfoFilterButton(
                text: 'Air Conditioning'.tr,
                controller: ref
                    .watch(crmAddSellOfferProvider)
                    .airConditioningController,
              ),
            ],
          ),
        ],
      ),
      // SizedBox(height: dynamiBoxHeigth),
      // SizedBox(height: dynamiBoxHeigth),
      // SizedBox(height: dynamiBoxHeigth),
      // Container(
      //   decoration: BoxDecoration(
      //     gradient: const LinearGradient(colors: [
      //       AppColors.buttonGradient1,
      //       AppColors.buttonGradient2
      //     ]),
      //     borderRadius: BorderRadius.circular(10.0),
      //   ),
      //   child: Material(
      //     color: Colors.transparent,
      //     child: InkWell(
      //       borderRadius: BorderRadius.circular(10.0),
      //       onTap: () {
      //         ref
      //             .read(crmAddSellOfferProvider.notifier)
      //             .sendData(context);
      //       },
      //       child: Padding(
      //         padding: const EdgeInsets.all(10.0),
      //         child: Center(
      //           child: Text('Wystaw ogłoszenie'.tr,
      //               style: AppTextStyles.interMedium
      //                   .copyWith(fontSize: 16)),
      //         ),
      //       ),
      //     ),
      //   ),
      // ),
      // SizedBox(height: dynamicSpacer),

      // ),
      // ),
    );
  }
}
