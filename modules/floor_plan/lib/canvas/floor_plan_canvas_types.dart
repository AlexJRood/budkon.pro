part of 'floor_plan_canvas.dart';

enum FloorPlanTool {
  select,
  wall,
  virtualWall,
  room,
  door,
  window,
  garageDoor,
  asset,
  pan,
}

/// Distinguishes what a pending touch-hold gesture (press-and-hold without
/// releasing) should do once the hold threshold elapses. Touch devices have
/// no hover, so a deliberate hold is used to disambiguate "move this vertex"
/// / "restart drawing here" from an ordinary pan swipe or a quick tap.
enum _TouchHoldPurpose {
  vertexDrag,
  wallRestart,
}

enum FloorPlanAssetType {
  sofa,
  bed,
  table,
  chair,
  kitchen,
  wardrobe,
  bathtub,
  shower,
  toilet,
  sink,
  car,
  stairs,
  custom,
}

extension FloorPlanAssetTypeX on FloorPlanAssetType {
  String get key {
    switch (this) {
      case FloorPlanAssetType.sofa:
        return 'sofa';
      case FloorPlanAssetType.bed:
        return 'bed';
      case FloorPlanAssetType.table:
        return 'table';
      case FloorPlanAssetType.chair:
        return 'chair';
      case FloorPlanAssetType.kitchen:
        return 'kitchen';
      case FloorPlanAssetType.wardrobe:
        return 'wardrobe';
      case FloorPlanAssetType.bathtub:
        return 'bathtub';
      case FloorPlanAssetType.shower:
        return 'shower';
      case FloorPlanAssetType.toilet:
        return 'toilet';
      case FloorPlanAssetType.sink:
        return 'sink';
      case FloorPlanAssetType.car:
        return 'car';
      case FloorPlanAssetType.stairs:
        return 'stairs';
      case FloorPlanAssetType.custom:
        return 'custom';
    }
  }

 String get label {
  switch (this) {
    case FloorPlanAssetType.sofa:
      return 'sofa_asset_label'.tr;
    case FloorPlanAssetType.bed:
      return 'bed_asset_label'.tr;
    case FloorPlanAssetType.table:
      return 'table_asset_label'.tr;
    case FloorPlanAssetType.chair:
      return 'chair_asset_label'.tr;
    case FloorPlanAssetType.kitchen:
      return 'kitchen_asset_label'.tr;
    case FloorPlanAssetType.wardrobe:
      return 'wardrobe_asset_label'.tr;
    case FloorPlanAssetType.bathtub:
      return 'bathtub_asset_label'.tr;
    case FloorPlanAssetType.shower:
      return 'shower_asset_label'.tr;
    case FloorPlanAssetType.toilet:
      return 'toilet_asset_label'.tr;
    case FloorPlanAssetType.sink:
      return 'sink_asset_label'.tr;
    case FloorPlanAssetType.car:
      return 'car_asset_label'.tr;
    case FloorPlanAssetType.stairs:
      return 'stairs_asset_label'.tr;
    case FloorPlanAssetType.custom:
      return 'custom_asset_label'.tr;
  }
}

  Size get defaultSizeM {
    switch (this) {
      case FloorPlanAssetType.sofa:
        return const Size(2.2, 0.9);
      case FloorPlanAssetType.bed:
        return const Size(1.6, 2.0);
      case FloorPlanAssetType.table:
        return const Size(1.4, 0.8);
      case FloorPlanAssetType.chair:
        return const Size(0.5, 0.5);
      case FloorPlanAssetType.kitchen:
        return const Size(2.6, 0.65);
      case FloorPlanAssetType.wardrobe:
        return const Size(1.8, 0.65);
      case FloorPlanAssetType.bathtub:
        return const Size(1.7, 0.75);
      case FloorPlanAssetType.shower:
        return const Size(0.9, 0.9);
      case FloorPlanAssetType.toilet:
        return const Size(0.45, 0.7);
      case FloorPlanAssetType.sink:
        return const Size(0.6, 0.5);
      case FloorPlanAssetType.car:
        return const Size(4.6, 1.9);
      case FloorPlanAssetType.stairs:
        return const Size(2.2, 0.9);
      case FloorPlanAssetType.custom:
        return const Size(1.0, 1.0);
    }
  }
}

FloorPlanAssetType floorPlanAssetTypeFromKey(String key) {
  for (final type in FloorPlanAssetType.values) {
    if (type.key == key) return type;
  }

  return FloorPlanAssetType.custom;
}

enum _SelectedObjectType {
  wall,
  door,
  window,
  room,
  asset,
}

