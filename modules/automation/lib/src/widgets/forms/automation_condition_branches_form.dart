import 'package:flutter/material.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/text_field.dart';

import 'automation_dynamic_form.dart';

class AutomationConditionBranchesForm extends StatefulWidget {
  final ThemeColors theme;
  final Map<String, dynamic> value;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final List<AutomationFormVariable> variables;

  const AutomationConditionBranchesForm({
    super.key,
    required this.theme,
    required this.value,
    required this.onChanged,
    this.variables = const [],
  });

  @override
  State<AutomationConditionBranchesForm> createState() => _AutomationConditionBranchesFormState();
}

class _AutomationConditionBranchesFormState extends State<AutomationConditionBranchesForm> {
  late String branchMode;
  late bool elseEnabled;
  late List<Map<String, dynamic>> branches;

  @override
  void initState() {
    super.initState();
    _load(widget.value);
  }

  @override
  void didUpdateWidget(covariant AutomationConditionBranchesForm oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.value != widget.value) {
      _load(widget.value);
    }
  }

  void _load(Map<String, dynamic> value) {
    branchMode = value['branch_mode']?.toString() ?? 'first_match';
    elseEnabled = value['else_enabled'] != false;
    branches = _asMapList(value['branches']);

    if (branches.isEmpty) {
      final oldConditions = _asMap(value['conditions']);
      branches = [
        {
          'id': 'true',
          'label': 'True',
          'conditions': oldConditions.isEmpty ? {'all': []} : oldConditions,
        },
      ];
    }
  }

  void _emit() {
    final normalizedBranches = [
      for (var i = 0; i < branches.length; i++)
        {
          ...branches[i],
          'id': _safeHandle(branches[i]['id']?.toString(), fallback: 'if_${i + 1}'),
          'label': _clean(branches[i]['label']?.toString(), fallback: 'IF ${i + 1}'),
          'conditions': _asMap(branches[i]['conditions']).isEmpty
              ? {'all': []}
              : _asMap(branches[i]['conditions']),
        },
    ];

    final next = {
      ...widget.value,
      'branch_mode': branchMode,
      'branches': normalizedBranches,
      'else_enabled': elseEnabled,
    };

    if (normalizedBranches.length == 1) {
      next['conditions'] = normalizedBranches.first['conditions'];
    }

    widget.onChanged(next);
  }

  void _patchBranch(int index, String key, dynamic value) {
    setState(() {
      branches[index] = {
        ...branches[index],
        key: value,
      };
    });
    _emit();
  }

  void _addBranch() {
    setState(() {
      final n = branches.length + 1;
      branches.add({
        'id': 'if_$n',
        'label': 'IF $n',
        'conditions': {'all': []},
      });
    });
    _emit();
  }

  void _removeBranch(int index) {
    setState(() {
      branches.removeAt(index);
      if (branches.isEmpty) {
        branches.add({
          'id': 'true',
          'label': 'True',
          'conditions': {'all': []},
        });
      }
    });
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InfoBox(
          theme: widget.theme,
          title: 'Branches / outputs',
          message: 'Each IF branch becomes its own output button and can have a separate arrow on the canvas.',
        ),
        const SizedBox(height: 12),
        CoreDropdown<String>(
          label: 'Branch behavior',
          value: branchMode,
          options: const ['first_match', 'all_matching'],
          prefixIcon: const Icon(Icons.call_split_rounded),
          display: (value) {
            switch (value) {
              case 'all_matching':
                return 'Run all matching outputs';
              case 'first_match':
              default:
                return 'Run first matching output';
            }
          },
          onChanged: (value) {
            if (value == null) return;
            setState(() => branchMode = value);
            _emit();
          },
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < branches.length; i++) ...[
          _BranchCard(
            theme: widget.theme,
            index: i,
            branch: branches[i],
            variables: widget.variables,
            canRemove: branches.length > 1,
            onRemove: () => _removeBranch(i),
            onPatch: (key, value) => _patchBranch(i, key, value),
          ),
          const SizedBox(height: 12),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: _addBranch,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add IF output'),
          ),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          value: elseEnabled,
          onChanged: (value) {
            setState(() => elseEnabled = value);
            _emit();
          },
          title: Text(
            'Add Else output',
            style: TextStyle(
              color: widget.theme.textColor,
              fontWeight: FontWeight.w900,
              fontSize: 12.5,
            ),
          ),
          subtitle: Text(
            'Creates an additional output arrow for records that do not match any IF branch.',
            style: TextStyle(
              color: widget.theme.textColor.withAlpha(145),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _asMapList(dynamic value) {
    if (value is! List) return <Map<String, dynamic>>[];
    return value.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
  }

  String _safeHandle(String? value, {required String fallback}) {
    final raw = _clean(value, fallback: fallback).toLowerCase();
    final normalized = raw
        .replaceAll(RegExp(r'[^a-z0-9_\-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return normalized.isEmpty ? fallback : normalized;
  }

  String _clean(String? value, {required String fallback}) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? fallback : text;
  }
}

class _BranchCard extends StatefulWidget {
  final ThemeColors theme;
  final int index;
  final Map<String, dynamic> branch;
  final List<AutomationFormVariable> variables;
  final bool canRemove;
  final VoidCallback onRemove;
  final void Function(String key, dynamic value) onPatch;

  const _BranchCard({
    required this.theme,
    required this.index,
    required this.branch,
    required this.variables,
    required this.canRemove,
    required this.onRemove,
    required this.onPatch,
  });

  @override
  State<_BranchCard> createState() => _BranchCardState();
}

class _BranchCardState extends State<_BranchCard> {
  late final TextEditingController idController;
  late final TextEditingController labelController;

  @override
  void initState() {
    super.initState();
    idController = TextEditingController(text: widget.branch['id']?.toString() ?? 'if_${widget.index + 1}');
    labelController = TextEditingController(text: widget.branch['label']?.toString() ?? 'IF ${widget.index + 1}');
  }

  @override
  void didUpdateWidget(covariant _BranchCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    final nextId = widget.branch['id']?.toString() ?? 'if_${widget.index + 1}';
    final nextLabel = widget.branch['label']?.toString() ?? 'IF ${widget.index + 1}';

    if (idController.text != nextId) idController.text = nextId;
    if (labelController.text != nextLabel) labelController.text = nextLabel;
  }

  @override
  void dispose() {
    idController.dispose();
    labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conditions = _asMap(widget.branch['conditions']).isEmpty
        ? {'all': []}
        : _asMap(widget.branch['conditions']);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.theme.dashboardContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: widget.theme.dashboardBoarder.withAlpha(150)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: widget.theme.themeColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.call_split_rounded, color: widget.theme.themeColor, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Output ${widget.index + 1}',
                  style: TextStyle(
                    color: widget.theme.textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Remove output',
                onPressed: widget.canRemove ? widget.onRemove : null,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: CoreTextField(
                  label: 'Output handle',
                  controller: idController,
                  prefixIcon: const Icon(Icons.tag_rounded),
                  onChanged: (value) => widget.onPatch('id', value),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CoreTextField(
                  label: 'Button label',
                  controller: labelController,
                  prefixIcon: const Icon(Icons.label_outline_rounded),
                  onChanged: (value) => widget.onPatch('label', value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AutomationConditionBuilder(
            theme: widget.theme,
            value: conditions,
            variables: widget.variables,
            onChanged: (value) => widget.onPatch('conditions', value),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }
}

class _InfoBox extends StatelessWidget {
  final ThemeColors theme;
  final String title;
  final String message;

  const _InfoBox({
    required this.theme,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.themeColor.withAlpha(16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.themeColor.withAlpha(45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.output_rounded, color: theme.themeColor, size: 18),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: TextStyle(
                    color: theme.textColor.withAlpha(155),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
