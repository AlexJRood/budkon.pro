part of 'floor_plan_canvas.dart';

extension _FloorPlanCanvasClipboard on _FloorPlanCanvasState {
  void _copySelectionToClipboard() {
    final data = _buildClipboardDataFromSelection();

    if (data == null || data.isEmpty) {
      _showCanvasSnack('nothing_to_copy'.tr);
      return;
    }

    setState(() {
      _clipboard = data;
      _pasteSerial = 0;
    });

    _showCanvasSnack('selection_copied'.tr);
  }

  void _duplicateSelection() {
    final data = _buildClipboardDataFromSelection();

    if (data == null || data.isEmpty) {
      _showCanvasSnack('nothing_to_duplicate'.tr);
      return;
    }

    setState(() {
      _clipboard = data;
    });

    _pasteClipboard();
  }

  void _pasteClipboard() {
    final data = _clipboard;

    if (data == null || data.isEmpty) {
      _showCanvasSnack('clipboard_empty'.tr);
      return;
    }

    final offset = Offset(
      48 + (_pasteSerial * 24),
      48 + (_pasteSerial * 24),
    );

    _pasteSerial += 1;

    final result = _cloneClipboardData(
      data: data,
      transformPoint: (point) => point + offset,
      transformRotation: (rotation) => rotation,
      mapDoorSwing: (value) => value,
      openingPositionMapper: (position) => position,
    );

    _commitDocument(
      widget.document.copyWith(
        walls: [
          ...widget.document.walls,
          ...result.walls,
        ],
        doors: [
          ...widget.document.doors,
          ...result.doors,
        ],
        windows: [
          ...widget.document.windows,
          ...result.windows,
        ],
        rooms: [
          ...widget.document.rooms,
          ...result.rooms,
        ],
        assets: [
          ...widget.document.assets,
          ...result.assets,
        ],
      ),
    );

    setState(() {
      _selectedWallIds = result.walls.map((wall) => wall.id).toSet();
      _selectedVertex = null;
      _selectedVertexKeys.clear();

      if (result.walls.isNotEmpty) {
        _selectedObject = _SelectedObject(
          type: _SelectedObjectType.wall,
          id: result.walls.first.id,
        );
      } else if (result.assets.isNotEmpty) {
        _selectedObject = _SelectedObject(
          type: _SelectedObjectType.asset,
          id: result.assets.first.id,
        );
      } else if (result.rooms.isNotEmpty) {
        _selectedObject = _SelectedObject(
          type: _SelectedObjectType.room,
          id: result.rooms.first.id,
        );
      } else if (result.doors.isNotEmpty) {
        _selectedObject = _SelectedObject(
          type: _SelectedObjectType.door,
          id: result.doors.first['id'].toString(),
        );
      } else if (result.windows.isNotEmpty) {
        _selectedObject = _SelectedObject(
          type: _SelectedObjectType.window,
          id: result.windows.first['id'].toString(),
        );
      } else {
        _selectedObject = null;
      }
    });

    _emitLiveSelectionChanged();
    _showCanvasSnack('selection_pasted'.tr);
  }

