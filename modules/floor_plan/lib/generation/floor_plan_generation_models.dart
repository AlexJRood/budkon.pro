import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:floor_plan/models/floor_plan_document.dart';
import 'package:get/get_utils/get_utils.dart';

enum FloorPlanWallMaskMode {
  darkOnly,
  colorOnly,
  darkAndColor,
}

extension FloorPlanWallMaskModeLabel on FloorPlanWallMaskMode {
  String get label {
    switch (this) {
      case FloorPlanWallMaskMode.darkOnly:
        return 'dark_only_mode'.tr;
      case FloorPlanWallMaskMode.colorOnly:
        return 'color_only_mode'.tr;
      case FloorPlanWallMaskMode.darkAndColor:
        return 'dark_and_color_mode'.tr;
    }
  }
}

enum FloorPlanDetectedObjectType {
  door,
  window,
  fixture,
  furniture,
  unknown,
}

extension FloorPlanDetectedObjectTypeLabel on FloorPlanDetectedObjectType {
  String get label {
    switch (this) {
      case FloorPlanDetectedObjectType.door:
        return 'door_object_label'.tr;
      case FloorPlanDetectedObjectType.window:
        return 'window_object_label'.tr;
      case FloorPlanDetectedObjectType.fixture:
        return 'fixture_object_label'.tr;
      case FloorPlanDetectedObjectType.furniture:
        return 'furniture_object_label'.tr;
      case FloorPlanDetectedObjectType.unknown:
        return 'custom_asset_label'.tr;
    }
  }
}

@immutable
class FloorPlanColorRule {
  final String id;
  final String label;
  final Color color;
  final double tolerance;
  final bool enabled;

  const FloorPlanColorRule({
    required this.id,
    required this.label,
    required this.color,
    this.tolerance = 78,
    this.enabled = true,
  });

  bool matchesRgb(int r, int g, int b) {
    if (!enabled) return false;

    final dr = r - color.red;
    final dg = g - color.green;
    final db = b - color.blue;

    final distanceSquared = (dr * dr) + (dg * dg) + (db * db);
    return distanceSquared <= tolerance * tolerance;
  }

  FloorPlanColorRule copyWith({
    String? id,
    String? label,
    Color? color,
    double? tolerance,
    bool? enabled,
  }) {
    return FloorPlanColorRule(
      id: id ?? this.id,
      label: label ?? this.label,
      color: color ?? this.color,
      tolerance: tolerance ?? this.tolerance,
      enabled: enabled ?? this.enabled,
    );
  }
}

@immutable
class FloorPlanDetectionSettings {
  static final defaultColorRules = <FloorPlanColorRule>[
    FloorPlanColorRule(
      id: 'blue',
      label: 'blue_color_label'.tr,
      color: Color(0xFF2563EB),
      tolerance: 92,
    ),
    FloorPlanColorRule(
      id: 'red',
      label: 'red_color_label'.tr,
      color: Color(0xFFDC2626),
      tolerance: 92,
    ),
    FloorPlanColorRule(
      id: 'green',
      label: 'green_color_label'.tr,
      color: Color(0xFF16A34A),
      tolerance: 92,
    ),
    FloorPlanColorRule(
      id: 'orange',
      label: 'orange_color_label'.tr,
      color: Color(0xFFF97316),
      tolerance: 92,
    ),
    FloorPlanColorRule(
      id: 'purple',
      label: 'purple_color_label'.tr,
      color: Color(0xFF9333EA),
      tolerance: 92,
    ),
    FloorPlanColorRule(
      id: 'cyan',
      label: 'cyan_color_label'.tr,
      color: Color(0xFF0891B2),
      tolerance: 92,
    ),
  ];

  final FloorPlanWallMaskMode wallMaskMode;
  final List<FloorPlanColorRule> colorRules;

  final int darkThreshold;
  final double minColoredSaturation;
  final int maxColoredLightness;

  final int minLineLengthPx;
  final int maxLineGapPx;
  final int mergeDistancePx;
  final double snapDistancePx;
  final double intersectionSnapDistancePx;

