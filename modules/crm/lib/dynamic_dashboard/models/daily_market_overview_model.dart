class DailyMarketOverviewModel {
  final int id;
  final String summaryDate;
  final String city;
  final String state;
  final String country;
  final String scope;
  final String currency;
  final String title;
  final String status;
  final Map<String, dynamic> overview;
  final Map<String, dynamic> saleSnapshot;
  final Map<String, dynamic> rentSnapshot;
  final List<dynamic> propertyTypeBreakdown;
  final List<dynamic> offerTypeBreakdown;
  final List<dynamic> fastestSegments;
  final Map<String, dynamic> narrative;
  final int sampleSize;
  final String? generatedAt;
  final bool isFreshlyGenerated;
  final bool emmaEnabled;
  final bool emmaPlaceholder;

  DailyMarketOverviewModel({
    required this.id,
    required this.summaryDate,
    required this.city,
    required this.state,
    required this.country,
    required this.scope,
    required this.currency,
    required this.title,
    required this.status,
    required this.overview,
    required this.saleSnapshot,
    required this.rentSnapshot,
    required this.propertyTypeBreakdown,
    required this.offerTypeBreakdown,
    required this.fastestSegments,
    required this.narrative,
    required this.sampleSize,
    required this.generatedAt,
    required this.isFreshlyGenerated,
    required this.emmaEnabled,
    required this.emmaPlaceholder,
  });

  factory DailyMarketOverviewModel.fromJson(Map<String, dynamic> json) {
    return DailyMarketOverviewModel(
      id: json['id'] ?? 0,
      summaryDate: json['summary_date'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      country: json['country'] ?? '',
      scope: json['scope'] ?? '',
      currency: json['currency'] ?? 'PLN',
      title: json['title'] ?? '',
      status: json['status'] ?? '',
      overview: Map<String, dynamic>.from(json['overview'] ?? {}),
      saleSnapshot: Map<String, dynamic>.from(json['sale_snapshot'] ?? {}),
      rentSnapshot: Map<String, dynamic>.from(json['rent_snapshot'] ?? {}),
      propertyTypeBreakdown: List<dynamic>.from(json['property_type_breakdown'] ?? const []),
      offerTypeBreakdown: List<dynamic>.from(json['offer_type_breakdown'] ?? const []),
      fastestSegments: List<dynamic>.from(json['fastest_segments'] ?? const []),
      narrative: Map<String, dynamic>.from(json['narrative'] ?? {}),
      sampleSize: json['sample_size'] ?? 0,
      generatedAt: json['generated_at'],
      isFreshlyGenerated: json['is_freshly_generated'] ?? false,
      emmaEnabled: json['emma_enabled'] ?? false,
      emmaPlaceholder: json['emma_placeholder'] ?? true,
    );
  }
}