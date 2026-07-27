part of 'floor_plan_canvas.dart';

extension _FloorPlanCanvasGeometry on _FloorPlanCanvasState {
  double get _currentScale {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    if (scale <= 0) return 1;
    return scale;
  }

  double _wallThicknessPxForGeometry(FloorWall wall) {
    final thicknessM = wall.thickness / 100.0;
    final px = thicknessM * widget.document.scale.pixelsPerMeter;

    if (wall.isVirtual) return 2.0;

    return px.clamp(2.0, 120.0).toDouble();
  }

  Offset _viewportCenter() {
    final viewportContext = _canvasViewportKey.currentContext;

    if (viewportContext == null) {
      return Offset.zero;
    }

    final renderObject = viewportContext.findRenderObject();

    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return Offset.zero;
    }

    return renderObject.size.center(Offset.zero);
  }

  Matrix4 _applyViewportDelta(Matrix4 delta) {
    final center = _viewportCenter();

    return Matrix4.identity()
      ..translate(center.dx, center.dy)
      ..multiply(delta)
      ..translate(-center.dx, -center.dy)
      ..multiply(_transformationController.value);
  }

  void _panViewportBy(Offset viewportDelta) {
    if (viewportDelta == Offset.zero) return;

    final next = _transformationController.value.clone();

    next.storage[12] += viewportDelta.dx;
    next.storage[13] += viewportDelta.dy;

    _transformationController.value = next;

    setState(() {});
  }

  void _zoomAtGlobalPosition({
    required Offset globalPosition,
    required double factor,
  }) {
    if (factor <= 0) return;

    final viewportContext = _canvasViewportKey.currentContext;
    if (viewportContext == null) {
      _zoomViewBy(factor);
      return;
    }

    final renderObject = viewportContext.findRenderObject();

    if (renderObject is! RenderBox || !renderObject.hasSize) {
      _zoomViewBy(factor);
      return;
    }

    final localPosition = renderObject.globalToLocal(globalPosition);

    final currentScale = _currentScale;
    if (currentScale <= 0) return;

    final targetScale = (currentScale * factor).clamp(
      _FloorPlanCanvasState._minZoomScale,
      _FloorPlanCanvasState._maxZoomScale,
    );

    final actualFactor = targetScale / currentScale;

    if ((actualFactor - 1.0).abs() < 0.0001) return;

    final delta = Matrix4.identity()
      ..translate(localPosition.dx, localPosition.dy)
      ..scale(actualFactor)
      ..translate(-localPosition.dx, -localPosition.dy);

    delta.multiply(_transformationController.value);

    _transformationController.value = delta;

    setState(() {});
  }

  void _zoomViewBy(double factor) {
    if (factor <= 0) return;

    final currentScale = _currentScale;
    if (currentScale <= 0) return;

    final targetScale = (currentScale * factor).clamp(
      _FloorPlanCanvasState._minZoomScale,
      _FloorPlanCanvasState._maxZoomScale,
    );

    final actualFactor = targetScale / currentScale;

    if ((actualFactor - 1.0).abs() < 0.0001) return;

    final delta = Matrix4.identity()..scale(actualFactor);

    _transformationController.value = _applyViewportDelta(delta);

    setState(() {});
  }

  void _zoomViewIn() {
    _zoomViewBy(1.25);
  }

  void _zoomViewOut() {
    _zoomViewBy(1 / 1.25);
  }

  void _rotateViewBy(double degrees) {
    if (degrees.abs() < 0.001) return;

    final radians = degrees * math.pi / 180.0;
    final delta = Matrix4.identity()..rotateZ(radians);

    _transformationController.value = _applyViewportDelta(delta);

    setState(() {
      _viewRotationDegrees = _normalizeSignedDegrees(
        _viewRotationDegrees + degrees,
      );
    });
  }

  void _rotateViewLeft() {
    _rotateViewBy(-15);
  }

  void _rotateViewRight() {
    _rotateViewBy(15);
  }

  void _resetViewRotation() {
    if (_viewRotationDegrees.abs() < 0.001) return;

    final radians = -_viewRotationDegrees * math.pi / 180.0;
    final delta = Matrix4.identity()..rotateZ(radians);

    _transformationController.value = _applyViewportDelta(delta);

    setState(() {
      _viewRotationDegrees = 0;
    });
  }

  void _resetViewTransform() {
    _transformationController.value = Matrix4.identity();

    setState(() {
      _viewRotationDegrees = 0;
      _activeGuideSnap = null;
    });
  }

  double _normalizeSignedDegrees(double value) {
    var normalized = (value + 180) % 360;

    if (normalized < 0) {
      normalized += 360;
    }

    return normalized - 180;
  }

  Offset _toCanvasPosition(Offset globalPosition) {
    final viewportContext = _canvasViewportKey.currentContext;

    if (viewportContext == null) {
      return Offset.zero;
    }

    final renderObject = viewportContext.findRenderObject();

    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return Offset.zero;
    }

    final local = renderObject.globalToLocal(globalPosition);

    final matrix = _transformationController.value.clone();
    final inverted = Matrix4.inverted(matrix);

    return MatrixUtils.transformPoint(inverted, local);
  }

  Offset _canvasToViewportPosition(Offset canvasPosition) {
    return MatrixUtils.transformPoint(
      _transformationController.value,
      canvasPosition,
    );
  }

  Offset _wallCenter(FloorWall wall) {
    final start = wall.start.toOffset();
    final end = wall.end.toOffset();

    return Offset(
      (start.dx + end.dx) / 2,
      (start.dy + end.dy) / 2,
    );
  }

  Offset _wallLengthLabelCanvasPosition(FloorWall wall) {
    final start = wall.start.toOffset();
    final end = wall.end.toOffset();

    final vector = end - start;
    final length = vector.distance;

    final center = _wallCenter(wall);

    if (length <= 0.001) {
      return center - const Offset(0, 24);
    }

    final normal = Offset(-vector.dy / length, vector.dx / length);
    final thicknessPx = _wallThicknessPxForGeometry(wall);

    return center - normal * ((thicknessPx / 2) + 18);
  }

  Offset _wallLengthLabelViewportPosition(FloorWall wall) {
    return _canvasToViewportPosition(
      _wallLengthLabelCanvasPosition(wall),
    );
  }

  Offset _snapToGrid(Offset value) {
    final grid = widget.document.canvas.gridSize;
    if (grid <= 0) return value;

    return Offset(
      (value.dx / grid).round() * grid,
      (value.dy / grid).round() * grid,
    );
  }

  Offset? _nearestExistingCorner(
    Offset value, {
    double? threshold,
    String? ignoreWallId,
  }) {
    final hitDistance = threshold ?? (18 / _currentScale);

    Offset? best;
    double bestDistance = double.infinity;

    for (final wall in widget.document.walls) {
      if (ignoreWallId != null && wall.id == ignoreWallId) continue;

      final points = [
        wall.start.toOffset(),
        wall.end.toOffset(),
      ];

      for (final point in points) {
        final distance = (point - value).distance;

        if (distance <= hitDistance && distance < bestDistance) {
          best = point;
          bestDistance = distance;
        }
      }
    }

    return best;
  }

  Offset _snapToGridAndCorners(
    Offset value, {
    String? ignoreWallId,
  }) {
    final gridSnapped = _snapToGrid(value);

    final corner = _nearestExistingCorner(
      gridSnapped,
      ignoreWallId: ignoreWallId,
    );

    return corner ?? gridSnapped;
  }

  _GuideSnapResult _prepareFreePointSnap({
    required Offset rawPoint,
    Set<String> ignoreWallIds = const {},
  }) {
    final strongCornerThreshold = 24 / _currentScale;
    final wallThreshold = 18 / _currentScale;

    final corner = _nearestExistingCorner(
      rawPoint,
      threshold: strongCornerThreshold,
    );

    if (corner != null) {
      return _GuideSnapResult(
        point: corner,
        label: 'vertex_label'.tr,
        lines: const [],
      );
    }

    final wallSnap = _findWallLineSnap(
      rawPoint,
      threshold: wallThreshold,
      ignoreWallIds: ignoreWallIds,
    );

    if (wallSnap != null &&
        wallSnap.fraction > 0.02 &&
        wallSnap.fraction < 0.98) {
      return _GuideSnapResult(
        point: wallSnap.point,
        label: 'wall_action'.tr,
        snapWallId: wallSnap.wallId,
        snapWallFraction: wallSnap.fraction,
        lines: [
          _GuideLine(
            start: wallSnap.wall.start.toOffset(),
            end: wallSnap.wall.end.toOffset(),
          ),
        ],
      );
    }

    return _GuideSnapResult(
      point: _snapToGridAndCorners(rawPoint),
    );
  }

  Offset _applyAngleLock({
    required Offset start,
    required Offset rawEnd,
  }) {
    if (!_angleLockEnabled) return rawEnd;
    if (_isAltPressed) return rawEnd;

    final vector = rawEnd - start;
    final length = vector.distance;

    if (length < 0.001) return rawEnd;

    final angle = math.atan2(vector.dy, vector.dx);
    final step = _angleStepDegrees * math.pi / 180.0;
    final snappedAngle = (angle / step).round() * step;

    final rawAngleDeg = _normalizeAngleDegrees(angle * 180.0 / math.pi);
    final snappedAngleDeg =
        _normalizeAngleDegrees(snappedAngle * 180.0 / math.pi);

    final diff = _smallestAngleDifferenceDegrees(
      rawAngleDeg,
      snappedAngleDeg,
    );

    if (diff > _angleSnapToleranceDegrees) {
      return rawEnd;
    }

    return Offset(
      start.dx + math.cos(snappedAngle) * length,
      start.dy + math.sin(snappedAngle) * length,
    );
  }

  _GuideSnapResult _applyShiftDrawingAlignment({
    required Offset startPoint,
    required Offset rawPoint,
  }) {
    final threshold = 18 / _currentScale;

    final dx = rawPoint.dx - startPoint.dx;
    final dy = rawPoint.dy - startPoint.dy;

    Offset point;

    if (dx.abs() >= dy.abs()) {
      point = Offset(rawPoint.dx, startPoint.dy);
    } else {
      point = Offset(startPoint.dx, rawPoint.dy);
    }

    final lines = <_GuideLine>[
      _GuideLine(start: startPoint, end: point),
    ];

    final allPoints = <Offset>[
      startPoint,
      ..._collectUniqueCanvasCorners(),
    ];

    Offset? snapXPoint;
    Offset? snapYPoint;
    double bestXDistance = double.infinity;
    double bestYDistance = double.infinity;

    for (final candidate in allPoints) {
      final xDistance = (rawPoint.dx - candidate.dx).abs();
      if (xDistance <= threshold && xDistance < bestXDistance) {
        bestXDistance = xDistance;
        snapXPoint = candidate;
      }

      final yDistance = (rawPoint.dy - candidate.dy).abs();
      if (yDistance <= threshold && yDistance < bestYDistance) {
        bestYDistance = yDistance;
        snapYPoint = candidate;
      }
    }

    if (snapXPoint != null || snapYPoint != null) {
      point = Offset(
        snapXPoint?.dx ?? point.dx,
        snapYPoint?.dy ?? point.dy,
      );

      if (snapXPoint != null) {
        lines.add(
          _GuideLine(
            start: Offset(snapXPoint.dx, 0),
            end: Offset(snapXPoint.dx, widget.document.canvas.height),
          ),
        );
      }

      if (snapYPoint != null) {
        lines.add(
          _GuideLine(
            start: Offset(0, snapYPoint.dy),
            end: Offset(widget.document.canvas.width, snapYPoint.dy),
          ),
        );
      }
    }

    return _GuideSnapResult(
      point: point,
      label: snapXPoint != null && snapYPoint != null
          ? 'shift_align_xy_label'.tr
          : 'shift_align_label'.tr,
      lines: lines,
    );
  }

  List<Offset> _collectUniqueCanvasCorners() {
    final points = <String, Offset>{};

    for (final wall in widget.document.walls) {
      final start = wall.start.toOffset();
      final end = wall.end.toOffset();

      points[_cornerKey(start)] = start;
      points[_cornerKey(end)] = end;
    }

    return points.values.toList(growable: false);
  }

  void _updateHoveredRoomCandidate(Offset point) {
    final candidate = _detectRoomAtPoint(point);

    final currentKey = _roomCandidateKey(_hoveredRoomCandidate);
    final nextKey = _roomCandidateKey(candidate);

    if (currentKey == nextKey) return;

    setState(() {
      _hoveredRoomCandidate = candidate;
    });
  }

  String? _roomCandidateKey(_DetectedRoomCandidate? candidate) {
    if (candidate == null) return null;

    final keys = candidate.points.map(_cornerKey).toList()..sort();

    return keys.join('|');
  }

  double _crossProduct(Offset a, Offset b) {
    return a.dx * b.dy - a.dy * b.dx;
  }

  double _dotProduct(Offset a, Offset b) {
    return a.dx * b.dx + a.dy * b.dy;
  }

  double _fractionOnSegmentForPoint({
    required Offset point,
    required Offset start,
    required Offset end,
  }) {
    final vector = end - start;
    final lengthSq = vector.dx * vector.dx + vector.dy * vector.dy;

    if (lengthSq <= 0.000001) return 0;

    final relative = point - start;
    final t = _dotProduct(relative, vector) / lengthSq;

    return t.clamp(0.0, 1.0).toDouble();
  }

  Offset? _raySegmentIntersection({
    required Offset rayStart,
    required Offset rayDirection,
    required Offset segmentStart,
    required Offset segmentEnd,
  }) {
    final rayLength = rayDirection.distance;
    if (rayLength <= 0.001) return null;

    final ray = Offset(
      rayDirection.dx / rayLength,
      rayDirection.dy / rayLength,
    );

    final segment = segmentEnd - segmentStart;
    final denominator = _crossProduct(ray, segment);

    if (denominator.abs() <= 0.000001) {
      return null;
    }

    final relative = segmentStart - rayStart;

    final rayT = _crossProduct(relative, segment) / denominator;
    final segmentT = _crossProduct(relative, ray) / denominator;

    if (rayT < 0) return null;
    if (segmentT < -0.0001 || segmentT > 1.0001) return null;

    return rayStart + ray * rayT;
  }

  _WallLineSnapHit? _findWallSnapAlongDirection({
    required Offset startPoint,
    required Offset rawPoint,
    required Offset directionPoint,
    double? threshold,
    Set<String> ignoreWallIds = const {},
  }) {
    final hitDistance = threshold ?? (22 / _currentScale);

    var direction = directionPoint - startPoint;
    if (direction.distance <= 0.001) return null;

    final rawDirection = rawPoint - startPoint;

    if (_dotProduct(rawDirection, direction) < 0) {
      direction = Offset(-direction.dx, -direction.dy);
    }

    _WallLineSnapHit? best;
    double bestDistance = double.infinity;

    for (final wall in widget.document.walls) {
      if (ignoreWallIds.contains(wall.id)) continue;

      final wallStart = wall.start.toOffset();
      final wallEnd = wall.end.toOffset();

      final intersection = _raySegmentIntersection(
        rayStart: startPoint,
        rayDirection: direction,
        segmentStart: wallStart,
        segmentEnd: wallEnd,
      );

      if (intersection == null) continue;

      final distanceToCursor = (rawPoint - intersection).distance;

      if (distanceToCursor > hitDistance) continue;
      if (distanceToCursor >= bestDistance) continue;

      final fraction = _fractionOnSegmentForPoint(
        point: intersection,
        start: wallStart,
        end: wallEnd,
      );

      bestDistance = distanceToCursor;

      best = _WallLineSnapHit(
        wallId: wall.id,
        wall: wall,
        point: intersection,
        distance: distanceToCursor,
        fraction: fraction,
      );
    }

    return best;
  }

  List<_GuideLine> _directionalWallSnapLines({
    required Offset startPoint,
    required _WallLineSnapHit hit,
    List<_GuideLine> baseLines = const [],
  }) {
    return [
      ...baseLines,
      _GuideLine(
        start: hit.wall.start.toOffset(),
        end: hit.wall.end.toOffset(),
      ),
      _GuideLine(
        start: startPoint,
        end: hit.point,
      ),
    ];
  }

  _GuideSnapResult _applySmartGuides({
    required Offset rawPoint,
    required Offset startPoint,
    Set<String> ignoreWallIds = const {},
    Offset? rawCursorPoint,
  }) {
    if (!_smartGuidesEnabled) {
      return _GuideSnapResult(point: rawPoint);
    }

    final cursorPoint = rawCursorPoint ?? rawPoint;
    final hasDirectionalPoint = (cursorPoint - rawPoint).distance > 0.001;

    final threshold = 18 / _currentScale;
    final strongCornerThreshold = 26 / _currentScale;
    final wallThreshold = 22 / _currentScale;

    final hardCorner = _nearestExistingCorner(
      rawPoint,
      threshold: strongCornerThreshold,
    );

    if (hardCorner != null) {
      return _GuideSnapResult(
        point: hardCorner,
        label: 'vertex_label'.tr,
        lines: [
          _GuideLine(start: startPoint, end: hardCorner),
        ],
      );
    }

    _GuideSnapResult best = _GuideSnapResult(point: rawPoint);
    double bestScore = double.infinity;

    void consider({
      required Offset point,
      required double distance,
      required String label,
      List<_GuideLine> lines = const [],
      String? snapWallId,
      double? snapWallFraction,
      double? maxDistance,
      double priority = 1.0,
    }) {
      final allowedDistance = maxDistance ?? threshold;

      if (distance > allowedDistance) return;

      final score = distance * priority;

      if (score >= bestScore) return;

      bestScore = score;

      best = _GuideSnapResult(
        point: point,
        lines: lines,
        label: label,
        snapWallId: snapWallId,
        snapWallFraction: snapWallFraction,
      );
    }

    final points = _collectUniqueCanvasCorners();

    for (final point in points) {
      final sameXDistance = (rawPoint.dx - point.dx).abs();

      consider(
        point: Offset(point.dx, rawPoint.dy),
        distance: sameXDistance,
        label: 'align_x_label'.tr,
        lines: [
          _GuideLine(
            start: Offset(point.dx, 0),
            end: Offset(point.dx, widget.document.canvas.height),
          ),
        ],
      );

      final sameYDistance = (rawPoint.dy - point.dy).abs();

      consider(
        point: Offset(rawPoint.dx, point.dy),
        distance: sameYDistance,
        label: 'align_y_label'.tr,
        lines: [
          _GuideLine(
            start: Offset(0, point.dy),
            end: Offset(widget.document.canvas.width, point.dy),
          ),
        ],
      );
    }

    for (final xPoint in points) {
      for (final yPoint in points) {
        final dx = (rawPoint.dx - xPoint.dx).abs();
        final dy = (rawPoint.dy - yPoint.dy).abs();

        if (dx > threshold || dy > threshold) continue;

        final candidate = Offset(xPoint.dx, yPoint.dy);

        consider(
          point: candidate,
          distance: (rawPoint - candidate).distance,
          label: 'align_xy_label'.tr,
          lines: [
            _GuideLine(
              start: Offset(xPoint.dx, 0),
              end: Offset(xPoint.dx, widget.document.canvas.height),
            ),
            _GuideLine(
              start: Offset(0, yPoint.dy),
              end: Offset(widget.document.canvas.width, yPoint.dy),
            ),
          ],
          priority: 0.55,
        );
      }
    }

    if (!hasDirectionalPoint) {
      final wallLineSnap = _findWallLineSnap(
        rawPoint,
        threshold: wallThreshold,
        ignoreWallIds: ignoreWallIds,
      );

      if (wallLineSnap != null &&
          wallLineSnap.fraction > 0.02 &&
          wallLineSnap.fraction < 0.98) {
        consider(
          point: wallLineSnap.point,
          distance: wallLineSnap.distance,
          label: 'wall_label'.tr,
          snapWallId: wallLineSnap.wallId,
          snapWallFraction: wallLineSnap.fraction,
          maxDistance: wallThreshold,
          lines: [
            _GuideLine(
              start: wallLineSnap.wall.start.toOffset(),
              end: wallLineSnap.wall.end.toOffset(),
            ),
            _GuideLine(
              start: startPoint,
              end: wallLineSnap.point,
            ),
          ],
        );
      }
    }

    final directions = _collectGuideDirections();

    for (final direction in directions) {
      final parallelProjection = _projectPointOnInfiniteLine(
        point: rawPoint,
        linePoint: startPoint,
        direction: direction,
      );

      final parallelLines = [
        _GuideLine(start: startPoint, end: parallelProjection),
      ];

      consider(
        point: parallelProjection,
        distance: (rawPoint - parallelProjection).distance,
        label: 'parallel_label'.tr,
        lines: parallelLines,
      );

      final parallelWallSnap = _findWallSnapAlongDirection(
        startPoint: startPoint,
        rawPoint: cursorPoint,
        directionPoint: parallelProjection,
        threshold: wallThreshold,
        ignoreWallIds: ignoreWallIds,
      );

      if (parallelWallSnap != null) {
        consider(
          point: parallelWallSnap.point,
          distance: parallelWallSnap.distance,
          label: 'parallel_plus_wall_label'.tr,
          lines: _directionalWallSnapLines(
            startPoint: startPoint,
            hit: parallelWallSnap,
            baseLines: parallelLines,
          ),
          snapWallId: parallelWallSnap.wallId,
          snapWallFraction: parallelWallSnap.fraction,
          maxDistance: wallThreshold,
          priority: 0.28,
        );
      }

      final perpendicular = Offset(-direction.dy, direction.dx);

      final perpendicularProjection = _projectPointOnInfiniteLine(
        point: rawPoint,
        linePoint: startPoint,
        direction: perpendicular,
      );

      final perpendicularLines = [
        _GuideLine(start: startPoint, end: perpendicularProjection),
      ];

      consider(
        point: perpendicularProjection,
        distance: (rawPoint - perpendicularProjection).distance,
        label: 'perpendicular_label'.tr,
        lines: perpendicularLines,
      );

      final perpendicularWallSnap = _findWallSnapAlongDirection(
        startPoint: startPoint,
        rawPoint: cursorPoint,
        directionPoint: perpendicularProjection,
        threshold: wallThreshold,
        ignoreWallIds: ignoreWallIds,
      );

      if (perpendicularWallSnap != null) {
        consider(
          point: perpendicularWallSnap.point,
          distance: perpendicularWallSnap.distance,
          label: 'perpendicular_plus_wall_label'.tr,
          lines: _directionalWallSnapLines(
            startPoint: startPoint,
            hit: perpendicularWallSnap,
            baseLines: perpendicularLines,
          ),
          snapWallId: perpendicularWallSnap.wallId,
          snapWallFraction: perpendicularWallSnap.fraction,
          maxDistance: wallThreshold,
          priority: 0.28,
        );
      }
    }

    return best;
  }

  Offset _prepareDrawingPoint({
    required Offset rawPoint,
    Offset? startPoint,
  }) {
    if (startPoint == null) {
      final freeSnap = _prepareFreePointSnap(rawPoint: rawPoint);

      _activeGuideSnap = freeSnap;

      return freeSnap.point;
    }

    _GuideSnapResult? baseGuide;
    var workingPoint = rawPoint;

    if (_isShiftPressed) {
      baseGuide = _applyShiftDrawingAlignment(
        startPoint: startPoint,
        rawPoint: rawPoint,
      );

      workingPoint = baseGuide.point;
    } else if (_angleLockEnabled && !_isAltPressed) {
      final angleLocked = _applyAngleLock(
        start: startPoint,
        rawEnd: rawPoint,
      );

      if ((angleLocked - rawPoint).distance > 0.001) {
        baseGuide = _GuideSnapResult(
          point: angleLocked,
          label: 'angle_snap_label'.tr,
          lines: [
            _GuideLine(
              start: startPoint,
              end: angleLocked,
            ),
          ],
        );

        workingPoint = angleLocked;
      }
    }

    final directionalWallSnap = _findWallSnapAlongDirection(
      startPoint: startPoint,
      rawPoint: rawPoint,
      directionPoint: workingPoint,
      threshold: 24 / _currentScale,
    );

    if (directionalWallSnap != null) {
      final result = _GuideSnapResult(
        point: directionalWallSnap.point,
        label: '${baseGuide?.label ?? 'Wyrównanie'} + ściana',
        lines: _directionalWallSnapLines(
          startPoint: startPoint,
          hit: directionalWallSnap,
          baseLines: baseGuide?.lines ?? const [],
        ),
        snapWallId: directionalWallSnap.wallId,
        snapWallFraction: directionalWallSnap.fraction,
      );

      _activeGuideSnap = result;

      return result.point;
    }

    final guideResult = _applySmartGuides(
      rawPoint: workingPoint,
      startPoint: startPoint,
      rawCursorPoint: rawPoint,
    );

    final mergedLines = <_GuideLine>[
      if (baseGuide != null) ...baseGuide.lines,
      ...guideResult.lines,
    ];

    final result = _GuideSnapResult(
      point: guideResult.point,
      label: guideResult.label ?? baseGuide?.label,
      lines: mergedLines,
      snapWallId: guideResult.snapWallId,
      snapWallFraction: guideResult.snapWallFraction,
    );

    _activeGuideSnap = result;

       if (result.label == 'vertex_label'.tr ||
       result.label == 'wall_label'.tr ||
       result.label == 'parallel_label'.tr ||
       result.label == 'parallel_plus_wall_label'.tr ||
       result.label == 'perpendicular_label'.tr ||
       result.label == 'perpendicular_plus_wall_label'.tr ||
       result.label == 'align_x_label'.tr ||
       result.label == 'align_y_label'.tr ||
       result.label == 'align_xy_label'.tr ||
       result.label == 'shift_align_label'.tr ||
       result.label == 'shift_align_xy_label'.tr ||
       result.label == 'angle_snap_plus_wall_label'.tr ||
       result.label == 'align_plus_wall_label'.tr) {
     return result.point;
   }

    if (_isShiftPressed) {
      return workingPoint;
    }

    return _snapToGridAndCorners(result.point);
  }

  _GuideSnapResult _prepareVertexDragPoint({
    required Offset rawPoint,
    required Set<String> ignoreWallIds,
  }) {
    if (_draggingConnectedHandles.isEmpty) {
      return _prepareFreePointSnap(
        rawPoint: rawPoint,
        ignoreWallIds: ignoreWallIds,
      );
    }

    final anchor = _draggingConnectedHandles.first.point;

    _GuideSnapResult? shiftGuide;

    var workingPoint = rawPoint;

    if (_isShiftPressed) {
      shiftGuide = _applyShiftDrawingAlignment(
        startPoint: anchor,
        rawPoint: rawPoint,
      );

      workingPoint = shiftGuide.point;
    }

    final guide = _applySmartGuides(
      rawPoint: workingPoint,
      startPoint: anchor,
      ignoreWallIds: ignoreWallIds,
      rawCursorPoint: rawPoint,
    );

    final lines = <_GuideLine>[
      if (shiftGuide != null) ...shiftGuide.lines,
      ...guide.lines,
    ];

    final result = _GuideSnapResult(
      point: guide.point,
      label: guide.label ?? shiftGuide?.label,
      lines: lines,
      snapWallId: guide.snapWallId,
      snapWallFraction: guide.snapWallFraction,
    );

    _activeGuideSnap = result;

    return result;
  }

  double _normalizeAngleDegrees(double value) {
    final normalized = value % 360;
    if (normalized < 0) return normalized + 360;
    return normalized;
  }

  double _smallestAngleDifferenceDegrees(double a, double b) {
    var diff = (a - b).abs() % 360;
    if (diff > 180) {
      diff = 360 - diff;
    }
    return diff;
  }

  double _angleDegreesFromVector(Offset vector) {
    final radians = math.atan2(vector.dy, vector.dx);
    return _normalizeAngleDegrees(radians * 180.0 / math.pi);
  }

  double _wallAngleDegrees(FloorWall wall) {
    return _angleDegreesFromVector(
      wall.end.toOffset() - wall.start.toOffset(),
    );
  }

  double? _angleBetweenSelectedWalls() {
    if (_selectedWallIds.length != 2) return null;

    final ids = _selectedWallIds.toList();

    final wallA = _findWallById(ids[0]);
    final wallB = _findWallById(ids[1]);

    if (wallA == null || wallB == null) return null;

    final angleA = _wallAngleDegrees(wallA);
    final angleB = _wallAngleDegrees(wallB);

    var diff = (angleA - angleB).abs();
    diff = diff % 360;

    if (diff > 180) {
      diff = 360 - diff;
    }

    return diff;
  }

  Offset _unitVectorFromAngleDegrees(double degrees) {
    final radians = degrees * math.pi / 180.0;

    return Offset(
      math.cos(radians),
      math.sin(radians),
    );
  }

  Offset _pointFromStartAngleLength({
    required Offset start,
    required double angleDeg,
    required double lengthPx,
  }) {
    final unit = _unitVectorFromAngleDegrees(angleDeg);

    return Offset(
      start.dx + unit.dx * lengthPx,
      start.dy + unit.dy * lengthPx,
    );
  }

  double _distanceToSegment(Offset point, Offset start, Offset end) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;

    if (dx == 0 && dy == 0) {
      return (point - start).distance;
    }

    final t = (((point.dx - start.dx) * dx) + ((point.dy - start.dy) * dy)) /
        ((dx * dx) + (dy * dy));

    final clamped = t.clamp(0.0, 1.0);

    final projection = Offset(
      start.dx + clamped * dx,
      start.dy + clamped * dy,
    );

    return (point - projection).distance;
  }

  double _projectionFractionOnWall(Offset point, FloorWall wall) {
    final start = wall.start.toOffset();
    final end = wall.end.toOffset();

    return _projectionFractionOnSegment(point, start, end);
  }

  bool _isMiddleMousePointerDown(PointerDownEvent event) {
    return (event.buttons & kMiddleMouseButton) != 0;
  }

  bool _isMiddleMousePointerMove(PointerMoveEvent event) {
    return (event.buttons & kMiddleMouseButton) != 0;
  }

  void _startMiddleMousePan(Offset globalPosition) {
    _hideContextMenu();
    _hideLengthEditor(commit: true);
    _hideAngleEditor(commit: true);
    _hideRoomNameEditor(commit: true);
    _requestFocus();

    setState(() {
      _isMiddleMousePanning = true;
      _lastMiddleMousePanGlobalPosition = globalPosition;

      _isDraggingHandle = false;
      _isDraggingOpening = false;
      _isDraggingAsset = false;
      _isResizingOpening = false;

      _draggingConnectedHandles = const [];
      _draggingOpening = null;
      _draggingAssetId = null;
      _resizingOpeningHandle = null;

      _isBoxSelecting = false;
      _selectionBoxStart = null;
      _selectionBoxEnd = null;

      _activeGuideSnap = null;
    });
  }

  void _updateMiddleMousePan(Offset globalPosition) {
    final previous = _lastMiddleMousePanGlobalPosition;

    if (previous == null) {
      _lastMiddleMousePanGlobalPosition = globalPosition;
      return;
    }

    final delta = globalPosition - previous;

    if (delta.distance <= 0.001) return;

    _panViewportBy(delta);

    setState(() {
      _lastMiddleMousePanGlobalPosition = globalPosition;
    });
  }

  void _stopMiddleMousePan() {
    if (!_isMiddleMousePanning &&
        _lastMiddleMousePanGlobalPosition == null) {
      return;
    }

    setState(() {
      _isMiddleMousePanning = false;
      _lastMiddleMousePanGlobalPosition = null;
    });
  }
}

