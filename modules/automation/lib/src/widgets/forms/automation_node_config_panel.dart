import 'package:automation/src/widgets/forms/automation_condition_branches_form.dart';
import 'package:flutter/material.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/text_field.dart';

import '../../config/automation_studio_config.dart';
import '../../models/automation_catalog.dart';
import '../../models/automation_graph.dart';
import 'automation_dynamic_form.dart';
import 'automation_node_notifications_form.dart';

class AutomationNodeConfigPanel extends StatefulWidget {
  final AutomationGraphNode? node;
  final AutomationGraph? graph;
  final AutomationCatalog catalog;
  final ValueChanged<Map<String, dynamic>> onDataChanged;
  final ThemeColors theme;
  final bool showDeveloperRawData;

  const AutomationNodeConfigPanel({
    super.key,
    required this.node,
    this.graph,
    required this.catalog,
    required this.onDataChanged,
    required this.theme,
    this.showDeveloperRawData = false,
  });

  @override
  State<AutomationNodeConfigPanel> createState() =>
      _AutomationNodeConfigPanelState();
}

class _AutomationNodeConfigPanelState extends State<AutomationNodeConfigPanel> {
  late Map<String, dynamic> data;
  late TextEditingController labelController;
  List<TextEditingController> _branchControllers = [];
  List<TextEditingController> _varKeyControllers = [];
  List<TextEditingController> _varValueControllers = [];

  @override
  void initState() {
    super.initState();

    data = Map<String, dynamic>.from(widget.node?.data ?? const {});
    labelController = TextEditingController();

    _syncControllers();
  }

