part of 'floor_plan_canvas.dart';

const int _kMaxUndoHistory = 80;

const double _kDefaultDoorWidthM = 0.9;
const String _kDefaultDoorSwingDirection = 'left';
const String _kDefaultDoorOpeningSide = 'inside';
const String _kDefaultDoorType = 'single';

const double _kDefaultWindowWidthM = 1.2;
const double _kDefaultWindowSillHeightM = 0.9;
const String _kDefaultWindowType = 'standard';

const double _kDefaultGarageDoorWidthM = 2.5;
const String _kDefaultGarageDoorType = 'garage_door';

extension _FloorPlanCanvasMutations on _FloorPlanCanvasState {
  void _commitDocument(
    FloorPlanDocument nextDocument, {
    bool pushHistory = true,
    bool clearRedo = true,
  }) {
    if (pushHistory) {
      _undoStack.add(widget.document);

      if (_undoStack.length > _kMaxUndoHistory) {
        _undoStack.removeAt(0);
      }

      if (clearRedo) {
        _redoStack.clear();
      }
    }

    widget.onChanged(nextDocument);
  }

  void _pushDragHistoryOnce() {
    if (_dragHistoryPushed) return;

    _undoStack.add(widget.document);

    if (_undoStack.length > _kMaxUndoHistory) {
      _undoStack.removeAt(0);
    }

    _redoStack.clear();
    _dragHistoryPushed = true;
  }

  void _undo() {
    if (_undoStack.isEmpty) return;

    final previous = _undoStack.removeLast();
    _redoStack.add(widget.document);

    setState(() {
      _selectedObject = null;
      _selectedWallIds.clear();
      _selectedVertex = null;
      _selectedVertexKeys.clear();

      _wallStart = null;
      _wallPreviewEnd = null;
      _activeGuideSnap = null;

      _editingLengthWallId = null;
      _editingCornerAngle = null;
      _editingRoomId = null;

      _isDraggingHandle = false;
      _draggingConnectedHandles = const [];

      _isDraggingVertexGroup = false;
      _vertexGroupDragStartCanvasPoint = null;
      _vertexDragAnchors = const [];

      _isDraggingWall = false;
      _wallDragStartCanvasPoint = null;
      _draggingWallIds = {};
      _wallDragSnapshots = const [];

      _isDraggingOpening = false;
      _draggingOpening = null;

      _isDraggingAsset = false;
      _draggingAssetId = null;

      _isResizingOpening = false;
      _resizingOpeningHandle = null;

      _isBoxSelecting = false;
      _selectionBoxStart = null;
      _selectionBoxEnd = null;

      _pendingVertexWallSplitHit = null;

      _dragHistoryPushed = false;
    });

    widget.onChanged(previous);
    _clearLiveSelectionAndLock();
  }

  void _redo() {
    if (_redoStack.isEmpty) return;

    final next = _redoStack.removeLast();
    _undoStack.add(widget.document);

    setState(() {
      _selectedObject = null;
      _selectedWallIds.clear();
      _selectedVertex = null;
      _selectedVertexKeys.clear();

      _wallStart = null;
      _wallPreviewEnd = null;
      _activeGuideSnap = null;

      _editingLengthWallId = null;
      _editingCornerAngle = null;
      _editingRoomId = null;

      _isDraggingHandle = false;
      _draggingConnectedHandles = const [];

      _isDraggingVertexGroup = false;
      _vertexGroupDragStartCanvasPoint = null;
      _vertexDragAnchors = const [];

      _isDraggingWall = false;
      _wallDragStartCanvasPoint = null;
      _draggingWallIds = {};
      _wallDragSnapshots = const [];

      _isDraggingOpening = false;
      _draggingOpening = null;

      _isDraggingAsset = false;
      _draggingAssetId = null;

      _isResizingOpening = false;
      _resizingOpeningHandle = null;

      _isBoxSelecting = false;
      _selectionBoxStart = null;
      _selectionBoxEnd = null;

      _pendingVertexWallSplitHit = null;

      _dragHistoryPushed = false;
    });

    widget.onChanged(next);
    _clearLiveSelectionAndLock();
  }

  FloorWall _copyWallWith(
    FloorWall wall, {
    FloorPoint? start,
    FloorPoint? end,
    double? thickness,
    double? heightM,
    String? material,
    String? kind,
    bool? angleLocked,
    double? lockedAngleDeg,
    bool? lengthLocked,
    double? lockedLengthM,
  }) {
    return FloorWall(
      id: wall.id,
      start: start ?? wall.start,
      end: end ?? wall.end,
      thickness: thickness ?? wall.thickness,
      heightM: heightM ?? wall.heightM,
      material: material ?? wall.material,
      kind: kind ?? wall.kind,
      angleLocked: angleLocked ?? wall.angleLocked,
      lockedAngleDeg: lockedAngleDeg ?? wall.lockedAngleDeg,
      lengthLocked: lengthLocked ?? wall.lengthLocked,
      lockedLengthM: lockedLengthM ?? wall.lockedLengthM,
    );
  }

  Offset? _pointForVertexKey(String key) {
    for (final wall in widget.document.walls) {
      final start = wall.start.toOffset();
      final end = wall.end.toOffset();

      if (_vertexSelectionKey(start) == key) return start;
      if (_vertexSelectionKey(end) == key) return end;
    }

    return null;
  }

  Offset? _currentPointForHandle(_WallHandleHit handle) {
    final wall = _findWallById(handle.wallId);
    if (wall == null) return null;

    if (handle.kind == _WallHandleKind.start) {
      return wall.start.toOffset();
    }

    return wall.end.toOffset();
  }

