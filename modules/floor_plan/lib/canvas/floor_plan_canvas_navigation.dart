part of 'floor_plan_canvas.dart';

extension _FloorPlanCanvasNavigation on _FloorPlanCanvasState {
  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;

    GestureBinding.instance.pointerSignalResolver.register(
      event,
      (PointerSignalEvent resolvedEvent) {
        if (resolvedEvent is! PointerScrollEvent) return;

        _handleResolvedScrollShortcut(resolvedEvent);
      },
    );
  }

  void _handleResolvedScrollShortcut(PointerScrollEvent event) {
    _requestFocus();

    final scroll = event.scrollDelta;

    final isCtrl = _isCtrlOrMetaPressed;
    final isShift = _isShiftPressed;
    final isAlt = _isAltPressed;
    final isTrackpad = event.kind == PointerDeviceKind.trackpad;

    // Alt + scroll = rotate only.
    // Important: because InteractiveViewer.scaleEnabled is false,
    // this no longer also zooms.
    if (isAlt) {
      final direction = scroll.dy >= 0 ? 1.0 : -1.0;
      final amount = isShift ? 1.0 : 3.0;

      _rotateViewBy(direction * amount);
      return;
    }

    // Shift + scroll = horizontal pan.
    if (isShift && !isCtrl) {
      final rawDelta = scroll.dx.abs() > 0.01 ? scroll.dx : scroll.dy;
      final deltaX = -rawDelta;

      _panViewportBy(Offset(deltaX, 0));
      return;
    }

    // Ctrl/Cmd + scroll = zoom to cursor (both mouse and trackpad).
    if (isCtrl) {
      final factor = math.exp(-scroll.dy * 0.0015);

      _zoomAtGlobalPosition(
        globalPosition: event.position,
        factor: factor,
      );

      return;
    }

    // Trackpad two-finger scroll without modifier = pan (natural direction).
    // PointerPanZoomUpdateEvent handles trackpad pinch separately.
    if (isTrackpad) {
      _panViewportBy(Offset(-scroll.dx, -scroll.dy));
      return;
    }

    // Mouse wheel scroll = zoom to cursor.
    final factor = math.exp(-scroll.dy * 0.0015);

    _zoomAtGlobalPosition(
      globalPosition: event.position,
      factor: factor,
    );
  }

  void _handlePointerPanZoomStart(PointerPanZoomStartEvent event) {
    _trackpadGestureScale = 1.0;
  }

  void _handlePointerPanZoomUpdate(PointerPanZoomUpdateEvent event) {
    _requestFocus();

    // Pan component: panDelta is the physical finger movement direction.
    if (event.panDelta != Offset.zero) {
      _panViewportBy(event.panDelta);
    }

    // Scale/zoom component: event.scale is cumulative from gesture start.
    if (event.scale != _trackpadGestureScale) {
      final factor = event.scale / _trackpadGestureScale;
      _zoomAtGlobalPosition(
        globalPosition: event.position,
        factor: factor,
      );
      _trackpadGestureScale = event.scale;
    }
  }

  void _handlePointerPanZoomEnd(PointerPanZoomEndEvent event) {
    _trackpadGestureScale = 1.0;
  }

  KeyEventResult? _handleNavigationKeyEvent(KeyEvent event) {
    final key = event.logicalKey;

    final isArrow = key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowDown;

    if (!isArrow) return null;

    if (_lengthEditorFocusNode.hasFocus ||
        _angleEditorFocusNode.hasFocus ||
        _roomNameEditorFocusNode.hasFocus) {
      return KeyEventResult.ignored;
    }

    if (event is KeyUpEvent) {
      _dragHistoryPushed = false;
      return KeyEventResult.handled;
    }

    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final direction = _directionForArrowKey(key);
    if (direction == Offset.zero) return KeyEventResult.ignored;

    final hasSelection = _selectedVertex != null ||
        _selectedWallIds.isNotEmpty ||
        _selectedObject != null;

    if (hasSelection) {
      final grid = widget.document.canvas.gridSize <= 0
          ? 10.0
          : widget.document.canvas.gridSize;

      final step = _isAltPressed
          ? 1.0
          : _isShiftPressed
              ? grid * 5
              : grid;

      _nudgeSelection(direction * step);
    } else {
      final step = _isAltPressed
          ? 12.0
          : _isShiftPressed
              ? 180.0
              : 60.0;

      _panViewportBy(direction * step);
    }

    return KeyEventResult.handled;
  }

  Offset _directionForArrowKey(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.arrowLeft) {
      return const Offset(-1, 0);
    }

    if (key == LogicalKeyboardKey.arrowRight) {
      return const Offset(1, 0);
    }

    if (key == LogicalKeyboardKey.arrowUp) {
      return const Offset(0, -1);
    }

    if (key == LogicalKeyboardKey.arrowDown) {
      return const Offset(0, 1);
    }

    return Offset.zero;
  }

  void _nudgeSelection(Offset canvasDelta) {
    if (canvasDelta == Offset.zero) return;

    if (_selectedVertex != null) {
      _pushDragHistoryOnce();

      final nextPoint = _selectedVertex!.point + canvasDelta;

      _moveConnectedHandlesToPoint(nextPoint);

      _selectedVertex = _selectedVertex!.copyWith(
        point: nextPoint,
      );

      return;
    }

    final selected = _selectedObject;

    if (selected?.isAsset == true) {
      final asset = _selectedAsset;
      if (asset == null) return;

      _pushDragHistoryOnce();

      final nextPosition = asset.position.toOffset() + canvasDelta;

      final updatedAsset = FloorPlanAsset(
        id: asset.id,
        type: asset.type,
        position: FloorPoint.fromOffset(nextPosition),
        widthM: asset.widthM,
        depthM: asset.depthM,
        rotationDeg: asset.rotationDeg,
        label: asset.label,
      );

      _commitDocument(
        widget.document.copyWith(
          assets: widget.document.assets.map((item) {
            if (item.id == asset.id) return updatedAsset;
            return item;
          }).toList(),
        ),
        pushHistory: false,
      );

      return;
    }

    if (selected?.isDoor == true) {
      _nudgeSelectedOpening(
        isDoor: true,
        canvasDelta: canvasDelta,
      );
      return;
    }

    if (selected?.isWindow == true) {
      _nudgeSelectedOpening(
        isDoor: false,
        canvasDelta: canvasDelta,
      );
      return;
    }

    if (_selectedWallIds.isNotEmpty) {
      _pushDragHistoryOnce();

      final selectedIds = _selectedWallIds;

      final updatedWalls = widget.document.walls.map((wall) {
        if (!selectedIds.contains(wall.id)) return wall;

        final start = wall.start.toOffset() + canvasDelta;
        final end = wall.end.toOffset() + canvasDelta;

        return _copyWallWith(
          wall,
          start: FloorPoint.fromOffset(start),
          end: FloorPoint.fromOffset(end),
        );
      }).toList();

      _commitDocument(
        widget.document.copyWith(walls: updatedWalls),
        pushHistory: false,
      );

      return;
    }
  }

  void _nudgeSelectedOpening({
    required bool isDoor,
    required Offset canvasDelta,
  }) {
    final selected = _selectedObject;
    if (selected == null) return;

    final source = isDoor ? widget.document.doors : widget.document.windows;
    final opening = _findOpeningById(selected.id, source);
    if (opening == null) return;

    final wallId = opening['wall_id']?.toString();
    if (wallId == null) return;

    final wall = _findWallById(wallId);
    if (wall == null) return;

    final start = wall.start.toOffset();
    final end = wall.end.toOffset();

    final vector = end - start;
    final wallLength = vector.distance;

    if (wallLength <= 0.001) return;

    final unit = Offset(
      vector.dx / wallLength,
      vector.dy / wallLength,
    );

    final projectedDeltaPx =
        canvasDelta.dx * unit.dx + canvasDelta.dy * unit.dy;

    final fractionDelta = projectedDeltaPx / wallLength;

    final currentPosition =
        ((opening['position'] as num?)?.toDouble() ?? 0.5).clamp(0.0, 1.0);

    final nextOpening = {
      ...opening,
      'position': (currentPosition + fractionDelta).clamp(0.0, 1.0),
    };

    _pushDragHistoryOnce();

    if (isDoor) {
      _commitDocument(
        widget.document.copyWith(
          doors: _replaceOpening(
            widget.document.doors,
            selected.id,
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
            selected.id,
            nextOpening,
          ),
        ),
        pushHistory: false,
      );
    }
  }
}