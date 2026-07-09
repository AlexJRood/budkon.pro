import 'dart:ui' as ui;

import 'package:core/ui/device_type_util.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:portal/screens/filter_landing_page/enum/tag_input_cache_extension.dart';
import 'package:portal/screens/filters/widgets/components/accept_row.dart';
import 'package:portal/screens/filters/widgets/tag_input_widget.dart';
import 'package:core/common/autocompletion/autocomplete.dart';
import 'package:core/common/autocompletion/provider/autocompletion_provider.dart';
import 'package:core/common/install_popup.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';

import 'package:portal/screens/filter_landing_page/components/filters_components.dart';
import 'package:portal/screens/filter_landing_page/providers/filter_provider.dart';
import 'package:core/platform/filters/filters_const.dart';

class FiltersPagePopMobile extends ConsumerStatefulWidget {
  final String tag;
  final bool isNeedToNavigate;
  final ScrollController? scrollController;

  const FiltersPagePopMobile({
    super.key,
    this.scrollController,
    required this.tag,
    this.isNeedToNavigate = false,
  });

  @override
  FiltersPagePopMobileState createState() => FiltersPagePopMobileState();
}

class FiltersPagePopMobileState extends ConsumerState<FiltersPagePopMobile> {
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

  late ScrollController scrollController;
  late final FocusNode areaFromFocusNode;
  late final FocusNode areaToFocusNode;
  late final FocusNode priceFromFocusNode;
  late final FocusNode priceToFocusNode;
  late final FocusNode pricePerMeterFromFocusNode;
  late final FocusNode pricePerMeterToFocusNode;
  late final FocusNode buildYearFromFocusNode;
  late final FocusNode buildYearToFocusNode;

