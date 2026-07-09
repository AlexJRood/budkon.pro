import 'package:flutter/material.dart';
import 'package:portal/screens/filter_landing_page/providers/filter_provider.dart';
import 'package:core/platform/filters/filters_const.dart';

class LandingFilterControllers {
  LandingFilterControllers._({
    required this.searchController,
    required this.searchRadiusController,
    required this.excludeController,
    required this.minPriceController,
    required this.maxPriceController,
    required this.minPricePerMeterController,
    required this.maxPricePerMeterController,
    required this.minRoomsController,
    required this.maxRoomsController,
    required this.minBathroomsController,
    required this.maxBathroomsController,
    required this.minSquareFootageController,
    required this.maxSquareFootageController,
    required this.minLotSizeController,
    required this.maxLotSizeController,
    required this.titleController,
    required this.descriptionController,
    required this.currencyController,
    required this.estateTypeController,
    required this.buildingTypeController,
    required this.countryController,
    required this.streetController,
    required this.cityController,
    required this.stateController,
    required this.zipcodeController,
    required this.propertyFormController,
    required this.marketTypeController,
    required this.offerTypeController,
    required this.minBuildYearController,
    required this.maxBuildYearController,
  });

  factory LandingFilterControllers.fromCache(FilterCacheNotifier cache) {
    return LandingFilterControllers._(
      searchController: TextEditingController(text: cache.searchQuery),
      searchRadiusController: TextEditingController(
        text: _toText(cache.filters['search_radius']),
      ),
      excludeController: TextEditingController(text: cache.excludeQuery),
      minPriceController: TextEditingController(
        text: _toText(cache.filters[FilterPopConst.minPrice]),
      ),
      maxPriceController: TextEditingController(
        text: _toText(cache.filters[FilterPopConst.maxPrice]),
      ),
      minPricePerMeterController: TextEditingController(
        text: _toText(cache.filters[FilterPopConst.minPricePerMeter]),
      ),
      maxPricePerMeterController: TextEditingController(
        text: _toText(cache.filters[FilterPopConst.maxPricePerMeter]),
      ),
      minRoomsController: TextEditingController(
        text: _toText(cache.filters[FilterPopConst.minRooms]),
      ),
      maxRoomsController: TextEditingController(
        text: _toText(cache.filters[FilterPopConst.maxRooms]),
      ),
      minBathroomsController: TextEditingController(
        text: _toText(cache.filters[FilterPopConst.minBathrooms]),
      ),
      maxBathroomsController: TextEditingController(
        text: _toText(cache.filters[FilterPopConst.maxBathrooms]),
      ),
      minSquareFootageController: TextEditingController(
        text: _toText(cache.filters[FilterPopConst.minSquareFootage]),
      ),
      maxSquareFootageController: TextEditingController(
        text: _toText(cache.filters[FilterPopConst.maxSquareFootage]),
      ),
      minLotSizeController: TextEditingController(
        text: _toText(cache.filters[FilterPopConst.minLotSize]),
      ),
      maxLotSizeController: TextEditingController(
        text: _toText(cache.filters[FilterPopConst.maxLotSize]),
      ),
      titleController: TextEditingController(
        text: _toText(cache.filters[FilterPopConst.title]),
      ),
      descriptionController: TextEditingController(
        text: _toText(cache.filters[FilterPopConst.description]),
      ),
      currencyController: TextEditingController(
        text: _toText(cache.filters[FilterPopConst.currency]),
      ),
      estateTypeController: TextEditingController(
        text: _toText(cache.filters[FilterPopConst.estateType]),
      ),
      buildingTypeController: TextEditingController(
        text: _toText(cache.filters[FilterPopConst.buildingType]),
      ),
      countryController: TextEditingController(
        text: _toText(cache.filters[FilterPopConst.country]),
      ),
      streetController: TextEditingController(
        text: _toText(cache.filters[FilterPopConst.street]),
      ),
      cityController: TextEditingController(
        text: _toText(cache.filters[FilterPopConst.city]),
      ),
      stateController: TextEditingController(
        text: _toText(cache.filters[FilterPopConst.state]),
      ),
      zipcodeController: TextEditingController(
        text: _toText(cache.filters[FilterPopConst.zipcode]),
      ),
      propertyFormController: TextEditingController(
        text: _toText(cache.filters[FilterPopConst.propertyForm]),
      ),
      marketTypeController: TextEditingController(
        text: _toText(cache.filters[FilterPopConst.marketType]),
      ),
      offerTypeController: TextEditingController(
        text: _toText(cache.filters[FilterPopConst.offerType]),
      ),
      minBuildYearController: TextEditingController(
        text: _toText(cache.filters[FilterPopConst.minBuildYear]),
      ),
      maxBuildYearController: TextEditingController(
        text: _toText(cache.filters[FilterPopConst.maxBuildYear]),
      ),
    );
  }

  final TextEditingController searchController;
  final TextEditingController searchRadiusController;
  final TextEditingController excludeController;
  final TextEditingController minPriceController;
  final TextEditingController maxPriceController;
  final TextEditingController minPricePerMeterController;
  final TextEditingController maxPricePerMeterController;
  final TextEditingController minRoomsController;
  final TextEditingController maxRoomsController;
  final TextEditingController minBathroomsController;
  final TextEditingController maxBathroomsController;
  final TextEditingController minSquareFootageController;
  final TextEditingController maxSquareFootageController;
  final TextEditingController minLotSizeController;
  final TextEditingController maxLotSizeController;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController currencyController;
  final TextEditingController estateTypeController;
  final TextEditingController buildingTypeController;
  final TextEditingController countryController;
  final TextEditingController streetController;
  final TextEditingController cityController;
  final TextEditingController stateController;
  final TextEditingController zipcodeController;
  final TextEditingController propertyFormController;
  final TextEditingController marketTypeController;
  final TextEditingController offerTypeController;
  final TextEditingController minBuildYearController;
  final TextEditingController maxBuildYearController;

  static String _toText(dynamic value) => value?.toString() ?? '';

  List<TextEditingController> get _allControllers => [
        searchController,
        searchRadiusController,
        excludeController,
        minPriceController,
        maxPriceController,
        minPricePerMeterController,
        maxPricePerMeterController,
        minRoomsController,
        maxRoomsController,
        minBathroomsController,
        maxBathroomsController,
        minSquareFootageController,
        maxSquareFootageController,
        minLotSizeController,
        maxLotSizeController,
        titleController,
        descriptionController,
        currencyController,
        estateTypeController,
        buildingTypeController,
        countryController,
        streetController,
        cityController,
        stateController,
        zipcodeController,
        propertyFormController,
        marketTypeController,
        offerTypeController,
        minBuildYearController,
        maxBuildYearController,
      ];

  void clearAll() {
    for (final controller in _allControllers) {
      controller.clear();
    }
  }

  void dispose() {
    for (final controller in _allControllers) {
      controller.dispose();
    }
  }
}