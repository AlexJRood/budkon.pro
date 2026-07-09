import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/common/shared_widgets/country_model.dart';

final propertyValuationFormProvider = StateNotifierProvider<
  PropertyValuationFormNotifier,
  PropertyValuationFormState
>((ref) {
  return PropertyValuationFormNotifier();
});

class PropertyValuationFormState {
  final DropDownCountry? country;
  final String? state;
  final String? city;
  final String? streetAddress;
  final String? zipcode;
  final double? distanceFilter;
  final String? propertyType;
  final String? keyPropertyFeatures;
  final String? typeOfBuilding;
  final String? buildingMaterial;
  final String? heatingType;
  final int? yearBuilt;
  final double? floorArea;
  final int floorLevel;
  final int bedrooms;
  final int bathrooms;
  final bool hasBalcony;
  final bool hasElevator;
  final bool hasSauna;
  final bool hasParking;
  final bool hasGym;
  final bool hasAirConditioning;
  final bool hasGarden;
  final bool hasBasement;
  final bool hasHighwayAccess;
  final String? boostProductivity;
  final List<String> additionalFeatures;

  // Controllers
  final TextEditingController streetAddressController;
  final TextEditingController zipcodeController;
  final TextEditingController yearBuiltController;
  final TextEditingController floorAreaController;
  final TextEditingController floorLevelController;
  final TextEditingController neighborhoodController;
  final TextEditingController distanceToPublicTransportController;
  final TextEditingController exclusiveController;
  final TextEditingController boostProductivityFacilityController;
  final TextEditingController pricePerSqmController;
 


  PropertyValuationFormState({
    this.country,
    this.state,
    this.city,
    this.streetAddress,
    this.zipcode,
    this.distanceFilter = 0,
    this.propertyType = 'All types',
    this.keyPropertyFeatures,
    this.typeOfBuilding,
    this.buildingMaterial,
    this.heatingType,
    this.yearBuilt,
    this.floorArea,
    this.floorLevel=0,
    this.bedrooms = 2147483647,
    this.bathrooms = 2147483647,
    this.hasBalcony = false,
    this.hasElevator = false,
    this.hasSauna = false,
    this.hasParking = false,
    this.hasGym = false,
    this.hasAirConditioning = false,
    this.hasGarden = false,
    this.hasBasement = false,
    this.hasHighwayAccess = false,
    this.boostProductivity,
    this.additionalFeatures = const [],
    TextEditingController? streetAddressController,
    TextEditingController? zipcodeController,
    TextEditingController? yearBuiltController,
    TextEditingController? floorAreaController,
    TextEditingController? floorLevelController,
    TextEditingController? neighborhoodController,
    TextEditingController? distanceToPublicTransportController,
    TextEditingController? exclusiveController,
    TextEditingController? boostProductivityFacilityController,
    TextEditingController? pricePerSqmController,

  }) : streetAddressController =
           streetAddressController ?? TextEditingController(),
       zipcodeController = zipcodeController ?? TextEditingController(),
       yearBuiltController = yearBuiltController ?? TextEditingController(),
       floorAreaController = floorAreaController ?? TextEditingController(),
       floorLevelController = floorLevelController ?? TextEditingController(),
       neighborhoodController = neighborhoodController ?? TextEditingController(),
       distanceToPublicTransportController = distanceToPublicTransportController ?? TextEditingController(),
       exclusiveController = exclusiveController ?? TextEditingController(),
       boostProductivityFacilityController = boostProductivityFacilityController ?? TextEditingController(),
       pricePerSqmController = pricePerSqmController ?? TextEditingController();
     

