import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_saver/file_saver.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/text_field.dart';

import '../../generation/floor_plan_generation_models.dart';
import '../../models/floor_plan_document.dart';
import '../platform/floor_plan_export_file_opener.dart';

part 'floor_plan_canvas_types.dart';
part 'floor_plan_canvas_theme.dart';
part 'floor_plan_canvas_intent.dart';
part 'floor_plan_canvas_keyboard.dart';
part 'floor_plan_canvas_geometry.dart';
part 'floor_plan_canvas_selection.dart';
part 'floor_plan_canvas_events.dart';
part 'floor_plan_canvas_mutations.dart';
part 'floor_plan_canvas_toolbar.dart';
part 'floor_plan_canvas_inspectors.dart';
part 'floor_plan_canvas_painter.dart';
part 'floor_plan_canvas_helpers.dart';
part 'floor_plan_canvas_context_menu.dart';
part 'floor_plan_canvas_topology.dart';
part 'floor_plan_canvas_resize_and_fit.dart';
part 'floor_plan_canvas_navigation.dart';
part 'floor_plan_canvas_collaboration.dart';
part 'floor_plan_background_layer.dart';
part 'floor_plan_canvas_export.dart';
part 'floor_plan_export_service.dart';
part 'floor_plan_canvas_clipboard.dart';

class FloorPlanCanvas extends StatefulWidget {
  final FloorPlanDocument document;
  final ValueChanged<FloorPlanDocument> onChanged;

  final Future<void> Function()? onSave;
  final Future<void> Function()? onReload;
  final VoidCallback? onGeneratePlan;
  final VoidCallback? onOpen3d;

  final bool isSaving;
  final bool isDirty;
  final String? saveStatusLabel;

  final FloorPlanBackgroundImage? backgroundImage;

  final ValueChanged<FloorPlanCanvasSelectionSnapshot>? onSelectionChanged;

  final void Function({
    required String objectType,
    required String objectId,
  })? onAcquireObjectLock;

  final void Function({
    required String objectType,
    required String objectId,
  })? onReleaseObjectLock;

  final bool Function({
    required String objectType,
    required String objectId,
  })? isObjectLockedByOther;

  final String? Function({
    required String objectType,
    required String objectId,
  })? objectLockOwnerLabel;

  final void Function({
    required String objectType,
    required String objectId,
    String? ownerLabel,
  })? onLockedObjectTap;

  const FloorPlanCanvas({
    super.key,
    required this.document,
    required this.onChanged,
    this.onSave,
    this.onReload,
    this.onGeneratePlan,
    this.onOpen3d,
    this.isSaving = false,
    this.isDirty = false,
    this.saveStatusLabel,
    this.backgroundImage,
    this.onSelectionChanged,
    this.onAcquireObjectLock,
    this.onReleaseObjectLock,
    this.isObjectLockedByOther,
    this.objectLockOwnerLabel,
    this.onLockedObjectTap,
  });

  @override
  State<FloorPlanCanvas> createState() => _FloorPlanCanvasState();
}

class _FloorPlanCanvasState extends State<FloorPlanCanvas> {
  final TransformationController _transformationController =
      TransformationController();

  final FocusNode _focusNode = FocusNode(debugLabel: 'FloorPlanCanvasFocus');
  final GlobalKey _canvasViewportKey = GlobalKey();

  final TextEditingController _lengthEditorController =
      TextEditingController();
  final FocusNode _lengthEditorFocusNode =
      FocusNode(debugLabel: 'FloorPlanLengthEditorFocus');
  String? _editingLengthWallId;

  final TextEditingController _angleEditorController =
      TextEditingController();
  final FocusNode _angleEditorFocusNode =
      FocusNode(debugLabel: 'FloorPlanAngleEditorFocus');
  _CornerAngleLabelHit? _editingCornerAngle;

  final TextEditingController _roomNameEditorController =
      TextEditingController();
  final FocusNode _roomNameEditorFocusNode =
      FocusNode(debugLabel: 'FloorPlanRoomNameEditorFocus');
  String? _editingRoomId;

