import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/automation_graph.dart';

class AutomationCanvasState {
  final AutomationGraph graph;
  final String? selectedNodeId;
  final Set<String> selectedNodeIds;
  final String? selectedEdgeId;
  final String? connectingFromNodeId;
  final String? connectingSourceHandle;
  final Offset? connectionPreviewStart;
  final Offset? connectionPreviewEnd;
  final String? reconnectingEdgeId;
  final String reconnectingMode;
  final AutomationGraph? clipboard;
  final List<AutomationGraph> undoStack;
  final List<AutomationGraph> redoStack;
  final bool snapToGrid;
  final double gridSize;
  final bool showGrid;

  const AutomationCanvasState({
    required this.graph,
    this.selectedNodeId,
    this.selectedNodeIds = const {},
    this.selectedEdgeId,
    this.connectingFromNodeId,
    this.connectingSourceHandle,
    this.connectionPreviewStart,
    this.connectionPreviewEnd,
    this.reconnectingEdgeId,
    this.reconnectingMode = '',
    this.clipboard,
    this.undoStack = const [],
    this.redoStack = const [],
    this.snapToGrid = true,
    this.gridSize = 24,
    this.showGrid = true,
  });

  bool get hasSelection => selectedNodeIds.isNotEmpty || selectedEdgeId != null;
  bool get hasClipboard => clipboard != null && clipboard!.nodes.isNotEmpty;
  bool get canUndo => undoStack.isNotEmpty;
  bool get canRedo => redoStack.isNotEmpty;
  bool get isConnecting => connectingFromNodeId != null;
  bool get isReconnectingEdge => reconnectingEdgeId != null;

  AutomationGraphNode? get singleSelectedNode {
    if (selectedNodeIds.length != 1) return null;
    return graph.nodeById(selectedNodeIds.first);
  }

  AutomationGraphEdge? get selectedEdge {
    final edgeId = selectedEdgeId;
    if (edgeId == null || edgeId.isEmpty) return null;

    for (final edge in graph.edges) {
      if (edge.id == edgeId) return edge;
    }

    return null;
  }

  AutomationGraphEdge? get reconnectingEdge {
    final edgeId = reconnectingEdgeId;
    if (edgeId == null || edgeId.isEmpty) return null;

    for (final edge in graph.edges) {
      if (edge.id == edgeId) return edge;
    }

    return null;
  }

  AutomationCanvasState copyWith({
    AutomationGraph? graph,
    Object? selectedNodeId = _sentinel,
    Set<String>? selectedNodeIds,
    Object? selectedEdgeId = _sentinel,
    Object? connectingFromNodeId = _sentinel,
    Object? connectingSourceHandle = _sentinel,
    Object? connectionPreviewStart = _sentinel,
    Object? connectionPreviewEnd = _sentinel,
    Object? reconnectingEdgeId = _sentinel,
    Object? reconnectingMode = _sentinel,
    Object? clipboard = _sentinel,
    List<AutomationGraph>? undoStack,
    List<AutomationGraph>? redoStack,
    bool? snapToGrid,
    double? gridSize,
    bool? showGrid,
  }) {
    final nextSelectedNodeIds = selectedNodeIds ?? this.selectedNodeIds;
    final nextSelectedNodeId = selectedNodeId == _sentinel
        ? (nextSelectedNodeIds.length == 1 ? nextSelectedNodeIds.first : this.selectedNodeId)
        : selectedNodeId as String?;

    return AutomationCanvasState(
      graph: graph ?? this.graph,
      selectedNodeId: nextSelectedNodeId,
      selectedNodeIds: nextSelectedNodeIds,
      selectedEdgeId: selectedEdgeId == _sentinel ? this.selectedEdgeId : selectedEdgeId as String?,
      connectingFromNodeId:
          connectingFromNodeId == _sentinel ? this.connectingFromNodeId : connectingFromNodeId as String?,
      connectingSourceHandle:
          connectingSourceHandle == _sentinel ? this.connectingSourceHandle : connectingSourceHandle as String?,
      connectionPreviewStart:
          connectionPreviewStart == _sentinel ? this.connectionPreviewStart : connectionPreviewStart as Offset?,
      connectionPreviewEnd:
          connectionPreviewEnd == _sentinel ? this.connectionPreviewEnd : connectionPreviewEnd as Offset?,
      reconnectingEdgeId:
          reconnectingEdgeId == _sentinel ? this.reconnectingEdgeId : reconnectingEdgeId as String?,
      reconnectingMode:
          reconnectingMode == _sentinel ? this.reconnectingMode : reconnectingMode as String,
      clipboard: clipboard == _sentinel ? this.clipboard : clipboard as AutomationGraph?,
      undoStack: undoStack ?? this.undoStack,
      redoStack: redoStack ?? this.redoStack,
      snapToGrid: snapToGrid ?? this.snapToGrid,
      gridSize: gridSize ?? this.gridSize,
      showGrid: showGrid ?? this.showGrid,
    );
  }