  PropertyValuationFormState copyWith({
    DropDownCountry? country,
    String? state,
    String? city,
    String? streetAddress,
    String? zipcode,
    double? distanceFilter,
    String? propertyType,
    String? keyPropertyFeatures,
    String? typeOfBuilding,
    String? buildingMaterial,
    String? heatingType,
    int? bedrooms,
    int? bathrooms,
    bool? hasBalcony,
    bool? hasElevator,
    bool? hasSauna,
    bool? hasParking,
    bool? hasGym,
    bool? hasAirConditioning,
    bool? hasGarden,
    bool? hasBasement,
    bool? hasHighwayAccess,
    String? boostProductivity,
    List<String>? additionalFeatures,
    TextEditingController? streetAddressController,
    TextEditingController? zipcodeController,
    TextEditingController? yearBuiltController,
    TextEditingController? floorAreaController,
    TextEditingController? floorLevelController,
    TextEditingController? neighborhoodController,
    TextEditingController? distanceToPublicTransportController,
    TextEditingController? exclusiveController,
    TextEditingController? boostProductivityFacilityController,
    TextEditingController? pricePerSqmController,

  }) {
    return PropertyValuationFormState(
      country: country ?? this.country,
      state: state ?? this.state,
      city: city ?? this.city,
      streetAddress: streetAddress ?? this.streetAddress,
      zipcode: zipcode ?? this.zipcode,
      distanceFilter: distanceFilter ?? this.distanceFilter,
      propertyType: propertyType ?? this.propertyType,
      keyPropertyFeatures: keyPropertyFeatures ?? this.keyPropertyFeatures,
      typeOfBuilding: typeOfBuilding ?? this.typeOfBuilding,
      buildingMaterial: buildingMaterial ?? this.buildingMaterial,
      heatingType: heatingType ?? this.heatingType,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      hasBalcony: hasBalcony ?? this.hasBalcony,
      hasElevator: hasElevator ?? this.hasElevator,
      hasSauna: hasSauna ?? this.hasSauna,
      hasParking: hasParking ?? this.hasParking,
      hasGym: hasGym ?? this.hasGym,
      hasAirConditioning: hasAirConditioning ?? this.hasAirConditioning,
      hasGarden: hasGarden ?? this.hasGarden,
      hasBasement: hasBasement ?? this.hasBasement,
      hasHighwayAccess: hasHighwayAccess ?? this.hasHighwayAccess,
      boostProductivity: boostProductivity ?? this.boostProductivity,
      additionalFeatures: additionalFeatures ?? this.additionalFeatures,
      streetAddressController:
          streetAddressController ?? this.streetAddressController,
      zipcodeController: zipcodeController ?? this.zipcodeController,
      yearBuiltController: yearBuiltController ?? this.yearBuiltController,
      floorAreaController: floorAreaController ?? this.floorAreaController,
      floorLevelController: floorLevelController ?? this.floorLevelController,
      neighborhoodController: neighborhoodController ?? this.neighborhoodController,
      distanceToPublicTransportController: distanceToPublicTransportController ?? this.distanceToPublicTransportController,
      exclusiveController: exclusiveController ?? this.exclusiveController,
      boostProductivityFacilityController: boostProductivityFacilityController ?? this.boostProductivityFacilityController,
      pricePerSqmController: pricePerSqmController ?? this.pricePerSqmController,
     
    );
  }
}

