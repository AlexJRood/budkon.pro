import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:country_state_city/models/country.dart';
import 'package:country_state_city/models/state.dart' as state_model;
import 'package:country_state_city/models/city.dart';
import 'package:country_state_city/utils/city_utils.dart';
import 'package:country_state_city/utils/country_utils.dart';
import 'package:country_state_city/utils/state_utils.dart';
import 'package:core/common/shared_widgets/country_model.dart';
import 'dart:developer';
import 'package:get/get_utils/get_utils.dart';

class LocationStateReport {
  final List<DropDownCountry> countries;
  final List<Country> allCountries;
  final List<String> states;
  final List<state_model.State> allStates;
  final List<String> cities;
  final List<City> allCities;
  final bool isLoading;
  final bool isLoadingStates;
  final bool isLoadingCities;
  final String? currentCountryForStates;
  final String? currentStateForCities;

  LocationStateReport({
    this.countries = const [],
    this.allCountries = const [],
    this.states = const [],
    this.allStates = const [],
    this.cities = const [],
    this.allCities = const [],
    this.isLoading = true,
    this.isLoadingStates = false,
    this.isLoadingCities = false,
    this.currentCountryForStates,
    this.currentStateForCities,
  });

  LocationStateReport copyWith({
    List<DropDownCountry>? countries,
    List<Country>? allCountries,
    List<String>? states,
    List<state_model.State>? allStates,
    List<String>? cities,
    List<City>? allCities,
    bool? isLoading,
    bool? isLoadingStates,
    bool? isLoadingCities,
    String? currentCountryForStates,
    String? currentStateForCities,
  }) {
    return LocationStateReport(
      countries: countries ?? this.countries,
      allCountries: allCountries ?? this.allCountries,
      states: states ?? this.states,
      allStates: allStates ?? this.allStates,
      cities: cities ?? this.cities,
      allCities: allCities ?? this.allCities,
      isLoading: isLoading ?? this.isLoading,
      isLoadingStates: isLoadingStates ?? this.isLoadingStates,
      isLoadingCities: isLoadingCities ?? this.isLoadingCities,
      currentCountryForStates: currentCountryForStates ?? this.currentCountryForStates,
      currentStateForCities: currentStateForCities ?? this.currentStateForCities,
    );
  }
}

class LocationNotifierReport extends StateNotifier<LocationStateReport> {
  LocationNotifierReport() : super(LocationStateReport()) {
    log("📦 LocationNotifierReport initialized: Loading countries...");
    _initializeWithPoland();
  }

  Future<void> _initializeWithPoland() async {
    try {
      // Load all countries first
      await loadCountries();
      
      // Load Poland's states by default
      await loadStates('Poland');
      
      log("✅ Initialized with Poland as default country");
    } catch (e, st) {
      log("❌ Error during initialization: $e", stackTrace: st);
    }
  }

