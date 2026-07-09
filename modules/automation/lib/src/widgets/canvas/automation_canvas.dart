// NOTE:
// This file is the same AutomationCanvas as the drag/drop canvas patch,
// with one extra public callback:
//   final ValueChanged<Offset>? onCanvasDoubleTap;
// Double-clicking the canvas background calls it with the scene position.
//
// If your current AutomationCanvas already has all previous canvas pro features,
// you can alternatively copy only:
// - constructor field `onCanvasDoubleTap`
// - `_handleCanvasDoubleTapDown`
// - `onDoubleTapDown: _handleCanvasDoubleTapDown`

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';

import '../../models/automation_graph.dart';
import '../../providers/automation_canvas_controller.dart';
import 'automation_edge_painter.dart';
import 'automation_node_card.dart';
import 'automation_node_ports.dart';

class AutomationCanvas extends ConsumerStatefulWidget {
  final AutomationGraph initialGraph;
  final ValueChanged<AutomationGraph>? onGraphChanged;
  final ValueChanged<Offset>? onCanvasDoubleTap;

  const AutomationCanvas({
    super.key,
    required this.initialGraph,
    this.onGraphChanged,
    this.onCanvasDoubleTap,
  });

  @override
  ConsumerState<AutomationCanvas> createState() => _AutomationCanvasState();
}

class _AutomationCanvasState extends ConsumerState<AutomationCanvas> with SingleTickerProviderStateMixin {
  static const Size _canvasSize = Size(5000, 3500);
  static const Size _nodeSize = Size(250, 92);

  final FocusNode _focusNode = FocusNode(debugLabel: 'AutomationCanvasFocus');
  final TransformationController _transformationController = TransformationController();
  final GlobalKey _canvasKey = GlobalKey();

  late final AnimationController _edgePulseController;

  Offset? _lastConnectionScenePoint;
  Offset? _selectionStart;
  Rect? _selectionRect;
  Offset? _dropPreviewScenePoint;
  _NodeDropIntent? _dropPreviewIntent;
  bool _marqueeActive = false;
  bool _dragCandidateAccepted = false;

  AutoDisposeStateNotifierProvider<AutomationCanvasController, AutomationCanvasState> get _provider {
    return automationCanvasControllerProvider(widget.initialGraph);
  }

  AutomationCanvasController get _controller => ref.read(_provider.notifier);
  AutomationCanvasState get _canvasState => ref.read(_provider);

  @override
  void initState() {
    super.initState();
    _edgePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1250),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _edgePulseController.dispose();
    _focusNode.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  double get _scale => _transformationController.value.getMaxScaleOnAxis();

  Offset _sceneFromGlobal(Offset globalPosition) {
    final box = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return globalPosition;

    final local = box.globalToLocal(globalPosition);
    return _transformationController.toScene(local);
  }

  void _followCursorWithConnection(Offset globalPosition) {
    final canvasState = _canvasState;

    if (!canvasState.isConnecting && !canvasState.isReconnectingEdge) return;

    final scene = _sceneFromGlobal(globalPosition);
    _lastConnectionScenePoint = scene;
    _controller.updateConnectionPreview(scene);
  }

  Offset _nodeOutputPortScenePoint(AutomationGraphNode node, {String? sourceHandle}) {
    return AutomationNodePortResolver.outputPoint(node, sourceHandle: sourceHandle);
  }

  Offset _nodeInputPortScenePoint(AutomationGraphNode node, {String? targetHandle}) {
    return AutomationNodePortResolver.inputPoint(node, targetHandle: targetHandle);
  }

  AutomationGraphNode? _nodeAt(Offset scenePoint) {
    for (final node in _canvasState.graph.nodes.reversed) {
      final rect = Rect.fromLTWH(
        node.position.dx,
        node.position.dy,
        _nodeSize.width,
        AutomationNodePortResolver.visualHeight(node),
      );

      if (rect.contains(scenePoint)) return node;
    }

    return null;
  }

  AutomationGraphNode? _nodeById(String? id) {
    if (id == null || id.isEmpty) return null;

    for (final node in _canvasState.graph.nodes) {
      if (node.id == id) return node;
    }

    return null;
  }

  AutomationGraphEdge? _edgeById(String? id) {
    if (id == null || id.isEmpty) return null;

    for (final edge in _canvasState.graph.edges) {
      if (edge.id == id) return edge;
    }

    return null;
  }