  void _mirrorSelection({
    required FloorPlanMirrorAxis axis,
  }) {
    final data = _buildClipboardDataFromSelection();

    if (data == null || data.isEmpty) {
      _showCanvasSnack('nothing_to_mirror'.tr);
      return;
    }

    final bounds = _clipboardBounds(data);
    if (bounds == null) {
      _showCanvasSnack('failed_to_calculate_mirror_bounds'.tr);
      return;
    }

    const gap = 80.0;

    final axisX = bounds.right + gap / 2;
    final axisY = bounds.bottom + gap / 2;

    Offset transformPoint(Offset point) {
      switch (axis) {
        case FloorPlanMirrorAxis.vertical:
          return Offset(
            axisX - (point.dx - axisX),
            point.dy,
          );

        case FloorPlanMirrorAxis.horizontal:
          return Offset(
            point.dx,
            axisY - (point.dy - axisY),
          );
      }
    }

    double transformRotation(double rotation) {
      switch (axis) {
        case FloorPlanMirrorAxis.vertical:
          return _normalizeAngleDegrees(180 - rotation);

        case FloorPlanMirrorAxis.horizontal:
          return _normalizeAngleDegrees(-rotation);
      }
    }

    String mapDoorSwing(String value) {
      if (value == 'left') return 'right';
      if (value == 'right') return 'left';
      return value;
    }

    final result = _cloneClipboardData(
      data: data,
      transformPoint: transformPoint,
      transformRotation: transformRotation,
      mapDoorSwing: mapDoorSwing,
      openingPositionMapper: (position) => position,
    );

    _commitDocument(
      widget.document.copyWith(
        walls: [
          ...widget.document.walls,
          ...result.walls,
        ],
        doors: [
          ...widget.document.doors,
          ...result.doors,
        ],
        windows: [
          ...widget.document.windows,
          ...result.windows,
        ],
        rooms: [
          ...widget.document.rooms,
          ...result.rooms,
        ],
        assets: [
          ...widget.document.assets,
          ...result.assets,
        ],
      ),
    );

    setState(() {
      _selectedWallIds = result.walls.map((wall) => wall.id).toSet();
      _selectedVertex = null;
      _selectedVertexKeys.clear();

      if (result.walls.isNotEmpty) {
        _selectedObject = _SelectedObject(
          type: _SelectedObjectType.wall,
          id: result.walls.first.id,
        );
      } else if (result.rooms.isNotEmpty) {
        _selectedObject = _SelectedObject(
          type: _SelectedObjectType.room,
          id: result.rooms.first.id,
        );
      } else if (result.assets.isNotEmpty) {
        _selectedObject = _SelectedObject(
          type: _SelectedObjectType.asset,
          id: result.assets.first.id,
        );
      } else {
        _selectedObject = null;
      }
    });

    _emitLiveSelectionChanged();

    _showCanvasSnack(
      axis == FloorPlanMirrorAxis.vertical
          ? 'vertical_mirror_created'.tr
          : 'horizontal_mirror_created'.tr,
    );
  }

  _FloorPlanClipboardData? _buildClipboardDataFromSelection() {
    final selected = _selectedObject;

    final wallIds = <String>{};

    if (_selectedWallIds.isNotEmpty) {
      wallIds.addAll(_selectedWallIds);
    }

    if (selected?.isWall == true) {
      wallIds.add(selected!.id);
    }

    if (_selectedVertexKeys.isNotEmpty) {
      for (final wall in widget.document.walls) {
        final startKey = _vertexSelectionKey(wall.start.toOffset());
        final endKey = _vertexSelectionKey(wall.end.toOffset());

        if (_selectedVertexKeys.contains(startKey) ||
            _selectedVertexKeys.contains(endKey)) {
          wallIds.add(wall.id);
        }
      }
    }

    final walls = widget.document.walls
        .where((wall) => wallIds.contains(wall.id))
        .toList();

    final doors = widget.document.doors.where((door) {
      final id = door['id']?.toString();
      final wallId = door['wall_id']?.toString();

      if (selected?.isDoor == true && selected?.id == id) return true;
      return wallId != null && wallIds.contains(wallId);
    }).map((item) {
      return Map<String, dynamic>.from(item);
    }).toList();

    final windows = widget.document.windows.where((window) {
      final id = window['id']?.toString();
      final wallId = window['wall_id']?.toString();

      if (selected?.isWindow == true && selected?.id == id) return true;
      return wallId != null && wallIds.contains(wallId);
    }).map((item) {
      return Map<String, dynamic>.from(item);
    }).toList();

    final rooms = widget.document.rooms.where((room) {
      return selected?.isRoom == true && selected?.id == room.id;
    }).toList();

    final assets = widget.document.assets.where((asset) {
      return selected?.isAsset == true && selected?.id == asset.id;
    }).toList();

    return _FloorPlanClipboardData(
      walls: walls,
      doors: doors,
      windows: windows,
      rooms: rooms,
      assets: assets,
    );
  }

