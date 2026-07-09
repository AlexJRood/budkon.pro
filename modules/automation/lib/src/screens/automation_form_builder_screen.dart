import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/automation_studio_config.dart';
import '../models/automation_common.dart';
import '../models/automation_context.dart';
import '../models/automation_graph.dart';
import '../models/automation_workflow.dart';
import '../providers/automation_api_provider.dart';
import '../providers/automation_catalog_provider.dart';
import '../widgets/forms/automation_json_field.dart';

class AutomationFormBuilderScreen extends ConsumerStatefulWidget {
  final AutomationContextData? contextData;

  const AutomationFormBuilderScreen({
    super.key,
    this.contextData,
  });

  @override
  ConsumerState<AutomationFormBuilderScreen> createState() => _AutomationFormBuilderScreenState();
}

class _AutomationFormBuilderScreenState extends ConsumerState<AutomationFormBuilderScreen> {
  final nameController = TextEditingController();
  String? selectedSignal;
  String? selectedAction;
  Map<String, dynamic> condition = const {'all': []};
  Map<String, dynamic> actionConfig = const {};

  @override
  void initState() {
    super.initState();
    selectedSignal = widget.contextData?.suggestedSignals.isNotEmpty == true
        ? widget.contextData!.suggestedSignals.first
        : null;
    selectedAction = widget.contextData?.suggestedActions.isNotEmpty == true
        ? widget.contextData!.suggestedActions.first
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(automationCatalogProvider);

    return automationShell(
      context,
      ref: ref,
      title: 'Automation form builder',
      screenKey: 'automation.form_builder',
      actions: [
        IconButton(
          onPressed: _save,
          icon: const Icon(Icons.save_rounded),
        ),
      ],
      child: catalogAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text(error.toString())),
        data: (catalog) {
          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Automation name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: selectedSignal,
                items: catalog.signals
                    .map((signal) => DropdownMenuItem(
                          value: signal.key,
                          child: Text(signal.label),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => selectedSignal = value),
                decoration: const InputDecoration(
                  labelText: 'When this happens',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              AutomationJsonField(
                label: 'Conditions',
                value: condition,
                onChanged: (value) => condition = value,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: selectedAction,
                items: catalog.actions
                    .map((action) => DropdownMenuItem(
                          value: action.key,
                          child: Text(action.label),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => selectedAction = value),
                decoration: const InputDecoration(
                  labelText: 'Then do this',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              AutomationJsonField(
                label: 'Action config',
                value: actionConfig,
                onChanged: (value) => actionConfig = value,
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _save() async {
    if (selectedSignal == null || selectedAction == null) return;

    final graph = AutomationGraph(
      nodes: [
        AutomationGraphNode(
          id: 'trigger_1',
          type: 'trigger',
          position: const Offset(100, 100),
          data: {
            'label': 'Trigger',
            'signal_key': selectedSignal,
            'trigger_type': 'event',
          },
        ),
        AutomationGraphNode(
          id: 'condition_1',
          type: 'condition',
          position: const Offset(380, 100),
          data: {
            'label': 'Condition',
            'conditions': condition,
          },
        ),
        AutomationGraphNode(
          id: 'action_1',
          type: 'action',
          position: const Offset(660, 100),
          data: {
            'label': 'Action',
            'action_key': selectedAction,
            'config': actionConfig,
          },
        ),
      ],
      edges: const [
        AutomationGraphEdge(id: 'e1', source: 'trigger_1', target: 'condition_1'),
        AutomationGraphEdge(id: 'e2', source: 'condition_1', target: 'action_1', sourceHandle: 'true'),
      ],
    );

    final workflow = AutomationWorkflow(
      id: '',
      name: nameController.text.trim().isEmpty ? 'New automation' : nameController.text.trim(),
      graph: graph,
      companyId: widget.contextData?.companyId,
      ownerId: widget.contextData?.userId,
      scopeType: widget.contextData?.defaultScopeType ?? AutomationScopeType.user,
    );

    await ref.read(automationApiServiceProvider).createWorkflow(workflow);

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }
}
