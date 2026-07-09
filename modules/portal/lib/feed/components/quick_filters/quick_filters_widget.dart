import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/shell/keyboard_shortcuts.dart';
import 'package:portal/screens/filter_landing_page/components/filters_components.dart';
import 'package:portal/screens/filter_landing_page/providers/filter_provider.dart';
import 'package:core/platform/filters/filters_const.dart';
import 'package:core/platform/navigation_history_provider.dart';
import 'package:core/common/autocompletion/autocomplete.dart';

import 'package:portal/feed/components/quick_filters/components/estate_type_widget.dart';
import 'package:portal/feed/components/quick_filters/components/filter_buttons_widget.dart';
import 'package:portal/feed/components/quick_filters/components/filters_widget.dart';
import 'package:portal/feed/components/quick_filters/components/market_filters_widget.dart';
import 'package:portal/feed/components/quick_filters/components/offer_type_widget.dart';
import 'package:portal/screens/filter_landing_page/providers/filter_cntrl.dart';

class QuickFilterWidget extends ConsumerStatefulWidget {
  const QuickFilterWidget({super.key});

  @override
  ConsumerState<QuickFilterWidget> createState() => _QuickFilterWidgetState();
}

class _QuickFilterWidgetState extends ConsumerState<QuickFilterWidget>
    with AutomaticKeepAliveClientMixin {
  late final LandingFilterControllers controllers;
  late final ScrollController _scrollController;
  late final FocusNode _focusNode;
  ProviderSubscription<Map<String, dynamic>>? _filterCacheSubscription;

  String selectedOfferType = '';

  @override
  void initState() {
    super.initState();

    _focusNode = FocusNode();
    _scrollController = ScrollController();

    final cache = ref.read(filterCacheProvider.notifier);
    controllers = LandingFilterControllers.fromCache(cache);
    selectedOfferType = controllers.offerTypeController.text;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });

    _filterCacheSubscription = ref.listenManual<Map<String, dynamic>>(
      filterCacheProvider,
      (previous, next) {
        final prevClearedAt = previous?['clearedAt'];
        final nextClearedAt = next['clearedAt'];

        if (nextClearedAt != null && nextClearedAt != prevClearedAt) {
          _syncControllersWithCache();
        }
      },
    );
  }

  @override
  void dispose() {
    _filterCacheSubscription?.close();
    _focusNode.dispose();
    _scrollController.dispose();
    controllers.dispose();
    super.dispose();
  }

  void setSelectedOfferType(String value) {
    setState(() {
      selectedOfferType = value;
      controllers.offerTypeController.text = value;
    });
  }

  void _syncControllersWithCache() {
    final cache = ref.read(filterCacheProvider.notifier);

    controllers.searchController.text = cache.searchQuery;
    controllers.excludeController.text = cache.excludeQuery;
    controllers.searchRadiusController.text =
        cache.filters['search_radius']?.toString() ?? '';

    controllers.minPriceController.text =
        cache.filters[FilterPopConst.minPrice]?.toString() ?? '';
    controllers.maxPriceController.text =
        cache.filters[FilterPopConst.maxPrice]?.toString() ?? '';

    controllers.minPricePerMeterController.text =
        cache.filters[FilterPopConst.minPricePerMeter]?.toString() ?? '';
    controllers.maxPricePerMeterController.text =
        cache.filters[FilterPopConst.maxPricePerMeter]?.toString() ?? '';

    controllers.minRoomsController.text =
        cache.filters[FilterPopConst.minRooms]?.toString() ?? '';
    controllers.maxRoomsController.text =
        cache.filters[FilterPopConst.maxRooms]?.toString() ?? '';

    controllers.minBathroomsController.text =
        cache.filters[FilterPopConst.minBathrooms]?.toString() ?? '';
    controllers.maxBathroomsController.text =
        cache.filters[FilterPopConst.maxBathrooms]?.toString() ?? '';

    controllers.minSquareFootageController.text =
        cache.filters[FilterPopConst.minSquareFootage]?.toString() ?? '';
    controllers.maxSquareFootageController.text =
        cache.filters[FilterPopConst.maxSquareFootage]?.toString() ?? '';

    controllers.minLotSizeController.text =
        cache.filters[FilterPopConst.minLotSize]?.toString() ?? '';
    controllers.maxLotSizeController.text =
        cache.filters[FilterPopConst.maxLotSize]?.toString() ?? '';

    controllers.titleController.text =
        cache.filters[FilterPopConst.title]?.toString() ?? '';
    controllers.descriptionController.text =
        cache.filters[FilterPopConst.description]?.toString() ?? '';
    controllers.currencyController.text =
        cache.filters[FilterPopConst.currency]?.toString() ?? '';
    controllers.estateTypeController.text =
        cache.filters[FilterPopConst.estateType]?.toString() ?? '';
    controllers.buildingTypeController.text =
        cache.filters[FilterPopConst.buildingType]?.toString() ?? '';

    controllers.countryController.text =
        cache.filters[FilterPopConst.country]?.toString() ?? '';
    controllers.streetController.text =
        cache.filters[FilterPopConst.street]?.toString() ?? '';
    controllers.cityController.text =
        cache.filters[FilterPopConst.city]?.toString() ?? '';
    controllers.stateController.text =
        cache.filters[FilterPopConst.state]?.toString() ?? '';
    controllers.zipcodeController.text =
        cache.filters[FilterPopConst.zipcode]?.toString() ?? '';

    controllers.propertyFormController.text =
        cache.filters[FilterPopConst.propertyForm]?.toString() ?? '';
    controllers.marketTypeController.text =
        cache.filters[FilterPopConst.marketType]?.toString() ?? '';
    controllers.offerTypeController.text =
        cache.filters[FilterPopConst.offerType]?.toString() ?? '';

    setState(() {
      selectedOfferType = controllers.offerTypeController.text;
    });
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final String? currentCountry = ref.watch(
      filterButtonProvider.select((state) => state['country']),
    );

    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    final double dynamicBoxHeight = screenWidth < 1400 ? 14 : 25;
    final double dynamicBoxHeightGroup = screenWidth < 1400 ? 8 : 10;
    const double dynamicBoxHeightGroupSmall = 8;
    const double dynamiSpacerBoxWidth = 15;
    const double dynamicSpace = 5;

    final double filterBarWidth = math.max(screenWidth * 0.75, 450);
    final double filterBarHeigth = math.max(screenHeight, 400);

    return Stack(
      children: [
        Center(
          child: SizedBox(
            width: filterBarWidth,
            height: filterBarHeigth,
            child: Column(
              children: [
                Expanded(
                  child: ScrollbarTheme(
                    data: ScrollbarThemeData(
                      thumbColor: WidgetStateProperty.all(
                        Colors.white.withAlpha((255 * 0.5).toInt()),
                      ),
                      thickness: WidgetStateProperty.all(6.0),
                      radius: const Radius.circular(10.0),
                    ),
                    child: Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      child: ListView(
                        controller: _scrollController,
                        padding: const EdgeInsets.only(
                          top: 10,
                          bottom: 20,
                          left: 20,
                          right: 20,
                        ),
                        children: [
                          const SizedBox(height: 60),

                          OfferTypeWidget(
                            dynamicBoxHeightGroupSmall:
                                dynamicBoxHeightGroupSmall,
                          ),

                          SizedBox(height: dynamicBoxHeight),

                          AutoCompleteWidget(
            onCleared: (ref) => ref.read(filterProvider.notifier).applyFiltersFromCache(ref.read(filterCacheProvider.notifier), ref),
                            provider: 'portal',
                            onLocationChanged: (ref, sel) {
                              final cache = ref.read(
                                filterCacheProvider.notifier,
                              );

                              if (sel.isEmpty) {
                                cache.removeFilter('location_type');
                                cache.removeFilter('location_id');

                                cache.removeFilter(FilterPopConst.city);
                                cache.removeFilter(FilterPopConst.voivodeship);
                                cache.removeFilter(FilterPopConst.district);
                                return;
                              }

                              cache.addFilter('location_type', sel.type);
                              cache.addFilter('location_id', sel.id);

                              if (sel.city.trim().isNotEmpty) {
                                cache.addFilter(
                                  FilterPopConst.city,
                                  sel.city.trim(),
                                );
                              } else {
                                cache.removeFilter(FilterPopConst.city);
                              }

                              if (sel.state.trim().isNotEmpty) {
                                cache.addFilter(
                                  FilterPopConst.voivodeship,
                                  sel.state.trim(),
                                );
                              } else {
                                cache.removeFilter(FilterPopConst.voivodeship);
                              }

                              if (sel.districts.isNotEmpty) {
                                cache.addFilter(
                                  FilterPopConst.district,
                                  sel.districts.first.trim(),
                                );
                              } else {
                                cache.removeFilter(FilterPopConst.district);
                              }
                            },
                          ),

                          SizedBox(height: dynamicBoxHeight),

                          EstateTypeWidget(
                            dynamicSpace: dynamicSpace,
                            dynamicBoxHeightGroupSmall:
                                dynamicBoxHeightGroupSmall,
                          ),

                          SizedBox(height: dynamicBoxHeight),

                          FiltersWidget(
                            controllers: controllers,
                            dynamicBoxHeightGroupSmall:
                                dynamicBoxHeightGroupSmall,
                            dynamiSpacerBoxWidth: dynamiSpacerBoxWidth,
                            dynamicBoxHeightGroup: dynamicBoxHeightGroup,
                            dynamicBoxHeight: dynamicBoxHeight,
                            dynamicSpace: dynamicSpace,
                            ref: ref,
                          ),

                          SizedBox(height: dynamicBoxHeight),

                          MarketFiltersWidget(
                            currentCountry: currentCountry,
                            dynamicBoxHeightGroup: dynamicBoxHeightGroup,
                            dynamicBoxHeightGroupSmall:
                                dynamicBoxHeightGroupSmall,
                            ref: ref,
                          ),

                          SizedBox(height: dynamicBoxHeight + 30),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: FilterButtonsWidget(
            navigationHistoryProvider: navigationHistoryProvider,
          ),
        ),
      ],
    );
  }
}
