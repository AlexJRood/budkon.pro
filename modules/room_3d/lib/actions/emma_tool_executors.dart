/// Real implementations of the 7 Emma tools defined on the Django side
/// (`room_3d/emma/actions/room_3d.py` in the hously.cloud repo — tool names
/// and parameter shapes must stay in sync with that file, not be redesigned
/// here in isolation). All 7 are `execution_mode: local_only` there except
/// `room3d_search_catalog` (`backend_first`) — but since the backend catalog
/// doesn't exist yet (Faza 2), this file implements search against the same
/// local dev seed data (`devFurnitureCatalog`/`devSurfaceMaterials`) so the
/// tool is actually usable today; swap for a real backend call once Faza 2
/// lands, no shape change needed downstream.
///
/// Resolution pattern used throughout: commands reference rooms/items/
/// materials by free-text name, never by opaque id (Emma doesn't have ids
/// to give). Every resolver returns 0, 1, or N>1 matches — 0 is an error,
/// N>1 returns `{"ok": false, "matches": [...]}` so Emma can ask the user to
/// disambiguate instead of guessing, mirroring `notes_update_note`'s
/// pattern (see ARCHITECTURE.md section 7).
library;

import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:furniture_catalog/furniture_catalog.dart';
import 'package:surface_materials/surface_materials.dart';

import '../model/room_scene.dart';
import '../providers/room_scene_provider.dart';
import 'room_scene_actions.dart';

/// Emma's tools always act on the currently active floor (Option A:
/// `RoomScene.floors`, see `room_scene.dart`) — Emma has no floor-selection
/// concept of its own, it just edits whatever the user is looking at, same
/// as every manual-editing tool in this file.
RoomFloor? _activeFloor(Ref ref) {
  final state = ref.read(roomSceneProvider);
  final scene = state.scene;
  if (scene == null || scene.floors.isEmpty) return null;
  return scene.floors[state.activeFloorIndex.clamp(0, scene.floors.length - 1)];
}

Map<String, RoomSceneToolExecutor> buildRoomSceneToolExecutors(
  RoomSceneActions actions,
) {
  return {
    'room3d_place_item': (params) => _placeItem(actions, params),
    'room3d_move_item': (params) => _moveItem(actions, params),
    'room3d_remove_item': (params) => _removeItem(actions, params),
    'room3d_set_wall_material': (params) => _setWallMaterial(actions, params),
    'room3d_set_floor_material': (params) => _setFloorMaterial(actions, params),
    'room3d_list_scene_items': (params) => _listSceneItems(actions, params),
    'room3d_search_catalog': (params) => _searchCatalog(actions, params),
  };
}

// ---------------------------------------------------------------------------
// room3d_place_item
// ---------------------------------------------------------------------------

Future<Map<String, dynamic>> _placeItem(
  RoomSceneActions actions,
  Map<String, dynamic> params,
) async {
  final floor = _activeFloor(actions.ref);
  if (floor == null) return _noSceneError();

  final catalogItemId = params['catalog_item_id']?.toString();
  final roomName = params['room_name']?.toString();

  if (catalogItemId == null || catalogItemId.trim().isEmpty) {
    return _err('Brak catalog_item_id — najpierw wywołaj room3d_search_catalog.');
  }
  if (roomName == null || roomName.trim().isEmpty) {
    return _err('Brak room_name.');
  }

  final catalogItem = actions.ref
      .read(furnitureCatalogProvider)
      .where((c) => c.id == catalogItemId)
      .firstOrNull;
  if (catalogItem == null) {
    return _err('Nie znaleziono mebla o id "$catalogItemId" w katalogu.');
  }

  final roomMatch = _resolveSingleRoom(floor, roomName);
  if (roomMatch.error != null) return roomMatch.error!;
  final room = roomMatch.value!;

  // near_wall isn't geometrically resolved yet (would need wall-relative
  // offset placement, a separate build) — accepted but ignored, falls back
  // to the same staggered default the furniture catalog panel UI uses.
  final position = _positionFromParams(params['position']) ??
      _defaultPlacementPosition(floor, room);

  final id = 'emma_item_${floor.items.length}_${catalogItemId.hashCode}';
  actions.placeItem(
    id: id,
    catalogItemId: catalogItemId,
    roomId: room.id,
    position: position,
  );

  return {
    'ok': true,
    'item_id': id,
    'room': room.name,
    'message': 'Postawiono "${catalogItem.name}" w pokoju ${room.name}.',
  };
}

