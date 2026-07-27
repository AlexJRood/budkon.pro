part of 'floor_plan_canvas.dart';

extension _FloorPlanCanvasOpeningResizeGeometry on _FloorPlanCanvasState {
  _OpeningGeometry? _openingGeometryFor(
    Map<String, dynamic> opening,
    FloorWall wall,
  ) {
    final start = wall.start.toOffset();
    final end = wall.end.toOffset();

    final vector = end - start;
    final wallLengthPx = vector.distance;

    if (wallLengthPx <= 0.001) return null;

    final unit = Offset(
      vector.dx / wallLengthPx,
      vector.dy / wallLengthPx,
    );

    final normal = Offset(-unit.dy, unit.dx);

    final rawPosition = (opening['position'] as num?)?.toDouble() ?? 0.5;
    final position = rawPosition.clamp(0.0, 1.0).toDouble();

    final rawWidthM = (opening['width_m'] as num?)?.toDouble();
    final type = opening['type']?.toString();

    final fallbackWidthM = type == 'garage_door'
        ? 2.5
        : type == 'double'
            ? 1.4
            : type == 'sliding'
                ? 1.2
                : 0.9;

    final widthM = (rawWidthM ?? fallbackWidthM).clamp(0.1, 20.0).toDouble();
    final widthPx = widthM * widget.document.scale.pixelsPerMeter;

    final center = Offset(
      start.dx + vector.dx * position,
      start.dy + vector.dy * position,
    );

    final gapStart = center - unit * (widthPx / 2);
    final gapEnd = center + unit * (widthPx / 2);

    return _OpeningGeometry(
      center: center,
      gapStart: gapStart,
      gapEnd: gapEnd,
      unit: unit,
      normal: normal,
      position: position,
      widthM: widthM,
      wallLengthPx: wallLengthPx,
    );
  }

  _WallProjectionHit? _nearestWallProjection(
    Offset point, {
    Set<String> ignoreWallIds = const {},
    double? threshold,
    bool allowEndpoints = true,
    bool includeVirtualWalls = true,
  }) {
    final maxDistance = threshold ?? double.infinity;

    _WallProjectionHit? best;

    for (final wall in widget.document.walls) {
      if (ignoreWallIds.contains(wall.id)) continue;
      if (!includeVirtualWalls && wall.isVirtual) continue;

      final start = wall.start.toOffset();
      final end = wall.end.toOffset();

      final vector = end - start;
      if (vector.distance <= 0.001) continue;

      final fraction = _projectionFractionOnSegment(point, start, end);

      if (!allowEndpoints && (fraction <= 0.02 || fraction >= 0.98)) {
        continue;
      }

      final projected = _projectPointOnSegment(point, start, end);
      final distance = (point - projected).distance;

      if (distance > maxDistance) continue;

      if (best == null || distance < best.distance) {
        best = _WallProjectionHit(
          wall: wall,
          point: projected,
          fraction: fraction,
          distance: distance,
        );
      }
    }

    return best;
  }
}

extension _FloorPlanCanvasOpeningResizeSelection on _FloorPlanCanvasState {
  _OpeningResizeHandleHit? _hitTestOpeningResizeHandle(Offset point) {
    final selected = _selectedObject;

    if (selected == null) return null;
    if (!selected.isDoor && !selected.isWindow) return null;

    final threshold = 14 / _currentScale;

    _OpeningResizeHandleHit? best;

    void checkCollection({
      required List<Map<String, dynamic>> items,
      required _SelectedObjectType type,
    }) {
      if (selected.type != type) return;

      for (final opening in items) {
        final openingId = opening['id']?.toString();
        final wallId = opening['wall_id']?.toString();

        if (openingId == null || wallId == null) continue;
        if (openingId != selected.id) continue;

        final wall = _findWallById(wallId);
        if (wall == null) continue;

        final geometry = _openingGeometryFor(opening, wall);
        if (geometry == null) continue;

        final startDistance = (point - geometry.gapStart).distance;
        final endDistance = (point - geometry.gapEnd).distance;

        if (startDistance <= threshold) {
          final hit = _OpeningResizeHandleHit(
            openingType: type,
            openingId: openingId,
            wallId: wallId,
            side: _OpeningHandleSide.start,
            wall: wall,
            point: geometry.gapStart,
            distance: startDistance,
          );

          if (best == null || hit.distance < best!.distance) {
            best = hit;
          }
        }

        if (endDistance <= threshold) {
          final hit = _OpeningResizeHandleHit(
            openingType: type,
            openingId: openingId,
            wallId: wallId,
            side: _OpeningHandleSide.end,
            wall: wall,
            point: geometry.gapEnd,
            distance: endDistance,
          );

          if (best == null || hit.distance < best!.distance) {
            best = hit;
          }
        }
      }
    }

    checkCollection(
      items: widget.document.doors,
      type: _SelectedObjectType.door,
    );

    checkCollection(
      items: widget.document.windows,
      type: _SelectedObjectType.window,
    );

    return best;
  }
}

