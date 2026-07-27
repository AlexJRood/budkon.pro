import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:floor_plan/generation/floor_plan_generation_models.dart';

class FloorPlanFrontGeneratorService {
  const FloorPlanFrontGeneratorService();

  Future<List<FloorPlanDetectedLine>> detectWallsFromImage({
    required ui.Image image,
    required double pixelsPerMeter,
    int darkThreshold = 135,
    double minDarkRatio = 0.32,
    int minLineLengthPx = 64,
    int mergeDistancePx = 12,
    FloorPlanWallMaskMode wallMaskMode = FloorPlanWallMaskMode.darkAndColor,
  }) async {
    final result = await analyzeFloorPlanImage(
      image: image,
      pixelsPerMeter: pixelsPerMeter,
      settings: FloorPlanDetectionSettings(
        wallMaskMode: wallMaskMode,
        darkThreshold: darkThreshold,
        minLineLengthPx: minLineLengthPx,
        mergeDistancePx: mergeDistancePx,
        detectObjects: false,
      ),
    );

    return result.lines;
  }

  Future<FloorPlanImageAnalysisResult> analyzeFloorPlanImage({
    required ui.Image image,
    required double pixelsPerMeter,
    FloorPlanDetectionSettings settings = const FloorPlanDetectionSettings(),
  }) async {
    final byteData = await image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );

    if (byteData == null) {
      const metrics = FloorPlanGenerationMetrics(
        wallCount: 0,
        objectCount: 0,
        totalWallLengthM: 0,
        longestWallLengthM: 0,
        estimatedFootprintAreaM2: 0,
        averageConfidence: 0,
      );

      return const FloorPlanImageAnalysisResult(
        lines: <FloorPlanDetectedLine>[],
        objects: <FloorPlanDetectedObject>[],
        metrics: metrics,
      );
    }

    final width = image.width;
    final height = image.height;
    final bytes = byteData.buffer.asUint8List();

    final wallMask = _buildWallMask(
      bytes: bytes,
      width: width,
      height: height,
      settings: settings,
    );

    final horizontal = _detectHorizontalLines(
      wallMask: wallMask,
      width: width,
      height: height,
      minLineLengthPx: settings.minLineLengthPx,
      maxLineGapPx: settings.maxLineGapPx,
    );

    final vertical = _detectVerticalLines(
      wallMask: wallMask,
      width: width,
      height: height,
      minLineLengthPx: settings.minLineLengthPx,
      maxLineGapPx: settings.maxLineGapPx,
    );

    var lines = _mergeCollinearLines(
      <FloorPlanDetectedLine>[
        ...horizontal,
        ...vertical,
      ],
      mergeDistancePx: settings.mergeDistancePx,
    );

    lines = _snapAxisAlignedIntersections(
      lines,
      snapDistancePx: settings.intersectionSnapDistancePx,
    );

    lines = _clusterLineEndpoints(
      lines,
      snapDistancePx: settings.snapDistancePx,
    );

    lines = _dedupeAndFilterLines(
      lines,
      minLengthPx: math.max(12, settings.minLineLengthPx * 0.55),
    );

    final objects = settings.detectObjects
        ? _detectObjects(
            wallMask: wallMask,
            width: width,
            height: height,
            lines: lines,
            settings: settings,
          )
        : const <FloorPlanDetectedObject>[];

    final metrics = FloorPlanGenerationMetrics.fromDetection(
      lines: lines,
      objects: objects,
      pixelsPerMeter: pixelsPerMeter,
    );