// ---------------------------------------------------------------------------
// room3d_move_item
// ---------------------------------------------------------------------------

Future<Map<String, dynamic>> _moveItem(
  RoomSceneActions actions,
  Map<String, dynamic> params,
) async {
  final floor = _activeFloor(actions.ref);
  if (floor == null) return _noSceneError();

  final itemMatch = _resolveSingleItem(actions.ref, floor, params);
  if (itemMatch.error != null) return itemMatch.error!;
  final item = itemMatch.value!;

  final explicitPosition = _positionFromParams(params['position']);
  final direction = params['direction']?.toString();

  final position = explicitPosition ??
      (direction != null ? _applyDirection(item.position, direction) : null);

  if (position == null) {
    return _err('Podaj position ({x,y,z}) albo direction (np. "left"/"closer to the window").');
  }

  actions.moveItem(itemId: item.id, position: position);

  return {'ok': true, 'item_id': item.id, 'message': 'Przesunięto mebel.'};
}

// ---------------------------------------------------------------------------
// room3d_remove_item
// ---------------------------------------------------------------------------

Future<Map<String, dynamic>> _removeItem(
  RoomSceneActions actions,
  Map<String, dynamic> params,
) async {
  final floor = _activeFloor(actions.ref);
  if (floor == null) return _noSceneError();

  final itemMatch = _resolveSingleItem(actions.ref, floor, params);
  if (itemMatch.error != null) return itemMatch.error!;
  final item = itemMatch.value!;

  actions.removeItem(item.id);

  return {'ok': true, 'item_id': item.id, 'message': 'Usunięto mebel.'};
}

// ---------------------------------------------------------------------------
// room3d_set_wall_material
// ---------------------------------------------------------------------------