  static const _sentinel = Object();
}

class AutomationCanvasController extends StateNotifier<AutomationCanvasState> {
  AutomationCanvasController(AutomationGraph graph) : super(AutomationCanvasState(graph: graph));

  int _pasteCounter = 0;

  String _id(String prefix) => '${prefix}_${DateTime.now().microsecondsSinceEpoch}';

  Map<String, dynamic> _deepData(Map<String, dynamic> data) {
    if (data.isEmpty) return <String, dynamic>{};
    return Map<String, dynamic>.from(jsonDecode(jsonEncode(data)) as Map);
  }

  Offset _snap(Offset value) {
    final size = state.gridSize <= 1 ? 1.0 : state.gridSize;
    return Offset((value.dx / size).roundToDouble() * size, (value.dy / size).roundToDouble() * size);
  }

  void _commit(AutomationGraph graph, {bool trackHistory = true, bool clearRedo = true}) {
    if (!trackHistory || graph == state.graph) {
      state = state.copyWith(graph: graph);
      return;
    }

    final undo = [...state.undoStack, state.graph];
    final trimmedUndo = undo.length > 80 ? undo.sublist(undo.length - 80) : undo;
    state = state.copyWith(graph: graph, undoStack: trimmedUndo, redoStack: clearRedo ? const [] : state.redoStack);
  }

  AutomationGraphEdge? _edgeById(String? edgeId) {
    if (edgeId == null || edgeId.isEmpty) return null;

    for (final edge in state.graph.edges) {
      if (edge.id == edgeId) return edge;
    }

    return null;
  }

  void replaceGraph(AutomationGraph graph, {bool resetHistory = true}) {
    state = AutomationCanvasState(
      graph: graph,
      snapToGrid: state.snapToGrid,
      gridSize: state.gridSize,
      showGrid: state.showGrid,
      clipboard: state.clipboard,
      undoStack: resetHistory ? const [] : state.undoStack,
      redoStack: resetHistory ? const [] : state.redoStack,
    );
  }

  void toggleGrid() => state = state.copyWith(showGrid: !state.showGrid);
  void toggleSnap() => state = state.copyWith(snapToGrid: !state.snapToGrid);

  void selectNode(String? nodeId, {bool additive = false}) {
    if (nodeId == null) {
      clearSelection();
      return;
    }

    if (!additive) {
      state = state.copyWith(
        selectedNodeId: nodeId,
        selectedNodeIds: {nodeId},
        selectedEdgeId: null,
      );
      return;
    }

    final selected = {...state.selectedNodeIds};
    selected.contains(nodeId) ? selected.remove(nodeId) : selected.add(nodeId);

    state = state.copyWith(
      selectedNodeId: selected.length == 1 ? selected.first : null,
      selectedNodeIds: selected,
      selectedEdgeId: null,
    );
  }

