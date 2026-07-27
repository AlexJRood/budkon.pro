part of 'floor_plan_canvas.dart';

enum FloorPlanIntentType {
  editWallLength,
  editCornerAngle,
  editRoomName,

  splitWall,

  dragVertex,
  dragWall,
  dragOpening,
  resizeOpening,
  dragAsset,

  selectWall,
  selectOpening,
  selectRoom,
  selectAsset,
  boxSelect,

  drawWall,
  addRoom,
  addDoor,
  addWindow,
  addGarageDoor,
  addAsset,

  pan,
  none,
}

class FloorPlanIntent {
  final FloorPlanIntentType type;
  final Offset canvasPoint;

  final FloorWall? wall;
  final _WallHandleHit? handle;
  final _OpeningHit? opening;
  final _OpeningResizeHandleHit? openingResizeHandle;
  final _AssetHit? assetHit;
  final FloorRoom? room;

  final _WallLengthLabelHit? lengthLabelHit;
  final _CornerAngleLabelHit? angleLabelHit;
  final _RoomLabelHit? roomLabelHit;

  final String debugLabel;
  final bool isSmartIntent;
  final int priority;

  const FloorPlanIntent({
    required this.type,
    required this.canvasPoint,
    this.wall,
    this.handle,
    this.opening,
    this.openingResizeHandle,
    this.assetHit,
    this.room,
    this.lengthLabelHit,
    this.angleLabelHit,
    this.roomLabelHit,
    this.debugLabel = '',
    this.isSmartIntent = false,
    this.priority = 0,
  });

  bool get isNone => type == FloorPlanIntentType.none;

  bool get isEditIntent {
    return type == FloorPlanIntentType.editWallLength ||
        type == FloorPlanIntentType.editCornerAngle ||
        type == FloorPlanIntentType.editRoomName;
  }

  bool get isDragIntent {
    return type == FloorPlanIntentType.dragVertex ||
        type == FloorPlanIntentType.dragWall ||
        type == FloorPlanIntentType.dragOpening ||
        type == FloorPlanIntentType.resizeOpening ||
        type == FloorPlanIntentType.dragAsset;
  }

  bool get isCreationIntent {
    return type == FloorPlanIntentType.drawWall ||
        type == FloorPlanIntentType.addRoom ||
        type == FloorPlanIntentType.addDoor ||
        type == FloorPlanIntentType.addWindow ||
        type == FloorPlanIntentType.addGarageDoor ||
        type == FloorPlanIntentType.addAsset;
  }
}