  static const double _minZoomScale = 0.03;
  static const double _maxZoomScale = 16.0;

  double _viewRotationDegrees = 0;

  OverlayEntry? _contextMenuEntry;

  DateTime? _lastPrimaryClickAt;
  Offset? _lastPrimaryClickCanvasPoint;

  _WallLineSnapHit? _pendingVertexWallSplitHit;

  FloorPlanTool _tool = FloorPlanTool.wall;
  FloorPlanAssetType _selectedAssetType = FloorPlanAssetType.sofa;

  _SelectedObject? _selectedObject;
  Set<String> _selectedWallIds = {};
  _SelectedVertex? _selectedVertex;

  

  /// Multi-vertex selection.
  ///
  /// Key format is `_cornerKey(point)`, so connected walls using the same
  /// physical corner are selected together.
  Set<String> _selectedVertexKeys = {};

  Offset? _wallStart;
  Offset? _wallPreviewEnd;

  bool _angleLockEnabled = true;
  double _angleStepDegrees = 90;
  double _angleSnapToleranceDegrees = 5;

  bool _continuousDrawingEnabled = true;
  bool _smartGuidesEnabled = true;
  bool _cornerAnglesVisible = true;
  bool _roomLabelsVisible = true;
  bool _roomAreasVisible = true;

  Offset? _continuousFirstPoint;
  int _continuousWallCount = 0;

  Offset? _selectionBoxStart;
  Offset? _selectionBoxEnd;
  bool _isBoxSelecting = false;

  _GuideSnapResult? _activeGuideSnap;
  _DetectedRoomCandidate? _hoveredRoomCandidate;

  bool _isDraggingHandle = false;
  List<_WallHandleHit> _draggingConnectedHandles = const [];

  /// Multi-vertex drag state.
  bool _isDraggingVertexGroup = false;
  Offset? _vertexGroupDragStartCanvasPoint;
  List<_VertexDragAnchor> _vertexDragAnchors = const [];

  /// Whole-wall drag state.
  bool _isDraggingWall = false;
  Offset? _wallDragStartCanvasPoint;
  Set<String> _draggingWallIds = {};
  List<_WallDragSnapshot> _wallDragSnapshots = const [];

  bool _isDraggingOpening = false;
  _OpeningHit? _draggingOpening;

  bool _isResizingOpening = false;
  _OpeningResizeHandleHit? _resizingOpeningHandle;

  bool _isDraggingAsset = false;
  String? _draggingAssetId;

  bool _isMiddleMousePanning = false;
  Offset? _lastMiddleMousePanGlobalPosition;

  // Touch gesture tracking — when ≥2 fingers are on screen the InteractiveViewer
  // handles pan/zoom natively; all tool actions are suppressed.
  int _activeTouchPointers = 0;
  bool get _isTouchGesturing => _activeTouchPointers >= 2;

  // When transitioning from 2-finger gesture to 1-finger, keep navigating
  // instead of triggering tool actions.
  bool _singleFingerNavigating = false;

  // Touch-hold gesture tracking (see _TouchHoldPurpose). Touch has no hover,
  // so a deliberate press-and-hold is used to enter vertex-drag / restart
  // drawing, while a quick tap or an immediate swipe keep their old meaning.
  Timer? _touchHoldTimer;
  _TouchHoldPurpose? _touchHoldPurpose;
  _WallHandleHit? _touchHoldHandle;
  Offset? _touchHoldStartGlobalPosition;
  Offset? _touchHoldStartCanvasPoint;
  int? _touchHoldPointerId;

  bool get _isTouchHoldPending => _touchHoldTimer != null;

  // Whether the tool's initial default has already been picked based on
  // layout (mobile defaults to Pan, desktop keeps the drawing-first default).
  bool _toolDefaultApplied = false;

  // Mobile inspector bottom sheet state.
  bool _mobileInspectorVisible = false;
  bool _isMobileLayout = false;

