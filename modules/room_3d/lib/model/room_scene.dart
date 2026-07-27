/// RoomScene is the contract between geometry sources (floor_plan today,
/// room_scan later) and the room_3d viewer/editor. See
/// docs/sims_mode/ARCHITECTURE.md section 3 for the full rationale — in
/// particular why wall materials are zone-based (RoomWallZone) rather than
/// whole-wall or whole-room.
library;

enum RoomSceneSourceKind {
  floorPlan,
  roomScan;

  static RoomSceneSourceKind fromKey(String? key) {
    switch (key) {
      case 'room_scan':
        return RoomSceneSourceKind.roomScan;
      case 'floor_plan':
      default:
        return RoomSceneSourceKind.floorPlan;
    }
  }

  String get key => switch (this) {
        RoomSceneSourceKind.floorPlan => 'floor_plan',
        RoomSceneSourceKind.roomScan => 'room_scan',
      };
}

class RoomPoint2 {
  final double x;
  final double y;

  const RoomPoint2({required this.x, required this.y});

  factory RoomPoint2.fromJson(Map<String, dynamic> json) {
    return RoomPoint2(
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {'x': x, 'y': y};
}

class RoomPoint3 {
  final double x;
  final double y;
  final double z;

  const RoomPoint3({required this.x, required this.y, this.z = 0.0});

  factory RoomPoint3.fromJson(Map<String, dynamic> json) {
    return RoomPoint3(
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
      z: (json['z'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {'x': x, 'y': y, 'z': z};
}

/// Default wall height (m) used when a geometry source (floor_plan is 2D and
/// has no concept of wall height) doesn't provide one.
const double kDefaultWallHeightM = 2.6;
const double kDefaultDoorWidthM = 0.9;
const double kDefaultDoorHeightM = 2.05;
const double kDefaultWindowWidthM = 1.2;
const double kDefaultWindowSillHeightM = 0.9;
const double kDefaultWindowHeightM = 1.2;

class RoomWall {
  final String id;
  final RoomPoint2 start;
  final RoomPoint2 end;
  final double heightM;
  final double thicknessM;
  final bool isVirtual;

  const RoomWall({
    required this.id,
    required this.start,
    required this.end,
    this.heightM = kDefaultWallHeightM,
    this.thicknessM = 0.15,
    this.isVirtual = false,
  });

  factory RoomWall.fromJson(Map<String, dynamic> json) {
    return RoomWall(
      id: json['id'].toString(),
      start: RoomPoint2.fromJson(Map<String, dynamic>.from(json['start'] ?? {})),
      end: RoomPoint2.fromJson(Map<String, dynamic>.from(json['end'] ?? {})),
      heightM: (json['height_m'] as num?)?.toDouble() ?? kDefaultWallHeightM,
      thicknessM: (json['thickness_m'] as num?)?.toDouble() ?? 0.15,
      isVirtual: json['is_virtual'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'start': start.toJson(),
        'end': end.toJson(),
        'height_m': heightM,
        'thickness_m': thicknessM,
        'is_virtual': isVirtual,
      };
}

class RoomRoom {
  final String id;
  final String name;
  final List<RoomPoint2> points;
  final String? floorMaterialId;
  final String? ceilingMaterialId;

  const RoomRoom({
    required this.id,
    required this.name,
    this.points = const [],
    this.floorMaterialId,
    this.ceilingMaterialId,
  });

  factory RoomRoom.fromJson(Map<String, dynamic> json) {
    return RoomRoom(
      id: json['id'].toString(),
      name: json['name']?.toString() ?? '',
      points: ((json['points'] as List?) ?? [])
          .map((item) => RoomPoint2.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      floorMaterialId: json['floor_material_id']?.toString(),
      ceilingMaterialId: json['ceiling_material_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'points': points.map((point) => point.toJson()).toList(),
        'floor_material_id': floorMaterialId,
        'ceiling_material_id': ceilingMaterialId,
      };
}

enum RoomOpeningKind {
  door,
  window,
  garageDoor;

  static RoomOpeningKind fromKey(String? key) {
    switch (key) {
      case 'window':
        return RoomOpeningKind.window;
      case 'garage_door':
        return RoomOpeningKind.garageDoor;
      case 'door':
      default:
        return RoomOpeningKind.door;
    }
  }

  String get key => switch (this) {
        RoomOpeningKind.door => 'door',
        RoomOpeningKind.window => 'window',
        RoomOpeningKind.garageDoor => 'garage_door',
      };
}

class RoomOpening {
  final String id;
  final String wallId;
  final RoomOpeningKind kind;

  /// 0-1 position along the wall, same convention as floor_plan's doors/windows.
  final double position;
  final double widthM;
  final double sillHeightM;
  final double heightM;

  const RoomOpening({
    required this.id,
    required this.wallId,
    required this.kind,
    this.position = 0.5,
    required this.widthM,
    this.sillHeightM = 0.0,
    required this.heightM,
  });

  factory RoomOpening.fromJson(Map<String, dynamic> json) {
    final kind = RoomOpeningKind.fromKey(json['kind']?.toString());

    return RoomOpening(
      id: json['id'].toString(),
      wallId: json['wall_id'].toString(),
      kind: kind,
      position: (json['position'] as num?)?.toDouble() ?? 0.5,
      widthM: (json['width_m'] as num?)?.toDouble() ??
          (kind == RoomOpeningKind.window ? kDefaultWindowWidthM : kDefaultDoorWidthM),
      sillHeightM: (json['sill_height_m'] as num?)?.toDouble() ??
          (kind == RoomOpeningKind.window ? kDefaultWindowSillHeightM : 0.0),
      heightM: (json['height_m'] as num?)?.toDouble() ??
          (kind == RoomOpeningKind.window ? kDefaultWindowHeightM : kDefaultDoorHeightM),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'wall_id': wallId,
        'kind': kind.key,
        'position': position,
        'width_m': widthM,
        'sill_height_m': sillHeightM,
        'height_m': heightM,
      };
}

class RoomPlacedItem {
  final String id;
  final String catalogItemId;
  final RoomPoint3 position;
  final double rotationDeg;
  final double scale;
  final String roomId;

  const RoomPlacedItem({
    required this.id,
    required this.catalogItemId,
    required this.position,
    this.rotationDeg = 0.0,
    this.scale = 1.0,
    required this.roomId,
  });

  RoomPlacedItem copyWith({
    RoomPoint3? position,
    double? rotationDeg,
    double? scale,
    String? roomId,
  }) {
    return RoomPlacedItem(
      id: id,
      catalogItemId: catalogItemId,
      position: position ?? this.position,
      rotationDeg: rotationDeg ?? this.rotationDeg,
      scale: scale ?? this.scale,
      roomId: roomId ?? this.roomId,
    );
  }

  factory RoomPlacedItem.fromJson(Map<String, dynamic> json) {
    return RoomPlacedItem(
      id: json['id'].toString(),
      catalogItemId: json['catalog_item_id'].toString(),
      position: RoomPoint3.fromJson(Map<String, dynamic>.from(json['position'] ?? {})),
      rotationDeg: (json['rotation_deg'] as num?)?.toDouble() ?? 0.0,
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
      roomId: json['room_id'].toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'catalog_item_id': catalogItemId,
        'position': position.toJson(),
        'rotation_deg': rotationDeg,
        'scale': scale,
        'room_id': roomId,
      };
}

/// A rectangular material zone on a wall — height range x position range
/// along the wall, both normalized 0-1. Chosen over whole-wall or
/// top/bottom-only splits so "tile just the kitchen backsplash strip" is
/// representable. A wall with no zones falls back to
/// [RoomScene.wallSurfaceMaterials] as a whole-wall default.
class RoomWallZone {
  final String id;
  final String wallId;
  final String materialId;

  /// [minHeight01, maxHeight01], both 0-1 of the wall's heightM.
  final List<double> heightRange;

  /// [minPosition01, maxPosition01], both 0-1 along the wall's length.
  final List<double> positionRange;

  const RoomWallZone({
    required this.id,
    required this.wallId,
    required this.materialId,
    this.heightRange = const [0.0, 1.0],
    this.positionRange = const [0.0, 1.0],
  });

  RoomWallZone copyWith({String? materialId}) {
    return RoomWallZone(
      id: id,
      wallId: wallId,
      materialId: materialId ?? this.materialId,
      heightRange: heightRange,
      positionRange: positionRange,
    );
  }

  factory RoomWallZone.fromJson(Map<String, dynamic> json) {
    return RoomWallZone(
      id: json['id'].toString(),
      wallId: json['wall_id'].toString(),
      materialId: json['material_id'].toString(),
      heightRange: ((json['height_range'] as List?) ?? [0.0, 1.0])
          .map((value) => (value as num).toDouble())
          .toList(),
      positionRange: ((json['position_range'] as List?) ?? [0.0, 1.0])
          .map((value) => (value as num).toDouble())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'wall_id': wallId,
        'material_id': materialId,
        'height_range': heightRange,
        'position_range': positionRange,
      };
}

/// A schematic staircase run connecting this floor up to the floor above
/// (FINAL_VISION.md §6's "rendered stairs" — the last item in the floors
/// arc). Deliberately minimal: a straight run from [start] to [end], rising
/// from this floor's level to `storyHeightM` above it. No landings, turns,
/// or railings — those are out of scope for a visual connector.
class RoomStair {
  final String id;
  final RoomPoint2 start;
  final RoomPoint2 end;
  final double widthM;

  const RoomStair({
    required this.id,
    required this.start,
    required this.end,
    this.widthM = 1.0,
  });

  factory RoomStair.fromJson(Map<String, dynamic> json) {
    return RoomStair(
      id: json['id'].toString(),
      start: RoomPoint2.fromJson(Map<String, dynamic>.from(json['start'] ?? {})),
      end: RoomPoint2.fromJson(Map<String, dynamic>.from(json['end'] ?? {})),
      widthM: (json['width_m'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'start': start.toJson(),
        'end': end.toJson(),
        'width_m': widthM,
      };
}

/// One storey of a [RoomScene] (Option A multi-floor model: a single scene
/// document owns an internal list of floors, rather than a separate
/// `RoomSceneProject` per floor — chosen explicitly over the
/// floor_plan/room_3d "independent records" precedent because it needs zero
/// backend changes: `scene_document` is an opaque JSONField, only its
/// internal shape changes here). Holds exactly what used to be the top-level
/// entity lists on [RoomScene] pre-floors — nothing else about those lists
/// changed, they just moved down one level.
/// Default story height (m) — used for the vertical Y offset when stacking
/// floors in the 3D viewer (wall height + a slab/ceiling allowance).
/// Per-floor and user-editable (`RoomFloor.storyHeightM`), NOT a single
/// building-wide constant — real buildings often vary this per storey
/// (e.g. a taller ground floor).
const double kDefaultStoryHeightM = 2.8;

class RoomFloor {
  final String id;
  final int index;
  final String label;

  /// Vertical stacking height for this floor (FINAL_VISION.md §6's "true
  /// floor stacking" — chosen explicitly over a camera-only fake and over a
  /// single global constant, so each storey can differ). Used both as this
  /// floor's own Y offset when it's rendered as a dimmed neighbor of some
  /// OTHER active floor, and to compute where the NEXT floor up should sit
  /// (cumulative sum of every floor below it — see
  /// `RoomScene.cumulativeFloorYOffset`).
  final double storyHeightM;

  final List<RoomWall> walls;
  final List<RoomRoom> rooms;
  final List<RoomOpening> openings;
  final List<RoomPlacedItem> items;
  final List<RoomStair> stairs;

  /// wallId -> materialId, whole-wall default (fallback under wallSurfaceZones).
  final Map<String, String> wallSurfaceMaterials;
  final List<RoomWallZone> wallSurfaceZones;

  const RoomFloor({
    required this.id,
    required this.index,
    required this.label,
    this.storyHeightM = kDefaultStoryHeightM,
    this.walls = const [],
    this.rooms = const [],
    this.openings = const [],
    this.items = const [],
    this.stairs = const [],
    this.wallSurfaceMaterials = const {},
    this.wallSurfaceZones = const [],
  });

  RoomFloor copyWith({
    String? label,
    double? storyHeightM,
    List<RoomWall>? walls,
    List<RoomRoom>? rooms,
    List<RoomOpening>? openings,
    List<RoomPlacedItem>? items,
    List<RoomStair>? stairs,
    Map<String, String>? wallSurfaceMaterials,
    List<RoomWallZone>? wallSurfaceZones,
  }) {
    return RoomFloor(
      id: id,
      index: index,
      label: label ?? this.label,
      storyHeightM: storyHeightM ?? this.storyHeightM,
      walls: walls ?? this.walls,
      rooms: rooms ?? this.rooms,
      openings: openings ?? this.openings,
      items: items ?? this.items,
      stairs: stairs ?? this.stairs,
      wallSurfaceMaterials: wallSurfaceMaterials ?? this.wallSurfaceMaterials,
      wallSurfaceZones: wallSurfaceZones ?? this.wallSurfaceZones,
    );
  }

  factory RoomFloor.fromJson(Map<String, dynamic> json) {
    return RoomFloor(
      id: json['id']?.toString() ?? 'floor_0',
      index: (json['index'] as num?)?.toInt() ?? 0,
      label: json['label']?.toString() ?? 'Parter',
      storyHeightM: (json['story_height_m'] as num?)?.toDouble() ?? kDefaultStoryHeightM,
      walls: ((json['walls'] as List?) ?? [])
          .map((item) => RoomWall.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      rooms: ((json['rooms'] as List?) ?? [])
          .map((item) => RoomRoom.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      openings: ((json['openings'] as List?) ?? [])
          .map((item) => RoomOpening.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      items: ((json['items'] as List?) ?? [])
          .map((item) => RoomPlacedItem.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      stairs: ((json['stairs'] as List?) ?? [])
          .map((item) => RoomStair.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      wallSurfaceMaterials: Map<String, String>.from(
        json['wall_surface_materials'] ?? const {},
      ),
      wallSurfaceZones: ((json['wall_surface_zones'] as List?) ?? [])
          .map((item) => RoomWallZone.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'index': index,
      'label': label,
      'story_height_m': storyHeightM,
      'walls': walls.map((item) => item.toJson()).toList(),
      'rooms': rooms.map((item) => item.toJson()).toList(),
      'openings': openings.map((item) => item.toJson()).toList(),
      'items': items.map((item) => item.toJson()).toList(),
      'stairs': stairs.map((item) => item.toJson()).toList(),
      'wall_surface_materials': wallSurfaceMaterials,
      'wall_surface_zones': wallSurfaceZones.map((item) => item.toJson()).toList(),
    };
  }

  /// The subset scene.js's `loadScene` actually reads (confirmed by grep —
  /// it never touches `wall_surface_materials`, whole-wall color is only
  /// ever applied incrementally via `setWholeWallMaterial`). Sent to the
  /// viewer whenever the active floor is (re)rendered — floor switch, undo/
  /// redo, initial load — so `scene.js` needs zero structural changes for
  /// floors: it already only ever sees "the data for one floor," it just
  /// used to always be the same one.
  Map<String, dynamic> toViewerPayload() {
    return {
      'walls': walls.map((item) => item.toJson()).toList(),
      'rooms': rooms.map((item) => item.toJson()).toList(),
      'openings': openings.map((item) => item.toJson()).toList(),
      'items': items.map((item) => item.toJson()).toList(),
      'stairs': stairs.map((item) => item.toJson()).toList(),
      'wall_surface_zones': wallSurfaceZones.map((item) => item.toJson()).toList(),
      'story_height_m': storyHeightM,
    };
  }
}

class RoomScene {
  /// Bumped from 1 (flat single-floor document) — a breaking structural
  /// change (top-level walls/rooms/... moved under `floors`), not a shim: no
  /// external consumers besides this module's own code, per the project's
  /// "no backwards-compatibility hacks" convention.
  static const int currentVersion = 2;

  final int version;
  final RoomSceneSourceKind sourceKind;
  final String sourceId;
  final String units;

  final List<RoomFloor> floors;

  const RoomScene({
    this.version = currentVersion,
    required this.sourceKind,
    required this.sourceId,
    this.units = 'meters',
    this.floors = const [],
  });

  /// Convenience constructor for the common single-floor case (floor_plan
  /// import, the dev test scene) — builds one `RoomFloor` named "Parter"
  /// from the flat entity lists room_3d used pre-floors.
  factory RoomScene.singleFloor({
    int version = currentVersion,
    required RoomSceneSourceKind sourceKind,
    required String sourceId,
    String units = 'meters',
    List<RoomWall> walls = const [],
    List<RoomRoom> rooms = const [],
    List<RoomOpening> openings = const [],
    List<RoomPlacedItem> items = const [],
    Map<String, String> wallSurfaceMaterials = const {},
    List<RoomWallZone> wallSurfaceZones = const [],
  }) {
    return RoomScene(
      version: version,
      sourceKind: sourceKind,
      sourceId: sourceId,
      units: units,
      floors: [
        RoomFloor(
          id: 'floor_0',
          index: 0,
          label: 'Parter',
          walls: walls,
          rooms: rooms,
          openings: openings,
          items: items,
          wallSurfaceMaterials: wallSurfaceMaterials,
          wallSurfaceZones: wallSurfaceZones,
        ),
      ],
    );
  }

  RoomScene copyWith({List<RoomFloor>? floors}) {
    return RoomScene(
      version: version,
      sourceKind: sourceKind,
      sourceId: sourceId,
      units: units,
      floors: floors ?? this.floors,
    );
  }

  factory RoomScene.fromJson(Map<String, dynamic> json) {
    return RoomScene(
      version: (json['version'] as num?)?.toInt() ?? currentVersion,
      sourceKind: RoomSceneSourceKind.fromKey(json['source_kind']?.toString()),
      sourceId: json['source_id']?.toString() ?? '',
      units: json['units']?.toString() ?? 'meters',
      floors: ((json['floors'] as List?) ?? [])
          .map((item) => RoomFloor.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'source_kind': sourceKind.key,
      'source_id': sourceId,
      'units': units,
      'floors': floors.map((item) => item.toJson()).toList(),
    };
  }
}
