part of 'floor_plan_canvas.dart';

extension _FloorPlanCanvasKeyboard on _FloorPlanCanvasState {
  bool get _isShiftPressed {
    final keys = HardwareKeyboard.instance.logicalKeysPressed;

    return keys.contains(LogicalKeyboardKey.shiftLeft) ||
        keys.contains(LogicalKeyboardKey.shiftRight);
  }

  bool get _isAltPressed {
    final keys = HardwareKeyboard.instance.logicalKeysPressed;

    return keys.contains(LogicalKeyboardKey.altLeft) ||
        keys.contains(LogicalKeyboardKey.altRight);
  }

  bool get _isCtrlOrMetaPressed {
    final keys = HardwareKeyboard.instance.logicalKeysPressed;

    return keys.contains(LogicalKeyboardKey.controlLeft) ||
        keys.contains(LogicalKeyboardKey.controlRight) ||
        keys.contains(LogicalKeyboardKey.metaLeft) ||
        keys.contains(LogicalKeyboardKey.metaRight);
  }

  bool get _isEditorFocused {
    return _lengthEditorFocusNode.hasFocus ||
        _angleEditorFocusNode.hasFocus ||
        _roomNameEditorFocusNode.hasFocus;
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (_isEditorFocused) {
      return KeyEventResult.ignored;
    }

    final navigationResult = _handleNavigationKeyEvent(event);
    if (navigationResult != null) {
      return navigationResult;
    }

    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;

    if (_isCtrlOrMetaPressed && key == LogicalKeyboardKey.keyS) {
      widget.onSave?.call();
      return KeyEventResult.handled;
    }

    if (_isCtrlOrMetaPressed && key == LogicalKeyboardKey.keyZ) {
      if (_isShiftPressed) {
        _redo();
      } else {
        _undo();
      }

      return KeyEventResult.handled;
    }

    if (_isCtrlOrMetaPressed && key == LogicalKeyboardKey.keyY) {
      _redo();
      return KeyEventResult.handled;
    }

    if (_isCtrlOrMetaPressed && key == LogicalKeyboardKey.keyC) {
      _copySelectionToClipboard();
      return KeyEventResult.handled;
    }

    if (_isCtrlOrMetaPressed && key == LogicalKeyboardKey.keyV) {
      _pasteClipboard();
      return KeyEventResult.handled;
    }

    if (_isCtrlOrMetaPressed && key == LogicalKeyboardKey.keyD) {
      _duplicateSelection();
      return KeyEventResult.handled;
    }

    if (_isAltPressed && key == LogicalKeyboardKey.keyH) {
      _mirrorSelection(axis: FloorPlanMirrorAxis.horizontal);
      return KeyEventResult.handled;
    }

    if (_isAltPressed && key == LogicalKeyboardKey.keyV) {
      _mirrorSelection(axis: FloorPlanMirrorAxis.vertical);
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.escape) {
      _cancelCurrentDrawing();
      _hideContextMenu();
      _hideLengthEditor();
      _hideAngleEditor();
      _hideRoomNameEditor();

      setState(() {
        _isDraggingHandle = false;
        _isDraggingOpening = false;
        _isResizingOpening = false;
        _isDraggingAsset = false;
        _isMiddleMousePanning = false;

        _draggingConnectedHandles = const [];
        _draggingOpening = null;
        _resizingOpeningHandle = null;
        _draggingAssetId = null;
        _lastMiddleMousePanGlobalPosition = null;

        _isBoxSelecting = false;
        _selectionBoxStart = null;
        _selectionBoxEnd = null;

        _pendingVertexWallSplitHit = null;
        _activeGuideSnap = null;
        _dragHistoryPushed = false;

        _isDraggingVertexGroup = false;
        _vertexGroupDragStartCanvasPoint = null;
        _vertexDragAnchors = const [];

        _isDraggingWall = false;
        _wallDragStartCanvasPoint = null;
        _draggingWallIds = {};
        _wallDragSnapshots = const [];
      });

      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.delete ||
        key == LogicalKeyboardKey.backspace) {
      if (_selectedVertex != null || _selectedVertexKeys.isNotEmpty) {
        setState(() {
          _selectedVertex = null;
          _selectedVertexKeys.clear();
        });

        _clearLiveSelectionAndLock();
        return KeyEventResult.handled;
      }

      if (_selectedObject != null || _selectedWallIds.isNotEmpty) {
        _deleteSelectedObject();
        return KeyEventResult.handled;
      }

      return KeyEventResult.ignored;
    }

    if (_isCtrlOrMetaPressed) {
      return KeyEventResult.ignored;
    }

    if (event is KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    if (key == LogicalKeyboardKey.keyV || key == LogicalKeyboardKey.keyS) {
      _switchToolFromKeyboard(FloorPlanTool.select);
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.keyW) {
      _switchToolFromKeyboard(FloorPlanTool.wall);
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.keyF) {
      _switchToolFromKeyboard(FloorPlanTool.virtualWall);
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.keyR) {
      _switchToolFromKeyboard(FloorPlanTool.room);
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.keyD) {
      _switchToolFromKeyboard(FloorPlanTool.door);
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.keyO) {
      _switchToolFromKeyboard(FloorPlanTool.window);
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.keyG) {
      _switchToolFromKeyboard(FloorPlanTool.garageDoor);
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.keyA) {
      _switchToolFromKeyboard(FloorPlanTool.asset);
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.keyP || key == LogicalKeyboardKey.space) {
      _switchToolFromKeyboard(FloorPlanTool.pan);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _switchToolFromKeyboard(FloorPlanTool tool) {
    _hideContextMenu();
    _hideLengthEditor();
    _hideAngleEditor();
    _hideRoomNameEditor();

    setState(() {
      _tool = tool;

      _wallStart = null;
      _wallPreviewEnd = null;

      _continuousFirstPoint = null;
      _continuousWallCount = 0;

      _selectedVertex = null;

      _isDraggingHandle = false;
      _isDraggingOpening = false;
      _isResizingOpening = false;
      _isDraggingAsset = false;
      _isMiddleMousePanning = false;

      _draggingConnectedHandles = const [];
      _draggingOpening = null;
      _resizingOpeningHandle = null;
      _draggingAssetId = null;
      _lastMiddleMousePanGlobalPosition = null;

      _isDraggingVertexGroup = false;
      _vertexGroupDragStartCanvasPoint = null;
      _vertexDragAnchors = const [];

      _isDraggingWall = false;
      _wallDragStartCanvasPoint = null;
      _draggingWallIds = {};
      _wallDragSnapshots = const [];

      _pendingVertexWallSplitHit = null;

      _dragHistoryPushed = false;
      _activeGuideSnap = null;

      _isBoxSelecting = false;
      _selectionBoxStart = null;
      _selectionBoxEnd = null;
    });
  }
}