extension _FloorPlanCanvasOpeningResizeMutations on _FloorPlanCanvasState {
  void _resizeOpeningWithHandle({
    required _OpeningResizeHandleHit hit,
    required Offset canvasPoint,
  }) {
    final isDoor = hit.openingType == _SelectedObjectType.door;
    final source = isDoor ? widget.document.doors : widget.document.windows;

    final opening = _findOpeningById(hit.openingId, source);
    if (opening == null) return;

    final wallId = opening['wall_id']?.toString();
    if (wallId == null) return;

    final wall = _findWallById(wallId);
    if (wall == null) return;

    final geometry = _openingGeometryFor(opening, wall);
    if (geometry == null) return;

    final pixelsPerMeter = widget.document.scale.pixelsPerMeter;
    if (pixelsPerMeter <= 0) return;

    final wallLengthM = geometry.wallLengthPx / pixelsPerMeter;
    if (wallLengthM <= 0.001) return;

    final projectedFraction = _projectionFractionOnWall(canvasPoint, wall)
        .clamp(0.0, 1.0)
        .toDouble();

    final currentWidthFraction =
        (geometry.widthM / wallLengthM).clamp(0.001, 1.0).toDouble();

    var left = (geometry.position - currentWidthFraction / 2)
        .clamp(0.0, 1.0)
        .toDouble();

    var right = (geometry.position + currentWidthFraction / 2)
        .clamp(0.0, 1.0)
        .toDouble();

    final openingType = opening['type']?.toString();
    final minWidthM = openingType == 'garage_door' ? 1.6 : 0.3;
    final minWidthFraction =
        (minWidthM / wallLengthM).clamp(0.001, 1.0).toDouble();

    if (hit.side == _OpeningHandleSide.start) {
      left = projectedFraction
          .clamp(
            0.0,
            right - minWidthFraction,
          )
          .toDouble();
    } else {
      right = projectedFraction
          .clamp(
            left + minWidthFraction,
            1.0,
          )
          .toDouble();
    }

    var nextWidthM = (right - left) * wallLengthM;

    final snappedWidthM = _snapOpeningWidthM(
      opening: opening,
      widthM: nextWidthM,
    );

    if ((snappedWidthM - nextWidthM).abs() > 0.001) {
      final snappedWidthFraction =
          (snappedWidthM / wallLengthM).clamp(minWidthFraction, 1.0).toDouble();

      if (hit.side == _OpeningHandleSide.start) {
        left = (right - snappedWidthFraction).clamp(0.0, right).toDouble();
      } else {
        right = (left + snappedWidthFraction).clamp(left, 1.0).toDouble();
      }

      nextWidthM = (right - left) * wallLengthM;
    }

    final nextPosition = ((left + right) / 2).clamp(0.0, 1.0).toDouble();
    final maxWidthM = wallLengthM.clamp(minWidthM, wallLengthM).toDouble();
    final safeWidthM = nextWidthM.clamp(minWidthM, maxWidthM).toDouble();

    final nextOpening = {
      ...opening,
      'position': nextPosition,
      'width_m': safeWidthM,
    };

    if (isDoor) {
      _commitDocument(
        widget.document.copyWith(
          doors: _replaceOpening(
            widget.document.doors,
            hit.openingId,
            nextOpening,
          ),
        ),
        pushHistory: false,
      );
    } else {
      _commitDocument(
        widget.document.copyWith(
          windows: _replaceOpening(
            widget.document.windows,
            hit.openingId,
            nextOpening,
          ),
        ),
        pushHistory: false,
      );
    }

    setState(() {
      _selectedObject = _SelectedObject(
        type: hit.openingType,
        id: hit.openingId,
      );
      _selectedWallIds.clear();
      _selectedVertex = null;
    });
  }