enum _WallHandleKind {
  start,
  end,
}

class _SelectedObject {
  final _SelectedObjectType type;
  final String id;

  const _SelectedObject({
    required this.type,
    required this.id,
  });

  bool get isWall => type == _SelectedObjectType.wall;
  bool get isDoor => type == _SelectedObjectType.door;
  bool get isWindow => type == _SelectedObjectType.window;
  bool get isRoom => type == _SelectedObjectType.room;
  bool get isAsset => type == _SelectedObjectType.asset;
}

class _WallHandleHit {
  final String wallId;
  final _WallHandleKind kind;
  final Offset point;

  const _WallHandleHit({
    required this.wallId,
    required this.kind,
    required this.point,
  });
}

class _OpeningHit {
  final _SelectedObjectType type;
  final String id;
  final String wallId;

  const _OpeningHit({
    required this.type,
    required this.id,
    required this.wallId,
  });
}

class _GuideSnapResult {
  final Offset point;
  final List<_GuideLine> lines;
  final String? label;

  /// Snap metadata used when endpoint/vertex should create a point
  /// on an existing wall segment.
  final String? snapWallId;
  final double? snapWallFraction;

  const _GuideSnapResult({
    required this.point,
    this.lines = const [],
    this.label,
    this.snapWallId,
    this.snapWallFraction,
  });

  bool get isWallLineSnap => snapWallId != null;
}

class _GuideLine {
  final Offset start;
  final Offset end;

  const _GuideLine({
    required this.start,
    required this.end,
  });
}

class _WallLengthLabelHit {
  final String wallId;
  final FloorWall wall;

  const _WallLengthLabelHit({
    required this.wallId,
    required this.wall,
  });
}

class _CornerAngleLabelHit {
  final Offset corner;
  final String wallAId;
  final String wallBId;
  final double angleDeg;
  final int sweepSign;
  final Offset labelPosition;
  final Rect labelRect;

  const _CornerAngleLabelHit({
    required this.corner,
    required this.wallAId,
    required this.wallBId,
    required this.angleDeg,
    required this.sweepSign,
    required this.labelPosition,
    required this.labelRect,
  });
}

class _RoomLabelHit {
  final String roomId;
  final FloorRoom room;

  const _RoomLabelHit({
    required this.roomId,
    required this.room,
  });
}

class _AssetHit {
  final String assetId;
  final FloorPlanAsset asset;

  const _AssetHit({
    required this.assetId,
    required this.asset,
  });
}

class _DetectedRoomCandidate {
  final List<Offset> points;
  final double areaM2;

  const _DetectedRoomCandidate({
    required this.points,
    required this.areaM2,
  });
}

class _WallLineSnapHit {
  final String wallId;
  final FloorWall wall;
  final Offset point;
  final double fraction;
  final double distance;

  const _WallLineSnapHit({
    required this.wallId,
    required this.wall,
    required this.point,
    required this.fraction,
    required this.distance,
  });

  bool get canSplit => fraction > 0.02 && fraction < 0.98;
}

class _WallSplitResult {
  final FloorPlanDocument document;
  final bool didSplit;
  final String? firstWallId;
  final String? secondWallId;
  final Offset splitPoint;

  const _WallSplitResult({
    required this.document,
    required this.didSplit,
    required this.splitPoint,
    this.firstWallId,
    this.secondWallId,
  });
}






enum _OpeningHandleSide {
  start,
  end,
}

class _OpeningGeometry {
  final Offset center;
  final Offset gapStart;
  final Offset gapEnd;
  final Offset unit;
  final Offset normal;
  final double position;
  final double widthM;
  final double wallLengthPx;

  const _OpeningGeometry({
    required this.center,
    required this.gapStart,
    required this.gapEnd,
    required this.unit,
    required this.normal,
    required this.position,
    required this.widthM,
    required this.wallLengthPx,
  });
}

class _OpeningResizeHandleHit {
  final _SelectedObjectType openingType;
  final String openingId;
  final String wallId;
  final _OpeningHandleSide side;
  final FloorWall wall;
  final Offset point;
  final double distance;

  const _OpeningResizeHandleHit({
    required this.openingType,
    required this.openingId,
    required this.wallId,
    required this.side,
    required this.wall,
    required this.point,
    required this.distance,
  });
}

class _WallProjectionHit {
  final FloorWall wall;
  final Offset point;
  final double fraction;
  final double distance;

  const _WallProjectionHit({
    required this.wall,
    required this.point,
    required this.fraction,
    required this.distance,
  });
}