Future<Map<String, dynamic>> _setWallMaterial(
  RoomSceneActions actions,
  Map<String, dynamic> params,
) async {
  final floor = _activeFloor(actions.ref);
  if (floor == null) return _noSceneError();

  final roomName = params['room_name']?.toString();
  final wallSelector = params['wall_selector']?.toString() ?? 'all';

  if (roomName == null || roomName.trim().isEmpty) {
    return _err('Brak room_name.');
  }

  final roomMatch = _resolveSingleRoom(floor, roomName);
  if (roomMatch.error != null) return roomMatch.error!;
  final room = roomMatch.value!;

  final wallsInRoom = _wallsForRoom(floor, room);
  if (wallsInRoom.isEmpty) {
    return _err('Nie udało się geometrycznie dopasować ścian do pokoju "${room.name}".');
  }

  RoomWall wall;

  if (wallSelector.startsWith('zone:')) {
    final zoneId = wallSelector.substring('zone:'.length);
    final zone = floor.wallSurfaceZones.where((z) => z.id == zoneId).firstOrNull;
    if (zone == null) return _err('Nie znaleziono strefy "$zoneId".');

    final zoneWall = wallsInRoom.where((w) => w.id == zone.wallId).firstOrNull;
    if (zoneWall == null) {
      return _err('Strefa "$zoneId" nie należy do żadnej ściany pokoju "${room.name}".');
    }
    wall = zoneWall;
  } else if (wallsInRoom.length == 1) {
    wall = wallsInRoom.single;
  } else {
    // Multiple walls and no zone: to specify — ask which one, with compass +
    // length hints so the follow-up question is actually answerable.
    return _ambiguous(
      'Pokój "${room.name}" ma kilka ścian — którą? (podaj wall_selector jako "zone:<id>" wskazanej ściany)',
      wallsInRoom.map((w) => _describeWall(w, room)).toList(),
    );
  }

  final materialResolution = _resolveMaterial(actions.ref, params);
  if (materialResolution.error != null) return materialResolution.error!;
  final material = materialResolution.value!;

  if (wallSelector == 'all') {
    actions.setWholeWallMaterial(
      wallId: wall.id,
      materialId: material.id,
      colorHex: material.previewColorHex,
    );
  } else {
    // 'backsplash' or 'zone:<id>' — both target a zone. 'backsplash' uses
    // the same heightRange as WallMaterialPanel's preset (see
    // wall_material_panel.dart WallZonePreset.backsplash) so Emma and the
    // manual picker produce identical geometry for the same request.
    final isBackslash = wallSelector == 'backsplash';
    final zoneId = wallSelector.startsWith('zone:')
        ? wallSelector.substring('zone:'.length)
        : 'zone_${wall.id}_backsplash';

    actions.setWallZoneMaterial(
      wallId: wall.id,
      zoneId: zoneId,
      materialId: material.id,
      heightRange: isBackslash ? const [0.35, 0.65] : const [0.0, 1.0],
      colorHex: material.previewColorHex,
    );
  }

  return {
    'ok': true,
    'wall_id': wall.id,
    'material': material.name,
    'message': 'Zmieniono materiał ściany na "${material.name}".',
  };
}

// ---------------------------------------------------------------------------
// room3d_set_floor_material
// ---------------------------------------------------------------------------

Future<Map<String, dynamic>> _setFloorMaterial(
  RoomSceneActions actions,
  Map<String, dynamic> params,
) async {
  final floor = _activeFloor(actions.ref);
  if (floor == null) return _noSceneError();

  final roomName = params['room_name']?.toString();
  if (roomName == null || roomName.trim().isEmpty) {
    return _err('Brak room_name.');
  }

  final roomMatch = _resolveSingleRoom(floor, roomName);
  if (roomMatch.error != null) return roomMatch.error!;
  final room = roomMatch.value!;

  final materialResolution = _resolveMaterial(actions.ref, params);
  if (materialResolution.error != null) return materialResolution.error!;
  final material = materialResolution.value!;

  actions.setFloorMaterial(
    roomId: room.id,
    materialId: material.id,
    colorHex: material.previewColorHex,
  );

  return {
    'ok': true,
    'room': room.name,
    'material': material.name,
    'message': 'Zmieniono podłogę w pokoju ${room.name} na "${material.name}".',
  };
}

// ---------------------------------------------------------------------------
// room3d_list_scene_items
// ---------------------------------------------------------------------------

Future<Map<String, dynamic>> _listSceneItems(
  RoomSceneActions actions,
  Map<String, dynamic> params,
) async {
  final floor = _activeFloor(actions.ref);
  if (floor == null) return _noSceneError();

  var items = floor.items;
  final roomName = params['room_name']?.toString();

  if (roomName != null && roomName.trim().isNotEmpty) {
    final roomMatch = _resolveSingleRoom(floor, roomName);
    if (roomMatch.error != null) return roomMatch.error!;
    items = items.where((item) => item.roomId == roomMatch.value!.id).toList();
  }

  final catalog = actions.ref.read(furnitureCatalogProvider);

  final list = items.map((item) {
    final catalogItem = catalog.where((c) => c.id == item.catalogItemId).firstOrNull;
    return {
      'item_id': item.id,
      'name': catalogItem?.name ?? item.catalogItemId,
      'room_id': item.roomId,
    };
  }).toList();

  return {'ok': true, 'items': list, 'count': list.length};
}

