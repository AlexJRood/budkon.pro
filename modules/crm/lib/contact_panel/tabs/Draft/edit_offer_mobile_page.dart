import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:core/theme/backgroundgradient.dart';
import 'package:core/theme/icons.dart';
import 'package:core/theme/design.dart';
import 'package:crm/data/add_field/edit_sell_offer_provider.dart';
import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/common/install_popup.dart';

import 'package:portal/screens/edit_offer/components/edit_fileds.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';

import 'package:get/get_utils/get_utils.dart';

// ignore: must_be_immutable
class CrmEditOfferMobilePage extends ConsumerWidget {
  double editOfferFontSize = 14;
  double dynamiBoxHeigth = 25;
  double dynamicSpacer = 15;
  final ScrollController scrollController = ScrollController();
  final int? offerId;

  CrmEditOfferMobilePage({super.key, required this.offerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ensure the provider is only watched once

    final editOfferState = ref.watch(crmEditSellOfferProvider(offerId));
    double screenWidth = MediaQuery.of(context).size.width;
    final sideMenuKey = GlobalKey<SideMenuState>();

    return PopupListener(
      child: BarManager(
        sideMenuKey: sideMenuKey,
        appModule: AppModule.agentCrm,
        isTopAppBarHoveroverUI: true,
        childMobile: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                      gradient: CustomBackgroundGradients.getMainMenuBackground(
                          context, ref)),
                  child: Column(
                    children: [
                      Expanded(
                        child: ScrollbarTheme(
                          data: ScrollbarThemeData(
                            thumbColor: WidgetStateProperty.all(
                              AppColors.light.withAlpha((255 * 0.35).toInt()),
                            ),
                            thickness: WidgetStateProperty.all(2),
                            radius: const Radius.circular(8.0),
                          ),
                          child: Scrollbar(
                            thumbVisibility: true,
                            thickness: 4,
                            controller: scrollController,    
                            radius: const Radius.circular(8.0),
                            child: ListView(
                              controller: scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              children: [
                                if (editOfferState.imagesData.isNotEmpty)
                                  Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Text(
                                      'your_main_photo'.tr,
                                      style: AppTextStyles.interMedium.copyWith(
                                        fontSize: 18,
                                        color: AppColors.light,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: editOfferState.imagesData.isNotEmpty
                                      ? GestureDetector(
                                          onTap: () {
                                            final indexToSet =
                                                editOfferState.mainImageIndex ??
                                                    0;
                                            ref
                                                .read(crmEditSellOfferProvider(offerId)
                                                    .notifier)
                                                .setMainImageIndex(indexToSet);
                                          },
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              Image.memory(
                                                editOfferState.imagesData[
                                                    editOfferState
                                                            .mainImageIndex ??
                                                        0],
                                                width: double.infinity,
                                                height:
                                                    screenWidth * (650 / 1200),
                                                fit: BoxFit.cover,
                                              ),
                                              if (editOfferState.mainImageIndex !=
                                                  null)
                                                const Positioned(
                                                  top: 0,
                                                  right: 0,
                                                  child: Icon(Icons.star,
                                                      color: AppColors.light),
                                                ),
                                            ],
                                          ),
                                        )
                                      : InkWell(
                                          onTap: () => ref
                                              .read(crmEditSellOfferProvider(offerId)
                                                  .notifier)
                                              .pickImage(),
                                          child: Container(
                                            height: screenWidth * (650 / 1200),
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              gradient: CustomBackgroundGradients
                                                  .adGradient1(context, ref),
                                              border: Border.all(
                                                  color: AppColors.light),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: const Center(
                                              child: Icon(
                                                Icons.camera_alt,
                                                color: AppColors.light,
                                                size: 48,
                                              ),
                                            ),
                                          ),
                                        ),
                                ),
                                const SizedBox(height: 7),
                                if (editOfferState.imagesData.isNotEmpty &&
                                    editOfferState.imagesData.length > 1)
                                  Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        Text(
                                          'remaining_photos'.tr,
                                          style:
                                              AppTextStyles.interMedium.copyWith(
                                            fontSize: 18,
                                            color: AppColors.light,
                                          ),
                                        ),
                                        Text(
                                          'select_main_photo_by_clicking_on_thumbnail'.tr,
                                          style:
                                              AppTextStyles.interMedium.copyWith(
                                            fontSize: 12,
                                            color: AppColors.light,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                GridView.builder(
                                  addAutomaticKeepAlives: false,
                                  addSemanticIndexes: false,
                                  cacheExtent: 160,
                                  physics: const NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 5,
                                    crossAxisSpacing: 7,
                                    mainAxisSpacing: 7,
                                  ),
                                  itemCount: editOfferState.imagesData.length + 1,
                                  itemBuilder: (context, index) {
                                    if (index ==
                                        editOfferState.imagesData.length) {
                                      return GestureDetector(
                                        onTap: () => ref
                                            .read(crmEditSellOfferProvider(offerId)
                                                .notifier)
                                            .pickImage(),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: AppColors.light),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Center(
                                            child: Icon(
                                              Icons.add,
                                              color: AppColors.light,
                                              size: 48,
                                            ),
                                          ),
                                        ),
                                      );
                                    }

                                    return GestureDetector(
                                      onTap: () {
                                        ref
                                            .read(crmEditSellOfferProvider(offerId)
                                                .notifier)
                                            .setMainImageIndex(index);
                                      },
                                      child: AspectRatio(
                                        aspectRatio: 1,
                                        child: Stack(
                                          alignment: Alignment.topRight,
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                image: DecorationImage(
                                                  image: MemoryImage(
                                                      editOfferState
                                                          .imagesData[index]),
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              top: 0,
                                              right: 0,
                                              child: IconButton(
                                                icon: AppIcons.delete(color: AppColors.light),
                                                onPressed: () {
                                                  if (editOfferState
                                                          .imagesData.length >
                                                      4) {
                                                    ref
                                                        .read(crmEditSellOfferProvider(
                                                                offerId)
                                                            .notifier)
                                                        .removeImage(index);
                                                  } else {
                                                    ScaffoldMessenger.of(context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                           'must_add_at_least_4_photos'
                                                                .tr),
                                                      ),
                                                    );
                                                  }
                                                },
                                              ),
                                            ),
                                            if (index ==
                                                editOfferState.mainImageIndex)
                                              const Positioned(
                                                top: 0,
                                                left: 0,
                                                child: Icon(Icons.star,
                                                    color: AppColors.light),
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                SizedBox(height: dynamiBoxHeigth),
                                SelectButtonsOptions(
                                  controller: ref
                                      .watch(crmEditSellOfferProvider(offerId))
                                      .offerTypeController,
                                  options: [
                                    ButtonOption('want_to_sell_option'.tr, 'sell'),
                                    ButtonOption('want_to_rent_option'.tr, 'rent'),
                                  ],
                                  labelText:
                                      'what_do_you_want_to_do_with_your_property'
                                          .tr,
                                ),
                                SizedBox(height: dynamiBoxHeigth),
                                SizedBox(height: dynamiBoxHeigth),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'property_address_question'
                                          .tr,
                                      style: AppTextStyles.interRegular.copyWith(
                                          fontSize: 14, color: AppColors.light),
                                    ),
                                    SizedBox(height: dynamicSpacer),
                                    Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: BuildDropdownButtonFormField(
                                            controller: ref
                                                .watch(crmEditSellOfferProvider(offerId))
                                                .countryController,
                                            items: [
                                              'poland'.tr,
                                              'country_2'.tr,
                                              'country_3'.tr
                                            ],
                                            labelText: 'country'.tr,
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
                                          child: BuildDropdownButtonFormField(
                                            controller: ref
                                                .watch(crmEditSellOfferProvider(offerId))
                                                .zipcodeController,
                                            items: const [
                                              '71204',
                                              '75488',
                                              '12345'
                                            ],
                                            labelText: 'zipcode'.tr,
                                          ),
                                        ),
                                        const Spacer(flex: 1),
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(height: dynamiBoxHeigth),
                                SelectButtonsOptions(
                                  controller: ref
                                      .watch(crmEditSellOfferProvider(offerId))
                                      .estateTypeController,
                                  options: [
                                    ButtonOption('apartment_type_option'.tr, 'Flat'.tr),
                                    ButtonOption('studio_type_option'.tr, 'Studio'.tr),
                                    ButtonOption('Apartament'.tr, 'apartment'.tr),
                                    ButtonOption('house_type_option'.tr, 'House'.tr),
                                    ButtonOption('semi_detached_type_option'.tr, 'Twin house'.tr),
                                    ButtonOption('townhouse_type_option'.tr, 'Row house'.tr),
                                    ButtonOption('investments_type_option'.tr, 'Invest'.tr),
                                    ButtonOption('plots_type_option'.tr, 'Lot'.tr),
                                    ButtonOption(
                                        'commercial_type_option'.tr, 'Commercial'.tr),
                                    ButtonOption(
                                        'warehouse_type_option'.tr, 'Warehouse'.tr),
                                    ButtonOption('rooms_type_option'.tr, 'Room'.tr),
                                    ButtonOption('garages_type_option'.tr, 'Garage'.tr),
                                  ],
                                  labelText: 'property_type'.tr,
                                ),
                                SizedBox(height: dynamiBoxHeigth),
                                SizedBox(height: dynamiBoxHeigth),
                                Text(
                                  'what_do_you_want_to_tell_others_about_your_property'
                                      .tr,
                                  style: AppTextStyles.interRegular.copyWith(
                                      fontSize: 14, color: AppColors.light),
                                ),
                                SizedBox(height: dynamiBoxHeigth),
                                BuildTextField(
                                  controller: ref
                                      .watch(crmEditSellOfferProvider(offerId))
                                      .titleController,
                                  labelText: 'ad_title'.tr,
                                  maxLines: 1,
                                ),
                                SizedBox(height: dynamicSpacer),
                                BuildTextFieldDes(
                                  controller: ref
                                      .watch(crmEditSellOfferProvider(offerId))
                                      .descriptionController,
                                  labelText: 'listing_description_label'.tr,
                                ),
                                SizedBox(height: dynamiBoxHeigth),
                                SizedBox(height: dynamiBoxHeigth),
                                Text(
                                  'what_is_the_price_of_your_property'.tr,
                                  style: AppTextStyles.interRegular.copyWith(
                                      fontSize: 14, color: AppColors.light),
                                ),
                                SizedBox(height: dynamiBoxHeigth),
                                Column(
                                  children: [
                                    BuildDropdownButtonFormField(
                                      controller: ref
                                          .watch(crmEditSellOfferProvider(offerId))
                                          .currencyController,
                                      items: const [
                                        'PLN',
                                        'EUR',
                                        'GBP',
                                        'USD',
                                        'CZK'
                                      ],
                                      labelText: 'Currency'.tr,
                                    ),
                                    SizedBox(height: dynamicSpacer),
                                    BuildNumberTextField(
                                      controller: ref
                                          .watch(crmEditSellOfferProvider(offerId))
                                          .priceController,
                                      labelText:
                                          'how_much_do_you_want_to_sell_your_property_for'.tr,
                                      unit: '',
                                    ),
                                  ],
                                ),
                                SizedBox(height: dynamiBoxHeigth),
                                SizedBox(height: dynamiBoxHeigth),
                                Text(
                                  'add_some_information_about_your_property'
                                      .tr,
                                  style: AppTextStyles.interRegular.copyWith(
                                      fontSize: 14, color: AppColors.light),
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
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Wrap(
                                                children: [
                                                  BuildSelectableButtonsFormField(
                                                    controller: ref
                                                        .watch(crmEditSellOfferProvider(
                                                            offerId))
                                                        .roomsController,
                                                    options: const [
                                                      '1',
                                                      '2',
                                                      '3',
                                                      '4',
                                                      '5',
                                                      '6',
                                                      '7+'
                                                    ],
                                                    labelText: 'Room number'.tr,
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: dynamicSpacer),
                                              Wrap(
                                                children: [
                                                  BuildSelectableButtonsFormField(
                                                    controller: ref
                                                        .watch(crmEditSellOfferProvider(
                                                            offerId))
                                                        .bathroomsController,
                                                    options: const [
                                                      '1',
                                                      '2',
                                                      '3',
                                                      '4',
                                                      '5',
                                                      '6',
                                                      '7+'
                                                    ],
                                                    labelText:
                                                        'Batroom number'.tr,
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: dynamicSpacer * 2),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(
                                                    flex: 2,
                                                    child: BuildNumberTextField(
                                                      controller: ref
                                                          .watch(
                                                              crmEditSellOfferProvider(
                                                                  offerId))
                                                          .floorController,
                                                      labelText: 'Floor'.tr,
                                                      unit: 'Piętro',
                                                    ),
                                                  ),
                                                  SizedBox(width: dynamicSpacer),
                                                  Expanded(
                                                    flex: 2,
                                                    child: BuildNumberTextField(
                                                      controller: ref
                                                          .watch(
                                                              crmEditSellOfferProvider(
                                                                  offerId))
                                                          .totalFloorsController,
                                                      labelText:
                                                          'Floor number'.tr,
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
                                                BuildDropdownButtonFormField(
                                                  controller: ref
                                                      .watch(crmEditSellOfferProvider(
                                                          offerId))
                                                      .buildingTypeController,
                                                  items: [
                                                    'building_type_option_block'.tr,
                                                    'building_type_option_apartment_building'.tr,
                                                    'building_type_option_townhouse'.tr,
                                                    'tenement_building_option'.tr,
                                                    'highrise_building_option'.tr,
                                                    'loft_building_option'.tr
                                                  ],
                                                  labelText: 'filter_label_building_type'.tr,
                                                ),
                                                SizedBox(height: dynamicSpacer),
                                                BuildDropdownButtonFormField(
                                                  controller: ref
                                                      .watch(crmEditSellOfferProvider(
                                                          offerId))
                                                      .heatingTypeController,
                                                  items: [
                                                    'heating_type_gas'.tr,
                                                    'heating_type_electric'.tr,
                                                    'heating_type_district'.tr,
                                                    'heating_type_heat_pump'.tr,
                                                    'heating_type_oil'.tr,
                                                    'all_types'.tr,
                                                    'heating_type_unknown'.tr
                                                  ],
                                                  labelText:
                                                      'heating_type'.tr,
                                                ),
                                                SizedBox(height: dynamicSpacer),
                                                BuildDropdownButtonFormField(
                                                  controller: ref
                                                      .watch(crmEditSellOfferProvider(
                                                          offerId))
                                                      .buildingMaterialController,
                                                  items: [
                                                    'brick'.tr,
                                                    'large_panel'.tr,
                                                    'silicate_material_option'.tr,
                                                    'concrete_material_option'.tr,
                                                    'aerated_concrete_material_option'.tr,
                                                    'hollow_block_material_option'.tr,
                                                    'reinforced_concrete_material_option'.tr,
                                                    'ceramsite_material_option'.tr,
                                                    'wood_material_option'.tr,
                                                    'other_material_option'.tr
                                                  ],
                                                  labelText:
                                                      'building_material_label'.tr,
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
                                  'property_information'.tr,
                                  style: AppTextStyles.interRegular.copyWith(
                                      fontSize: 14, color: AppColors.light),
                                ),
                                SizedBox(height: dynamicSpacer),
                                Column(
                                  children: [
                                    BuildNumberTextField(
                                      controller: ref
                                          .watch(crmEditSellOfferProvider(offerId))
                                          .buildYearController,
                                      labelText: 'build_year_label'.tr,
                                      unit: '',
                                    ),
                                    SizedBox(height: dynamicSpacer),
                                    BuildNumberTextField(
                                      controller: ref
                                          .watch(crmEditSellOfferProvider(offerId))
                                          .squareFootageController,
                                      labelText:
                                          'what_is_the_square_footage_of_your_property'
                                              .tr,
                                      unit: 'm²',
                                    ),
                                  ],
                                ),
                                SizedBox(height: dynamiBoxHeigth),
                                SizedBox(height: dynamiBoxHeigth),
                                Text(
                                  'additional_info'.tr,
                                  style: AppTextStyles.interRegular.copyWith(
                                      fontSize: 14, color: AppColors.light),
                                ),
                                SizedBox(height: dynamicSpacer),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          AdditionalInfoFilterButton(
                                            text: 'Balcony'.tr,
                                            controller: ref
                                                .watch(crmEditSellOfferProvider(offerId))
                                                .balconyController,
                                          ),
                                          const SizedBox(
                                            width: 5,
                                          ),
                                          AdditionalInfoFilterButton(
                                            text: 'Terrace'.tr,
                                            controller: ref
                                                .watch(crmEditSellOfferProvider(offerId))
                                                .terraceController,
                                          ),
                                          const SizedBox(
                                            width: 5,
                                          ),
                                          AdditionalInfoFilterButton(
                                            text: 'Sauna'.tr,
                                            controller: ref
                                                .watch(crmEditSellOfferProvider(offerId))
                                                .saunaController,
                                          ),
                                          const SizedBox(
                                            width: 5,
                                          ),
                                          AdditionalInfoFilterButton(
                                            text: 'Jacuzzi',
                                            controller: ref
                                                .watch(crmEditSellOfferProvider(offerId))
                                                .jacuzziController,
                                          ),
                                          const SizedBox(
                                            width: 5,
                                          ),
                                          AdditionalInfoFilterButton(
                                            text: 'basement'.tr,
                                            controller: ref
                                                .watch(crmEditSellOfferProvider(offerId))
                                                .basementController,
                                          ),
                                          const SizedBox(
                                            width: 5,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          AdditionalInfoFilterButton(
                                            text: 'Parking space'.tr,
                                            controller: ref
                                                .watch(crmEditSellOfferProvider(offerId))
                                                .parkingSpaceController,
                                          ),
                                          const SizedBox(
                                            width: 5,
                                          ),
                                          AdditionalInfoFilterButton(
                                            text: 'garage'.tr,
                                            controller: ref
                                                .watch(crmEditSellOfferProvider(offerId))
                                                .garageController,
                                          ),
                                          const SizedBox(
                                            width: 5,
                                          ),
                                          AdditionalInfoFilterButton(
                                            text: 'Elevator'.tr,
                                            controller: ref
                                                .watch(crmEditSellOfferProvider(offerId))
                                                .elevatorController,
                                          ),
                                          const SizedBox(
                                            width: 5,
                                          ),
                                          AdditionalInfoFilterButton(
                                            text: 'Garden'.tr,
                                            controller: ref
                                                .watch(crmEditSellOfferProvider(offerId))
                                                .gardenController,
                                          ),
                                          const SizedBox(
                                            width: 5,
                                          ),
                                          AdditionalInfoFilterButton(
                                            text: 'air_conditioning_label'.tr,
                                            controller: ref
                                                .watch(crmEditSellOfferProvider(offerId))
                                                .airConditioningController,
                                          ),
                                          const SizedBox(
                                            width: 5,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: dynamiBoxHeigth),
                                SizedBox(height: dynamiBoxHeigth),
                                SizedBox(height: dynamiBoxHeigth),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: CustomBackgroundGradients
                                        .getbuttonGradient1(context, ref),
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(10.0),
                                      onTap: () {
                                        ref
                                            .read(crmEditSellOfferProvider(offerId)
                                                .notifier)
                                            .sendData(context, offerId);
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(10.0),
                                        child: Center(
                                          child: Text('update_ad'.tr,
                                              style: AppTextStyles.interMedium
                                                  .copyWith(fontSize: 16)),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: dynamicSpacer),
                                const SizedBox(height: 55),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (editOfferState.isLoading)
                  Container(
                    color: Colors.black.withAlpha((255 * 0.5).toInt()),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: Theme.of(context)
                                .iconTheme
                                .color, // Ustawienie koloru paska ładowania na biały
                          ),
                          const SizedBox(height: 20),
                          AnimatedTextKit(
                            animatedTexts: editOfferState.statusMessages
                                .map((message) => TypewriterAnimatedText(
                                      message,
                                      textStyle: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                      speed: const Duration(milliseconds: 100),
                                    ))
                                .toList(),
                            isRepeatingAnimation: false,
                          ),
                        ],
                      ),
                    ),
                  ),
        ]
        ),
      ),
    );
  }
}
