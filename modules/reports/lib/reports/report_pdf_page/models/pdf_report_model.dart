import 'dart:math' as math;

import 'package:reports/reports/report_pdf_page/models/government_data_model.dart';

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

bool _toBool(dynamic value) {
  if (value == null) return false;
  if (value is bool) return value;

  final text = value.toString().trim().toLowerCase();
  return !{
    '',
    '0',
    'false',
    'no',
    'nie',
    'null',
    'none',
  }.contains(text);
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

List<Map<String, dynamic>> _asMapList(dynamic value) {
  if (value is! List) return [];
  return value
      .map((e) => _asMap(e))
      .whereType<Map<String, dynamic>>()
      .toList();
}

class PdfReportModel {
  final String? reportMode;
  final MarketContextData? marketContext;
  final ReportData? report;
  final PricesInArea? pricesInArea;
  final AccuracyIndex? accuracyIndex;
  final RentalData? rentalData;
  final LocationData? location;
  final EstimationData? estimation;
  final List<ComparableProperty>? comparable;
  final int? comparableCount;
  final int? comparablePreviewCount;
  final int? excludedDuplicateCount;
  final int? excludedOutlierCount;
  final GuardMeta? guardMeta;
  final DistributionChartData? pricePerM2Distribution;
  final DistributionChartData? adjustedTotalPriceDistribution;
  final MarketSnapshotData? saleMarket;
  final MarketSnapshotData? rentMarket;

  const PdfReportModel({
    this.reportMode,
    this.marketContext,
    this.report,
    this.pricesInArea,
    this.accuracyIndex,
    this.rentalData,
    this.location,
    this.estimation,
    this.comparable,
    this.comparableCount,
    this.comparablePreviewCount,
    this.excludedDuplicateCount,
    this.excludedOutlierCount,
    this.guardMeta,
    this.pricePerM2Distribution,
    this.adjustedTotalPriceDistribution,
    this.saleMarket,
    this.rentMarket,
  });

  factory PdfReportModel.fromJson(Map<String, dynamic> json) {
    return PdfReportModel(
      reportMode: json['report_mode']?.toString(),
      marketContext: _asMap(json['market_context']) != null
          ? MarketContextData.fromJson(_asMap(json['market_context'])!)
          : null,
      report: _asMap(json['report']) != null
          ? ReportData.fromJson(_asMap(json['report'])!)
          : null,
      pricesInArea: _asMap(json['prices_in_area']) != null
          ? PricesInArea.fromJson(_asMap(json['prices_in_area'])!)
          : null,
      accuracyIndex: _asMap(json['accuracy_index']) != null
          ? AccuracyIndex.fromJson(_asMap(json['accuracy_index'])!)
          : null,
      rentalData: _asMap(json['rental_data']) != null
          ? RentalData.fromJson(_asMap(json['rental_data'])!)
          : null,
      location: _asMap(json['location']) != null
          ? LocationData.fromJson(_asMap(json['location'])!)
          : null,
      estimation: _asMap(json['estimation']) != null
          ? EstimationData.fromJson(_asMap(json['estimation'])!)
          : null,
      comparable: json['comparable'] is List
          ? _asMapList(json['comparable'])
              .map(ComparableProperty.fromJson)
              .toList()
          : const [],
      comparableCount: _toInt(json['comparable_count']),
      comparablePreviewCount: _toInt(json['comparable_preview_count']),
      excludedDuplicateCount: _toInt(json['excluded_duplicate_count']),
      excludedOutlierCount: _toInt(json['excluded_outlier_count']),
      guardMeta: _asMap(json['guard_meta']) != null
          ? GuardMeta.fromJson(_asMap(json['guard_meta'])!)
          : null,
      pricePerM2Distribution: _asMap(json['price_per_m2_distribution']) != null
          ? DistributionChartData.fromJson(
              _asMap(json['price_per_m2_distribution'])!,
            )
          : null,
      adjustedTotalPriceDistribution:
          _asMap(json['adjusted_total_price_distribution']) != null
              ? DistributionChartData.fromJson(
                  _asMap(json['adjusted_total_price_distribution'])!,
                )
              : null,
      saleMarket: _asMap(json['sale_market']) != null
          ? MarketSnapshotData.fromJson(_asMap(json['sale_market'])!)
          : null,
      rentMarket: _asMap(json['rent_market']) != null
          ? MarketSnapshotData.fromJson(_asMap(json['rent_market'])!)
          : null,
    );
  }
}

class MarketContextData {
  final String? primaryOfferType;
  final int? previewLimit;
  final bool usedAllMatchesForCalculation;

  const MarketContextData({
    this.primaryOfferType,
    this.previewLimit,
    this.usedAllMatchesForCalculation = false,
  });

  factory MarketContextData.fromJson(Map<String, dynamic> json) {
    return MarketContextData(
      primaryOfferType: json['primary_offer_type']?.toString(),
      previewLimit: _toInt(json['preview_limit']),
      usedAllMatchesForCalculation:
          _toBool(json['used_all_matches_for_calculation']),
    );
  }
}

class ReportData {
  final int? id;
  final int? user;
  final String? streetAddress;
  final String? city;
  final String? state;
  final String? country;
  final String? zipcode;
  final double? distanceFilter;
  final double? lat;
  final double? lon;
  final String? propertyType;
  final String? typeOfBuilding;
  final String? buildingMaterial;
  final String? heatingType;
  final int? yearBuilt;
  final double? floorArea;
  final int? floorLevel;
  final int? bedrooms;
  final int? bathrooms;
  final bool hasBalcony;
  final bool hasElevator;
  final bool hasSauna;
  final bool hasParking;
  final bool hasGym;
  final bool hasAirConditioning;
  final bool hasGarden;
  final bool hasBasement;
  final bool hasHighways;
  final double? valueEstimate;
  final String? neighborhood;
  final String? distanceToPublicTransport;
  final String? boostProductivity;
  final String? currency;
  final double? pricePerSqm;
  final String? createdAt;
  final String? updatedAt;
  final String? sourceKind;
  final int? sourceAdvertisementId;
  final int? sourceNetworkAdId;
  final ReportGovernmentDataModel? governmentData;

  const ReportData({
    this.id,
    this.user,
    this.streetAddress,
    this.city,
    this.state,
    this.country,
    this.zipcode,
    this.distanceFilter,
    this.lat,
    this.lon,
    this.propertyType,
    this.typeOfBuilding,
    this.buildingMaterial,
    this.heatingType,
    this.yearBuilt,
    this.floorArea,
    this.floorLevel,
    this.bedrooms,
    this.bathrooms,
    this.hasBalcony = false,
    this.hasElevator = false,
    this.hasSauna = false,
    this.hasParking = false,
    this.hasGym = false,
    this.hasAirConditioning = false,
    this.hasGarden = false,
    this.hasBasement = false,
    this.hasHighways = false,
    this.valueEstimate,
    this.neighborhood,
    this.distanceToPublicTransport,
    this.boostProductivity,
    this.currency,
    this.pricePerSqm,
    this.createdAt,
    this.updatedAt,
    this.sourceKind,
    this.sourceAdvertisementId,
    this.sourceNetworkAdId,
    this.governmentData,
  });

  bool get hasCoordinates => lat != null && lon != null;

  factory ReportData.fromJson(Map<String, dynamic> json) {
    return ReportData(
      id: _toInt(json['id']),
      user: _toInt(json['user']),
      streetAddress: json['street_address']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      country: json['country']?.toString(),
      zipcode: json['zipcode']?.toString(),
      distanceFilter: _toDouble(json['distance_filter']),
      lat: _toDouble(json['lat']),
      lon: _toDouble(json['lon']),
      propertyType: json['property_type']?.toString(),
      typeOfBuilding: json['type_of_building']?.toString(),
      buildingMaterial: json['building_material']?.toString(),
      heatingType: json['heating_type']?.toString(),
      yearBuilt: _toInt(json['year_built']),
      floorArea: _toDouble(json['floor_area']),
      floorLevel: _toInt(json['floor_level']),
      bedrooms: _toInt(json['bedrooms']),
      bathrooms: _toInt(json['bathrooms']),
      hasBalcony: _toBool(json['has_balcony']),
      hasElevator: _toBool(json['has_elevator']),
      hasSauna: _toBool(json['has_sauna']),
      hasParking: _toBool(json['has_parking']),
      hasGym: _toBool(json['has_gym']),
      hasAirConditioning: _toBool(json['has_air_conditioning']),
      hasGarden: _toBool(json['has_garden']),
      hasBasement: _toBool(json['has_basement']),
      hasHighways: _toBool(json['has_highways']),
      valueEstimate: _toDouble(json['value_estimate']),
      neighborhood: json['neighborhood']?.toString(),
      distanceToPublicTransport:
          json['distance_to_public_transport']?.toString(),
      boostProductivity: json['boost_productivity']?.toString(),
      currency: json['currency']?.toString(),
      pricePerSqm: _toDouble(json['price_per_sqm']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      sourceKind: json['source_kind']?.toString(),
      sourceAdvertisementId: _toInt(json['source_advertisement_id']),
      sourceNetworkAdId: _toInt(json['source_network_ad_id']),
      governmentData: _asMap(json['government_data']) != null
          ? ReportGovernmentDataModel.fromJson(_asMap(json['government_data'])!)
          : null,
    );
  }
}


class PricesInArea {
  final String? offerType;
  final double? minPrice;
  final double? averagePrice;
  final double? maxPrice;
  final String? currency;
  final int? sampleSize;
  final bool usedAllMatches;
  final int? excludedDuplicateCount;
  final int? excludedOutlierCount;
  final GuardMeta? guardMeta;

  const PricesInArea({
    this.offerType,
    this.minPrice,
    this.averagePrice,
    this.maxPrice,
    this.currency,
    this.sampleSize,
    this.usedAllMatches = false,
    this.excludedDuplicateCount,
    this.excludedOutlierCount,
    this.guardMeta,
  });

  factory PricesInArea.fromJson(Map<String, dynamic> json) {
    return PricesInArea(
      offerType: json['offer_type']?.toString(),
      minPrice: _toDouble(json['min_price']),
      averagePrice: _toDouble(json['average_price']),
      maxPrice: _toDouble(json['max_price']),
      currency: json['currency']?.toString(),
      sampleSize: _toInt(json['sample_size']),
      usedAllMatches: _toBool(json['used_all_matches']),
      excludedDuplicateCount: _toInt(json['excluded_duplicate_count']),
      excludedOutlierCount: _toInt(json['excluded_outlier_count']),
      guardMeta: _asMap(json['guard_meta']) != null
          ? GuardMeta.fromJson(_asMap(json['guard_meta'])!)
          : null,
    );
  }
}

class AccuracyIndex {
  final double? percentage;
  final double? areaM2;
  final int? offersCount;
  final double? medianAreaDeltaPct;

  const AccuracyIndex({
    this.percentage,
    this.areaM2,
    this.offersCount,
    this.medianAreaDeltaPct,
  });

  factory AccuracyIndex.fromJson(Map<String, dynamic> json) {
    return AccuracyIndex(
      percentage: _toDouble(json['percentage']),
      areaM2: _toDouble(json['area_m2']),
      offersCount: _toInt(json['offers_count']),
      medianAreaDeltaPct: _toDouble(json['median_area_delta_pct']),
    );
  }
}

class RentalRoiData {
  final double? referenceSaleValue;
  final double? grossYieldPct;
  final double? netYieldPct;
  final double? annualNetIncome;
  final double? monthlyNetIncome;

  const RentalRoiData({
    this.referenceSaleValue,
    this.grossYieldPct,
    this.netYieldPct,
    this.annualNetIncome,
    this.monthlyNetIncome,
  });

  factory RentalRoiData.fromJson(Map<String, dynamic> json) {
    return RentalRoiData(
      referenceSaleValue: _toDouble(json['reference_sale_value']),
      grossYieldPct: _toDouble(json['gross_yield_pct']),
      netYieldPct: _toDouble(json['net_yield_pct']),
      annualNetIncome: _toDouble(json['annual_net_income']),
      monthlyNetIncome: _toDouble(json['monthly_net_income']),
    );
  }
}

class RentalData {
  final String? offerType;
  final double? rental;
  final double? administrativeFees;
  final double? estimatedRentalPrice;
  final String? currency;
  final int? sampleSize;
  final bool usedAllMatches;
  final int? excludedDuplicateCount;
  final int? excludedOutlierCount;
  final GuardMeta? guardMeta;
  final RentalRoiData? roi;

  const RentalData({
    this.offerType,
    this.rental,
    this.administrativeFees,
    this.estimatedRentalPrice,
    this.currency,
    this.sampleSize,
    this.usedAllMatches = false,
    this.excludedDuplicateCount,
    this.excludedOutlierCount,
    this.guardMeta,
    this.roi,
  });

  factory RentalData.fromJson(Map<String, dynamic> json) {
    return RentalData(
      offerType: json['offer_type']?.toString(),
      rental: _toDouble(json['rental']),
      administrativeFees: _toDouble(json['administrative_fees']),
      estimatedRentalPrice: _toDouble(json['estimated_rental_price']),
      currency: json['currency']?.toString(),
      sampleSize: _toInt(json['sample_size']),
      usedAllMatches: _toBool(json['used_all_matches']),
      excludedDuplicateCount: _toInt(json['excluded_duplicate_count']),
      excludedOutlierCount: _toInt(json['excluded_outlier_count']),
      guardMeta: _asMap(json['guard_meta']) != null
          ? GuardMeta.fromJson(_asMap(json['guard_meta'])!)
          : null,
      roi: _asMap(json['roi']) != null
          ? RentalRoiData.fromJson(_asMap(json['roi'])!)
          : null,
    );
  }
}

class LocationData {
  final String? address;
  final String? fullAddress;
  final String? city;
  final String? state;
  final String? country;
  final String? zipcode;
  final String? neighborhood;
  final double? lat;
  final double? lon;

  const LocationData({
    this.address,
    this.fullAddress,
    this.city,
    this.state,
    this.country,
    this.zipcode,
    this.neighborhood,
    this.lat,
    this.lon,
  });

  bool get hasCoordinates => lat != null && lon != null;

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      address: json['address']?.toString(),
      fullAddress: json['full_address']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      country: json['country']?.toString(),
      zipcode: json['zipcode']?.toString(),
      neighborhood: json['neighborhood']?.toString(),
      lat: _toDouble(json['lat']),
      lon: _toDouble(json['lon']),
    );
  }
}

