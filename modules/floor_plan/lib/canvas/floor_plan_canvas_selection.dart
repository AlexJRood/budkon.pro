part of 'floor_plan_canvas.dart';

extension _FloorPlanCanvasSelection on _FloorPlanCanvasState {
  FloorWall? get _selectedWall {
    final selected = _selectedObject;
    if (selected == null || !selected.isWall) return null;
    return _findWallById(selected.id);
  }

  Map<String, dynamic>? get _selectedDoor {
    final selected = _selectedObject;
    if (selected == null || !selected.isDoor) return null;

    return _findOpeningById(
      selected.id,
      widget.document.doors,
    );
  }

  Map<String, dynamic>? get _selectedWindow {
    final selected = _selectedObject;
    if (selected == null || !selected.isWindow) return null;

    return _findOpeningById(
      selected.id,
      widget.document.windows,
    );
  }

  FloorWall? get _editingLengthWall {
    final id = _editingLengthWallId;
    if (id == null) return null;
    return _findWallById(id);
  }

  FloorWall? _findWallById(String id) {
    for (final wall in widget.document.walls) {
      if (wall.id == id) return wall;
    }

    return null;
  }

  Map<String, dynamic>? _findOpeningById(
    String id,
    List<Map<String, dynamic>> items,
  ) {
    for (final item in items) {
      if (item['id']?.toString() == id) {
        return Map<String, dynamic>.from(item);
      }
    }

    return null;
  }

  List<FloorWall> _replaceWall(FloorWall updatedWall) {
    return widget.document.walls.map((wall) {
      if (wall.id == updatedWall.id) return updatedWall;
      return wall;
    }).toList();
  }

  List<Map<String, dynamic>> _replaceOpening(
    List<Map<String, dynamic>> source,
    String id,
    Map<String, dynamic> next,
  ) {
    return source.map((item) {
      if (item['id']?.toString() == id) {
        return next;
      }

      return item;
    }).toList();
  }

  String _vertexSelectionKey(Offset point) {
    return _cornerKey(point);
  }

  bool _isVertexSelected(Offset point) {
    return _selectedVertexKeys.contains(_vertexSelectionKey(point));
  }

  void _selectSingleVertex(Offset point) {
    final key = _vertexSelectionKey(point);
    final connectedHandles = _findConnectedHandles(point);

    setState(() {
      _selectedObject = null;
      _selectedWallIds.clear();
      _selectedVertexKeys = {key};
      _selectedVertex = _SelectedVertex(
        point: point,
        connectedHandles: connectedHandles,
      );
    });

    _clearLiveSelectionAndLock();
    _emitLiveSelectionChanged();
  }

  void _toggleVertexSelection(Offset point) {
    final key = _vertexSelectionKey(point);
    final next = Set<String>.from(_selectedVertexKeys);

    if (next.contains(key)) {
      next.remove(key);
    } else {
      next.add(key);
    }

    setState(() {
      _selectedObject = null;
      _selectedWallIds.clear();
      _selectedVertexKeys = next;

      if (next.isEmpty) {
        _selectedVertex = null;
      } else {
        _selectedVertex = _SelectedVertex(
          point: point,
          connectedHandles: _findConnectedHandles(point),
        );
      }
    });

    _clearLiveSelectionAndLock();
    _emitLiveSelectionChanged();
  }

  void _clearVertexSelection() {
    setState(() {
      _selectedVertex = null;
      _selectedVertexKeys.clear();
    });

    _emitLiveSelectionChanged();
  }