  @override
  void didUpdateWidget(covariant AutomationNodeConfigPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.node?.id != widget.node?.id) {
      data = Map<String, dynamic>.from(widget.node?.data ?? const {});
      _syncControllers();
    }
  }

  @override
  void dispose() {
    labelController.dispose();
    for (final c in _branchControllers) { c.dispose(); }
    for (final c in _varKeyControllers) { c.dispose(); }
    for (final c in _varValueControllers) { c.dispose(); }
    super.dispose();
  }

  void _syncControllers() {
    labelController.text = data['label']?.toString() ?? '';
    _rebuildBranchControllers();
    _rebuildVariableControllers();
  }

  void _rebuildBranchControllers() {
    for (final c in _branchControllers) c.dispose();
    final branches = data['branches'];
    if (branches is! List) {
      _branchControllers = [];
      return;
    }
    _branchControllers = [
      for (var i = 0; i < branches.length; i++)
        TextEditingController(
          text: (branches[i] as Map?)?['label']?.toString() ?? 'Branch ${i + 1}',
        ),
    ];
  }

  void _rebuildVariableControllers() {
    for (final c in _varKeyControllers) c.dispose();
    for (final c in _varValueControllers) c.dispose();
    final vars = data['variables'];
    if (vars is! List) {
      _varKeyControllers = [];
      _varValueControllers = [];
      return;
    }
    _varKeyControllers = [
      for (var i = 0; i < vars.length; i++)
        TextEditingController(text: (vars[i] as Map?)?['key']?.toString() ?? ''),
    ];
    _varValueControllers = [
      for (var i = 0; i < vars.length; i++)
        TextEditingController(text: (vars[i] as Map?)?['value']?.toString() ?? ''),
    ];
  }

  void patch(String key, dynamic value) {
    final next = Map<String, dynamic>.from(data);

    if (value == null) {
      next.remove(key);
    } else {
      next[key] = value;
    }

    setState(() {
      data = next;
      if (key == 'branches' && value is List && value.length != _branchControllers.length) {
        _rebuildBranchControllers();
      }
      if (key == 'variables' && value is List && value.length != _varKeyControllers.length) {
        _rebuildVariableControllers();
      }
    });
    widget.onDataChanged(next);
  }

  void patchMany(Map<String, dynamic> values) {
    final next = {
      ...data,
      ...values,
    };

    setState(() => data = Map<String, dynamic>.from(next));
    widget.onDataChanged(data);
  }

  @override
  Widget build(BuildContext context) {
    final colors = automationColors(context);
    final node = widget.node;

    if (node == null) {
      return Container(
        color: widget.theme.dashboardContainer,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.touch_app_rounded,
                  color: colors.mutedText,
                  size: 34,
                ),
                const SizedBox(height: 12),
                Text(
                  'Select a node',
                  style: TextStyle(
                    color: colors.text,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Click any block on the canvas to configure it.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.mutedText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final variables = _availableVariablesFor(node);

    return Container(
      color: widget.theme.dashboardContainer,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Icon(
                _nodeIcon(node.type),
                color: widget.theme.themeColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Node settings',
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _NodeTypeBadge(
                theme: widget.theme,
                label: node.type,
              ),
            ],
          ),
          const SizedBox(height: 14),

          CoreTextField(
            label: 'Label',
            controller: labelController,
            textInputAction: TextInputAction.done,
            prefixIcon: const Icon(Icons.label_outline_rounded),
            onChanged: (value) => patch('label', value),
          ),

          const SizedBox(height: 12),

          AutomationAvailableInputPanel(
            theme: widget.theme,
            variables: variables,
          ),

          if (variables.isNotEmpty) const SizedBox(height: 14),

          if (node.type == 'trigger') _triggerFields(variables),
          if (node.type == 'condition') _conditionFields(variables),
          if (node.type == 'action') _actionFields(variables),
          if (node.type == 'delay') _delayFields(),
          if (node.type == 'approval') _approvalFields(variables),
          if (node.type == 'ai_prompt') _aiFields(variables),
          if (node.type == 'switch') _switchFields(variables),
          if (node.type == 'api') _apiFields(variables),
          if (node.type == 'for_each') _forEachFields(variables),
          if (node.type == 'parallel') _parallelFields(),
          if (node.type == 'wait_for_event') _waitForEventFields(variables),
          if (node.type == 'set_variable') _setVariableFields(variables),
          if (node.type == 'loop_until') _loopUntilFields(variables),
          if (node.type == 'subworkflow') _subworkflowFields(variables),
          if (node.type == 'end') _endFields(),

          const SizedBox(height: 16),

          AutomationNodeNotificationsForm(
            nodeId: node.id,
            nodeType: node.type,
            theme: widget.theme,
            value: data['notifications'],
            variables: _notificationVariables(variables),
            onChanged: (value) => patch('notifications', value),
          ),

          if (widget.showDeveloperRawData) ...[
            const SizedBox(height: 18),
            _DeveloperDataPreview(
              theme: widget.theme,
              data: data,
            ),
          ],
        ],
      ),
    );
  }

  Widget _triggerFields(List<AutomationFormVariable> variables) {
    final signalKey = data['signal_key']?.toString();
    final signalOptions = widget.catalog.signals
        .map((signal) => signal.key)
        .toList();

    final signal = signalKey == null
        ? null
        : widget.catalog.signalByKey(signalKey);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CoreDropdown<String>(
          label: 'When this happens',
          value: signalOptions.contains(signalKey) ? signalKey : null,
          options: signalOptions,
          hintText: 'Choose trigger event',
          onChanged: (value) {
            patchMany({
              'signal_key': value,
              'trigger_type': 'event',
            });
          },
          display: (key) => widget.catalog.signalByKey(key)?.label ?? key,
          prefixIcon: const Icon(Icons.flash_on_rounded),
        ),

        if ((signal?.description ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          _InfoBox(
            theme: widget.theme,
            icon: Icons.info_outline_rounded,
            title: 'About this event',
            message: signal!.description,
          ),
        ],

        const SizedBox(height: 12),

        _PayloadPreview(
          theme: widget.theme,
          title: 'Payload available from this event',
          schema: signal?.payloadSchema ?? const {},
          example: signal?.examplePayload ?? const {},
        ),
      ],
    );
  }

  Widget _conditionFields(List<AutomationFormVariable> variables) {
    return AutomationConditionBranchesForm(
      theme: widget.theme,
      value: data,
      variables: variables,
      onChanged: (value) => patchMany(value),
    );
  }

  Widget _actionFields(List<AutomationFormVariable> variables) {
    final actionKey = data['action_key']?.toString();
    final actionOptions = widget.catalog.actions
        .map((action) => action.key)
        .toList();

    final action = actionKey == null
        ? null
        : widget.catalog.actionByKey(actionKey);

    final config = Map<String, dynamic>.from(
      data['config'] as Map? ?? const {},
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CoreDropdown<String>(
          label: 'Then do this',
          value: actionOptions.contains(actionKey) ? actionKey : null,
          options: actionOptions,
          hintText: 'Choose action',
          onChanged: (value) {
            final selectedAction = value == null
                ? null
                : widget.catalog.actionByKey(value);

            final defaults = selectedAction == null
                ? <String, dynamic>{}
                : automationDefaultsFromSchema(selectedAction.configSchema);

            patchMany({
              'action_key': value,
              'config': defaults,
            });
          },
          display: (key) => widget.catalog.actionByKey(key)?.label ?? key,
          prefixIcon: const Icon(Icons.play_circle_fill_rounded),
        ),

        if ((action?.description ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          _InfoBox(
            theme: widget.theme,
            icon: Icons.info_outline_rounded,
            title: 'About this action',
            message: action!.description,
          ),
        ],

        const SizedBox(height: 14),

        if (action == null)
          _InfoBox(
            theme: widget.theme,
            icon: Icons.touch_app_rounded,
            title: 'Choose an action',
            message:
                'After choosing an action, the form below will be generated from its DB/schema definition.',
          )
        else
          AutomationDynamicForm(
            title: 'Action configuration',
            schema: _schemaWithSmartUiHints(action.configSchema),
            value: config,
            theme: widget.theme,
            variables: variables,
            onChanged: (value) => patch('config', value),
          ),
      ],
    );
  }

  Widget _delayFields() {
    return AutomationDelayForm(
      theme: widget.theme,
      value: Map<String, dynamic>.from(
        data['delay'] as Map? ??
            const {
              'amount': 1,
              'unit': 'minutes',
            },
      ),
      onChanged: (value) => patch('delay', value),
    );
  }

  Widget _approvalFields(List<AutomationFormVariable> variables) {
    return AutomationDynamicForm(
      title: 'Approval',
      schema: const {
        'type': 'object',
        'required': ['title'],
        'properties': {
          'title': {
            'type': 'string',
            'title': 'Approval title',
            'description': 'Short title shown to the approver.',
          },
          'message': {
            'type': 'string',
            'title': 'Approval message',
            'x-ui-widget': 'textarea',
            'description':
                'Explain what needs approval. You can use input variables here.',
          },
          'expires_in_minutes': {
            'type': 'integer',
            'title': 'Expires after minutes',
            'default': 1440,
          },
        },
      },
      value: {
        'title': data['title'] ?? 'Approval required',
        'message': data['message'] ?? '',
        'expires_in_minutes': data['expires_in_minutes'] ?? 1440,
      },
      theme: widget.theme,
      variables: variables,
      onChanged: (value) => patchMany(value),
    );
  }

  Widget _aiFields(List<AutomationFormVariable> variables) {
    return AutomationDynamicForm(
      title: 'AI prompt',
      schema: const {
        'type': 'object',
        'required': ['prompt', 'output_key'],
        'properties': {
          'prompt': {
            'type': 'string',
            'title': 'Prompt',
            'x-ui-widget': 'textarea',
            'description':
                'Tell Emma what to generate or analyze. Use input chips to inject workflow data.',
          },
          'output_key': {
            'type': 'string',
            'title': 'Save output as',
            'default': 'text',
            'description':
                'Name used by following nodes to read this AI result.',
          },
        },
      },
      value: {
        'prompt': data['prompt'] ?? '',
        'output_key': data['output_key'] ?? 'text',
      },
      theme: widget.theme,
      variables: variables,
      onChanged: (value) => patchMany(value),
    );
  }

  Widget _switchFields(List<AutomationFormVariable> variables) {
    return AutomationDynamicForm(
      title: 'Switch',
      schema: const {
        'type': 'object',
        'required': ['field'],
        'properties': {
          'field': {
            'type': 'string',
            'title': 'Input path',
            'description': 'Field used to choose the outgoing route.',
          },
          'default_case': {
            'type': 'string',
            'title': 'Default case',
            'description': 'Fallback route if nothing matches.',
          },
        },
      },
      value: {
        'field': data['field'] ?? '',
        'default_case': data['default_case'] ?? 'default',
      },
      theme: widget.theme,
      variables: variables,
      onChanged: (value) => patchMany(value),
    );
  }

  Widget _apiFields(List<AutomationFormVariable> variables) {
    return AutomationDynamicForm(
      title: 'API request',
      schema: const {
        'type': 'object',
        'required': ['url', 'method'],
        'properties': {
          'url': {
            'type': 'string',
            'title': 'URL',
            'format': 'uri',
          },
          'method': {
            'type': 'string',
            'title': 'Method',
            'enum': ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
          },
          'headers': {
            'type': 'object',
            'title': 'Headers',
          },
          'body': {
            'type': 'object',
            'title': 'Body',
          },
          'timeout': {
            'type': 'integer',
            'title': 'Timeout seconds',
            'default': 10,
          },
        },
      },
      value: {
        'url': data['url'] ?? '',
        'method': data['method'] ?? 'POST',
        'headers': data['headers'] ?? <String, dynamic>{},
        'body': data['body'] ?? <String, dynamic>{},
        'timeout': data['timeout'] ?? 10,
      },
      theme: widget.theme,
      variables: variables,
      onChanged: (value) => patchMany(value),
    );
  }

  Widget _forEachFields(List<AutomationFormVariable> variables) {
    return AutomationDynamicForm(
      title: 'For each',
      schema: const {
        'type': 'object',
        'required': ['items_path'],
        'properties': {
          'items_path': {
            'type': 'string',
            'title': 'Items path',
            'description': 'Path to the list in context, e.g. outputs.find_users.records',
          },
          'item_key': {
            'type': 'string',
            'title': 'Item variable name',
            'default': 'item',
            'description': 'Name to reference each element inside actions, e.g. item → {{item.email}}',
          },
          'max_iterations': {
            'type': 'integer',
            'title': 'Max iterations',
            'default': 50,
            'description': 'Safety cap. Prevents runaway loops.',
          },
        },
      },
      value: {
        'items_path': data['items_path'] ?? '',
        'item_key': data['item_key'] ?? 'item',
        'max_iterations': data['max_iterations'] ?? 50,
      },
      theme: widget.theme,
      variables: variables,
      onChanged: (value) => patchMany(value),
    );
  }

  Widget _parallelFields() {
    final branches = _asList(data['branches']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InfoBox(
          theme: widget.theme,
          icon: Icons.call_split_rounded,
          title: 'Parallel node',
          message:
              'All branches run simultaneously. Connect each output handle to a different path. Add / remove branches below.',
        ),
        const SizedBox(height: 12),
        ..._buildBranchList(branches),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () {
            final next = List<Map<String, dynamic>>.from(
              branches.map((b) => Map<String, dynamic>.from(b is Map ? b : {})),
            );
            final idx = next.length + 1;
            next.add({'handle': 'branch_$idx', 'label': 'Branch $idx'});
            patch('branches', next);
          },
          icon: const Icon(Icons.add_rounded, size: 16),
          label: const Text('Add branch'),
        ),
      ],
    );
  }

  List<Widget> _buildBranchList(List<dynamic> branches) {
    return [
      for (var i = 0; i < branches.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: CoreTextField(
                  label: 'Branch ${i + 1} label',
                  controller: _branchControllers[i],
                  onChanged: (value) {
                    final next = List<Map<String, dynamic>>.from(
                      branches.map((b) => Map<String, dynamic>.from(b is Map ? b : {})),
                    );
                    next[i] = {
                      ...next[i],
                      'label': value,
                      'handle': next[i]['handle'] ?? 'branch_${i + 1}',
                    };
                    patch('branches', next);
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  final next = List<Map<String, dynamic>>.from(
                    branches.map((b) => Map<String, dynamic>.from(b is Map ? b : {})),
                  )..removeAt(i);
                  patch('branches', next);
                },
                icon: const Icon(Icons.remove_circle_outline_rounded, size: 18),
                color: Colors.redAccent,
              ),
            ],
          ),
        ),
    ];
  }

  Widget _waitForEventFields(List<AutomationFormVariable> variables) {
    final signalOptions = widget.catalog.signals.map((s) => s.key).toList();
    final selectedSignal = data['signal_key']?.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CoreDropdown<String>(
          label: 'Wait for this event',
          value: signalOptions.contains(selectedSignal) ? selectedSignal : null,
          options: signalOptions,
          hintText: 'Choose signal to wait for',
          onChanged: (value) => patch('signal_key', value),
          display: (key) => widget.catalog.signalByKey(key)?.label ?? key,
          prefixIcon: const Icon(Icons.notifications_paused_rounded),
        ),
        const SizedBox(height: 12),
        AutomationDynamicForm(
          title: 'Timeout and matching',
          schema: const {
            'type': 'object',
            'properties': {
              'timeout_minutes': {
                'type': 'integer',
                'title': 'Timeout (minutes)',
                'description': 'Resume via "Timeout" handle after this many minutes. Leave empty to wait indefinitely.',
              },
              'match_payload_key': {
                'type': 'string',
                'title': 'Match payload field',
                'description': 'Only resume if event.payload[field] matches the value below.',
              },
              'match_value': {
                'type': 'string',
                'title': 'Match value',
                'description': 'Expected value for the payload field above.',
              },
            },
          },
          value: {
            'timeout_minutes': data['timeout_minutes'],
            'match_payload_key': data['match_payload_key'] ?? '',
            'match_value': data['match_value'] ?? '',
          },
          theme: widget.theme,
          variables: variables,
          onChanged: (value) => patchMany(value),
        ),
      ],
    );
  }

  Widget _setVariableFields(List<AutomationFormVariable> variables) {
    final varsList = _asList(data['variables']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InfoBox(
          theme: widget.theme,
          icon: Icons.edit_note_rounded,
          title: 'Set variable',
          message:
              'Stores computed values in context.vars. Reference them downstream as {{vars.my_key}}.',
        ),
        const SizedBox(height: 12),
        ..._buildVariableList(varsList, variables),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () {
            final next = List<Map<String, dynamic>>.from(
              varsList.map((v) => Map<String, dynamic>.from(v is Map ? v : {})),
            );
            next.add({'key': '', 'value': ''});
            patch('variables', next);
          },
          icon: const Icon(Icons.add_rounded, size: 16),
          label: const Text('Add variable'),
        ),
      ],
    );
  }

  List<Widget> _buildVariableList(
    List<dynamic> varsList,
    List<AutomationFormVariable> variables,
  ) {
    return [
      for (var i = 0; i < varsList.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: CoreTextField(
                  label: 'Key',
                  controller: _varKeyControllers[i],
                  onChanged: (value) {
                    final next = List<Map<String, dynamic>>.from(
                      varsList.map((v) => Map<String, dynamic>.from(v is Map ? v : {})),
                    );
                    next[i] = {...next[i], 'key': value};
                    patch('variables', next);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: CoreTextField(
                  label: 'Value / template',
                  controller: _varValueControllers[i],
                  onChanged: (value) {
                    final next = List<Map<String, dynamic>>.from(
                      varsList.map((v) => Map<String, dynamic>.from(v is Map ? v : {})),
                    );
                    next[i] = {...next[i], 'value': value};
                    patch('variables', next);
                  },
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: () {
                  final next = List<Map<String, dynamic>>.from(
                    varsList.map((v) => Map<String, dynamic>.from(v is Map ? v : {})),
                  )..removeAt(i);
                  patch('variables', next);
                },
                icon: const Icon(Icons.remove_circle_outline_rounded, size: 18),
                color: Colors.redAccent,
              ),
            ],
          ),
        ),
    ];
  }

  Widget _loopUntilFields(List<AutomationFormVariable> variables) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InfoBox(
          theme: widget.theme,
          icon: Icons.loop_rounded,
          title: 'Loop until',
          message:
              'Runs inline actions repeatedly until a condition is met or max attempts is reached. '
              'Use "success" port when condition met, "exhausted" port for max-attempts fallback.',
        ),
        const SizedBox(height: 12),
        AutomationDynamicForm(
          title: 'Loop settings',
          schema: const {
            'type': 'object',
            'required': ['max_attempts'],
            'properties': {
              'max_attempts': {
                'type': 'integer',
                'title': 'Max attempts',
                'default': 10,
                'description': 'Safety cap — stop after this many iterations even if condition is not met.',
              },
              'check_before_run': {
                'type': 'boolean',
                'title': 'Check condition before first run',
                'description': 'If true, check condition before executing actions on each attempt.',
              },
            },
          },
          value: {
            'max_attempts': data['max_attempts'] ?? 10,
            'check_before_run': data['check_before_run'] ?? false,
          },
          theme: widget.theme,
          variables: variables,
          onChanged: (value) => patchMany(value),
        ),
      ],
    );
  }

  Widget _subworkflowFields(List<AutomationFormVariable> variables) {
    return AutomationDynamicForm(
      title: 'Subworkflow',
      schema: const {
        'type': 'object',
        'required': ['workflow_id'],
        'properties': {
          'workflow_id': {
            'type': 'string',
            'title': 'Workflow ID',
            'description': 'UUID of the target AutomationWorkflow to execute as a child.',
          },
          'output_key': {
            'type': 'string',
            'title': 'Output key',
            'default': 'sub_result',
            'description': 'Store the child workflow output in vars[output_key].',
          },
          'pass_context_keys': {
            'type': 'array',
            'title': 'Context keys to pass',
            'items': {'type': 'string'},
            'description': 'Dot-paths to pass as payload to the child (e.g. "payload.user_id"). Leave empty to pass payload + vars.',
          },
        },
      },
      value: {
        'workflow_id': data['workflow_id'] ?? '',
        'output_key': data['output_key'] ?? 'sub_result',
        'pass_context_keys': _asList(data['pass_context_keys']),
      },
      theme: widget.theme,
      variables: variables,
      onChanged: (value) => patchMany(value),
    );
  }

  Widget _endFields() {
    return _InfoBox(
      theme: widget.theme,
      icon: Icons.flag_rounded,
      title: 'End node',
      message:
          'This node stops the current workflow path. It does not need extra configuration.',
    );
  }

  List<AutomationNotificationVariable> _notificationVariables(
    List<AutomationFormVariable> variables,
  ) {
    final raw = <AutomationNotificationVariable>[
      const AutomationNotificationVariable(
        label: 'Workflow name',
        token: '{{workflow.name}}',
        icon: Icons.account_tree_rounded,
      ),
      const AutomationNotificationVariable(
        label: 'Node label',
        token: '{{node.label}}',
        icon: Icons.widgets_rounded,
      ),
      const AutomationNotificationVariable(
        label: 'Selected route',
        token: '{{node.selected_handle}}',
        icon: Icons.alt_route_rounded,
      ),
      const AutomationNotificationVariable(
        label: 'Actor ID',
        token: '{{actor.id}}',
        icon: Icons.person_rounded,
      ),
      const AutomationNotificationVariable(
        label: 'Payload',
        token: '{{payload}}',
        icon: Icons.data_object_rounded,
      ),
      const AutomationNotificationVariable(
        label: 'Node output',
        token: '{{output}}',
        icon: Icons.output_rounded,
      ),
      const AutomationNotificationVariable(
        label: 'Timing',
        token: '{{timing}}',
        icon: Icons.schedule_rounded,
      ),
      const AutomationNotificationVariable(
        label: 'Run ID',
        token: '{{run.id}}',
        icon: Icons.fingerprint_rounded,
      ),

      for (final item in variables)
        AutomationNotificationVariable(
          label: item.label,
          token: item.token,
          icon: item.icon,
        ),
    ];

    final seen = <String>{};

    return [
      for (final item in raw)
        if (seen.add(item.token)) item,
    ];
  }

  List<AutomationFormVariable> _availableVariablesFor(
    AutomationGraphNode node,
  ) {
    final out = <AutomationFormVariable>[
      const AutomationFormVariable(
        label: 'Actor ID',
        token: '{{actor.id}}',
        description: 'Current user/actor ID.',
        icon: Icons.person_rounded,
      ),
      const AutomationFormVariable(
        label: 'Actor email',
        token: '{{actor.email}}',
        description: 'Current user/actor email.',
        icon: Icons.alternate_email_rounded,
      ),
      const AutomationFormVariable(
        label: 'Event payload',
        token: '{{payload}}',
        description: 'Full event payload.',
        icon: Icons.data_object_rounded,
      ),
      const AutomationFormVariable(
        label: 'Now',
        token: '{{now}}',
        description: 'Current datetime when workflow runs.',
        icon: Icons.schedule_rounded,
      ),
    ];

    final signalKey = _firstTriggerSignalKey(node);
    final signal = signalKey == null
        ? null
        : widget.catalog.signalByKey(signalKey);

    if (signal != null) {
      out.addAll(_variablesFromPayloadSchema(signal.payloadSchema));
      out.addAll(_variablesFromExamplePayload(signal.examplePayload));
    }

    final graph = widget.graph;

    if (graph != null) {
      final upstreamNodes = _upstreamNodes(graph, node.id);

      for (final upstream in upstreamNodes) {
        final label = upstream.label;
        final safeId = upstream.id;

        out.add(
          AutomationFormVariable(
            label: '$label output',
            token: '{{nodes.$safeId.output}}',
            description: 'Output produced by node "$label".',
            icon: _nodeIcon(upstream.type),
          ),
        );

        out.add(
          AutomationFormVariable(
            label: '$label route',
            token: '{{nodes.$safeId.selected_handle}}',
            description: 'Selected output route from "$label".',
            icon: Icons.alt_route_rounded,
          ),
        );

        if (upstream.type == 'ai_prompt') {
          final outputKey = upstream.data['output_key']?.toString() ?? 'text';

          out.add(
            AutomationFormVariable(
              label: '$label.$outputKey',
              token: '{{nodes.$safeId.$outputKey}}',
              description: 'Named AI output from "$label".',
              icon: Icons.auto_awesome_rounded,
            ),
          );
        }
      }
    }

    final seen = <String>{};

    return [
      for (final item in out)
        if (seen.add(item.token)) item,
    ];
  }

  String? _firstTriggerSignalKey(AutomationGraphNode currentNode) {
    if (currentNode.type == 'trigger') {
      final value = currentNode.data['signal_key']?.toString();
      return value?.trim().isEmpty == true ? null : value;
    }

    final graph = widget.graph;

    if (graph == null) return null;

    for (final node in graph.nodes) {
      if (node.type != 'trigger') continue;

      final value = node.data['signal_key']?.toString();

      if (value?.trim().isNotEmpty == true) {
        return value;
      }
    }

    return null;
  }

  List<AutomationFormVariable> _variablesFromPayloadSchema(
    Map<String, dynamic> schema,
  ) {
    final properties = _asMap(schema['properties']);
    final variables = <AutomationFormVariable>[];

    for (final entry in properties.entries) {
      final key = entry.key;
      final fieldSchema = _asMap(entry.value);
      final title = fieldSchema['title']?.toString() ?? _humanize(key);

      variables.add(
        AutomationFormVariable(
          label: title,
          token: '{{payload.$key}}',
          description:
              fieldSchema['description']?.toString() ?? 'Payload field: $key',
          icon: Icons.input_rounded,
        ),
      );
    }

    return variables;
  }

  List<AutomationFormVariable> _variablesFromExamplePayload(
    Map<String, dynamic> example,
  ) {
    final variables = <AutomationFormVariable>[];

    for (final key in example.keys.take(20)) {
      variables.add(
        AutomationFormVariable(
          label: _humanize(key),
          token: '{{payload.$key}}',
          description: 'Payload field from example payload.',
          icon: Icons.input_rounded,
        ),
      );
    }

    return variables;
  }

  List<AutomationGraphNode> _upstreamNodes(
    AutomationGraph graph,
    String nodeId,
  ) {
    final byId = {
      for (final node in graph.nodes) node.id: node,
    };

    final visited = <String>{};
    final result = <AutomationGraphNode>[];

    void visit(String targetId) {
      final incoming = graph.edges.where((edge) => edge.target == targetId);

      for (final edge in incoming) {
        if (!visited.add(edge.source)) continue;

        final sourceNode = byId[edge.source];

        if (sourceNode == null) continue;

        result.add(sourceNode);
        visit(sourceNode.id);
      }
    }

    visit(nodeId);

    return result.reversed.toList();
  }

  Map<String, dynamic> _schemaWithSmartUiHints(
    Map<String, dynamic> schema,
  ) {
    final normalized = _asMap(schema);
    final properties = _asMap(normalized['properties']);

    if (properties.isEmpty) return normalized;

    final patchedProperties = <String, dynamic>{};

    for (final entry in properties.entries) {
      final key = entry.key;
      final field = _asMap(entry.value);

      if (key == 'method' && !field.containsKey('enum')) {
        field['enum'] = ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'];
      }

      if ((key == 'body' || key == 'payload' || key == 'headers') &&
          !field.containsKey('type')) {
        field['type'] = 'object';
      }

      if ((key == 'prompt' || key == 'message' || key == 'body') &&
          !field.containsKey('x-ui-widget')) {
        field['x-ui-widget'] = 'textarea';
      }

      patchedProperties[key] = field;
    }

    return {
      ...normalized,
      'properties': patchedProperties,
    };
  }

  IconData _nodeIcon(String type) {
    switch (type) {
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
      case 'end':
        return Icons.flag_rounded;
      case 'for_each':
        return Icons.repeat_rounded;
      case 'parallel':
        return Icons.call_split_rounded;
      case 'wait_for_event':
        return Icons.notifications_paused_rounded;
      case 'set_variable':
        return Icons.edit_note_rounded;
      case 'loop_until':
        return Icons.loop_rounded;
      case 'subworkflow':
        return Icons.account_tree_rounded;
      default:
        return Icons.play_circle_fill_rounded;
    }
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);

    return <String, dynamic>{};
  }

  List<dynamic> _asList(dynamic value) {
    if (value is List) return value;
    return const [];
  }

  String _humanize(String value) {
    final normalized = value
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .replaceAll('.', ' ')
        .trim();

    if (normalized.isEmpty) return value;

    return normalized[0].toUpperCase() + normalized.substring(1);
  }
}

