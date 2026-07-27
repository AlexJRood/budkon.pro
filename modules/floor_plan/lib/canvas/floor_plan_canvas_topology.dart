part of 'floor_plan_canvas.dart';

const int _kDoubleClickMaxMs = 360;
const double _kDoubleClickMaxCanvasPx = 12;

extension _FloorPlanCanvasTopology on _FloorPlanCanvasState {
  bool _isPrimaryPointerDown(PointerDownEvent event) {
    return (event.buttons & kPrimaryMouseButton) != 0;
  }

  bool _isDoubleClickOnCanvas(Offset canvasPoint) {
    final now = DateTime.now();
    final previousTime = _lastPrimaryClickAt;
    final previousPoint = _lastPrimaryClickCanvasPoint;

    _lastPrimaryClickAt = now;
    _lastPrimaryClickCanvasPoint = canvasPoint;

    if (previousTime == null || previousPoint == null) {
      return false;
    }

    final dt = now.difference(previousTime).inMilliseconds;
    final distance = (canvasPoint - previousPoint).distance;

    return dt <= _kDoubleClickMaxMs &&
        distance <= (_kDoubleClickMaxCanvasPx / _currentScale);
  }

  Offset _projectPointOnSegment(
    Offset point,
    Offset start,
    Offset end,
  ) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;

    if (dx.abs() < 0.000001 && dy.abs() < 0.000001) {
      return start;
    }

    final t = (((point.dx - start.dx) * dx) + ((point.dy - start.dy) * dy)) /
        ((dx * dx) + (dy * dy));

    final clamped = t.clamp(0.0, 1.0).toDouble();