  Map<String, Offset> _buildRoomPointReplacementsForAnchors({
    required List<_VertexDragAnchor> anchors,
    required Offset delta,
  }) {
    final replacements = <String, Offset>{};

    for (final anchor in anchors) {
      final target = anchor.originalPoint + delta;

      replacements[anchor.vertexKey] = target;

      for (final handle in anchor.connectedHandles) {
        final currentPoint = _currentPointForHandle(handle);

        if (currentPoint != null) {
          replacements[_vertexSelectionKey(currentPoint)] = target;
        }
      }
    }

    return replacements;
  }

  Offset? _findNearReplacementForRoomPoint({
    required Offset point,
    required Map<String, Offset> replacements,
  }) {
    const tolerance = 1.5;

    for (final entry in replacements.entries) {
      final parts = entry.key.split(':');
      if (parts.length != 2) continue;

      final x = double.tryParse(parts[0]);
      final y = double.tryParse(parts[1]);

      if (x == null || y == null) continue;

      final candidate = Offset(x, y);

      if ((candidate - point).distance <= tolerance) {
        return entry.value;
      }
    }

    return null;
  }

  List<_VertexDragAnchor> _buildWallDragVertexAnchors({
    required Set<String> wallIds,
  }) {
    final pointsByKey = <String, Offset>{};

    for (final wall in widget.document.walls) {
      if (!wallIds.contains(wall.id)) continue;

      final start = wall.start.toOffset();
      final end = wall.end.toOffset();

      pointsByKey[_vertexSelectionKey(start)] = start;
      pointsByKey[_vertexSelectionKey(end)] = end;
    }

    final anchors = <_VertexDragAnchor>[];

    for (final entry in pointsByKey.entries) {
      anchors.add(
        _VertexDragAnchor(
          vertexKey: entry.key,
          originalPoint: entry.value,
          connectedHandles: _findConnectedHandles(entry.value),
        ),
      );
    }

    return anchors;
  }

  void _startVertexGroupDrag({
    required _WallHandleHit primaryHandle,
    required Offset canvasPoint,
  }) {
    final anchors = _buildVertexDragAnchors(
      primaryHandle: primaryHandle,
    );

    if (anchors.isEmpty) return;

    final primaryConnectedHandles = _findConnectedHandles(primaryHandle.point);

    setState(() {
      _isDraggingVertexGroup = true;
      _vertexGroupDragStartCanvasPoint = canvasPoint;
      _vertexDragAnchors = anchors;

      _selectedVertexKeys = anchors.map((item) => item.vertexKey).toSet();
      _selectedVertex = _SelectedVertex(
        point: primaryHandle.point,
        connectedHandles: primaryConnectedHandles,
      );

      _selectedObject = null;
      _selectedWallIds.clear();

      _isDraggingHandle = false;
      _draggingConnectedHandles = primaryConnectedHandles;

      _isDraggingWall = false;
      _wallDragStartCanvasPoint = null;
      _draggingWallIds = {};
      _wallDragSnapshots = const [];

      _isDraggingOpening = false;
      _draggingOpening = null;

      _isDraggingAsset = false;
      _draggingAssetId = null;

      _isResizingOpening = false;
      _resizingOpeningHandle = null;

      _pendingVertexWallSplitHit = null;
      _activeGuideSnap = null;
    });
  }

  void _moveVertexGroupTo({
    required Offset rawPoint,
  }) {
    final dragStart = _vertexGroupDragStartCanvasPoint;
    if (dragStart == null) return;
    if (_vertexDragAnchors.isEmpty) return;

    final primaryAnchor = _vertexDragAnchors.first;

    final rawDelta = rawPoint - dragStart;
    final primaryRawTarget = primaryAnchor.originalPoint + rawDelta;

    final ignoredWallIds = _vertexDragAnchors
        .expand((anchor) => anchor.connectedHandles)
        .map((handle) => handle.wallId)
        .toSet();

    final prepared = _prepareVertexDragPoint(
      rawPoint: primaryRawTarget,
      ignoreWallIds: ignoredWallIds,
    );

    final delta = prepared.point - primaryAnchor.originalPoint;

    if (delta.distance <= 0.001) return;

    _pushDragHistoryOnce();

    final movedPointsByOldKey = <String, Offset>{};

    for (final anchor in _vertexDragAnchors) {
      movedPointsByOldKey[anchor.vertexKey] = anchor.originalPoint + delta;
    }

    final handleTargetByKey = <String, Offset>{};

    for (final anchor in _vertexDragAnchors) {
      final target = movedPointsByOldKey[anchor.vertexKey];
      if (target == null) continue;

      for (final handle in anchor.connectedHandles) {
        handleTargetByKey[_wallHandleKey(handle)] = target;
      }
    }

    final roomPointReplacements = _buildRoomPointReplacementsForAnchors(
      anchors: _vertexDragAnchors,
      delta: delta,
    );

    final updatedWalls = widget.document.walls.map((wall) {
      final startHandle = _WallHandleHit(
        wallId: wall.id,
        kind: _WallHandleKind.start,
        point: wall.start.toOffset(),
      );

      final endHandle = _WallHandleHit(
        wallId: wall.id,
        kind: _WallHandleKind.end,
        point: wall.end.toOffset(),
      );

      final nextStart = handleTargetByKey[_wallHandleKey(startHandle)];
      final nextEnd = handleTargetByKey[_wallHandleKey(endHandle)];

      if (nextStart == null && nextEnd == null) return wall;

      return _copyWallWith(
        wall,
        start: nextStart == null ? null : FloorPoint.fromOffset(nextStart),
        end: nextEnd == null ? null : FloorPoint.fromOffset(nextEnd),
      );
    }).toList();

    var nextDocument = widget.document.copyWith(
      walls: updatedWalls,
    );

    nextDocument = _replaceRoomPointsByKey(
      document: nextDocument,
      replacements: roomPointReplacements,
    );

    _commitDocument(
      nextDocument,
      pushHistory: false,
    );

    if (prepared.snapWallId != null &&
        prepared.snapWallFraction != null &&
        prepared.snapWallFraction! > 0.02 &&
        prepared.snapWallFraction! < 0.98) {
      final wall = _findWallById(prepared.snapWallId!);

      if (wall != null) {
        _pendingVertexWallSplitHit = _WallLineSnapHit(
          wallId: prepared.snapWallId!,
          wall: wall,
          point: prepared.point,
          distance: 0,
          fraction: prepared.snapWallFraction!,
        );
      }
    } else {
      _pendingVertexWallSplitHit = null;
    }

    setState(() {
      _selectedVertexKeys =
          movedPointsByOldKey.values.map(_vertexSelectionKey).toSet();

      _selectedVertex = _SelectedVertex(
        point: prepared.point,
        connectedHandles: primaryAnchor.connectedHandles,
      );

      _activeGuideSnap = prepared;
    });
  }