class EstimationData {
  final String? offerType;
  final double? estimatedValue;
  final double? estimatedPricePerM2;
  final double? lowValue;
  final double? highValue;
  final int? comparablesUsed;
  final double? confidence;
  final String? currency;
  final bool usedAllMatches;
  final int? previewLimit;
  final int? totalComparablesFound;

  const EstimationData({
    this.offerType,
    this.estimatedValue,
    this.estimatedPricePerM2,
    this.lowValue,
    this.highValue,
    this.comparablesUsed,
    this.confidence,
    this.currency,
    this.usedAllMatches = false,
    this.previewLimit,
    this.totalComparablesFound,
  });

  factory EstimationData.fromJson(Map<String, dynamic> json) {
    return EstimationData(
      offerType: json['offer_type']?.toString(),
      estimatedValue: _toDouble(json['estimated_value']),
      estimatedPricePerM2: _toDouble(json['estimated_price_per_m2']),
      lowValue: _toDouble(json['low_value']),
      highValue: _toDouble(json['high_value']),
      comparablesUsed: _toInt(json['comparables_used']),
      confidence: _toDouble(json['confidence']),
      currency: json['currency']?.toString(),
      usedAllMatches: _toBool(json['used_all_matches']),
      previewLimit: _toInt(json['preview_limit']),
      totalComparablesFound: _toInt(json['total_comparables_found']),
    );
  }
}