extension _FloorPlanCanvasIntentResolver on _FloorPlanCanvasState {
  FloorPlanIntent _resolvePointerDownIntent(
    PointerDownEvent event,
    Offset canvasPoint,
  ) {
    final isPrimary = _isPrimaryPointerDown(event);

    if (!isPrimary) {
      return FloorPlanIntent(
        type: FloorPlanIntentType.none,
        canvasPoint: canvasPoint,
        debugLabel: 'Non-primary pointer',
      );
    }

    final isFinishingWall =
        (_tool == FloorPlanTool.wall || _tool == FloorPlanTool.virtualWall) &&
            _wallStart != null;

    if (isFinishingWall) {
      return FloorPlanIntent(
        type: FloorPlanIntentType.drawWall,
        canvasPoint: canvasPoint,
        debugLabel: 'Finish active wall drawing',
        isSmartIntent: true,
        priority: 1000,
      );
    }

    final doubleClickIntent = _resolveDoubleClickIntent(canvasPoint);
    if (doubleClickIntent != null) return doubleClickIntent;

    final editorIntent = _resolveEditorIntent(canvasPoint);
    if (editorIntent != null) return editorIntent;

    final resizeIntent = _resolveResizeIntent(canvasPoint);
    if (resizeIntent != null) return resizeIntent;

    if (_tool == FloorPlanTool.wall || _tool == FloorPlanTool.virtualWall) {
      return FloorPlanIntent(
        type: FloorPlanIntentType.drawWall,
        canvasPoint: canvasPoint,
        debugLabel: 'Wall tool: draw wall',
        priority: 850,
      );
    }

    if (_tool == FloorPlanTool.room) {
      final roomLabelHit = _hitTestRoomLabel(canvasPoint);

      if (roomLabelHit != null) {
        return FloorPlanIntent(
          type: FloorPlanIntentType.editRoomName,
          canvasPoint: canvasPoint,
          room: roomLabelHit.room,
          roomLabelHit: roomLabelHit,
          debugLabel: 'Room tool: edit room label',
          isSmartIntent: true,
          priority: 840,
        );
      }

      final existingRoom = _hitTestRoomBody(canvasPoint);

      if (existingRoom != null) {
        return FloorPlanIntent(
          type: FloorPlanIntentType.editRoomName,
          canvasPoint: canvasPoint,
          room: existingRoom,
          debugLabel: 'Room tool: edit existing room',
          isSmartIntent: true,
          priority: 830,
        );
      }

      return FloorPlanIntent(
        type: FloorPlanIntentType.addRoom,
        canvasPoint: canvasPoint,
        debugLabel: 'Room tool: add room',
        priority: 820,
      );
    }

    if (_tool == FloorPlanTool.door ||
        _tool == FloorPlanTool.window ||
        _tool == FloorPlanTool.garageDoor) {
      final directIntent = _resolveDirectManipulationIntent(
        canvasPoint,
        allowVertexDrag: true,
        allowOpeningDrag: true,
        allowAssetDrag: true,
        allowWallDrag: false,
        allowWallSelect: false,
        allowRoomSelect: false,
      );

      if (directIntent != null) return directIntent;

      final wall = _hitTestWall(canvasPoint);

      if (wall == null) {
        return FloorPlanIntent(
          type: FloorPlanIntentType.none,
          canvasPoint: canvasPoint,
          debugLabel: 'Opening tool: no wall found',
        );
      }

      if (_tool == FloorPlanTool.door) {
        return FloorPlanIntent(
          type: FloorPlanIntentType.addDoor,
          canvasPoint: canvasPoint,
          wall: wall,
          debugLabel: 'Add door',
          priority: 800,
        );
      }

      if (_tool == FloorPlanTool.window) {
        return FloorPlanIntent(
          type: FloorPlanIntentType.addWindow,
          canvasPoint: canvasPoint,
          wall: wall,
          debugLabel: 'Add window',
          priority: 800,
        );
      }

      return FloorPlanIntent(
        type: FloorPlanIntentType.addGarageDoor,
        canvasPoint: canvasPoint,
        wall: wall,
        debugLabel: 'Add garage door',
        priority: 800,
      );
    }

    if (_tool == FloorPlanTool.asset) {
      final directIntent = _resolveDirectManipulationIntent(
        canvasPoint,
        allowVertexDrag: true,
        allowOpeningDrag: true,
        allowAssetDrag: true,
        allowWallDrag: false,
        allowWallSelect: false,
        allowRoomSelect: false,
      );

      if (directIntent != null) return directIntent;

      return FloorPlanIntent(
        type: FloorPlanIntentType.addAsset,
        canvasPoint: canvasPoint,
        debugLabel: 'Asset tool: add asset',
        priority: 780,
      );
    }

    if (_tool == FloorPlanTool.select) {
      final directIntent = _resolveDirectManipulationIntent(
        canvasPoint,
        allowVertexDrag: true,
        allowOpeningDrag: true,
        allowAssetDrag: true,
        allowWallDrag: true,
        allowWallSelect: true,
        allowRoomSelect: true,
      );

      if (directIntent != null) return directIntent;

      return FloorPlanIntent(
        type: FloorPlanIntentType.boxSelect,
        canvasPoint: canvasPoint,
        debugLabel: 'Select tool: box select / clear selection',
        priority: 200,
      );
    }

    if (_tool == FloorPlanTool.pan) {
      final directIntent = _resolveDirectManipulationIntent(
        canvasPoint,
        allowVertexDrag: false,
        allowOpeningDrag: true,
        allowAssetDrag: true,
        allowWallDrag: true,
        allowWallSelect: true,
        allowRoomSelect: true,
      );

      if (directIntent != null) return directIntent;

      return FloorPlanIntent(
        type: FloorPlanIntentType.pan,
        canvasPoint: canvasPoint,
        debugLabel: 'Pan tool',
        priority: 100,
      );
    }

    return FloorPlanIntent(
      type: FloorPlanIntentType.none,
      canvasPoint: canvasPoint,
      debugLabel: 'No intent',
    );
  }

  FloorPlanIntent? _resolveDoubleClickIntent(Offset canvasPoint) {
    if (!_isDoubleClickOnCanvas(canvasPoint)) return null;

    final roomLabelHit = _hitTestRoomLabel(canvasPoint);

    if (roomLabelHit != null) {
      return FloorPlanIntent(
        type: FloorPlanIntentType.editRoomName,
        canvasPoint: canvasPoint,
        room: roomLabelHit.room,
        roomLabelHit: roomLabelHit,
        debugLabel: 'Double click room label',
        isSmartIntent: true,
        priority: 980,
      );
    }

    final wall = _hitTestWall(canvasPoint);

    if (wall != null) {
      return FloorPlanIntent(
        type: FloorPlanIntentType.splitWall,
        canvasPoint: canvasPoint,
        wall: wall,
        debugLabel: 'Double click wall: split wall',
        isSmartIntent: true,
        priority: 970,
      );
    }

    final room = _hitTestRoomBody(canvasPoint);

    if (room != null) {
      return FloorPlanIntent(
        type: FloorPlanIntentType.editRoomName,
        canvasPoint: canvasPoint,
        room: room,
        debugLabel: 'Double click room body',
        isSmartIntent: true,
        priority: 960,
      );
    }

    return null;
  }

