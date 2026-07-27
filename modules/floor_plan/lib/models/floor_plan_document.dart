import 'dart:math' as math;
import 'dart:ui';

class FloorPlanDocument {
  final FloorPlanCanvasConfig canvas;
  final FloorPlanScale scale;
  final String unit;

  final List<FloorWall> walls;
  final List<Map<String, dynamic>> doors;
  final List<Map<String, dynamic>> windows;
  final List<FloorRoom> rooms;
  final List<FloorPlanAsset> assets;

  const FloorPlanDocument({
    required this.canvas,
    required this.scale,
    this.unit = 'm',
    this.walls = const [],
    this.doors = const [],
    this.windows = const [],
    this.rooms = const [],
    this.assets = const [],
  });

  factory FloorPlanDocument.empty() {
    return const FloorPlanDocument(
      canvas: FloorPlanCanvasConfig(
        width: 2400,
        height: 1800,
        gridSize: 20,
      ),
      scale: FloorPlanScale(
        pixelsPerMeter: 100,
      ),
    );
  }

  FloorPlanDocument copyWith({
    FloorPlanCanvasConfig? canvas,
    FloorPlanScale? scale,
    String? unit,
    List<FloorWall>? walls,
    List<Map<String, dynamic>>? doors,
    List<Map<String, dynamic>>? windows,
    List<FloorRoom>? rooms,
    List<FloorPlanAsset>? assets,
  }) {
    return FloorPlanDocument(
      canvas: canvas ?? this.canvas,
      scale: scale ?? this.scale,
      unit: unit ?? this.unit,
      walls: walls ?? this.walls,
      doors: doors ?? this.doors,
      windows: windows ?? this.windows,
      rooms: rooms ?? this.rooms,
      assets: assets ?? this.assets,
    );
  }

  factory FloorPlanDocument.fromJson(Map<String, dynamic> json) {
    return FloorPlanDocument(
      canvas: FloorPlanCanvasConfig.fromJson(
        Map<String, dynamic>.from(json['canvas'] ?? {}),
      ),
      scale: FloorPlanScale.fromJson(
        Map<String, dynamic>.from(json['scale'] ?? {}),
      ),
      unit: json['unit']?.toString() ?? 'm',
      walls: ((json['walls'] as List?) ?? [])
          .map((item) => FloorWall.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      doors: ((json['doors'] as List?) ?? [])
          .map((item) => Map<String, dynamic>.from(item))
          .toList(),
      windows: ((json['windows'] as List?) ?? [])
          .map((item) => Map<String, dynamic>.from(item))
          .toList(),
      rooms: ((json['rooms'] as List?) ?? [])
          .map((item) => FloorRoom.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      assets: ((json['assets'] as List?) ?? [])
          .map(
            (item) => FloorPlanAsset.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'canvas': canvas.toJson(),
      'scale': scale.toJson(),
      'unit': unit,
      'walls': walls.map((item) => item.toJson()).toList(),
      'doors': doors,
      'windows': windows,
      'rooms': rooms.map((item) => item.toJson()).toList(),
      'assets': assets.map((item) => item.toJson()).toList(),
    };
  }
}

class FloorPlanCanvasConfig {
  final double width;
  final double height;
  final double gridSize;

  const FloorPlanCanvasConfig({
    required this.width,
    required this.height,
    required this.gridSize,
  });

  factory FloorPlanCanvasConfig.fromJson(Map<String, dynamic> json) {
    return FloorPlanCanvasConfig(
      width: (json['width'] as num?)?.toDouble() ?? 2400,
      height: (json['height'] as num?)?.toDouble() ?? 1800,
      gridSize: (json['grid_size'] ?? json['gridSize'] as num?)?.toDouble() ??
          20,
    );
  }

  FloorPlanCanvasConfig copyWith({
    double? width,
    double? height,
    double? gridSize,
  }) {
    return FloorPlanCanvasConfig(
      width: width ?? this.width,
      height: height ?? this.height,
      gridSize: gridSize ?? this.gridSize,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'width': width,
      'height': height,
      'grid_size': gridSize,
    };
  }
}

class FloorPlanScale {
  final double pixelsPerMeter;

  const FloorPlanScale({
    required this.pixelsPerMeter,
  });

  factory FloorPlanScale.fromJson(Map<String, dynamic> json) {
    return FloorPlanScale(
      pixelsPerMeter:
          (json['pixels_per_meter'] ?? json['pixelsPerMeter'] as num?)
                  ?.toDouble() ??
              100,
    );
  }

  FloorPlanScale copyWith({double? pixelsPerMeter}) {
    return FloorPlanScale(
      pixelsPerMeter: pixelsPerMeter ?? this.pixelsPerMeter,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pixels_per_meter': pixelsPerMeter,
    };
  }
}

class FloorPoint {
  final double x;
  final double y;

  const FloorPoint({
    required this.x,
    required this.y,
  });

  factory FloorPoint.fromOffset(Offset offset) {
    return FloorPoint(
      x: offset.dx,
      y: offset.dy,
    );
  }

  factory FloorPoint.fromJson(Map<String, dynamic> json) {
    return FloorPoint(
      x: (json['x'] as num?)?.toDouble() ?? 0,
      y: (json['y'] as num?)?.toDouble() ?? 0,
    );
  }

  Offset toOffset() {
    return Offset(x, y);
  }

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
    };
  }
}

class FloorWall {
  static const String kindStructural = 'structural';
  static const String kindVirtual = 'virtual';

