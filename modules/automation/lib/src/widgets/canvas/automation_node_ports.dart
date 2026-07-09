import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/automation_graph.dart';

class AutomationNodePort {
  final String id;
  final String label;
  final String description;
  final IconData icon;
  final Color? color;

  const AutomationNodePort({
    required this.id,
    required this.label,
    this.description = '',
    this.icon = Icons.arrow_outward_rounded,
    this.color,
  });
}

class AutomationNodePortResolver {
  static const double nodeWidth = 250;
  static const double baseNodeHeight = 92;
  static const double outputStep = 34;
  static const double outputTopPadding = 38;

  static List<AutomationNodePort> inputPorts(AutomationGraphNode node) {
    return const [
      AutomationNodePort(
        id: 'default',
        label: 'Input',
        icon: Icons.radio_button_unchecked_rounded,
      ),
    ];
  }

  static List<AutomationNodePort> outputPorts(AutomationGraphNode node) {
    final data = node.data;

    final customOutputs = _portsFromList(data['outputs']);
    if (customOutputs.isNotEmpty) return customOutputs;

    switch (node.type) {
      case 'end':
        return const [];

      case 'condition':
        final branchPorts = _conditionBranchPorts(data);
        if (branchPorts.isNotEmpty) return branchPorts;

        return const [
          AutomationNodePort(
            id: 'true',
            label: 'True',
            icon: Icons.check_rounded,
            color: Colors.green,
          ),
          AutomationNodePort(
            id: 'false',
            label: 'False',
            icon: Icons.close_rounded,
            color: Colors.deepOrange,
          ),
        ];

      case 'switch':
        final switchPorts = _switchPorts(data);
        if (switchPorts.isNotEmpty) return switchPorts;

        return const [
          AutomationNodePort(
            id: 'default',
            label: 'Default',
            icon: Icons.alt_route_rounded,
          ),
        ];

      case 'approval':
        return const [
          AutomationNodePort(
            id: 'approved',
            label: 'Approved',
            icon: Icons.check_rounded,
            color: Colors.green,
          ),
          AutomationNodePort(
            id: 'rejected',
            label: 'Rejected',
            icon: Icons.close_rounded,
            color: Colors.redAccent,
          ),
          AutomationNodePort(
            id: 'expired',
            label: 'Expired',
            icon: Icons.timer_off_rounded,
            color: Colors.orange,
          ),
        ];

      case 'ai_prompt':
        final aiPorts = _aiDecisionPorts(data);
        if (aiPorts.isNotEmpty) return aiPorts;

        final format = _stringPath(data, ['ai_config', 'expected_output', 'format']);
        if (format == 'action_plan') {
          return const [
            AutomationNodePort(
              id: 'has_actions',
              label: 'Has actions',
              icon: Icons.playlist_add_check_rounded,
              color: Colors.purple,
            ),
            AutomationNodePort(
              id: 'no_actions',
              label: 'No actions',
              icon: Icons.playlist_remove_rounded,
              color: Colors.blueGrey,
            ),
          ];
        }

        return const [
          AutomationNodePort(
            id: 'success',
            label: 'Success',
            icon: Icons.check_rounded,
            color: Colors.green,
          ),
          AutomationNodePort(
            id: 'low_confidence',
            label: 'Low confidence',
            icon: Icons.warning_amber_rounded,
            color: Colors.orange,
          ),
          AutomationNodePort(
            id: 'error',
            label: 'Error',
            icon: Icons.error_outline_rounded,
            color: Colors.redAccent,
          ),
        ];

      case 'action':
      case 'api':
      case 'http':
      case 'code':
      case 'code_run':
      case 'for_each':
        return const [
          AutomationNodePort(
            id: 'success',
            label: 'Success',
            icon: Icons.check_rounded,
            color: Colors.green,
          ),
          AutomationNodePort(
            id: 'error',
            label: 'Error',
            icon: Icons.error_outline_rounded,
            color: Colors.redAccent,
          ),
        ];

      case 'parallel':
        final parallelBranches = _parallelBranchPorts(data);
        if (parallelBranches.isNotEmpty) return parallelBranches;
        return const [
          AutomationNodePort(
            id: 'branch_1',
            label: 'Branch 1',
            icon: Icons.call_split_rounded,
            color: Colors.blue,
          ),
          AutomationNodePort(
            id: 'branch_2',
            label: 'Branch 2',
            icon: Icons.call_split_rounded,
            color: Colors.blue,
          ),
        ];

      case 'wait_for_event':
        return const [
          AutomationNodePort(
            id: 'success',
            label: 'Event received',
            icon: Icons.notifications_active_rounded,
            color: Colors.green,
          ),
          AutomationNodePort(
            id: 'timeout',
            label: 'Timeout',
            icon: Icons.timer_off_rounded,
            color: Colors.orange,
          ),
        ];

      case 'set_variable':
        return const [
          AutomationNodePort(
            id: 'success',
            label: 'Next',
            icon: Icons.arrow_outward_rounded,
          ),
        ];

      case 'loop_until':
        return const [
          AutomationNodePort(
            id: 'success',
            label: 'Condition met',
            icon: Icons.check_rounded,
            color: Colors.green,
          ),
          AutomationNodePort(
            id: 'exhausted',
            label: 'Max attempts',
            icon: Icons.block_rounded,
            color: Colors.orange,
          ),
        ];

      case 'subworkflow':
        return const [
          AutomationNodePort(
            id: 'success',
            label: 'Completed',
            icon: Icons.check_rounded,
            color: Colors.green,
          ),
          AutomationNodePort(
            id: 'error',
            label: 'Error',
            icon: Icons.error_outline_rounded,
            color: Colors.redAccent,
          ),
        ];

      case 'trigger':
      case 'delay':
      default:
        return const [
          AutomationNodePort(
            id: 'default',
            label: 'Next',
            icon: Icons.arrow_outward_rounded,
          ),
        ];
    }
  }

