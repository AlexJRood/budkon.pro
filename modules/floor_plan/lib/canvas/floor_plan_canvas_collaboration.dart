part of 'floor_plan_canvas.dart';

extension _FloorPlanCanvasCollaboration on _FloorPlanCanvasState {
  bool _isLiveLockedByOther({
    required String objectType,
    required String objectId,
  }) {
    return widget.isObjectLockedByOther?.call(
          objectType: objectType,
          objectId: objectId,
        ) ??
        false;
  }

  String? _liveLockOwnerLabel({
    required String objectType,
    required String objectId,
  }) {
    return widget.objectLockOwnerLabel?.call(
      objectType: objectType,
      objectId: objectId,
    );
  }

  bool _guardLiveLock({
    required String objectType,
    required String objectId,
  }) {
    if (!_isLiveLockedByOther(
      objectType: objectType,
      objectId: objectId,
    )) {
      return true;
    }

    widget.onLockedObjectTap?.call(
      objectType: objectType,
      objectId: objectId,
      ownerLabel: _liveLockOwnerLabel(
        objectType: objectType,
        objectId: objectId,
      ),
    );

    return false;
  }

  void _syncLiveLockForObject({
    required String objectType,
    required String objectId,
  }) {
    if (_liveLockedObjectType == objectType &&
        _liveLockedObjectId == objectId) {
      return;
    }

    _releaseCurrentLiveObjectLock();

    _liveLockedObjectType = objectType;
    _liveLockedObjectId = objectId;

    widget.onAcquireObjectLock?.call(
      objectType: objectType,
      objectId: objectId,
    );
  }

  void _releaseCurrentLiveObjectLock() {
    final objectType = _liveLockedObjectType;
    final objectId = _liveLockedObjectId;

    if (objectType == null || objectId == null) return;

    widget.onReleaseObjectLock?.call(
      objectType: objectType,
      objectId: objectId,
    );

    _liveLockedObjectType = null;
    _liveLockedObjectId = null;
  }

  void _emitLiveSelectionChanged() {
    widget.onSelectionChanged?.call(_currentLiveSelectionSnapshot());
  }

  FloorPlanCanvasSelectionSnapshot _currentLiveSelectionSnapshot() {
    final selected = _selectedObject;

    if (_selectedVertex != null) {
      return FloorPlanCanvasSelectionSnapshot(
        objectType: 'vertex',
        objectId: _vertexLiveObjectId(_selectedVertex!.point),
        wallIds: _selectedVertex!.connectedHandles
            .map((handle) => handle.wallId)
            .toSet()
            .toList(),
        extra: {
          'x': _selectedVertex!.point.dx,
          'y': _selectedVertex!.point.dy,
        },
      );
    }

    if (selected == null) {
      return const FloorPlanCanvasSelectionSnapshot();
    }

    return FloorPlanCanvasSelectionSnapshot(
      objectType: _selectedObjectTypeToLiveType(selected.type),
      objectId: selected.id,
      wallIds: _selectedWallIds.toList(),
    );
  }

  String _selectedObjectTypeToLiveType(_SelectedObjectType type) {
    switch (type) {
      case _SelectedObjectType.wall:
        return 'wall';
      case _SelectedObjectType.door:
        return 'door';
      case _SelectedObjectType.window:
        return 'window';
      case _SelectedObjectType.room:
        return 'room';
      case _SelectedObjectType.asset:
        return 'asset';
    }
  }

  String _vertexLiveObjectId(Offset point) {
    return '${point.dx.toStringAsFixed(2)}:${point.dy.toStringAsFixed(2)}';
  }

  void _clearLiveSelectionAndLock() {
    _releaseCurrentLiveObjectLock();

    widget.onSelectionChanged?.call(
      const FloorPlanCanvasSelectionSnapshot(),
    );
  }
}