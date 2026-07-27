/// A single paint/tile/wood/panel material available to apply to a wall
/// zone or room floor in room_3d.
///
/// Kept deliberately separate from `furniture_catalog`'s `CatalogItem` —
/// wall/floor materials come from different partners (paint/tile suppliers,
/// not furniture retailers) and have a different data lifecycle. See
/// docs/sims_mode/ARCHITECTURE.md section 4.
enum MaterialCategory {
  paint,
  tile,
  wood,
  panel;

  static MaterialCategory fromKey(String? key) {
    return MaterialCategory.values.firstWhere(
      (value) => value.name == key,
      orElse: () => MaterialCategory.paint,
    );
  }
}

class MaterialItem {
  final String id;
  final String name;
  final MaterialCategory category;

  /// Tileable texture used by the three.js viewer.
  final String textureUrl;

  /// Solid-color fallback / swatch preview, e.g. '#F5F0E8'.
  final String previewColorHex;

  final String? brand;

  const MaterialItem({
    required this.id,
    required this.name,
    required this.category,
    required this.textureUrl,
    required this.previewColorHex,
    this.brand,
  });

  MaterialItem copyWith({
    String? id,
    String? name,
    MaterialCategory? category,
    String? textureUrl,
    String? previewColorHex,
    String? brand,
  }) {
    return MaterialItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      textureUrl: textureUrl ?? this.textureUrl,
      previewColorHex: previewColorHex ?? this.previewColorHex,
      brand: brand ?? this.brand,
    );
  }

  factory MaterialItem.fromJson(Map<String, dynamic> json) {
    return MaterialItem(
      id: json['id'].toString(),
      name: json['name']?.toString() ?? '',
      category: MaterialCategory.fromKey(json['category']?.toString()),
      textureUrl: json['texture_url']?.toString() ?? '',
      previewColorHex: json['preview_color']?.toString() ?? '#CCCCCC',
      brand: json['brand']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category.name,
      'texture_url': textureUrl,
      'preview_color': previewColorHex,
      if (brand != null) 'brand': brand,
    };
  }
}