  void _stopVertexGroupDrag() {
    if (!_isDraggingVertexGroup) return;

    if (_pendingVertexWallSplitHit != null) {
      _splitPendingVertexWallIfNeeded();
    }

    setState(() {
      _isDraggingVertexGroup = false;
      _vertexGroupDragStartCanvasPoint = null;
      _vertexDragAnchors = const [];

      _draggingConnectedHandles = const [];

      _pendingVertexWallSplitHit = null;
      _activeGuideSnap = null;

      _dragHistoryPushed = false;
    });
  }

  void _startWallDrag({
    required FloorWall wall,
    required Offset canvasPoint,
  }) {
    final ids = _selectedWallIds.contains(wall.id)
        ? Set<String>.from(_selectedWallIds)
        : <String>{wall.id};

    final snapshots = widget.document.walls
        .where((item) => ids.contains(item.id))
        .map(
          (item) => _WallDragSnapshot(
            wallId: item.id,
            wall: item,
            originalStart: item.start.toOffset(),
            originalEnd: item.end.toOffset(),
          ),
        )
        .toList();

    if (snapshots.isEmpty) return;

    final anchors = _buildWallDragVertexAnchors(
      wallIds: ids,
    );

    if (anchors.isEmpty) return;

    setState(() {
      _isDraggingWall = true;
      _wallDragStartCanvasPoint = canvasPoint;
      _draggingWallIds = ids;
      _wallDragSnapshots = snapshots;

      // Reuse the vertex anchor system for wall dragging.
      // This is the key part that prevents breaking connected corners.
      _vertexDragAnchors = anchors;

      _selectedObject = _SelectedObject(
        type: _SelectedObjectType.wall,
        id: wall.id,
      );
      _selectedWallIds = ids;

      _selectedVertex = null;
      _selectedVertexKeys.clear();

      _isDraggingVertexGroup = false;
      _vertexGroupDragStartCanvasPoint = null;

      _isDraggingHandle = false;
      _draggingConnectedHandles = const [];

      _isDraggingOpening = false;
      _draggingOpening = null;

      _isDraggingAsset = false;
      _draggingAssetId = null;

      _isResizingOpening = false;
      _resizingOpeningHandle = null;

      _pendingVertexWallSplitHit = null;
      _activeGuideSnap = null;
    });
  }

  void _moveWallDragTo(Offset canvasPoint) {
    final dragStart = _wallDragStartCanvasPoint;
    if (dragStart == null) return;
    if (_vertexDragAnchors.isEmpty) return;

    final rawDelta = canvasPoint - dragStart;
    if (rawDelta.distance <= 0.001) return;

    _pushDragHistoryOnce();

    Offset delta = rawDelta;

    if (_isShiftPressed) {
      if (rawDelta.dx.abs() >= rawDelta.dy.abs()) {
        delta = Offset(rawDelta.dx, 0);
      } else {
        delta = Offset(0, rawDelta.dy);
      }
    }

    final handleTargetByKey = <String, Offset>{};

    for (final anchor in _vertexDragAnchors) {
      final target = anchor.originalPoint + delta;

      for (final handle in anchor.connectedHandles) {
        handleTargetByKey[_wallHandleKey(handle)] = target;
      }
    }

    final roomPointReplacements = _buildRoomPointReplacementsForAnchors(
      anchors: _vertexDragAnchors,
      delta: delta,
    );

    final updatedWalls = widget.document.walls.map((wall) {
      final startHandle = _WallHandleHit(
        wallId: wall.id,
        kind: _WallHandleKind.start,
        point: wall.start.toOffset(),
      );

      final endHandle = _WallHandleHit(
        wallId: wall.id,
        kind: _WallHandleKind.end,
        point: wall.end.toOffset(),
      );

      final nextStart = handleTargetByKey[_wallHandleKey(startHandle)];
      final nextEnd = handleTargetByKey[_wallHandleKey(endHandle)];

      if (nextStart == null && nextEnd == null) return wall;

      return _copyWallWith(
        wall,
        start: nextStart == null ? null : FloorPoint.fromOffset(nextStart),
        end: nextEnd == null ? null : FloorPoint.fromOffset(nextEnd),
      );
    }).toList();

    var nextDocument = widget.document.copyWith(
      walls: updatedWalls,
    );

    nextDocument = _replaceRoomPointsByKey(
      document: nextDocument,
      replacements: roomPointReplacements,
    );

    _commitDocument(
      nextDocument,
      pushHistory: false,
    );
  }

