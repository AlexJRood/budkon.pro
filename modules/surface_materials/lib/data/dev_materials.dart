/// Dev/test material catalog — same idea as furniture_catalog's dev seed.
/// No real texture assets exist yet (docs/sims_mode/
/// IMPLEMENTATION_CHECKLIST.md Faza 2), so `textureUrl` is empty and the
/// picker UI renders `previewColorHex` swatches instead. Swap this provider
/// for a real backend-backed one (`room3d_search_catalog` on the Django
/// side) in Faza 2 — downstream code only depends on `List<MaterialItem>`.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/material_item.dart';

final List<MaterialItem> devSurfaceMaterials = [
  const MaterialItem(
    id: 'dev:paint_white',
    name: 'Biała farba',
    category: MaterialCategory.paint,
    textureUrl: '',
    previewColorHex: '#F5F3EE',
  ),
  const MaterialItem(
    id: 'dev:paint_sage',
    name: 'Farba szałwiowa',
    category: MaterialCategory.paint,
    textureUrl: '',
    previewColorHex: '#9CAF88',
  ),
  const MaterialItem(
    id: 'dev:paint_terracotta',
    name: 'Farba terakotowa',
    category: MaterialCategory.paint,
    textureUrl: '',
    previewColorHex: '#C97B4A',
  ),
  const MaterialItem(
    id: 'dev:tile_metro_white',
    name: 'Płytki metro białe',
    category: MaterialCategory.tile,
    textureUrl: '',
    previewColorHex: '#FAFAFA',
  ),
  const MaterialItem(
    id: 'dev:tile_black',
    name: 'Płytki czarne',
    category: MaterialCategory.tile,
    textureUrl: '',
    previewColorHex: '#2B2B2B',
  ),
  const MaterialItem(
    id: 'dev:wood_oak',
    name: 'Panel dębowy',
    category: MaterialCategory.wood,
    textureUrl: '',
    previewColorHex: '#B08655',
  ),
  const MaterialItem(
    id: 'dev:wood_walnut',
    name: 'Panel orzechowy',
    category: MaterialCategory.wood,
    textureUrl: '',
    previewColorHex: '#6B4226',
  ),
  const MaterialItem(
    id: 'dev:panel_grey',
    name: 'Panel szary',
    category: MaterialCategory.panel,
    textureUrl: '',
    previewColorHex: '#8C8C8C',
  ),
];

final surfaceMaterialsProvider = Provider<List<MaterialItem>>((ref) => devSurfaceMaterials);