  static double visualHeight(AutomationGraphNode node) {
    final outputs = outputPorts(node);
    if (outputs.length <= 1) return baseNodeHeight;

    return math.max(baseNodeHeight, outputTopPadding + outputs.length * outputStep + 18);
  }

  static Offset inputPoint(AutomationGraphNode node, {String? targetHandle}) {
    return node.position + Offset(0, visualHeight(node) / 2);
  }

  static Offset outputPoint(AutomationGraphNode node, {String? sourceHandle}) {
    final ports = outputPorts(node);
    if (ports.length <= 1) {
      return node.position + Offset(nodeWidth, visualHeight(node) / 2);
    }

    final index = _portIndex(ports, sourceHandle);
    final y = outputTopPadding + index * outputStep + 10;

    return node.position + Offset(nodeWidth, y);
  }

  static int outputPortIndex(AutomationGraphNode node, String? sourceHandle) {
    return _portIndex(outputPorts(node), sourceHandle);
  }

  static AutomationNodePort? outputPortById(AutomationGraphNode node, String? sourceHandle) {
    final ports = outputPorts(node);
    if (ports.isEmpty) return null;

    final index = _portIndex(ports, sourceHandle);
    return ports[index];
  }

  static String outputLabel(AutomationGraphNode node, String? sourceHandle) {
    final port = outputPortById(node, sourceHandle);
    return port?.label ?? sourceHandle ?? 'Next';
  }

  static Color? outputColor(AutomationGraphNode node, String? sourceHandle) {
    return outputPortById(node, sourceHandle)?.color;
  }

  static int _portIndex(List<AutomationNodePort> ports, String? handle) {
    if (ports.isEmpty) return 0;

    if (handle == null || handle.trim().isEmpty) return 0;

    final normalized = handle.trim();
    final index = ports.indexWhere((port) => port.id == normalized);

    return index < 0 ? 0 : index;
  }

  static List<AutomationNodePort> _conditionBranchPorts(Map<String, dynamic> data) {
    final branches = _listOfMaps(data['branches']).isNotEmpty
        ? _listOfMaps(data['branches'])
        : _listOfMaps(_map(data['conditions'])['branches']);

    final ports = <AutomationNodePort>[];

    for (var i = 0; i < branches.length; i++) {
      final branch = branches[i];
      final id = _firstString(branch, ['id', 'key', 'handle', 'name']) ?? 'if_${i + 1}';
      final label = _firstString(branch, ['label', 'title', 'name']) ?? 'IF ${i + 1}';

      ports.add(
        AutomationNodePort(
          id: id,
          label: label,
          description: branch['description']?.toString() ?? '',
          icon: Icons.call_split_rounded,
          color: i == 0 ? Colors.green : Colors.orange,
        ),
      );
    }

    final elseEnabled = data['else_enabled'] != false;
    final hasElse = ports.any((port) => port.id == 'else' || port.id == 'false');

    if (elseEnabled && !hasElse) {
      ports.add(
        const AutomationNodePort(
          id: 'else',
          label: 'Else',
          icon: Icons.subdirectory_arrow_right_rounded,
          color: Colors.deepOrange,
        ),
      );
    }

    return ports;
  }