class PropertyValuationFormNotifier
    extends StateNotifier<PropertyValuationFormState> {
  PropertyValuationFormNotifier()
    : super(
        PropertyValuationFormState(
          country: DropDownCountry(name: '', isoCode: '', phoneCode: ''),
          state: '',
          city: '',
          streetAddress: '',
          zipcode: '',
          distanceFilter: 0,
          propertyType: 'All types',
          keyPropertyFeatures: '',
          typeOfBuilding: '',
          buildingMaterial: '',
          heatingType: '',
          yearBuilt: null,
          floorArea: null,
          floorLevel: 0,
          bedrooms: 2147483647,
          bathrooms: 2147483647,
          hasBalcony: false,
          hasElevator: false,
          hasSauna: false,
          hasParking: false,
          hasGym: false,
          hasAirConditioning: false,
          hasGarden: false,
          hasBasement: false,
          hasHighwayAccess: false,
          boostProductivity: null,
          additionalFeatures: [],
        ),
      );

  void resetFields() {
    state = PropertyValuationFormState(
      country: DropDownCountry(name: '', isoCode: '', phoneCode: ''),
      state: '',
      city: '',
      streetAddress: '',
      zipcode: '',
      distanceFilter: 1.0,
      propertyType: 'All types',
      keyPropertyFeatures: '',
      typeOfBuilding: '',
      buildingMaterial: '',
      heatingType: '',
      yearBuilt: null,
      floorArea: null,
      floorLevel: 0,
      bedrooms: 2147483647,
      bathrooms: 2147483647,
      hasBalcony: false,
      hasElevator: false,
      hasSauna: false,
      hasParking: false,
      hasGym: false,
      hasAirConditioning: false,
      hasGarden: false,
      hasBasement: false,
      hasHighwayAccess: false,
      boostProductivity: null,
      additionalFeatures: [],
    );
  }

  void updateField(String key, dynamic value) {
    switch (key) {
      case 'country':
        state = state.copyWith(country: value);
        break;
      case 'state':
        state = state.copyWith(state: value);
        break;
      case 'city':
        state = state.copyWith(city: value);
        break;
      case 'streetAddress':
        state = state.copyWith(
          streetAddress: value,
          streetAddressController: TextEditingController(text: value),
        );
        break;
      case 'zipcode':
        state = state.copyWith(
          zipcode: value,
          zipcodeController: TextEditingController(text: value),
        );
        break;
      case 'distanceFilter':
        state = state.copyWith(distanceFilter: value);
        break;
      case 'propertyType':
        state = state.copyWith(propertyType: value);
        break;
      case 'keyPropertyFeatures':
        state = state.copyWith(
          keyPropertyFeatures: value,
         
        );
        break;
      case 'building_type':
        state = state.copyWith(
          typeOfBuilding: value,
          
        );
        break;
      case 'building_material':
        state = state.copyWith(
          buildingMaterial: value,
          
        );
        break;
      case 'heating_type':
        state = state.copyWith(
          heatingType: value,
          
        );
        break;
      case 'bedrooms':
        state = state.copyWith(bedrooms: value);
        break;
      case 'bathrooms':
        state = state.copyWith(bathrooms: value);
        break;

      case 'neighborhood':
        state.neighborhoodController.text = value ?? '';
        break;
      case 'distanceToPublicTransport':
        state.distanceToPublicTransportController.text = value ?? '';
        break;
      case 'hasHighwayAccess':
        state = state.copyWith(hasHighwayAccess: value);
        break;
      case 'boostProductivity':
        state = state.copyWith(boostProductivity: value);
        break;
      case 'exclusive':
        state.exclusiveController.text = value ?? '';
        break;
      case 'boostProductivityFacility':
        state.boostProductivityFacilityController.text = value ?? '';
        break;
      case 'pricePerSqm':
        state.pricePerSqmController.text = value ?? '';
        break;
      default:
        break;
    }
    log('Updated field $key: $value');
  }

  void toggleAdditionalFeature(String feature) {
    final features = List<String>.from(state.additionalFeatures);

    final isRemoving = features.contains(feature);
    if (isRemoving) {
      features.remove(feature);
    } else {
      features.add(feature);
    }

    // Update feature list
    state = state.copyWith(additionalFeatures: features);

    // Toggle corresponding boolean if it's a known mapped feature
    switch (feature) {
      case 'Parking':
        state = state.copyWith(hasParking: !isRemoving);
        break;
      case 'Sauna':
        state = state.copyWith(hasSauna: !isRemoving);
        break;
      case 'Balcony':
        state = state.copyWith(hasBalcony: !isRemoving);
        break;
      case 'Elevator':
        state = state.copyWith(hasElevator: !isRemoving);
        break;

      case 'Gym':
        state = state.copyWith(hasGym: !isRemoving);
        break;
      case 'Air Conditioning':
        state = state.copyWith(hasAirConditioning: !isRemoving);
        break;
      case 'Garden':
        state = state.copyWith(hasGarden: !isRemoving);
        break;
      case 'hasBasement':
        state = state.copyWith(hasBasement: !isRemoving);
        break;
      // Add more mappings here as needed
    }

    log('Toggled additional feature: $feature');
    log('Updated features list: ${state.hasBalcony}');
  }
}