// ---------------------------------------------------------------------------
// room3d_search_catalog
// ---------------------------------------------------------------------------

Future<Map<String, dynamic>> _searchCatalog(
  RoomSceneActions actions,
  Map<String, dynamic> params,
) async {
  final query = params['query']?.toString() ?? '';
  if (query.trim().isEmpty) return _err('Brak query.');

  final category = params['category']?.toString();

  final furnitureMatches = _matchCatalogItems(
    actions.ref.read(furnitureCatalogProvider),
    query,
    category,
  );
  final materialMatches = _matchMaterials(
    actions.ref.read(surfaceMaterialsProvider),
    query,
    category,
  );

  return {
    'ok': true,
    'furniture': furnitureMatches
        .map((c) => {'id': c.id, 'name': c.name, 'category': c.category.name})
        .toList(),
    'materials': materialMatches
        .map((m) => {'id': m.id, 'name': m.name, 'category': m.category.name})
        .toList(),
  };
}

// ---------------------------------------------------------------------------
// Resolution helpers
// ---------------------------------------------------------------------------

class _Resolved<T> {
  final T? value;
  final Map<String, dynamic>? error;

  const _Resolved.ok(this.value) : error = null;
  const _Resolved.err(this.error) : value = null;
}

_Resolved<RoomRoom> _resolveSingleRoom(RoomFloor floor, String query) {
  final matches = _matchRooms(floor, query);

  if (matches.isEmpty) {
    return _Resolved.err(_err('Nie znaleziono pokoju "$query".'));
  }
  if (matches.length > 1) {
    return _Resolved.err(_ambiguous(
      'Kilka pokoi pasuje do "$query".',
      matches.map((r) => {'id': r.id, 'name': r.name}).toList(),
    ));
  }

  return _Resolved.ok(matches.single);
}

List<RoomRoom> _matchRooms(RoomFloor floor, String query) {
  final normalized = query.trim().toLowerCase();

  final exact = floor.rooms.where((r) => r.name.trim().toLowerCase() == normalized).toList();
  if (exact.isNotEmpty) return exact;

  return floor.rooms.where((r) => r.name.toLowerCase().contains(normalized)).toList();
}

_Resolved<RoomPlacedItem> _resolveSingleItem(
  Ref ref,
  RoomFloor floor,
  Map<String, dynamic> params,
) {
  final itemId = params['item_id']?.toString();
  final searchQuery = params['search_query']?.toString();
  final roomName = params['room_name']?.toString();

  if (itemId != null && itemId.trim().isNotEmpty) {
    final match = floor.items.where((i) => i.id == itemId).toList();
    if (match.isEmpty) return _Resolved.err(_err('Nie znaleziono mebla o id "$itemId".'));
    return _Resolved.ok(match.single);
  }

  var candidates = floor.items;

  if (roomName != null && roomName.trim().isNotEmpty) {
    final roomMatch = _resolveSingleRoom(floor, roomName);
    if (roomMatch.error != null) return _Resolved.err(roomMatch.error);
    candidates = candidates.where((i) => i.roomId == roomMatch.value!.id).toList();
  }

  if (searchQuery == null || searchQuery.trim().isEmpty) {
    return _Resolved.err(_err('Podaj item_id albo search_query, żeby wskazać mebel.'));
  }

  final catalog = ref.read(furnitureCatalogProvider);
  final normalized = searchQuery.trim().toLowerCase();

  final matches = candidates.where((item) {
    final catalogItem = catalog.where((c) => c.id == item.catalogItemId).firstOrNull;
    final name = (catalogItem?.name ?? item.catalogItemId).toLowerCase();
    return name.contains(normalized);
  }).toList();

  if (matches.isEmpty) {
    return _Resolved.err(_err('Nie znaleziono mebla pasującego do "$searchQuery".'));
  }
  if (matches.length > 1) {
    return _Resolved.err(_ambiguous(
      'Kilka mebli pasuje do "$searchQuery".',
      matches.map((i) => {'item_id': i.id, 'catalog_item_id': i.catalogItemId}).toList(),
    ));
  }

  return _Resolved.ok(matches.single);
}