  double _handleDistance(Offset start, Offset end) {
    final distance = (end.dx - start.dx).abs();
    return distance.clamp(80.0, 180.0).toDouble();
  }

  Offset _cubicPoint(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
    final mt = 1 - t;
    final a = mt * mt * mt;
    final b = 3 * mt * mt * t;
    final c = 3 * mt * t * t;
    final d = t * t * t;

    return Offset(
      a * p0.dx + b * p1.dx + c * p2.dx + d * p3.dx,
      a * p0.dy + b * p1.dy + c * p2.dy + d * p3.dy,
    );
  }

  double _distanceToSegment(Offset point, Offset a, Offset b) {
    final ab = b - a;
    final ap = point - a;
    final denominator = ab.dx * ab.dx + ab.dy * ab.dy;

    if (denominator == 0) return (point - a).distance;

    final t = ((ap.dx * ab.dx + ap.dy * ab.dy) / denominator).clamp(0.0, 1.0).toDouble();
    final projection = a + ab * t;

    return (point - projection).distance;
  }

  Offset? _edgeMidpoint(AutomationGraphEdge edge) {
    final source = _nodeById(edge.source);
    final target = _nodeById(edge.target);

    if (source == null || target == null) return null;

    final start = _nodeOutputPortScenePoint(source, sourceHandle: edge.sourceHandle);
    final end = _nodeInputPortScenePoint(target, targetHandle: edge.targetHandle);
    final handle = _handleDistance(start, end);

    return _cubicPoint(
      start,
      start + Offset(handle, 0),
      end - Offset(handle, 0),
      end,
      0.52,
    );
  }

  AutomationGraphEdge? _edgeAt(Offset scenePoint) {
    final tolerance = (16 / _scale).clamp(8.0, 28.0).toDouble();

    for (final edge in _canvasState.graph.edges.reversed) {
      final source = _nodeById(edge.source);
      final target = _nodeById(edge.target);

      if (source == null || target == null) continue;

      final start = _nodeOutputPortScenePoint(source, sourceHandle: edge.sourceHandle);
      final end = _nodeInputPortScenePoint(target, targetHandle: edge.targetHandle);
      final handle = _handleDistance(start, end);

      final c1 = start + Offset(handle, 0);
      final c2 = end - Offset(handle, 0);

      var previous = start;
      for (var i = 1; i <= 34; i++) {
        final t = i / 34.0;
        final current = _cubicPoint(start, c1, c2, end, t);
        final distance = _distanceToSegment(scenePoint, previous, current);

        if (distance <= tolerance) return edge;

        previous = current;
      }
    }

    return null;
  }

  bool _isCtrlPressed() {
    final keyboard = HardwareKeyboard.instance;
    return keyboard.isControlPressed || keyboard.isMetaPressed;
  }

  String _stringFromMap(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) continue;

