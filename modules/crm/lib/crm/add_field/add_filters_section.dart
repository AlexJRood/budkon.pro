import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:core/theme/icons.dart';
import 'package:core/theme/design.dart';
import 'package:core/platform/navigation_history_provider.dart';
import 'package:portal/screens/filter_landing_page/providers/filter_provider.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:portal/screens/filter_landing_page/components/filters_components.dart';

import 'package:get/get_utils/get_utils.dart';

class AddCrmFilters extends ConsumerStatefulWidget {
  const AddCrmFilters({super.key});

  @override
  AddCrmFiltersState createState() => AddCrmFiltersState();
}

class AddCrmFiltersState extends ConsumerState<AddCrmFilters> {
  String selectedOfferType = '';

  late TextEditingController searchController;
  late TextEditingController searchRadiusController;
  late TextEditingController excludeController;
  late TextEditingController minPriceController;
  late TextEditingController maxPriceController;
  late TextEditingController minPricePerMeterController;
  late TextEditingController maxPricePerMeterController;
  late TextEditingController minRoomsController;
  late TextEditingController maxRoomsController;
  late TextEditingController minBathroomsController;
  late TextEditingController maxBathroomsController;
  late TextEditingController minSquareFootageController;
  late TextEditingController maxSquareFootageController;
  late TextEditingController minLotSizeController;
  late TextEditingController maxLotSizeController;
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late TextEditingController currencyController;
  late TextEditingController estateTypeController;
  late TextEditingController buildingTypeController;
  late TextEditingController countryController;
  late TextEditingController streetController;
  late TextEditingController cityController;
  late TextEditingController stateController;
  late TextEditingController zipcodeController;
  late TextEditingController propertyFormController;
  late TextEditingController marketTypeController;
  late TextEditingController offerTypeController;