  List<_VertexDragAnchor> _buildVertexDragAnchors({
    required _WallHandleHit primaryHandle,
  }) {
    final primaryKey = _vertexSelectionKey(primaryHandle.point);

    final selectedKeys = _selectedVertexKeys.contains(primaryKey)
        ? Set<String>.from(_selectedVertexKeys)
        : <String>{primaryKey};

    final pointsByKey = <String, Offset>{};

    for (final wall in widget.document.walls) {
      final start = wall.start.toOffset();
      final end = wall.end.toOffset();

      final startKey = _vertexSelectionKey(start);
      final endKey = _vertexSelectionKey(end);

      if (selectedKeys.contains(startKey)) {
        pointsByKey[startKey] = start;
      }

      if (selectedKeys.contains(endKey)) {
        pointsByKey[endKey] = end;
      }
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

  Set<String> _verticesInsideRect(Rect rect) {
    final result = <String>{};

    for (final wall in widget.document.walls) {
      final start = wall.start.toOffset();
      final end = wall.end.toOffset();

      if (rect.contains(start)) {
        result.add(_vertexSelectionKey(start));
      }

      if (rect.contains(end)) {
        result.add(_vertexSelectionKey(end));
      }
    }

    return result;
  }

  Offset? _findVertexPointByKey(String key) {
    for (final wall in widget.document.walls) {
      final start = wall.start.toOffset();
      final end = wall.end.toOffset();

      if (_vertexSelectionKey(start) == key) {
        return start;
      }

      if (_vertexSelectionKey(end) == key) {
        return end;
      }
    }

    return null;
  }

  void _selectSingleWall(String wallId) {
    if (!_guardLiveLock(objectType: 'wall', objectId: wallId)) {
      return;
    }

    setState(() {
      _selectedWallIds = {wallId};
      _selectedObject = _SelectedObject(
        type: _SelectedObjectType.wall,
        id: wallId,
      );
      _selectedVertex = null;
      _selectedVertexKeys.clear();
    });

    _syncLiveLockForObject(
      objectType: 'wall',
      objectId: wallId,
    );

    _emitLiveSelectionChanged();
  }

  void _toggleWallSelection(String wallId) {
    if (!_guardLiveLock(objectType: 'wall', objectId: wallId)) {
      return;
    }

    final next = Set<String>.from(_selectedWallIds);

    if (next.contains(wallId)) {
      next.remove(wallId);
    } else {
      next.add(wallId);
    }

    setState(() {
      _selectedWallIds = next;
      _selectedVertex = null;
      _selectedVertexKeys.clear();

      if (next.isEmpty) {
        _selectedObject = null;
      } else {
        _selectedObject = _SelectedObject(
          type: _SelectedObjectType.wall,
          id: wallId,
        );
      }
    });

    if (next.isEmpty) {
      _clearLiveSelectionAndLock();
    } else {
      _syncLiveLockForObject(
        objectType: 'wall',
        objectId: wallId,
      );

      _emitLiveSelectionChanged();
    }
  }

  void _clearSelection() {
    setState(() {
      _selectedObject = null;
      _selectedWallIds.clear();
      _selectedVertex = null;
      _selectedVertexKeys.clear();
      _mobileInspectorVisible = false;
    });

    _clearLiveSelectionAndLock();
  }

  Rect? _currentSelectionRect() {
    final start = _selectionBoxStart;
    final end = _selectionBoxEnd;

    if (start == null || end == null) return null;

    return Rect.fromPoints(start, end);
  }

  Set<String> _wallsInsideRect(Rect rect) {
    final result = <String>{};

    for (final wall in widget.document.walls) {
      final start = wall.start.toOffset();
      final end = wall.end.toOffset();
      final center = Offset(
        (start.dx + end.dx) / 2,
        (start.dy + end.dy) / 2,
      );

      if (rect.contains(start) || rect.contains(end) || rect.contains(center)) {
        result.add(wall.id);
      }
    }

    return result;
  }

  _WallLengthLabelHit? _hitTestWallLengthLabel(Offset point) {
    _WallLengthLabelHit? best;
    double bestDistance = double.infinity;

    for (final wall in widget.document.walls) {
      final rect = _wallLengthLabelRect(wall);

      if (!rect.contains(point)) continue;

      final center = rect.center;
      final distance = (point - center).distance;

      if (distance < bestDistance) {
        best = _WallLengthLabelHit(
          wallId: wall.id,
          wall: wall,
        );
        bestDistance = distance;
      }
    }

    return best;
  }

  Rect _wallLengthLabelRect(FloorWall wall) {
    final lengthM = wall.lengthM(widget.document.scale.pixelsPerMeter);
    final text = '${lengthM.toStringAsFixed(2)} m';

    final labelCenter = _wallLengthLabelCanvasPosition(wall);

    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final topLeft = labelCenter - Offset(
      painter.width / 2,
      painter.height / 2,
    );

    final rect = topLeft & Size(
      painter.width,
      painter.height,
    );

    return rect.inflate(10 / _currentScale);
  }

  _WallHandleHit? _hitTestHandle(Offset point) {
    final threshold = 16 / _currentScale;

    _WallHandleHit? best;
    double bestDistance = double.infinity;

    for (final wall in widget.document.walls) {
      final start = wall.start.toOffset();
      final end = wall.end.toOffset();

      final startDistance = (start - point).distance;
      if (startDistance <= threshold && startDistance < bestDistance) {
        best = _WallHandleHit(
          wallId: wall.id,
          kind: _WallHandleKind.start,
          point: start,
        );
        bestDistance = startDistance;
      }

      final endDistance = (end - point).distance;
      if (endDistance <= threshold && endDistance < bestDistance) {
        best = _WallHandleHit(
          wallId: wall.id,
          kind: _WallHandleKind.end,
          point: end,
        );
        bestDistance = endDistance;
      }
    }

    return best;
  }

  List<_WallHandleHit> _findConnectedHandles(Offset point) {
    const epsilon = 2.0;
    final result = <_WallHandleHit>[];

    for (final wall in widget.document.walls) {
      final start = wall.start.toOffset();
      final end = wall.end.toOffset();

      if ((start - point).distance <= epsilon) {
        result.add(
          _WallHandleHit(
            wallId: wall.id,
            kind: _WallHandleKind.start,
            point: start,
          ),
        );
      }

      if ((end - point).distance <= epsilon) {
        result.add(
          _WallHandleHit(
            wallId: wall.id,
            kind: _WallHandleKind.end,
            point: end,
          ),
        );
      }
    }

    return result;
  }

  FloorWall? _hitTestWall(Offset point) {
    FloorWall? best;
    double bestDistance = double.infinity;

    for (final wall in widget.document.walls) {
      final thicknessPx =
          (wall.thickness / 100.0) * widget.document.scale.pixelsPerMeter;

      final threshold = math.max(
        18 / _currentScale,
        (thicknessPx / 2) + (12 / _currentScale),
      );

      final distance = _distanceToSegment(
        point,
        wall.start.toOffset(),
        wall.end.toOffset(),
      );

      if (distance <= threshold && distance < bestDistance) {
        best = wall;
        bestDistance = distance;
      }
    }

    return best;
  }

  _OpeningHit? _hitTestOpening(Offset point) {
    final threshold = 18 / _currentScale;

    _OpeningHit? best;
    double bestDistance = double.infinity;

    void check({
      required List<Map<String, dynamic>> items,
      required _SelectedObjectType type,
    }) {
      for (final item in items) {
        final wallId = item['wall_id']?.toString();
        final id = item['id']?.toString();

        if (wallId == null || id == null) continue;

        final wall = _findWallById(wallId);
        if (wall == null) continue;

        final center = _openingCenter(item, wall);
        if (center == null) continue;

        final distance = (point - center).distance;

        if (distance <= threshold && distance < bestDistance) {
          best = _OpeningHit(
            type: type,
            id: id,
            wallId: wallId,
          );
          bestDistance = distance;
        }
      }
    }

    check(
      items: widget.document.doors,
      type: _SelectedObjectType.door,
    );

    check(
      items: widget.document.windows,
      type: _SelectedObjectType.window,
    );

    return best;
  }

  Offset? _openingCenter(Map<String, dynamic> item, FloorWall wall) {
    final start = wall.start.toOffset();
    final end = wall.end.toOffset();
    final vector = end - start;

    final position = (item['position'] as num?)?.toDouble() ?? 0.5;

    return Offset(
      start.dx + vector.dx * position,
      start.dy + vector.dy * position,
    );
  }
}

extension _FloorPlanCanvasSelectionExtra on _FloorPlanCanvasState {
  FloorRoom? get _selectedRoom {
    final selected = _selectedObject;
    if (selected == null || !selected.isRoom) return null;

    for (final room in widget.document.rooms) {
      if (room.id == selected.id) return room;
    }

    return null;
  }

  FloorRoom? get _editingRoom {
    final id = _editingRoomId;
    if (id == null) return null;

    for (final room in widget.document.rooms) {
      if (room.id == id) return room;
    }

    return null;
  }

  FloorPlanAsset? get _selectedAsset {
    final selected = _selectedObject;
    if (selected == null || !selected.isAsset) return null;

    for (final asset in widget.document.assets) {
      if (asset.id == selected.id) return asset;
    }

    return null;
  }

  _CornerAngleLabelHit? _hitTestCornerAngleLabel(Offset point) {
    final labels = _buildCornerAngleLabels(widget.document);

    for (final label in labels) {
      if (label.labelRect.inflate(8 / _currentScale).contains(point)) {
        return label;
      }
    }

    return null;
  }

  _RoomLabelHit? _hitTestRoomLabel(Offset point) {
    for (final room in widget.document.rooms) {
      final rect = _roomLabelRect(room);

      if (rect.contains(point)) {
        return _RoomLabelHit(
          roomId: room.id,
          room: room,
        );
      }
    }

    return null;
  }

  FloorRoom? _hitTestRoomBody(Offset point) {
    FloorRoom? best;
    double bestArea = double.infinity;

    for (final room in widget.document.rooms) {
      final polygon = room.offsets;
      if (!_pointInPolygon(point, polygon)) continue;

      final area = room.areaM2(widget.document.scale.pixelsPerMeter);

      if (area < bestArea) {
        best = room;
        bestArea = area;
      }
    }

    return best;
  }

  Rect _roomLabelRect(FloorRoom room) {
    final area = room.areaM2(widget.document.scale.pixelsPerMeter);
    final text = '${room.name}\n${_formatAreaLabel(area)}';

    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    final center = _roomLabelCanvasPosition(room);

    return Rect.fromCenter(
      center: center,
      width: painter.width + 22,
      height: painter.height + 16,
    ).inflate(8 / _currentScale);
  }

  _AssetHit? _hitTestAsset(Offset point) {
    for (final asset in widget.document.assets.reversed) {
      final rect = _assetCanvasRect(asset).inflate(8 / _currentScale);

      if (rect.contains(point)) {
        return _AssetHit(
          assetId: asset.id,
          asset: asset,
        );
      }
    }

    return null;
  }
}