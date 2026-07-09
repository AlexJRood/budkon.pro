import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:core/shell/keyboard_shortcuts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:portal/screens/filter_landing_page/components/filters_components.dart';
import 'package:portal/screens/filter_landing_page/providers/filter_cntrl.dart';
import 'package:portal/screens/filter_landing_page/enum/tag_input_cache_extension.dart';
import 'package:portal/screens/filter_landing_page/providers/filter_provider.dart';
import 'package:portal/screens/filter_landing_page/providers/tag_input_provider.dart';
import 'package:portal/screens/filters/widgets/components/accept_row.dart';
import 'package:portal/screens/filters/widgets/filterslider.dart';
import 'package:portal/screens/filters/widgets/tag_input_widget.dart';
import 'package:core/platform/filters/filters_const.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/common/autocompletion/autocomplete.dart';
import 'package:core/common/autocompletion/provider/autocompletion_provider.dart';
import 'package:core/common/drad_scroll_widget.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:portal/emma/anchors/anchors_portal.dart';

class FiltersPagePopPc extends ConsumerStatefulWidget {
  final String tag;
  final bool isNeedToNavigate;

  const FiltersPagePopPc({
    super.key,
    required this.tag,
    this.isNeedToNavigate = false,
  });

  @override
  FiltersPagePopPcState createState() => FiltersPagePopPcState();
}