_Resolved<MaterialItem> _resolveMaterial(Ref ref, Map<String, dynamic> params) {
  final materials = ref.read(surfaceMaterialsProvider);

  final materialId = params['material_id']?.toString();
  if (materialId != null && materialId.trim().isNotEmpty) {
    final match = materials.where((m) => m.id == materialId).firstOrNull;
    if (match == null) {
      return _Resolved.err(_err('Nie znaleziono materiału o id "$materialId".'));
    }
    return _Resolved.ok(match);
  }

  final query = params['material_query']?.toString();
  if (query == null || query.trim().isEmpty) {
    return _Resolved.err(_err('Podaj material_id albo material_query.'));
  }

  final matches = _matchMaterials(materials, query, null);
  if (matches.isEmpty) {
    return _Resolved.err(_err('Nie znaleziono materiału pasującego do "$query". Użyj room3d_search_catalog.'));
  }
  if (matches.length > 1) {
    return _Resolved.err(_ambiguous(
      'Kilka materiałów pasuje do "$query".',
      matches.map((m) => {'id': m.id, 'name': m.name}).toList(),
    ));
  }

  return _Resolved.ok(matches.single);
}

List<CatalogItem> _matchCatalogItems(List<CatalogItem> catalog, String query, String? category) {
  final normalized = query.trim().toLowerCase();

  return catalog.where((item) {
    if (category != null &&
        category.trim().isNotEmpty &&
        item.category.name.toLowerCase() != category.trim().toLowerCase()) {
      return false;
    }
    return item.name.toLowerCase().contains(normalized);
  }).toList();
}

List<MaterialItem> _matchMaterials(List<MaterialItem> materials, String query, String? category) {
  final normalized = query.trim().toLowerCase();

  return materials.where((item) {
    if (category != null &&
        category.trim().isNotEmpty &&
        item.category.name.toLowerCase() != category.trim().toLowerCase()) {
      return false;
    }
    return item.name.toLowerCase().contains(normalized);
  }).toList();
}

// ---------------------------------------------------------------------------
// Geometry helpers — RoomWall has no roomId (walls are shared boundaries,
// rooms are defined by their own polygon), so "which walls belong to this
// room" has to be worked out from geometry: a wall belongs to a room if both
// its endpoints lie on that room polygon's boundary.
// ---------------------------------------------------------------------------

List<RoomWall> _wallsForRoom(RoomFloor floor, RoomRoom room) {
  const eps = 0.05; // 5cm tolerance — floor_plan-authored geometry, not hand-drawn

  return floor.walls.where((wall) {
    return _pointOnPolygonBoundary(wall.start, room.points, eps) &&
        _pointOnPolygonBoundary(wall.end, room.points, eps);
  }).toList();
}

bool _pointOnPolygonBoundary(RoomPoint2 point, List<RoomPoint2> polygon, double eps) {
  for (var i = 0; i < polygon.length; i++) {
    final a = polygon[i];
    final b = polygon[(i + 1) % polygon.length];
    if (_distanceToSegment(point, a, b) <= eps) return true;
  }
  return false;
}

double _distanceToSegment(RoomPoint2 p, RoomPoint2 a, RoomPoint2 b) {
  final dx = b.x - a.x;
  final dy = b.y - a.y;
  final lengthSq = dx * dx + dy * dy;

  if (lengthSq == 0) {
    return math.sqrt(math.pow(p.x - a.x, 2) + math.pow(p.y - a.y, 2)).toDouble();
  }

  var t = ((p.x - a.x) * dx + (p.y - a.y) * dy) / lengthSq;
  t = t.clamp(0.0, 1.0);

  final projX = a.x + t * dx;
  final projY = a.y + t * dy;

  return math.sqrt(math.pow(p.x - projX, 2) + math.pow(p.y - projY, 2)).toDouble();
}

