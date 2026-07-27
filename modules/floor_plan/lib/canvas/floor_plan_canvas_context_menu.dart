part of 'floor_plan_canvas.dart';

class _PieMenuAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;
  final bool primary;

  const _PieMenuAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
    this.primary = false,
  });
}

extension _FloorPlanCanvasContextMenu on _FloorPlanCanvasState {
  bool _isSecondaryPointerDown(PointerDownEvent event) {
    return (event.buttons & kSecondaryMouseButton) != 0;
  }

  void _hideContextMenu() {
    _contextMenuEntry?.remove();
    _contextMenuEntry?.dispose();
    _contextMenuEntry = null;
  }

  /// True while some drag/box-select/hold-decision is already under way, in
  /// which case a long-press firing on top of it would rip the selection out
  /// from under an in-progress gesture (e.g. dragging a vertex) and pop the
  /// pie menu instead of letting the drag continue.
  bool get _isInteractionActiveForLongPress {
    return _isDraggingVertexGroup ||
        _isDraggingHandle ||
        _isDraggingWall ||
        _isDraggingOpening ||
        _isDraggingAsset ||
        _isResizingOpening ||
        _isBoxSelecting ||
        _isMiddleMousePanning ||
        _isTouchHoldPending;
  }

  void _showContextMenuForLongPress(LongPressStartDetails details) {
    if (_isInteractionActiveForLongPress) return;

    _hideContextMenu();
    _requestFocus();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _showContextMenuAt(
        globalPosition: details.globalPosition,
        canvasPoint: _toCanvasPosition(details.globalPosition),
      );
    });
  }

  void _queueContextMenuForPointer(PointerDownEvent event) {
    _hideContextMenu();
    _requestFocus();

    _queuedContextMenuOpen = true;
    _queuedContextMenuGlobalPosition = event.position;
    _queuedContextMenuCanvasPoint = _toCanvasPosition(event.position);
  }

  void _cancelQueuedContextMenu() {
    _queuedContextMenuOpen = false;
    _queuedContextMenuGlobalPosition = null;
    _queuedContextMenuCanvasPoint = null;
  }

  bool _consumeQueuedContextMenu() {
    if (!_queuedContextMenuOpen) return false;

    final globalPosition = _queuedContextMenuGlobalPosition;
    final canvasPoint = _queuedContextMenuCanvasPoint;

    _cancelQueuedContextMenu();

    if (globalPosition == null || canvasPoint == null) {
      return true;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _showContextMenuAt(
        globalPosition: globalPosition,
        canvasPoint: canvasPoint,
      );
    });

    return true;
  }

  void _showContextMenuAt({
    required Offset globalPosition,
    required Offset canvasPoint,
  }) {
    _hideContextMenu();
    _requestFocus();

    final isDrawing =
        (_tool == FloorPlanTool.wall || _tool == FloorPlanTool.virtualWall) &&
            _wallStart != null;

    _OpeningHit? opening;
    FloorWall? wall;
    FloorRoom? room;
    _AssetHit? asset;

    if (!isDrawing) {
      opening = _hitTestOpening(canvasPoint);

      if (opening != null) {
        setState(() {
          _selectedVertex = null;
          _selectedVertexKeys.clear();
          _selectedWallIds.clear();
          _selectedObject = _SelectedObject(
            type: opening!.type,
            id: opening.id,
          );
        });
      } else {
        asset = _hitTestAsset(canvasPoint);

        if (asset != null) {
          setState(() {
            _selectedVertex = null;
            _selectedVertexKeys.clear();
            _selectedWallIds.clear();
            _selectedObject = _SelectedObject(
              type: _SelectedObjectType.asset,
              id: asset!.assetId,
            );
          });
        } else {
          room = _hitTestRoomBody(canvasPoint);

          if (room != null) {
            setState(() {
              _selectedVertex = null;
              _selectedVertexKeys.clear();
              _selectedWallIds.clear();
              _selectedObject = _SelectedObject(
                type: _SelectedObjectType.room,
                id: room!.id,
              );
            });
          } else {
            wall = _hitTestWall(canvasPoint);

            if (wall != null) {
              final hitWall = wall;

              setState(() {
                _selectedVertex = null;
                _selectedVertexKeys.clear();
                _selectedWallIds = {hitWall!.id};
                _selectedObject = _SelectedObject(
                  type: _SelectedObjectType.wall,
                  id: hitWall.id,
                );
              });
            }
          }
        }
      }
    }

    final actions = _buildContextMenuActions(
      wall: wall,
      opening: opening,
      room: room,
      asset: asset,
      canvasPoint: canvasPoint,
    );

    if (actions.isEmpty) return;

    final overlay = Overlay.of(context);
    const menuSize = _FloorPlanPieMenu.size;

    _contextMenuEntry = OverlayEntry(
      builder: (overlayContext) {
        final screenSize = MediaQuery.sizeOf(overlayContext);

        final left = (globalPosition.dx - menuSize / 2)
            .clamp(
              8.0,
              math.max(8.0, screenSize.width - menuSize - 8),
            )
            .toDouble();

        final top = (globalPosition.dy - menuSize / 2)
            .clamp(
              8.0,
              math.max(8.0, screenSize.height - menuSize - 8),
            )
            .toDouble();

        return Stack(
          children: [
            Positioned.fill(
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (_) => _hideContextMenu(),
                child: const SizedBox.expand(),
              ),
            ),
            Positioned(
              left: left,
              top: top,
              child: _FloorPlanPieMenu(
                actions: actions,
                onClose: _hideContextMenu,
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(_contextMenuEntry!);
  }


  List<_PieMenuAction> _buildContextMenuActions({
    required FloorWall? wall,
    required _OpeningHit? opening,
    required FloorRoom? room,
    required _AssetHit? asset,
    required Offset canvasPoint,
  }) {
    final selectedWall = _selectedWall;
    final selectedDoor = _selectedDoor;
    final selectedWindow = _selectedWindow;
    final selectedRoom = _selectedRoom;
    final selectedAsset = _selectedAsset;

    final isDrawing = (_tool == FloorPlanTool.wall ||
            _tool == FloorPlanTool.virtualWall) &&
        _wallStart != null;

    if (isDrawing) {
      return [
        _PieMenuAction(
          icon: Icons.check,
          label: 'finish_action'.tr,
          primary: true,
          onTap: _cancelCurrentDrawing,
        ),
        _PieMenuAction(
          icon: _angleLockEnabled
              ? Icons.grid_goldenratio
              : Icons.grid_off_outlined,
          label: _angleLockEnabled ? 'snap_off'.tr : 'snap_on'.tr,
          onTap: () {
            setState(() {
              _angleLockEnabled = !_angleLockEnabled;
            });
          },
        ),
        _PieMenuAction(
          icon: _smartGuidesEnabled
              ? Icons.auto_fix_high
              : Icons.auto_fix_off_outlined,
          label: _smartGuidesEnabled ? 'guides_off'.tr : 'guides_on'.tr,
          onTap: () {
            setState(() {
              _smartGuidesEnabled = !_smartGuidesEnabled;

              if (!_smartGuidesEnabled) {
                _activeGuideSnap = null;
              }
            });
          },
        ),
        _PieMenuAction(
          icon: Icons.undo,
          label: 'undo_action'.tr,
          onTap: _undo,
        ),
        _PieMenuAction(
          icon: Icons.zoom_in,
          label: 'zoom_in_action'.tr,
          onTap: _zoomViewIn,
        ),
        _PieMenuAction(
          icon: Icons.zoom_out,
          label: 'zoom_out_action'.tr,
          onTap: _zoomViewOut,
        ),
        _PieMenuAction(
          icon: Icons.close,
          label: 'cancel_action'.tr,
          destructive: true,
          onTap: _cancelCurrentDrawing,
        ),
      ];
    }

    if (selectedWall != null) {
      final isVirtual = _wallKindOf(selectedWall) == 'virtual';
      final isBearing = _wallKindOf(selectedWall) == 'load_bearing';

      return [
        _PieMenuAction(
          icon: Icons.meeting_room_outlined,
          label: 'door_action'.tr,
          primary: true,
          onTap: _addDoorToSelectedWallCenter,
        ),
        _PieMenuAction(
          icon: Icons.window_outlined,
          label: 'window_action'.tr,
          onTap: _addWindowToSelectedWallCenter,
        ),
        _PieMenuAction(
          icon: Icons.garage_outlined,
          label: 'garage_door_action'.tr,
          onTap: () {
            _addGarageDoor(
              wall: selectedWall,
              position: 0.5,
            );
          },
        ),
        _PieMenuAction(
          icon: isBearing ? Icons.home_work : Icons.foundation_outlined,
          label: isBearing ? 'partition_wall_action'.tr : 'load_bearing_wall_action'.tr,
          onTap: () {
            _setSelectedWallsKind(
              isBearing ? 'partition' : 'load_bearing',
            );
          },
        ),
        _PieMenuAction(
          icon: isVirtual ? Icons.sanitizer : Icons.border_style,
          label: isVirtual ? 'normal_wall_action'.tr : 'virtual_wall_action'.tr,
          onTap: () {
            _setSelectedWallsKind(
              isVirtual ? 'partition' : 'virtual',
            );
          },
        ),
        _PieMenuAction(
          icon: selectedWall.angleLocked
              ? Icons.lock_open_outlined
              : Icons.screen_rotation_alt_outlined,
          label: selectedWall.angleLocked ? 'unlock_angle_action'.tr : 'lock_angle_action'.tr,
          onTap: () {
            _toggleSelectedWallAngleLock(!selectedWall.angleLocked);
          },
        ),
        _PieMenuAction(
          icon: selectedWall.lengthLocked
              ? Icons.lock_open_outlined
              : Icons.straighten,
          label: selectedWall.lengthLocked ? 'unlock_length_action'.tr : 'lock_length_action'.tr,
          onTap: () {
            _toggleSelectedWallLengthLock(!selectedWall.lengthLocked);
          },
        ),
        _PieMenuAction(
          icon: Icons.flip,
          label: 'mirror_x_action'.tr,
          onTap: () {
            _mirrorSelectedWalls(horizontal: true);
          },
        ),
        _PieMenuAction(
          icon: Icons.flip_camera_android,
          label: 'mirror_y_action'.tr,
          onTap: () {
            _mirrorSelectedWalls(horizontal: false);
          },
        ),
        _PieMenuAction(
          icon: Icons.delete_outline,
          label: 'delete_action'.tr,
          destructive: true,
          onTap: _deleteSelectedObject,
        ),
      ];
    }

    if (selectedDoor != null) {
      final type = selectedDoor['type']?.toString() ?? 'single';
      final isGarageDoor = type == 'garage_door';

      return [
        _PieMenuAction(
          icon: Icons.center_focus_strong,
          label: 'center_action'.tr,
          primary: true,
          onTap: _centerSelectedDoor,
        ),
        if (!isGarageDoor)
          _PieMenuAction(
            icon: Icons.swap_horiz,
            label: 'left_right_action'.tr,
            onTap: () {
              final current =
                  selectedDoor['swing_direction']?.toString() ?? 'left';

              _updateSelectedDoor({
                ...selectedDoor,
                'swing_direction': current == 'left' ? 'right' : 'left',
              });
            },
          ),
        if (!isGarageDoor)
          _PieMenuAction(
            icon: Icons.door_sliding_outlined,
            label: type == 'sliding' ? 'classic_door_action'.tr : 'sliding_door_action'.tr,
            onTap: () {
              _updateSelectedDoor({
                ...selectedDoor,
                'type': type == 'sliding' ? 'single' : 'sliding',
              });
            },
          ),
        _PieMenuAction(
          icon: Icons.delete_outline,
          label: 'delete_action'.tr,
          destructive: true,
          onTap: _deleteSelectedObject,
        ),
      ];
    }

    if (selectedWindow != null) {
      final type = selectedWindow['type']?.toString() ?? 'standard';

      return [
        _PieMenuAction(
          icon: Icons.center_focus_strong,
          label: 'center_action'.tr,
          primary: true,
          onTap: _centerSelectedWindow,
        ),
        _PieMenuAction(
          icon: Icons.balcony_outlined,
          label: type == 'balcony' ? 'standard_window_action'.tr : 'balcony_window_action'.tr,
          onTap: () {
            _updateSelectedWindow({
              ...selectedWindow,
              'type': type == 'balcony' ? 'standard' : 'balcony',
            });
          },
        ),
        _PieMenuAction(
          icon: Icons.crop_square,
          label: type == 'corner' ? 'standard_window_action'.tr : 'corner_window_action'.tr,
          onTap: () {
            _updateSelectedWindow({
              ...selectedWindow,
              'type': type == 'corner' ? 'standard' : 'corner',
            });
          },
        ),
        _PieMenuAction(
          icon: Icons.delete_outline,
          label: 'delete_action'.tr,
          destructive: true,
          onTap: _deleteSelectedObject,
        ),
      ];
    }

    if (selectedRoom != null) {
      return [
        _PieMenuAction(
          icon: Icons.edit_outlined,
          label: 'name_action'.tr,
          primary: true,
          onTap: () {
            _showRoomNameEditor(selectedRoom);
          },
        ),
        _PieMenuAction(
          icon: Icons.label_outline,
          label: selectedRoom.showName ? 'hide_name_action'.tr : 'show_name_action'.tr,
          onTap: () {
            _toggleRoomNameVisibility(selectedRoom);
          },
        ),
        _PieMenuAction(
          icon: Icons.square_foot_outlined,
          label: selectedRoom.showArea ? 'hide_area_action'.tr : 'show_area_action'.tr,
          onTap: () {
            _toggleRoomAreaVisibility(selectedRoom);
          },
        ),
        _PieMenuAction(
          icon: Icons.delete_outline,
          label: 'delete_action'.tr,
          destructive: true,
          onTap: _deleteSelectedObject,
        ),
      ];
    }

    if (selectedAsset != null) {
      return [
        _PieMenuAction(
          icon: Icons.align_horizontal_left_outlined,
          label: 'align_to_wall_action'.tr,
          primary: true,
          onTap: _alignSelectedAssetToNearestWall,
        ),
        _PieMenuAction(
          icon: Icons.rotate_left,
          label: 'rotate_minus_action'.tr,
          onTap: () {
            _rotateSelectedAssetBy(selectedAsset, -15);
          },
        ),
        _PieMenuAction(
          icon: Icons.rotate_right,
          label: 'rotate_plus_action'.tr,
          onTap: () {
            _rotateSelectedAssetBy(selectedAsset, 15);
          },
        ),
        _PieMenuAction(
          icon: Icons.delete_outline,
          label: 'delete_action'.tr,
          destructive: true,
          onTap: _deleteSelectedObject,
        ),
      ];
    }

    return [
      _PieMenuAction(
        icon: Icons.show_chart,
        label: 'wall_action'.tr,
        primary: true,
        onTap: () {
          _startWallDrawingAt(canvasPoint, isVirtual: false);
        },
      ),
      _PieMenuAction(
        icon: Icons.border_style,
        label: 'virtual_wall_action'.tr,
        onTap: () {
          _startWallDrawingAt(canvasPoint, isVirtual: true);
        },
      ),
      _PieMenuAction(
        icon: Icons.crop_square,
        label: 'room_action'.tr,
        onTap: () {
          setState(() {
            _tool = FloorPlanTool.room;
          });
          _createRoomFromPoint(canvasPoint);
        },
      ),
      _PieMenuAction(
        icon: Icons.weekend_outlined,
        label: 'asset_action'.tr,
        onTap: () {
          setState(() {
            _tool = FloorPlanTool.asset;
          });
          _addAssetAtPoint(canvasPoint);
        },
      ),
      _PieMenuAction(
        icon: _angleLockEnabled
            ? Icons.grid_goldenratio
            : Icons.grid_off_outlined,
        label: _angleLockEnabled ? 'snap_off'.tr : 'snap_on'.tr,
        onTap: () {
          setState(() {
            _angleLockEnabled = !_angleLockEnabled;
          });
        },
      ),
      _PieMenuAction(
        icon: _smartGuidesEnabled
            ? Icons.auto_fix_high
            : Icons.auto_fix_off_outlined,
        label: _smartGuidesEnabled ? 'guides_off'.tr : 'guides_on'.tr,
        onTap: () {
          setState(() {
            _smartGuidesEnabled = !_smartGuidesEnabled;

            if (!_smartGuidesEnabled) {
              _activeGuideSnap = null;
            }
          });
        },
      ),
      _PieMenuAction(
        icon: Icons.zoom_in,
        label: 'zoom_in_action'.tr,
        onTap: _zoomViewIn,
      ),
      _PieMenuAction(
        icon: Icons.zoom_out,
        label: 'zoom_out_action'.tr,
        onTap: _zoomViewOut,
      ),
      _PieMenuAction(
        icon: Icons.rotate_left,
        label: 'rotate_minus_action'.tr,
        onTap: _rotateViewLeft,
      ),
      _PieMenuAction(
        icon: Icons.rotate_right,
        label: 'rotate_plus_action'.tr,
        onTap: _rotateViewRight,
      ),
      _PieMenuAction(
        icon: Icons.fit_screen_outlined,
        label: 'reset_action'.tr,
        onTap: _resetViewTransform,
      ),
    ];
  }

  String _wallKindOf(FloorWall wall) {
    if (wall.isVirtual) return 'virtual';

    final kind = wall.kind.trim().toLowerCase();

    if (kind == 'virtual' ||
        kind == 'virtual_wall' ||
        kind == 'fictional' ||
        kind == 'fake' ||
        kind == 'divider') {
      return 'virtual';
    }

    if (kind == 'load_bearing' ||
        kind == 'bearing' ||
        kind == 'structural' ||
        kind == 'carrier' ||
        kind == 'nosna' ||
        kind == 'nośna') {
      return 'load_bearing';
    }

    return 'partition';
  }

  void _setSelectedWallsKind(String kind) {
    final selected = _selectedObject;

    final ids = _selectedWallIds.isNotEmpty
        ? Set<String>.from(_selectedWallIds)
        : selected != null && selected.isWall
            ? <String>{selected.id}
            : <String>{};

    if (ids.isEmpty) return;

    final updatedWalls = widget.document.walls.map((wall) {
      if (!ids.contains(wall.id)) return wall;

      return _copyWallWith(
        wall,
        kind: kind,
      );
    }).toList();

    _commitDocument(
      widget.document.copyWith(
        walls: updatedWalls,
      ),
    );

    setState(() {
      _selectedWallIds = ids;
      _selectedObject = _SelectedObject(
        type: _SelectedObjectType.wall,
        id: ids.first,
      );
      _selectedVertex = null;
      _selectedVertexKeys.clear();
    });
  }

  void _mirrorSelectedWalls({
    required bool horizontal,
  }) {
    final selected = _selectedObject;

    final ids = _selectedWallIds.isNotEmpty
        ? Set<String>.from(_selectedWallIds)
        : selected != null && selected.isWall
            ? <String>{selected.id}
            : <String>{};

    if (ids.isEmpty) return;

    final selectedWalls =
        widget.document.walls.where((wall) => ids.contains(wall.id)).toList();

    if (selectedWalls.isEmpty) return;

    final allPoints = <Offset>[];

    for (final wall in selectedWalls) {
      allPoints.add(wall.start.toOffset());
      allPoints.add(wall.end.toOffset());
    }

    final bounds = _boundsForPoints(allPoints);
    final center = bounds.center;

    Offset mirrorPoint(Offset point) {
      if (horizontal) {
        return Offset(
          center.dx + (center.dx - point.dx),
          point.dy,
        );
      }

      return Offset(
        point.dx,
        center.dy + (center.dy - point.dy),
      );
    }

    final replacements = <String, Offset>{};

    for (final point in allPoints) {
      replacements[_cornerKey(point)] = mirrorPoint(point);
    }

    final updatedWalls = widget.document.walls.map((wall) {
      if (!ids.contains(wall.id)) return wall;

      return _copyWallWith(
        wall,
        start: FloorPoint.fromOffset(mirrorPoint(wall.start.toOffset())),
        end: FloorPoint.fromOffset(mirrorPoint(wall.end.toOffset())),
      );
    }).toList();

    var nextDocument = widget.document.copyWith(
      walls: updatedWalls,
    );

    nextDocument = _replaceRoomPointsByKey(
      document: nextDocument,
      replacements: replacements,
    );

    _commitDocument(nextDocument);

    setState(() {
      _selectedWallIds = ids;
      _selectedObject = _SelectedObject(
        type: _SelectedObjectType.wall,
        id: ids.first,
      );
      _selectedVertex = null;
      _selectedVertexKeys.clear();
    });
  }

  Rect _boundsForPoints(List<Offset> points) {
    if (points.isEmpty) {
      return const Rect.fromLTWH(0, 0, 1, 1);
    }

    var minX = points.first.dx;
    var minY = points.first.dy;
    var maxX = points.first.dx;
    var maxY = points.first.dy;

    for (final point in points.skip(1)) {
      minX = math.min(minX, point.dx);
      minY = math.min(minY, point.dy);
      maxX = math.max(maxX, point.dx);
      maxY = math.max(maxY, point.dy);
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  void _toggleRoomNameVisibility(FloorRoom room) {
    final rooms = widget.document.rooms.map((item) {
      if (item.id != room.id) return item;

      return FloorRoom(
        id: item.id,
        name: item.name,
        points: item.points,
        colorHex: item.colorHex,
        showName: !item.showName,
        showArea: item.showArea,
      );
    }).toList();

    _commitDocument(
      widget.document.copyWith(
        rooms: rooms,
      ),
    );
  }

  void _toggleRoomAreaVisibility(FloorRoom room) {
    final rooms = widget.document.rooms.map((item) {
      if (item.id != room.id) return item;

      return FloorRoom(
        id: item.id,
        name: item.name,
        points: item.points,
        colorHex: item.colorHex,
        showName: item.showName,
        showArea: !item.showArea,
      );
    }).toList();

    _commitDocument(
      widget.document.copyWith(
        rooms: rooms,
      ),
    );
  }

  void _rotateSelectedAssetBy(
    FloorPlanAsset asset,
    double deltaDeg,
  ) {
    final next = FloorPlanAsset(
      id: asset.id,
      type: asset.type,
      position: asset.position,
      widthM: asset.widthM,
      depthM: asset.depthM,
      rotationDeg: _normalizeAngleDegrees(asset.rotationDeg + deltaDeg),
      label: asset.label,
    );

    _updateSelectedAsset(next);
  }
}

class _FloorPlanPieMenu extends StatelessWidget {
  final List<_PieMenuAction> actions;
  final VoidCallback onClose;

  const _FloorPlanPieMenu({
    required this.actions,
    required this.onClose,
  });

  static const double size = 260;
  static const double itemWidth = 78;
  static const double itemHeight = 60;
  static const double radius = 94;

  @override
  Widget build(BuildContext context) {
    final visibleActions = actions.take(10).toList();
    final center = Offset(size / 2, size / 2);

    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: center.dx - 30,
              top: center.dy - 30,
              width: 60,
              height: 60,
              child: Material(
                elevation: 12,
                color: const Color(0xFF111827),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onClose,
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
            for (var i = 0; i < visibleActions.length; i++)
              _buildActionButton(
                action: visibleActions[i],
                index: i,
                total: visibleActions.length,
                center: center,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required _PieMenuAction action,
    required int index,
    required int total,
    required Offset center,
  }) {
    final startAngle = -math.pi / 2;
    final angle = startAngle + (2 * math.pi * index / total);

    final x = center.dx + math.cos(angle) * radius - itemWidth / 2;
    final y = center.dy + math.sin(angle) * radius - itemHeight / 2;

    final foreground = action.destructive
        ? const Color(0xFFB91C1C)
        : action.primary
            ? Colors.white
            : const Color(0xFF111827);

    final background = action.destructive
        ? const Color(0xFFFFE4E6)
        : action.primary
            ? const Color(0xFF2563EB)
            : Colors.white;

    return Positioned(
      left: x,
      top: y,
      width: itemWidth,
      height: itemHeight,
      child: Material(
        elevation: action.primary ? 12 : 8,
        color: background,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            onClose();
            action.onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  action.icon,
                  color: foreground,
                  size: 20,
                ),
                const SizedBox(height: 4),
                Text(
                  action.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}