class ComparableProperty {
  final int? id;
  final String? title;
  final String? link;
  final String? offerType;
  final String? city;
  final String? district;
  final String? street;
  final int? rooms;
  final int? bathrooms;
  final int? floor;
  final double? floorArea;
  final double? price;
  final double? pricePerM2;
  final String? currency;
  final double? similarityScore;
  final double? areaDeltaPct;
  final double? priceDeltaPct;

  const ComparableProperty({
    this.id,
    this.title,
    this.link,
    this.offerType,
    this.city,
    this.district,
    this.street,
    this.rooms,
    this.bathrooms,
    this.floor,
    this.floorArea,
    this.price,
    this.pricePerM2,
    this.currency,
    this.similarityScore,
    this.areaDeltaPct,
    this.priceDeltaPct,
  });

  String get fullAddress {
    final parts = [street, district, city]
        .where((e) => e != null && e!.trim().isNotEmpty)
        .cast<String>()
        .toList();
    return parts.join(', ');
  }

  factory ComparableProperty.fromJson(Map<String, dynamic> json) {
    return ComparableProperty(
      id: _toInt(json['id']),
      title: json['title']?.toString(),
      link: json['link']?.toString(),
      offerType: json['offer_type']?.toString(),
      city: json['city']?.toString(),
      district: json['district']?.toString(),
      street: json['street']?.toString(),
      rooms: _toInt(json['rooms']),
      bathrooms: _toInt(json['bathrooms']),
      floor: _toInt(json['floor']),
      floorArea: _toDouble(json['floor_area']),
      price: _toDouble(json['price']),
      pricePerM2: _toDouble(json['price_per_m2'] ?? json['price_per_meter']),
      currency: json['currency']?.toString(),
      similarityScore: _toDouble(json['similarity_score']),
      areaDeltaPct: _toDouble(json['area_delta_pct']),
      priceDeltaPct: _toDouble(json['price_delta_pct']),
    );
  }
}