class _SelectedVertex {
  final Offset point;
  final List<_WallHandleHit> connectedHandles;

  const _SelectedVertex({
    required this.point,
    required this.connectedHandles,
  });

  _SelectedVertex copyWith({
    Offset? point,
    List<_WallHandleHit>? connectedHandles,
  }) {
    return _SelectedVertex(
      point: point ?? this.point,
      connectedHandles: connectedHandles ?? this.connectedHandles,
    );
  }
}



class FloorPlanCanvasSelectionSnapshot {
  final String? objectType;
  final String? objectId;
  final List<String> wallIds;
  final Map<String, dynamic>? extra;

  const FloorPlanCanvasSelectionSnapshot({
    this.objectType,
    this.objectId,
    this.wallIds = const [],
    this.extra,
  });

  bool get isEmpty {
    return objectType == null &&
        objectId == null &&
        wallIds.isEmpty &&
        extra == null;
  }

  Map<String, dynamic> toJson() {
    return {
      'object_type': objectType,
      'object_id': objectId,
      'wall_ids': wallIds,
      if (extra != null) 'extra': extra,
    };
  }
}




enum FloorPlanExportFormat {
  png,
  jpg,
  webp,
  pdf,
}

extension FloorPlanExportFormatX on FloorPlanExportFormat {
  String get extension {
    switch (this) {
      case FloorPlanExportFormat.png:
        return 'png';
      case FloorPlanExportFormat.jpg:
        return 'jpg';
      case FloorPlanExportFormat.webp:
        return 'webp';
      case FloorPlanExportFormat.pdf:
        return 'pdf';
    }
  }

  String get label {
    switch (this) {
      case FloorPlanExportFormat.png:
        return 'PNG';
      case FloorPlanExportFormat.jpg:
        return 'JPG';
      case FloorPlanExportFormat.webp:
        return 'WEBP';
      case FloorPlanExportFormat.pdf:
        return 'PDF';
    }
  }
}

enum FloorPlanExportBoundsMode {
  fullCanvas,
  content,
}

extension FloorPlanExportBoundsModeX on FloorPlanExportBoundsMode {
  String get label {
    switch (this) {
      case FloorPlanExportBoundsMode.fullCanvas:
        return 'full_canvas_bounds_label'.tr;
      case FloorPlanExportBoundsMode.content:
        return 'content_bounds_label'.tr;
    }
  }
}

enum FloorPlanExportThemeMode {
  current,
  white,
  dark,
  blueprint,
}

extension FloorPlanExportThemeModeX on FloorPlanExportThemeMode {
  String get label {
    switch (this) {
      case FloorPlanExportThemeMode.current:
        return 'current_theme_label'.tr;
      case FloorPlanExportThemeMode.white:
        return 'white_theme_label'.tr;
      case FloorPlanExportThemeMode.dark:
        return 'dark_theme_label'.tr;
      case FloorPlanExportThemeMode.blueprint:
        return 'blueprint_theme_label'.tr;
    }
  }
}

class FloorPlanExportSettings {
  final FloorPlanExportFormat format;
  final FloorPlanExportBoundsMode boundsMode;
  final FloorPlanExportThemeMode themeMode;

  final double marginPx;
  final double pixelRatio;

  final bool showBackgroundImage;
  final bool showGrid;
  final bool showWallDimensions;
  final bool showCornerAngles;
  final bool showRoomLabels;
  final bool showRoomAreas;
  final bool showRoomFill;
  final bool highlightRooms;
  final bool showAssets;
  final bool showOpenings;

  final String backgroundColorHex;
  final String gridColorHex;
  final String wallColorHex;
  final String virtualWallColorHex;
  final String openingColorHex;
  final String assetFillColorHex;
  final String assetStrokeColorHex;
  final String roomFillColorHex;
  final String roomHighlightColorHex;
  final String labelColorHex;

  final double roomFillOpacity;
  final double roomHighlightOpacity;

  const FloorPlanExportSettings({
    required this.format,
    required this.boundsMode,
    required this.themeMode,
    required this.marginPx,
    required this.pixelRatio,
    required this.showBackgroundImage,
    required this.showGrid,
    required this.showWallDimensions,
    required this.showCornerAngles,
    required this.showRoomLabels,
    required this.showRoomAreas,
    required this.showRoomFill,
    required this.highlightRooms,
    required this.showAssets,
    required this.showOpenings,
    required this.backgroundColorHex,
    required this.gridColorHex,
    required this.wallColorHex,
    required this.virtualWallColorHex,
    required this.openingColorHex,
    required this.assetFillColorHex,
    required this.assetStrokeColorHex,
    required this.roomFillColorHex,
    required this.roomHighlightColorHex,
    required this.labelColorHex,
    required this.roomFillOpacity,
    required this.roomHighlightOpacity,
  });