    return Offset(
      start.dx + clamped * dx,
      start.dy + clamped * dy,
    );
  }

  double _projectionFractionOnSegment(
    Offset point,
    Offset start,
    Offset end,
  ) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;

    if (dx.abs() < 0.000001 && dy.abs() < 0.000001) {
      return 0;
    }

    final t = (((point.dx - start.dx) * dx) + ((point.dy - start.dy) * dy)) /
        ((dx * dx) + (dy * dy));

    return t.clamp(0.0, 1.0).toDouble();
  }

  _WallLineSnapHit? _findWallLineSnap(
    Offset point, {
    Set<String> ignoreWallIds = const {},
    double? threshold,
  }) {
    final snapThreshold = threshold ?? (14 / _currentScale);

    _WallLineSnapHit? best;

    for (final wall in widget.document.walls) {
      if (ignoreWallIds.contains(wall.id)) continue;

      final start = wall.start.toOffset();
      final end = wall.end.toOffset();
      final vector = end - start;

      if (vector.distance <= 0.001) continue;

      final fraction = _projectionFractionOnSegment(point, start, end);

      // Endpoints are handled by corner snap.
      if (fraction <= 0.02 || fraction >= 0.98) continue;

      final projected = _projectPointOnSegment(point, start, end);
      final distance = (point - projected).distance;

      if (distance > snapThreshold) continue;

      if (best == null || distance < best.distance) {
        best = _WallLineSnapHit(
          wallId: wall.id,
          wall: wall,
          point: projected,
          fraction: fraction,
          distance: distance,
        );
      }
    }

    return best;
  }

  void _splitWallAtPoint(
    FloorWall wall,
    Offset rawPoint, {
    bool selectNewWalls = true,
    bool pushHistory = true,
  }) {
    final result = _splitWallInDocument(
      widget.document,
      wallId: wall.id,
      rawPoint: rawPoint,
    );

    if (!result.didSplit) return;

    _commitDocument(
      result.document,
      pushHistory: pushHistory,
    );

    if (selectNewWalls) {
      setState(() {
        _selectedVertex = null;
        _selectedWallIds = {
          if (result.firstWallId != null) result.firstWallId!,
          if (result.secondWallId != null) result.secondWallId!,
        };

        _selectedObject = result.firstWallId == null
            ? null
            : _SelectedObject(
                type: _SelectedObjectType.wall,
                id: result.firstWallId!,
              );
      });
    }
  }

  _WallSplitResult _splitWallInDocument(
    FloorPlanDocument source, {
    required String wallId,
    required Offset rawPoint,
  }) {
    FloorWall? target;

    for (final wall in source.walls) {
      if (wall.id == wallId) {
        target = wall;
        break;
      }
    }

    if (target == null) {
      return _WallSplitResult(
        document: source,
        didSplit: false,
        splitPoint: rawPoint,
      );
    }

    final start = target.start.toOffset();
    final end = target.end.toOffset();

    final fraction = _projectionFractionOnSegment(rawPoint, start, end);
    final splitPoint = _projectPointOnSegment(rawPoint, start, end);

    if (fraction <= 0.02 || fraction >= 0.98) {
      return _WallSplitResult(
        document: source,
        didSplit: false,
        splitPoint: splitPoint,
      );
    }

    final now = DateTime.now().microsecondsSinceEpoch;
    final firstId = '${target.id}_a_$now';
    final secondId = '${target.id}_b_$now';

    final firstLengthM =
        (splitPoint - start).distance / source.scale.pixelsPerMeter;
    final secondLengthM =
        (end - splitPoint).distance / source.scale.pixelsPerMeter;

    final firstWall = FloorWall(
      id: firstId,
      start: target.start,
      end: FloorPoint.fromOffset(splitPoint),
      thickness: target.thickness,
      heightM: target.heightM,
      material: target.material,
      angleLocked: target.angleLocked,
      lockedAngleDeg: target.lockedAngleDeg,
      lengthLocked: target.lengthLocked,
      lockedLengthM: target.lengthLocked ? firstLengthM : null,
      kind: target.kind,
    );

    final secondWall = FloorWall(
      id: secondId,
      start: FloorPoint.fromOffset(splitPoint),
      end: target.end,
      thickness: target.thickness,
      heightM: target.heightM,
      material: target.material,
      angleLocked: target.angleLocked,
      lockedAngleDeg: target.lockedAngleDeg,
      lengthLocked: target.lengthLocked,
      lockedLengthM: target.lengthLocked ? secondLengthM : null,
      kind: target.kind,
    );

    final walls = <FloorWall>[];

    for (final wall in source.walls) {
      if (wall.id == wallId) {
        walls
          ..add(firstWall)
          ..add(secondWall);
      } else {
        walls.add(wall);
      }
    }

    final doors = _reassignOpeningsAfterWallSplit(
      source.doors,
      originalWallId: wallId,
      firstWallId: firstId,
      secondWallId: secondId,
      splitFraction: fraction,
    );

    final windows = _reassignOpeningsAfterWallSplit(
      source.windows,
      originalWallId: wallId,
      firstWallId: firstId,
      secondWallId: secondId,
      splitFraction: fraction,
    );

    return _WallSplitResult(
      document: source.copyWith(
        walls: walls,
        doors: doors,
        windows: windows,
      ),
      didSplit: true,
      firstWallId: firstId,
      secondWallId: secondId,
      splitPoint: splitPoint,
    );
  }

  List<Map<String, dynamic>> _reassignOpeningsAfterWallSplit(
    List<Map<String, dynamic>> source, {
    required String originalWallId,
    required String firstWallId,
    required String secondWallId,
    required double splitFraction,
  }) {
    return source.map((item) {
      final wallId = item['wall_id']?.toString();

      if (wallId != originalWallId) {
        return item;
      }

      final rawPosition = (item['position'] as num?)?.toDouble() ?? 0.5;

      if (rawPosition <= splitFraction) {
        final nextPosition = splitFraction <= 0.000001
            ? 0.0
            : (rawPosition / splitFraction).clamp(0.0, 1.0).toDouble();

        return {
          ...item,
          'wall_id': firstWallId,
          'position': nextPosition,
        };
      }

      final denominator = 1.0 - splitFraction;
      final nextPosition = denominator <= 0.000001
          ? 1.0
          : ((rawPosition - splitFraction) / denominator)
              .clamp(0.0, 1.0)
              .toDouble();

      return {
        ...item,
        'wall_id': secondWallId,
        'position': nextPosition,
      };
    }).toList();
  }

  void _moveConnectedHandlesToPoint(Offset newPoint) {
    final handles = _draggingConnectedHandles;
    if (handles.isEmpty) return;

    final updatedWalls = widget.document.walls.map((wall) {
      FloorPoint? nextStart;
      FloorPoint? nextEnd;

      for (final handle in handles) {
        if (handle.wallId != wall.id) continue;

        if (handle.kind == _WallHandleKind.start) {
          nextStart = FloorPoint.fromOffset(newPoint);
        } else {
          nextEnd = FloorPoint.fromOffset(newPoint);
        }
      }

      if (nextStart == null && nextEnd == null) return wall;

      return _copyWallWith(
        wall,
        start: nextStart,
        end: nextEnd,
      );
    }).toList();

    _commitDocument(
      widget.document.copyWith(walls: updatedWalls),
      pushHistory: false,
    );

    _selectedVertex = _SelectedVertex(
      point: newPoint,
      connectedHandles: handles,
    );
  }

  void _splitPendingVertexWallIfNeeded() {
    final pending = _pendingVertexWallSplitHit;
    if (pending == null || !pending.canSplit) return;

    _splitWallAtPoint(
      pending.wall,
      pending.point,
      selectNewWalls: false,
      pushHistory: false,
    );
  }
}