  _FloorPlanClipboardData _cloneClipboardData({
    required _FloorPlanClipboardData data,
    required Offset Function(Offset point) transformPoint,
    required double Function(double rotation) transformRotation,
    required String Function(String value) mapDoorSwing,
    required double Function(double position) openingPositionMapper,
  }) {
    final suffix = DateTime.now().microsecondsSinceEpoch;

    final wallIdMap = <String, String>{};

    for (var i = 0; i < data.walls.length; i++) {
      wallIdMap[data.walls[i].id] = 'wall_${suffix}_$i';
    }

    final clonedWalls = <FloorWall>[];

    for (final wall in data.walls) {
      final newId = wallIdMap[wall.id] ?? 'wall_${suffix}_${clonedWalls.length}';

      clonedWalls.add(
        FloorWall(
          id: newId,
          start: FloorPoint.fromOffset(
            transformPoint(wall.start.toOffset()),
          ),
          end: FloorPoint.fromOffset(
            transformPoint(wall.end.toOffset()),
          ),
          thickness: wall.thickness,
          heightM: wall.heightM,
          material: wall.material,
          kind: wall.wallKind.key,
          angleLocked: wall.angleLocked,
          lockedAngleDeg: wall.lockedAngleDeg == null
              ? null
              : transformRotation(wall.lockedAngleDeg!),
          lengthLocked: wall.lengthLocked,
          lockedLengthM: wall.lockedLengthM,
        ),
      );
    }

    final clonedDoors = <Map<String, dynamic>>[];

    for (var i = 0; i < data.doors.length; i++) {
      final door = data.doors[i];
      final oldWallId = door['wall_id']?.toString();
      final mappedWallId = oldWallId == null ? null : wallIdMap[oldWallId];

      final swingDirection = door['swing_direction']?.toString();

      clonedDoors.add({
        ...door,
        'id': 'door_${suffix}_$i',
        if (mappedWallId != null) 'wall_id': mappedWallId,
        'position': openingPositionMapper(
          (door['position'] as num?)?.toDouble() ?? 0.5,
        ).clamp(0.0, 1.0),
        if (swingDirection != null)
          'swing_direction': mapDoorSwing(swingDirection),
      });
    }

    final clonedWindows = <Map<String, dynamic>>[];

    for (var i = 0; i < data.windows.length; i++) {
      final window = data.windows[i];
      final oldWallId = window['wall_id']?.toString();
      final mappedWallId = oldWallId == null ? null : wallIdMap[oldWallId];

      clonedWindows.add({
        ...window,
        'id': 'window_${suffix}_$i',
        if (mappedWallId != null) 'wall_id': mappedWallId,
        'position': openingPositionMapper(
          (window['position'] as num?)?.toDouble() ?? 0.5,
        ).clamp(0.0, 1.0),
      });
    }

    final clonedRooms = <FloorRoom>[];

    for (var i = 0; i < data.rooms.length; i++) {
      final room = data.rooms[i];

      clonedRooms.add(
        FloorRoom(
          id: 'room_${suffix}_$i',
          name: '${room.name} kopia',
          points: room.points
              .map((point) => FloorPoint.fromOffset(
                    transformPoint(point.toOffset()),
                  ))
              .toList(),
          colorHex: room.colorHex,
          showName: room.showName,
          showArea: room.showArea,
        ),
      );
    }

    final clonedAssets = <FloorPlanAsset>[];

    for (var i = 0; i < data.assets.length; i++) {
      final asset = data.assets[i];

      clonedAssets.add(
        FloorPlanAsset(
          id: 'asset_${suffix}_$i',
          type: asset.type,
          position: FloorPoint.fromOffset(
            transformPoint(asset.position.toOffset()),
          ),
          widthM: asset.widthM,
          depthM: asset.depthM,
          rotationDeg: transformRotation(asset.rotationDeg),
          label: asset.label,
        ),
      );
    }

    return _FloorPlanClipboardData(
      walls: clonedWalls,
      doors: clonedDoors,
      windows: clonedWindows,
      rooms: clonedRooms,
      assets: clonedAssets,
    );
  }

  Rect? _clipboardBounds(_FloorPlanClipboardData data) {
    final points = <Offset>[];

    for (final wall in data.walls) {
      points.add(wall.start.toOffset());
      points.add(wall.end.toOffset());
    }

    for (final room in data.rooms) {
      points.addAll(room.points.map((point) => point.toOffset()));
    }

    for (final asset in data.assets) {
      points.add(asset.position.toOffset());
    }

    for (final door in data.doors) {
      final wallId = door['wall_id']?.toString();
      if (wallId == null) continue;

      final wall = data.walls.where((item) => item.id == wallId).firstOrNull;
      if (wall == null) continue;

      final center = _openingCenter(door, wall);
      if (center != null) points.add(center);
    }

    for (final window in data.windows) {
      final wallId = window['wall_id']?.toString();
      if (wallId == null) continue;

      final wall = data.walls.where((item) => item.id == wallId).firstOrNull;
      if (wall == null) continue;

      final center = _openingCenter(window, wall);
      if (center != null) points.add(center);
    }

    if (points.isEmpty) return null;

    var minX = points.first.dx;
    var maxX = points.first.dx;
    var minY = points.first.dy;
    var maxY = points.first.dy;

    for (final point in points.skip(1)) {
      minX = math.min(minX, point.dx);
      maxX = math.max(maxX, point.dx);
      minY = math.min(minY, point.dy);
      maxY = math.max(maxY, point.dy);
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  void _showCanvasSnack(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 1400),
      ),
    );
  }
}