extension _FloorPlanCanvasAdvancedGuides on _FloorPlanCanvasState {
  List<Offset> _collectGuideDirections() {
    final directions = <Offset>[];

    void addDirection(Offset vector) {
      final length = vector.distance;
      if (length <= 0.001) return;

      final normalized = Offset(
        vector.dx / length,
        vector.dy / length,
      );

      final angle = math.atan2(normalized.dy, normalized.dx);

      final alreadyExists = directions.any((existing) {
        final existingAngle = math.atan2(existing.dy, existing.dx);

        return _smallestAngleDifferenceDegrees(
              _normalizeAngleDegrees(angle * 180 / math.pi),
              _normalizeAngleDegrees(existingAngle * 180 / math.pi),
            ) <
            1.0;
      });

      if (!alreadyExists) {
        directions.add(normalized);
      }
    }

    for (final wall in widget.document.walls) {
      addDirection(wall.end.toOffset() - wall.start.toOffset());
    }

    final points = <Offset>[];

    for (final wall in widget.document.walls) {
      points.add(wall.start.toOffset());
      points.add(wall.end.toOffset());
    }

    final uniquePoints = <String, Offset>{};
    for (final point in points) {
      uniquePoints[_cornerKey(point)] = point;
    }

    final values = uniquePoints.values.toList();

    if (values.length <= 80) {
      for (var i = 0; i < values.length; i++) {
        for (var j = i + 1; j < values.length; j++) {
          addDirection(values[j] - values[i]);
        }
      }
    }

    return directions;
  }