  void selectEdge(String? edgeId) {
    state = state.copyWith(
      selectedNodeId: null,
      selectedNodeIds: const {},
      selectedEdgeId: edgeId,
      connectingFromNodeId: null,
      connectingSourceHandle: null,
      connectionPreviewStart: null,
      connectionPreviewEnd: null,
      reconnectingEdgeId: null,
      reconnectingMode: '',
    );
  }

  void clearSelection() {
    state = state.copyWith(
      selectedNodeId: null,
      selectedNodeIds: const {},
      selectedEdgeId: null,
    );
  }

  void selectAll() {
    state = state.copyWith(
      selectedNodeId: null,
      selectedNodeIds: state.graph.nodes.map((node) => node.id).toSet(),
      selectedEdgeId: null,
    );
  }

  void selectNodesInRect(Rect rect, {bool replace = true}) {
    final ids = state.graph.nodes
        .where((node) => rect.overlaps(Rect.fromLTWH(node.position.dx, node.position.dy, 250, 92)))
        .map((node) => node.id)
        .toSet();

    if (!replace) ids.addAll(state.selectedNodeIds);

    state = state.copyWith(
      selectedNodeId: ids.length == 1 ? ids.first : null,
      selectedNodeIds: ids,
      selectedEdgeId: null,
    );
  }

  void beginNodeDrag(String nodeId, {bool duplicateOnDrag = false, bool additive = false}) {
    if (!state.selectedNodeIds.contains(nodeId)) selectNode(nodeId, additive: additive);
    if (duplicateOnDrag) duplicateSelected(offset: Offset.zero);
  }

  void endNodeDrag() {
    if (state.snapToGrid) snapSelectedToGrid();
  }

  void startConnection(String nodeId, {String? sourceHandle, Offset? startPosition}) {
    state = state.copyWith(
      connectingFromNodeId: nodeId,
      connectingSourceHandle: sourceHandle,
      connectionPreviewStart: startPosition,
      connectionPreviewEnd: startPosition,
      selectedEdgeId: null,
      reconnectingEdgeId: null,
      reconnectingMode: '',
    );
  }

  void startEdgeTargetReconnect(
    String edgeId, {
    Offset? previewStart,
    Offset? previewEnd,
  }) {
    final edge = _edgeById(edgeId);
    if (edge == null) return;

    state = state.copyWith(
      selectedNodeId: null,
      selectedNodeIds: const {},
      selectedEdgeId: edgeId,
      connectingFromNodeId: edge.source,
      connectingSourceHandle: edge.sourceHandle,
      connectionPreviewStart: previewStart,
      connectionPreviewEnd: previewEnd ?? previewStart,
      reconnectingEdgeId: edgeId,
      reconnectingMode: 'target',
    );
  }

  void updateConnectionPreview(Offset scenePoint) {
    if (state.connectingFromNodeId == null && !state.isReconnectingEdge) return;
    state = state.copyWith(connectionPreviewEnd: scenePoint);
  }

  void cancelConnection() {
    state = state.copyWith(
      connectingFromNodeId: null,
      connectingSourceHandle: null,
      connectionPreviewStart: null,
      connectionPreviewEnd: null,
      reconnectingEdgeId: null,
      reconnectingMode: '',
    );
  }