      final text = value.toString().trim();
      if (text.isNotEmpty && text != 'null') return text;
    }

    return '';
  }

  Map<String, dynamic> _mapFromDynamic(dynamic value) {
    if (value is Map<String, dynamic>) return Map<String, dynamic>.from(value);
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  _NodeDropIntent? _dropIntentFrom(Object? raw) {
    if (raw == null) return null;

    if (raw is String) {
      final value = raw.trim();
      if (value.isEmpty) return null;

      return _NodeDropIntent(
        type: 'action',
        label: value,
        data: {
          'label': value,
          'action_key': value,
        },
      );
    }

    if (raw is! Map) return null;

    final map = Map<String, dynamic>.from(raw);
    final nestedData = _mapFromDynamic(map['data']);
    final merged = {
      ...map,
      ...nestedData,
    };

    var type = _stringFromMap(merged, [
      'node_type',
      'nodeType',
      'type',
      'kind',
      'category',
    ]).toLowerCase();

    final key = _stringFromMap(merged, [
      'action_key',
      'signal_key',
      'key',
      'id',
      'name',
      'label',
    ]);

    final label = _stringFromMap(merged, [
      'label',
      'name',
      'title',
      'key',
      'action_key',
      'signal_key',
    ]);

    final keyLower = key.toLowerCase();
    final labelLower = label.toLowerCase();

    if (type.isEmpty || type == 'node' || type == 'tool') {
      if (merged.containsKey('signal_key') || keyLower.contains('trigger') || keyLower.contains('signal')) {
        type = 'trigger';
      } else if (keyLower.contains('condition') || labelLower.contains('condition') || labelLower.contains('if')) {
        type = 'condition';
      } else if (keyLower.contains('switch') || labelLower.contains('switch')) {
        type = 'switch';
      } else if (keyLower.contains('delay') || labelLower.contains('delay')) {
        type = 'delay';
      } else if (keyLower.contains('approval') || labelLower.contains('approval')) {
        type = 'approval';
      } else if (keyLower.contains('ai') || labelLower.contains('ai') || keyLower.contains('prompt')) {
        type = 'ai_prompt';
      } else if (keyLower.contains('http') || keyLower.contains('api') || labelLower.contains('webhook')) {
        type = 'api';
      } else {
        type = 'action';
      }
    }

    if (type == 'signal') type = 'trigger';
    if (type == 'tool' || type == 'automation_action') type = 'action';
    if (type == 'ai' || type == 'prompt') type = 'ai_prompt';
    if (type == 'http_request' || type == 'webhook') type = 'api';

    final data = Map<String, dynamic>.from(nestedData);

    if (label.isNotEmpty) data.putIfAbsent('label', () => label);

    if (type == 'trigger') {
      data.putIfAbsent('signal_key', () => _stringFromMap(merged, ['signal_key', 'key', 'id']));
    } else if (type == 'action') {
      data.putIfAbsent('action_key', () => _stringFromMap(merged, ['action_key', 'key', 'id']));
    } else if (type == 'ai_prompt') {
      data.putIfAbsent('output_key', () => 'text');
    } else if (type == 'api') {
      data.putIfAbsent('method', () => 'POST');
      data.putIfAbsent('url', () => '');
    }

    return _NodeDropIntent(
      type: type.isEmpty ? 'action' : type,
      label: label.isEmpty ? type : label,
      data: data,
    );
  }

  void _previewPaletteDrop(DragTargetDetails<Object> details) {
    final intent = _dropIntentFrom(details.data);

    if (intent == null) {
      if (!_dragCandidateAccepted || _dropPreviewScenePoint != null) {
        setState(() {
          _dragCandidateAccepted = false;
          _dropPreviewScenePoint = null;
          _dropPreviewIntent = null;
        });
      }
      return;
    }

    final scene = _sceneFromGlobal(details.offset);

    setState(() {
      _dragCandidateAccepted = true;
      _dropPreviewScenePoint = scene;
      _dropPreviewIntent = intent;
    });
  }

  void _clearPaletteDropPreview() {
    if (!_dragCandidateAccepted && _dropPreviewScenePoint == null) return;

    setState(() {
      _dragCandidateAccepted = false;
      _dropPreviewScenePoint = null;
      _dropPreviewIntent = null;
    });
  }

  void _acceptPaletteDrop(DragTargetDetails<Object> details) {
    final intent = _dropIntentFrom(details.data);
    if (intent == null) {
      _clearPaletteDropPreview();
      return;
    }

    final scene = _sceneFromGlobal(details.offset);
    final position = scene - Offset(_nodeSize.width / 2, _nodeSize.height / 2);

    _controller.addNode(
      type: intent.type,
      position: position,
      data: {
        ...intent.data,
        if (!intent.data.containsKey('label')) 'label': intent.label,
      },
    );

    _clearPaletteDropPreview();
  }

  void _startConnectionFromNode(AutomationGraphNode node, {String sourceHandle = 'default'}) {
    _focusNode.requestFocus();

    final start = _nodeOutputPortScenePoint(node, sourceHandle: sourceHandle);

    _controller.startConnection(
      node.id,
      sourceHandle: sourceHandle,
      startPosition: start,
    );

    _controller.updateConnectionPreview(start + const Offset(72, 0));
  }

  void _finishConnectionToNode(AutomationGraphNode node, {String targetHandle = 'default'}) {
    _focusNode.requestFocus();

    if (!_canvasState.isConnecting) {
      _controller.selectNode(
        node.id,
        additive: HardwareKeyboard.instance.isShiftPressed || _isCtrlPressed(),
      );
      return;
    }

    _controller.updateConnectionPreview(_nodeInputPortScenePoint(node, targetHandle: targetHandle));
    _controller.finishConnection(node.id, targetHandle: targetHandle);
  }

  void _startSelectedEdgeReconnect(AutomationGraphEdge edge) {
    final source = _nodeById(edge.source);
    final target = _nodeById(edge.target);

    _controller.startEdgeTargetReconnect(
      edge.id,
      previewStart: source == null ? null : _nodeOutputPortScenePoint(source, sourceHandle: edge.sourceHandle),
      previewEnd: target == null ? null : _nodeInputPortScenePoint(target, targetHandle: edge.targetHandle),
    );
  }

  void _handleCanvasTapDown(TapDownDetails details) {
    _focusNode.requestFocus();

    final scene = _sceneFromGlobal(details.globalPosition);
    final edge = _edgeAt(scene);

    if (edge != null) {
      _controller.selectEdge(edge.id);
      return;
    }

    if (_canvasState.isConnecting) {
      _controller.cancelConnection();
      return;
    }

    _controller.clearSelection();
  }

  void _handleCanvasDoubleTapDown(TapDownDetails details) {
    _focusNode.requestFocus();

    if (widget.onCanvasDoubleTap == null) return;

    final scene = _sceneFromGlobal(details.globalPosition);

    if (_nodeAt(scene) != null) return;
    if (_edgeAt(scene) != null) return;

    widget.onCanvasDoubleTap?.call(scene);
  }

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final key = event.logicalKey;
    final controller = _controller;
    final ctrl = _isCtrlPressed();
    final shift = HardwareKeyboard.instance.isShiftPressed;

    if (ctrl && key == LogicalKeyboardKey.keyA) return controller.selectAll();
    if (ctrl && key == LogicalKeyboardKey.keyC) return controller.copySelected();
    if (ctrl && key == LogicalKeyboardKey.keyX) return controller.cutSelected();
    if (ctrl && key == LogicalKeyboardKey.keyV) return controller.pasteClipboard();
    if (ctrl && key == LogicalKeyboardKey.keyD) return controller.duplicateSelected();
    if (ctrl && key == LogicalKeyboardKey.keyZ && !shift) return controller.undo();

    if ((ctrl && key == LogicalKeyboardKey.keyY) || (ctrl && shift && key == LogicalKeyboardKey.keyZ)) {
      return controller.redo();
    }

    if (key == LogicalKeyboardKey.delete || key == LogicalKeyboardKey.backspace) {
      return controller.deleteSelection();
    }

    if (key == LogicalKeyboardKey.escape) {
      controller.cancelConnection();
      controller.clearSelection();
      _cancelMarquee();
      _clearPaletteDropPreview();
      return;
    }

    final step = shift ? 24.0 : 6.0;
    if (key == LogicalKeyboardKey.arrowLeft) controller.nudgeSelected(Offset(-step, 0));
    if (key == LogicalKeyboardKey.arrowRight) controller.nudgeSelected(Offset(step, 0));
    if (key == LogicalKeyboardKey.arrowUp) controller.nudgeSelected(Offset(0, -step));
    if (key == LogicalKeyboardKey.arrowDown) controller.nudgeSelected(Offset(0, step));
  }

  void _startMarquee(PointerDownEvent event) {
    if (!HardwareKeyboard.instance.isShiftPressed || event.buttons != kPrimaryMouseButton) return;

    final scene = _sceneFromGlobal(event.position);

    setState(() {
      _marqueeActive = true;
      _selectionStart = scene;
      _selectionRect = Rect.fromPoints(scene, scene);
    });

    _controller.selectNodesInRect(_selectionRect!);
  }

  void _updateMarquee(PointerMoveEvent event) {
    _followCursorWithConnection(event.position);

    if (!_marqueeActive || _selectionStart == null) return;

    final scene = _sceneFromGlobal(event.position);
    final rect = Rect.fromPoints(_selectionStart!, scene);

    setState(() => _selectionRect = rect);
    _controller.selectNodesInRect(rect);
  }

  void _endMarquee(PointerUpEvent event) => _cancelMarquee();

  void _cancelMarquee() {
    if (!_marqueeActive) return;

    setState(() {
      _marqueeActive = false;
      _selectionStart = null;
      _selectionRect = null;
    });
  }

  void _fitToContent() {
    final nodes = _canvasState.graph.nodes;
    if (nodes.isEmpty) return;

    var rect = Rect.fromLTWH(
      nodes.first.position.dx,
      nodes.first.position.dy,
      _nodeSize.width,
      _nodeSize.height,
    );

    for (final node in nodes.skip(1)) {
      rect = rect.expandToInclude(
        Rect.fromLTWH(
          node.position.dx,
          node.position.dy,
          _nodeSize.width,
          _nodeSize.height,
        ),
      );
    }

    final target = rect.inflate(220);
    final viewport = context.size ?? const Size(1200, 700);
    final scaleX = viewport.width / target.width;
    final scaleY = viewport.height / target.height;
    final safeScale = (scaleX < scaleY ? scaleX : scaleY).clamp(0.25, 1.4).toDouble();

    _transformationController.value = Matrix4.identity()
      ..translate(-target.left * safeScale + 24, -target.top * safeScale + 24)
      ..scale(safeScale);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);
    final canvasState = ref.watch(_provider);
    final controller = ref.read(_provider.notifier);
    final selectedEdge = _edgeById(canvasState.selectedEdgeId);
    final selectedEdgePoint = selectedEdge == null ? null : _edgeMidpoint(selectedEdge);

    ref.listen(_provider, (previous, next) {
      if (previous?.graph != next.graph) {
        widget.onGraphChanged?.call(next.graph);
      }
    });

    return DragTarget<Object>(
      onWillAcceptWithDetails: (details) => _dropIntentFrom(details.data) != null,
      onMove: _previewPaletteDrop,
      onLeave: (_) => _clearPaletteDropPreview(),
      onAcceptWithDetails: _acceptPaletteDrop,
      builder: (context, candidateData, rejectedData) {
        return KeyboardListener(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: _handleKey,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _focusNode.requestFocus,
            child: Container(
              color: theme.dashboardContainer.withValues(alpha: 0.27),
              child: Stack(
                children: [
                  InteractiveViewer(
                    key: _canvasKey,
                    transformationController: _transformationController,
                    constrained: false,
                    boundaryMargin: const EdgeInsets.all(3000),
                    minScale: 0.18,
                    maxScale: 2.6,
                    panEnabled: !_marqueeActive,
                    scaleEnabled: !_marqueeActive,
                    child: SizedBox(
                      width: _canvasSize.width,
                      height: _canvasSize.height,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Listener(
                              behavior: HitTestBehavior.translucent,
                              onPointerHover: (event) => _followCursorWithConnection(event.position),
                              onPointerDown: _startMarquee,
                              onPointerMove: _updateMarquee,
                              onPointerUp: _endMarquee,
                              onPointerCancel: (_) => _cancelMarquee(),
                              child: GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onTapDown: _handleCanvasTapDown,
                                onDoubleTapDown: _handleCanvasDoubleTapDown,
                                child: MouseRegion(
                                  cursor: canvasState.isConnecting
                                      ? SystemMouseCursors.precise
                                      : SystemMouseCursors.basic,
                                  onHover: (event) => _followCursorWithConnection(event.position),
                                  child: AnimatedBuilder(
                                    animation: _edgePulseController,
                                    builder: (context, _) {
                                      return CustomPaint(
                                        painter: AutomationEdgePainter(
                                          graph: canvasState.graph,
                                          theme: theme,
                                          selectedEdgeId: canvasState.selectedEdgeId,
                                          connectingFromNodeId: canvasState.connectingFromNodeId,
                                          connectionPreviewStart: canvasState.connectionPreviewStart,
                                          connectionPreviewEnd: canvasState.connectionPreviewEnd,
                                          showGrid: canvasState.showGrid,
                                          gridSize: canvasState.gridSize,
                                          selectionRect: _selectionRect,
                                          edgePulse: _edgePulseController.value,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                          for (final node in canvasState.graph.nodes)
                            Positioned(
                              left: node.position.dx,
                              top: node.position.dy,
                              child: AutomationNodeCard(
                                node: node,
                                theme: theme,
                                selected: canvasState.selectedNodeIds.contains(node.id),
                                multiSelected: canvasState.selectedNodeIds.length > 1 &&
                                    canvasState.selectedNodeIds.contains(node.id),
                                connecting: canvasState.connectingFromNodeId != null,
                                connectionSourceNodeId: canvasState.connectingFromNodeId,
                                onTap: () {
                                  _focusNode.requestFocus();
                                  controller.selectNode(
                                    node.id,
                                    additive: HardwareKeyboard.instance.isShiftPressed || _isCtrlPressed(),
                                  );
                                },
                                onDelete: () => controller.deleteNode(node.id),
                                onStartConnect: (sourceHandle) => _startConnectionFromNode(node, sourceHandle: sourceHandle),
                                onFinishConnect: () => _finishConnectionToNode(node),
                                onInputPortTap: () => _finishConnectionToNode(node),
                                onOutputPortTap: (sourceHandle) => _startConnectionFromNode(node, sourceHandle: sourceHandle),
                                onDragStart: (_) {
                                  _focusNode.requestFocus();
                                  controller.beginNodeDrag(
                                    node.id,
                                    duplicateOnDrag: HardwareKeyboard.instance.isAltPressed,
                                    additive: HardwareKeyboard.instance.isShiftPressed || _isCtrlPressed(),
                                  );
                                },
                                onDragUpdate: (details) {
                                  _followCursorWithConnection(details.globalPosition);
                                  controller.moveNode(node.id, details.delta / _scale);
                                },
                                onDragEnd: (_) => controller.endNodeDrag(),
                                onConnectionDragStart: (sourceHandle, details) {
                                  _focusNode.requestFocus();

                                  final scene = _sceneFromGlobal(details.globalPosition);
                                  _lastConnectionScenePoint = scene;

                                  controller.startConnection(
                                    node.id,
                                    sourceHandle: sourceHandle,
                                    startPosition: _nodeOutputPortScenePoint(node, sourceHandle: sourceHandle),
                                  );
                                },
                                onConnectionDragUpdate: (details) {
                                  final scene = _sceneFromGlobal(details.globalPosition);
                                  _lastConnectionScenePoint = scene;
                                  controller.updateConnectionPreview(scene);
                                },
                                onConnectionDragEnd: (_) {
                                  final scene = _lastConnectionScenePoint;
                                  if (scene == null) return controller.cancelConnection();

                                  final target = _nodeAt(scene);
                                  if (target == null) return controller.cancelConnection();

                                  controller.finishConnection(target.id, targetHandle: 'default');
                                  _lastConnectionScenePoint = null;
                                },
                                onDuplicate: controller.duplicateSelected,
                                onCopy: controller.copySelected,
                                onCut: controller.cutSelected,
                              ),
                            ),
                          if (_dropPreviewScenePoint != null && _dropPreviewIntent != null)
                            Positioned(
                              left: _dropPreviewScenePoint!.dx - _nodeSize.width / 2,
                              top: _dropPreviewScenePoint!.dy - _nodeSize.height / 2,
                              child: IgnorePointer(
                                child: _DropPreviewCard(
                                  theme: theme,
                                  intent: _dropPreviewIntent!,
                                  accepted: _dragCandidateAccepted,
                                ),
                              ),
                            ),
                          if (selectedEdge != null && selectedEdgePoint != null)
                            Positioned(
                              left: selectedEdgePoint.dx - 126,
                              top: selectedEdgePoint.dy - 72,
                              child: _EdgeFloatingToolbar(
                                theme: theme,
                                edge: selectedEdge,
                                reconnecting: canvasState.reconnectingEdgeId == selectedEdge.id,
                                onReconnectTarget: () => _startSelectedEdgeReconnect(selectedEdge),
                                onDelete: () => controller.deleteEdge(selectedEdge.id),
                                onClose: controller.clearSelection,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: _CanvasToolbar(
                      theme: theme,
                      state: canvasState,
                      onUndo: controller.undo,
                      onRedo: controller.redo,
                      onCopy: controller.copySelected,
                      onCut: controller.cutSelected,
                      onPaste: controller.pasteClipboard,
                      onDuplicate: controller.duplicateSelected,
                      onDelete: controller.deleteSelection,
                      onSelectAll: controller.selectAll,
                      onAutoLayout: controller.autoLayout,
                      onAlignLeft: controller.alignSelectedLeft,
                      onAlignTop: controller.alignSelectedTop,
                      onToggleGrid: controller.toggleGrid,
                      onToggleSnap: controller.toggleSnap,
                      onFit: _fitToContent,
                    ),
                  ),
                  if (_dragCandidateAccepted)
                    Positioned(
                      top: 74,
                      left: 12,
                      child: _DropModeHint(theme: theme),
                    ),
                  if (canvasState.isConnecting)
                    Positioned(
                      top: _dragCandidateAccepted ? 124 : 74,
                      left: 12,
                      child: _ConnectionModeHint(
                        theme: theme,
                        reconnecting: canvasState.isReconnectingEdge,
                        onCancel: controller.cancelConnection,
                      ),
                    ),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: _ShortcutHint(theme: theme),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NodeDropIntent {
  final String type;
  final String label;
  final Map<String, dynamic> data;

  const _NodeDropIntent({
    required this.type,
    required this.label,
    required this.data,
  });
}

class _DropPreviewCard extends StatelessWidget {
  final ThemeColors theme;
  final _NodeDropIntent intent;
  final bool accepted;

  const _DropPreviewCard({
    required this.theme,
    required this.intent,
    required this.accepted,
  });

  IconData get icon {
    switch (intent.type) {
      case 'trigger':
        return Icons.flash_on_rounded;
      case 'condition':
        return Icons.rule_rounded;
      case 'switch':
        return Icons.alt_route_rounded;
      case 'delay':
        return Icons.schedule_rounded;
      case 'approval':
        return Icons.verified_user_rounded;
      case 'ai_prompt':
        return Icons.auto_awesome_rounded;
      case 'api':
        return Icons.http_rounded;
      default:
        return Icons.play_circle_fill_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = accepted ? theme.themeColor : theme.dashboardBoarder;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 110),
      opacity: accepted ? 0.92 : 0.45,
      child: Container(
        width: 250,
        height: 94,
        decoration: BoxDecoration(
          color: theme.dashboardContainer.withValues(alpha: 0.90),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: accent.withValues(alpha: 0.82),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.22),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: accent, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                intent.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.textColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}

class _DropModeHint extends StatelessWidget {
  final ThemeColors theme;

  const _DropModeHint({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: theme.dashboardContainer.withValues(alpha: 0.95),
      borderRadius: BorderRadius.circular(16),
      elevation: 12,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          border: Border.all(color: theme.themeColor.withValues(alpha: 0.48)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_box_rounded, size: 18, color: theme.themeColor),
            const SizedBox(width: 8),
            Text(
              'Drop here to add this block exactly here',
              style: TextStyle(
                color: theme.textColor,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EdgeFloatingToolbar extends StatelessWidget {
  final ThemeColors theme;
  final AutomationGraphEdge edge;
  final bool reconnecting;
  final VoidCallback onReconnectTarget;
  final VoidCallback onDelete;
  final VoidCallback onClose;

  const _EdgeFloatingToolbar({
    required this.theme,
    required this.edge,
    required this.reconnecting,
    required this.onReconnectTarget,
    required this.onDelete,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    Widget action({
      required IconData icon,
      required String label,
      required VoidCallback onTap,
      Color? color,
    }) {
      final foreground = color ?? theme.textColor;

      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: foreground),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Material(
      color: theme.dashboardContainer.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(18),
      elevation: 16,
      shadowColor: Colors.black.withValues(alpha: 0.19),
      child: Container(
        constraints: const BoxConstraints(minWidth: 252),
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          border: Border.all(color: theme.themeColor.withValues(alpha: reconnecting ? 0.68 : 0.48)),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: theme.themeColor.withValues(alpha: reconnecting ? 0.16 : 0.09),
              blurRadius: 24,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: theme.themeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                reconnecting ? Icons.add_link_rounded : Icons.polyline_rounded,
                color: theme.themeColor,
                size: 16,
              ),
            ),
            const SizedBox(width: 6),
            action(
              icon: Icons.open_with_rounded,
              label: reconnecting ? 'Choose target' : 'Move arrow',
              onTap: onReconnectTarget,
              color: theme.themeColor,
            ),
            action(
              icon: Icons.delete_outline_rounded,
              label: 'Delete',
              onTap: onDelete,
              color: Colors.redAccent,
            ),
            InkWell(
              onTap: onClose,
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.all(7),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: theme.textColor.withValues(alpha: 0.57),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectionModeHint extends StatelessWidget {
  final ThemeColors theme;
  final bool reconnecting;
  final VoidCallback onCancel;

  const _ConnectionModeHint({
    required this.theme,
    required this.reconnecting,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: theme.dashboardContainer.withValues(alpha: 0.95),
      borderRadius: BorderRadius.circular(16),
      elevation: 12,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          border: Border.all(color: theme.themeColor.withValues(alpha: 0.48)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(reconnecting ? Icons.open_with_rounded : Icons.polyline_rounded, size: 18, color: theme.themeColor),
            const SizedBox(width: 8),
            Text(
              reconnecting
                  ? 'Move arrow: click input dot on the new target card'
                  : 'Connection mode: move cursor, then click input dot',
              style: TextStyle(
                color: theme.textColor,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: onCancel,
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.close_rounded, size: 16, color: theme.textColor.withValues(alpha: 0.59)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CanvasToolbar extends StatelessWidget {
  final ThemeColors theme;
  final AutomationCanvasState state;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onCopy;
  final VoidCallback onCut;
  final VoidCallback onPaste;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final VoidCallback onSelectAll;
  final VoidCallback onAutoLayout;
  final VoidCallback onAlignLeft;
  final VoidCallback onAlignTop;
  final VoidCallback onToggleGrid;
  final VoidCallback onToggleSnap;
  final VoidCallback onFit;

  const _CanvasToolbar({
    required this.theme,
    required this.state,
    required this.onUndo,
    required this.onRedo,
    required this.onCopy,
    required this.onCut,
    required this.onPaste,
    required this.onDuplicate,
    required this.onDelete,
    required this.onSelectAll,
    required this.onAutoLayout,
    required this.onAlignLeft,
    required this.onAlignTop,
    required this.onToggleGrid,
    required this.onToggleSnap,
    required this.onFit,
  });

  @override
  Widget build(BuildContext context) {
    Widget button({
      required IconData icon,
      required String tooltip,
      required VoidCallback? onPressed,
      bool active = false,
    }) {
      return Tooltip(
        message: tooltip,
        child: IconButton(
          visualDensity: VisualDensity.compact,
          iconSize: 18,
          onPressed: onPressed,
          color: active ? theme.themeColor : theme.textColor.withValues(alpha: onPressed == null ? 0.35 : 0.86),
          icon: Icon(icon),
        ),
      );
    }

    return Material(
      color: theme.dashboardContainer.withValues(alpha: 0.95),
      borderRadius: BorderRadius.circular(18),
      elevation: 14,
      shadowColor: Colors.black.withValues(alpha: 0.16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: theme.dashboardBoarder.withValues(alpha: 0.63)),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            button(icon: Icons.undo_rounded, tooltip: 'Undo · Ctrl+Z', onPressed: state.canUndo ? onUndo : null),
            button(icon: Icons.redo_rounded, tooltip: 'Redo · Ctrl+Y', onPressed: state.canRedo ? onRedo : null),
            const SizedBox(width: 4),
            button(icon: Icons.select_all_rounded, tooltip: 'Select all · Ctrl+A', onPressed: onSelectAll),
            button(icon: Icons.copy_rounded, tooltip: 'Copy · Ctrl+C', onPressed: state.hasSelection ? onCopy : null),
            button(icon: Icons.content_cut_rounded, tooltip: 'Cut · Ctrl+X', onPressed: state.hasSelection ? onCut : null),
            button(icon: Icons.content_paste_rounded, tooltip: 'Paste · Ctrl+V', onPressed: state.hasClipboard ? onPaste : null),
            button(icon: Icons.control_point_duplicate_rounded, tooltip: 'Duplicate · Ctrl+D / Alt+drag', onPressed: state.hasSelection ? onDuplicate : null),
            button(icon: Icons.delete_outline_rounded, tooltip: 'Delete', onPressed: state.hasSelection ? onDelete : null),
            const SizedBox(width: 4),
            button(icon: Icons.align_horizontal_left_rounded, tooltip: 'Align left', onPressed: state.selectedNodeIds.length > 1 ? onAlignLeft : null),
            button(icon: Icons.align_vertical_top_rounded, tooltip: 'Align top', onPressed: state.selectedNodeIds.length > 1 ? onAlignTop : null),
            button(icon: Icons.auto_fix_high_rounded, tooltip: 'Auto layout', onPressed: onAutoLayout),
            button(icon: Icons.center_focus_strong_rounded, tooltip: 'Fit to content', onPressed: onFit),
            const SizedBox(width: 4),
            button(icon: Icons.grid_4x4_rounded, tooltip: 'Grid', onPressed: onToggleGrid, active: state.showGrid),
            button(icon: Icons.grid_on_rounded, tooltip: 'Snap to grid', onPressed: onToggleSnap, active: state.snapToGrid),
          ],
        ),
      ),
    );
  }
}

class _ShortcutHint extends StatelessWidget {
  final ThemeColors theme;

  const _ShortcutHint({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: theme.dashboardContainer.withValues(alpha: 0.91),
      borderRadius: BorderRadius.circular(16),
      elevation: 10,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: theme.dashboardBoarder.withValues(alpha: 0.51)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          'Double-click background to add · Drag blocks from list onto canvas',
          style: TextStyle(
            color: theme.textColor.withValues(alpha: 0.61),
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