  double _snapOpeningWidthM({
    required Map<String, dynamic> opening,
    required double widthM,
  }) {
    final type = opening['type']?.toString();

    final presets = switch (type) {
      'garage_door' => const [2.4, 2.5, 2.7, 3.0, 4.0, 5.0],
      'single' => const [0.7, 0.8, 0.9, 1.0],
      'double' => const [1.2, 1.4, 1.5, 1.6, 1.8],
      'sliding' => const [0.8, 0.9, 1.0, 1.2, 1.5, 1.8, 2.0],
      _ => const [0.6, 0.9, 1.2, 1.5, 1.8],
    };

    const toleranceM = 0.05;

    for (final preset in presets) {
      if ((widthM - preset).abs() <= toleranceM) {
        return preset;
      }
    }

    return widthM;
  }
}

extension _FloorPlanCanvasAssetWallFitMutations on _FloorPlanCanvasState {
  void _alignSelectedAssetToNearestWall() {
    final asset = _selectedAsset;
    if (asset == null) return;

    _alignAssetToNearestWall(asset.id);
  }

  void _alignAssetToNearestWall(String assetId) {
    FloorPlanAsset? asset;

    for (final item in widget.document.assets) {
      if (item.id == assetId) {
        asset = item;
        break;
      }
    }

    if (asset == null) return;

    final center = asset.position.toOffset();

    final projection = _nearestWallProjection(
      center,
      threshold: 400 / _currentScale,
      allowEndpoints: true,
      includeVirtualWalls: false,
    );

    if (projection == null) return;

    final wall = projection.wall;
    final wallStart = wall.start.toOffset();
    final wallEnd = wall.end.toOffset();

    final vector = wallEnd - wallStart;
    final length = vector.distance;

    if (length <= 0.001) return;

    final unit = Offset(
      vector.dx / length,
      vector.dy / length,
    );

    final normal = Offset(-unit.dy, unit.dx);

    final relative = center - projection.point;
    final sideDot = relative.dx * normal.dx + relative.dy * normal.dy;
    final sideSign = sideDot >= 0 ? 1.0 : -1.0;

    final pixelsPerMeter = widget.document.scale.pixelsPerMeter;
    if (pixelsPerMeter <= 0) return;

    final assetDepthPx = asset.depthM * pixelsPerMeter;
    final wallThicknessPx = _wallThicknessPxForGeometry(wall);

    final offsetFromWall = (assetDepthPx / 2) + (wallThicknessPx / 2) + 4;
    final nextCenter = projection.point + normal * sideSign * offsetFromWall;

    final wallAngleDeg = _normalizeAngleDegrees(
      math.atan2(unit.dy, unit.dx) * 180 / math.pi,
    );

    final updatedAsset = FloorPlanAsset(
      id: asset.id,
      type: asset.type,
      position: FloorPoint.fromOffset(nextCenter),
      widthM: asset.widthM,
      depthM: asset.depthM,
      rotationDeg: wallAngleDeg,
      label: asset.label,
    );

    final assets = widget.document.assets.map((item) {
      if (item.id == assetId) return updatedAsset;
      return item;
    }).toList();

    _commitDocument(
      widget.document.copyWith(
        assets: assets,
      ),
    );

    setState(() {
      _selectedObject = _SelectedObject(
        type: _SelectedObjectType.asset,
        id: assetId,
      );
      _selectedWallIds.clear();
      _selectedVertex = null;
    });
  }
}