  void finishConnection(String targetNodeId, {String? targetHandle}) {
    final source = state.connectingFromNodeId;
    if (source == null || source == targetNodeId) {
      cancelConnection();
      return;
    }

    final reconnectingEdgeId = state.reconnectingEdgeId;
    final reconnectingMode = state.reconnectingMode;

    final exists = state.graph.edges.any((edge) =>
        edge.id != reconnectingEdgeId &&
        edge.source == source &&
        edge.target == targetNodeId &&
        edge.sourceHandle == state.connectingSourceHandle &&
        edge.targetHandle == targetHandle);

    if (exists) {
      cancelConnection();
      return;
    }

    if (reconnectingEdgeId != null && reconnectingMode == 'target') {
      final edges = state.graph.edges.map((edge) {
        if (edge.id != reconnectingEdgeId) return edge;

        return AutomationGraphEdge(
          id: edge.id,
          source: source,
          target: targetNodeId,
          sourceHandle: edge.sourceHandle ?? state.connectingSourceHandle,
          targetHandle: targetHandle ?? edge.targetHandle,
        );
      }).toList();

      _commit(state.graph.copyWith(edges: edges));

      state = state.copyWith(
        selectedEdgeId: reconnectingEdgeId,
        connectingFromNodeId: null,
        connectingSourceHandle: null,
        connectionPreviewStart: null,
        connectionPreviewEnd: null,
        reconnectingEdgeId: null,
        reconnectingMode: '',
      );
      return;
    }

    final edge = AutomationGraphEdge(
      id: _id('edge'),
      source: source,
      target: targetNodeId,
      sourceHandle: state.connectingSourceHandle,
      targetHandle: targetHandle,
    );

    _commit(state.graph.copyWith(edges: [...state.graph.edges, edge]));

    state = state.copyWith(
      selectedNodeId: null,
      selectedNodeIds: const {},
      selectedEdgeId: edge.id,
      connectingFromNodeId: null,
      connectingSourceHandle: null,
      connectionPreviewStart: null,
      connectionPreviewEnd: null,
      reconnectingEdgeId: null,
      reconnectingMode: '',
    );
  }

  void addNode({required String type, required Offset position, required Map<String, dynamic> data}) {
    final node = AutomationGraphNode(
      id: _id(type),
      type: type,
      position: state.snapToGrid ? _snap(position) : position,
      data: _deepData(data),
    );

    _commit(state.graph.copyWith(nodes: [...state.graph.nodes, node]));

    state = state.copyWith(
      selectedNodeId: node.id,
      selectedNodeIds: {node.id},
      selectedEdgeId: null,
    );
  }

  void moveNode(String nodeId, Offset delta) {
    if (!state.selectedNodeIds.contains(nodeId)) selectNode(nodeId);
    moveSelectedNodes(delta);
  }

  void moveSelectedNodes(Offset delta) {
    if (state.selectedNodeIds.isEmpty) return;

    final selected = state.selectedNodeIds;
    final nodes = state.graph.nodes.map((node) {
      if (!selected.contains(node.id)) return node;
      return node.copyWith(position: node.position + delta);
    }).toList();

    _commit(state.graph.copyWith(nodes: nodes), trackHistory: false);
  }

  void nudgeSelected(Offset delta) {
    if (state.selectedNodeIds.isEmpty) return;

    final selected = state.selectedNodeIds;
    final nodes = state.graph.nodes.map((node) {
      if (!selected.contains(node.id)) return node;
      final next = node.position + delta;
      return node.copyWith(position: state.snapToGrid ? _snap(next) : next);
    }).toList();

    _commit(state.graph.copyWith(nodes: nodes));
  }

  void snapSelectedToGrid() {
    if (state.selectedNodeIds.isEmpty) return;

    final selected = state.selectedNodeIds;
    final nodes = state.graph.nodes.map((node) {
      if (!selected.contains(node.id)) return node;
      return node.copyWith(position: _snap(node.position));
    }).toList();

    _commit(state.graph.copyWith(nodes: nodes));
  }

  void updateNodeData(String nodeId, Map<String, dynamic> data) {
    final nodes = state.graph.nodes.map((node) {
      if (node.id != nodeId) return node;
      return node.copyWith(data: _deepData(data));
    }).toList();

    _commit(state.graph.copyWith(nodes: nodes));
  }

  void deleteNode(String nodeId) {
    final nextSelection = {...state.selectedNodeIds}..remove(nodeId);

    _commit(state.graph.copyWith(
      nodes: state.graph.nodes.where((node) => node.id != nodeId).toList(),
      edges: state.graph.edges.where((edge) => edge.source != nodeId && edge.target != nodeId).toList(),
    ));

    state = state.copyWith(
      selectedNodeId: nextSelection.length == 1 ? nextSelection.first : null,
      selectedNodeIds: nextSelection,
      selectedEdgeId: null,
    );
  }

