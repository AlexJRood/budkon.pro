part of 'floor_plan_canvas.dart';

extension _FloorPlanCanvasEvents on _FloorPlanCanvasState {
  void _handlePointerHover(PointerHoverEvent event) {
    final canvasPoint = _toCanvasPosition(event.position);

    _updateHoveredRoomCandidate(canvasPoint);

    if (_tool != FloorPlanTool.wall && _tool != FloorPlanTool.virtualWall) {
      return;
    }

    if (_wallStart == null) return;

    final nextPoint = _prepareDrawingPoint(
      rawPoint: canvasPoint,
      startPoint: _wallStart,
    );

    setState(() {
      _wallPreviewEnd = nextPoint;
    });
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (event.kind == PointerDeviceKind.touch) {
      if (_activeTouchPointers == 0) {
        // Fresh touch — clear single-finger navigation mode.
        _singleFingerNavigating = false;
      }
      _activeTouchPointers++;
      if (_isTouchGesturing) {
        // Second finger down — cancel any in-progress action and let
        // InteractiveViewer take over pan/zoom.
        final touchCount = _activeTouchPointers;
        setState(() {
          _resetInteractionStateForToolChange();
          // Restore the actual touch count after reset so _isTouchGesturing
          // stays true and InteractiveViewer keeps panEnabled/scaleEnabled.
          _activeTouchPointers = touchCount;
        });
        return;
      }
      if (_singleFingerNavigating) {
        // Remaining finger from a 2-finger gesture — keep navigating, don't
        // trigger tool actions.
        return;
      }
    }

    if (_isMiddleMousePointerDown(event)) {
      _startMiddleMousePan(event.position);
      return;
    }

    if (_isSecondaryPointerDown(event)) {
      _queueContextMenuForPointer(event);
      return;
    }
    _hideContextMenu();
    _requestFocus();

    final canvasPoint = _toCanvasPosition(event.position);

    _updateHoveredRoomCandidate(canvasPoint);

    if (_maybeStartTouchHold(event, canvasPoint)) {
      return;
    }

    final intent = _resolvePointerDownIntent(
      event,
      canvasPoint,
    );

    switch (intent.type) {
      case FloorPlanIntentType.editWallLength:
        _handleEditWallLengthIntent(intent);
        return;

      case FloorPlanIntentType.editCornerAngle:
        _handleEditCornerAngleIntent(intent);
        return;

      case FloorPlanIntentType.editRoomName:
        _handleEditRoomNameIntent(intent);
        return;

      case FloorPlanIntentType.splitWall:
        _handleSplitWallIntent(intent, canvasPoint);
        return;

      case FloorPlanIntentType.addRoom:
        _handleAddRoomIntent(canvasPoint);
        return;

      case FloorPlanIntentType.addAsset:
        _handleAddAssetIntent(canvasPoint);
        return;

      case FloorPlanIntentType.resizeOpening:
        _handleResizeOpeningIntent(intent);
        return;

      case FloorPlanIntentType.dragVertex:
        _handleDragVertexIntent(intent, canvasPoint);
        return;

      case FloorPlanIntentType.dragWall:
        _handleDragWallIntent(intent, canvasPoint);
        return;

      case FloorPlanIntentType.dragOpening:
        _handleDragOpeningIntent(intent);
        return;

      case FloorPlanIntentType.dragAsset:
        _handleDragAssetIntent(intent);
        return;

      case FloorPlanIntentType.selectRoom:
        _handleSelectRoomIntent(intent);
        return;

      case FloorPlanIntentType.selectWall:
        _handleSelectWallIntent(intent);
        return;

      case FloorPlanIntentType.boxSelect:
        _handleBoxSelectIntent(canvasPoint);
        return;

      case FloorPlanIntentType.drawWall:
        _handleDrawWallPointerDown(canvasPoint);
        return;

      case FloorPlanIntentType.addDoor:
        _handleAddDoorIntent(intent, canvasPoint);
        return;

      case FloorPlanIntentType.addWindow:
        _handleAddWindowIntent(intent, canvasPoint);
        return;

      case FloorPlanIntentType.addGarageDoor:
        _handleAddGarageDoorIntent(intent, canvasPoint);
        return;

      case FloorPlanIntentType.selectOpening:
        _handleSelectOpeningIntent(intent);
        return;

      case FloorPlanIntentType.selectAsset:
        _handleSelectAssetIntent(intent);
        return;

      case FloorPlanIntentType.pan:
      case FloorPlanIntentType.none:
        if (!_isShiftPressed) {
          _clearSelection();
          _clearLiveSelectionAndLock();
        }
        return;
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (_isTouchGesturing) return;

    if (_isTouchHoldPending) {
      if (event.pointer != _touchHoldPointerId) return;

      final start = _touchHoldStartGlobalPosition;
      final moved = start == null ? 0.0 : (event.position - start).distance;

      if (moved > 12) {
        // Moved like a swipe, not a hold — bail out so panning / normal
        // drag behavior (handled natively by InteractiveViewer / below)
        // takes over instead.
        _cancelTouchHold();
      } else {
        // Still deciding whether this is a hold; suppress everything else
        // until the timer fires or the gesture is cancelled.
        return;
      }
    }

    if (_singleFingerNavigating) {
      _panViewportBy(event.delta);
      return;
    }

    if (_isMiddleMousePanning) {
      if (!_isMiddleMousePointerMove(event)) {
        _stopMiddleMousePan();
        return;
      }

      _updateMiddleMousePan(event.position);
      return;
    }

    final canvasPoint = _toCanvasPosition(event.position);

    _updateHoveredRoomCandidate(canvasPoint);

    if (_isDraggingVertexGroup) {
      _moveVertexGroupTo(rawPoint: canvasPoint);
      return;
    }

    if (_isDraggingWall) {
      _moveWallDragTo(canvasPoint);
      return;
    }

    if (_isResizingOpening) {
      final handle = _resizingOpeningHandle;
      if (handle == null) return;

      _resizeOpeningWithHandle(
        hit: handle,
        canvasPoint: canvasPoint,
      );

      return;
    }

    if (_isBoxSelecting) {
      setState(() {
        _selectionBoxEnd = canvasPoint;
      });

      return;
    }

    if (_isDraggingHandle) {
      _moveSingleDraggedHandle(canvasPoint);
      return;
    }

    if (_isDraggingOpening) {
      final opening = _draggingOpening;
      if (opening == null) return;

      final wall = _findWallById(opening.wallId);
      if (wall == null) return;

      final position = _projectionFractionOnWall(canvasPoint, wall);

      _moveOpeningOnWall(
        opening,
        position,
      );

      return;
    }

    if (_isDraggingAsset) {
      final assetId = _draggingAssetId;
      if (assetId == null) return;

      _moveAssetTo(
        assetId,
        canvasPoint,
      );

      return;
    }

    if ((_tool == FloorPlanTool.wall || _tool == FloorPlanTool.virtualWall) &&
        _wallStart != null) {
      final nextPoint = _prepareDrawingPoint(
        rawPoint: canvasPoint,
        startPoint: _wallStart,
      );

      setState(() {
        _wallPreviewEnd = nextPoint;
      });

      return;
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (event.kind == PointerDeviceKind.touch) {
      final wasGesturing = _isTouchGesturing;
      setState(() {
        _activeTouchPointers = math.max(0, _activeTouchPointers - 1);
      });
      if (wasGesturing && _activeTouchPointers == 1) {
        // Transitioned from 2-finger gesture to 1 finger still on screen —
        // keep navigating with the remaining finger.
        setState(() => _singleFingerNavigating = true);
        return;
      }
      if (_activeTouchPointers == 0) {
        _singleFingerNavigating = false;
      }
      // Still have fingers on screen — don't process tool actions yet.
      if (_activeTouchPointers >= 1) return;
    }

    if (_isTouchHoldPending && event.pointer == _touchHoldPointerId) {
      // Released before the hold threshold — this was a quick tap, not a
      // hold. Cancel the pending gesture and let the normal tap handling
      // below run (e.g. finishing/connecting a wall as it always did).
      _cancelTouchHold();
    }

    if (_consumeQueuedContextMenu()) {
      return;
    }


    if (_isMiddleMousePanning) {
      _stopMiddleMousePan();
      return;
    }

    final canvasPoint = _toCanvasPosition(event.position);

    _updateHoveredRoomCandidate(canvasPoint);

    if (_isDraggingVertexGroup) {
      _stopVertexGroupDrag();
      _emitLiveSelectionChanged();
      return;
    }

    if (_isDraggingWall) {
      _stopWallDrag();
      _emitLiveSelectionChanged();
      return;
    }

    if (_isResizingOpening) {
      setState(() {
        _isResizingOpening = false;
        _resizingOpeningHandle = null;
        _dragHistoryPushed = false;
      });

      _emitLiveSelectionChanged();
      return;
    }

    if (_isBoxSelecting) {
      _finishBoxSelection();
      return;
    }

    if (_tool == FloorPlanTool.select || _tool == FloorPlanTool.pan) {
      if (_isDraggingHandle) {
        _splitPendingVertexWallIfNeeded();
      }

      setState(() {
        _isDraggingHandle = false;
        _isDraggingOpening = false;
        _isDraggingAsset = false;
        _isResizingOpening = false;
        _isMiddleMousePanning = false;

        _draggingConnectedHandles = const [];
        _draggingOpening = null;
        _draggingAssetId = null;
        _resizingOpeningHandle = null;
        _lastMiddleMousePanGlobalPosition = null;

        _pendingVertexWallSplitHit = null;
        _activeGuideSnap = null;

        _dragHistoryPushed = false;
      });

      _emitLiveSelectionChanged();
      return;
    }

    if ((_tool == FloorPlanTool.wall || _tool == FloorPlanTool.virtualWall) &&
        _wallStart != null) {
      _finishWallDrawing(canvasPoint);
      return;
    }
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (event.kind == PointerDeviceKind.touch) {
      setState(() {
        _activeTouchPointers = math.max(0, _activeTouchPointers - 1);
        if (_activeTouchPointers == 0) _singleFingerNavigating = false;
      });
    }
    if (event.pointer == _touchHoldPointerId) {
      _cancelTouchHold();
    }
    _stopMiddleMousePan();
  }

  /// Detects the two touch-only situations where a plain pointer-down should
  /// NOT immediately resolve into its usual intent, because a deliberate
  /// long-hold means something different here than an immediate tap/drag:
  ///  - Pan tool + touch down on a vertex handle: hold to grab & move the
  ///    vertex; anything less than a hold keeps panning as normal.
  ///  - Actively drawing a wall chain + touch down on a *different* existing
  ///    vertex: hold to restart drawing from that vertex instead of silently
  ///    connecting the pending chain to it (a quick tap still connects the
  ///    chain, same as before).
  /// Returns true if the down event was captured for a pending hold decision
  /// (the caller should stop processing this pointer-down any further).
  bool _maybeStartTouchHold(PointerDownEvent event, Offset canvasPoint) {
    if (event.kind != PointerDeviceKind.touch) return false;
    if (!_isPrimaryPointerDown(event)) return false;

    if (_tool == FloorPlanTool.pan) {
      final handle = _hitTestHandle(canvasPoint);
      if (handle == null) return false;

      _startTouchHold(
        purpose: _TouchHoldPurpose.vertexDrag,
        handle: handle,
        event: event,
        canvasPoint: canvasPoint,
      );
      return true;
    }

    if ((_tool == FloorPlanTool.wall || _tool == FloorPlanTool.virtualWall) &&
        _wallStart != null) {
      final handle = _hitTestHandle(canvasPoint);
      if (handle == null || _cornerKey(handle.point) == _cornerKey(_wallStart!)) {
        return false;
      }

      _startTouchHold(
        purpose: _TouchHoldPurpose.wallRestart,
        handle: handle,
        event: event,
        canvasPoint: canvasPoint,
      );
      return true;
    }

    return false;
  }

  void _startTouchHold({
    required _TouchHoldPurpose purpose,
    required _WallHandleHit handle,
    required PointerDownEvent event,
    required Offset canvasPoint,
  }) {
    _touchHoldTimer?.cancel();

    _touchHoldPurpose = purpose;
    _touchHoldHandle = handle;
    _touchHoldStartGlobalPosition = event.position;
    _touchHoldStartCanvasPoint = canvasPoint;
    _touchHoldPointerId = event.pointer;

    _touchHoldTimer = Timer(const Duration(milliseconds: 450), _fireTouchHold);
  }

  void _cancelTouchHold() {
    _touchHoldTimer?.cancel();
    _touchHoldTimer = null;
    _touchHoldPurpose = null;
    _touchHoldHandle = null;
    _touchHoldStartGlobalPosition = null;
    _touchHoldStartCanvasPoint = null;
    _touchHoldPointerId = null;
  }

  void _fireTouchHold() {
    _touchHoldTimer = null;

    final purpose = _touchHoldPurpose;
    final handle = _touchHoldHandle;
    final canvasPoint = _touchHoldStartCanvasPoint;

    _touchHoldPurpose = null;
    _touchHoldHandle = null;
    _touchHoldStartGlobalPosition = null;
    _touchHoldStartCanvasPoint = null;
    _touchHoldPointerId = null;

    if (!mounted || purpose == null || handle == null || canvasPoint == null) {
      return;
    }

    HapticFeedback.mediumImpact();

    switch (purpose) {
      case _TouchHoldPurpose.vertexDrag:
        _handleDragVertexIntent(
          FloorPlanIntent(
            type: FloorPlanIntentType.dragVertex,
            canvasPoint: canvasPoint,
            handle: handle,
            debugLabel: 'Touch hold: drag vertex',
            isSmartIntent: true,
            priority: 880,
          ),
          canvasPoint,
        );
        return;

      case _TouchHoldPurpose.wallRestart:
        _restartWallDrawingFromVertex(handle);
        return;
    }
  }

  void _restartWallDrawingFromVertex(_WallHandleHit handle) {
    final vertexObjectId = _vertexLiveObjectId(handle.point);

    if (!_guardLiveLock(objectType: 'vertex', objectId: vertexObjectId)) {
      return;
    }

    setState(() {
      _wallStart = handle.point;
      _wallPreviewEnd = handle.point;
      _activeGuideSnap = _GuideSnapResult(
        point: handle.point,
        label: 'Wierzchołek',
      );

      _continuousFirstPoint = handle.point;
      _continuousWallCount = 0;
    });
  }

  void _startWallDrawingAt(Offset canvasPoint, {required bool isVirtual}) {
    final existingHandle = _hitTestHandle(canvasPoint);

    final startSnap = existingHandle == null
        ? _prepareFreePointSnap(rawPoint: canvasPoint)
        : _GuideSnapResult(
            point: existingHandle.point,
            label: 'Wierzchołek',
          );

    setState(() {
      _tool = isVirtual ? FloorPlanTool.virtualWall : FloorPlanTool.wall;

      _selectedVertex = null;
      _selectedVertexKeys.clear();
      _selectedObject = null;
      _selectedWallIds.clear();

      _wallStart = startSnap.point;
      _wallPreviewEnd = startSnap.point;
      _activeGuideSnap = startSnap;
      _pendingVertexWallSplitHit = null;

      _continuousFirstPoint = startSnap.point;
      _continuousWallCount = 0;
    });
  }

  void _handleEditWallLengthIntent(FloorPlanIntent intent) {
    final wall = intent.lengthLabelHit?.wall ?? intent.wall;
    if (wall == null) return;

    if (!_guardLiveLock(
      objectType: 'wall',
      objectId: wall.id,
    )) {
      return;
    }

    _syncLiveLockForObject(
      objectType: 'wall',
      objectId: wall.id,
    );

    _showLengthEditorForWall(wall);
    _emitLiveSelectionChanged();
  }

  void _handleEditCornerAngleIntent(FloorPlanIntent intent) {
    final hit = intent.angleLabelHit;
    if (hit == null) return;

    if (!_guardLiveLock(
      objectType: 'wall',
      objectId: hit.wallAId,
    )) {
      return;
    }

    if (!_guardLiveLock(
      objectType: 'wall',
      objectId: hit.wallBId,
    )) {
      return;
    }

    _syncLiveLockForObject(
      objectType: 'wall',
      objectId: hit.wallBId,
    );

    _showAngleEditor(hit);
    _emitLiveSelectionChanged();
  }

  void _handleEditRoomNameIntent(FloorPlanIntent intent) {
    final room = intent.roomLabelHit?.room ?? intent.room;
    if (room == null) return;

    if (!_guardLiveLock(
      objectType: 'room',
      objectId: room.id,
    )) {
      return;
    }

    _hideLengthEditor(commit: true);
    _hideAngleEditor(commit: true);

    setState(() {
      _selectedVertex = null;
      _selectedVertexKeys.clear();
      _selectedWallIds.clear();
      _selectedObject = _SelectedObject(
        type: _SelectedObjectType.room,
        id: room.id,
      );

      _activeGuideSnap = null;
      _pendingVertexWallSplitHit = null;
    });

    _syncLiveLockForObject(
      objectType: 'room',
      objectId: room.id,
    );

    _showRoomNameEditor(room);
    _emitLiveSelectionChanged();
  }

  void _handleSplitWallIntent(
    FloorPlanIntent intent,
    Offset canvasPoint,
  ) {
    final wall = intent.wall;
    if (wall == null) return;

    if (!_guardLiveLock(
      objectType: 'wall',
      objectId: wall.id,
    )) {
      return;
    }

    _cancelCurrentDrawing();
    _hideLengthEditor();
    _hideAngleEditor();
    _hideRoomNameEditor();

    setState(() {
      _selectedVertex = null;
      _selectedVertexKeys.clear();
      _activeGuideSnap = null;
      _pendingVertexWallSplitHit = null;
    });

    _syncLiveLockForObject(
      objectType: 'wall',
      objectId: wall.id,
    );

    _splitWallAtPoint(
      wall,
      canvasPoint,
    );

    _emitLiveSelectionChanged();
  }

  void _handleAddRoomIntent(Offset canvasPoint) {
    _hideLengthEditor(commit: true);
    _hideAngleEditor(commit: true);
    _hideRoomNameEditor(commit: true);

    setState(() {
      _selectedVertex = null;
      _selectedVertexKeys.clear();
      _activeGuideSnap = null;
      _pendingVertexWallSplitHit = null;
    });

    _createRoomFromPoint(canvasPoint);
    _emitLiveSelectionChanged();
  }

  void _handleAddAssetIntent(Offset canvasPoint) {
    _hideLengthEditor(commit: true);
    _hideAngleEditor(commit: true);
    _hideRoomNameEditor(commit: true);

    setState(() {
      _selectedVertex = null;
      _selectedVertexKeys.clear();
      _activeGuideSnap = null;
      _pendingVertexWallSplitHit = null;
    });

    _addAssetAtPoint(canvasPoint);
    _emitLiveSelectionChanged();

    final selectedAsset = _selectedAsset;
    if (selectedAsset != null) {
      _syncLiveLockForObject(
        objectType: 'asset',
        objectId: selectedAsset.id,
      );
    }
  }

  void _handleResizeOpeningIntent(FloorPlanIntent intent) {
    _hideLengthEditor(commit: true);
    _hideAngleEditor(commit: true);
    _hideRoomNameEditor(commit: true);

    final handle = intent.openingResizeHandle;
    if (handle == null) return;

    final objectType =
        handle.openingType == _SelectedObjectType.door ? 'door' : 'window';

    if (!_guardLiveLock(
      objectType: objectType,
      objectId: handle.openingId,
    )) {
      return;
    }

    _pushDragHistoryOnce();

    setState(() {
      _selectedVertex = null;
      _selectedVertexKeys.clear();
      _selectedWallIds.clear();
      _selectedObject = _SelectedObject(
        type: handle.openingType,
        id: handle.openingId,
      );

      _isResizingOpening = true;
      _resizingOpeningHandle = handle;

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

      _isMiddleMousePanning = false;
      _lastMiddleMousePanGlobalPosition = null;

      _isBoxSelecting = false;
      _selectionBoxStart = null;
      _selectionBoxEnd = null;

      _pendingVertexWallSplitHit = null;
      _activeGuideSnap = null;
    });

    _syncLiveLockForObject(
      objectType: objectType,
      objectId: handle.openingId,
    );

    _emitLiveSelectionChanged();
  }

  void _handleDragVertexIntent(
    FloorPlanIntent intent,
    Offset canvasPoint,
  ) {
    _hideLengthEditor(commit: true);
    _hideAngleEditor(commit: true);
    _hideRoomNameEditor(commit: true);

    final handle = intent.handle;
    if (handle == null) return;

    if (_isShiftPressed) {
      _toggleVertexSelection(handle.point);
      _emitLiveSelectionChanged();
      return;
    }

    final vertexObjectId = _vertexLiveObjectId(handle.point);

    if (!_guardLiveLock(
      objectType: 'vertex',
      objectId: vertexObjectId,
    )) {
      return;
    }

    if (!_isVertexSelected(handle.point)) {
      _selectSingleVertex(handle.point);
    }

    _startVertexGroupDrag(
      primaryHandle: handle,
      canvasPoint: canvasPoint,
    );

    _syncLiveLockForObject(
      objectType: 'vertex',
      objectId: vertexObjectId,
    );

    _emitLiveSelectionChanged();
  }

  void _handleDragWallIntent(
    FloorPlanIntent intent,
    Offset canvasPoint,
  ) {
    _hideLengthEditor(commit: true);
    _hideAngleEditor(commit: true);
    _hideRoomNameEditor(commit: true);

    final wall = intent.wall;
    if (wall == null) return;

    if (_isMobileLayout && _selectedWallIds.contains(wall.id)) {
      setState(() => _mobileInspectorVisible = true);
      return;
    }

    if (_isShiftPressed) {
      _toggleWallSelection(wall.id);

      setState(() {
        _selectedVertex = null;
        _selectedVertexKeys.clear();
        _activeGuideSnap = null;
        _pendingVertexWallSplitHit = null;
      });

      _emitLiveSelectionChanged();
      return;
    }

    final wallIdsToMove = _selectedWallIds.contains(wall.id)
        ? Set<String>.from(_selectedWallIds)
        : <String>{wall.id};

    for (final wallId in wallIdsToMove) {
      if (!_guardLiveLock(
        objectType: 'wall',
        objectId: wallId,
      )) {
        return;
      }
    }

    setState(() {
      _selectedObject = _SelectedObject(
        type: _SelectedObjectType.wall,
        id: wall.id,
      );
      _selectedWallIds = wallIdsToMove;

      _selectedVertex = null;
      _selectedVertexKeys.clear();

      _isDraggingHandle = false;
      _draggingConnectedHandles = const [];

      _isDraggingVertexGroup = false;
      _vertexGroupDragStartCanvasPoint = null;
      _vertexDragAnchors = const [];

      _isDraggingOpening = false;
      _draggingOpening = null;

      _isDraggingAsset = false;
      _draggingAssetId = null;

      _isResizingOpening = false;
      _resizingOpeningHandle = null;

      _isMiddleMousePanning = false;
      _lastMiddleMousePanGlobalPosition = null;

      _isBoxSelecting = false;
      _selectionBoxStart = null;
      _selectionBoxEnd = null;

      _pendingVertexWallSplitHit = null;
      _activeGuideSnap = null;
    });

    _startWallDrag(
      wall: wall,
      canvasPoint: canvasPoint,
    );

    _syncLiveLockForObject(
      objectType: 'wall',
      objectId: wall.id,
    );

    _emitLiveSelectionChanged();
  }

  void _handleDragOpeningIntent(FloorPlanIntent intent) {
    _hideLengthEditor(commit: true);
    _hideAngleEditor(commit: true);
    _hideRoomNameEditor(commit: true);

    final opening = intent.opening;
    if (opening == null) return;

    if (_isMobileLayout && _selectedObject?.id == opening.id) {
      setState(() => _mobileInspectorVisible = true);
      return;
    }

    final objectType =
        opening.type == _SelectedObjectType.door ? 'door' : 'window';

    if (!_guardLiveLock(
      objectType: objectType,
      objectId: opening.id,
    )) {
      return;
    }

    _pushDragHistoryOnce();

    setState(() {
      _selectedVertex = null;
      _selectedVertexKeys.clear();
      _selectedWallIds.clear();
      _selectedObject = _SelectedObject(
        type: opening.type,
        id: opening.id,
      );

      _isDraggingOpening = true;
      _draggingOpening = opening;

      _isResizingOpening = false;
      _resizingOpeningHandle = null;

      _isDraggingHandle = false;
      _draggingConnectedHandles = const [];

      _isDraggingVertexGroup = false;
      _vertexGroupDragStartCanvasPoint = null;
      _vertexDragAnchors = const [];

      _isDraggingWall = false;
      _wallDragStartCanvasPoint = null;
      _draggingWallIds = {};
      _wallDragSnapshots = const [];

      _isDraggingAsset = false;
      _draggingAssetId = null;

      _isMiddleMousePanning = false;
      _lastMiddleMousePanGlobalPosition = null;

      _isBoxSelecting = false;
      _selectionBoxStart = null;
      _selectionBoxEnd = null;

      _pendingVertexWallSplitHit = null;
      _activeGuideSnap = null;
    });

    _syncLiveLockForObject(
      objectType: objectType,
      objectId: opening.id,
    );

    _emitLiveSelectionChanged();
  }

  void _handleDragAssetIntent(FloorPlanIntent intent) {
    _hideLengthEditor(commit: true);
    _hideAngleEditor(commit: true);
    _hideRoomNameEditor(commit: true);

    final asset = intent.assetHit;
    if (asset == null) return;

    if (_isMobileLayout && _selectedObject?.id == asset.assetId) {
      setState(() => _mobileInspectorVisible = true);
      return;
    }

    if (!_guardLiveLock(
      objectType: 'asset',
      objectId: asset.assetId,
    )) {
      return;
    }

    _pushDragHistoryOnce();

    setState(() {
      _selectedVertex = null;
      _selectedVertexKeys.clear();
      _selectedWallIds.clear();
      _selectedObject = _SelectedObject(
        type: _SelectedObjectType.asset,
        id: asset.assetId,
      );

      _isDraggingAsset = true;
      _draggingAssetId = asset.assetId;

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

      _isResizingOpening = false;
      _resizingOpeningHandle = null;

      _isMiddleMousePanning = false;
      _lastMiddleMousePanGlobalPosition = null;

      _isBoxSelecting = false;
      _selectionBoxStart = null;
      _selectionBoxEnd = null;

      _pendingVertexWallSplitHit = null;
      _activeGuideSnap = null;
    });

    _syncLiveLockForObject(
      objectType: 'asset',
      objectId: asset.assetId,
    );

    _emitLiveSelectionChanged();
  }

  void _handleSelectRoomIntent(FloorPlanIntent intent) {
    _hideLengthEditor(commit: true);
    _hideAngleEditor(commit: true);
    _hideRoomNameEditor(commit: true);

    final room = intent.room;
    if (room == null) return;

    if (_isMobileLayout && _selectedObject?.id == room.id) {
      setState(() => _mobileInspectorVisible = true);
      return;
    }

    if (!_guardLiveLock(
      objectType: 'room',
      objectId: room.id,
    )) {
      return;
    }

    setState(() {
      _selectedVertex = null;
      _selectedVertexKeys.clear();
      _selectedWallIds.clear();
      _selectedObject = _SelectedObject(
        type: _SelectedObjectType.room,
        id: room.id,
      );

      _isBoxSelecting = false;
      _selectionBoxStart = null;
      _selectionBoxEnd = null;

      _pendingVertexWallSplitHit = null;
      _activeGuideSnap = null;
    });

    _syncLiveLockForObject(
      objectType: 'room',
      objectId: room.id,
    );

    _emitLiveSelectionChanged();
  }

  void _handleSelectWallIntent(FloorPlanIntent intent) {
    _hideLengthEditor(commit: true);
    _hideAngleEditor(commit: true);
    _hideRoomNameEditor(commit: true);

    final wall = intent.wall;
    if (wall == null) return;

    if (_isMobileLayout && _selectedWallIds.contains(wall.id)) {
      setState(() => _mobileInspectorVisible = true);
      return;
    }

    if (_isShiftPressed) {
      _toggleWallSelection(wall.id);

      setState(() {
        _selectedVertex = null;
        _selectedVertexKeys.clear();
        _activeGuideSnap = null;
        _pendingVertexWallSplitHit = null;
      });

      _emitLiveSelectionChanged();
      return;
    }

    if (!_guardLiveLock(
      objectType: 'wall',
      objectId: wall.id,
    )) {
      return;
    }

    _selectSingleWall(wall.id);

    setState(() {
      _selectedVertex = null;
      _selectedVertexKeys.clear();

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

      _isMiddleMousePanning = false;
      _lastMiddleMousePanGlobalPosition = null;

      _pendingVertexWallSplitHit = null;
      _activeGuideSnap = null;

      _isBoxSelecting = false;
      _selectionBoxStart = null;
      _selectionBoxEnd = null;
    });

    _syncLiveLockForObject(
      objectType: 'wall',
      objectId: wall.id,
    );

    _emitLiveSelectionChanged();
  }

  void _handleBoxSelectIntent(Offset canvasPoint) {
    _hideLengthEditor(commit: true);
    _hideAngleEditor(commit: true);
    _hideRoomNameEditor(commit: true);

    setState(() {
      if (!_isShiftPressed) {
        _selectedVertex = null;
        _selectedVertexKeys.clear();
        _selectedWallIds.clear();
        _selectedObject = null;
        _releaseCurrentLiveObjectLock();
      }

      _isBoxSelecting = true;
      _selectionBoxStart = canvasPoint;
      _selectionBoxEnd = canvasPoint;

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

      _isMiddleMousePanning = false;
      _lastMiddleMousePanGlobalPosition = null;

      _pendingVertexWallSplitHit = null;
      _activeGuideSnap = null;
    });
  }

  void _handleDrawWallPointerDown(Offset canvasPoint) {
    _hideLengthEditor(commit: true);
    _hideAngleEditor(commit: true);
    _hideRoomNameEditor(commit: true);

    if (_wallStart == null) {
      final existingHandle = _hitTestHandle(canvasPoint);

      if (existingHandle != null) {
        final vertexObjectId = _vertexLiveObjectId(existingHandle.point);

        if (!_guardLiveLock(
          objectType: 'vertex',
          objectId: vertexObjectId,
        )) {
          return;
        }
      }

      final startSnap = existingHandle == null
          ? _prepareFreePointSnap(rawPoint: canvasPoint)
          : _GuideSnapResult(
              point: existingHandle.point,
              label: 'Wierzchołek',
            );

      final startPoint = startSnap.point;

      setState(() {
        _selectedVertex = null;
        _selectedVertexKeys.clear();
        _selectedObject = null;
        _selectedWallIds.clear();

        _wallStart = startPoint;
        _wallPreviewEnd = startPoint;

        _activeGuideSnap = startSnap;
        _pendingVertexWallSplitHit = null;

        _continuousFirstPoint ??= startPoint;
      });

      return;
    }

    final nextPoint = _prepareDrawingPoint(
      rawPoint: canvasPoint,
      startPoint: _wallStart,
    );

    setState(() {
      _wallPreviewEnd = nextPoint;
    });
  }

  void _handleAddDoorIntent(
    FloorPlanIntent intent,
    Offset canvasPoint,
  ) {
    _hideLengthEditor(commit: true);
    _hideAngleEditor(commit: true);
    _hideRoomNameEditor(commit: true);

    final wall = intent.wall;
    if (wall == null) return;

    if (!_guardLiveLock(
      objectType: 'wall',
      objectId: wall.id,
    )) {
      return;
    }

    setState(() {
      _selectedVertex = null;
      _selectedVertexKeys.clear();
      _activeGuideSnap = null;
      _pendingVertexWallSplitHit = null;
    });

    _syncLiveLockForObject(
      objectType: 'wall',
      objectId: wall.id,
    );

    _addDoor(
      wall: wall,
      position: _projectionFractionOnWall(canvasPoint, wall),
    );

    _emitLiveSelectionChanged();
  }

  void _handleAddWindowIntent(
    FloorPlanIntent intent,
    Offset canvasPoint,
  ) {
    _hideLengthEditor(commit: true);
    _hideAngleEditor(commit: true);
    _hideRoomNameEditor(commit: true);

    final wall = intent.wall;
    if (wall == null) return;

    if (!_guardLiveLock(
      objectType: 'wall',
      objectId: wall.id,
    )) {
      return;
    }

    setState(() {
      _selectedVertex = null;
      _selectedVertexKeys.clear();
      _activeGuideSnap = null;
      _pendingVertexWallSplitHit = null;
    });

    _syncLiveLockForObject(
      objectType: 'wall',
      objectId: wall.id,
    );

    _addWindow(
      wall: wall,
      position: _projectionFractionOnWall(canvasPoint, wall),
    );

    _emitLiveSelectionChanged();
  }

  void _handleAddGarageDoorIntent(
    FloorPlanIntent intent,
    Offset canvasPoint,
  ) {
    _hideLengthEditor(commit: true);
    _hideAngleEditor(commit: true);
    _hideRoomNameEditor(commit: true);

    final wall = intent.wall;
    if (wall == null) return;

    if (!_guardLiveLock(
      objectType: 'wall',
      objectId: wall.id,
    )) {
      return;
    }

    setState(() {
      _selectedVertex = null;
      _selectedVertexKeys.clear();
      _activeGuideSnap = null;
      _pendingVertexWallSplitHit = null;
    });

    _syncLiveLockForObject(
      objectType: 'wall',
      objectId: wall.id,
    );

    _addGarageDoor(
      wall: wall,
      position: _projectionFractionOnWall(canvasPoint, wall),
    );

    _emitLiveSelectionChanged();
  }

  void _handleSelectOpeningIntent(FloorPlanIntent intent) {
    _hideLengthEditor(commit: true);
    _hideAngleEditor(commit: true);
    _hideRoomNameEditor(commit: true);

    final opening = intent.opening;
    if (opening == null) return;

    if (_isMobileLayout && _selectedObject?.id == opening.id) {
      setState(() => _mobileInspectorVisible = true);
      return;
    }

    final objectType =
        opening.type == _SelectedObjectType.door ? 'door' : 'window';

    if (!_guardLiveLock(
      objectType: objectType,
      objectId: opening.id,
    )) {
      return;
    }

    setState(() {
      _selectedVertex = null;
      _selectedVertexKeys.clear();
      _selectedWallIds.clear();
      _selectedObject = _SelectedObject(
        type: opening.type,
        id: opening.id,
      );

      _pendingVertexWallSplitHit = null;
      _activeGuideSnap = null;
    });

    _syncLiveLockForObject(
      objectType: objectType,
      objectId: opening.id,
    );

    _emitLiveSelectionChanged();
  }

  void _handleSelectAssetIntent(FloorPlanIntent intent) {
    _hideLengthEditor(commit: true);
    _hideAngleEditor(commit: true);
    _hideRoomNameEditor(commit: true);

    final asset = intent.assetHit;
    if (asset == null) return;

    if (_isMobileLayout && _selectedObject?.id == asset.assetId) {
      setState(() => _mobileInspectorVisible = true);
      return;
    }

    if (!_guardLiveLock(
      objectType: 'asset',
      objectId: asset.assetId,
    )) {
      return;
    }

    setState(() {
      _selectedVertex = null;
      _selectedVertexKeys.clear();
      _selectedWallIds.clear();
      _selectedObject = _SelectedObject(
        type: _SelectedObjectType.asset,
        id: asset.assetId,
      );

      _pendingVertexWallSplitHit = null;
      _activeGuideSnap = null;
    });

    _syncLiveLockForObject(
      objectType: 'asset',
      objectId: asset.assetId,
    );

    _emitLiveSelectionChanged();
  }

  void _moveSingleDraggedHandle(Offset canvasPoint) {
    final ignoredWallIds =
        _draggingConnectedHandles.map((handle) => handle.wallId).toSet();

    final prepared = _prepareVertexDragPoint(
      rawPoint: canvasPoint,
      ignoreWallIds: ignoredWallIds,
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

      _moveConnectedHandlesToPoint(prepared.point);
    } else {
      _pendingVertexWallSplitHit = null;
      _moveConnectedHandles(prepared.point);
    }

    setState(() {
      _selectedVertex = _SelectedVertex(
        point: prepared.point,
        connectedHandles: _draggingConnectedHandles,
      );
    });
  }

  void _finishBoxSelection() {
    final rect = _currentSelectionRect();

    final isTinySelection = rect == null ||
        (rect.width.abs() < (4 / _currentScale) &&
            rect.height.abs() < (4 / _currentScale));

    if (isTinySelection) {
      setState(() {
        if (!_isShiftPressed) {
          _selectedWallIds.clear();
          _selectedVertexKeys.clear();
          _selectedObject = null;
          _selectedVertex = null;
        }

        _isBoxSelecting = false;
        _selectionBoxStart = null;
        _selectionBoxEnd = null;
      });

      if (!_isShiftPressed) {
        _clearLiveSelectionAndLock();
      }

      _emitLiveSelectionChanged();
      return;
    }

    final foundWalls = _wallsInsideRect(rect);
    final foundVertices = _verticesInsideRect(rect);

    setState(() {
      if (_isShiftPressed) {
        _selectedWallIds = {
          ..._selectedWallIds,
          ...foundWalls,
        };

        _selectedVertexKeys = {
          ..._selectedVertexKeys,
          ...foundVertices,
        };
      } else {
        _selectedWallIds = foundWalls;
        _selectedVertexKeys = foundVertices;
      }

      if (_selectedWallIds.isNotEmpty) {
        _selectedObject = _SelectedObject(
          type: _SelectedObjectType.wall,
          id: _selectedWallIds.last,
        );
        _selectedVertex = null;
      } else if (_selectedVertexKeys.isNotEmpty) {
        _selectedObject = null;

        final firstPoint = _pointForVertexKey(_selectedVertexKeys.first);

        _selectedVertex = firstPoint == null
            ? null
            : _SelectedVertex(
                point: firstPoint,
                connectedHandles: _findConnectedHandles(firstPoint),
              );
      } else {
        _selectedObject = null;
        _selectedVertex = null;
      }

      _isBoxSelecting = false;
      _selectionBoxStart = null;
      _selectionBoxEnd = null;
    });

    if (_selectedWallIds.isNotEmpty) {
      final primaryWallId = _selectedWallIds.last;

      if (_guardLiveLock(
        objectType: 'wall',
        objectId: primaryWallId,
      )) {
        _syncLiveLockForObject(
          objectType: 'wall',
          objectId: primaryWallId,
        );
      }
    } else if (_selectedVertexKeys.isNotEmpty) {
      final primaryVertexId = _selectedVertexKeys.first;

      if (_guardLiveLock(
        objectType: 'vertex',
        objectId: primaryVertexId,
      )) {
        _syncLiveLockForObject(
          objectType: 'vertex',
          objectId: primaryVertexId,
        );
      }
    } else {
      _clearLiveSelectionAndLock();
    }

    _emitLiveSelectionChanged();
  }

  void _finishWallDrawing(Offset canvasPoint) {
    final start = _wallStart;
    if (start == null) return;

    final end = _prepareDrawingPoint(
      rawPoint: canvasPoint,
      startPoint: start,
    );

    final distance = (end - start).distance;

    if (distance < 8) {
      setState(() {
        if (!_continuousDrawingEnabled) {
          _wallStart = null;
          _wallPreviewEnd = null;
          _activeGuideSnap = null;
        }
      });

      return;
    }

    final isVirtual = _tool == FloorPlanTool.virtualWall;

    final wall = FloorWall(
      id: 'wall_${DateTime.now().microsecondsSinceEpoch}',
      start: FloorPoint(
        x: start.dx,
        y: start.dy,
      ),
      end: FloorPoint(
        x: end.dx,
        y: end.dy,
      ),
      thickness: isVirtual ? 1 : 12,
      heightM: 2.6,
      kind: isVirtual ? FloorWall.kindVirtual : FloorWall.kindStructural,
    );

    var nextDocument = widget.document;

    final snapWallId = _activeGuideSnap?.snapWallId;
    final snapWallFraction = _activeGuideSnap?.snapWallFraction;

    if (snapWallId != null &&
        snapWallFraction != null &&
        snapWallFraction > 0.02 &&
        snapWallFraction < 0.98) {
      final splitResult = _splitWallInDocument(
        nextDocument,
        wallId: snapWallId,
        rawPoint: end,
      );

      nextDocument = splitResult.document;
    }

    nextDocument = nextDocument.copyWith(
      walls: [
        ...nextDocument.walls,
        wall,
      ],
    );

    _commitDocument(nextDocument);

    final didCloseShape = _didCloseContinuousShape(end);
    final shouldContinue = _continuousDrawingEnabled && !didCloseShape;

    setState(() {
      _selectedVertex = null;
      _selectedVertexKeys.clear();
      _selectedObject = _SelectedObject(
        type: _SelectedObjectType.wall,
        id: wall.id,
      );
      _selectedWallIds = {wall.id};

      if (shouldContinue) {
        _continuousFirstPoint ??= start;
        _continuousWallCount += 1;
        _wallStart = end;
        _wallPreviewEnd = end;
      } else {
        _continuousFirstPoint = null;
        _continuousWallCount = 0;
        _wallStart = null;
        _wallPreviewEnd = null;
        _activeGuideSnap = null;
      }
    });

    _syncLiveLockForObject(
      objectType: 'wall',
      objectId: wall.id,
    );

    _emitLiveSelectionChanged();
  }
}