import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_monitoring/providers/search_page/filters_provider.dart';
import 'package:core/shell/keyboard_shortcuts.dart';
import 'package:network_monitoring/widgets/filter/estate_type_widget.dart';
import 'package:network_monitoring/widgets/filter/fileds.dart';
import 'package:network_monitoring/widgets/filter/filters_widget.dart';
import 'package:network_monitoring/widgets/filter/market_filters_widget.dart';
import 'package:network_monitoring/widgets/filter/offer_type_widget.dart';
import 'package:portal/screens/feed/components/cards/quick_filters/filter_buttons_widget.dart';
import 'package:core/platform/navigation_history_provider.dart';
import 'package:core/common/autocompletion/autocompletion.dart';

class FilterNetworkMonitoringNotifier
    extends StateNotifier<_FilterNetowrkMonitoringState> {
  FilterNetworkMonitoringNotifier() : super(_FilterNetowrkMonitoringState());
}

final filterNetworkMonitoringProvider = StateNotifierProvider<
  FilterNetworkMonitoringNotifier,
  _FilterNetowrkMonitoringState
>((ref) => FilterNetworkMonitoringNotifier());

class FilterMonitoringWidget extends ConsumerStatefulWidget {
  const FilterMonitoringWidget({super.key});

  @override
  _FilterNetowrkMonitoringState createState() =>
      _FilterNetowrkMonitoringState();
}

class _FilterNetowrkMonitoringState
    extends ConsumerState<FilterMonitoringWidget> with AutomaticKeepAliveClientMixin{
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
  late final ScrollController _scrollController;
  late FocusNode _focusNode;
  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
    final filterNotifier = ref.read(
      networkMonitoringFilterCacheProvider.notifier,
    );

    searchController = TextEditingController(text: filterNotifier.searchQuery);
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
    _scrollController = ScrollController();
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
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void setSelectedOfferType(String value) {
    setState(() {
      selectedOfferType = value;
      offerTypeController.text = value;
    });
  }

 @override
  bool get wantKeepAlive => true;
  
  @override
  Widget build(BuildContext context) {
      super.build(context);
    final String? currentCountry = ref.watch(
      networkMonitoringFilterButtonProvider.select((state) => state['country']),
    );

    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double dynamicBoxHeight = 25;
    double dynamicBoxHeightGroup = 10;
    double dynamicBoxHeightGroupSmall = 8;
    double dynamiSpacerBoxWidth = 15;
    double filterBarWidth = math.max(screenWidth * 0.75, 450);
    double filterBarHeigth = math.max(screenHeight, 400);
    double dynamicSpace = 5;

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: (KeyEvent event) {
        // Check if the pressed key matches the stored pop key
        KeyBoardShortcuts().handleKeyEvent(event, _scrollController, 50, 100);
      },
      child: Stack(
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
                        thumbVisibility: true,
                        controller: _scrollController,
                        child: ListView(
                          controller: _scrollController,
                          padding: const EdgeInsets.only(
                            top: 10,
                            bottom: 20.0,
                            left: 20.0,
                            right: 20,
                          ),
                          children: [
                            const SizedBox(height: 60),
                            // SearchBarWidget(
                            //     searchController: searchController,
                            //     ref: ref,
                            //     dynamiSpacerBoxWidth: dynamiSpacerBoxWidth),
                            // SizedBox(height: dynamiSpacerBoxWidth),
                            OfferTypeWidget(
                              dynamicBoxHeightGroupSmall:
                                  dynamicBoxHeightGroupSmall,
                            ),

                            SizedBox(height: dynamicBoxHeight),

                            Mytextfield(),

                            SizedBox(height: dynamicBoxHeight),

                            // LocationWidget(
                            //     cityController: cityController,
                            //     stateController: stateController,
                            //     streetController: streetController,
                            //     zipcodeController: zipcodeController,
                            //     searchRadiusController: searchRadiusController,
                            //     ref: ref,
                            //     dynamicBoxHeightGroupSmall: dynamicBoxHeightGroupSmall,
                            //     dynamiSpacerBoxWidth: dynamiSpacerBoxWidth),
                            // SizedBox(height: dynamicBoxHeight),
                            EstateTypeWidget(
                              dynamicSpace: dynamicSpace,
                              dynamicBoxHeightGroupSmall:
                                  dynamicBoxHeightGroupSmall,
                            ),

                            SizedBox(height: dynamicBoxHeight),

                            FiltersWidget(
                              minSquareFootageController:
                                  minSquareFootageController,
                              maxSquareFootageController:
                                  maxSquareFootageController,
                              minPriceController: minPriceController,
                              maxPriceController: maxPriceController,
                              minPricePerMeterController:
                                  minPricePerMeterController,
                              maxPricePerMeterController:
                                  maxPricePerMeterController,
                              minRoomsController: minRoomsController,
                              maxRoomsController: maxRoomsController,
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
                            // SizedBox(height: dynamicBoxHeight),
                            // AdditionalInfoWidget(
                            //     dynamicBoxHeightGroup: dynamicBoxHeightGroup,
                            //     dynamicSpace: dynamicSpace),
                            SizedBox(height: dynamicBoxHeight * 2),
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
      ),
    );
  }
}