  Offset _projectPointOnInfiniteLine({
    required Offset point,
    required Offset linePoint,
    required Offset direction,
  }) {
    final length = direction.distance;
    if (length <= 0.001) return linePoint;

    final unit = Offset(direction.dx / length, direction.dy / length);
    final relative = point - linePoint;

    final t = relative.dx * unit.dx + relative.dy * unit.dy;

    return linePoint + unit * t;
  }
}

extension _FloorPlanCanvasRoomGeometry on _FloorPlanCanvasState {
  Offset _roomLabelCanvasPosition(FloorRoom room) {
    return room.centroid();
  }

  Offset _roomLabelViewportPosition(FloorRoom room) {
    return _canvasToViewportPosition(_roomLabelCanvasPosition(room));
  }

  Rect _assetCanvasRect(FloorPlanAsset asset) {
    final widthPx = asset.widthM * widget.document.scale.pixelsPerMeter;
    final depthPx = asset.depthM * widget.document.scale.pixelsPerMeter;
    final center = asset.position.toOffset();

    return Rect.fromCenter(
      center: center,
      width: widthPx,
      height: depthPx,
    );
  }

  _DetectedRoomCandidate? _detectRoomAtPoint(Offset point) {
    final candidates = _detectRoomCandidates();

    final containing = candidates
        .where((candidate) => _pointInPolygon(point, candidate.points))
        .toList()
      ..sort((a, b) => a.areaM2.compareTo(b.areaM2));

    if (containing.isEmpty) return null;
    return containing.first;
  }