  FloorPlanIntent? _resolveEditorIntent(Offset canvasPoint) {
    final lengthLabelHit = _hitTestWallLengthLabel(canvasPoint);

    if (lengthLabelHit != null) {
      return FloorPlanIntent(
        type: FloorPlanIntentType.editWallLength,
        canvasPoint: canvasPoint,
        wall: lengthLabelHit.wall,
        lengthLabelHit: lengthLabelHit,
        debugLabel: 'Edit wall length',
        priority: 940,
      );
    }

    if (_cornerAnglesVisible) {
      final angleHit = _hitTestCornerAngleLabel(canvasPoint);

      if (angleHit != null) {
        return FloorPlanIntent(
          type: FloorPlanIntentType.editCornerAngle,
          canvasPoint: canvasPoint,
          angleLabelHit: angleHit,
          debugLabel: 'Edit corner angle',
          priority: 930,
        );
      }
    }

    final roomLabelHit = _hitTestRoomLabel(canvasPoint);

    if (roomLabelHit != null) {
      return FloorPlanIntent(
        type: FloorPlanIntentType.editRoomName,
        canvasPoint: canvasPoint,
        room: roomLabelHit.room,
        roomLabelHit: roomLabelHit,
        debugLabel: 'Edit room name',
        priority: 920,
      );
    }

    return null;
  }

  FloorPlanIntent? _resolveResizeIntent(Offset canvasPoint) {
    final openingResizeHandle = _hitTestOpeningResizeHandle(canvasPoint);

    if (openingResizeHandle == null) return null;

    return FloorPlanIntent(
      type: FloorPlanIntentType.resizeOpening,
      canvasPoint: canvasPoint,
      openingResizeHandle: openingResizeHandle,
      debugLabel: 'Resize opening',
      isSmartIntent: true,
      priority: 900,
    );
  }

  FloorPlanIntent? _resolveDirectManipulationIntent(
    Offset canvasPoint, {
    required bool allowVertexDrag,
    required bool allowOpeningDrag,
    required bool allowAssetDrag,
    required bool allowWallDrag,
    required bool allowWallSelect,
    required bool allowRoomSelect,
  }) {
    if (allowVertexDrag) {
      final handle = _hitTestHandle(canvasPoint);

      if (handle != null) {
        return FloorPlanIntent(
          type: FloorPlanIntentType.dragVertex,
          canvasPoint: canvasPoint,
          handle: handle,
          debugLabel:
              _isShiftPressed ? 'Shift vertex selection' : 'Drag vertex',
          isSmartIntent: true,
          priority: 880,
        );
      }
    }

    if (allowOpeningDrag) {
      final opening = _hitTestOpening(canvasPoint);

      if (opening != null) {
        return FloorPlanIntent(
          type: FloorPlanIntentType.dragOpening,
          canvasPoint: canvasPoint,
          opening: opening,
          debugLabel: 'Drag opening',
          isSmartIntent: true,
          priority: 870,
        );
      }
    }

    if (allowAssetDrag) {
      final asset = _hitTestAsset(canvasPoint);

      if (asset != null) {
        return FloorPlanIntent(
          type: FloorPlanIntentType.dragAsset,
          canvasPoint: canvasPoint,
          assetHit: asset,
          debugLabel: 'Drag asset',
          isSmartIntent: true,
          priority: 860,
        );
      }
    }

    if (allowWallDrag || allowWallSelect) {
      final wall = _hitTestWall(canvasPoint);

      if (wall != null) {
        final type = allowWallDrag && !_isShiftPressed
            ? FloorPlanIntentType.dragWall
            : FloorPlanIntentType.selectWall;

        return FloorPlanIntent(
          type: type,
          canvasPoint: canvasPoint,
          wall: wall,
          debugLabel: type == FloorPlanIntentType.dragWall
              ? 'Drag wall with topology'
              : 'Select wall',
          isSmartIntent: true,
          priority: 850,
        );
      }
    }

    if (allowRoomSelect) {
      final room = _hitTestRoomBody(canvasPoint);

      if (room != null) {
        return FloorPlanIntent(
          type: FloorPlanIntentType.selectRoom,
          canvasPoint: canvasPoint,
          room: room,
          debugLabel: 'Select room',
          isSmartIntent: true,
          priority: 840,
        );
      }
    }

    return null;
  }
}