/// A furniture/appliance model available to place in a room_3d scene.
///
/// MVP is seeded manually/CSV (no partner API integrations signed yet — see
/// docs/sims_mode/ARCHITECTURE.md section 4 and IMPLEMENTATION_CHECKLIST.md
/// Faza 2). `purchaseUrl`, when present, links out to the partner's storefront;
/// opening it always requires explicit user confirmation, never auto-redirect.
enum CatalogItemCategory {
  sofa,
  bed,
  table,
  chair,
  kitchen,
  wardrobe,
  bathroom,
  lighting,
  decor,
  other;

  static CatalogItemCategory fromKey(String? key) {
    return CatalogItemCategory.values.firstWhere(
      (value) => value.name == key,
      orElse: () => CatalogItemCategory.other,
    );
  }
}

class CatalogItemDimensions {
  final double widthM;
  final double depthM;
  final double heightM;

  const CatalogItemDimensions({
    required this.widthM,
    required this.depthM,
    required this.heightM,
  });

  factory CatalogItemDimensions.fromJson(Map<String, dynamic> json) {
    return CatalogItemDimensions(
      widthM: (json['width_m'] as num?)?.toDouble() ?? 0.5,
      depthM: (json['depth_m'] as num?)?.toDouble() ?? 0.5,
      heightM: (json['height_m'] as num?)?.toDouble() ?? 0.5,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'width_m': widthM,
      'depth_m': depthM,
      'height_m': heightM,
    };
  }
}

class CatalogItem {
  final String id;
  final String name;
  final CatalogItemCategory category;
  final String glbUrl;
  final String thumbnailUrl;
  final CatalogItemDimensions dimensions;
  final String? brand;
  final String? purchaseUrl;
  final String? priceHint;

  const CatalogItem({
    required this.id,
    required this.name,
    required this.category,
    required this.glbUrl,
    required this.thumbnailUrl,
    required this.dimensions,
    this.brand,
    this.purchaseUrl,
    this.priceHint,
  });

  CatalogItem copyWith({
    String? id,
    String? name,
    CatalogItemCategory? category,
    String? glbUrl,
    String? thumbnailUrl,
    CatalogItemDimensions? dimensions,
    String? brand,
    String? purchaseUrl,
    String? priceHint,
  }) {
    return CatalogItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      glbUrl: glbUrl ?? this.glbUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      dimensions: dimensions ?? this.dimensions,
      brand: brand ?? this.brand,
      purchaseUrl: purchaseUrl ?? this.purchaseUrl,
      priceHint: priceHint ?? this.priceHint,
    );
  }

  factory CatalogItem.fromJson(Map<String, dynamic> json) {
    return CatalogItem(
      id: json['id'].toString(),
      name: json['name']?.toString() ?? '',
      category: CatalogItemCategory.fromKey(json['category']?.toString()),
      glbUrl: json['glb_url']?.toString() ?? '',
      thumbnailUrl: json['thumbnail_url']?.toString() ?? '',
      dimensions: CatalogItemDimensions.fromJson(
        Map<String, dynamic>.from(json['dimensions'] ?? {}),
      ),
      brand: json['brand']?.toString(),
      purchaseUrl: json['purchase_url']?.toString(),
      priceHint: json['price_hint']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category.name,
      'glb_url': glbUrl,
      'thumbnail_url': thumbnailUrl,
      'dimensions': dimensions.toJson(),
      if (brand != null) 'brand': brand,
      if (purchaseUrl != null) 'purchase_url': purchaseUrl,
      if (priceHint != null) 'price_hint': priceHint,
    };
  }
}