  List<_DetectedRoomCandidate> _detectRoomCandidates() {
    final walls = widget.document.walls;

    final nodes = <String, Offset>{};
    final outgoing = <String, List<_DirectedEdge>>{};

    for (final wall in walls) {
      final start = wall.start.toOffset();
      final end = wall.end.toOffset();

      if ((end - start).distance <= 0.001) continue;

      final startKey = _cornerKey(start);
      final endKey = _cornerKey(end);

      nodes[startKey] = start;
      nodes[endKey] = end;

      outgoing.putIfAbsent(startKey, () => []);
      outgoing.putIfAbsent(endKey, () => []);

      outgoing[startKey]!.add(
        _DirectedEdge(
          fromKey: startKey,
          toKey: endKey,
          from: start,
          to: end,
        ),
      );

      outgoing[endKey]!.add(
        _DirectedEdge(
          fromKey: endKey,
          toKey: startKey,
          from: end,
          to: start,
        ),
      );
    }

    for (final list in outgoing.values) {
      list.sort((a, b) => a.angle.compareTo(b.angle));
    }

    final visited = <String>{};
    final candidates = <_DetectedRoomCandidate>[];
    final uniquePolygons = <String>{};

    for (final list in outgoing.values) {
      for (final startEdge in list) {
        final edgeKey = startEdge.key;
        if (visited.contains(edgeKey)) continue;

        final polygon = <Offset>[];
        var edge = startEdge;

        for (var guard = 0; guard < 500; guard++) {
          visited.add(edge.key);
          polygon.add(edge.from);

          final nextEdges = outgoing[edge.toKey] ?? [];
          if (nextEdges.isEmpty) break;

          final reverseAngle = math.atan2(
            edge.from.dy - edge.to.dy,
            edge.from.dx - edge.to.dx,
          );

          var reverseIndex = 0;
          var bestDiff = double.infinity;

          for (var i = 0; i < nextEdges.length; i++) {
            final diff = _smallestAngleDifferenceDegrees(
              _normalizeAngleDegrees(nextEdges[i].angle * 180 / math.pi),
              _normalizeAngleDegrees(reverseAngle * 180 / math.pi),
            );

            if (diff < bestDiff) {
              bestDiff = diff;
              reverseIndex = i;
            }
          }

          final nextIndex =
              (reverseIndex - 1 + nextEdges.length) % nextEdges.length;
          edge = nextEdges[nextIndex];

          if (edge.fromKey == startEdge.fromKey &&
              edge.toKey == startEdge.toKey) {
            break;
          }
        }

        if (polygon.length < 3) continue;

        final areaPx2 = _polygonAreaPx2(polygon);
        if (areaPx2 < 1000) continue;

        final areaM2 = areaPx2 /
            (widget.document.scale.pixelsPerMeter *
                widget.document.scale.pixelsPerMeter);

        final normalizedKey = polygon.map((p) => _cornerKey(p)).toList()
          ..sort();

        final polygonKey = normalizedKey.join('|');
        if (uniquePolygons.contains(polygonKey)) continue;
        uniquePolygons.add(polygonKey);

        candidates.add(
          _DetectedRoomCandidate(
            points: polygon,
            areaM2: areaM2,
          ),
        );
      }
    }

    return candidates;
  }
}

class _DirectedEdge {
  final String fromKey;
  final String toKey;
  final Offset from;
  final Offset to;

  const _DirectedEdge({
    required this.fromKey,
    required this.toKey,
    required this.from,
    required this.to,
  });

  String get key => '$fromKey->$toKey';

  double get angle {
    return math.atan2(to.dy - from.dy, to.dx - from.dx);
  }
}