  @override
  void initState() {
    super.initState();
    final filterNotifier = ref.read(filterCacheProvider.notifier);

    searchController = TextEditingController(text: filterNotifier.searchQuery);
    //  excludeController = TextEditingController(
    //   text: filterNotifier.excludeQuery,  
    // );
    searchRadiusController = TextEditingController(
      text: filterNotifier.searchQuery,
    );
    excludeController = TextEditingController(
      text: filterNotifier.excludeQuery,
    );
    minPriceController = TextEditingController(
      text: filterNotifier.filters['min_price']?.toString(),
    );
    maxPriceController = TextEditingController(
      text: filterNotifier.filters['max_price']?.toString(),
    );
    minPricePerMeterController = TextEditingController(
      text: filterNotifier.filters['min_price_per_meter']?.toString(),
    );
    maxPricePerMeterController = TextEditingController(
      text: filterNotifier.filters['max_price_per_meter']?.toString(),
    );
    minRoomsController = TextEditingController(
      text: filterNotifier.filters['min_rooms']?.toString(),
    );
    maxRoomsController = TextEditingController(
      text: filterNotifier.filters['max_rooms']?.toString(),
    );
    minBathroomsController = TextEditingController(
      text: filterNotifier.filters['min_bathrooms']?.toString(),
    );
    maxBathroomsController = TextEditingController(
      text: filterNotifier.filters['max_bathrooms']?.toString(),
    );
    minSquareFootageController = TextEditingController(
      text: filterNotifier.filters['min_square_footage']?.toString(),
    );
    maxSquareFootageController = TextEditingController(
      text: filterNotifier.filters['max_square_footage']?.toString(),
    );
    minLotSizeController = TextEditingController(
      text: filterNotifier.filters['min_lot_size']?.toString(),
    );
    maxLotSizeController = TextEditingController(
      text: filterNotifier.filters['max_lot_size']?.toString(),
    );
    titleController = TextEditingController(
      text: filterNotifier.filters['title'],
    );
    descriptionController = TextEditingController(
      text: filterNotifier.filters['description'],
    );
    currencyController = TextEditingController(
      text: filterNotifier.filters['currency'],
    );
    estateTypeController = TextEditingController(
      text: filterNotifier.filters['estate_type'],
    );
    buildingTypeController = TextEditingController(
      text: filterNotifier.filters['building_type'],
    );
    streetController = TextEditingController(
      text: filterNotifier.filters['street'],
    );
    cityController = TextEditingController(
      text: filterNotifier.filters['city'],
    );
    stateController = TextEditingController(
      text: filterNotifier.filters['state'],
    );
    zipcodeController = TextEditingController(
      text: filterNotifier.filters['zipcode'],
    );
    propertyFormController = TextEditingController(
      text: filterNotifier.filters['property_form'],
    );
    marketTypeController = TextEditingController(
      text: filterNotifier.filters['market_type'],
    );
    offerTypeController = TextEditingController(
      text: filterNotifier.filters['offer_type'],
    );
    countryController = TextEditingController(
      text: filterNotifier.filters['country'],
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    searchRadiusController.dispose();
    excludeController.dispose();
    minPriceController.dispose();
    maxPriceController.dispose();
    minPricePerMeterController.dispose();
    maxPricePerMeterController.dispose();
    minRoomsController.dispose();
    maxRoomsController.dispose();
    minBathroomsController.dispose();
    maxBathroomsController.dispose();
    minSquareFootageController.dispose();
    maxSquareFootageController.dispose();
    minLotSizeController.dispose();
    maxLotSizeController.dispose();
    titleController.dispose();
    descriptionController.dispose();
    currencyController.dispose();
    estateTypeController.dispose();
    buildingTypeController.dispose();
    streetController.dispose();
    cityController.dispose();
    stateController.dispose();
    zipcodeController.dispose();
    propertyFormController.dispose();
    marketTypeController.dispose();
    offerTypeController.dispose();
    countryController.dispose();
    super.dispose();
  }

  void setSelectedOfferType(String value) {
    setState(() {
      selectedOfferType = value;
      offerTypeController.text = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final String? currentCountry = ref.watch(
      filterButtonProvider.select((state) => state['country']),
    );

    double dynamicBoxHeight = 25;
    double dynamicBoxHeightGroup = 10;
    double dynamicBoxHeightGroupSmall = 8;
    double dynamiSpacerBoxWidth = 15;
    double dynamicSpace = 5;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Material(
                          borderRadius: BorderRadius.circular(30.0),
                          elevation: 2,
                          child: SizedBox(
                            height: 35.0,
                            child: TextField(
                              controller: searchController,
                              style: AppTextStyles.interRegular14.copyWith(
                                color: AppColors.dark,
                              ),
                              decoration: InputDecoration(
                                labelText: 'search_keywords'.tr,
                                labelStyle: AppTextStyles.interRegular14
                                    .copyWith(color: AppColors.dark),
                                prefixIcon: AppIcons.search(
                                  color: Colors.black,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                  borderSide: BorderSide.none,
                                ),
                                filled: false,
                                fillColor: Colors.white,
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                  borderSide: const BorderSide(
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              onChanged:
                                  (value) => ref
                                      .read(filterCacheProvider.notifier)
                                      .setSearchQuery(value),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: dynamiSpacerBoxWidth),
                      MaterialButton(
                        onPressed: () {},
                        child: const Row(
                          children: [
                            Text('', style: TextStyle(color: Colors.white)),
                            SizedBox(width: 10),
                            Icon(Icons.save, color: Colors.white),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: dynamiSpacerBoxWidth),
                  Wrap(
                    spacing: dynamicBoxHeightGroupSmall,
                    runSpacing: dynamicBoxHeightGroupSmall,
                    runAlignment: WrapAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: Text(
                              'offer_type'.tr,
                              style: AppTextStyles.interSemiBold16,
                            ),
                          ),
                        ],
                      ),
                      FilterButton(
                        text: 'offer_type_sell'.tr,
                        filterValue: 'sell',
                        filterKey: 'offer_type',
                      ),
                      FilterButton(
                        text: 'offer_type_rent'.tr,
                        filterValue: 'rent',
                        filterKey: 'offer_type',
                      ),
                    ],
                  ),
                  SizedBox(height: dynamicBoxHeight),
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: Text(
                              'Locations'.tr,
                              style: AppTextStyles.interSemiBold16,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: dynamicBoxHeightGroupSmall),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 200,
                            child: BuildDropdownButtonFormField(
                              currentValue: currentCountry,
                              items: [
                                'poland'.tr,
                                'germany'.tr,
                                'czech_republic'.tr,
                                'austria',
                                'lithuania'.tr,
                                'france'.tr,
                              ],
                              labelText: 'country'.tr,
                              filterKey: 'country',
                            ),
                          ),
                          SizedBox(width: dynamiSpacerBoxWidth),
                          Expanded(
                            child: BuildTextField(
                              controller: cityController,
                              labelText: 'city'.tr,
                              filterKey: 'city',
                            ),
                          ),
                          SizedBox(width: dynamiSpacerBoxWidth),
                          Expanded(
                            child: BuildTextField(
                              controller: stateController,
                              labelText: 'State'.tr,
                              filterKey: 'state',
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: dynamicBoxHeightGroupSmall),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Expanded(
                            child: BuildTextField(
                              controller: streetController,
                              labelText: 'street'.tr,
                              filterKey: 'street',
                            ),
                          ),
                          SizedBox(width: dynamiSpacerBoxWidth),
                          SizedBox(
                            width: 150,
                            child: BuildTextField(
                              controller: zipcodeController,
                              labelText: 'postal code'.tr,
                              filterKey: 'zip_code',
                            ),
                          ),
                          SizedBox(width: dynamiSpacerBoxWidth),
                          SizedBox(
                            width: 100,
                            child: BuildTextField(
                              controller: searchRadiusController,
                              labelText: '+ 0km',
                              filterKey: 'city',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: dynamicBoxHeight),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: Text(
                              'property_type'.tr,
                              style: AppTextStyles.interSemiBold16,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: dynamicBoxHeightGroupSmall),
                      Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        children: [
                          EstateTypeFilterButton(
                            text: 'apartment_option'.tr,
                            filterValue: 'Flat'.tr,
                            filterKey: 'estate_type',
                          ),
                          EstateTypeFilterButton(
                            text: 'studio_flat'.tr,
                            filterValue: 'Studio',
                            filterKey: 'estate_type',
                          ),
                          EstateTypeFilterButton(
                            text: 'apartment_buildings'.tr,
                            filterValue: 'Apartment'.tr,
                            filterKey: 'estate_type',
                          ),
                          EstateTypeFilterButton(
                            text: 'house_type_option'.tr,
                            filterValue: 'House'.tr,
                            filterKey: 'estate_type',
                          ),
                          EstateTypeFilterButton(
                            text: 'semi_detached_house'.tr,
                            filterValue: 'Twin house'.tr,
                            filterKey: 'estate_type',
                          ),
                          EstateTypeFilterButton(
                            text: 'townhouse_option'.tr,
                            filterValue: 'Row house'.tr,
                            filterKey: 'estate_type',
                          ),
                          EstateTypeFilterButton(
                            text: 'investments_option'.tr,
                            filterValue: 'Invest'.tr,
                            filterKey: 'estate_type',
                          ),
                          EstateTypeFilterButton(
                            text: 'plots_option'.tr,
                            filterValue: 'Lot'.tr,
                            filterKey: 'estate_type',
                          ),
                          EstateTypeFilterButton(
                            text: 'commercial_option'.tr,
                            filterValue: 'Commercial'.tr,
                            filterKey: 'estate_type',
                          ),
                          EstateTypeFilterButton(
                            text: 'warehouse_option'.tr,
                            filterValue: 'Warehouse'.tr,
                            filterKey: 'estate_type',
                          ),
                          EstateTypeFilterButton(
                            text: 'rooms_option'.tr,
                            filterValue: 'Room'.tr,
                            filterKey: 'estate_type',
                          ),
                          EstateTypeFilterButton(
                            text: 'garages_option'.tr,
                            filterValue: 'Garage'.tr,
                            filterKey: 'estate_type',
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: dynamicBoxHeight),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: Text(
                          'filters_label'.tr,
                          style: AppTextStyles.interSemiBold16,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: dynamicBoxHeightGroupSmall),
                  IntrinsicHeight(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Expanded(
                              child: BuildNumberField(
                                controller: minSquareFootageController,
                                labelText: 'Area from'.tr,
                                filterKey: 'min_square_footage',
                              ),
                            ),
                            SizedBox(width: dynamiSpacerBoxWidth),
                            Expanded(
                              child: BuildNumberField(
                                controller: maxSquareFootageController,
                                labelText: 'Area to'.tr,
                                filterKey: 'max_square_footage',
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: dynamicBoxHeightGroup),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Expanded(
                              child: BuildNumberField(
                                controller: minPriceController,
                                labelText: 'price_from'.tr,
                                filterKey: 'min_price',
                              ),
                            ),
                            SizedBox(width: dynamiSpacerBoxWidth),
                            Expanded(
                              child: BuildNumberField(
                                controller: maxPriceController,
                                labelText: 'price_to'.tr,
                                filterKey: 'max_price',
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: dynamicBoxHeightGroup),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Expanded(
                              child: BuildNumberField(
                                controller: minPricePerMeterController,
                                labelText: 'Price per meter from'.tr,
                                filterKey: 'min_price_per_meter',
                              ),
                            ),
                            SizedBox(width: dynamiSpacerBoxWidth),
                            Expanded(
                              child: BuildNumberField(
                                controller: maxPricePerMeterController,
                                labelText: 'Price per meter to'.tr,
                                filterKey: 'max_price_per_meter',
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: dynamicBoxHeightGroup),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Expanded(
                              child: BuildNumberField(
                                controller: minRoomsController,
                                labelText: 'Year of build from'.tr,
                                filterKey: 'min_build_year',
                              ),
                            ),
                            SizedBox(width: dynamiSpacerBoxWidth),
                            Expanded(
                              child: BuildNumberField(
                                controller: maxRoomsController,
                                labelText: 'Year of build to'.tr,
                                filterKey: 'max_build_year',
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: dynamicBoxHeight),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Material(
                                  color: Colors.transparent,
                                  child: Text(
                                    'Room number'.tr,
                                    style: AppTextStyles.interMedium.copyWith(
                                      color: AppColors.light,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: dynamicBoxHeightGroupSmall),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const FilterButton(
                                    text: '1',
                                    filterValue: '1',
                                    filterKey: 'rooms',
                                  ),
                                  SizedBox(width: dynamicSpace),
                                  const FilterButton(
                                    text: '2',
                                    filterValue: '2',
                                    filterKey: 'rooms',
                                  ),
                                  SizedBox(width: dynamicSpace),
                                  const FilterButton(
                                    text: '3',
                                    filterValue: '3',
                                    filterKey: 'rooms',
                                  ),
                                  SizedBox(width: dynamicSpace),
                                  const FilterButton(
                                    text: '4',
                                    filterValue: '4',
                                    filterKey: 'rooms',
                                  ),
                                  SizedBox(width: dynamicSpace),
                                  const FilterButton(
                                    text: '5',
                                    filterValue: '5',
                                    filterKey: 'rooms',
                                  ),
                                  SizedBox(width: dynamicSpace),
                                  const FilterButton(
                                    text: '6',
                                    filterValue: '6',
                                    filterKey: 'rooms',
                                  ),
                                  SizedBox(width: dynamicSpace),
                                  const FilterButton(
                                    text: '7+',
                                    filterValue: '7+',
                                    filterKey: 'rooms',
                                  ),
                                  SizedBox(width: dynamicSpace),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: dynamicBoxHeightGroup),
                      ],
                    ),
                  ),
                  SizedBox(height: dynamicBoxHeight),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: Text(
                          'additional_filters'.tr,
                          style: AppTextStyles.interSemiBold.copyWith(
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: dynamicBoxHeightGroupSmall),
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: FilterButton(
                              text: 'Primary'.tr,
                              filterValue: 'primary',
                              filterKey: 'market_type',
                            ),
                          ),
                          SizedBox(width: dynamicBoxHeightGroup),
                          Expanded(
                            child: FilterButton(
                              text: 'Secondary'.tr,
                              filterValue: 'secondary',
                              filterKey: 'market_type',
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: dynamicBoxHeightGroup),
                      SizedBox(
                        child: BuildDropdownButtonFormField(
                          currentValue: currentCountry,
                          items: [
                            'building_type_option_block'.tr,
                            'building_type_option_apartment_building'.tr,
                            'building_type_option_tenement'.tr,
                            'building_type_option_highrise'.tr,
                            'building_type_option_loft'.tr,
                            'building_type_option_townhouse'.tr,
                            'building_type_option_infill'.tr,
                          ],
                          labelText: 'building_type'.tr,
                          filterKey: 'building_type',
                        ),
                      ),
                      SizedBox(height: dynamicBoxHeightGroup),
                      SizedBox(
                        child: BuildDropdownButtonFormField(
                          currentValue: currentCountry,
                          items: [
                            'heating_type_gas'.tr,
                            'heating_type_electric'.tr,
                            'heating_type_district'.tr,
                            'heating_type_heat_pump'.tr,
                            'heating_type_oil'.tr,
                            'heating_type_unknown'.tr,
                            'heating_type_all'.tr,
                          ],
                          labelText: 'heating_type'.tr,
                          filterKey: 'heating_type',
                        ),
                      ),
                      SizedBox(height: dynamicBoxHeightGroup),
                      SizedBox(
                        child: BuildDropdownButtonFormField(
                          currentValue: currentCountry,
                          items: [
                            'offer_freshness_option_any'.tr,
                            'offer_freshness_option_24h'.tr,
                            'offer_freshness_option_3d'.tr,
                            'offer_freshness_option_7d'.tr,
                            'offer_freshness_option_14d'.tr,
                            'offer_freshness_option_30d'.tr,
                          ],
                          labelText: 'filter_label_offer_freshness'.tr,
                          filterKey: 'aktualnosc_oferty',
                        ),
                      ),
                      SizedBox(height: dynamicBoxHeightGroup),
                      SizedBox(
                        child: BuildDropdownButtonFormField(
                          currentValue: currentCountry,
                          items: [
                            'building_type_option_any'.tr,
                            'building_material_option_brick'.tr,
                            'building_material_option_panel'.tr,
                            'building_material_option_wood'.tr,
                            'building_material_option_hollow_block'.tr,
                            'building_material_option_expanded_clay'.tr,
                            'building_material_option_concrete'.tr,
                            'building_material_option_silicate'.tr,
                            'building_material_option_aerated_concrete'.tr,
                            'building_material_option_reinforced_concrete'.tr,
                          ],
                          labelText:  'building_material_label'.tr,
                          filterKey: 'building_material',
                        ),
                      ),
                      SizedBox(height: dynamicBoxHeightGroup),
                      SizedBox(
                        child: BuildDropdownButtonFormField(
                          currentValue: currentCountry,
                          items: [
                            'advertiser_option_agent'.tr,
                             'advertiser_option_developer'.tr,
                            'advertiser_option_private'.tr,
                            'building_type_option_any'.tr,
                          ],
                          labelText: 'filter_label_advertiser'.tr,
                          filterKey: 'building_material',
                        ),
                      ),
                      SizedBox(height: dynamicBoxHeightGroup),
                    ],
                  ),
                  SizedBox(height: dynamicBoxHeight),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: Text(
                              'additional_info'.tr,
                              style: AppTextStyles.interSemiBold16,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: dynamicBoxHeightGroup),
                      Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        children: [
                          AdditionalInfoFilterButton(
                            text: 'Balcony'.tr,
                            filterKey: 'balcony',
                          ),
                          AdditionalInfoFilterButton(
                            text: 'Taras'.tr,
                            filterKey: 'terrace',
                          ),
                          AdditionalInfoFilterButton(
                            text: 'Basement'.tr,
                            filterKey: 'basement',
                          ),
                          AdditionalInfoFilterButton(
                            text: 'Elevator'.tr,
                            filterKey: 'elevator',
                          ),
                          AdditionalInfoFilterButton(
                            text: 'Garden'.tr,
                            filterKey: 'garden',
                          ),
                          AdditionalInfoFilterButton(
                            text: 'Garage'.tr,
                            filterKey: 'garage',
                          ),
                          AdditionalInfoFilterButton(
                            text: 'Air Conditioning'.tr,
                            filterKey: 'air_conditioning',
                          ),
                          AdditionalInfoFilterButton(
                            text: 'Parking space'.tr,
                            filterKey: 'parking_space',
                          ),
                          const AdditionalInfoFilterButton(
                            text: 'Jacuzzi',
                            filterKey: 'jacuzzi',
                          ),
                           AdditionalInfoFilterButton(
                            text: 'Sauna'.tr,
                            filterKey: 'sauna',
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: dynamicBoxHeight),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: () {
                  ref.read(filterCacheProvider.notifier).clearFilters();
                  ref.read(filterButtonProvider.notifier).clearUiFilters();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  'Clear filters'.tr,
                  style: AppTextStyles.interRegular14,
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  ref
                      .read(filterProvider.notifier)
                      .applyFiltersFromCache(
                        ref.read(filterCacheProvider.notifier),
                        ref,
                      );
                  final String lastPage =
                      ref.read(navigationHistoryProvider.notifier).lastPage;
                  if (ref.read(navigationService).canBeamBack()) {
                    ref.read(navigationService).beamPop();
                  } else {
                    ref
                        .read(navigationService)
                        .pushNamedReplacementScreen(lastPage);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.only(
                    left: 30,
                    right: 30,
                    top: 10,
                    bottom: 10,
                  ),
                  textStyle: AppTextStyles.interSemiBold14,
                ),
                child: Text('apply_filters'.tr),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
