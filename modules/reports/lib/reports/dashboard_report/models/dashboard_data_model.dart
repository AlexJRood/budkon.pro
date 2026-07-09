class DashboardData {
  final String currency;
  final List<String> focusCities;
  final DashboardOverview overview;
  final List<PriceTrendPoint> priceTrend;
  final MarketVelocity marketVelocity;
  final List<MarketPressureCity> marketPressure;
  final List<CategoryActivity> categoryActivity;
  final List<LastReport> lastReports;

  DashboardData({
    required this.currency,
    required this.focusCities,
    required this.overview,
    required this.priceTrend,
    required this.marketVelocity,
    required this.marketPressure,
    required this.categoryActivity,
    required this.lastReports,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final root = _asMap(json['data']) ?? json;
    final marketVelocityPayload = _extractMarketVelocityPayload(root);

    return DashboardData(
      currency: root['currency']?.toString() ?? 'PLN',
      focusCities:
          _asList(root['focus_cities']).map((e) => e.toString()).toList(),
      overview: DashboardOverview.fromJson(
        _asMap(root['overview']) ?? const <String, dynamic>{},
      ),
      priceTrend:
          _asList(root['price_trend'])
              .map((e) => PriceTrendPoint.fromJson(_asMap(e) ?? const {}))
              .toList(),
      marketVelocity: MarketVelocity.fromJson(marketVelocityPayload),
      marketPressure:
          _asList(root['market_pressure'])
              .map(
                (e) => MarketPressureCity.fromJson(_asMap(e) ?? const {}),
              )
              .toList(),
      categoryActivity:
          _asList(root['category_activity'])
              .map((e) => CategoryActivity.fromJson(_asMap(e) ?? const {}))
              .toList(),
      lastReports:
          _asList(root['last_reports'])
              .map((e) => LastReport.fromJson(_asMap(e) ?? const {}))
              .toList(),
    );
  }
}

class DashboardOverview {
  final int activeInventory;
  final int newListings7d;
  final int previousNewListings7d;
  final double? newListings7dChangePct;
  final int removedListings7d;
  final int previousRemovedListings7d;
  final double? removedListings7dChangePct;
  final double? averagePricePerSqm;
  final double? previousAveragePricePerSqm;
  final double? averagePriceChangePct;
  final double? medianDisappearanceDays;
  final double? previousMedianDisappearanceDays;
  final double? medianDisappearanceDaysChangePct;
  final String currency;

  DashboardOverview({
    required this.activeInventory,
    required this.newListings7d,
    required this.previousNewListings7d,
    required this.newListings7dChangePct,
    required this.removedListings7d,
    required this.previousRemovedListings7d,
    required this.removedListings7dChangePct,
    required this.averagePricePerSqm,
    required this.previousAveragePricePerSqm,
    required this.averagePriceChangePct,
    required this.medianDisappearanceDays,
    required this.previousMedianDisappearanceDays,
    required this.medianDisappearanceDaysChangePct,
    required this.currency,
  });

  factory DashboardOverview.fromJson(Map<String, dynamic> json) {
    return DashboardOverview(
      activeInventory: _asInt(json['active_inventory']),
      newListings7d: _asInt(json['new_listings_7d']),
      previousNewListings7d: _asInt(json['previous_new_listings_7d']),
      newListings7dChangePct: _asNullableDouble(
        json['new_listings_7d_change_pct'],
      ),
      removedListings7d: _asInt(json['removed_listings_7d']),
      previousRemovedListings7d: _asInt(json['previous_removed_listings_7d']),
      removedListings7dChangePct: _asNullableDouble(
        json['removed_listings_7d_change_pct'],
      ),
      averagePricePerSqm: _asNullableDouble(json['average_price_per_sqm']),
      previousAveragePricePerSqm: _asNullableDouble(
        json['previous_average_price_per_sqm'],
      ),
      averagePriceChangePct: _asNullableDouble(
        json['average_price_change_pct'],
      ),
      medianDisappearanceDays: _asNullableDouble(
        json['median_disappearance_days'],
      ),
      previousMedianDisappearanceDays: _asNullableDouble(
        json['previous_median_disappearance_days'],
      ),
      medianDisappearanceDaysChangePct: _asNullableDouble(
        json['median_disappearance_days_change_pct'],
      ),
      currency: json['currency']?.toString() ?? 'PLN',
    );
  }
}

class PriceTrendPoint {
  final String periodKey;
  final String periodLabel;
  final String propertyType;
  final double averagePricePerSqm;
  final int listingCount;
  final String currency;

  PriceTrendPoint({
    required this.periodKey,
    required this.periodLabel,
    required this.propertyType,
    required this.averagePricePerSqm,
    required this.listingCount,
    required this.currency,
  });

  factory PriceTrendPoint.fromJson(Map<String, dynamic> json) {
    return PriceTrendPoint(
      periodKey: json['period_key']?.toString() ?? '',
      periodLabel: json['period_label']?.toString() ?? '',
      propertyType: json['property_type']?.toString() ?? '',
      averagePricePerSqm: _asDouble(json['average_price_per_sqm']),
      listingCount: _asInt(json['listing_count']),
      currency: json['currency']?.toString() ?? 'PLN',
    );
  }
}

class MarketVelocity {
  final MarketVelocitySummary summary;
  final List<VelocityBucket> histogram;
  final List<VelocityTrendPoint> trend;
  final List<VelocityListing> topFastest;
  final List<VelocityListing> topSlowest;
  final List<VelocityBreakdownItem> byOfferType;
  final List<VelocityBreakdownItem> byMarketType;
  final List<VelocityBreakdownItem> byEstateType;
  final List<VelocityBreakdownItem> byCity;
  final Map<String, dynamic> meta;

  MarketVelocity({
    required this.summary,
    required this.histogram,
    required this.trend,
    required this.topFastest,
    required this.topSlowest,
    required this.byOfferType,
    required this.byMarketType,
    required this.byEstateType,
    required this.byCity,
    required this.meta,
  });

  factory MarketVelocity.fromJson(Map<String, dynamic> rawJson) {
    final normalized = _normalizeMarketVelocityPayload(rawJson);

    return MarketVelocity(
      summary: MarketVelocitySummary.fromJson(
        _asMap(normalized['summary']) ?? const {},
      ),
      histogram:
          _asList(normalized['histogram'])
              .map((e) => VelocityBucket.fromJson(_asMap(e) ?? const {}))
              .toList(),
      trend:
          _asList(normalized['trend'])
              .map((e) => VelocityTrendPoint.fromJson(_asMap(e) ?? const {}))
              .toList(),
      topFastest:
          _asList(normalized['top_fastest'])
              .map((e) => VelocityListing.fromJson(_asMap(e) ?? const {}))
              .toList(),
      topSlowest:
          _asList(normalized['top_slowest'])
              .map((e) => VelocityListing.fromJson(_asMap(e) ?? const {}))
              .toList(),
      byOfferType:
          _asList(normalized['by_offer_type'])
              .map(
                (e) => VelocityBreakdownItem.fromJson(_asMap(e) ?? const {}),
              )
              .toList(),
      byMarketType:
          _asList(normalized['by_market_type'])
              .map(
                (e) => VelocityBreakdownItem.fromJson(_asMap(e) ?? const {}),
              )
              .toList(),
      byEstateType:
          _asList(normalized['by_estate_type'])
              .map(
                (e) => VelocityBreakdownItem.fromJson(_asMap(e) ?? const {}),
              )
              .toList(),
      byCity:
          _asList(normalized['by_city'])
              .map(
                (e) => VelocityBreakdownItem.fromJson(_asMap(e) ?? const {}),
              )
              .toList(),
      meta: _asMap(normalized['meta']) ?? const {},
    );
  }
}

class MarketVelocitySummary {
  final int activeInventory;
  final int newListings7d;
  final int newListings30d;
  final int removedListings7d;
  final int removedListings30d;
  final int analyzedDisappearedOffers;
  final double meanDaysOnMarket;
  final double medianDaysOnMarket;
  final double p25DaysOnMarket;
  final double p75DaysOnMarket;
  final double p90DaysOnMarket;
  final double meanHoursOnMarket;
  final double medianHoursOnMarket;
  final double fastMarketShare;
  final double slowMarketShare;
  final double absorptionRate30d;
  final double removalToNewRatio30d;
  final double sellThroughRate30d;
  final double velocityScore;
  final String label;

  MarketVelocitySummary({
    required this.activeInventory,
    required this.newListings7d,
    required this.newListings30d,
    required this.removedListings7d,
    required this.removedListings30d,
    required this.analyzedDisappearedOffers,
    required this.meanDaysOnMarket,
    required this.medianDaysOnMarket,
    required this.p25DaysOnMarket,
    required this.p75DaysOnMarket,
    required this.p90DaysOnMarket,
    required this.meanHoursOnMarket,
    required this.medianHoursOnMarket,
    required this.fastMarketShare,
    required this.slowMarketShare,
    required this.absorptionRate30d,
    required this.removalToNewRatio30d,
    required this.sellThroughRate30d,
    required this.velocityScore,
    required this.label,
  });

  factory MarketVelocitySummary.fromJson(Map<String, dynamic> json) {
    return MarketVelocitySummary(
      activeInventory: _asInt(json['active_inventory']),
      newListings7d: _asInt(json['new_listings_7d']),
      newListings30d: _asInt(json['new_listings_30d']),
      removedListings7d: _asInt(json['removed_listings_7d']),
      removedListings30d: _asInt(json['removed_listings_30d']),
      analyzedDisappearedOffers: _asInt(json['analyzed_disappeared_offers']),
      meanDaysOnMarket: _asDouble(json['mean_days_on_market']),
      medianDaysOnMarket: _asDouble(json['median_days_on_market']),
      p25DaysOnMarket: _asDouble(json['p25_days_on_market']),
      p75DaysOnMarket: _asDouble(json['p75_days_on_market']),
      p90DaysOnMarket: _asDouble(json['p90_days_on_market']),
      meanHoursOnMarket: _asDouble(json['mean_hours_on_market']),
      medianHoursOnMarket: _asDouble(json['median_hours_on_market']),
      fastMarketShare: _asDouble(json['fast_market_share']),
      slowMarketShare: _asDouble(json['slow_market_share']),
      absorptionRate30d: _asDouble(json['absorption_rate_30d']),
      removalToNewRatio30d: _asDouble(json['removal_to_new_ratio_30d']),
      sellThroughRate30d: _asDouble(json['sell_through_rate_30d']),
      velocityScore: _asDouble(json['velocity_score']),
      label: json['label']?.toString() ?? '',
    );
  }
}

class VelocityBucket {
  final String label;
  final int count;

  VelocityBucket({
    required this.label,
    required this.count,
  });

  factory VelocityBucket.fromJson(Map<String, dynamic> json) {
    return VelocityBucket(
      label: json['label']?.toString() ?? '',
      count: _asInt(json['count']),
    );
  }
}

class VelocityTrendPoint {
  final String periodKey;
  final String periodLabel;
  final int newListings;
  final int removedListings;
  final double? medianDaysOnMarket;
  final double? meanDaysOnMarket;
  final double removalToNewRatio;

  VelocityTrendPoint({
    required this.periodKey,
    required this.periodLabel,
    required this.newListings,
    required this.removedListings,
    required this.medianDaysOnMarket,
    required this.meanDaysOnMarket,
    required this.removalToNewRatio,
  });

  factory VelocityTrendPoint.fromJson(Map<String, dynamic> json) {
    return VelocityTrendPoint(
      periodKey: json['period_key']?.toString() ?? '',
      periodLabel: json['period_label']?.toString() ?? '',
      newListings: _asInt(json['new_listings']),
      removedListings: _asInt(json['removed_listings']),
      medianDaysOnMarket: _asNullableDouble(json['median_days_on_market']),
      meanDaysOnMarket: _asNullableDouble(json['mean_days_on_market']),
      removalToNewRatio: _asDouble(json['removal_to_new_ratio']),
    );
  }
}

class VelocityListing {
  final int id;
  final String title;
  final String city;
  final String estateType;
  final String offerType;
  final String marketType;
  final dynamic price;
  final String? currency;
  final String? createdAt;
  final String? inactiveDate;
  final double? daysOnMarket;
  final String? url;

  VelocityListing({
    required this.id,
    required this.title,
    required this.city,
    required this.estateType,
    required this.offerType,
    required this.marketType,
    required this.price,
    required this.currency,
    required this.createdAt,
    required this.inactiveDate,
    required this.daysOnMarket,
    required this.url,
  });

  factory VelocityListing.fromJson(Map<String, dynamic> json) {
    return VelocityListing(
      id: _asInt(json['id']),
      title: json['title']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      estateType: json['estate_type']?.toString() ?? '',
      offerType: json['offer_type']?.toString() ?? '',
      marketType: json['market_type']?.toString() ?? '',
      price: json['price'],
      currency: json['currency']?.toString(),
      createdAt: json['created_at']?.toString(),
      inactiveDate: json['inactive_date']?.toString(),
      daysOnMarket: _asNullableDouble(json['days_on_market']),
      url: json['url']?.toString(),
    );
  }
}

class VelocityBreakdownItem {
  final String segment;
  final int activeInventory;
  final int newListings7d;
  final int newListings30d;
  final int removedListings7d;
  final int removedListings30d;
  final double? meanDaysOnMarket;
  final double? medianDaysOnMarket;
  final double? p25DaysOnMarket;
  final double? p75DaysOnMarket;
  final double absorptionRate30d;
  final double removalToNewRatio30d;
  final double shareOfRemoved30d;
  final double shareOfActiveInventory;
  final int netFlow30d;
  final String marketBalance;
  final double? relativeVelocityIndex;
  final double velocityScore;
  final String label;

  VelocityBreakdownItem({
    required this.segment,
    required this.activeInventory,
    required this.newListings7d,
    required this.newListings30d,
    required this.removedListings7d,
    required this.removedListings30d,
    required this.meanDaysOnMarket,
    required this.medianDaysOnMarket,
    required this.p25DaysOnMarket,
    required this.p75DaysOnMarket,
    required this.absorptionRate30d,
    required this.removalToNewRatio30d,
    required this.shareOfRemoved30d,
    required this.shareOfActiveInventory,
    required this.netFlow30d,
    required this.marketBalance,
    required this.relativeVelocityIndex,
    required this.velocityScore,
    required this.label,
  });

  factory VelocityBreakdownItem.fromJson(Map<String, dynamic> json) {
    return VelocityBreakdownItem(
      segment: json['segment']?.toString() ?? '',
      activeInventory: _asInt(json['active_inventory']),
      newListings7d: _asInt(json['new_listings_7d']),
      newListings30d: _asInt(json['new_listings_30d']),
      removedListings7d: _asInt(json['removed_listings_7d']),
      removedListings30d: _asInt(json['removed_listings_30d']),
      meanDaysOnMarket: _asNullableDouble(json['mean_days_on_market']),
      medianDaysOnMarket: _asNullableDouble(json['median_days_on_market']),
      p25DaysOnMarket: _asNullableDouble(json['p25_days_on_market']),
      p75DaysOnMarket: _asNullableDouble(json['p75_days_on_market']),
      absorptionRate30d: _asDouble(json['absorption_rate_30d']),
      removalToNewRatio30d: _asDouble(json['removal_to_new_ratio_30d']),
      shareOfRemoved30d: _asDouble(json['share_of_removed_30d']),
      shareOfActiveInventory: _asDouble(json['share_of_active_inventory']),
      netFlow30d: _asInt(json['net_flow_30d']),
      marketBalance: json['market_balance']?.toString() ?? '',
      relativeVelocityIndex: _asNullableDouble(json['relative_velocity_index']),
      velocityScore: _asDouble(json['velocity_score']),
      label: json['label']?.toString() ?? '',
    );
  }
}

class MarketPressureCity {
  final String city;
  final int activeInventory;
  final int newListings30d;
  final int removedListings30d;
  final double? medianDisappearanceDays;
  final double pressureIndex;
  final String label;

  MarketPressureCity({
    required this.city,
    required this.activeInventory,
    required this.newListings30d,
    required this.removedListings30d,
    required this.medianDisappearanceDays,
    required this.pressureIndex,
    required this.label,
  });

  factory MarketPressureCity.fromJson(Map<String, dynamic> json) {
    return MarketPressureCity(
      city: json['city']?.toString() ?? '',
      activeInventory: _asInt(json['active_inventory']),
      newListings30d: _asInt(json['new_listings_30d']),
      removedListings30d: _asInt(json['removed_listings_30d']),
      medianDisappearanceDays: _asNullableDouble(
        json['median_disappearance_days'],
      ),
      pressureIndex: _asDouble(json['pressure_index']),
      label: json['label']?.toString() ?? '',
    );
  }
}

class CategoryActivity {
  final String category;
  final int activeInventory;
  final int newListings30d;
  final int removedListings30d;
  final double? averagePricePerSqm;
  final double sharePct;
  final String currency;

  CategoryActivity({
    required this.category,
    required this.activeInventory,
    required this.newListings30d,
    required this.removedListings30d,
    required this.averagePricePerSqm,
    required this.sharePct,
    required this.currency,
  });

  factory CategoryActivity.fromJson(Map<String, dynamic> json) {
    return CategoryActivity(
      category: json['category']?.toString() ?? '',
      activeInventory: _asInt(json['active_inventory']),
      newListings30d: _asInt(json['new_listings_30d']),
      removedListings30d: _asInt(json['removed_listings_30d']),
      averagePricePerSqm: _asNullableDouble(json['average_price_per_sqm']),
      sharePct: _asDouble(json['share_pct']),
      currency: json['currency']?.toString() ?? 'PLN',
    );
  }
}

class LastReport {
  final int id;
  final String streetAddress;
  final String city;
  final String state;
  final String country;
  final String propertyType;
  final double? valueEstimate;
  final String currency;
  final String createdAt;
  final double? pricePerSqm;

  LastReport({
    required this.id,
    required this.streetAddress,
    required this.city,
    required this.state,
    required this.country,
    required this.propertyType,
    this.valueEstimate,
    required this.currency,
    required this.createdAt,
    this.pricePerSqm,
  });

  factory LastReport.fromJson(Map<String, dynamic> json) {
    return LastReport(
      id: _asInt(json['id']),
      streetAddress: json['street_address']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      propertyType: json['property_type']?.toString() ?? '',
      valueEstimate: _asNullableDouble(json['value_estimate']),
      currency: json['currency']?.toString() ?? 'PLN',
      createdAt: json['created_at']?.toString() ?? '',
      pricePerSqm: _asNullableDouble(json['price_per_sqm']),
    );
  }
}

Map<String, dynamic> _extractMarketVelocityPayload(
  Map<String, dynamic> root,
) {
  final direct = _asMap(root['market_velocity']);
  if (direct != null && direct.isNotEmpty) {
    return direct;
  }

  final fallbackKeys = {
    'summary',
    'stats_hours',
    'stats_days',
    'histogram',
    'trend',
    'top_fastest',
    'top_slowest',
    'by_offer_type',
    'by_market_type',
    'by_estate_type',
    'by_city',
    'meta',
  };

  final fallback = <String, dynamic>{};
  for (final entry in root.entries) {
    if (fallbackKeys.contains(entry.key)) {
      fallback[entry.key] = entry.value;
    }
  }
  return fallback;
}

Map<String, dynamic> _normalizeMarketVelocityPayload(
  Map<String, dynamic> rawJson,
) {
  final raw = Map<String, dynamic>.from(rawJson);

  final summaryRaw = _asMap(raw['summary']) ?? const <String, dynamic>{};
  final statsDaysRaw = _asMap(raw['stats_days']) ?? const <String, dynamic>{};
  final statsHoursRaw = _asMap(raw['stats_hours']) ?? const <String, dynamic>{};

  final histogramRaw = _asList(raw['histogram']);
  final trendRaw = _asList(raw['trend']);
  final topFastestRaw = _asList(raw['top_fastest']);
  final topSlowestRaw = _asList(raw['top_slowest']);
  final byOfferTypeRaw = _asList(raw['by_offer_type']);
  final byMarketTypeRaw = _asList(raw['by_market_type']);
  final byEstateTypeRaw = _asList(raw['by_estate_type']);
  final byCityRaw = _asList(raw['by_city']);
  final metaRaw = _asMap(raw['meta']) ?? <String, dynamic>{};

  final hasSummaryPayload = summaryRaw.isNotEmpty;
  final hasInventoryStats =
      summaryRaw.containsKey('active_inventory') ||
      summaryRaw.containsKey('new_listings_30d') ||
      summaryRaw.containsKey('removed_listings_30d') ||
      summaryRaw.containsKey('absorption_rate_30d') ||
      summaryRaw.containsKey('removal_to_new_ratio_30d');

  final hasTrendPayload = raw.containsKey('trend');
  final hasBreakdownPayload =
      raw.containsKey('by_offer_type') ||
      raw.containsKey('by_market_type') ||
      raw.containsKey('by_estate_type') ||
      raw.containsKey('by_city');

  final analyzedDisappearedOffers = summaryRaw.containsKey(
        'analyzed_disappeared_offers',
      )
      ? _asInt(summaryRaw['analyzed_disappeared_offers'])
      : _sumHistogramCounts(histogramRaw);

  final derivedShares = _deriveFastSlowShares(histogramRaw);
  final derivedVelocityScore = _deriveLegacyVelocityScore(
    statsDaysRaw,
    summaryRaw,
  );

  final velocityScore = summaryRaw.containsKey('velocity_score')
      ? _asDouble(summaryRaw['velocity_score'])
      : derivedVelocityScore;

  final label = summaryRaw['label']?.toString() ??
      (hasInventoryStats
          ? _velocityLabelFromScore(velocityScore)
          : ((statsDaysRaw.isNotEmpty || histogramRaw.isNotEmpty)
                ? 'Partial'
                : 'No Data'));

  final summary = <String, dynamic>{
    'active_inventory': summaryRaw['active_inventory'] ?? 0,
    'new_listings_7d': summaryRaw['new_listings_7d'] ?? 0,
    'new_listings_30d': summaryRaw['new_listings_30d'] ?? 0,
    'removed_listings_7d': summaryRaw['removed_listings_7d'] ?? 0,
    'removed_listings_30d': summaryRaw['removed_listings_30d'] ?? 0,
    'analyzed_disappeared_offers': analyzedDisappearedOffers,
    'mean_days_on_market':
        summaryRaw['mean_days_on_market'] ?? statsDaysRaw['mean'] ?? 0.0,
    'median_days_on_market':
        summaryRaw['median_days_on_market'] ?? statsDaysRaw['median'] ?? 0.0,
    'p25_days_on_market':
        summaryRaw['p25_days_on_market'] ?? statsDaysRaw['p25'] ?? 0.0,
    'p75_days_on_market':
        summaryRaw['p75_days_on_market'] ?? statsDaysRaw['p75'] ?? 0.0,
    'p90_days_on_market':
        summaryRaw['p90_days_on_market'] ?? statsDaysRaw['p90'] ?? 0.0,
    'mean_hours_on_market':
        summaryRaw['mean_hours_on_market'] ?? statsHoursRaw['mean'] ?? 0.0,
    'median_hours_on_market':
        summaryRaw['median_hours_on_market'] ?? statsHoursRaw['median'] ?? 0.0,
    'fast_market_share':
        summaryRaw['fast_market_share'] ?? derivedShares['fast_market_share'],
    'slow_market_share':
        summaryRaw['slow_market_share'] ?? derivedShares['slow_market_share'],
    'absorption_rate_30d': summaryRaw['absorption_rate_30d'] ?? 0.0,
    'removal_to_new_ratio_30d':
        summaryRaw['removal_to_new_ratio_30d'] ?? 0.0,
    'sell_through_rate_30d': summaryRaw['sell_through_rate_30d'] ?? 0.0,
    'velocity_score': velocityScore,
    'label': label,
  };

  final normalizedMeta = <String, dynamic>{
    ...metaRaw,
    'is_legacy_shape': !hasSummaryPayload,
    'is_partial_payload':
        !hasInventoryStats || !hasTrendPayload || !hasBreakdownPayload,
    'has_summary_payload': hasSummaryPayload,
    'has_inventory_stats': hasInventoryStats,
    'has_trend_payload': hasTrendPayload,
    'has_breakdown_payload': hasBreakdownPayload,
    'has_top_fastest_payload': raw.containsKey('top_fastest'),
    'has_top_slowest_payload': raw.containsKey('top_slowest'),
    'summary_source': hasSummaryPayload
        ? 'summary'
        : (statsDaysRaw.isNotEmpty || statsHoursRaw.isNotEmpty)
            ? 'stats_fallback'
            : 'empty',
    'available_keys': raw.keys.map((e) => e.toString()).toList(),
  };

  return {
    'summary': summary,
    'histogram': histogramRaw,
    'trend': trendRaw,
    'top_fastest': topFastestRaw,
    'top_slowest': topSlowestRaw,
    'by_offer_type': byOfferTypeRaw,
    'by_market_type': byMarketTypeRaw,
    'by_estate_type': byEstateTypeRaw,
    'by_city': byCityRaw,
    'meta': normalizedMeta,
  };
}

int _sumHistogramCounts(List<dynamic> histogramRaw) {
  var total = 0;
  for (final item in histogramRaw) {
    final map = _asMap(item);
    if (map == null) continue;
    total += _asInt(map['count']);
  }
  return total;
}

Map<String, double> _deriveFastSlowShares(List<dynamic> histogramRaw) {
  final total = _sumHistogramCounts(histogramRaw);
  if (total == 0) {
    return {
      'fast_market_share': 0.0,
      'slow_market_share': 0.0,
    };
  }

  var fast = 0;
  var slow = 0;

  for (final item in histogramRaw) {
    final map = _asMap(item);
    if (map == null) continue;

    final label = map['label']?.toString().toLowerCase() ?? '';
    final count = _asInt(map['count']);

    final isFast =
        label.contains('<24h') ||
        label.contains('1-3d') ||
        label.contains('3-7d') ||
        label.contains('< 7') ||
        label.contains('<7') ||
        label.contains('7-14');

    final isSlow =
        label.contains('>60') ||
        label.contains('> 60') ||
        label.contains('>30') ||
        label.contains('> 30');

    if (isFast) {
      fast += count;
    }
    if (isSlow) {
      slow += count;
    }
  }

  return {
    'fast_market_share': fast / total,
    'slow_market_share': slow / total,
  };
}

double _deriveLegacyVelocityScore(
  Map<String, dynamic> statsDaysRaw,
  Map<String, dynamic> summaryRaw,
) {
  if (summaryRaw.containsKey('velocity_score')) {
    return _asDouble(summaryRaw['velocity_score']);
  }

  final median = _asNullableDouble(statsDaysRaw['median']);
  if (median == null || median <= 0) {
    return 0.0;
  }

  final speedScore = (30.0 / median).clamp(0.0, 2.0) / 2.0;
  return double.parse((speedScore * 100.0).toStringAsFixed(2));
}

String _velocityLabelFromScore(double score) {
  if (score >= 80) return 'Very Fast';
  if (score >= 60) return 'Fast';
  if (score >= 40) return 'Balanced';
  if (score > 0) return 'Slow';
  return 'No Data';
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

List<dynamic> _asList(dynamic value) {
  if (value is List) return value;
  return const [];
}

int _asInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

double _asDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0.0;
}

double? _asNullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}