  static List<AutomationNodePort> _switchPorts(Map<String, dynamic> data) {
    final cases = _listOfMaps(data['cases']);
    final ports = <AutomationNodePort>[];

    for (var i = 0; i < cases.length; i++) {
      final item = cases[i];
      final id = _firstString(item, ['id', 'key', 'value', 'handle']) ?? 'case_${i + 1}';
      final label = _firstString(item, ['label', 'title', 'value', 'key']) ?? 'Case ${i + 1}';

      ports.add(
        AutomationNodePort(
          id: id,
          label: label,
          description: item['description']?.toString() ?? '',
          icon: Icons.alt_route_rounded,
          color: Colors.orange,
        ),
      );
    }

    final defaultCase = data['default_case']?.toString().trim();
    ports.add(
      AutomationNodePort(
        id: defaultCase?.isNotEmpty == true ? defaultCase! : 'default',
        label: 'Default',
        icon: Icons.subdirectory_arrow_right_rounded,
        color: Colors.blueGrey,
      ),
    );

    return ports;
  }

  static List<AutomationNodePort> _aiDecisionPorts(Map<String, dynamic> data) {
    final decision = _map(_map(data['ai_config'])['decision']);
    final enabled = decision['enabled'] == true || _stringPath(data, ['ai_config', 'expected_output', 'format']) == 'decision';
    if (!enabled) return const [];

    final options = _listOfMaps(decision['options']);
    if (options.isEmpty) {
      return const [
        AutomationNodePort(
          id: 'yes',
          label: 'Yes',
          icon: Icons.check_rounded,
          color: Colors.green,
        ),
        AutomationNodePort(
          id: 'no',
          label: 'No',
          icon: Icons.close_rounded,
          color: Colors.deepOrange,
        ),
      ];
    }

    final colors = [Colors.green, Colors.orange, Colors.purple, Colors.blue, Colors.teal, Colors.redAccent];

    return [
      for (var i = 0; i < options.length; i++)
        AutomationNodePort(
          id: _firstString(options[i], ['key', 'id', 'value']) ?? 'option_${i + 1}',
          label: _firstString(options[i], ['label', 'title', 'key', 'id']) ?? 'Option ${i + 1}',
          description: options[i]['description']?.toString() ?? '',
          icon: Icons.psychology_alt_rounded,
          color: colors[i % colors.length],
        ),
    ];
  }

  static List<AutomationNodePort> _parallelBranchPorts(Map<String, dynamic> data) {
    final branches = _listOfMaps(data['branches']);
    if (branches.isEmpty) return const [];

    const colors = [Colors.blue, Colors.cyan, Colors.indigo, Colors.lightBlue, Colors.teal];

    return [
      for (var i = 0; i < branches.length; i++)
        AutomationNodePort(
          id: _firstString(branches[i], ['handle', 'id', 'key']) ?? 'branch_${i + 1}',
          label: _firstString(branches[i], ['label', 'title', 'name']) ?? 'Branch ${i + 1}',
          icon: Icons.call_split_rounded,
          color: colors[i % colors.length],
        ),
    ];
  }

  static List<AutomationNodePort> _portsFromList(dynamic raw) {
    final items = _listOfMaps(raw);
    if (items.isEmpty) return const [];

    return [
      for (var i = 0; i < items.length; i++)
        AutomationNodePort(
          id: _firstString(items[i], ['id', 'key', 'handle', 'value']) ?? 'output_${i + 1}',
          label: _firstString(items[i], ['label', 'title', 'name']) ?? 'Output ${i + 1}',
          description: items[i]['description']?.toString() ?? '',
          icon: Icons.arrow_outward_rounded,
        ),
    ];
  }

  static Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  static List<Map<String, dynamic>> _listOfMaps(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
  }

  static String? _firstString(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty && text != 'null') return text;
    }
    return null;
  }

  static String _stringPath(Map<String, dynamic> root, List<String> path) {
    dynamic cursor = root;
    for (final key in path) {
      if (cursor is! Map) return '';
      cursor = cursor[key];
    }
    return cursor?.toString().trim() ?? '';
  }
}