  void _stopWallDrag() {
    if (!_isDraggingWall) return;

    setState(() {
      _isDraggingWall = false;
      _wallDragStartCanvasPoint = null;
      _draggingWallIds = {};
      _wallDragSnapshots = const [];

      // Important: clear reused wall drag anchors.
      _vertexDragAnchors = const [];

      _dragHistoryPushed = false;
      _activeGuideSnap = null;
    });
  }

  _WallDragSnapshot? _findWallDragSnapshot(String wallId) {
    for (final snapshot in _wallDragSnapshots) {
      if (snapshot.wallId == wallId) return snapshot;
    }

    return null;
  }

  String _wallHandleKey(_WallHandleHit handle) {
    final kind = handle.kind == _WallHandleKind.start ? 'start' : 'end';
    return '${handle.wallId}:$kind';
  }

  FloorPlanDocument _replaceRoomPointsByKey({
    required FloorPlanDocument document,
    required Map<String, Offset> replacements,
  }) {
    if (replacements.isEmpty) return document;

    final rooms = document.rooms.map((room) {
      final nextPoints = room.points.map((point) {
        final offset = point.toOffset();
        final key = _cornerKey(offset);

        final replacement = replacements[key] ??
            _findNearReplacementForRoomPoint(
              point: offset,
              replacements: replacements,
            );

        if (replacement == null) return point;

        return FloorPoint.fromOffset(replacement);
      }).toList();

      return FloorRoom(
        id: room.id,
        name: room.name,
        points: nextPoints,
        colorHex: room.colorHex,
        showName: room.showName,
        showArea: room.showArea,
      );
    }).toList();

    return document.copyWith(
      rooms: rooms,
    );
  }

  void _showLengthEditorForWall(FloorWall wall) {
    final lengthM = wall.lengthM(widget.document.scale.pixelsPerMeter);
    final text = lengthM.toStringAsFixed(2);

    _lengthEditorController.text = text;
    _lengthEditorController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: text.length,
    );

