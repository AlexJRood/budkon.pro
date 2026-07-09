// nm_controllers.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_monitoring/providers/search_page/filters_provider.dart';
import 'package:network_monitoring/providers/tag_input_provider.dart';

/// Single source of truth for all text/scroll controllers used on the NM filter screen.
/// Owns lifecycle (dispose) via Riverpod's ref.onDispose.
class NMControllers {
  NMControllers._();
  // ── Text controllers ────────────────────────────────────────────────────────
  final searchController               = TextEditingController();
  final searchRadiusController         = TextEditingController();
  final excludeController              = TextEditingController();

  final minPriceController             = TextEditingController();
  final maxPriceController             = TextEditingController();
  final minPricePerMeterController     = TextEditingController();
  final maxPricePerMeterController     = TextEditingController();

  final minRoomsController             = TextEditingController();
  final maxRoomsController             = TextEditingController();
  final minBathroomsController         = TextEditingController();
  final maxBathroomsController         = TextEditingController();

  final minSquareFootageController     = TextEditingController();
  final maxSquareFootageController     = TextEditingController();

  final minYearBuildController     = TextEditingController();
  final maxYearBuildController     = TextEditingController();

  final minLotSizeController           = TextEditingController();
  final maxLotSizeController           = TextEditingController();

  final titleController                = TextEditingController();
  final descriptionController          = TextEditingController();
  final currencyController             = TextEditingController();

  final estateTypeController           = TextEditingController();
  final buildingTypeController         = TextEditingController();

  final countryController              = TextEditingController();
  final streetController               = TextEditingController();
  final cityController                 = TextEditingController();
  final stateController                = TextEditingController();
  final zipcodeController              = TextEditingController();

  final propertyFormController         = TextEditingController();
  final marketTypeController           = TextEditingController();
  final offerTypeController            = TextEditingController();

  // ── Scroll controller ───────────────────────────────────────────────────────
  final scrollController               = ScrollController();


  void clearTagInputs(WidgetRef ref) {
    ref.read(nmTagInputProvider('nm_search').notifier).clearAll();
    ref.read(nmTagInputProvider('nm_exclude').notifier).clearAll();
  }

  // Initialize values from cache once.
  void initializeFromCache(Ref ref) {
    final cache = ref.read(networkMonitoringFilterCacheProvider.notifier);
    final f = cache.filters;
    // search & exclude
    searchController.text         = cache.searchQuery ?? '';
    searchRadiusController.text   = cache.searchQuery ?? '';
    excludeController.text        = cache.excludeQuery ?? '';

    // simple string/num fields
    String _s(String key) => (f[key] ?? '').toString();
    minPriceController.text             = _s('min_price');
    maxPriceController.text             = _s('max_price');
    minPricePerMeterController.text     = _s('min_price_per_meter');
    maxPricePerMeterController.text     = _s('max_price_per_meter');

    minRoomsController.text             = _s('min_rooms');
    maxRoomsController.text             = _s('max_rooms');
    minBathroomsController.text         = _s('min_bathrooms');
    maxBathroomsController.text         = _s('max_bathrooms');

    minSquareFootageController.text     = _s('min_square_footage');
    maxSquareFootageController.text     = _s('max_square_footage');

    minLotSizeController.text           = _s('min_lot_size');
    maxLotSizeController.text           = _s('max_lot_size');

    minYearBuildController.text           = _s('min_build_year');
    maxYearBuildController.text           = _s('max_build_year');

    titleController.text                = _s('title');
    descriptionController.text          = _s('description');
    currencyController.text             = _s('currency');

    estateTypeController.text           = _s('estate_type');
    buildingTypeController.text         = _s('building_type');

    streetController.text               = _s('street');
    cityController.text                 = _s('city');
    stateController.text                = _s('state');
    zipcodeController.text              = _s('zipcode');

    propertyFormController.text         = _s('property_form');
    marketTypeController.text           = _s('market_type');
    offerTypeController.text            = _s('offer_type');
    countryController.text              = _s('country');
  }