  Future<void> loadCountries() async {
    try {
      log("🌍 Fetching all countries...");
      final countries = await getAllCountries();
      log("✅ Fetched ${countries.length} countries");

      final dropdownCountries = countries.map((c) {
        return DropDownCountry(
          name: c.name,
          isoCode: c.isoCode,
          phoneCode: c.phoneCode,
        );
      }).toList();

      state = state.copyWith(
        countries: dropdownCountries,
        allCountries: countries,
        isLoading: false,
      );

      log("✅ Countries loaded into state. Total: ${dropdownCountries.length}");
    } catch (e, st) {
      log("❌ Error while loading countries: $e", stackTrace: st);
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loadStates(String countryName) async {
    if (countryName.isEmpty || countryName == 'null') {
      log("⚠️ No country selected (empty or null)...");
      state = state.copyWith(
        states: [],
        allStates: [],
        isLoadingStates: false,
        currentCountryForStates: null,
      );
      return;
    }

    // Check if country exists in the list
    final countryExists = state.countries.any((c) => c.name.toLowerCase() == countryName.toLowerCase());
    if (!countryExists) {
      log("⚠️ Country '$countryName' not found in countries list...");
      state = state.copyWith(
        states: ['no_records_found'.tr],
        allStates: [],
        isLoadingStates: false,
        currentCountryForStates: countryName,
      );
      return;
    }

    // Set loading state
    state = state.copyWith(
      isLoadingStates: true,
      currentCountryForStates: countryName,
      states: [],
      allStates: [],
      cities: [], // Clear cities when country changes
      allCities: [],
    );

    try {
      log("🏛️ Fetching states for country: $countryName");

      final selectedCountry = state.countries.firstWhere((c) => c.name.toLowerCase() == countryName.toLowerCase());
      log("✅ Found selected country: ${selectedCountry.name} (${selectedCountry.isoCode})");

      final stateList = await getStatesOfCountry(selectedCountry.isoCode);
      log("✅ Fetched ${stateList.length} states for ${selectedCountry.name}");

      final stateNames = stateList.map((s) => s.name).toList();

      // Only update if we're still loading for the same country
      if (state.currentCountryForStates == countryName) {
        if (stateNames.isEmpty) {
          state = state.copyWith(
            states: ['no_states_available'.tr],
            allStates: [],
            isLoadingStates: false,
          );
        } else {
          state = state.copyWith(
            states: stateNames,
            allStates: stateList,
            isLoadingStates: false,
          );
        }
      }

      log("✅ States loaded into state. Total: ${stateNames.length}");
    } catch (e, st) {
      log("❌ Error while loading states for $countryName: $e", stackTrace: st);
      // Only update if we're still loading for the same country
      if (state.currentCountryForStates == countryName) {
        state = state.copyWith(
          states: ['error_loading_states'.tr],
          allStates: [],
          isLoadingStates: false,
        );
      }
    }
  }

  Future<void> loadCities(String countryName, String stateName) async {
    if (countryName.isEmpty || stateName.isEmpty || countryName == 'null' || stateName == 'null') {
      log("⚠️ No country or state selected...");
      state = state.copyWith(
        cities: [],
        allCities: [],
        isLoadingCities: false,
        currentStateForCities: null,
      );
      return;
    }

    // Check if country and state exist
    final countryExists = state.countries.any((c) => c.name.toLowerCase() == countryName.toLowerCase());
    final stateExists = state.states.any((s) => s.toLowerCase() == stateName.toLowerCase());
    
    if (!countryExists || !stateExists) {
      log("⚠️ Country '$countryName' or state '$stateName' not found...");
      state = state.copyWith(
        cities: ['no_records_found'.tr],
        allCities: [],
        isLoadingCities: false,
        currentStateForCities: stateName,
      );
      return;
    }

    // Set loading state
    state = state.copyWith(
      isLoadingCities: true,
      currentStateForCities: stateName,
      cities: [],
      allCities: [],
    );

    try {
      log("🌆 Fetching cities for state: $stateName in country: $countryName");

      final selectedCountry = state.countries.firstWhere((c) => c.name.toLowerCase() == countryName.toLowerCase());
      final selectedState = state.allStates.firstWhere((s) => s.name.toLowerCase() == stateName.toLowerCase());
      
      log("✅ Found selected state: ${selectedState.name} (${selectedState.isoCode})");

      final cityList = await getStateCities(selectedCountry.isoCode, selectedState.isoCode);
      log("✅ Fetched ${cityList.length} cities for ${selectedState.name}");

      final cityNames = cityList.map((c) => c.name).toList();

      // Only update if we're still loading for the same state
      if (state.currentStateForCities == stateName) {
        if (cityNames.isEmpty) {
          state = state.copyWith(
            cities: ['no_cities_available'.tr],
            allCities: [],
            isLoadingCities: false,
          );
        } else {
          state = state.copyWith(
            cities: cityNames,
            allCities: cityList,
            isLoadingCities: false,
          );
        }
      }

      log("✅ Cities loaded into state. Total: ${cityNames.length}");
    } catch (e, st) {
      log("❌ Error while loading cities for $stateName in $countryName: $e", stackTrace: st);
      // Only update if we're still loading for the same state
      if (state.currentStateForCities == stateName) {
        state = state.copyWith(
          cities: ['error_loading_cities'.tr],
          allCities: [],
          isLoadingCities: false,
        );
      }
    }
  }

  void clearStates() {
    log("🧹 Clearing states from state...");
    state = state.copyWith(
      states: [],
      allStates: [],
      isLoadingStates: false,
      currentCountryForStates: null,
      cities: [], // Also clear cities when clearing states
      allCities: [],
      isLoadingCities: false,
      currentStateForCities: null,
    );
    log("✅ States cleared");
  }

  void clearCities() {
    log("🧹 Clearing cities from state...");
    state = state.copyWith(
      cities: [],
      allCities: [],
      isLoadingCities: false,
      currentStateForCities: null,
    );
    log("✅ Cities cleared");
  }
}

final locationProviderReport =
    StateNotifierProvider<LocationNotifierReport, LocationStateReport>(
  (ref) => LocationNotifierReport(),
);