  @override
  void initState() {
    super.initState();

    final filterNotifier = ref.read(filterCacheProvider.notifier);

    // ✅ Seed multi-select estate_type (tak jak na PC)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final cache = ref.read(filterCacheProvider.notifier);
        final raw = cache.filters[FilterPopConst.estateType];

        final selected = FilterPopConst.parseCsv(raw);
        final ui = ref.read(filterButtonProvider.notifier);

        if (selected.isNotEmpty) {
          ui.updateFilter(FilterPopConst.estateType, selected);
          cache.addFilter(FilterPopConst.estateType, selected.join(','));
        } else {
          ui.updateFilter(FilterPopConst.estateType, <String>[]);
          cache.removeFilter(FilterPopConst.estateType);
        }
      } catch (e) {
        if (kDebugMode) {
          // ignore: avoid_print
          debugPrint('estate_type seed error (mobile): $e');
        }
      }
    });

    // controllers
    searchController = TextEditingController(text: filterNotifier.searchQuery);
    searchRadiusController = TextEditingController(text: filterNotifier.searchQuery);
    excludeController = TextEditingController(text: filterNotifier.excludeQuery);

    minPriceController = TextEditingController(
      text: filterNotifier.filters[FilterPopConst.minPrice]?.toString(),
    );
    maxPriceController = TextEditingController(
      text: filterNotifier.filters[FilterPopConst.maxPrice]?.toString(),
    );

    minPricePerMeterController = TextEditingController(
      text: filterNotifier.filters[FilterPopConst.minPricePerMeter]?.toString(),
    );
    maxPricePerMeterController = TextEditingController(
      text: filterNotifier.filters[FilterPopConst.maxPricePerMeter]?.toString(),
    );

    minRoomsController = TextEditingController(
      text: filterNotifier.filters[FilterPopConst.minRooms]?.toString(),
    );
    maxRoomsController = TextEditingController(
      text: filterNotifier.filters[FilterPopConst.maxRooms]?.toString(),
    );

    minBathroomsController = TextEditingController(
      text: filterNotifier.filters[FilterPopConst.minBathrooms]?.toString(),
    );
    maxBathroomsController = TextEditingController(
      text: filterNotifier.filters[FilterPopConst.maxBathrooms]?.toString(),
    );

    minSquareFootageController = TextEditingController(
      text: filterNotifier.filters[FilterPopConst.minSquareFootage]?.toString(),
    );
    maxSquareFootageController = TextEditingController(
      text: filterNotifier.filters[FilterPopConst.maxSquareFootage]?.toString(),
    );

    minLotSizeController = TextEditingController(
      text: filterNotifier.filters[FilterPopConst.minLotSize]?.toString(),
    );
    maxLotSizeController = TextEditingController(
      text: filterNotifier.filters[FilterPopConst.maxLotSize]?.toString(),
    );

    titleController = TextEditingController(
      text: filterNotifier.filters[FilterPopConst.title],
    );
    descriptionController = TextEditingController(
      text: filterNotifier.filters[FilterPopConst.description],
    );
    currencyController = TextEditingController(
      text: filterNotifier.filters[FilterPopConst.currency],
    );

    estateTypeController = TextEditingController(
      text: filterNotifier.filters[FilterPopConst.estateType],
    );
    buildingTypeController = TextEditingController(
      text: filterNotifier.filters[FilterPopConst.buildingType],
    );

    streetController = TextEditingController(
      text: filterNotifier.filters[FilterPopConst.street],
    );
    cityController = TextEditingController(
      text: filterNotifier.filters[FilterPopConst.city],
    );
    stateController = TextEditingController(
      text: filterNotifier.filters[FilterPopConst.state],
    );
    zipcodeController = TextEditingController(
      text: filterNotifier.filters[FilterPopConst.zipcode],
    );

    propertyFormController = TextEditingController(
      text: filterNotifier.filters[FilterPopConst.propertyForm],
    );
    marketTypeController = TextEditingController(
      text: filterNotifier.filters[FilterPopConst.marketType],
    );
    offerTypeController = TextEditingController(
      text: filterNotifier.filters[FilterPopConst.offerType],
    );
    countryController = TextEditingController(
      text: filterNotifier.filters[FilterPopConst.country],
    );

    scrollController = ScrollController();
    areaFromFocusNode = FocusNode();
    areaToFocusNode = FocusNode();
    priceFromFocusNode = FocusNode();
    priceToFocusNode = FocusNode();
    pricePerMeterFromFocusNode = FocusNode();
    pricePerMeterToFocusNode = FocusNode();
    buildYearFromFocusNode = FocusNode();
    buildYearToFocusNode = FocusNode();
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

    scrollController.dispose();
    areaFromFocusNode.dispose();
    areaToFocusNode.dispose();
    priceFromFocusNode.dispose();
    priceToFocusNode.dispose();
    pricePerMeterFromFocusNode.dispose();
    pricePerMeterToFocusNode.dispose();
    buildYearFromFocusNode.dispose();
    buildYearToFocusNode.dispose();
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
    final model = ref.watch(myTextFieldViewModelProvider('portal').notifier);
    final theme = ref.watch(themeColorsProvider);

    final double dynamicBoxHeight = 25;
    final double dynamicBoxHeightGroup = 10;
    final double dynamicBoxHeightGroupSmall = 8;
    final double dynamiSpacerBoxWidth = 15;

    // ✅ SINGLE SOURCE OF TRUTH - dropdown current values
    final selectedBuildingType =
        ref.watch(filterButtonProvider)[FilterPopConst.buildingType] as String?;
    final selectedHeatingType =
        ref.watch(filterButtonProvider)[FilterPopConst.heatingType] as String?;
    final selectedAktualnosc =
        ref.watch(filterButtonProvider)[FilterPopConst.aktualnoscOferty] as String?;
    final selectedMaterial =
        ref.watch(filterButtonProvider)[FilterPopConst.buildingMaterial] as String?;
    final selectedAdvertiser =
        ref.watch(filterButtonProvider)[FilterPopConst.advertiserType] as String?;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) return;
        final cache = ref.read(filterCacheProvider.notifier);
        ref.read(filterProvider.notifier).applyFiltersFromCache(cache, ref);
      },
      child: PopupListener(
      child: SafeArea(
        top: false,
        bottom: false,
        child: Container(
           decoration: BoxDecoration(
           color: theme.dashboardContainer, 
           borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: theme.textColor,
                    ),
                    height: 5,
                    width: 200,
                  ),
                  Expanded(
                    child: ScrollbarTheme(
                      data: ScrollbarThemeData(
                        thumbColor: WidgetStateProperty.all(
                          theme.textFieldColor.withAlpha((255 * 0.5).toInt()),
                        ),
                        thickness: WidgetStateProperty.all(6.0),
                        radius: const Radius.circular(10.0),
                      ),
                      child: Scrollbar(
                        controller: widget.scrollController ?? scrollController,
                        thumbVisibility: true,
                        child: ListView(
                          controller: widget.scrollController ?? scrollController,
                          physics: const ClampingScrollPhysics(),
                          padding: EdgeInsets.only(
                            left: 12.0,
                            right: 12.0,
                            top: 16.0,
                            bottom: MediaQuery.of(context).viewInsets.bottom +
                                BottomBarSize.resolve(context) +
                                160,
                          ),
                          children: [
                            // =========================
                            // OFFER TYPE
                            // =========================
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
                                        'Typ oferty'.tr,
                                        style: AppTextStyles.interSemiBold16.copyWith(
                                          color: theme.textColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                FilterButton(
                                  text: 'offer_type_sell'.tr,
                                  filterValue: 'sell',
                                  filterKey: FilterPopConst.offerType,
                                ),
                                FilterButton(
                                  text: 'offer_type_rent'.tr,
                                  filterValue: 'rent',
                                  filterKey: FilterPopConst.offerType,
                                ),
                              ],
                            ),
        
                            SizedBox(height: dynamicBoxHeight),
        
                            // =========================
                            // LOCATION
                            // =========================
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Material(
                                  color: Colors.transparent,
                                  child: Text(
                                    'location'.tr,
                                    style: AppTextStyles.interSemiBold16.copyWith(
                                      color: theme.textColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: dynamicBoxHeightGroupSmall),
        
                            // ✅ ten widget zostaje, bo logikę “działania jak na PC”
                            // najlepiej trzymać w samym AutoCompleteWidget/providerze.
        
                            
        AutoCompleteWidget(
            onCleared: (ref) => ref.read(filterProvider.notifier).applyFiltersFromCache(ref.read(filterCacheProvider.notifier), ref),
          provider: 'portal',
          onLocationChanged: (ref, sel) {
            final cache = ref.read(filterCacheProvider.notifier);
        
            if (sel.isEmpty) {
              cache.removeFilter(FilterPopConst.city);
              cache.removeFilter(FilterPopConst.voivodeship); // jeśli masz
              cache.removeFilter(FilterPopConst.district);     // jeśli dodasz
              return;
            }
        
            // City (locality/city name)
            cache.addFilter(FilterPopConst.city, sel.city);
        
            // Voivodeship
            cache.addFilter(FilterPopConst.voivodeship, sel.state);
        
            // Optional: district filter (recommended)
            if (sel.districts.isNotEmpty) {
              cache.addFilter(FilterPopConst.district, sel.districts.first);
            } else {
              cache.removeFilter(FilterPopConst.district);
            }
          },
        ),
        
        
        
                            SizedBox(height: dynamicBoxHeight),
        
                            // =========================
                            // ESTATE TYPE (multi-select)
                            // =========================
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Material(
                                      color: Colors.transparent,
                                      child: Text(
                                        'property_type'.tr,
                                        style: AppTextStyles.interSemiBold16.copyWith(
                                          color: theme.textColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: dynamicBoxHeightGroupSmall),
        
                                // 2 rzędy jak wcześniej, ale z danych z FilterPopConst
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          for (final opt in FilterPopConst.estateTypes.take(4))
                                            Padding(
                                              padding: const EdgeInsets.only(right: 5),
                                              child: EstateTypeFilterButton(
                                                text: (opt['text'] ?? '').tr,
                                                filterValue: opt['filterValue'] ?? '',
                                                filterKey: FilterPopConst.estateType,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      Row(
                                        children: [
                                          for (final opt in FilterPopConst.estateTypes.skip(4))
                                            Padding(
                                              padding: const EdgeInsets.only(right: 5),
                                              child: EstateTypeFilterButton(
                                                text: (opt['text'] ?? '').tr,
                                                filterValue: opt['filterValue'] ?? '',
                                                filterKey: FilterPopConst.estateType,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
        
                            SizedBox(height: dynamicBoxHeight),
        
                            // =========================
                            // FILTERS
                            // =========================
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Material(
                                  color: Colors.transparent,
                                  child: Text(
                                    'filters'.tr,
                                    style: AppTextStyles.interSemiBold16.copyWith(
                                      color: theme.textColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: dynamicBoxHeightGroupSmall),
        
                            IntrinsicHeight(
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: BuildNumberField(
                                          controller: minSquareFootageController,
                                          labelText: 'Area from'.tr,
                                          filterKey: FilterPopConst.minSquareFootage,
                                          focusNode: areaFromFocusNode,
                                          nextFocusNode: areaToFocusNode,
                                        ),
                                      ),
                                      SizedBox(width: dynamiSpacerBoxWidth),
                                      Expanded(
                                        child: BuildNumberField(
                                          controller: maxSquareFootageController,
                                          labelText: 'Area to'.tr,
                                          filterKey: FilterPopConst.maxSquareFootage,
                                          focusNode: areaToFocusNode,
                                          nextFocusNode: priceFromFocusNode,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: dynamicBoxHeightGroup),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: BuildNumberField(
                                          controller: minPriceController,
                                          labelText: 'price_from'.tr,
                                          filterKey: FilterPopConst.minPrice,
                                          focusNode: priceFromFocusNode,
                                          nextFocusNode: priceToFocusNode,
                                        ),
                                      ),
                                      SizedBox(width: dynamiSpacerBoxWidth),
                                      Expanded(
                                        child: BuildNumberField(
                                          controller: maxPriceController,
                                          labelText: 'price_to'.tr,
                                          filterKey: FilterPopConst.maxPrice,
                                          focusNode: priceToFocusNode,
                                          nextFocusNode: pricePerMeterFromFocusNode,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: dynamicBoxHeightGroup),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: BuildNumberField(
                                          controller: minPricePerMeterController,
                                          labelText: 'Price per meter from'.tr,
                                          filterKey: FilterPopConst.minPricePerMeter,
                                          focusNode: pricePerMeterFromFocusNode,
                                          nextFocusNode: pricePerMeterToFocusNode,
                                        ),
                                      ),
                                      SizedBox(width: dynamiSpacerBoxWidth),
                                      Expanded(
                                        child: BuildNumberField(
                                          controller: maxPricePerMeterController,
                                          labelText: 'Price per meter to'.tr,
                                          filterKey: FilterPopConst.maxPricePerMeter,
                                          focusNode: pricePerMeterToFocusNode,
                                          nextFocusNode: buildYearFromFocusNode,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: dynamicBoxHeightGroup),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: BuildNumberField(
                                          controller: minRoomsController,
                                          labelText: 'Year of build from'.tr,
                                          filterKey: FilterPopConst.minBuildYear,
                                          focusNode: buildYearFromFocusNode,
                                          nextFocusNode: buildYearToFocusNode,
                                        ),
                                      ),
                                      SizedBox(width: dynamiSpacerBoxWidth),
                                      Expanded(
                                        child: BuildNumberField(
                                          controller: maxRoomsController,
                                          labelText: 'Year of build to'.tr,
                                          filterKey: FilterPopConst.maxBuildYear,
                                          focusNode: buildYearToFocusNode,
                                          isLast: true,
        
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: dynamicBoxHeight),
        
                                  // rooms
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Material(
                                            color: Colors.transparent,
                                            child: Text(
                                              'Number of Rooms'.tr,
                                              style: AppTextStyles.interMedium.copyWith(
                                                color: theme.textColor,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: dynamicBoxHeightGroupSmall),
                                      const SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          children: [
                                            FilterButton(text: '1', filterValue: '1', filterKey: FilterPopConst.rooms),
                                            SizedBox(width: 5),
                                            FilterButton(text: '2', filterValue: '2', filterKey: FilterPopConst.rooms),
                                            SizedBox(width: 5),
                                            FilterButton(text: '3', filterValue: '3', filterKey: FilterPopConst.rooms),
                                            SizedBox(width: 5),
                                            FilterButton(text: '4', filterValue: '4', filterKey: FilterPopConst.rooms),
                                            SizedBox(width: 5),
                                            FilterButton(text: '5', filterValue: '5', filterKey: FilterPopConst.rooms),
                                            SizedBox(width: 5),
                                            FilterButton(text: '6', filterValue: '6', filterKey: FilterPopConst.rooms),
                                            SizedBox(width: 5),
                                            FilterButton(text: '7+', filterValue: '7+', filterKey: FilterPopConst.rooms),
                                            SizedBox(width: 5),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
        
                            SizedBox(height: dynamicBoxHeight),
        
                            // =========================
                            // ADDITIONAL FILTERS
                            // =========================
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  'additional_filters'.tr,
                                  style: AppTextStyles.interSemiBold.copyWith(
                                    color: theme.textColor,
                                    fontSize: 18,
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
                                        filterKey: FilterPopConst.marketType,
                                      ),
                                    ),
                                    SizedBox(width: dynamicBoxHeightGroup),
                                    Expanded(
                                      child: FilterButton(
                                        text: 'Secondary'.tr,
                                        filterValue: 'secondary',
                                        filterKey: FilterPopConst.marketType,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: dynamicBoxHeightGroup),
        
                                // ✅ Dropdowny jak na PC: options + stable value
                                BuildDropdownButtonFormField(
                                  currentValue: selectedBuildingType,
                                  options: FilterPopConst.dropdownOptionsFor(FilterPopConst.buildingType),
                                  labelText: FilterPopConst.dropdownLabels[FilterPopConst.buildingType] ??
                                      'filter_label_building_type'.tr,
                                  filterKey: FilterPopConst.buildingType,
                                ),
                                SizedBox(height: dynamicBoxHeightGroup),
        
                                BuildDropdownButtonFormField(
                                  currentValue: selectedHeatingType,
                                  options: FilterPopConst.dropdownOptionsFor(FilterPopConst.heatingType),
                                  labelText: FilterPopConst.dropdownLabels[FilterPopConst.heatingType] ??
                                      'filter_label_heating_type'.tr,
                                  filterKey: FilterPopConst.heatingType,
                                ),
                                SizedBox(height: dynamicBoxHeightGroup),
        
                                BuildDropdownButtonFormField(
                                  currentValue: selectedAktualnosc,
                                  options: FilterPopConst.dropdownOptionsFor(FilterPopConst.aktualnoscOferty),
                                  labelText: FilterPopConst.dropdownLabels[FilterPopConst.aktualnoscOferty] ??
                                      'filter_label_offer_freshness'.tr,
                                  filterKey: FilterPopConst.aktualnoscOferty,
                                ),
                                SizedBox(height: dynamicBoxHeightGroup),
        
                                BuildDropdownButtonFormField(
                                  currentValue: selectedMaterial,
                                  options: FilterPopConst.dropdownOptionsFor(FilterPopConst.buildingMaterial),
                                  labelText: FilterPopConst.dropdownLabels[FilterPopConst.buildingMaterial] ??
                                      'Building material'.tr,
                                  filterKey: FilterPopConst.buildingMaterial,
                                ),
                                SizedBox(height: dynamicBoxHeightGroup),
        
                                BuildDropdownButtonFormField(
                                  currentValue: selectedAdvertiser,
                                  options: FilterPopConst.dropdownOptionsFor(FilterPopConst.advertiserType),
                                  labelText: FilterPopConst.dropdownLabels[FilterPopConst.advertiserType] ??
                                      'Advertiser'.tr,
                                  filterKey: FilterPopConst.advertiserType,
                                ),
                                SizedBox(height: dynamicBoxHeightGroup),
                              ],
                            ),
        
                            SizedBox(height: dynamicBoxHeight),
        
                            // =========================
                            // ADDITIONAL INFO (bool)
                            // =========================
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Material(
                                      color: Colors.transparent,
                                      child: Text(
                                        'additional_info'.tr,
                                        style: AppTextStyles.interSemiBold16.copyWith(
                                          color: theme.textColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: dynamicBoxHeightGroup),
        
                                // jak chcesz “dwa rzędy” jak wcześniej:
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          for (final opt in FilterPopConst.additionalInfo.take(6))
                                            Padding(
                                              padding: const EdgeInsets.only(right: 5),
                                              child: AdditionalInfoFilterButton(
                                                text: (opt['text'] ?? '').tr,
                                                filterKey: opt['filterKey'] ?? '',
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          for (final opt in FilterPopConst.additionalInfo.skip(6))
                                            Padding(
                                              padding: const EdgeInsets.only(right: 5),
                                              child: AdditionalInfoFilterButton(
                                                text: (opt['text'] ?? '').tr,
                                                filterKey: opt['filterKey'] ?? '',
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: dynamicBoxHeightGroup),
                                 Column(
                                       children: [
                                                    TagInputWidget(
                                                      label: 'search_keywords'.tr,
                                                      hintText:
                                                          'keywords',
                                                      prefixIcon:
                                                          Icons.search,
                                                      providerId: 'search',
                                                      externalController:
                                                          searchController,
                                                      onItemsChanged:
                                                          (items) {
                                                        ref.syncTagInputToCache(
                                                          providerId:
                                                              'search',
                                                          cacheKey:
                                                              FilterPopConst
                                                                  .search,
                                                          cache: ref.read(
                                                            filterCacheProvider
                                                                .notifier,
                                                          ),
                                                          ref: ref,
                                                        );
                                                      },
                                                    ),
                                                    const SizedBox(
                                                      height: 10,
                                                    ),
                                                    TagInputWidget(
                                                      label: 'exclude'.tr,
                                                      hintText:
                                                          'words to skip',
                                                      prefixIcon:
                                                          Icons.block,
                                                      providerId: 'exclude',
                                                      externalController:
                                                          excludeController,
                                                      onItemsChanged:
                                                          (items) {
                                                        ref.syncTagInputToCache(
                                                          providerId:
                                                              'exclude',
                                                          cacheKey:
                                                              FilterPopConst
                                                                  .exclude,
                                                          cache: ref.read(
                                                            filterCacheProvider
                                                                .notifier,
                                                          ),
                                                          ref: ref,
                                                        );
                                                      },
                                                    ),
                                                    const SizedBox(
                                                      height: 4.0,
                                                    ),
                                                  ],
                                                ),
                              ],
                            ),
        
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
        
              // bottom buttons
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: AcceptRowButtonsFilters(
                  isNeedToNavigate: widget.isNeedToNavigate,
                  isMobile: true,
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