  final bool detectObjects;
  final int minObjectSizePx;
  final int maxObjectSizePx;
  final int minObjectPixels;
  final int lineExclusionRadiusPx;

  const FloorPlanDetectionSettings({
    this.wallMaskMode = FloorPlanWallMaskMode.darkAndColor,
    this.colorRules = const <FloorPlanColorRule>[],
    this.darkThreshold = 135,
    this.minColoredSaturation = 0.18,
    this.maxColoredLightness = 238,
    this.minLineLengthPx = 64,
    this.maxLineGapPx = 5,
    this.mergeDistancePx = 12,
    this.snapDistancePx = 16,
    this.intersectionSnapDistancePx = 20,
    this.detectObjects = true,
    this.minObjectSizePx = 10,
    this.maxObjectSizePx = 220,
    this.minObjectPixels = 36,
    this.lineExclusionRadiusPx = 7,
  });

  List<FloorPlanColorRule> get effectiveColorRules {
    return colorRules.isEmpty ? defaultColorRules : colorRules;
  }

  FloorPlanDetectionSettings copyWith({
    FloorPlanWallMaskMode? wallMaskMode,
    List<FloorPlanColorRule>? colorRules,
    int? darkThreshold,
    double? minColoredSaturation,
    int? maxColoredLightness,
    int? minLineLengthPx,
    int? maxLineGapPx,
    int? mergeDistancePx,
    double? snapDistancePx,
    double? intersectionSnapDistancePx,
    bool? detectObjects,
    int? minObjectSizePx,
    int? maxObjectSizePx,
    int? minObjectPixels,
    int? lineExclusionRadiusPx,
  }) {
    return FloorPlanDetectionSettings(
      wallMaskMode: wallMaskMode ?? this.wallMaskMode,
      colorRules: colorRules ?? this.colorRules,
      darkThreshold: darkThreshold ?? this.darkThreshold,
      minColoredSaturation:
          minColoredSaturation ?? this.minColoredSaturation,
      maxColoredLightness:
          maxColoredLightness ?? this.maxColoredLightness,
      minLineLengthPx: minLineLengthPx ?? this.minLineLengthPx,
      maxLineGapPx: maxLineGapPx ?? this.maxLineGapPx,
      mergeDistancePx: mergeDistancePx ?? this.mergeDistancePx,
      snapDistancePx: snapDistancePx ?? this.snapDistancePx,
      intersectionSnapDistancePx:
          intersectionSnapDistancePx ?? this.intersectionSnapDistancePx,
      detectObjects: detectObjects ?? this.detectObjects,
      minObjectSizePx: minObjectSizePx ?? this.minObjectSizePx,
      maxObjectSizePx: maxObjectSizePx ?? this.maxObjectSizePx,
      minObjectPixels: minObjectPixels ?? this.minObjectPixels,
      lineExclusionRadiusPx:
          lineExclusionRadiusPx ?? this.lineExclusionRadiusPx,
    );
  }
}

@immutable
class FloorPlanBackgroundImage {
  final String id;
  final Uint8List bytes;
  final double x;
  final double y;
  final double width;
  final double height;
  final double opacity;
  final double rotationDeg;
  final bool locked;

  const FloorPlanBackgroundImage({
    required this.id,
    required this.bytes,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.opacity = 0.42,
    this.rotationDeg = 0,
    this.locked = true,
  });

  FloorPlanBackgroundImage copyWith({
    String? id,
    Uint8List? bytes,
    double? x,
    double? y,
    double? width,
    double? height,
    double? opacity,
    double? rotationDeg,
    bool? locked,
  }) {
    return FloorPlanBackgroundImage(
      id: id ?? this.id,
      bytes: bytes ?? this.bytes,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      opacity: opacity ?? this.opacity,
      rotationDeg: rotationDeg ?? this.rotationDeg,
      locked: locked ?? this.locked,
    );
  }
}

@immutable
class FloorPlanDetectedLine {
  final Offset start;
  final Offset end;
  final double confidence;

  const FloorPlanDetectedLine({
    required this.start,
    required this.end,
    this.confidence = 1,
  });