/// Coarse compass label + length, so an ambiguous-wall error is actually
/// answerable by Emma's follow-up question rather than just listing opaque
/// ids. Direction is relative to the room polygon's (unweighted) centroid —
/// fine for the rectangular rooms floor_plan actually produces.
Map<String, dynamic> _describeWall(RoomWall wall, RoomRoom room) {
  final centroidX = room.points.map((p) => p.x).reduce((a, b) => a + b) / room.points.length;
  final centroidY = room.points.map((p) => p.y).reduce((a, b) => a + b) / room.points.length;

  final midX = (wall.start.x + wall.end.x) / 2;
  final midY = (wall.start.y + wall.end.y) / 2;

  final dx = midX - centroidX;
  final dy = midY - centroidY;

  final direction = dx.abs() > dy.abs()
      ? (dx > 0 ? 'wschodnia' : 'zachodnia')
      : (dy > 0 ? 'południowa' : 'północna');

  final length = math.sqrt(
    math.pow(wall.end.x - wall.start.x, 2) + math.pow(wall.end.y - wall.start.y, 2),
  );

  return {
    'wall_id': wall.id,
    'wall_selector': 'zone:${wall.id}',
    'description': '$direction (${length.toStringAsFixed(1)} m)',
  };
}

// ---------------------------------------------------------------------------
// Misc small helpers
// ---------------------------------------------------------------------------

RoomPoint3 _defaultPlacementPosition(RoomFloor floor, RoomRoom room) {
  final placedCount = floor.items.where((item) => item.roomId == room.id).length;
  final origin = room.points.isNotEmpty ? room.points.first : const RoomPoint2(x: 0, y: 0);

  return RoomPoint3(x: origin.x + 0.8 + placedCount * 0.7, y: origin.y + 0.8, z: 0);
}

RoomPoint3? _positionFromParams(dynamic raw) {
  if (raw is! Map) return null;

  final x = (raw['x'] as num?)?.toDouble();
  final y = (raw['y'] as num?)?.toDouble();
  if (x == null || y == null) return null;

  final z = (raw['z'] as num?)?.toDouble() ?? 0.0;
  return RoomPoint3(x: x, y: y, z: z);
}

/// Coarse nudge in a named direction — not true spatial reasoning (e.g.
/// "closer to the window" doesn't actually look for a window), just a fixed
/// 0.3m step along the named axis. Real relative placement (near_wall,
/// "next to the sofa", etc.) needs the room's geometry factored in properly
/// and is deliberately out of scope for this first pass.
RoomPoint3 _applyDirection(RoomPoint3 from, String direction) {
  const step = 0.3;
  final normalized = direction.trim().toLowerCase();

  switch (normalized) {
    case 'left':
    case 'lewo':
    case 'w lewo':
      return RoomPoint3(x: from.x - step, y: from.y, z: from.z);
    case 'right':
    case 'prawo':
    case 'w prawo':
      return RoomPoint3(x: from.x + step, y: from.y, z: from.z);
    case 'forward':
    case 'closer':
    case 'bliżej':
    case 'do przodu':
      return RoomPoint3(x: from.x, y: from.y - step, z: from.z);
    case 'back':
    case 'further':
    case 'dalej':
    case 'do tyłu':
      return RoomPoint3(x: from.x, y: from.y + step, z: from.z);
    default:
      return from;
  }
}

Map<String, dynamic> _noSceneError() =>
    _err('Brak wczytanej sceny — otwórz najpierw pokój w trybie 3D.');

Map<String, dynamic> _err(String message) => {'ok': false, 'error': message};

Map<String, dynamic> _ambiguous(String message, List<Map<String, dynamic>> matches) => {
      'ok': false,
      'error': message,
      'matches': matches,
    };
