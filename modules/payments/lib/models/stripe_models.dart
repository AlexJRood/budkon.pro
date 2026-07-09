import 'dart:convert';

class StripeProductsResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<StripeProduct> results;

  StripeProductsResponse({
    required this.count,
    required this.next,
    required this.previous,
    required this.results,
  });

  factory StripeProductsResponse.fromJson(Map<String, dynamic> json) {
    return StripeProductsResponse(
      count: (json['count'] ?? 0) as int,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: (json['results'] as List<dynamic>? ?? [])
          .map((e) => StripeProduct.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static StripeProductsResponse fromJsonString(String source) =>
      StripeProductsResponse.fromJson(jsonDecode(source) as Map<String, dynamic>);
}



class StripePrice {
  final String id;
  final String currency;   // "pln", "usd"
  final double amount;     // 104.0, 49.0, 79.0
  final String? interval;  // "month", "year" albo null dla one-off

  StripePrice({
    required this.id,
    required this.currency,
    required this.amount,
    required this.interval,
  });

  factory StripePrice.fromJson(Map<String, dynamic> json) {
    return StripePrice(
      id: json['id'] ?? '',
      currency: json['currency'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      interval: json['interval'] as String?, // może być null
    );
  }
}

class StripeProduct {
  final String id;
  final String name;
  final String? description;
  final String? type;
  final bool active;
  final String? category;
  final String? placement;
  final List<dynamic> bundleItems;
  final List<StripePrice> prices;
  final String? tier;
  final List<String> features;

  StripeProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.active,
    required this.category,
    required this.placement,
    required this.bundleItems,
    required this.prices,
    required this.tier,
    required this.features,
  });

  factory StripeProduct.fromJson(Map<String, dynamic> json) {
    final pricesJson = (json['prices'] as List?) ?? const [];

    return StripeProduct(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] as String?,
      type: json['type'] as String?,
      active: json['active'] ?? false,
      category: json['category'] as String?,
      placement: json['placement'] as String?,
      bundleItems: (json['bundle_items'] as List?) ?? const [],
      prices: pricesJson
          .whereType<Map<String, dynamic>>()
          .map(StripePrice.fromJson)
          .toList(),
      tier: json['tier'] as String?,
      features: (json['features'] as List?)
              ?.whereType<String>()
              .toList() ??
          const [],
    );
  }
}
