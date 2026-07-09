import 'package:flutter/material.dart';

class ReportsListModel {
  final int? id;
  final int? user;
  final String? country;
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
  final String? neighborhood;
  final String? distanceToPublicTransport;
  final bool hasHighways;
  final String? boostProductivity;
  final List<String> additionalFeatures;
  final double? valueEstimate;
  final String? currency;
  final String? recentSalesData;
  final String? createdAt;
  final String? updatedAt;
  final double? pricePerSqm;

  // Controllers
  final TextEditingController streetAddressController;
  final TextEditingController zipcodeController;

  ReportsListModel({
    this.id,
    this.user,
    this.currency,
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
    this.floorLevel = 0,
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
    this.neighborhood,
    this.distanceToPublicTransport,
    this.hasHighways = false,
    this.boostProductivity,
    this.additionalFeatures = const [],
    this.valueEstimate,
    this.recentSalesData,
    this.createdAt,
    this.updatedAt,
    this.pricePerSqm,
    TextEditingController? streetAddressController,
    TextEditingController? zipcodeController,
  }) : streetAddressController =
            streetAddressController ?? TextEditingController(),
        zipcodeController = zipcodeController ?? TextEditingController();

  factory ReportsListModel.fromJson(Map<String, dynamic> json) {
    return ReportsListModel(
      id: json['id'] as int?,
      user: json['user'] as int?,
      country: json['country'] as String?,
      currency: json['currency'] as String?,
      state: json['state'] as String?,
      city: json['city'] as String?,
      streetAddress: json['street_address'] as String?,
      zipcode: json['zipcode'] as String?,
      distanceFilter: (json['distance_filter'] as num?)?.toDouble(),
      propertyType: json['property_type'] as String?,
      keyPropertyFeatures: null, // Not present in JSON
      typeOfBuilding: json['type_of_building'] as String?,
      buildingMaterial: json['building_material'] as String?,
      heatingType: json['heating_type'] as String?,
      yearBuilt: json['year_built'] as int?,
      floorArea: (json['floor_area'] as num?)?.toDouble(),
      floorLevel: json['floor_level'] as int? ?? 0,
      bedrooms: json['bedrooms'] as int? ?? 2147483647,
      bathrooms: json['bathrooms'] as int? ?? 2147483647,
      hasBalcony: json['has_balcony'] as bool? ?? false,
      hasElevator: json['has_elevator'] as bool? ?? false,
      hasSauna: json['has_sauna'] as bool? ?? false,
      hasParking: json['has_parking'] as bool? ?? false,
      hasGym: json['has_gym'] as bool? ?? false,
      hasAirConditioning: json['has_air_conditioning'] as bool? ?? false,
      hasGarden: json['has_garden'] as bool? ?? false,
      hasBasement: json['has_basement'] as bool? ?? false,
      neighborhood: json['neighborhood'] as String?,
      distanceToPublicTransport: json['distance_to_public_transport'] as String?,
      hasHighways: json['has_highways'] as bool? ?? false,
      boostProductivity: json['boost_productivity'] as String?,
      additionalFeatures: const [], // Not present in JSON
      valueEstimate: (json['value_estimate'] as num?)?.toDouble(),
      recentSalesData: json['recent_sales_data'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      pricePerSqm: (json['price_per_sqm'] as num?)?.toDouble(),
    );
  }

  ReportsListModel copyWith({
    String? country,
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
    int? yearBuilt,
    double? floorArea,
    int? floorLevel,
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
    String? neighborhood,
    String? distanceToPublicTransport,
    bool? hasHighways,
    String? boostProductivity,
    List<String>? additionalFeatures,
    TextEditingController? streetAddressController,
    TextEditingController? zipcodeController,
  }) {
    return ReportsListModel(
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
      yearBuilt: yearBuilt ?? this.yearBuilt,
      floorArea: floorArea ?? this.floorArea,
      floorLevel: floorLevel ?? this.floorLevel,
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
      neighborhood: neighborhood ?? this.neighborhood,
      distanceToPublicTransport:
          distanceToPublicTransport ?? this.distanceToPublicTransport,
      hasHighways: hasHighways ?? this.hasHighways,
      boostProductivity: boostProductivity ?? this.boostProductivity,
      additionalFeatures: additionalFeatures ?? this.additionalFeatures,
      streetAddressController:
          streetAddressController ?? this.streetAddressController,
      zipcodeController: zipcodeController ?? this.zipcodeController,
    );
  }
}