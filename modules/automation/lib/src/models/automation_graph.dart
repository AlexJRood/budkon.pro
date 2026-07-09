import 'package:flutter/material.dart';

class AutomationGraph {
  final int version;
  final List<AutomationGraphNode> nodes;
  final List<AutomationGraphEdge> edges;

  const AutomationGraph({
    this.version = 1,
    this.nodes = const [],
    this.edges = const [],
  });

  factory AutomationGraph.empty() => const AutomationGraph();

  factory AutomationGraph.fromJson(Map<String, dynamic>? json) {
    if (json == null) return AutomationGraph.empty();

    return AutomationGraph(
      version: (json['version'] as num?)?.toInt() ?? 1,
      nodes: (json['nodes'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => AutomationGraphNode.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      edges: (json['edges'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => AutomationGraphEdge.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'nodes': nodes.map((item) => item.toJson()).toList(),
      'edges': edges.map((item) => item.toJson()).toList(),
    };
  }

  AutomationGraph copyWith({
    int? version,
    List<AutomationGraphNode>? nodes,
    List<AutomationGraphEdge>? edges,
  }) {
    return AutomationGraph(
      version: version ?? this.version,
      nodes: nodes ?? this.nodes,
      edges: edges ?? this.edges,
    );
  }

  AutomationGraphNode? nodeById(String id) {
    for (final node in nodes) {
      if (node.id == id) return node;
    }
    return null;
  }
}

class AutomationGraphNode {
  final String id;
  final String type;
  final Offset position;
  final Map<String, dynamic> data;

  const AutomationGraphNode({
    required this.id,
    required this.type,
    required this.position,
    this.data = const {},
  });

  String get label => (data['label'] as String?)?.trim().isNotEmpty == true
      ? data['label'] as String
      : type;

  factory AutomationGraphNode.fromJson(Map<String, dynamic> json) {
    final position = Map<String, dynamic>.from(json['position'] as Map? ?? const {});

    return AutomationGraphNode(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'action',
      position: Offset(
        (position['x'] as num?)?.toDouble() ?? 0,
        (position['y'] as num?)?.toDouble() ?? 0,
      ),
      data: Map<String, dynamic>.from(json['data'] as Map? ?? const {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'position': {
        'x': position.dx,
        'y': position.dy,
      },
      'data': data,
    };
  }

  AutomationGraphNode copyWith({
    String? id,
    String? type,
    Offset? position,
    Map<String, dynamic>? data,
  }) {
    return AutomationGraphNode(
      id: id ?? this.id,
      type: type ?? this.type,
      position: position ?? this.position,
      data: data ?? this.data,
    );
  }
}

class AutomationGraphEdge {
  final String id;
  final String source;
  final String target;
  final String? sourceHandle;
  final String? targetHandle;

  const AutomationGraphEdge({
    required this.id,
    required this.source,
    required this.target,
    this.sourceHandle,
    this.targetHandle,
  });

  factory AutomationGraphEdge.fromJson(Map<String, dynamic> json) {
    return AutomationGraphEdge(
      id: json['id']?.toString() ?? '',
      source: json['source']?.toString() ?? '',
      target: json['target']?.toString() ?? '',
      sourceHandle: json['sourceHandle']?.toString(),
      targetHandle: json['targetHandle']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'source': source,
      'target': target,
      if (sourceHandle != null) 'sourceHandle': sourceHandle,
      if (targetHandle != null) 'targetHandle': targetHandle,
    };
  }
}