class FiltersPagePopPcState extends ConsumerState<FiltersPagePopPc>
    with AutomaticKeepAliveClientMixin {
  String selectedOfferType = '';

  late LandingFilterControllers controllers;
  late ScrollController scrollController;
  late FocusNode _focusNode;

  TextEditingController get searchController => controllers.searchController;
  TextEditingController get searchRadiusController =>
      controllers.searchRadiusController;
  TextEditingController get excludeController => controllers.excludeController;
  TextEditingController get minPriceController => controllers.minPriceController;
  TextEditingController get maxPriceController => controllers.maxPriceController;
  TextEditingController get minPricePerMeterController =>
      controllers.minPricePerMeterController;
  TextEditingController get maxPricePerMeterController =>
      controllers.maxPricePerMeterController;
  TextEditingController get minRoomsController => controllers.minRoomsController;
  TextEditingController get maxRoomsController => controllers.maxRoomsController;
  TextEditingController get minBathroomsController =>
      controllers.minBathroomsController;
  TextEditingController get maxBathroomsController =>
      controllers.maxBathroomsController;
  TextEditingController get minSquareFootageController =>
      controllers.minSquareFootageController;
  TextEditingController get maxSquareFootageController =>
      controllers.maxSquareFootageController;
  TextEditingController get minLotSizeController =>
      controllers.minLotSizeController;
  TextEditingController get maxLotSizeController =>
      controllers.maxLotSizeController;
  TextEditingController get titleController => controllers.titleController;
  TextEditingController get descriptionController =>
      controllers.descriptionController;
  TextEditingController get currencyController => controllers.currencyController;
  TextEditingController get estateTypeController =>
      controllers.estateTypeController;
  TextEditingController get buildingTypeController =>
      controllers.buildingTypeController;
  TextEditingController get countryController => controllers.countryController;
  TextEditingController get streetController => controllers.streetController;
  TextEditingController get cityController => controllers.cityController;
  TextEditingController get stateController => controllers.stateController;
  TextEditingController get zipcodeController => controllers.zipcodeController;
  TextEditingController get propertyFormController =>
      controllers.propertyFormController;
  TextEditingController get marketTypeController =>
      controllers.marketTypeController;
  TextEditingController get offerTypeController =>
      controllers.offerTypeController;
  TextEditingController get minBuildYearController =>
      controllers.minBuildYearController;

  TextEditingController get maxBuildYearController =>
      controllers.maxBuildYearController;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();

    final filterNotifier = ref.read(filterCacheProvider.notifier);
    controllers = LandingFilterControllers.fromCache(filterNotifier);
    selectedOfferType =
        filterNotifier.filters[FilterPopConst.offerType]?.toString() ?? '';

    scrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }

      try {
        final cache = ref.read(filterCacheProvider.notifier);
        final raw = cache.filters[FilterPopConst.estateType];
        final selected = FilterPopConst.parseCsv(raw);

        if (selected.isNotEmpty) {
          ref
              .read(filterButtonProvider.notifier)
              .updateFilter(FilterPopConst.estateType, selected);

          cache.addFilter(FilterPopConst.estateType, selected.join(','));
        } else {
          ref
              .read(filterButtonProvider.notifier)
              .updateFilter(FilterPopConst.estateType, <String>[]);
          cache.removeFilter(FilterPopConst.estateType);
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('estate_type seed error: $e');
        }
      }

      ref.initializeTagInputFromCache(
        providerId: 'search',
        cacheKey: FilterPopConst.search,
        cache: filterNotifier,
      );

      ref.initializeTagInputFromCache(
        providerId: 'exclude',
        cacheKey: FilterPopConst.exclude,
        cache: filterNotifier,
      );

      ref.read(tagInputProvider('search').notifier).clearText();
      ref.read(tagInputProvider('exclude').notifier).clearText();

      searchController.clear();
      excludeController.clear();
    });
  }

  @override
  void dispose() {
    controllers.dispose();
    scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void setSelectedOfferType(String value) {
    setState(() {
      selectedOfferType = value;
      offerTypeController.text = value;
    });
  }

  void clearAllFilters(WidgetRef ref) {
    controllers.clearAll();

    ref.read(filterCacheProvider.notifier).clearFilters(ref: ref);

    ref.read(tagInputProvider('search').notifier).clearAll();
    ref.read(tagInputProvider('exclude').notifier).clearAll();

    final ui = ref.read(filterButtonProvider.notifier);
    ui.clearUiFilters();

    for (final key in FilterPopConst.allFilterKeys) {
      ui.removeFilter(key);
    }

    ui.updateFilter(FilterPopConst.estateType, <String>[]);

    if (mounted) {
      setState(() {
        selectedOfferType = '';
      });
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final model = ref.watch(myTextFieldViewModelProvider('portal').notifier);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    const dynamicBoxHeight = 20.0;
    const dynamicBoxHeightGroup = 12.0;
    const dynamicBoxHeightGroupSmall = 10.0;
    const dynamiSpacerBoxWidth = 15.0;
    final double inputWidth = math.max(screenWidth * 0.25, 170);

    final theme = ref.watch(themeColorsProvider);

    final selectedBuildingType =
        ref.watch(filterButtonProvider)[FilterPopConst.buildingType] as String?;
    final selectedHeatingType =
        ref.watch(filterButtonProvider)[FilterPopConst.heatingType] as String?;
    final selectedAktualnosc = ref.watch(
      filterButtonProvider,
    )[FilterPopConst.aktualnoscOferty] as String?;
    final selectedMaterial =
        ref.watch(filterButtonProvider)[FilterPopConst.buildingMaterial]
            as String?;
    final selectedAdvertiser =
        ref.watch(filterButtonProvider)[FilterPopConst.advertiserType]
            as String?;

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: (KeyEvent event) {
        if (event.logicalKey == ref.read(popKeyProvider) &&
            event is KeyDownEvent) {
          if (Navigator.canPop(context)) {
            ref.read(navigationService).beamPop();
          }
        }
        KeyBoardShortcuts().handleKeyEvent(event, scrollController, 100, 100);
      },
      child: DragPoponlyWidget(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  color: theme.whitewhiteblack.withAlpha((255 * 0.05).toInt()),
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                  model.setLoading(false);
                },
              ),
              Center(
                child: Hero(
                  tag: widget.tag,
                  child: GestureDetector(
                    onTap: () => model.setLoading(false),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15.0),
                      child: SizedBox(
                        width: math.max(screenWidth * 0.6, 450),
                        height: math.max(screenHeight * 0.91, 400),
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                          child: ClipRRect(
                            child: Stack(
                              children: [
                                Container(
                                  color: theme.adPopBackground.withAlpha(
                                    (255 * 0.25).toInt(),
                                  ),
                                  padding: const EdgeInsets.only(
                                    top: dynamiSpacerBoxWidth + 70,
                                  ),
                                  child: Column(
                                    children: [
                                      SizedBox(height: dynamiSpacerBoxWidth),
                                      Expanded(
                                        child: Scrollbar(
                                          thumbVisibility: true,
                                          thickness: 6.0,
                                          controller: scrollController,
                                          radius: const Radius.circular(10.0),
                                          trackVisibility: true,
                                          interactive: true,
                                          child: SingleChildScrollView(
                                            controller: scrollController,
                                            child: Padding(
                                              padding: const EdgeInsets.all(15),
                                              child: Column(
                                                children: [
                                                  EmmaUiAnchorTarget(
                                                    anchorKey: PortalEmmaAnchors.filtersPcOfferType.anchorKey,

                                                    spec: PortalEmmaAnchors.filtersPcOfferType,
                                                    runtimeMode: PortalEmmaAnchors.filtersPcOfferType.runtimeMode,
                                                    tapMode: PortalEmmaAnchors.filtersPcOfferType.tapMode,
                                                    child: Wrap(
                                                    spacing:
                                                        dynamicBoxHeightGroupSmall,
                                                    runSpacing:
                                                        dynamicBoxHeightGroupSmall,
                                                    children: [
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .start,
                                                        children: [
                                                          Material(
                                                            color: Colors
                                                                .transparent,
                                                            child: Text(
                                                              'Typ oferty'.tr,
                                                              style: AppTextStyles
                                                                  .interSemiBold
                                                                  .copyWith(
                                                                fontSize: 18,
                                                                color: theme
                                                                    .textColor,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      FilterButton(
                                                        text: 'offer_type_sell'.tr,
                                                        filterValue: 'sell',
                                                        filterKey:
                                                            FilterPopConst
                                                                .offerType,
                                                      ),
                                                      FilterButton(
                                                        text: 'offer_type_rent'.tr,
                                                        filterValue: 'rent',
                                                        filterKey:
                                                            FilterPopConst
                                                                .offerType,
                                                      ),
                                                    ],
                                                  ),
                                                  ),
                                                  const SizedBox(
                                                    height: dynamicBoxHeight,
                                                  ),
                                                  Column(
                                                    children: [
                                                      EmmaUiAnchorTarget(
                                                        anchorKey: PortalEmmaAnchors.filtersPcLocation.anchorKey,

                                                        spec: PortalEmmaAnchors.filtersPcLocation,
                                                        runtimeMode: PortalEmmaAnchors.filtersPcLocation.runtimeMode,
                                                        tapMode: PortalEmmaAnchors.filtersPcLocation.tapMode,
                                                        child: AutoCompleteWidget(
            onCleared: (ref) => ref.read(filterProvider.notifier).applyFiltersFromCache(ref.read(filterCacheProvider.notifier), ref),
                                                        provider: 'portal',
                                                        onLocationChanged:
                                                            (ref, sel) {
                                                          final cache = ref.read(
                                                            filterCacheProvider
                                                                .notifier,
                                                          );

                                                          if (sel.isEmpty) {
                                                            cache.removeFilter(
                                                              'location_type',
                                                            );
                                                            cache.removeFilter(
                                                              'location_id',
                                                            );
                                                            cache.removeFilter(
                                                              FilterPopConst
                                                                  .city,
                                                            );
                                                            cache.removeFilter(
                                                              FilterPopConst
                                                                  .voivodeship,
                                                            );
                                                            cache.removeFilter(
                                                              FilterPopConst
                                                                  .district,
                                                            );
                                                            return;
                                                          }

                                                          cache.addFilter(
                                                            'location_type',
                                                            sel.type,
                                                          );
                                                          cache.addFilter(
                                                            'location_id',
                                                            sel.id,
                                                          );

                                                          if (sel.city
                                                              .trim()
                                                              .isNotEmpty) {
                                                            cache.addFilter(
                                                              FilterPopConst
                                                                  .city,
                                                              sel.city.trim(),
                                                            );
                                                          } else {
                                                            cache.removeFilter(
                                                              FilterPopConst
                                                                  .city,
                                                            );
                                                          }

                                                          if (sel.state
                                                              .trim()
                                                              .isNotEmpty) {
                                                            cache.addFilter(
                                                              FilterPopConst
                                                                  .voivodeship,
                                                              sel.state.trim(),
                                                            );
                                                          } else {
                                                            cache.removeFilter(
                                                              FilterPopConst
                                                                  .voivodeship,
                                                            );
                                                          }

                                                          if (sel.districts
                                                              .isNotEmpty) {
                                                            cache.addFilter(
                                                              FilterPopConst
                                                                  .district,
                                                              sel.districts.first
                                                                  .trim(),
                                                            );
                                                          } else {
                                                            cache.removeFilter(
                                                              FilterPopConst
                                                                  .district,
                                                            );
                                                          }
                                                        },
                                                      ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(
                                                    height: dynamicBoxHeight,
                                                  ),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    children: [
                                                      Material(
                                                        color:
                                                            Colors.transparent,
                                                        child: Text(
                                                          'Estate type'.tr,
                                                          style: AppTextStyles
                                                              .interSemiBold
                                                              .copyWith(
                                                            fontSize: 18,
                                                            color: theme
                                                                .textColor,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(
                                                    height: dynamicBoxHeightGroup,
                                                  ),
                                                  Align(
                                                    alignment: Alignment.topLeft,
                                                    child: Wrap(
                                                      spacing:
                                                          dynamicBoxHeightGroupSmall,
                                                      runSpacing:
                                                          dynamicBoxHeightGroupSmall,
                                                      alignment:
                                                          WrapAlignment.start,
                                                      children: [
                                                        for (final opt
                                                            in FilterPopConst
                                                                .estateTypes)
                                                          EstateTypeFilterButton(
                                                            text: opt['text']!.tr ?? '',
                                                            filterValue: opt['filterValue'] ?? '',
                                                            filterKey: FilterPopConst.estateType,
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                    height: dynamicBoxHeight,
                                                  ),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    children: [
                                                      Material(
                                                        color:
                                                            Colors.transparent,
                                                        child: Text(
                                                          'Filters'.tr,
                                                          style: AppTextStyles
                                                              .interSemiBold
                                                              .copyWith(
                                                            fontSize: 18,
                                                            color: theme
                                                                .textColor,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(
                                                    height:
                                                        dynamicBoxHeightGroupSmall,
                                                  ),
                                                  Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.start,
                                                    children: [
                                                      Expanded(
                                                        child: Column(
                                                          children: [
                                                            Row(
                                                              children: [
                                                                Expanded(
                                                                  child:
                                                                      BuildNumberField(
                                                                    controller:
                                                                        minSquareFootageController,
                                                                    labelText:
                                                                        'Area from'
                                                                            .tr,
                                                                    filterKey:
                                                                        FilterPopConst
                                                                            .minSquareFootage,
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                  width:
                                                                      dynamiSpacerBoxWidth,
                                                                ),
                                                                Expanded(
                                                                  child:
                                                                      BuildNumberField(
                                                                    controller:
                                                                        maxSquareFootageController,
                                                                    labelText:
                                                                        'Area to'
                                                                            .tr,
                                                                    filterKey:
                                                                        FilterPopConst
                                                                            .maxSquareFootage,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            const SizedBox(
                                                              height:
                                                                  dynamicBoxHeightGroup,
                                                            ),
                                                            Row(
                                                              children: [
                                                                Expanded(
                                                                  child:
                                                                      BuildNumberField(
                                                                    controller:
                                                                        minPriceController,
                                                                    labelText:
                                                                        'Price from'
                                                                            .tr,
                                                                    filterKey:
                                                                        FilterPopConst
                                                                            .minPrice,
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                  width:
                                                                      dynamiSpacerBoxWidth,
                                                                ),
                                                                Expanded(
                                                                  child:
                                                                      BuildNumberField(
                                                                    controller:
                                                                        maxPriceController,
                                                                    labelText:
                                                                        'Price to'
                                                                            .tr,
                                                                    filterKey:
                                                                        FilterPopConst
                                                                            .maxPrice,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            const SizedBox(
                                                              height:
                                                                  dynamicBoxHeightGroup,
                                                            ),
                                                            Row(
                                                              children: [
                                                                Expanded(
                                                                  child:
                                                                      BuildNumberField(
                                                                    controller:
                                                                        minPricePerMeterController,
                                                                    labelText:
                                                                        'Price per meter from'
                                                                            .tr,
                                                                    filterKey:
                                                                        FilterPopConst
                                                                            .minPricePerMeter,
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                  width:
                                                                      dynamiSpacerBoxWidth,
                                                                ),
                                                                Expanded(
                                                                  child:
                                                                      BuildNumberField(
                                                                    controller:
                                                                        maxPricePerMeterController,
                                                                    labelText:
                                                                        'Price per meter to'
                                                                            .tr,
                                                                    filterKey:
                                                                        FilterPopConst
                                                                            .maxPricePerMeter,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            const SizedBox(
                                                              height:
                                                                  dynamicBoxHeightGroup,
                                                            ),
                                                            Row(
                                                              children: [
                                                                Expanded(
                                                                  child:
                                                                      BuildNumberField(
                                                                        controller: minBuildYearController,
                                                                        filterKey: FilterPopConst.minBuildYear,
                                                                        formatWithSpaces: false,
                                                                    labelText:
                                                                        'Year of build from'
                                                                            .tr,
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                  width:
                                                                      dynamiSpacerBoxWidth,
                                                                ),
                                                                Expanded(
                                                                  child:
                                                                      BuildNumberField(
                                                                        controller: maxBuildYearController,
                                                                        filterKey: FilterPopConst.maxBuildYear,
                                                                        formatWithSpaces: false,
                                                                    labelText:
                                                                        'Year of build to'
                                                                            .tr,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            const SizedBox(
                                                              height:
                                                                  dynamicBoxHeight,
                                                            ),
                                                            Wrap(
                                                              spacing:
                                                                  dynamicBoxHeightGroupSmall,
                                                              runSpacing:
                                                                  dynamicBoxHeightGroupSmall,
                                                              children: const [
                                                                FilterButton(
                                                                  text: '1',
                                                                  filterValue:
                                                                      '1',
                                                                  filterKey:
                                                                      FilterPopConst
                                                                          .rooms,
                                                                ),
                                                                FilterButton(
                                                                  text: '2',
                                                                  filterValue:
                                                                      '2',
                                                                  filterKey:
                                                                      FilterPopConst
                                                                          .rooms,
                                                                ),
                                                                FilterButton(
                                                                  text: '3',
                                                                  filterValue:
                                                                      '3',
                                                                  filterKey:
                                                                      FilterPopConst
                                                                          .rooms,
                                                                ),
                                                                FilterButton(
                                                                  text: '4',
                                                                  filterValue:
                                                                      '4',
                                                                  filterKey:
                                                                      FilterPopConst
                                                                          .rooms,
                                                                ),
                                                                FilterButton(
                                                                  text: '5',
                                                                  filterValue:
                                                                      '5',
                                                                  filterKey:
                                                                      FilterPopConst
                                                                          .rooms,
                                                                ),
                                                                FilterButton(
                                                                  text: '6',
                                                                  filterValue:
                                                                      '6',
                                                                  filterKey:
                                                                      FilterPopConst
                                                                          .rooms,
                                                                ),
                                                                FilterButton(
                                                                  text: '7+',
                                                                  filterValue:
                                                                      '7+',
                                                                  filterKey:
                                                                      FilterPopConst
                                                                          .rooms,
                                                                ),
                                                              ],
                                                            ),
                                                            const SizedBox(
                                                              height:
                                                                  dynamicBoxHeight,
                                                            ),
                                                            const Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                FilterSlider(
                                                                  filterKey:
                                                                      FilterPopConst
                                                                          .floors,
                                                                ),
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        width:
                                                            dynamiSpacerBoxWidth *
                                                                3,
                                                      ),
                                                      Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          IntrinsicHeight(
                                                            child: Row(
                                                              children: [
                                                                FilterButton(
                                                                  text: 'Primary market'
                                                                      .tr,
                                                                  filterValue:
                                                                      'primary',
                                                                  filterKey:
                                                                      FilterPopConst
                                                                          .marketType,
                                                                ),
                                                                const SizedBox(
                                                                  width:
                                                                      dynamicBoxHeightGroup,
                                                                ),
                                                                FilterButton(
                                                                  text: 'Secondary market'
                                                                      .tr,
                                                                  filterValue:
                                                                      'secondary',
                                                                  filterKey:
                                                                      FilterPopConst
                                                                          .marketType,
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            height:
                                                                dynamicBoxHeightGroup,
                                                          ),
                                                          SizedBox(
                                                            width: inputWidth,
                                                            child:
                                                                BuildDropdownButtonFormField(
                                                              currentValue:
                                                                  selectedBuildingType,
                                                              options:
                                                                  FilterPopConst
                                                                      .dropdownOptionsFor(
                                                                FilterPopConst
                                                                    .buildingType,
                                                              ),
                                                              labelText:
                                                                  'filter_label_building_type'
                                                                      .tr,
                                                              filterKey:
                                                                  FilterPopConst
                                                                      .buildingType,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            height:
                                                                dynamicBoxHeightGroup,
                                                          ),
                                                          SizedBox(
                                                            width: inputWidth,
                                                            child:
                                                                BuildDropdownButtonFormField(
                                                              currentValue:
                                                                  selectedHeatingType,
                                                              options:
                                                                  FilterPopConst
                                                                      .dropdownOptionsFor(
                                                                FilterPopConst
                                                                    .heatingType,
                                                              ),
                                                              labelText:
                                                                  'Heating type'
                                                                      .tr,
                                                              filterKey:
                                                                  FilterPopConst
                                                                      .heatingType,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            height:
                                                                dynamicBoxHeightGroup,
                                                          ),
                                                          SizedBox(
                                                            width: inputWidth,
                                                            child:
                                                                BuildDropdownButtonFormField(
                                                              currentValue:
                                                                  selectedAktualnosc,
                                                              options:
                                                                  FilterPopConst
                                                                      .dropdownOptionsFor(
                                                                FilterPopConst
                                                                    .aktualnoscOferty,
                                                              ),
                                                              labelText:
                                                                  'filter_label_offer_freshness'
                                                                      .tr,
                                                              filterKey:
                                                                  FilterPopConst
                                                                      .aktualnoscOferty,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            height:
                                                                dynamicBoxHeightGroup,
                                                          ),
                                                          SizedBox(
                                                            width: inputWidth,
                                                            child:
                                                                BuildDropdownButtonFormField(
                                                              currentValue:
                                                                  selectedMaterial,
                                                              options:
                                                                  FilterPopConst
                                                                      .dropdownOptionsFor(
                                                                FilterPopConst
                                                                    .buildingMaterial,
                                                              ),
                                                              labelText:
                                                                  'filter_label_building_material'
                                                                      .tr,
                                                              filterKey:
                                                                  FilterPopConst
                                                                      .buildingMaterial,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            height:
                                                                dynamicBoxHeightGroup,
                                                          ),
                                                          SizedBox(
                                                            width: inputWidth,
                                                            child:
                                                                BuildDropdownButtonFormField(
                                                              currentValue:
                                                                  selectedAdvertiser,
                                                              options:
                                                                  FilterPopConst
                                                                      .dropdownOptionsFor(
                                                                FilterPopConst
                                                                    .advertiserType,
                                                              ),
                                                              labelText:
                                                                  'Advertiser'
                                                                      .tr,
                                                              filterKey:
                                                                  FilterPopConst
                                                                      .advertiserType,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(
                                                    height: dynamicBoxHeight,
                                                  ),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    children: [
                                                      Material(
                                                        color:
                                                            Colors.transparent,
                                                        child: Text(
                                                          'Additional information'
                                                              .tr,
                                                          style: AppTextStyles
                                                              .interSemiBold
                                                              .copyWith(
                                                            fontSize: 18,
                                                            color: theme
                                                                .textColor,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(
                                                    height:
                                                        dynamicBoxHeightGroup,
                                                  ),
                                                  Wrap(
                                                    spacing:
                                                        dynamicBoxHeightGroup,
                                                    runSpacing:
                                                        dynamicBoxHeightGroupSmall,
                                                    children: [
                                                      for (final opt
                                                          in FilterPopConst
                                                              .additionalInfo)
                                                        AdditionalInfoFilterButton(
                                                          text:
                                                              opt['text'] ?? '',
                                                          filterKey:
                                                              opt['filterKey'] ??
                                                                  '',
                                                        ),
                                                    ],
                                                  ),
                                                  const SizedBox(
                                                    height:
                                                        dynamicBoxHeightGroup,
                                                  ),
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
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      EmmaUiAnchorTarget(
                                        anchorKey: PortalEmmaAnchors.filtersPcSubmit.anchorKey,

                                        spec: PortalEmmaAnchors.filtersPcSubmit,
                                        runtimeMode: PortalEmmaAnchors.filtersPcSubmit.runtimeMode,
                                        tapMode: PortalEmmaAnchors.filtersPcSubmit.tapMode,
                                        child: AcceptRowButtonsFilters(
                                          isNeedToNavigate:
                                              widget.isNeedToNavigate,
                                          onClearFilters: () =>
                                              clearAllFilters(ref),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  top: 35,
                                  right: 18,
                                  child: Material(
                                    color: Colors.transparent,
                                    child: Ink(
                                      decoration: BoxDecoration(
                                        color: theme.whitewhiteblack
                                            .withAlpha(51),
                                        shape: BoxShape.circle,
                                      ),
                                      child: InkWell(
                                        customBorder: const CircleBorder(),
                                        onTap: () {
                                          Navigator.of(context).pop();
                                          model.setLoading(false);
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Icon(
                                            Icons.close,
                                            color: theme.textColor,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}