class GuardBranchMeta {
  final bool enabled;
  final String? reason;
  final int? sampleSize;
  final int? duplicateCount;
  final List<int> duplicateIds;
  final int? excludedCount;
  final double? medianPricePerM2;
  final double? lowCutoffPricePerM2;
  final double? highCutoffPricePerM2;
  final List<int> excludedIds;

  const GuardBranchMeta({
    this.enabled = false,
    this.reason,
    this.sampleSize,
    this.duplicateCount,
    this.duplicateIds = const [],
    this.excludedCount,
    this.medianPricePerM2,
    this.lowCutoffPricePerM2,
    this.highCutoffPricePerM2,
    this.excludedIds = const [],
  });

  factory GuardBranchMeta.fromJson(Map<String, dynamic> json) {
    return GuardBranchMeta(
      enabled: _toBool(json['enabled']),
      reason: json['reason']?.toString(),
      sampleSize: _toInt(json['sample_size']),
      duplicateCount: _toInt(json['duplicate_count']),
      duplicateIds: (json['duplicate_ids'] is List)
          ? (json['duplicate_ids'] as List)
              .map(_toInt)
              .whereType<int>()
              .toList()
          : const [],
      excludedCount: _toInt(json['excluded_count']),
      medianPricePerM2: _toDouble(json['median_price_per_m2']),
      lowCutoffPricePerM2: _toDouble(json['low_cutoff_price_per_m2']),
      highCutoffPricePerM2: _toDouble(json['high_cutoff_price_per_m2']),
      excludedIds: (json['excluded_ids'] is List)
          ? (json['excluded_ids'] as List)
              .map(_toInt)
              .whereType<int>()
              .toList()
          : const [],
    );
  }
}