    setState(() {
      _editingLengthWallId = wall.id;
      _selectedVertex = null;
      _selectedVertexKeys.clear();
      _selectedWallIds = {wall.id};
      _selectedObject = _SelectedObject(
        type: _SelectedObjectType.wall,
        id: wall.id,
      );
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _lengthEditorFocusNode.requestFocus();
      _lengthEditorController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _lengthEditorController.text.length,
      );
    });
  }

  void _hideLengthEditor({bool commit = false}) {
    if (commit) {
      _commitLengthEditorValue();
    }

    if (_editingLengthWallId == null) return;

    setState(() {
      _editingLengthWallId = null;
    });
  }

  void _submitWallLengthEditor(String value) {
    final wallId = _editingLengthWallId;
    if (wallId == null) return;

    final parsed = _parseDouble(value);
    if (parsed == null || parsed <= 0) return;

    _setWallLengthM(
      wallId: wallId,
      lengthM: parsed,
    );

    setState(() {
      _editingLengthWallId = null;
    });
  }

  bool _commitLengthEditorValue() {
    final wallId = _editingLengthWallId;
    if (wallId == null) return false;

    final parsed = _parseDouble(_lengthEditorController.text);
    if (parsed == null || parsed <= 0) return false;

    _setWallLengthM(
      wallId: wallId,
      lengthM: parsed,
    );

    return true;
  }

  void _setWallLengthM({
    required String wallId,
    required double lengthM,
  }) {
    final wall = _findWallById(wallId);
    if (wall == null) return;
    if (lengthM <= 0) return;

    final start = wall.start.toOffset();

    final angleDeg = wall.angleLocked && wall.lockedAngleDeg != null
        ? wall.lockedAngleDeg!
        : _wallAngleDegrees(wall);

    final targetLengthPx = lengthM * widget.document.scale.pixelsPerMeter;

    final nextEnd = _pointFromStartAngleLength(
      start: start,
      angleDeg: angleDeg,
      lengthPx: targetLengthPx,
    );

    final updatedWall = _copyWallWith(
      wall,
      end: FloorPoint(
        x: nextEnd.dx,
        y: nextEnd.dy,
      ),
      lockedLengthM: wall.lengthLocked ? lengthM : wall.lockedLengthM,
    );

    _commitDocument(
      widget.document.copyWith(
        walls: _replaceWall(updatedWall),
      ),
    );
  }

  Offset _constrainHandlePoint({
    required Offset rawPoint,
    required _WallHandleHit handle,
  }) {
    final wall = _findWallById(handle.wallId);
    if (wall == null) return rawPoint;

    final pixelsPerMeter = widget.document.scale.pixelsPerMeter;
    final isMovingEnd = handle.kind == _WallHandleKind.end;

    final fixedPoint = isMovingEnd
        ? wall.start.toOffset()
        : wall.end.toOffset();

    final rawVector = isMovingEnd
        ? rawPoint - fixedPoint
        : fixedPoint - rawPoint;

    final rawLengthPx = rawVector.distance;

    if (rawLengthPx <= 0.001) {
      return rawPoint;
    }

    final hasAngleLock = wall.angleLocked && wall.lockedAngleDeg != null;
    final hasLengthLock = wall.lengthLocked && wall.lockedLengthM != null;

    final angleDeg = hasAngleLock
        ? wall.lockedAngleDeg!
        : _angleDegreesFromVector(rawVector);

    final lengthPx = hasLengthLock
        ? wall.lockedLengthM! * pixelsPerMeter
        : rawLengthPx;

    final unit = _unitVectorFromAngleDegrees(angleDeg);

    if (isMovingEnd) {
      return Offset(
        fixedPoint.dx + unit.dx * lengthPx,
        fixedPoint.dy + unit.dy * lengthPx,
      );
    }

    return Offset(
      fixedPoint.dx - unit.dx * lengthPx,
      fixedPoint.dy - unit.dy * lengthPx,
    );
  }

  Offset _resolveConstrainedSharedCornerPoint({
    required Offset rawPoint,
    required List<_WallHandleHit> handles,
  }) {
    final snappedRaw = _snapToGridAndCorners(rawPoint);
    final candidates = <Offset>[];

    for (final handle in handles) {
      final wall = _findWallById(handle.wallId);
      if (wall == null) continue;

      final hasAnyLock = wall.angleLocked == true || wall.lengthLocked == true;

      if (!hasAnyLock) continue;

      final candidate = _constrainHandlePoint(
        rawPoint: snappedRaw,
        handle: handle,
      );

      candidates.add(candidate);
    }

    if (candidates.isEmpty) {
      return snappedRaw;
    }

    if (candidates.length == 1) {
      return candidates.first;
    }

    Offset best = candidates.first;
    double bestDistance = (best - snappedRaw).distance;

    for (final candidate in candidates.skip(1)) {
      final distance = (candidate - snappedRaw).distance;

      if (distance < bestDistance) {
        best = candidate;
        bestDistance = distance;
      }
    }

    return best;
  }

  bool _didCloseContinuousShape(Offset endPoint) {
    final first = _continuousFirstPoint;
    if (first == null) return false;

    if (_continuousWallCount < 2) return false;

    final threshold = 12 / _currentScale;
    return (endPoint - first).distance <= threshold;
  }

  void _moveConnectedHandles(Offset rawPoint) {
    final handles = _draggingConnectedHandles;
    if (handles.isEmpty) return;

    final newPoint = _resolveConstrainedSharedCornerPoint(
      rawPoint: rawPoint,
      handles: handles,
    );

    final replacements = <String, Offset>{};

    for (final handle in handles) {
      final currentPoint = _currentPointForHandle(handle) ?? handle.point;
      replacements[_vertexSelectionKey(currentPoint)] = newPoint;
      replacements[_vertexSelectionKey(handle.point)] = newPoint;
    }

    final updatedWalls = widget.document.walls.map((wall) {
      FloorPoint? nextStart;
      FloorPoint? nextEnd;

      for (final handle in handles) {
        if (handle.wallId != wall.id) continue;

        if (handle.kind == _WallHandleKind.start) {
          nextStart = FloorPoint(x: newPoint.dx, y: newPoint.dy);
        } else {
          nextEnd = FloorPoint(x: newPoint.dx, y: newPoint.dy);
        }
      }

      if (nextStart == null && nextEnd == null) return wall;

      return _copyWallWith(
        wall,
        start: nextStart,
        end: nextEnd,
      );
    }).toList();

    var nextDocument = widget.document.copyWith(
      walls: updatedWalls,
    );

    nextDocument = _replaceRoomPointsByKey(
      document: nextDocument,
      replacements: replacements,
    );

    _commitDocument(
      nextDocument,
      pushHistory: false,
    );
  }

  void _moveOpeningOnWall(_OpeningHit opening, double position) {
    if (opening.type == _SelectedObjectType.door) {
      final current = _findOpeningById(opening.id, widget.document.doors);
      if (current == null) return;

      final next = {
        ...current,
        'position': position.clamp(0.0, 1.0),
      };

      _commitDocument(
        widget.document.copyWith(
          doors: _replaceOpening(widget.document.doors, opening.id, next),
        ),
        pushHistory: false,
      );

      return;
    }

    if (opening.type == _SelectedObjectType.window) {
      final current = _findOpeningById(opening.id, widget.document.windows);
      if (current == null) return;

      final next = {
        ...current,
        'position': position.clamp(0.0, 1.0),
      };

      _commitDocument(
        widget.document.copyWith(
          windows: _replaceOpening(widget.document.windows, opening.id, next),
        ),
        pushHistory: false,
      );
    }
  }

  void _addDoor({
    required FloorWall wall,
    required double position,
  }) {
    final id = 'door_${DateTime.now().microsecondsSinceEpoch}';

    final door = {
      'id': id,
      'wall_id': wall.id,
      'position': position.clamp(0.0, 1.0),
      'width_m': _kDefaultDoorWidthM,
      'swing_direction': _kDefaultDoorSwingDirection,
      'opening_side': _kDefaultDoorOpeningSide,
      'type': _kDefaultDoorType,
    };

    _commitDocument(
      widget.document.copyWith(
        doors: [
          ...widget.document.doors,
          door,
        ],
      ),
    );

    setState(() {
      _selectedVertex = null;
      _selectedVertexKeys.clear();
      _selectedWallIds.clear();
      _selectedObject = _SelectedObject(
        type: _SelectedObjectType.door,
        id: id,
      );
    });
  }

  void _addWindow({
    required FloorWall wall,
    required double position,
  }) {
    final id = 'window_${DateTime.now().microsecondsSinceEpoch}';

    final window = {
      'id': id,
      'wall_id': wall.id,
      'position': position.clamp(0.0, 1.0),
      'width_m': _kDefaultWindowWidthM,
      'type': _kDefaultWindowType,
      'sill_height_m': _kDefaultWindowSillHeightM,
    };

    _commitDocument(
      widget.document.copyWith(
        windows: [
          ...widget.document.windows,
          window,
        ],
      ),
    );

    setState(() {
      _selectedVertex = null;
      _selectedVertexKeys.clear();
      _selectedWallIds.clear();
      _selectedObject = _SelectedObject(
        type: _SelectedObjectType.window,
        id: id,
      );
    });
  }

  void _addDoorToSelectedWallCenter() {
    final wall = _selectedWall;
    if (wall == null) return;

    _addDoor(
      wall: wall,
      position: 0.5,
    );
  }

  void _addWindowToSelectedWallCenter() {
    final wall = _selectedWall;
    if (wall == null) return;

    _addWindow(
      wall: wall,
      position: 0.5,
    );
  }

  void _centerSelectedDoor() {
    final door = _selectedDoor;
    if (door == null) return;

    _updateSelectedDoor({
      ...door,
      'position': 0.5,
    });
  }

  void _centerSelectedWindow() {
    final window = _selectedWindow;
    if (window == null) return;

    _updateSelectedWindow({
      ...window,
      'position': 0.5,
    });
  }

  void _cancelCurrentDrawing() {
    setState(() {
      _wallStart = null;
      _wallPreviewEnd = null;
      _continuousFirstPoint = null;
      _continuousWallCount = 0;
      _activeGuideSnap = null;
    });
  }

  void _deleteSelectedObject() {
    final selected = _selectedObject;

    if (selected == null && _selectedVertexKeys.isNotEmpty) {
      setState(() {
        _selectedVertex = null;
        _selectedVertexKeys.clear();
      });

      _clearLiveSelectionAndLock();
      return;
    }

    if (selected == null) return;

    _hideLengthEditor();
    _hideAngleEditor();
    _hideRoomNameEditor();

    if (selected.isRoom) {
      _commitDocument(
        widget.document.copyWith(
          rooms: widget.document.rooms
              .where((room) => room.id != selected.id)
              .toList(),
        ),
      );
    } else if (selected.isAsset) {
      _commitDocument(
        widget.document.copyWith(
          assets: widget.document.assets
              .where((asset) => asset.id != selected.id)
              .toList(),
        ),
      );
    } else if (selected.isWall) {
      final wallIds = _selectedWallIds.isNotEmpty
          ? Set<String>.from(_selectedWallIds)
          : <String>{selected.id};

      _commitDocument(
        widget.document.copyWith(
          walls: widget.document.walls
              .where((wall) => !wallIds.contains(wall.id))
              .toList(),
          doors: widget.document.doors
              .where((door) => !wallIds.contains(door['wall_id']?.toString()))
              .toList(),
          windows: widget.document.windows
              .where(
                (window) => !wallIds.contains(window['wall_id']?.toString()),
              )
              .toList(),
        ),
      );
    } else if (selected.isDoor) {
      _commitDocument(
        widget.document.copyWith(
          doors: widget.document.doors
              .where((door) => door['id']?.toString() != selected.id)
              .toList(),
        ),
      );
    } else if (selected.isWindow) {
      _commitDocument(
        widget.document.copyWith(
          windows: widget.document.windows
              .where((window) => window['id']?.toString() != selected.id)
              .toList(),
        ),
      );
    }

    setState(() {
      _selectedObject = null;
      _selectedWallIds.clear();
      _selectedVertex = null;
      _selectedVertexKeys.clear();
    });

    _clearLiveSelectionAndLock();
  }

  void _setSelectedWallLengthM(double lengthM) {
    final wall = _selectedWall;
    if (wall == null) return;

    _setWallLengthM(
      wallId: wall.id,
      lengthM: lengthM,
    );
  }

  void _setSelectedWallThickness(double thickness) {
    final wall = _selectedWall;
    if (wall == null) return;

    final safeThickness = thickness.clamp(1.0, 80.0).toDouble();

    final updatedWall = _copyWallWith(
      wall,
      thickness: safeThickness,
    );

    _commitDocument(
      widget.document.copyWith(
        walls: _replaceWall(updatedWall),
      ),
    );
  }

  void _setSelectedWallAngleDeg(double angleDeg) {
    final wall = _selectedWall;
    if (wall == null) return;

    final start = wall.start.toOffset();

    final lengthPx = wall.lengthLocked && wall.lockedLengthM != null
        ? wall.lockedLengthM! * widget.document.scale.pixelsPerMeter
        : wall.lengthPx();

    final normalizedAngle = _normalizeAngleDegrees(angleDeg);

    final nextEnd = _pointFromStartAngleLength(
      start: start,
      angleDeg: normalizedAngle,
      lengthPx: lengthPx,
    );

    final updatedWall = _copyWallWith(
      wall,
      end: FloorPoint(
        x: nextEnd.dx,
        y: nextEnd.dy,
      ),
      angleLocked: true,
      lockedAngleDeg: normalizedAngle,
    );

    _commitDocument(
      widget.document.copyWith(
        walls: _replaceWall(updatedWall),
      ),
    );
  }

  void _toggleSelectedWallAngleLock(bool enabled) {
    final wall = _selectedWall;
    if (wall == null) return;

    final currentAngle = _wallAngleDegrees(wall);

    final updatedWall = _copyWallWith(
      wall,
      angleLocked: enabled,
      lockedAngleDeg: enabled
          ? _normalizeAngleDegrees(wall.lockedAngleDeg ?? currentAngle)
          : wall.lockedAngleDeg,
    );

    _commitDocument(
      widget.document.copyWith(
        walls: _replaceWall(updatedWall),
      ),
    );
  }

  void _toggleSelectedWallLengthLock(bool enabled) {
    final wall = _selectedWall;
    if (wall == null) return;

    final currentLengthM = wall.lengthM(widget.document.scale.pixelsPerMeter);

    final updatedWall = _copyWallWith(
      wall,
      lengthLocked: enabled,
      lockedLengthM:
          enabled ? wall.lockedLengthM ?? currentLengthM : wall.lockedLengthM,
    );

    _commitDocument(
      widget.document.copyWith(
        walls: _replaceWall(updatedWall),
      ),
    );
  }

  void _setSelectedWallLockedLengthM(double lengthM) {
    final wall = _selectedWall;
    if (wall == null) return;
    if (lengthM <= 0) return;

    final start = wall.start.toOffset();

    final angleDeg = wall.angleLocked && wall.lockedAngleDeg != null
        ? wall.lockedAngleDeg!
        : _wallAngleDegrees(wall);

    final lengthPx = lengthM * widget.document.scale.pixelsPerMeter;

    final nextEnd = _pointFromStartAngleLength(
      start: start,
      angleDeg: angleDeg,
      lengthPx: lengthPx,
    );

    final updatedWall = _copyWallWith(
      wall,
      end: FloorPoint(
        x: nextEnd.dx,
        y: nextEnd.dy,
      ),
      lengthLocked: true,
      lockedLengthM: lengthM,
    );

    _commitDocument(
      widget.document.copyWith(
        walls: _replaceWall(updatedWall),
      ),
    );
  }

  void _updateSelectedDoor(Map<String, dynamic> nextDoor) {
    final selected = _selectedObject;
    if (selected == null || !selected.isDoor) return;

    _commitDocument(
      widget.document.copyWith(
        doors: _replaceOpening(widget.document.doors, selected.id, nextDoor),
      ),
    );
  }

  void _updateSelectedWindow(Map<String, dynamic> nextWindow) {
    final selected = _selectedObject;
    if (selected == null || !selected.isWindow) return;

    _commitDocument(
      widget.document.copyWith(
        windows: _replaceOpening(
          widget.document.windows,
          selected.id,
          nextWindow,
        ),
      ),
    );
  }
}