  double get lengthPx => (end - start).distance;

  bool get isValid => lengthPx > 4;

  bool get isMostlyHorizontal {
    final dx = (end.dx - start.dx).abs();
    final dy = (end.dy - start.dy).abs();
    return dx >= dy;
  }

  bool get isMostlyVertical => !isMostlyHorizontal;

  bool get isHorizontal {
    final dx = (end.dx - start.dx).abs();
    final dy = (end.dy - start.dy).abs();
    return dy <= 6 && dx > dy;
  }

  bool get isVertical {
    final dx = (end.dx - start.dx).abs();
    final dy = (end.dy - start.dy).abs();
    return dx <= 6 && dy > dx;
  }

  double lengthMeters(double pixelsPerMeter) {
    if (pixelsPerMeter <= 0) return 0;
    return lengthPx / pixelsPerMeter;
  }

  FloorPlanDetectedLine copyWith({
    Offset? start,
    Offset? end,
    double? confidence,
  }) {
    return FloorPlanDetectedLine(
      start: start ?? this.start,
      end: end ?? this.end,
      confidence: confidence ?? this.confidence,
    );
  }

  FloorPlanDetectedLine normalizedAxisAligned() {
    if (isMostlyHorizontal) {
      final y = (start.dy + end.dy) / 2;
      final minX = start.dx < end.dx ? start.dx : end.dx;
      final maxX = start.dx > end.dx ? start.dx : end.dx;

      return copyWith(
        start: Offset(minX, y),
        end: Offset(maxX, y),
      );
    }

    final x = (start.dx + end.dx) / 2;
    final minY = start.dy < end.dy ? start.dy : end.dy;
    final maxY = start.dy > end.dy ? start.dy : end.dy;

    return copyWith(
      start: Offset(x, minY),
      end: Offset(x, maxY),
    );
  }

  FloorWall toWall({
    required int index,
    double thicknessCm = 12,
    bool isVirtual = false,
  }) {
    return FloorWall(
      id: 'generated_wall_${DateTime.now().microsecondsSinceEpoch}_$index',
      start: FloorPoint(x: start.dx, y: start.dy),
      end: FloorPoint(x: end.dx, y: end.dy),
      thickness: thicknessCm,
      heightM: 2.6,
      kind: isVirtual ? FloorWall.kindVirtual : FloorWall.kindStructural,
    );
  }
}

@immutable
class FloorPlanDetectedObject {
  final String id;
  final Rect bounds;
  final FloorPlanDetectedObjectType type;
  final double confidence;
  final String? label;

  const FloorPlanDetectedObject({
    required this.id,
    required this.bounds,
    this.type = FloorPlanDetectedObjectType.unknown,
    this.confidence = 1,
    this.label,
  });

  Offset get center => bounds.center;

  double get widthPx => bounds.width;

  double get heightPx => bounds.height;

  double widthMeters(double pixelsPerMeter) {
    if (pixelsPerMeter <= 0) return 0;
    return widthPx / pixelsPerMeter;
  }

  double heightMeters(double pixelsPerMeter) {
    if (pixelsPerMeter <= 0) return 0;
    return heightPx / pixelsPerMeter;
  }

  FloorPlanDetectedObject copyWith({
    String? id,
    Rect? bounds,
    FloorPlanDetectedObjectType? type,
    double? confidence,
    String? label,
  }) {
    return FloorPlanDetectedObject(
      id: id ?? this.id,
      bounds: bounds ?? this.bounds,
      type: type ?? this.type,
      confidence: confidence ?? this.confidence,
      label: label ?? this.label,
    );
  }
}

@immutable
class FloorPlanGenerationMetrics {
  final int wallCount;
  final int objectCount;
  final double totalWallLengthM;
  final double longestWallLengthM;
  final double estimatedFootprintAreaM2;
  final double averageConfidence;

  const FloorPlanGenerationMetrics({
    required this.wallCount,
    required this.objectCount,
    required this.totalWallLengthM,
    required this.longestWallLengthM,
    required this.estimatedFootprintAreaM2,
    required this.averageConfidence,
  });