class GuardMeta {
  final GuardBranchMeta? dedupe;
  final GuardBranchMeta? outliers;
  final int? excludedDuplicateCount;
  final int? excludedOutlierCount;
  final int? excludedTotalCount;

  const GuardMeta({
    this.dedupe,
    this.outliers,
    this.excludedDuplicateCount,
    this.excludedOutlierCount,
    this.excludedTotalCount,
  });

  factory GuardMeta.fromJson(Map<String, dynamic> json) {
    return GuardMeta(
      dedupe: _asMap(json['dedupe']) != null
          ? GuardBranchMeta.fromJson(_asMap(json['dedupe'])!)
          : null,
      outliers: _asMap(json['outliers']) != null
          ? GuardBranchMeta.fromJson(_asMap(json['outliers'])!)
          : null,
      excludedDuplicateCount: _toInt(json['excluded_duplicate_count']),
      excludedOutlierCount: _toInt(json['excluded_outlier_count']),
      excludedTotalCount: _toInt(json['excluded_total_count']),
    );
  }
}

class DistributionChartBin {
  final int index;
  final double? fromValue;
  final double? toValue;
  final int count;

  const DistributionChartBin({
    required this.index,
    this.fromValue,
    this.toValue,
    required this.count,
  });

  factory DistributionChartBin.fromJson(Map<String, dynamic> json) {
    return DistributionChartBin(
      index: _toInt(json['index']) ?? 0,
      fromValue: _toDouble(json['from_value']),
      toValue: _toDouble(json['to_value']),
      count: _toInt(json['count']) ?? 0,
    );
  }
}

class DistributionChartData {
  final String? title;
  final String? description;
  final String? valueLabel;
  final String? unitLabel;
  final int sampleSize;
  final int bucketCount;
  final double? minValue;
  final double? averageValue;
  final double? medianValue;
  final double? maxValue;
  final double? subjectValue;
  final int? subjectBinIndex;
  final double? subjectVsMedianPct;
  final String? subjectPositionLabel;
  final String? subjectValueSource;
  final List<DistributionChartBin> bins;