  void deleteEdge(String edgeId) {
    _commit(state.graph.copyWith(edges: state.graph.edges.where((edge) => edge.id != edgeId).toList()));

    if (state.selectedEdgeId == edgeId || state.reconnectingEdgeId == edgeId) {
      state = state.copyWith(
        selectedEdgeId: null,
        reconnectingEdgeId: null,
        reconnectingMode: '',
        connectingFromNodeId: null,
        connectingSourceHandle: null,
        connectionPreviewStart: null,
        connectionPreviewEnd: null,
      );
    }
  }

  void deleteSelectedEdge() {
    final edgeId = state.selectedEdgeId;
    if (edgeId == null) return;
    deleteEdge(edgeId);
  }

  void deleteSelection() {
    if (!state.hasSelection) return;

    final selectedNodes = state.selectedNodeIds;
    final selectedEdge = state.selectedEdgeId;

    _commit(state.graph.copyWith(
      nodes: state.graph.nodes.where((node) => !selectedNodes.contains(node.id)).toList(),
      edges: state.graph.edges.where((edge) {
        if (selectedEdge != null && edge.id == selectedEdge) return false;
        return !selectedNodes.contains(edge.source) && !selectedNodes.contains(edge.target);
      }).toList(),
    ));

    clearSelection();
  }

  void copySelected() {
    final selected = state.selectedNodeIds;
    if (selected.isEmpty) return;

    final nodes = state.graph.nodes.where((node) => selected.contains(node.id)).toList();
    final edges = state.graph.edges.where((edge) => selected.contains(edge.source) && selected.contains(edge.target)).toList();

    state = state.copyWith(
      clipboard: AutomationGraph(
        version: state.graph.version,
        nodes: nodes.map((node) => node.copyWith(data: _deepData(node.data))).toList(),
        edges: [...edges],
      ),
    );
  }

  void cutSelected() {
    copySelected();
    deleteSelection();
  }

  void pasteClipboard({Offset offset = const Offset(48, 48)}) {
    final clipboard = state.clipboard;
    if (clipboard == null || clipboard.nodes.isEmpty) return;

    _pasteCounter += 1;
    final multiplier = _pasteCounter.toDouble().clamp(1.0, 6.0).toDouble();
    final pasteOffset = offset * multiplier;

    final idMap = <String, String>{};
    final copiedNodes = clipboard.nodes.map((node) {
      final newId = _id(node.type);
      idMap[node.id] = newId;
      final nextPosition = node.position + pasteOffset;

      return node.copyWith(
        id: newId,
        position: state.snapToGrid ? _snap(nextPosition) : nextPosition,
        data: {..._deepData(node.data), 'label': '${node.label} copy'},
      );
    }).toList();

    final copiedEdges = clipboard.edges
        .where((edge) => idMap.containsKey(edge.source) && idMap.containsKey(edge.target))
        .map((edge) => AutomationGraphEdge(
              id: _id('edge'),
              source: idMap[edge.source]!,
              target: idMap[edge.target]!,
              sourceHandle: edge.sourceHandle,
              targetHandle: edge.targetHandle,
            ))
        .toList();

    _commit(state.graph.copyWith(nodes: [...state.graph.nodes, ...copiedNodes], edges: [...state.graph.edges, ...copiedEdges]));

    final selected = copiedNodes.map((node) => node.id).toSet();

    state = state.copyWith(
      selectedNodeId: selected.length == 1 ? selected.first : null,
      selectedNodeIds: selected,
      selectedEdgeId: null,
    );
  }

  void duplicateSelected({Offset offset = const Offset(36, 36)}) {
    copySelected();
    pasteClipboard(offset: offset);
  }

  void undo() {
    if (state.undoStack.isEmpty) return;

    final previous = state.undoStack.last;
    final undo = [...state.undoStack]..removeLast();
    final redo = [...state.redoStack, state.graph];

    state = state.copyWith(
      graph: previous,
      undoStack: undo,
      redoStack: redo,
      selectedNodeId: null,
      selectedNodeIds: const {},
      selectedEdgeId: null,
      connectingFromNodeId: null,
      connectingSourceHandle: null,
      connectionPreviewStart: null,
      connectionPreviewEnd: null,
      reconnectingEdgeId: null,
      reconnectingMode: '',
    );
  }