  factory FloorPlanGenerationMetrics.fromDetection({
    required List<FloorPlanDetectedLine> lines,
    required List<FloorPlanDetectedObject> objects,
    required double pixelsPerMeter,
  }) {
    final validLines = lines.where((line) => line.isValid).toList();

    var totalLength = 0.0;
    var longest = 0.0;
    var confidenceSum = 0.0;

    double? minX;
    double? minY;
    double? maxX;
    double? maxY;

    void includePoint(Offset point) {
      minX = minX == null ? point.dx : (point.dx < minX! ? point.dx : minX);
      minY = minY == null ? point.dy : (point.dy < minY! ? point.dy : minY);
      maxX = maxX == null ? point.dx : (point.dx > maxX! ? point.dx : maxX);
      maxY = maxY == null ? point.dy : (point.dy > maxY! ? point.dy : maxY);
    }

    for (final line in validLines) {
      final length = line.lengthMeters(pixelsPerMeter);

      totalLength += length;
      if (length > longest) longest = length;

      confidenceSum += line.confidence;

      includePoint(line.start);
      includePoint(line.end);
    }

    for (final object in objects) {
      includePoint(object.bounds.topLeft);
      includePoint(object.bounds.bottomRight);
    }

    var area = 0.0;

    if (pixelsPerMeter > 0 &&
        minX != null &&
        minY != null &&
        maxX != null &&
        maxY != null) {
      final widthM = (maxX! - minX!).abs() / pixelsPerMeter;
      final heightM = (maxY! - minY!).abs() / pixelsPerMeter;
      area = widthM * heightM;
    }

    return FloorPlanGenerationMetrics(
      wallCount: validLines.length,
      objectCount: objects.length,
      totalWallLengthM: totalLength,
      longestWallLengthM: longest,
      estimatedFootprintAreaM2: area,
      averageConfidence:
          validLines.isEmpty ? 0 : confidenceSum / validLines.length,
    );
  }
}

@immutable
class FloorPlanImageAnalysisResult {
  final List<FloorPlanDetectedLine> lines;
  final List<FloorPlanDetectedObject> objects;
  final FloorPlanGenerationMetrics metrics;

  const FloorPlanImageAnalysisResult({
    required this.lines,
    required this.objects,
    required this.metrics,
  });
}

@immutable
class FloorPlanGeneratedDraft {
  final Uint8List imageBytes;
  final int imageWidth;
  final int imageHeight;
  final double pixelsPerMeter;
  final List<FloorPlanDetectedLine> lines;
  final List<FloorPlanDetectedObject> objects;
  final FloorPlanGenerationMetrics? metrics;

  const FloorPlanGeneratedDraft({
    required this.imageBytes,
    required this.imageWidth,
    required this.imageHeight,
    required this.pixelsPerMeter,
    required this.lines,
    this.objects = const <FloorPlanDetectedObject>[],
    this.metrics,
  });

  FloorPlanBackgroundImage toBackgroundImage() {
    return FloorPlanBackgroundImage(
      id: 'background_${DateTime.now().microsecondsSinceEpoch}',
      bytes: imageBytes,
      x: 0,
      y: 0,
      width: imageWidth.toDouble(),
      height: imageHeight.toDouble(),
      opacity: 0.42,
      rotationDeg: 0,
      locked: true,
    );
  }

  List<FloorWall> toWalls() {
    final result = <FloorWall>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (!line.isValid) continue;

      result.add(
        line.toWall(
          index: i,
          thicknessCm: 12,
        ),
      );
    }

    return result;
  }
}

@immutable
class FloorPlanGenerationApplyResult {
  final FloorPlanGeneratedDraft draft;
  final bool replaceExistingWalls;
  final bool useImageAsBackground;

  const FloorPlanGenerationApplyResult({
    required this.draft,
    required this.replaceExistingWalls,
    required this.useImageAsBackground,
  });
}

class FloorPlanCalibrationPoint {
  final Offset point;

  const FloorPlanCalibrationPoint({
    required this.point,
  });
}

Future<ui.Image> decodeFloorPlanImage(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  return frame.image;
}