  final String id;
  final FloorPoint start;
  final FloorPoint end;

  /// Backward-compatible.
  /// This is now interpreted as centimeters.
  /// Example: 12 = 12 cm.
  final double thickness;

  final double heightM;
  final String? material;

  final bool angleLocked;
  final double? lockedAngleDeg;

  final bool lengthLocked;
  final double? lockedLengthM;

  final String kind;

  const FloorWall({
    required this.id,
    required this.start,
    required this.end,
    this.thickness = 12,
    this.heightM = 2.6,
    this.material,
    this.angleLocked = false,
    this.lockedAngleDeg,
    this.lengthLocked = false,
    this.lockedLengthM,
    this.kind = kindStructural,
  });

  bool get isVirtual => kind == kindVirtual;

  double lengthPx() {
    return (end.toOffset() - start.toOffset()).distance;
  }

  double lengthM(double pixelsPerMeter) {
    if (pixelsPerMeter <= 0) return 0;
    return lengthPx() / pixelsPerMeter;
  }

  factory FloorWall.fromJson(Map<String, dynamic> json) {
    return FloorWall(
      id: json['id']?.toString() ??
          'wall_${DateTime.now().microsecondsSinceEpoch}',
      start: FloorPoint.fromJson(
        Map<String, dynamic>.from(json['start'] ?? {}),
      ),
      end: FloorPoint.fromJson(
        Map<String, dynamic>.from(json['end'] ?? {}),
      ),
      thickness: (json['thickness'] as num?)?.toDouble() ?? 12,
      heightM: (json['height_m'] ?? json['heightM'] as num?)?.toDouble() ?? 2.6,
      material: json['material']?.toString(),
      angleLocked:
          (json['angle_locked'] ?? json['angleLocked'] as bool?) ?? false,
      lockedAngleDeg:
          (json['locked_angle_deg'] ?? json['lockedAngleDeg'] as num?)
              ?.toDouble(),
      lengthLocked:
          (json['length_locked'] ?? json['lengthLocked'] as bool?) ?? false,
      lockedLengthM:
          (json['locked_length_m'] ?? json['lockedLengthM'] as num?)
              ?.toDouble(),
      kind: json['kind']?.toString() ?? kindStructural,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'start': start.toJson(),
      'end': end.toJson(),
      'thickness': thickness,
      'height_m': heightM,
      'material': material,
      'angle_locked': angleLocked,
      'locked_angle_deg': lockedAngleDeg,
      'length_locked': lengthLocked,
      'locked_length_m': lockedLengthM,
      'kind': kind,
    };
  }
}

class FloorRoom {
  final String id;
  final String name;
  final List<FloorPoint> points;
  final String? colorHex;
  final bool showName;
  final bool showArea;