class _PayloadPreview extends StatelessWidget {
  final ThemeColors theme;
  final String title;
  final Map<String, dynamic> schema;
  final Map<String, dynamic> example;

  const _PayloadPreview({
    required this.theme,
    required this.title,
    required this.schema,
    required this.example,
  });

  @override
  Widget build(BuildContext context) {
    final properties = _asMap(schema['properties']);
    final keys = properties.keys.toList();

    if (keys.isEmpty && example.isEmpty) {
      return _InfoBox(
        theme: theme,
        icon: Icons.input_rounded,
        title: title,
        message:
            'No payload schema is registered yet. You can still use {{payload}} in following nodes.',
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dashboardBoarder.withAlpha(150),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(
              color: theme.textColor,
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          if (keys.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final key in keys)
                  Chip(
                    label: Text('{{payload.$key}}'),
                    backgroundColor: theme.themeColor.withAlpha(18),
                    side: BorderSide(
                      color: theme.themeColor.withAlpha(58),
                    ),
                    labelStyle: TextStyle(
                      color: theme.textColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
              ],
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final key in example.keys.take(12))
                  Chip(
                    label: Text('{{payload.$key}}'),
                    backgroundColor: theme.themeColor.withAlpha(18),
                    side: BorderSide(
                      color: theme.themeColor.withAlpha(58),
                    ),
                    labelStyle: TextStyle(
                      color: theme.textColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
              ],
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
  final IconData icon;
  final String title;
  final String message;

  const _InfoBox({
    required this.theme,
    required this.icon,
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
        border: Border.all(
          color: theme.themeColor.withAlpha(45),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: theme.themeColor,
            size: 18,
          ),
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

class _NodeTypeBadge extends StatelessWidget {
  final ThemeColors theme;
  final String label;

  const _NodeTypeBadge({
    required this.theme,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: theme.themeColor.withAlpha(18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.themeColor.withAlpha(48),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: theme.themeColor,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _DeveloperDataPreview extends StatelessWidget {
  final ThemeColors theme;
  final Map<String, dynamic> data;

  const _DeveloperDataPreview({
    required this.theme,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      initiallyExpanded: false,
      tilePadding: EdgeInsets.zero,
      title: Text(
        'Developer raw data',
        style: TextStyle(
          color: theme.textColor,
          fontWeight: FontWeight.w900,
        ),
      ),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(22),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            data.toString(),
            style: TextStyle(
              color: theme.textColor.withAlpha(160),
              fontFamily: 'monospace',
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}