  // Trackpad pan-zoom gesture tracking (PointerPanZoomUpdateEvent).
  // Scale is cumulative since gesture start, so we track the last value to compute delta.
  double _trackpadGestureScale = 1.0;

  final List<FloorPlanDocument> _undoStack = [];
  final List<FloorPlanDocument> _redoStack = [];

  bool _dragHistoryPushed = false;

  String? _liveLockedObjectType;
  String? _liveLockedObjectId;



  List<_VertexDragAnchor> _wallDragVertexAnchors = const [];



  _FloorPlanClipboardData? _clipboard;
  int _pasteSerial = 0;

  bool _queuedContextMenuOpen = false;
  Offset? _queuedContextMenuGlobalPosition;
  Offset? _queuedContextMenuCanvasPoint;


  void _requestFocus() {
    if (_focusNode.hasFocus) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNode.requestFocus();
    });
  }

  void _resetInteractionStateForToolChange() {
    _wallStart = null;
    _wallPreviewEnd = null;

    _continuousFirstPoint = null;
    _continuousWallCount = 0;

    _isDraggingHandle = false;
    _isDraggingVertexGroup = false;
    _isDraggingWall = false;
    _isDraggingOpening = false;
    _isResizingOpening = false;
    _isDraggingAsset = false;
    _isMiddleMousePanning = false;
    _activeTouchPointers = 0;

    _draggingConnectedHandles = const [];

    _vertexGroupDragStartCanvasPoint = null;
    _vertexDragAnchors = const [];

    _wallDragStartCanvasPoint = null;
    _draggingWallIds = {};
    _wallDragSnapshots = const [];

    _draggingOpening = null;
    _resizingOpeningHandle = null;
    _draggingAssetId = null;
    _lastMiddleMousePanGlobalPosition = null;

    _pendingVertexWallSplitHit = null;

    _dragHistoryPushed = false;
    _activeGuideSnap = null;
    _hoveredRoomCandidate = null;

    _isBoxSelecting = false;
    _selectionBoxStart = null;
    _selectionBoxEnd = null;

    _singleFingerNavigating = false;
    _mobileInspectorVisible = false;

    _touchHoldTimer?.cancel();
    _touchHoldTimer = null;
    _touchHoldPurpose = null;
    _touchHoldHandle = null;
    _touchHoldStartGlobalPosition = null;
    _touchHoldStartCanvasPoint = null;
    _touchHoldPointerId = null;
  }

  @override
  void dispose() {
    _touchHoldTimer?.cancel();
    _hideContextMenu();
    _releaseCurrentLiveObjectLock();

    _lengthEditorController.dispose();
    _lengthEditorFocusNode.dispose();

    _angleEditorController.dispose();
    _angleEditorFocusNode.dispose();

    _roomNameEditorController.dispose();
    _roomNameEditorFocusNode.dispose();

    _transformationController.dispose();
    _queuedContextMenuOpen = false;
    _queuedContextMenuGlobalPosition = null;
    _queuedContextMenuCanvasPoint = null;
    _focusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedWall = _selectedWall;
    final selectedDoor = _selectedDoor;
    final selectedWindow = _selectedWindow;
    final selectedRoom = _selectedRoom;
    final selectedAsset = _selectedAsset;
    final selectedAngle = _angleBetweenSelectedWalls();

    final editingLengthWall = _editingLengthWall;
    final editingLengthPosition = editingLengthWall == null
        ? null
        : _wallLengthLabelViewportPosition(editingLengthWall);

    final editingAngle = _editingCornerAngle;
    final editingAnglePosition = editingAngle == null
        ? null
        : _canvasToViewportPosition(editingAngle.labelPosition);

    final editingRoom = _editingRoom;
    final editingRoomPosition =
        editingRoom == null ? null : _roomLabelViewportPosition(editingRoom);

    final isMobile = MediaQuery.of(context).size.width < 600;
    _isMobileLayout = isMobile;

    if (!_toolDefaultApplied) {
      _toolDefaultApplied = true;

      if (isMobile) {
        // Mobile users touch the canvas far more often to pan/inspect than
        // to draw, and drawing is one long-press away (see
        // _showContextMenuForLongPress) — so start in Pan rather than Wall.
        _tool = FloorPlanTool.pan;
      }
    }

    final body = Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Column(
        children: [
          _Toolbar(
            selectedTool: _tool,
            selectedAssetType: _selectedAssetType,
            isSaving: widget.isSaving,
            isDirty: widget.isDirty,
            saveStatusLabel: widget.saveStatusLabel,
            onSave: widget.onSave,
            onReload: widget.onReload,
            onGeneratePlan: widget.onGeneratePlan,
            onExport: _exportPlan,
            onOpen3d: widget.onOpen3d,
            angleLockEnabled: _angleLockEnabled,
            angleStepDegrees: _angleStepDegrees,
            continuousDrawingEnabled: _continuousDrawingEnabled,
            smartGuidesEnabled: _smartGuidesEnabled,
            cornerAnglesVisible: _cornerAnglesVisible,
            roomLabelsVisible: _roomLabelsVisible,
            roomAreasVisible: _roomAreasVisible,
            zoomScale: _currentScale,
            rotationDegrees: _viewRotationDegrees,
            canUndo: _undoStack.isNotEmpty,
            canRedo: _redoStack.isNotEmpty,
            onToolChanged: (tool) {
              _hideContextMenu();
              _hideLengthEditor();
              _hideAngleEditor();
              _hideRoomNameEditor();
              _requestFocus();

              setState(() {
                _tool = tool;
                _resetInteractionStateForToolChange();
              });
            },
            onAssetTypeChanged: (value) {
              _hideContextMenu();
              _requestFocus();

              setState(() {
                _selectedAssetType = value;
                _tool = FloorPlanTool.asset;
                _resetInteractionStateForToolChange();
              });
            },
            onAngleLockChanged: (value) {
              setState(() {
                _angleLockEnabled = value;
              });
            },
            onAngleStepChanged: (value) {
              if (value == null) return;

              setState(() {
                _angleStepDegrees = value;
              });
            },
            onContinuousDrawingChanged: (value) {
              setState(() {
                _continuousDrawingEnabled = value;

                if (!value) {
                  _continuousFirstPoint = null;
                  _continuousWallCount = 0;
                  _wallStart = null;
                  _wallPreviewEnd = null;
                  _activeGuideSnap = null;
                }
              });
            },
            onSmartGuidesChanged: (value) {
              setState(() {
                _smartGuidesEnabled = value;

                if (!value) {
                  _activeGuideSnap = null;
                }
              });
            },
            onCornerAnglesVisibleChanged: (value) {
              setState(() {
                _cornerAnglesVisible = value;
              });
            },
            onRoomLabelsVisibleChanged: (value) {
              setState(() {
                _roomLabelsVisible = value;
              });
            },
            onRoomAreasVisibleChanged: (value) {
              setState(() {
                _roomAreasVisible = value;
              });
            },
            onZoomIn: _zoomViewIn,
            onZoomOut: _zoomViewOut,
            onResetView: _resetViewTransform,
            onRotateLeft: _rotateViewLeft,
            onRotateRight: _rotateViewRight,
            onResetRotation: _resetViewRotation,
            onUndo: _undo,
            onRedo: _redo,
          ),
          Expanded(
            child: Consumer(
              builder: (context, ref, _) {
                final appTheme = ref.watch(themeColorsProvider);
                final canvasTheme = FloorPlanCanvasTheme.fromAppTheme(appTheme);

                return Container(
                  key: _canvasViewportKey,
                  color: canvasTheme.background,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: MouseRegion(
                          cursor: _isMiddleMousePanning
                              ? SystemMouseCursors.grabbing
                              : MouseCursor.defer,
                          onHover: _handlePointerHover,
                          child: GestureDetector(
                            onLongPressStart: _showContextMenuForLongPress,
                            child: Listener(
                            behavior: HitTestBehavior.opaque,
                            onPointerDown: _handlePointerDown,
                            onPointerMove: _handlePointerMove,
                            onPointerUp: _handlePointerUp,
                            onPointerCancel: _handlePointerCancel,
                            onPointerSignal: _handlePointerSignal,
                            onPointerPanZoomStart: _handlePointerPanZoomStart,
                            onPointerPanZoomUpdate: _handlePointerPanZoomUpdate,
                            onPointerPanZoomEnd: _handlePointerPanZoomEnd,
                            child: InteractiveViewer(
                              transformationController:
                                  _transformationController,
                              minScale: _minZoomScale,
                              maxScale: _maxZoomScale,
                              boundaryMargin:
                                  const EdgeInsets.all(double.infinity),
                              constrained: false,
                              panEnabled:
                                  _isTouchGesturing ||
                                  _tool == FloorPlanTool.pan,
                              scaleEnabled: _isTouchGesturing,
                              onInteractionUpdate: (_) {
                                if (!mounted) return;
                                setState(() {});
                              },
                              child: SizedBox(
                                width: widget.document.canvas.width,
                                height: widget.document.canvas.height,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    if (widget.backgroundImage != null)
                                      _FloorPlanBackgroundLayer(
                                        backgroundImage:
                                            widget.backgroundImage!,
                                      ),
                                    Positioned.fill(
                                      child: CustomPaint(
                                        painter: FloorPlanPainter(
                                          canvasTheme: canvasTheme,
                                          document: widget.document,
                                          previewStart: _wallStart,
                                          previewEnd: _wallPreviewEnd,
                                          previewIsVirtual:
                                              _tool ==
                                              FloorPlanTool.virtualWall,
                                          selectedObject: _selectedObject,
                                          selectedWallIds: _selectedWallIds,
                                          selectedVertex: _selectedVertex,
                                          selectedVertexKeys:
                                              _selectedVertexKeys,
                                          selectionRect:
                                              _currentSelectionRect(),
                                          guideSnap: _activeGuideSnap,
                                          hoveredRoomCandidate:
                                              _hoveredRoomCandidate,
                                          showCornerAngles:
                                              _cornerAnglesVisible,
                                          showRoomLabels: _roomLabelsVisible,
                                          showRoomAreas: _roomAreasVisible,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                      Positioned(
                        left: 16,
                        bottom: 16,
                        child: _CanvasHelpCard(tool: _tool),
                      ),
                      if (editingLengthWall != null &&
                          editingLengthPosition != null)
                        Positioned(
                          left: editingLengthPosition.dx - 58,
                          top: editingLengthPosition.dy - 22,
                          child: _InlineLengthEditor(
                            controller: _lengthEditorController,
                            focusNode: _lengthEditorFocusNode,
                            onSubmitted: _submitWallLengthEditor,
                            onCancel: _hideLengthEditor,
                          ),
                        ),
                      if (editingAngle != null && editingAnglePosition != null)
                        Positioned(
                          left: editingAnglePosition.dx - 48,
                          top: editingAnglePosition.dy - 22,
                          child: _InlineAngleEditor(
                            controller: _angleEditorController,
                            focusNode: _angleEditorFocusNode,
                            onSubmitted: _submitCornerAngleEditor,
                            onCancel: _hideAngleEditor,
                          ),
                        ),
                      if (editingRoom != null && editingRoomPosition != null)
                        Positioned(
                          left: editingRoomPosition.dx - 90,
                          top: editingRoomPosition.dy - 28,
                          child: _InlineRoomNameEditor(
                            controller: _roomNameEditorController,
                            focusNode: _roomNameEditorFocusNode,
                            onSubmitted: _submitRoomNameEditor,
                            onCancel: _hideRoomNameEditor,
                          ),
                        ),
                      if (selectedAngle != null)
                        Positioned(
                          top: 16,
                          left: 16,
                          child: _AngleBetweenWallsCard(angle: selectedAngle),
                        ),
                      if (!isMobile &&
                          selectedWall != null &&
                          _selectedWallIds.length <= 1 &&
                          _selectedVertex == null)
                        Positioned(
                          right: 16,
                          bottom: 16,
                          child: _WallInspector(
                            wall: selectedWall,
                            onWallKindChanged: _setSelectedWallKind,
                            pixelsPerMeter:
                                widget.document.scale.pixelsPerMeter,
                            currentAngleDeg: _wallAngleDegrees(selectedWall),
                            onLengthSubmitted: _setSelectedWallLengthM,
                            onThicknessSubmitted: _setSelectedWallThickness,
                            onAngleSubmitted: _setSelectedWallAngleDeg,
                            onAngleLockChanged: _toggleSelectedWallAngleLock,
                            onLengthLockChanged: _toggleSelectedWallLengthLock,
                            onLockedLengthSubmitted:
                                _setSelectedWallLockedLengthM,
                            onAddDoorCenter: _addDoorToSelectedWallCenter,
                            onAddWindowCenter: _addWindowToSelectedWallCenter,
                            onDelete: _deleteSelectedObject,
                          ),
                        ),
                      if (!isMobile && selectedDoor != null)
                        Positioned(
                          right: 16,
                          bottom: 16,
                          child: _DoorInspector(
                            door: selectedDoor,
                            onChanged: _updateSelectedDoor,
                            onDelete: _deleteSelectedObject,
                          ),
                        ),
                      if (!isMobile && selectedWindow != null)
                        Positioned(
                          right: 16,
                          bottom: 16,
                          child: _WindowInspector(
                            window: selectedWindow,
                            onChanged: _updateSelectedWindow,
                            onDelete: _deleteSelectedObject,
                          ),
                        ),
                      if (!isMobile && selectedRoom != null)
                        Positioned(
                          right: 16,
                          bottom: 16,
                          child: _RoomInspector(
                            room: selectedRoom,
                            areaM2: selectedRoom.areaM2(
                              widget.document.scale.pixelsPerMeter,
                            ),
                            onNameChanged: _renameSelectedRoom,
                            onDelete: _deleteSelectedObject,
                          ),
                        ),
                      if (!isMobile && selectedAsset != null)
                        Positioned(
                          right: 16,
                          bottom: 16,
                          child: _AssetInspector(
                            asset: selectedAsset,
                            onChanged: _updateSelectedAsset,
                            onAlignToNearestWall:
                                _alignSelectedAssetToNearestWall,
                            onDelete: _deleteSelectedObject,
                          ),
                        ),
                      if (isMobile && _mobileInspectorVisible) ...[
                        Positioned.fill(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => setState(
                              () => _mobileInspectorVisible = false,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: _MobileInspectorSheet(
                            onDismiss: () => setState(
                              () => _mobileInspectorVisible = false,
                            ),
                            child: selectedWall != null &&
                                    _selectedWallIds.length <= 1 &&
                                    _selectedVertex == null
                                ? _WallInspector(
                                    wall: selectedWall,
                                    onWallKindChanged: _setSelectedWallKind,
                                    pixelsPerMeter:
                                        widget.document.scale.pixelsPerMeter,
                                    currentAngleDeg:
                                        _wallAngleDegrees(selectedWall),
                                    onLengthSubmitted: _setSelectedWallLengthM,
                                    onThicknessSubmitted:
                                        _setSelectedWallThickness,
                                    onAngleSubmitted: _setSelectedWallAngleDeg,
                                    onAngleLockChanged:
                                        _toggleSelectedWallAngleLock,
                                    onLengthLockChanged:
                                        _toggleSelectedWallLengthLock,
                                    onLockedLengthSubmitted:
                                        _setSelectedWallLockedLengthM,
                                    onAddDoorCenter:
                                        _addDoorToSelectedWallCenter,
                                    onAddWindowCenter:
                                        _addWindowToSelectedWallCenter,
                                    onDelete: _deleteSelectedObject,
                                    flat: true,
                                  )
                                : selectedDoor != null
                                    ? _DoorInspector(
                                        door: selectedDoor,
                                        onChanged: _updateSelectedDoor,
                                        onDelete: _deleteSelectedObject,
                                        flat: true,
                                      )
                                    : selectedWindow != null
                                        ? _WindowInspector(
                                            window: selectedWindow,
                                            onChanged: _updateSelectedWindow,
                                            onDelete: _deleteSelectedObject,
                                            flat: true,
                                          )
                                        : selectedRoom != null
                                            ? _RoomInspector(
                                                room: selectedRoom,
                                                areaM2: selectedRoom.areaM2(
                                                  widget.document.scale
                                                      .pixelsPerMeter,
                                                ),
                                                onNameChanged:
                                                    _renameSelectedRoom,
                                                onDelete: _deleteSelectedObject,
                                                flat: true,
                                              )
                                            : selectedAsset != null
                                                ? _AssetInspector(
                                                    asset: selectedAsset,
                                                    onChanged:
                                                        _updateSelectedAsset,
                                                    onAlignToNearestWall:
                                                        _alignSelectedAssetToNearestWall,
                                                    onDelete:
                                                        _deleteSelectedObject,
                                                    flat: true,
                                                  )
                                                : const SizedBox.shrink(),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );

    if (!isMobile) return body;

    return Stack(
      children: [
        body,
        _MobileToolSheet(
          selectedTool: _tool,
          selectedAssetType: _selectedAssetType,
          isSaving: widget.isSaving,
          isDirty: widget.isDirty,
          saveStatusLabel: widget.saveStatusLabel,
          onSave: widget.onSave,
          onReload: widget.onReload,
          onGeneratePlan: widget.onGeneratePlan,
          onExport: _exportPlan,
          onOpen3d: widget.onOpen3d,
          angleLockEnabled: _angleLockEnabled,
          angleStepDegrees: _angleStepDegrees,
          continuousDrawingEnabled: _continuousDrawingEnabled,
          smartGuidesEnabled: _smartGuidesEnabled,
          cornerAnglesVisible: _cornerAnglesVisible,
          roomLabelsVisible: _roomLabelsVisible,
          roomAreasVisible: _roomAreasVisible,
          onToolChanged: (tool) {
            _hideContextMenu();
            _hideLengthEditor();
            _hideAngleEditor();
            _hideRoomNameEditor();
            _requestFocus();
            setState(() {
              _tool = tool;
              _resetInteractionStateForToolChange();
            });
          },
          onAssetTypeChanged: (value) {
            _hideContextMenu();
            _requestFocus();
            setState(() {
              _selectedAssetType = value;
              _tool = FloorPlanTool.asset;
              _resetInteractionStateForToolChange();
            });
          },
          onAngleLockChanged: (value) =>
              setState(() => _angleLockEnabled = value),
          onAngleStepChanged: (value) {
            if (value == null) return;
            setState(() => _angleStepDegrees = value);
          },
          onContinuousDrawingChanged: (value) {
            setState(() {
              _continuousDrawingEnabled = value;
              if (!value) {
                _continuousFirstPoint = null;
                _continuousWallCount = 0;
                _wallStart = null;
                _wallPreviewEnd = null;
                _activeGuideSnap = null;
              }
            });
          },
          onSmartGuidesChanged: (value) {
            setState(() {
              _smartGuidesEnabled = value;
              if (!value) _activeGuideSnap = null;
            });
          },
          onCornerAnglesVisibleChanged: (value) =>
              setState(() => _cornerAnglesVisible = value),
          onRoomLabelsVisibleChanged: (value) =>
              setState(() => _roomLabelsVisible = value),
          onRoomAreasVisibleChanged: (value) =>
              setState(() => _roomAreasVisible = value),
        ),
      ],
    );
  }
}