  void redo() {
    if (state.redoStack.isEmpty) return;

    final next = state.redoStack.last;
    final redo = [...state.redoStack]..removeLast();
    final undo = [...state.undoStack, state.graph];

    state = state.copyWith(
      graph: next,
      undoStack: undo,
      redoStack: redo,
      selectedNodeId: null,
      selectedNodeIds: const {},
      selectedEdgeId: null,
      connectingFromNodeId: null,
      connectingSourceHandle: null,
      connectionPreviewStart: null,
      connectionPreviewEnd: null,
      reconnectingEdgeId: null,
      reconnectingMode: '',
    );
  }

  void alignSelectedLeft() {
    if (state.selectedNodeIds.length < 2) return;

    final selectedNodes = state.graph.nodes.where((node) => state.selectedNodeIds.contains(node.id)).toList();
    final minX = selectedNodes.map((node) => node.position.dx).reduce((a, b) => a < b ? a : b);

    final nodes = state.graph.nodes.map((node) {
      if (!state.selectedNodeIds.contains(node.id)) return node;
      return node.copyWith(position: Offset(minX, node.position.dy));
    }).toList();

    _commit(state.graph.copyWith(nodes: nodes));
  }

  void alignSelectedTop() {
    if (state.selectedNodeIds.length < 2) return;

    final selectedNodes = state.graph.nodes.where((node) => state.selectedNodeIds.contains(node.id)).toList();
    final minY = selectedNodes.map((node) => node.position.dy).reduce((a, b) => a < b ? a : b);

    final nodes = state.graph.nodes.map((node) {
      if (!state.selectedNodeIds.contains(node.id)) return node;
      return node.copyWith(position: Offset(node.position.dx, minY));
    }).toList();

    _commit(state.graph.copyWith(nodes: nodes));
  }

  void autoLayout() {
    final nodes = [...state.graph.nodes];
    if (nodes.isEmpty) return;

    final incoming = <String, int>{for (final node in nodes) node.id: 0};

    for (final edge in state.graph.edges) {
      incoming[edge.target] = (incoming[edge.target] ?? 0) + 1;
    }

    final layer = <String, int>{};
    final queue = nodes.where((node) => (incoming[node.id] ?? 0) == 0).map((node) => node.id).toList();

    for (final id in queue) {
      layer[id] = 0;
    }

    var guard = 0;
    while (queue.isNotEmpty && guard < 10000) {
      guard++;
      final id = queue.removeAt(0);
      final baseLayer = layer[id] ?? 0;

      for (final edge in state.graph.edges.where((edge) => edge.source == id)) {
        final nextLayer = baseLayer + 1;

        if ((layer[edge.target] ?? -1) < nextLayer) {
          layer[edge.target] = nextLayer;
          queue.add(edge.target);
        }
      }
    }

    final buckets = <int, List<AutomationGraphNode>>{};
    for (final node in nodes) {
      buckets.putIfAbsent(layer[node.id] ?? 0, () => []).add(node);
    }

    final laidOut = <AutomationGraphNode>[];
    for (final entry in buckets.entries) {
      final x = 120.0 + entry.key * 340.0;

      for (var i = 0; i < entry.value.length; i++) {
        laidOut.add(entry.value[i].copyWith(position: Offset(x, 120.0 + i * 150.0)));
      }
    }

    final byId = {for (final node in laidOut) node.id: node};
    _commit(state.graph.copyWith(nodes: nodes.map((node) => byId[node.id] ?? node).toList()));
  }
}

final automationCanvasControllerProvider = StateNotifierProvider.autoDispose
    .family<AutomationCanvasController, AutomationCanvasState, AutomationGraph>((ref, graph) {
  return AutomationCanvasController(graph);
});