  factory FloorPlanExportSettings.initial({
    required FloorPlanExportFormat format,
    required bool showCornerAngles,
    required bool showRoomLabels,
    required bool showRoomAreas,
  }) {
    return FloorPlanExportSettings(
      format: format,
      boundsMode: FloorPlanExportBoundsMode.content,
      themeMode: FloorPlanExportThemeMode.current,
      marginPx: 180,
      pixelRatio: format == FloorPlanExportFormat.pdf ? 2.0 : 2.5,
      showBackgroundImage: true,
      showGrid: true,
      showWallDimensions: true,
      showCornerAngles: showCornerAngles,
      showRoomLabels: showRoomLabels,
      showRoomAreas: showRoomAreas,
      showRoomFill: true,
      highlightRooms: true,
      showAssets: true,
      showOpenings: true,
      backgroundColorHex: '#0F172A',
      gridColorHex: '#334155',
      wallColorHex: '#E5E7EB',
      virtualWallColorHex: '#94A3B8',
      openingColorHex: '#06B6D4',
      assetFillColorHex: '#1E293B',
      assetStrokeColorHex: '#CBD5E1',
      roomFillColorHex: '#7C3AED',
      roomHighlightColorHex: '#A855F7',
      labelColorHex: '#FFFFFF',
      roomFillOpacity: 0.18,
      roomHighlightOpacity: 0.28,
    );
  }

  FloorPlanExportSettings copyWith({
    FloorPlanExportFormat? format,
    FloorPlanExportBoundsMode? boundsMode,
    FloorPlanExportThemeMode? themeMode,
    double? marginPx,
    double? pixelRatio,
    bool? showBackgroundImage,
    bool? showGrid,
    bool? showWallDimensions,
    bool? showCornerAngles,
    bool? showRoomLabels,
    bool? showRoomAreas,
    bool? showRoomFill,
    bool? highlightRooms,
    bool? showAssets,
    bool? showOpenings,
    String? backgroundColorHex,
    String? gridColorHex,
    String? wallColorHex,
    String? virtualWallColorHex,
    String? openingColorHex,
    String? assetFillColorHex,
    String? assetStrokeColorHex,
    String? roomFillColorHex,
    String? roomHighlightColorHex,
    String? labelColorHex,
    double? roomFillOpacity,
    double? roomHighlightOpacity,
  }) {
    return FloorPlanExportSettings(
      format: format ?? this.format,
      boundsMode: boundsMode ?? this.boundsMode,
      themeMode: themeMode ?? this.themeMode,
      marginPx: marginPx ?? this.marginPx,
      pixelRatio: pixelRatio ?? this.pixelRatio,
      showBackgroundImage: showBackgroundImage ?? this.showBackgroundImage,
      showGrid: showGrid ?? this.showGrid,
      showWallDimensions: showWallDimensions ?? this.showWallDimensions,
      showCornerAngles: showCornerAngles ?? this.showCornerAngles,
      showRoomLabels: showRoomLabels ?? this.showRoomLabels,
      showRoomAreas: showRoomAreas ?? this.showRoomAreas,
      showRoomFill: showRoomFill ?? this.showRoomFill,
      highlightRooms: highlightRooms ?? this.highlightRooms,
      showAssets: showAssets ?? this.showAssets,
      showOpenings: showOpenings ?? this.showOpenings,
      backgroundColorHex: backgroundColorHex ?? this.backgroundColorHex,
      gridColorHex: gridColorHex ?? this.gridColorHex,
      wallColorHex: wallColorHex ?? this.wallColorHex,
      virtualWallColorHex: virtualWallColorHex ?? this.virtualWallColorHex,
      openingColorHex: openingColorHex ?? this.openingColorHex,
      assetFillColorHex: assetFillColorHex ?? this.assetFillColorHex,
      assetStrokeColorHex: assetStrokeColorHex ?? this.assetStrokeColorHex,
      roomFillColorHex: roomFillColorHex ?? this.roomFillColorHex,
      roomHighlightColorHex:
          roomHighlightColorHex ?? this.roomHighlightColorHex,
      labelColorHex: labelColorHex ?? this.labelColorHex,
      roomFillOpacity: roomFillOpacity ?? this.roomFillOpacity,
      roomHighlightOpacity:
          roomHighlightOpacity ?? this.roomHighlightOpacity,
    );
  }
}