  const DistributionChartData({
    this.title,
    this.description,
    this.valueLabel,
    this.unitLabel,
    this.sampleSize = 0,
    this.bucketCount = 0,
    this.minValue,
    this.averageValue,
    this.medianValue,
    this.maxValue,
    this.subjectValue,
    this.subjectBinIndex,
    this.subjectVsMedianPct,
    this.subjectPositionLabel,
    this.subjectValueSource,
    this.bins = const [],
  });

  int get maxBinCount {
    if (bins.isEmpty) return 0;
    return bins.map((e) => e.count).reduce(math.max);
  }

  bool get hasData => bins.isNotEmpty;

  factory DistributionChartData.fromJson(Map<String, dynamic> json) {
    return DistributionChartData(
      title: json['title']?.toString(),
      description: json['description']?.toString(),
      valueLabel: json['value_label']?.toString(),
      unitLabel: json['unit_label']?.toString(),
      sampleSize: _toInt(json['sample_size']) ?? 0,
      bucketCount: _toInt(json['bucket_count']) ?? 0,
      minValue: _toDouble(json['min_value']),
      averageValue: _toDouble(json['average_value']),
      medianValue: _toDouble(json['median_value']),
      maxValue: _toDouble(json['max_value']),
      subjectValue: _toDouble(json['subject_value']),
      subjectBinIndex: _toInt(json['subject_bin_index']),
      subjectVsMedianPct: _toDouble(json['subject_vs_median_pct']),
      subjectPositionLabel: json['subject_position_label']?.toString(),
      subjectValueSource: json['subject_value_source']?.toString(),
      bins: (json['bins'] is List)
          ? _asMapList(json['bins'])
              .map(DistributionChartBin.fromJson)
              .toList()
          : const [],
    );
  }
}

class MarketSnapshotData {
  final String? offerType;
  final PricesInArea? pricesInArea;
  final AccuracyIndex? accuracyIndex;
  final EstimationData? estimation;
  final List<ComparableProperty> comparable;
  final int? comparableCount;
  final int? comparablePreviewCount;
  final int? excludedDuplicateCount;
  final int? excludedOutlierCount;
  final GuardMeta? guardMeta;
  final DistributionChartData? pricePerM2Distribution;
  final DistributionChartData? adjustedTotalPriceDistribution;

  const MarketSnapshotData({
    this.offerType,
    this.pricesInArea,
    this.accuracyIndex,
    this.estimation,
    this.comparable = const [],
    this.comparableCount,
    this.comparablePreviewCount,
    this.excludedDuplicateCount,
    this.excludedOutlierCount,
    this.guardMeta,
    this.pricePerM2Distribution,
    this.adjustedTotalPriceDistribution,
  });

  factory MarketSnapshotData.fromJson(Map<String, dynamic> json) {
    return MarketSnapshotData(
      offerType: json['offer_type']?.toString(),
      pricesInArea: _asMap(json['prices_in_area']) != null
          ? PricesInArea.fromJson(_asMap(json['prices_in_area'])!)
          : null,
      accuracyIndex: _asMap(json['accuracy_index']) != null
          ? AccuracyIndex.fromJson(_asMap(json['accuracy_index'])!)
          : null,
      estimation: _asMap(json['estimation']) != null
          ? EstimationData.fromJson(_asMap(json['estimation'])!)
          : null,
      comparable: (json['comparable'] is List)
          ? _asMapList(json['comparable'])
              .map(ComparableProperty.fromJson)
              .toList()
          : const [],
      comparableCount: _toInt(json['comparable_count']),
      comparablePreviewCount: _toInt(json['comparable_preview_count']),
      excludedDuplicateCount: _toInt(json['excluded_duplicate_count']),
      excludedOutlierCount: _toInt(json['excluded_outlier_count']),
      guardMeta: _asMap(json['guard_meta']) != null
          ? GuardMeta.fromJson(_asMap(json['guard_meta'])!)
          : null,
      pricePerM2Distribution: _asMap(json['price_per_m2_distribution']) != null
          ? DistributionChartData.fromJson(
              _asMap(json['price_per_m2_distribution'])!,
            )
          : null,
      adjustedTotalPriceDistribution:
          _asMap(json['adjusted_total_price_distribution']) != null
              ? DistributionChartData.fromJson(
                  _asMap(json['adjusted_total_price_distribution'])!,
                )
              : null,
    );
  }
}