import 'package:get/get_utils/get_utils.dart';

//Components/edit_offer.dart

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:core/theme/backgroundgradient.dart';
import 'package:core/theme/icons.dart';
import 'package:core/theme/design.dart';
import 'package:crm/data/add_field/edit_sell_offer_provider.dart';
import 'package:portal/screens/edit_offer/components/edit_fileds.dart';

// ignore: must_be_immutable
class CrmEditSellOfferPc extends ConsumerWidget {
  double editOfferFontSize = 14;
  double dynamiBoxHeigth = 15;
  final int? offerId;

  CrmEditSellOfferPc({super.key, required this.offerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editOfferState = ref.watch(crmEditSellOfferProvider(offerId));
    double screenWidth = MediaQuery.of(context).size.width;
    double textSideWidth = screenWidth / 2 - 100;
    double imageSideWidth = screenWidth / 2 - 85;

    double itemWidth = screenWidth / 1920 * 350;
    itemWidth = max(100.0, min(itemWidth, 300.0));

    double minBaseTextSize = 14;
    double maxBaseTextSize = 20;
    double baseTextSize =
        minBaseTextSize +
        (itemWidth - 150) / (240 - 150) * (maxBaseTextSize - minBaseTextSize);
    baseTextSize = max(minBaseTextSize, min(baseTextSize, maxBaseTextSize));

    return Expanded(
      child: Row(
        children: [
          SizedBox(
            width: textSideWidth,
            child: ScrollbarTheme(
              data: ScrollbarThemeData(
                thumbColor: WidgetStateProperty.all(
                  AppColors.light.withAlpha((255 * 0.35).toInt()),
                ),
                thickness: WidgetStateProperty.all(4),
                radius: const Radius.circular(8.0),
              ),
              child: Scrollbar(
                thumbVisibility: true,
                thickness: 4,
                radius: const Radius.circular(8.0),
                child: SingleChildScrollView(
                  primary: true,
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 25),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SelectButtonsOptions(
                          controller:
                              ref
                                  .watch(crmEditSellOfferProvider(offerId))
                                  .offerTypeController,
                          options: [
                            ButtonOption('want_to_sell_option'.tr, 'sell'),
                            ButtonOption('want_to_rent_option'.tr, 'rent'),
                          ],
                          labelText:
                              'what_do_you_want_to_do_with_property'.tr,
                        ),
                        SizedBox(height: dynamiBoxHeigth),
                        SizedBox(height: dynamiBoxHeigth),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                             'property_address_question'.tr,
                              style: AppTextStyles.interRegular.copyWith(
                                fontSize: 14,
                                color: AppColors.light,
                              ),
                            ),
                            SizedBox(height: dynamiBoxHeigth),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: safeDropdownField(
                                    controller:
                                        ref
                                            .watch(
                                              crmEditSellOfferProvider(offerId),
                                            )
                                            .countryController,
                                    items: [
                                      'poland_country'.tr,
                                      'country_2'.tr,
                                      'country_3'.tr,
                                    ],
                                    labelText: 'country_label'.tr,
                                  ),
                                ),
                                SizedBox(width: dynamiBoxHeigth),
                                Expanded(
                                  flex: 3,
                                  child: safeDropdownField(
                                    controller:
                                        ref
                                            .watch(
                                              crmEditSellOfferProvider(offerId),
                                            )
                                            .stateController,
                                    items: [
                                      'lower_silesia_voivodeship'.tr,
                                      'kuyavian_pomeranian_voivodeship'.tr,
                                      'lublin_voivodeship'.tr,
                                      'lubusz_voivodeship'.tr,
                                      'lodz_voivodeship'.tr,
                                      'lesser_poland_voivodeship'.tr,
                                      'masovian_voivodeship'.tr,
                                      'opole_voivodeship'.tr,
                                      'subcarpathian_voivodeship'.tr,
                                      'podlaskie_voivodeship'.tr,
                                      'pomeranian_voivodeship'.tr,
                                      'silesian_voivodeship'.tr,
                                      'swietokrzyskie_voivodeship'.tr,
                                      'warmian_masurian_voivodeship'.tr,
                                      'greater_poland_voivodeship'.tr,
                                      'west_pomeranian_voivodeship'.tr,
                                    ],
                                    labelText: 'voivodeship_label'.tr,
                                  ),
                                ),
                                SizedBox(width: dynamiBoxHeigth),
                                Expanded(
                                  flex: 3,
                                  child: safeDropdownField(
                                    controller:
                                        ref
                                            .read(
                                              crmEditSellOfferProvider(offerId),
                                            )
                                            .cityController,
                                    items: [
                                      'warsaw_city'.tr,
                                      'krakow_city'.tr,
                                      'wroclaw_city'.tr,
                                      'poznan_city'.tr,
                                      'gdansk_city'.tr,
                                      'szczecin_city'.tr,
                                      'bydgoszcz_city'.tr,
                                      'lublin_city'.tr,
                                      'katowice_city'.tr,
                                      'bialystok_city'.tr,
                                      'gdynia_city'.tr,
                                      'czestochowa_city'.tr,
                                      'radom_city'.tr,
                                      'sosnowiec_city'.tr,
                                      'torun_city'.tr,
                                      'kielce_city'.tr,
                                      'gliwice_city'.tr,
                                      'zabrze_city'.tr,
                                      'bytom_city'.tr,
                                      'olsztyn_city'.tr,
                                    ],
                                    labelText: 'city_label'.tr,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: dynamiBoxHeigth),
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: safeDropdownField(
                                    controller:
                                        ref
                                            .read(
                                              crmEditSellOfferProvider(offerId),
                                            )
                                            .streetController,
                                    items: [
                                         'marszalkowska_street'.tr,
                                         'krakowskie_przedmiescie_street'.tr,
                                         'piotrkowska_street'.tr,
                                         'slowackiego_street'.tr,
                                         'dluga_street'.tr,
                                         '3_maja_street'.tr,
                                         'solidarnosci_street'.tr,
                                         'grzybowska_street'.tr,
                                         'zeromskiego_street'.tr,
                                         'polna_street'.tr,
                                         'ogrodowa_street'.tr,
                                         'mickiewicza_street'.tr,
                                         'sienkiewicza_street'.tr,
                                         'wielkopolska_street'.tr,
                                         'gdanska_street'.tr,
                                         'kosciuszki_street'.tr,
                                         'zamkowa_street'.tr,
                                         'podwale_street'.tr,
                                         'reymonta_street'.tr,
                                         'kopernika_street'.tr,
                                         'jagiellonska_street'.tr,
                                         'lwowska_street'.tr,
                                         'brzozowa_street'.tr,
                                         'nadbrzezna_street'.tr,
                                         'parkowa_street'.tr,
                                         'rybacka_street'.tr,
                                         'sloneczna_street'.tr,
                                         'widok_street'.tr,
                                         'zielona_street'.tr,
                                         'klonowa_street'.tr,
                                         'akacjowa_street'.tr,
                                         'cicha_street'.tr,
                                         'wisniowa_street'.tr,
                                         'kwiatowa_street'.tr,
                                         'lakowa_street'.tr,
                                         'modrzewiowa_street'.tr,
                                         'nadwislanska_street'.tr,
                                         'opolska_street'.tr,
                                         'piaskowa_street'.tr,
                                         'rozana_street'.tr,
                                       ],
                                    labelText: 'address_label'.tr,
                                  ),
                                ),
                                SizedBox(width: dynamiBoxHeigth),
                                Expanded(
                                  flex: 2,
                                  child: safeDropdownField(
                                    controller:
                                        ref
                                            .watch(
                                              crmEditSellOfferProvider(offerId),
                                            )
                                            .zipcodeController,
                                    items: const ['71204', '75488', '12345'],
                                    labelText: 'zipcode_label'.tr,
                                  ),
                                ),
                                const Spacer(flex: 1),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: dynamiBoxHeigth),
                        SelectButtonsOptions(
                          controller:
                              ref
                                  .read(crmEditSellOfferProvider(offerId))
                                  .estateTypeController,
                          options: [
                           ButtonOption('apartment_option'.tr, 'Flat'.tr),
                           ButtonOption('penthouse_option'.tr, 'Apartment'.tr),
                           ButtonOption('studio_option'.tr, 'Studio'),
                           ButtonOption('house_option'.tr, 'House'.tr),
                           ButtonOption('semi_detached_option'.tr, 'Twin house'.tr),
                           ButtonOption('townhouse_option'.tr, 'Row house'.tr),
                           ButtonOption('investments_option'.tr, 'Invest'.tr),
                           ButtonOption('plots_option'.tr, 'Lot'.tr),
                           ButtonOption('commercial_option'.tr, 'Commercial'.tr),
                           ButtonOption('warehouse_option'.tr, 'Warehouse'.tr),
                           ButtonOption('rooms_option'.tr, 'Room'.tr),
                           ButtonOption('garages_option'.tr, 'Garage'.tr),
                          ],
                          labelText:'property_type_label'.tr,
                        ),
                        SizedBox(height: dynamiBoxHeigth),
                        SizedBox(height: dynamiBoxHeigth),
                        Text(
                          'what_do_you_want_to_tell_others'.tr,
                          style: AppTextStyles.interRegular.copyWith(
                            fontSize: 14,
                            color: AppColors.light,
                          ),
                        ),
                        SizedBox(height: dynamiBoxHeigth),
                        BuildTextField(
                          controller:
                              ref
                                  .read(crmEditSellOfferProvider(offerId))
                                  .titleController,
                          labelText: 'ad_title_label'.tr,
                          maxLines: 1,
                        ),
                        SizedBox(height: dynamiBoxHeigth),
                        BuildTextFieldDes(
                          controller:
                              ref
                                  .read(crmEditSellOfferProvider(offerId))
                                  .descriptionController,
                          labelText: 'ad_description_label'.tr,
                        ),
                        SizedBox(height: dynamiBoxHeigth),
                        SizedBox(height: dynamiBoxHeigth),
                        Text(
                          'what_is_property_price'.tr,
                          style: AppTextStyles.interRegular.copyWith(
                            fontSize: 14,
                            color: AppColors.light,
                          ),
                        ),
                        SizedBox(height: dynamiBoxHeigth),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: safeDropdownField(
                                controller:
                                    ref
                                        .watch(
                                          crmEditSellOfferProvider(offerId),
                                        )
                                        .currencyController,
                                items: const [
                                  'PLN',
                                  'EUR',
                                  'GBP',
                                  'USD',
                                  'CZK',
                                ],
                                labelText: 'currency_label'.tr,
                              ),
                            ),
                            SizedBox(width: dynamiBoxHeigth),
                            Expanded(
                              flex: 7,
                              child: BuildNumberTextField(
                                controller:
                                    ref
                                        .watch(
                                          crmEditSellOfferProvider(offerId),
                                        )
                                        .priceController,
                                labelText:
                                    'how_much_sell_property'.tr,
                                unit: '',
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: dynamiBoxHeigth),
                        SizedBox(height: dynamiBoxHeigth),
                        Text(
                          'add_property_information'.tr,
                          style: AppTextStyles.interRegular.copyWith(
                            fontSize: 14,
                            color: AppColors.light,
                          ),
                        ),
                        SizedBox(height: dynamiBoxHeigth / 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    children: [
                                      BuildSelectableButtonsFormField(
                                        controller:
                                            ref
                                                .watch(
                                                  crmEditSellOfferProvider(
                                                    offerId,
                                                  ),
                                                )
                                                .roomsController,
                                        options: const [
                                          '1',
                                          '2',
                                          '3',
                                          '4',
                                          '5',
                                          '6',
                                          '7+',
                                        ],
                                        labelText: 'room_number_label'.tr,
                                      ),
                                    ],
                                  ),
                                  Wrap(
                                    children: [
                                      BuildSelectableButtonsFormField(
                                        controller:
                                            ref
                                                .watch(
                                                  crmEditSellOfferProvider(
                                                    offerId,
                                                  ),
                                                )
                                                .bathroomsController,
                                        options: const [
                                          '1',
                                          '2',
                                          '3',
                                          '4',
                                          '5',
                                          '6',
                                          '7+',
                                        ],
                                        labelText: 'bathroom_number_label'.tr,
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: dynamiBoxHeigth * 1.5),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: BuildNumberTextField(
                                          controller:
                                              ref
                                                  .watch(
                                                    crmEditSellOfferProvider(
                                                      offerId,
                                                    ),
                                                  )
                                                  .floorController,
                                          labelText: 'floor_label'.tr,
                                          unit: 'Piętro',
                                        ),
                                      ),
                                      SizedBox(width: dynamiBoxHeigth),
                                      Expanded(
                                        flex: 2,
                                        child: BuildNumberTextField(
                                          controller:
                                              ref
                                                  .watch(
                                                    crmEditSellOfferProvider(
                                                      offerId,
                                                    ),
                                                  )
                                                  .totalFloorsController,
                                          labelText: 'number_of_floors_label'.tr,
                                          unit: 'Pięter',
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: dynamiBoxHeigth * 2),
                            Expanded(
                              flex: 2,
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: Column(
                                  children: [
                                    SizedBox(height: dynamiBoxHeigth),
                                    safeDropdownField(
                                      controller:
                                          ref
                                              .watch(
                                                crmEditSellOfferProvider(
                                                  offerId,
                                                ),
                                              )
                                              .buildingTypeController,
                                      items: [
                                        'block_building_option'.tr,
                                        'apartment_building_option'.tr,
                                        'townhouse_building_option'.tr,
                                        'tenement_building_option'.tr,
                                        'highrise_building_option'.tr,
                                        'loft_building_option'.tr,
                                      ],
                                      labelText: 'building_type_label'.tr,
                                    ),
                                    SizedBox(height: dynamiBoxHeigth),
                                    safeDropdownField(
                                      controller:
                                          ref
                                              .watch(
                                                crmEditSellOfferProvider(
                                                  offerId,
                                                ),
                                              )
                                              .heatingTypeController,
                                      items: [
                                        'gas_heating_option'.tr,
                                        'electric_heating_option'.tr,
                                        'district_heating_option'.tr,
                                        'heat_pump_heating_option'.tr,
                                        'oil_heating_option'.tr,
                                        'all_heating_option'.tr,
                                        'not_provided_heating_option'.tr,
                                      ],
                                      labelText: 'heating_type_label'.tr,
                                    ),
                                    SizedBox(height: dynamiBoxHeigth),
                                    safeDropdownField(
                                      controller:
                                          ref
                                              .watch(
                                                crmEditSellOfferProvider(
                                                  offerId,
                                                ),
                                              )
                                              .buildingMaterialController,
                                      items: [
                                        'brick_material_option'.tr,
                                        'large_panel_material_option'.tr,
                                        'silicate_material_option'.tr,
                                        'concrete_material_option'.tr,
                                        'aerated_concrete_material_option'.tr,
                                        'hollow_block_material_option'.tr,
                                        'reinforced_concrete_material_option'.tr,
                                        'ceramsite_material_option'.tr,
                                        'wood_material_option'.tr,
                                        'other_material_option'.tr,
                                      ],
                                      labelText:'building_material_label'.tr,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: dynamiBoxHeigth),
                        SizedBox(height: dynamiBoxHeigth),
                        Text(
                          'property_information_label'.tr,
                          style: AppTextStyles.interRegular.copyWith(
                            fontSize: 14,
                            color: AppColors.light,
                          ),
                        ),
                        SizedBox(height: dynamiBoxHeigth),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: BuildNumberTextField(
                                controller:
                                    ref
                                        .watch(
                                          crmEditSellOfferProvider(offerId),
                                        )
                                        .buildYearController,
                                labelText: 'build_year_label'.tr,
                                unit: '',
                              ),
                            ),
                            SizedBox(width: dynamiBoxHeigth),
                            Expanded(
                              flex: 5,
                              child: BuildNumberTextField(
                                controller:
                                    ref
                                        .watch(
                                          crmEditSellOfferProvider(offerId),
                                        )
                                        .squareFootageController,
                                labelText:
                                    'what_is_property_area'.tr,
                                unit: 'm²',
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: dynamiBoxHeigth),
                        SizedBox(height: dynamiBoxHeigth),
                        Text(
                          'additional_information_title'.tr,
                          style: AppTextStyles.interRegular.copyWith(
                            fontSize: 14,
                            color: AppColors.light,
                          ),
                        ),
                        SizedBox(height: dynamiBoxHeigth),
                        Wrap(
                          alignment: WrapAlignment.start,
                          spacing: dynamiBoxHeigth,
                          runSpacing: dynamiBoxHeigth,
                          children: [
                            AdditionalInfoFilterButton(
                              text: 'balcony_label'.tr,
                              controller:
                                  ref
                                      .watch(crmEditSellOfferProvider(offerId))
                                      .balconyController,
                            ),
                            AdditionalInfoFilterButton(
                              text: 'terrace_label'.tr,
                              controller:
                                  ref
                                      .watch(crmEditSellOfferProvider(offerId))
                                      .terraceController,
                            ),
                            AdditionalInfoFilterButton(
                              text: 'sauna_label'.tr,
                              controller:
                                  ref
                                      .watch(crmEditSellOfferProvider(offerId))
                                      .saunaController,
                            ),
                            AdditionalInfoFilterButton(
                              text: 'jacuzzi_label'.tr,
                              controller:
                                  ref
                                      .watch(crmEditSellOfferProvider(offerId))
                                      .jacuzziController,
                            ),
                            AdditionalInfoFilterButton(
                              text: 'basement_label'.tr,
                              controller:
                                  ref
                                      .watch(crmEditSellOfferProvider(offerId))
                                      .basementController,
                            ),
                            AdditionalInfoFilterButton(
                              text: 'elevator_label'.tr,
                              controller:
                                  ref
                                      .watch(crmEditSellOfferProvider(offerId))
                                      .elevatorController,
                            ),
                            AdditionalInfoFilterButton(
                              text: 'garden_label'.tr,
                              controller:
                                  ref
                                      .watch(crmEditSellOfferProvider(offerId))
                                      .gardenController,
                            ),
                            AdditionalInfoFilterButton(
                              text: 'air_conditioning_label'.tr,
                              controller:
                                  ref
                                      .watch(crmEditSellOfferProvider(offerId))
                                      .airConditioningController,
                            ),
                            AdditionalInfoFilterButton(
                              text: 'garage_label'.tr,
                              controller:
                                  ref
                                      .watch(crmEditSellOfferProvider(offerId))
                                      .garageController,
                            ),
                            AdditionalInfoFilterButton(
                              text: 'parking_space_label'.tr,
                              controller:
                                  ref
                                      .watch(crmEditSellOfferProvider(offerId))
                                      .parkingSpaceController,
                            ),
                          ],
                        ),
                        SizedBox(height: dynamiBoxHeigth),
                        SizedBox(height: dynamiBoxHeigth),
                        SizedBox(height: dynamiBoxHeigth),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: dynamiBoxHeigth * 2),
          SizedBox(
            width: imageSideWidth,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(height: dynamiBoxHeigth),
                        // Etykieta "Twoje główne zdjęcie".tr
                        if (editOfferState.imagesData.isNotEmpty)
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

                        SizedBox(height: dynamiBoxHeigth),
                        // Kontener dla głównego zdjęcia lub przycisku do wyboru zdjęć
                        SizedBox(
                          width: imageSideWidth,
                          height: imageSideWidth * (650 / 1200),
                          child:
                              editOfferState.imagesData.isNotEmpty
                                  ? GestureDetector(
                                    onTap: () {
                                      int indexToSet =
                                          editOfferState.mainImageIndex ?? 0;
                                      ref
                                          .read(
                                            crmEditSellOfferProvider(
                                              offerId,
                                            ).notifier,
                                          )
                                          .setMainImageIndex(indexToSet);
                                    },
                                    child: Stack(
                                      alignment: Alignment.topRight,
                                      children: [
                                        Image.memory(
                                          editOfferState
                                              .imagesData[editOfferState
                                                  .mainImageIndex ??
                                              0],
                                          width: imageSideWidth,
                                          height: imageSideWidth * (650 / 1200),
                                          fit: BoxFit.cover,
                                        ),
                                        if (editOfferState.mainImageIndex !=
                                            null)
                                          const Icon(
                                            Icons.star,
                                            color: AppColors.light,
                                          ),
                                      ],
                                    ),
                                  )
                                  : InkWell(
                                    onTap:
                                        () =>
                                            ref
                                                .read(
                                                  crmEditSellOfferProvider(
                                                    offerId,
                                                  ).notifier,
                                                )
                                                .pickImage(),
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        gradient:
                                            CustomBackgroundGradients.adGradient1(
                                              context,
                                              ref,
                                            ), // Tło kontenera
                                        border: Border.all(
                                          color: AppColors.light,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.camera_alt, // Ikona aparatu
                                          color: AppColors.light,
                                          size: 48,
                                        ),
                                      ),
                                    ),
                                  ),
                        ),

                        SizedBox(height: dynamiBoxHeigth),

                        // Etykieta "Pozostałe zdjęcia".tr
                        if (editOfferState.imagesData.isNotEmpty &&
                            editOfferState.imagesData.length > 1)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  'remaining_photos_label'.tr,
                                  style: AppTextStyles.interMedium.copyWith(
                                    fontSize: 18,
                                    color: AppColors.light,
                                  ),
                                ),
                                Text(
                                  'select_main_photo_by_clicking_thumbnail'.tr,
                                  style: AppTextStyles.interMedium.copyWith(
                                    fontSize: 12,
                                    color: AppColors.light,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        SizedBox(height: dynamiBoxHeigth / 2),
                        GridView.builder(
                          addAutomaticKeepAlives: false,
                          addSemanticIndexes: false,
                          cacheExtent: 160,
                          shrinkWrap: true,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 5,
                                crossAxisSpacing: 7,
                                mainAxisSpacing: 7,
                              ),
                          itemCount:
                              editOfferState.imagesData.length +
                              1, // Dodaj +1 do liczby elementów
                          itemBuilder: (context, index) {
                            // Sprawdzenie, czy bieżący indeks to ostatni kafelek
                            if (index == editOfferState.imagesData.length) {
                              // Renderowanie przycisku dodawania zdjęć
                              return InkWell(
                                onTap:
                                    () =>
                                        ref
                                            .read(
                                              crmEditSellOfferProvider(
                                                offerId,
                                              ).notifier,
                                            )
                                            .pickImage(),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.add, // Ikona plusa
                                    color: Colors.black,
                                    size: 24,
                                  ),
                                ),
                              );
                            } else {
                              // Renderowanie miniatury zdjęcia
                              return GestureDetector(
                                onTap: () {
                                  ref
                                      .read(
                                        crmEditSellOfferProvider(
                                          offerId,
                                        ).notifier,
                                      )
                                      .setMainImageIndex(index);
                                },
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: Stack(
                                    alignment: Alignment.topRight,
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          image: DecorationImage(
                                            image: MemoryImage(
                                              editOfferState.imagesData[index],
                                            ),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: AppIcons.delete(
                                          color: Colors.red,
                                        ),
                                        onPressed: () {
                                          if (editOfferState
                                              .imagesData
                                              .isNotEmpty) {
                                            ref
                                                .read(
                                                  crmEditSellOfferProvider(
                                                    offerId,
                                                  ).notifier,
                                                )
                                                .removeImage(index);
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'must_add_at_least_4_photos'.tr,
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: dynamiBoxHeigth),
                Row(
                  children: [
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        gradient: CustomBackgroundGradients.getbuttonGradient1(
                          context,
                          ref,
                        ),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10.0),
                          onTap: () {
                            ref
                                .read(
                                  crmEditSellOfferProvider(offerId).notifier,
                                )
                                .sendData(context, offerId);
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: baseTextSize * 1.5,
                              vertical: baseTextSize / 5,
                            ),
                            child: Text(
                              'post_ad_button'.tr,
                              style: AppTextStyles.interMedium.copyWith(
                                fontSize: baseTextSize,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: dynamiBoxHeigth),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget safeDropdownField({
    required TextEditingController controller,
    required List<String> items,
    required String labelText,
  }) {
    // Ensure valid value
    if (!items.contains(controller.text)) {
      controller.text = '';
    }

    return BuildDropdownButtonFormField(
      controller: controller,
      items: items,
      labelText: labelText,
    );
  }
}