class FloorPlanPainterStyle {
  final Color backgroundColor;
  final Color gridColor;
  final Color wallColor;
  final Color virtualWallColor;
  final Color openingColor;
  final Color assetFillColor;
  final Color assetStrokeColor;
  final Color roomFillColor;
  final Color roomHighlightColor;
  final Color labelColor;

  final double roomFillOpacity;
  final double roomHighlightOpacity;

  final bool showGrid;
  final bool showWallDimensions;
  final bool showRoomFill;
  final bool highlightRooms;
  final bool showAssets;
  final bool showOpenings;

  const FloorPlanPainterStyle({
    required this.backgroundColor,
    required this.gridColor,
    required this.wallColor,
    required this.virtualWallColor,
    required this.openingColor,
    required this.assetFillColor,
    required this.assetStrokeColor,
    required this.roomFillColor,
    required this.roomHighlightColor,
    required this.labelColor,
    required this.roomFillOpacity,
    required this.roomHighlightOpacity,
    required this.showGrid,
    required this.showWallDimensions,
    required this.showRoomFill,
    required this.highlightRooms,
    required this.showAssets,
    required this.showOpenings,
  });
}






class _VertexDragAnchor {
  final String vertexKey;
  final Offset originalPoint;
  final List<_WallHandleHit> connectedHandles;

  const _VertexDragAnchor({
    required this.vertexKey,
    required this.originalPoint,
    required this.connectedHandles,
  });
}

class _WallDragSnapshot {
  final String wallId;
  final FloorWall wall;
  final Offset originalStart;
  final Offset originalEnd;

  const _WallDragSnapshot({
    required this.wallId,
    required this.wall,
    required this.originalStart,
    required this.originalEnd,
  });
}














enum FloorPlanMirrorAxis {
  vertical,
  horizontal,
}

class _FloorPlanClipboardData {
  final List<FloorWall> walls;
  final List<Map<String, dynamic>> doors;
  final List<Map<String, dynamic>> windows;
  final List<FloorRoom> rooms;
  final List<FloorPlanAsset> assets;

  const _FloorPlanClipboardData({
    required this.walls,
    required this.doors,
    required this.windows,
    required this.rooms,
    required this.assets,
  });

  bool get isEmpty {
    return walls.isEmpty &&
        doors.isEmpty &&
        windows.isEmpty &&
        rooms.isEmpty &&
        assets.isEmpty;
  }

  Set<String> get wallIds {
    return walls.map((wall) => wall.id).toSet();
  }
}







enum FloorWallKind {
  partition,
  loadBearing,
  virtualWall,
}

extension FloorWallKindX on FloorWallKind {
  String get key {
    switch (this) {
      case FloorWallKind.partition:
        return 'partition';
      case FloorWallKind.loadBearing:
        return 'load_bearing';
      case FloorWallKind.virtualWall:
        return 'virtual';
    }
  }

  String get label {
    switch (this) {
      case FloorWallKind.partition:
        return 'partition_wall_label'.tr;
      case FloorWallKind.loadBearing:
        return 'load_bearing_wall_label'.tr;
      case FloorWallKind.virtualWall:
        return 'virtual_wall_label'.tr;
    }
  }

  double get defaultThicknessCm {
    switch (this) {
      case FloorWallKind.partition:
        return 12;
      case FloorWallKind.loadBearing:
        return 24;
      case FloorWallKind.virtualWall:
        return 1;
    }
  }

  IconData get icon {
    switch (this) {
      case FloorWallKind.partition:
        return Icons.view_week_outlined;
      case FloorWallKind.loadBearing:
        return Icons.foundation_outlined;
      case FloorWallKind.virtualWall:
        return Icons.border_style;
    }
  }
}

FloorWallKind floorWallKindFromKey(String? value) {
  switch (value) {
    case 'load_bearing':
    case 'bearing':
    case 'structural':
      return FloorWallKind.loadBearing;

    case 'virtual':
    case 'virtual_wall':
    case 'fictional':
      return FloorWallKind.virtualWall;

    case 'partition':
    case 'normal':
    default:
      return FloorWallKind.partition;
  }
}

extension FloorWallKindCompatX on FloorWall {
  FloorWallKind get wallKind {
    if (isVirtual) return FloorWallKind.virtualWall;
    return floorWallKindFromKey(kind);
  }

  bool get isVirtualWall => wallKind == FloorWallKind.virtualWall;
  bool get isLoadBearingWall => wallKind == FloorWallKind.loadBearing;
  bool get isPartitionWall => wallKind == FloorWallKind.partition;
}



