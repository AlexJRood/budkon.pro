/// Dev/test furniture catalog — hand-seeded stand-in for a real partner
/// catalog (no partner API integration signed yet, docs/sims_mode/
/// IMPLEMENTATION_CHECKLIST.md Faza 2). `glbUrl` now points at 8 REAL,
/// legally-usable CC0 models from Kenney's "Furniture Kit"
/// (https://kenney.nl/assets/furniture-kit, see
/// `room_3d/assets/viewer/models/LICENSE.txt` for provenance/attribution) —
/// bundled flat under `room_3d`'s own `assets/viewer/models/` (same WebView
/// document root as scene.js itself), so `glbUrl` here is a path RELATIVE
/// TO THAT ROOT (`models/<file>.glb`), not a real URL. Swap this provider
/// for a real backend-backed one (`room3d_search_catalog` on the Django
/// side) in Faza 2 — nothing downstream should need to change shape when
/// that happens, since it still returns `List<CatalogItem>`; a real
/// partner's own `glbUrl`s would just be actual URLs instead of this
/// bundled-asset convention. `thumbnailUrl` stays empty — no 2D thumbnail
/// renders exist for these yet, the catalog panel still shows a category
/// icon.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/catalog_item.dart';

final List<CatalogItem> devFurnitureCatalog = [
  const CatalogItem(
    id: 'dev:sofa_01',
    name: 'Sofa Kivik',
    category: CatalogItemCategory.sofa,
    glbUrl: 'models/sofa_01.glb',
    thumbnailUrl: '',
    dimensions: CatalogItemDimensions(widthM: 2.2, depthM: 0.9, heightM: 0.8),
    brand: 'Dev',
  ),
  const CatalogItem(
    id: 'dev:bed_01',
    name: 'Łóżko Malm',
    category: CatalogItemCategory.bed,
    glbUrl: 'models/bed_01.glb',
    thumbnailUrl: '',
    dimensions: CatalogItemDimensions(widthM: 1.6, depthM: 2.0, heightM: 0.6),
    brand: 'Dev',
  ),
  const CatalogItem(
    id: 'dev:table_01',
    name: 'Stół Lisabo',
    category: CatalogItemCategory.table,
    glbUrl: 'models/table_01.glb',
    thumbnailUrl: '',
    dimensions: CatalogItemDimensions(widthM: 1.4, depthM: 0.8, heightM: 0.74),
    brand: 'Dev',
  ),
  const CatalogItem(
    id: 'dev:chair_01',
    name: 'Krzesło Odger',
    category: CatalogItemCategory.chair,
    glbUrl: 'models/chair_01.glb',
    thumbnailUrl: '',
    dimensions: CatalogItemDimensions(widthM: 0.5, depthM: 0.5, heightM: 0.9),
    brand: 'Dev',
  ),
  const CatalogItem(
    id: 'dev:kitchen_01',
    name: 'Zabudowa kuchenna',
    category: CatalogItemCategory.kitchen,
    glbUrl: 'models/kitchen_01.glb',
    thumbnailUrl: '',
    dimensions: CatalogItemDimensions(widthM: 2.6, depthM: 0.65, heightM: 0.9),
    brand: 'Dev',
  ),
  const CatalogItem(
    id: 'dev:wardrobe_01',
    name: 'Szafa Pax',
    category: CatalogItemCategory.wardrobe,
    glbUrl: 'models/wardrobe_01.glb',
    thumbnailUrl: '',
    dimensions: CatalogItemDimensions(widthM: 1.8, depthM: 0.6, heightM: 2.0),
    brand: 'Dev',
  ),
  const CatalogItem(
    id: 'dev:bathroom_01',
    name: 'Umywalka z szafką',
    category: CatalogItemCategory.bathroom,
    glbUrl: 'models/bathroom_01.glb',
    thumbnailUrl: '',
    dimensions: CatalogItemDimensions(widthM: 0.8, depthM: 0.45, heightM: 0.85),
    brand: 'Dev',
  ),
  const CatalogItem(
    id: 'dev:lighting_01',
    name: 'Lampa podłogowa',
    category: CatalogItemCategory.lighting,
    glbUrl: 'models/lighting_01.glb',
    thumbnailUrl: '',
    dimensions: CatalogItemDimensions(widthM: 0.35, depthM: 0.35, heightM: 1.5),
    brand: 'Dev',
  ),
];

final furnitureCatalogProvider = Provider<List<CatalogItem>>((ref) => devFurnitureCatalog);