extension _FloorPlanCanvasAdvancedMutations on _FloorPlanCanvasState {
  void _showAngleEditor(_CornerAngleLabelHit hit) {
    final text = hit.angleDeg.toStringAsFixed(1);

    _angleEditorController.text = text;
    _angleEditorController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: text.length,
    );

    setState(() {
      _editingCornerAngle = hit;
      _selectedVertex = null;
      _selectedVertexKeys.clear();
      _selectedWallIds = {hit.wallAId, hit.wallBId};
      _selectedObject = _SelectedObject(
        type: _SelectedObjectType.wall,
        id: hit.wallBId,
      );
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _angleEditorFocusNode.requestFocus();
      _angleEditorController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _angleEditorController.text.length,
      );
    });
  }

  void _hideAngleEditor({bool commit = false}) {
    if (commit) {
      _commitAngleEditorValue();
    }

    if (_editingCornerAngle == null) return;

    setState(() {
      _editingCornerAngle = null;
    });
  }

  void _submitCornerAngleEditor(String value) {
    final parsed = _parseDouble(value);
    if (parsed == null || parsed <= 0 || parsed >= 180) return;

    final hit = _editingCornerAngle;
    if (hit == null) return;

    _setCornerAngleDeg(
      hit: hit,
      angleDeg: parsed,
    );

    setState(() {
      _editingCornerAngle = null;
    });
  }

  bool _commitAngleEditorValue() {
    final parsed = _parseDouble(_angleEditorController.text);
    if (parsed == null || parsed <= 0 || parsed >= 180) return false;

    final hit = _editingCornerAngle;
    if (hit == null) return false;

    _setCornerAngleDeg(
      hit: hit,
      angleDeg: parsed,
    );

    return true;
  }

  void _setCornerAngleDeg({
    required _CornerAngleLabelHit hit,
    required double angleDeg,
  }) {
    final wallA = _findWallById(hit.wallAId);
    final wallB = _findWallById(hit.wallBId);

    if (wallA == null || wallB == null) return;

    final corner = hit.corner;

    final aStart = wallA.start.toOffset();
    final aEnd = wallA.end.toOffset();

    Offset aDirection;

    if ((aStart - corner).distance < 2) {
      aDirection = aEnd - aStart;
    } else {
      aDirection = aStart - aEnd;
    }

    if (aDirection.distance <= 0.001) return;

    final aAngle = math.atan2(aDirection.dy, aDirection.dx);

    final targetAngle =
        aAngle + hit.sweepSign * (angleDeg * math.pi / 180.0);

    final bStart = wallB.start.toOffset();
    final bEnd = wallB.end.toOffset();

    final bStartIsCorner = (bStart - corner).distance < 2;
    final otherPoint = bStartIsCorner ? bEnd : bStart;
    final bLength = (otherPoint - corner).distance;

    final nextOther = Offset(
      corner.dx + math.cos(targetAngle) * bLength,
      corner.dy + math.sin(targetAngle) * bLength,
    );

    final updatedWall = _copyWallWith(
      wallB,
      start: bStartIsCorner
          ? FloorPoint.fromOffset(corner)
          : FloorPoint.fromOffset(nextOther),
      end: bStartIsCorner
          ? FloorPoint.fromOffset(nextOther)
          : FloorPoint.fromOffset(corner),
      angleLocked: true,
      lockedAngleDeg: _normalizeAngleDegrees(targetAngle * 180.0 / math.pi),
    );

    _commitDocument(
      widget.document.copyWith(
        walls: _replaceWall(updatedWall),
      ),
    );
  }

  void _createRoomFromPoint(Offset point) {
    final detected = _detectRoomAtPoint(point);

    if (detected == null) {
      return;
    }

    final existing = widget.document.rooms.any((room) {
      if (room.points.length != detected.points.length) return false;

      final existingKeys =
          room.points.map((p) => _cornerKey(p.toOffset())).toSet();
      final detectedKeys = detected.points.map(_cornerKey).toSet();

      return existingKeys.length == detectedKeys.length &&
          existingKeys.containsAll(detectedKeys);
    });

    if (existing) {
      return;
    }

    final room = FloorRoom(
      id: 'room_${DateTime.now().microsecondsSinceEpoch}',
      name: 'Pomieszczenie ${widget.document.rooms.length + 1}',
      points: detected.points.map(FloorPoint.fromOffset).toList(),
      showName: true,
      showArea: true,
    );

    _commitDocument(
      widget.document.copyWith(
        rooms: [
          ...widget.document.rooms,
          room,
        ],
      ),
    );

    setState(() {
      _selectedVertex = null;
      _selectedVertexKeys.clear();
      _selectedObject = _SelectedObject(
        type: _SelectedObjectType.room,
        id: room.id,
      );
      _selectedWallIds.clear();
    });

    _showRoomNameEditor(room);
  }

  void _showRoomNameEditor(FloorRoom room) {
    _roomNameEditorController.text = room.name;
    _roomNameEditorController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: room.name.length,
    );

    setState(() {
      _editingRoomId = room.id;
      _selectedVertex = null;
      _selectedVertexKeys.clear();
      _selectedObject = _SelectedObject(
        type: _SelectedObjectType.room,
        id: room.id,
      );
      _selectedWallIds.clear();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _roomNameEditorFocusNode.requestFocus();
      _roomNameEditorController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _roomNameEditorController.text.length,
      );
    });
  }

  void _hideRoomNameEditor({bool commit = false}) {
    if (commit) {
      _commitRoomNameEditorValue();
    }

    if (_editingRoomId == null) return;

    setState(() {
      _editingRoomId = null;
    });
  }

  void _submitRoomNameEditor(String value) {
    final roomId = _editingRoomId;
    if (roomId == null) return;

    _renameRoom(
      roomId,
      value.trim().isEmpty ? 'Pomieszczenie' : value.trim(),
    );

    setState(() {
      _editingRoomId = null;
    });
  }

  bool _commitRoomNameEditorValue() {
    final roomId = _editingRoomId;
    if (roomId == null) return false;

    final value = _roomNameEditorController.text.trim();

    _renameRoom(
      roomId,
      value.isEmpty ? 'Pomieszczenie' : value,
    );

    return true;
  }

  void _renameSelectedRoom(String value) {
    final room = _selectedRoom;
    if (room == null) return;

    _renameRoom(room.id, value);
  }

  void _renameRoom(String roomId, String name) {
    final rooms = widget.document.rooms.map((room) {
      if (room.id != roomId) return room;

      return FloorRoom(
        id: room.id,
        name: name,
        points: room.points,
        colorHex: room.colorHex,
        showName: room.showName,
        showArea: room.showArea,
      );
    }).toList();

    _commitDocument(
      widget.document.copyWith(
        rooms: rooms,
      ),
    );
  }

  void _addGarageDoor({
    required FloorWall wall,
    required double position,
  }) {
    final id = 'garage_door_${DateTime.now().microsecondsSinceEpoch}';

    final garageDoor = {
      'id': id,
      'wall_id': wall.id,
      'position': position.clamp(0.0, 1.0),
      'width_m': _kDefaultGarageDoorWidthM,
      'type': _kDefaultGarageDoorType,
    };

    _commitDocument(
      widget.document.copyWith(
        doors: [
          ...widget.document.doors,
          garageDoor,
        ],
      ),
    );

    setState(() {
      _selectedVertex = null;
      _selectedVertexKeys.clear();
      _selectedWallIds.clear();
      _selectedObject = _SelectedObject(
        type: _SelectedObjectType.door,
        id: id,
      );
    });
  }

  void _addAssetAtPoint(Offset point) {
    final size = _selectedAssetType.defaultSizeM;

    final asset = FloorPlanAsset(
      id: 'asset_${DateTime.now().microsecondsSinceEpoch}',
      type: _selectedAssetType.key,
      position: FloorPoint.fromOffset(point),
      widthM: size.width,
      depthM: size.height,
      rotationDeg: 0,
      label: _selectedAssetType.label,
    );

    _commitDocument(
      widget.document.copyWith(
        assets: [
          ...widget.document.assets,
          asset,
        ],
      ),
    );

    setState(() {
      _selectedVertex = null;
      _selectedVertexKeys.clear();
      _selectedObject = _SelectedObject(
        type: _SelectedObjectType.asset,
        id: asset.id,
      );
      _selectedWallIds.clear();
    });
  }

  void _moveAssetTo(String assetId, Offset point) {
    final assets = widget.document.assets.map((asset) {
      if (asset.id != assetId) return asset;

      return FloorPlanAsset(
        id: asset.id,
        type: asset.type,
        position: FloorPoint.fromOffset(_snapToGrid(point)),
        widthM: asset.widthM,
        depthM: asset.depthM,
        rotationDeg: asset.rotationDeg,
        label: asset.label,
      );
    }).toList();

    _commitDocument(
      widget.document.copyWith(
        assets: assets,
      ),
      pushHistory: false,
    );
  }


  void _setSelectedWallKind(FloorWallKind kind) {
    final wall = _selectedWall;
    if (wall == null) return;

    final previousKind = wall.wallKind;
    final shouldApplyDefaultThickness = previousKind != kind;

    final updatedWall = _copyWallWith(
      wall,
      kind: kind.key,
      thickness: shouldApplyDefaultThickness
          ? kind.defaultThicknessCm
          : wall.thickness,
    );

    _commitDocument(
      widget.document.copyWith(
        walls: _replaceWall(updatedWall),
      ),
    );
  }



  void _updateSelectedAsset(FloorPlanAsset nextAsset) {
    final selected = _selectedObject;
    if (selected == null || !selected.isAsset) return;

    final assets = widget.document.assets.map((asset) {
      if (asset.id == selected.id) return nextAsset;
      return asset;
    }).toList();

    _commitDocument(
      widget.document.copyWith(
        assets: assets,
      ),
    );
  }
}