  void initializeTagInputsFromCacheDelayed(Ref ref) {
    final cache = ref.read(networkMonitoringFilterCacheProvider.notifier);

    final searchCache = cache.filters['search'];
    if (searchCache != null && searchCache is String && searchCache.isNotEmpty) {
      final searchItems = searchCache.split(',').where((item) => item.trim().isNotEmpty).toList();
      ref.read(nmTagInputProvider('nm_search').notifier).setItems(searchItems);
    }

    final excludeCache = cache.filters['exclude'];
    if (excludeCache != null && excludeCache is String && excludeCache.isNotEmpty) {
      final excludeItems = excludeCache.split(',').where((item) => item.trim().isNotEmpty).toList();
      ref.read(nmTagInputProvider('nm_exclude').notifier).setItems(excludeItems);
    }
  }

  void applyFromCacheSnapshot(Map<String, dynamic> filters, String? search, String? exclude) {
    searchController.text         = search ?? '';
    searchRadiusController.text   = search ?? '';
    excludeController.text        = exclude ?? '';

    String _s(String key) => (filters[key] ?? '').toString();

    minPriceController.text             = _s('min_price');
    maxPriceController.text             = _s('max_price');
    minPricePerMeterController.text     = _s('min_price_per_meter');
    maxPricePerMeterController.text     = _s('max_price_per_meter');

    minRoomsController.text             = _s('min_rooms');
    maxRoomsController.text             = _s('max_rooms');
    minBathroomsController.text         = _s('min_bathrooms');
    maxBathroomsController.text         = _s('max_bathrooms');

    minSquareFootageController.text     = _s('min_square_footage');
    maxSquareFootageController.text     = _s('max_square_footage');

    minLotSizeController.text           = _s('min_lot_size');
    maxLotSizeController.text           = _s('max_lot_size');

    minYearBuildController.text           = _s('min_build_year');
    maxYearBuildController.text           = _s('max_build_year');

    titleController.text                = _s('title');
    descriptionController.text          = _s('description');
    currencyController.text             = _s('currency');

    estateTypeController.text           = _s('estate_type');
    buildingTypeController.text         = _s('building_type');

    streetController.text               = _s('street');
    cityController.text                 = _s('city');
    stateController.text                = _s('state');
    zipcodeController.text              = _s('zipcode');

    propertyFormController.text         = _s('property_form');
    marketTypeController.text           = _s('market_type');
    offerTypeController.text            = _s('offer_type');
    countryController.text              = _s('country');
  }

  void dispose() {
    // Dispose ALL controllers
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

    minYearBuildController.dispose();
    maxYearBuildController.dispose();

    titleController.dispose();
    descriptionController.dispose();
    currencyController.dispose();

    estateTypeController.dispose();
    buildingTypeController.dispose();

    countryController.dispose();
    streetController.dispose();
    cityController.dispose();
    stateController.dispose();
    zipcodeController.dispose();

    propertyFormController.dispose();
    marketTypeController.dispose();
    offerTypeController.dispose();

    scrollController.dispose();
  }


  void clearAllTextFields() {
    for (final c in <TextEditingController>[
      searchController, searchRadiusController, excludeController,
      minPriceController, maxPriceController,
      minPricePerMeterController, maxPricePerMeterController,
      minRoomsController, maxRoomsController,
      minYearBuildController, maxYearBuildController,
      minBathroomsController, maxBathroomsController,
      minSquareFootageController, maxSquareFootageController,
      minLotSizeController, maxLotSizeController,
      titleController, descriptionController, currencyController,
      estateTypeController, buildingTypeController,
      countryController, streetController, cityController,
      stateController, zipcodeController,
      propertyFormController, marketTypeController, offerTypeController,
    ]) {
      c.text = '';
    }
  }

  void clearAll(WidgetRef ref) {
    clearAllTextFields();
    clearTagInputs(ref);
  }

}



/// Riverpod provider that owns NMControllers and their lifecycle.
/// Riverpod provider that owns NMControllers and their lifecycle.
final nmControllersProvider = AutoDisposeProvider<NMControllers>((ref) {
  final c = NMControllers._();

  // Initialize once from cache
  c.initializeFromCache(ref);

  // Schedule tag input initialization after the provider is fully built
  WidgetsBinding.instance.addPostFrameCallback((_) {
      c.initializeTagInputsFromCacheDelayed(ref);
  });

  ref.onDispose(c.dispose);
  return c;
});