  const FloorRoom({
    required this.id,
    required this.name,
    required this.points,
    this.colorHex,
    this.showName = true,
    this.showArea = true,
  });

  List<Offset> get offsets => points.map((item) => item.toOffset()).toList();

  double areaM2(double pixelsPerMeter) {
    if (points.length < 3 || pixelsPerMeter <= 0) return 0;

    double sum = 0;
    final pts = offsets;

    for (var i = 0; i < pts.length; i++) {
      final a = pts[i];
      final b = pts[(i + 1) % pts.length];

      sum += a.dx * b.dy - b.dx * a.dy;
    }

    final areaPx2 = sum.abs() / 2;
    return areaPx2 / (pixelsPerMeter * pixelsPerMeter);
  }

  Offset centroid() {
    final pts = offsets;
    if (pts.isEmpty) return Offset.zero;

    double signedArea = 0;
    double cx = 0;
    double cy = 0;

    for (var i = 0; i < pts.length; i++) {
      final a = pts[i];
      final b = pts[(i + 1) % pts.length];

      final cross = a.dx * b.dy - b.dx * a.dy;
      signedArea += cross;
      cx += (a.dx + b.dx) * cross;
      cy += (a.dy + b.dy) * cross;
    }

    signedArea *= 0.5;

    if (signedArea.abs() < 0.001) {
      final x = pts.map((e) => e.dx).reduce((a, b) => a + b) / pts.length;
      final y = pts.map((e) => e.dy).reduce((a, b) => a + b) / pts.length;
      return Offset(x, y);
    }

    cx /= 6 * signedArea;
    cy /= 6 * signedArea;

    return Offset(cx, cy);
  }

  factory FloorRoom.fromJson(Map<String, dynamic> json) {
    return FloorRoom(
      id: json['id']?.toString() ??
          'room_${DateTime.now().microsecondsSinceEpoch}',
      name: json['name']?.toString() ?? 'Pomieszczenie',
      points: ((json['points'] as List?) ?? [])
          .map((item) => FloorPoint.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      colorHex: json['color_hex']?.toString() ?? json['colorHex']?.toString(),
      showName: (json['show_name'] ?? json['showName'] as bool?) ?? true,
      showArea: (json['show_area'] ?? json['showArea'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'points': points.map((item) => item.toJson()).toList(),
      'color_hex': colorHex,
      'show_name': showName,
      'show_area': showArea,
    };
  }
}

class FloorPlanAsset {
  final String id;
  final String type;
  final FloorPoint position;
  final double widthM;
  final double depthM;
  final double rotationDeg;
  final String? label;

  const FloorPlanAsset({
    required this.id,
    required this.type,
    required this.position,
    required this.widthM,
    required this.depthM,
    this.rotationDeg = 0,
    this.label,
  });

  factory FloorPlanAsset.fromJson(Map<String, dynamic> json) {
    return FloorPlanAsset(
      id: json['id']?.toString() ??
          'asset_${DateTime.now().microsecondsSinceEpoch}',
      type: json['type']?.toString() ?? 'custom',
      position: FloorPoint.fromJson(
        Map<String, dynamic>.from(json['position'] ?? {}),
      ),
      widthM: (json['width_m'] ?? json['widthM'] as num?)?.toDouble() ?? 1,
      depthM: (json['depth_m'] ?? json['depthM'] as num?)?.toDouble() ?? 1,
      rotationDeg:
          (json['rotation_deg'] ?? json['rotationDeg'] as num?)?.toDouble() ??
              0,
      label: json['label']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'position': position.toJson(),
      'width_m': widthM,
      'depth_m': depthM,
      'rotation_deg': rotationDeg,
      'label': label,
    };
  }
}

double floorPlanDistance(Offset a, Offset b) {
  return math.sqrt(math.pow(a.dx - b.dx, 2) + math.pow(a.dy - b.dy, 2));
}