    return FloorPlanImageAnalysisResult(
      lines: lines,
      objects: objects,
      metrics: metrics,
    );
  }

  List<bool> _buildWallMask({
    required Uint8List bytes,
    required int width,
    required int height,
    required FloorPlanDetectionSettings settings,
  }) {
    final result = List<bool>.filled(width * height, false);
    final colorRules = settings.effectiveColorRules;

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final i = (y * width + x) * 4;

        final r = bytes[i];
        final g = bytes[i + 1];
        final b = bytes[i + 2];
        final a = bytes[i + 3];

        if (a < 30) continue;

        final gray = ((r * 0.299) + (g * 0.587) + (b * 0.114)).round();

        final maxChannel = math.max(r, math.max(g, b));
        final minChannel = math.min(r, math.min(g, b));
        final saturation =
            maxChannel == 0 ? 0.0 : (maxChannel - minChannel) / maxChannel;

        final isDark = gray <= settings.darkThreshold;

        final matchesNamedColor = colorRules.any(
          (rule) => rule.matchesRgb(r, g, b),
        );

        final isClearlyColored = saturation >= settings.minColoredSaturation &&
            gray <= settings.maxColoredLightness;

        final isColor = matchesNamedColor || isClearlyColored;

        switch (settings.wallMaskMode) {
          case FloorPlanWallMaskMode.darkOnly:
            result[y * width + x] = isDark;
            break;
          case FloorPlanWallMaskMode.colorOnly:
            result[y * width + x] = isColor;
            break;
          case FloorPlanWallMaskMode.darkAndColor:
            result[y * width + x] = isDark || isColor;
            break;
        }
      }
    }

    return result;
  }

  List<FloorPlanDetectedLine> _detectHorizontalLines({
    required List<bool> wallMask,
    required int width,
    required int height,
    required int minLineLengthPx,
    required int maxLineGapPx,
  }) {
    final result = <FloorPlanDetectedLine>[];

    for (var y = 0; y < height; y++) {
      final ranges = _darkRangesInRow(
        wallMask: wallMask,
        width: width,
        y: y,
        minLineLengthPx: minLineLengthPx,
        maxLineGapPx: maxLineGapPx,
      );

      for (final range in ranges) {
        result.add(
          FloorPlanDetectedLine(
            start: Offset(range.start.toDouble(), y.toDouble()),
            end: Offset(range.end.toDouble(), y.toDouble()),
            confidence: 0.68,
          ),
        );
      }
    }

    return _mergeHorizontal(result, math.max(2, maxLineGapPx + 2));
  }

  List<FloorPlanDetectedLine> _detectVerticalLines({
    required List<bool> wallMask,
    required int width,
    required int height,
    required int minLineLengthPx,
    required int maxLineGapPx,
  }) {
    final result = <FloorPlanDetectedLine>[];

    for (var x = 0; x < width; x++) {
      final ranges = _darkRangesInColumn(
        wallMask: wallMask,
        width: width,
        height: height,
        x: x,
        minLineLengthPx: minLineLengthPx,
        maxLineGapPx: maxLineGapPx,
      );

      for (final range in ranges) {
        result.add(
          FloorPlanDetectedLine(
            start: Offset(x.toDouble(), range.start.toDouble()),
            end: Offset(x.toDouble(), range.end.toDouble()),
            confidence: 0.68,
          ),
        );
      }
    }

    return _mergeVertical(result, math.max(2, maxLineGapPx + 2));
  }

  List<_IntRange> _darkRangesInRow({
    required List<bool> wallMask,
    required int width,
    required int y,
    required int minLineLengthPx,
    required int maxLineGapPx,
  }) {
    final ranges = <_IntRange>[];

    var start = -1;
    var lastHit = -1;
    var gap = 0;

    for (var x = 0; x < width; x++) {
      final isDark = wallMask[y * width + x];

      if (isDark) {
        if (start < 0) start = x;
        lastHit = x;
        gap = 0;
      } else if (start >= 0) {
        gap++;

        if (gap > maxLineGapPx) {
          if (lastHit - start + 1 >= minLineLengthPx) {
            ranges.add(_IntRange(start, lastHit));
          }

          start = -1;
          lastHit = -1;
          gap = 0;
        }
      }
    }

    if (start >= 0 && lastHit - start + 1 >= minLineLengthPx) {
      ranges.add(_IntRange(start, lastHit));
    }

    return ranges;
  }

  List<_IntRange> _darkRangesInColumn({
    required List<bool> wallMask,
    required int width,
    required int height,
    required int x,
    required int minLineLengthPx,
    required int maxLineGapPx,
  }) {
    final ranges = <_IntRange>[];

    var start = -1;
    var lastHit = -1;
    var gap = 0;

    for (var y = 0; y < height; y++) {
      final isDark = wallMask[y * width + x];

      if (isDark) {
        if (start < 0) start = y;
        lastHit = y;
        gap = 0;
      } else if (start >= 0) {
        gap++;

        if (gap > maxLineGapPx) {
          if (lastHit - start + 1 >= minLineLengthPx) {
            ranges.add(_IntRange(start, lastHit));
          }

          start = -1;
          lastHit = -1;
          gap = 0;
        }
      }
    }

    if (start >= 0 && lastHit - start + 1 >= minLineLengthPx) {
      ranges.add(_IntRange(start, lastHit));
    }

    return ranges;
  }

  List<FloorPlanDetectedLine> _mergeCollinearLines(
    List<FloorPlanDetectedLine> lines, {
    required int mergeDistancePx,
  }) {
    final horizontal = <FloorPlanDetectedLine>[];
    final vertical = <FloorPlanDetectedLine>[];
    final other = <FloorPlanDetectedLine>[];

    for (final line in lines) {
      final normalized = line.normalizedAxisAligned();

      if (normalized.isHorizontal) {
        horizontal.add(normalized);
      } else if (normalized.isVertical) {
        vertical.add(normalized);
      } else {
        other.add(normalized);
      }
    }

    return <FloorPlanDetectedLine>[
      ..._mergeHorizontal(horizontal, mergeDistancePx),
      ..._mergeVertical(vertical, mergeDistancePx),
      ...other,
    ];
  }

  List<FloorPlanDetectedLine> _mergeHorizontal(
    List<FloorPlanDetectedLine> source,
    int mergeDistancePx,
  ) {
    final lines = source.map((line) => line.normalizedAxisAligned()).toList()
      ..sort((a, b) {
        final ay = a.start.dy.compareTo(b.start.dy);
        if (ay != 0) return ay;
        return a.start.dx.compareTo(b.start.dx);
      });

    final result = <FloorPlanDetectedLine>[];

    for (final line in lines) {
      var merged = false;

      for (var i = 0; i < result.length; i++) {
        final current = result[i];

        final sameY =
            (current.start.dy - line.start.dy).abs() <= mergeDistancePx;

        final touches = _rangesTouchOrOverlap(
          current.start.dx,
          current.end.dx,
          line.start.dx,
          line.end.dx,
          mergeDistancePx.toDouble(),
        );

        if (!sameY || !touches) continue;

        final minX = math.min(current.start.dx, line.start.dx);
        final maxX = math.max(current.end.dx, line.end.dx);

        final currentLength = current.lengthPx;
        final lineLength = line.lengthPx;
        final totalLength = math.max(1.0, currentLength + lineLength);

        final weightedY =
            ((current.start.dy * currentLength) + (line.start.dy * lineLength)) /
                totalLength;

        result[i] = FloorPlanDetectedLine(
          start: Offset(minX, weightedY),
          end: Offset(maxX, weightedY),
          confidence: math.max(current.confidence, line.confidence),
        );

        merged = true;
        break;
      }

      if (!merged) {
        result.add(line);
      }
    }

    return result;
  }

  List<FloorPlanDetectedLine> _mergeVertical(
    List<FloorPlanDetectedLine> source,
    int mergeDistancePx,
  ) {
    final lines = source.map((line) => line.normalizedAxisAligned()).toList()
      ..sort((a, b) {
        final ax = a.start.dx.compareTo(b.start.dx);
        if (ax != 0) return ax;
        return a.start.dy.compareTo(b.start.dy);
      });

    final result = <FloorPlanDetectedLine>[];

    for (final line in lines) {
      var merged = false;

      for (var i = 0; i < result.length; i++) {
        final current = result[i];

        final sameX =
            (current.start.dx - line.start.dx).abs() <= mergeDistancePx;

        final touches = _rangesTouchOrOverlap(
          current.start.dy,
          current.end.dy,
          line.start.dy,
          line.end.dy,
          mergeDistancePx.toDouble(),
        );

        if (!sameX || !touches) continue;

        final minY = math.min(current.start.dy, line.start.dy);
        final maxY = math.max(current.end.dy, line.end.dy);

        final currentLength = current.lengthPx;
        final lineLength = line.lengthPx;
        final totalLength = math.max(1.0, currentLength + lineLength);

        final weightedX =
            ((current.start.dx * currentLength) + (line.start.dx * lineLength)) /
                totalLength;

        result[i] = FloorPlanDetectedLine(
          start: Offset(weightedX, minY),
          end: Offset(weightedX, maxY),
          confidence: math.max(current.confidence, line.confidence),
        );

        merged = true;
        break;
      }

      if (!merged) {
        result.add(line);
      }
    }

    return result;
  }

  bool _rangesTouchOrOverlap(
    double aStart,
    double aEnd,
    double bStart,
    double bEnd,
    double tolerance,
  ) {
    final aMin = math.min(aStart, aEnd);
    final aMax = math.max(aStart, aEnd);
    final bMin = math.min(bStart, bEnd);
    final bMax = math.max(bStart, bEnd);

    return bMin <= aMax + tolerance && aMin <= bMax + tolerance;
  }

  List<FloorPlanDetectedLine> _snapAxisAlignedIntersections(
    List<FloorPlanDetectedLine> source, {
    required double snapDistancePx,
  }) {
    final lines = source
        .map((line) => line.normalizedAxisAligned())
        .where((line) => line.isValid)
        .toList();

    for (var i = 0; i < lines.length; i++) {
      final a = lines[i];

      if (!a.isHorizontal) continue;

      for (var j = 0; j < lines.length; j++) {
        if (i == j) continue;

        final b = lines[j];
        if (!b.isVertical) continue;

        final y = a.start.dy;
        final x = b.start.dx;

        final hMinX = math.min(a.start.dx, a.end.dx);
        final hMaxX = math.max(a.start.dx, a.end.dx);

        final vMinY = math.min(b.start.dy, b.end.dy);
        final vMaxY = math.max(b.start.dy, b.end.dy);

        final xNearHorizontal =
            x >= hMinX - snapDistancePx && x <= hMaxX + snapDistancePx;

        final yNearVertical =
            y >= vMinY - snapDistancePx && y <= vMaxY + snapDistancePx;

        if (!xNearHorizontal || !yNearVertical) continue;

        lines[i] = _extendHorizontalToX(lines[i], x);
        lines[j] = _extendVerticalToY(lines[j], y);
      }
    }

    return lines;
  }

  FloorPlanDetectedLine _extendHorizontalToX(
    FloorPlanDetectedLine line,
    double x,
  ) {
    final normalized = line.normalizedAxisAligned();

    final y = normalized.start.dy;
    final minX = math.min(normalized.start.dx, normalized.end.dx);
    final maxX = math.max(normalized.start.dx, normalized.end.dx);

    return normalized.copyWith(
      start: Offset(math.min(minX, x), y),
      end: Offset(math.max(maxX, x), y),
    );
  }

  FloorPlanDetectedLine _extendVerticalToY(
    FloorPlanDetectedLine line,
    double y,
  ) {
    final normalized = line.normalizedAxisAligned();

    final x = normalized.start.dx;
    final minY = math.min(normalized.start.dy, normalized.end.dy);
    final maxY = math.max(normalized.start.dy, normalized.end.dy);

    return normalized.copyWith(
      start: Offset(x, math.min(minY, y)),
      end: Offset(x, math.max(maxY, y)),
    );
  }

  List<FloorPlanDetectedLine> _clusterLineEndpoints(
    List<FloorPlanDetectedLine> source, {
    required double snapDistancePx,
  }) {
    final lines = source
        .map((line) => line.normalizedAxisAligned())
        .where((line) => line.isValid)
        .toList();

    final endpoints = <_EndpointRef>[];

    for (var i = 0; i < lines.length; i++) {
      endpoints.add(_EndpointRef(lineIndex: i, isStart: true, point: lines[i].start));
      endpoints.add(_EndpointRef(lineIndex: i, isStart: false, point: lines[i].end));
    }

    final visited = List<bool>.filled(endpoints.length, false);

    for (var i = 0; i < endpoints.length; i++) {
      if (visited[i]) continue;

      final group = <int>[i];
      visited[i] = true;

      for (var j = i + 1; j < endpoints.length; j++) {
        if (visited[j]) continue;

        final distance = (endpoints[i].point - endpoints[j].point).distance;

        if (distance <= snapDistancePx) {
          visited[j] = true;
          group.add(j);
        }
      }

      if (group.length <= 1) continue;

      var sumX = 0.0;
      var sumY = 0.0;

      for (final endpointIndex in group) {
        final point = endpoints[endpointIndex].point;
        sumX += point.dx;
        sumY += point.dy;
      }

      final snapped = Offset(sumX / group.length, sumY / group.length);

      for (final endpointIndex in group) {
        final endpoint = endpoints[endpointIndex];
        final line = lines[endpoint.lineIndex];

        lines[endpoint.lineIndex] = endpoint.isStart
            ? line.copyWith(start: snapped)
            : line.copyWith(end: snapped);
      }
    }

    return lines
        .map((line) => line.normalizedAxisAligned())
        .where((line) => line.isValid)
        .toList();
  }

  List<FloorPlanDetectedLine> _dedupeAndFilterLines(
    List<FloorPlanDetectedLine> source, {
    required double minLengthPx,
  }) {
    final result = <FloorPlanDetectedLine>[];

    for (final raw in source) {
      final line = raw.normalizedAxisAligned();

      if (!line.isValid) continue;
      if (line.lengthPx < minLengthPx) continue;

      final duplicate = result.any(
        (existing) => _isAlmostSameLine(existing, line),
      );

      if (!duplicate) {
        result.add(line);
      }
    }

    result.sort((a, b) {
      final ay = a.start.dy.compareTo(b.start.dy);
      if (ay != 0) return ay;

      final ax = a.start.dx.compareTo(b.start.dx);
      if (ax != 0) return ax;

      return a.lengthPx.compareTo(b.lengthPx);
    });

    return result;
  }

  bool _isAlmostSameLine(
    FloorPlanDetectedLine a,
    FloorPlanDetectedLine b,
  ) {
    final sameOrientation =
        (a.isHorizontal && b.isHorizontal) || (a.isVertical && b.isVertical);

    if (!sameOrientation) return false;

    if (a.isHorizontal) {
      final sameY = (a.start.dy - b.start.dy).abs() <= 2.5;
      final sameStart = (a.start.dx - b.start.dx).abs() <= 4;
      final sameEnd = (a.end.dx - b.end.dx).abs() <= 4;

      return sameY && sameStart && sameEnd;
    }

    final sameX = (a.start.dx - b.start.dx).abs() <= 2.5;
    final sameStart = (a.start.dy - b.start.dy).abs() <= 4;
    final sameEnd = (a.end.dy - b.end.dy).abs() <= 4;

    return sameX && sameStart && sameEnd;
  }

  List<FloorPlanDetectedObject> _detectObjects({
    required List<bool> wallMask,
    required int width,
    required int height,
    required List<FloorPlanDetectedLine> lines,
    required FloorPlanDetectionSettings settings,
  }) {
    final lineCoverage = List<bool>.filled(width * height, false);

    for (final line in lines) {
      _markLineCoverage(
        coverage: lineCoverage,
        width: width,
        height: height,
        line: line,
        radiusPx: settings.lineExclusionRadiusPx.toDouble(),
      );
    }

    final residualMask = List<bool>.filled(width * height, false);

    for (var i = 0; i < wallMask.length; i++) {
      residualMask[i] = wallMask[i] && !lineCoverage[i];
    }

    final visited = List<bool>.filled(width * height, false);
    final objects = <FloorPlanDetectedObject>[];

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final startIndex = y * width + x;

        if (!residualMask[startIndex] || visited[startIndex]) continue;

        final component = _collectComponent(
          mask: residualMask,
          visited: visited,
          width: width,
          height: height,
          startX: x,
          startY: y,
        );

        if (component.pixelCount < settings.minObjectPixels) continue;
        if (component.width < settings.minObjectSizePx ||
            component.height < settings.minObjectSizePx) {
          continue;
        }

        if (component.width > settings.maxObjectSizePx ||
            component.height > settings.maxObjectSizePx) {
          continue;
        }

        final density = component.pixelCount /
            math.max(1, component.width * component.height);

        if (density < 0.045) continue;
        if (density > 0.92) continue;

        final bounds = Rect.fromLTRB(
          component.minX.toDouble(),
          component.minY.toDouble(),
          (component.maxX + 1).toDouble(),
          (component.maxY + 1).toDouble(),
        );

        final type = _classifyObject(
          widthPx: component.width,
          heightPx: component.height,
          density: density,
        );

        final confidence = _objectConfidence(
          type: type,
          widthPx: component.width,
          heightPx: component.height,
          density: density,
        );

        objects.add(
          FloorPlanDetectedObject(
            id: 'detected_object_${objects.length}_${DateTime.now().microsecondsSinceEpoch}',
            bounds: bounds,
            type: type,
            confidence: confidence,
          ),
        );
      }
    }

    objects.sort((a, b) {
      final ay = a.bounds.top.compareTo(b.bounds.top);
      if (ay != 0) return ay;
      return a.bounds.left.compareTo(b.bounds.left);
    });

    return objects;
  }

  void _markLineCoverage({
    required List<bool> coverage,
    required int width,
    required int height,
    required FloorPlanDetectedLine line,
    required double radiusPx,
  }) {
    final minX = math.max(
      0,
      (math.min(line.start.dx, line.end.dx) - radiusPx).floor(),
    );

    final maxX = math.min(
      width - 1,
      (math.max(line.start.dx, line.end.dx) + radiusPx).ceil(),
    );

    final minY = math.max(
      0,
      (math.min(line.start.dy, line.end.dy) - radiusPx).floor(),
    );

    final maxY = math.min(
      height - 1,
      (math.max(line.start.dy, line.end.dy) + radiusPx).ceil(),
    );

    for (var y = minY; y <= maxY; y++) {
      for (var x = minX; x <= maxX; x++) {
        final point = Offset(x + 0.5, y + 0.5);
        final distance = _distanceToSegment(point, line.start, line.end);

        if (distance <= radiusPx) {
          coverage[y * width + x] = true;
        }
      }
    }
  }

  double _distanceToSegment(
    Offset point,
    Offset a,
    Offset b,
  ) {
    final ab = b - a;
    final ap = point - a;

    final abLengthSquared = ab.dx * ab.dx + ab.dy * ab.dy;

    if (abLengthSquared <= 0.0001) {
      return (point - a).distance;
    }

    final t = ((ap.dx * ab.dx) + (ap.dy * ab.dy)) / abLengthSquared;
    final clampedT = t.clamp(0.0, 1.0);

    final projection = Offset(
      a.dx + ab.dx * clampedT,
      a.dy + ab.dy * clampedT,
    );

    return (point - projection).distance;
  }

  _ComponentBounds _collectComponent({
    required List<bool> mask,
    required List<bool> visited,
    required int width,
    required int height,
    required int startX,
    required int startY,
  }) {
    final queue = <int>[startY * width + startX];
    visited[startY * width + startX] = true;

    var head = 0;

    var minX = startX;
    var maxX = startX;
    var minY = startY;
    var maxY = startY;
    var pixelCount = 0;

    while (head < queue.length) {
      final index = queue[head++];
      final x = index % width;
      final y = index ~/ width;

      pixelCount++;

      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;

      void tryAdd(int nx, int ny) {
        if (nx < 0 || ny < 0 || nx >= width || ny >= height) return;

        final nextIndex = ny * width + nx;

        if (visited[nextIndex]) return;
        if (!mask[nextIndex]) return;

        visited[nextIndex] = true;
        queue.add(nextIndex);
      }

      tryAdd(x + 1, y);
      tryAdd(x - 1, y);
      tryAdd(x, y + 1);
      tryAdd(x, y - 1);
    }

    return _ComponentBounds(
      minX: minX,
      maxX: maxX,
      minY: minY,
      maxY: maxY,
      pixelCount: pixelCount,
    );
  }

  FloorPlanDetectedObjectType _classifyObject({
    required int widthPx,
    required int heightPx,
    required double density,
  }) {
    final shortSide = math.min(widthPx, heightPx);
    final longSide = math.max(widthPx, heightPx);
    final aspect = widthPx / math.max(1, heightPx);

    if (longSide >= 28 && shortSide <= 16) {
      return FloorPlanDetectedObjectType.window;
    }

    if (density < 0.36 && longSide >= 24) {
      return FloorPlanDetectedObjectType.door;
    }

    if (aspect >= 0.65 &&
        aspect <= 1.55 &&
        widthPx <= 90 &&
        heightPx <= 90) {
      return FloorPlanDetectedObjectType.fixture;
    }

    if (widthPx >= 24 && heightPx >= 24 && density >= 0.18) {
      return FloorPlanDetectedObjectType.furniture;
    }

    return FloorPlanDetectedObjectType.unknown;
  }

  double _objectConfidence({
    required FloorPlanDetectedObjectType type,
    required int widthPx,
    required int heightPx,
    required double density,
  }) {
    switch (type) {
      case FloorPlanDetectedObjectType.window:
        return 0.62;
      case FloorPlanDetectedObjectType.door:
        return 0.58;
      case FloorPlanDetectedObjectType.fixture:
        return 0.54;
      case FloorPlanDetectedObjectType.furniture:
        return 0.46;
      case FloorPlanDetectedObjectType.unknown:
        return 0.34;
    }
  }
}

class _IntRange {
  final int start;
  final int end;

  const _IntRange(this.start, this.end);
}

class _EndpointRef {
  final int lineIndex;
  final bool isStart;
  final Offset point;

  const _EndpointRef({
    required this.lineIndex,
    required this.isStart,
    required this.point,
  });
}

class _ComponentBounds {
  final int minX;
  final int maxX;
  final int minY;
  final int maxY;
  final int pixelCount;

  const _ComponentBounds({
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
    required this.pixelCount,
  });

  int get width => maxX - minX + 1;

  int get height => maxY - minY + 1;
}