import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/text_field.dart';

import '../config/automation_studio_config.dart';
import '../models/automation_common.dart';
import '../models/automation_context.dart';
import '../models/automation_graph.dart';
import '../models/automation_workflow.dart';
import '../providers/automation_api_provider.dart';
import '../providers/automation_canvas_controller.dart';
import '../providers/automation_catalog_provider.dart';
import '../providers/automation_workflow_provider.dart';
import '../widgets/canvas/automation_canvas.dart';
import '../widgets/forms/automation_node_config_panel.dart';
import '../widgets/forms/automation_scope_selector.dart';
import '../widgets/palette/automation_palette_draggable_item.dart';

class AutomationBuilderScreen extends ConsumerStatefulWidget {
  final String? workflowId;
  final AutomationContextData? contextData;

  const AutomationBuilderScreen({
    super.key,
    this.workflowId,
    this.contextData,
  });

  @override
  ConsumerState<AutomationBuilderScreen> createState() => _AutomationBuilderScreenState();
}

class _AutomationBuilderScreenState extends ConsumerState<AutomationBuilderScreen> {
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();

  AutomationScopeType scopeType = AutomationScopeType.user;
  int _mobileTab = 1;

  /// Current graph used for saving.
  AutomationGraph graph = AutomationGraph.empty();

  /// Stable graph object used as the Riverpod family key.
  ///
  /// IMPORTANT:
  /// Do not use the changing `graph` field as provider key after each canvas edit,
  /// otherwise the left panel may write to a different provider instance than the
  /// canvas currently watches.
  late AutomationGraph canvasSeedGraph;

  AutomationWorkflow? loadedWorkflow;
  bool saving = false;

  @override
  void initState() {
    super.initState();

    scopeType = widget.contextData?.defaultScopeType ?? AutomationScopeType.user;
    graph = _defaultGraphFromContext(widget.contextData);
    canvasSeedGraph = graph;
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  AutomationGraph _defaultGraphFromContext(AutomationContextData? ctx) {
    final signal = ctx?.suggestedSignals.isNotEmpty == true ? ctx!.suggestedSignals.first : 'lead.created';

    return AutomationGraph(
      nodes: [
        AutomationGraphNode(
          id: 'trigger_1',
          type: 'trigger',
          position: const Offset(120, 160),
          data: {
            'label': 'Trigger',
            'trigger_type': 'event',
            'signal_key': signal,
          },
        ),
      ],
    );
  }

  Map<String, dynamic> _cloneMap(Map<String, dynamic> value) {
    if (value.isEmpty) return <String, dynamic>{};

    try {
      return Map<String, dynamic>.from(jsonDecode(jsonEncode(value)) as Map);
    } catch (_) {
      return Map<String, dynamic>.from(value);
    }
  }

  AutoDisposeStateNotifierProvider<AutomationCanvasController, AutomationCanvasState> get _canvasProvider {
    return automationCanvasControllerProvider(canvasSeedGraph);
  }

  AutomationCanvasController get _canvasController {
    return ref.read(_canvasProvider.notifier);
  }

  AutomationCanvasState get _canvasState {
    return ref.read(_canvasProvider);
  }

  Offset _nextAutoAddPosition() {
    final nodes = _canvasState.graph.nodes;

    if (nodes.isEmpty) {
      return const Offset(180, 180);
    }

    final last = nodes.last.position;
    final next = last + const Offset(70, 110);

    // Keep quick-click additions in a visible, tidy area.
    return Offset(
      next.dx.clamp(140.0, 1600.0).toDouble(),
      next.dy.clamp(140.0, 1100.0).toDouble(),
    );
  }

  void _addNodeToCanvas(
    String type,
    Map<String, dynamic> data, {
    Offset? position,
  }) {
    final safeData = _cloneMap(data);

    _canvasController.addNode(
      type: type,
      position: position ?? _nextAutoAddPosition(),
      data: safeData,
    );

    graph = _canvasState.graph;
  }

  Future<void> _openNodePickerAt(Offset scenePosition) async {
    final template = await showModalBottomSheet<_NodeTemplate>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.22),
      builder: (context) {
        return _NodePickerSheet(
          theme: ref.read(themeColorsProvider),
          templates: _defaultNodeTemplates(),
        );
      },
    );

    if (template == null || !mounted) return;

    _addNodeToCanvas(
      template.type,
      template.data,
      position: scenePosition - const Offset(125, 48),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(automationCatalogProvider);
    final workflowAsync = widget.workflowId == null
        ? const AsyncValue<AutomationWorkflow?>.data(null)
        : ref.watch(automationWorkflowProvider(widget.workflowId!)).whenData((value) => value);
    final theme = ref.watch(themeColorsProvider);

    return automationShell(
      context,
      ref: ref,
      title: widget.workflowId == null ? 'New automation' : 'Edit automation',
      screenKey: 'automation.builder',
      actions: [
        IconButton(
          tooltip: 'Save',
          onPressed: saving ? null : _save,
          icon: saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.save_rounded),
        ),
      ],
      child: catalogAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text(error.toString())),
        data: (catalog) {
          return workflowAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text(error.toString())),
            data: (workflow) {
              if (workflow != null && loadedWorkflow?.id != workflow.id) {
                loadedWorkflow = workflow;
                nameController.text = workflow.name;
                descriptionController.text = workflow.description;
                scopeType = workflow.scopeType;
                graph = workflow.graph;
                canvasSeedGraph = workflow.graph;
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 650;

                  if (!isMobile) {
                    return Row(
                      children: [
                        SizedBox(
                          width: 290,
                          child: _LeftCatalog(
                            theme: theme,
                            onAddNode: (type, data) => _addNodeToCanvas(type, data),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              _HeaderEditor(
                                theme: theme,
                                nameController: nameController,
                                descriptionController: descriptionController,
                                scopeType: scopeType,
                                onScopeChanged: (value) => setState(() => scopeType = value),
                                contextData: widget.contextData,
                              ),
                              Expanded(
                                child: AutomationCanvas(
                                  initialGraph: canvasSeedGraph,
                                  onCanvasDoubleTap: _openNodePickerAt,
                                  onGraphChanged: (value) => graph = value,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 360,
                          child: Consumer(
                            builder: (context, ref, _) {
                              final state = ref.watch(_canvasProvider);
                              final controller = ref.read(_canvasProvider.notifier);
                              final selectedNode = state.selectedNodeId == null
                                  ? null
                                  : state.graph.nodeById(state.selectedNodeId!);

                              return AutomationNodeConfigPanel(
                                theme: theme,
                                node: selectedNode,
                                graph: state.graph,
                                catalog: catalog,
                                onDataChanged: (data) {
                                  if (selectedNode != null) {
                                    controller.updateNodeData(selectedNode.id, data);
                                    graph = ref.read(_canvasProvider).graph;
                                  }
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  }

                  // ── Mobile layout ──────────────────────────────
                  return Consumer(
                    builder: (context, ref, _) {
                      final state = ref.watch(_canvasProvider);
                      final controller = ref.read(_canvasProvider.notifier);
                      final selectedNode = state.selectedNodeId == null
                          ? null
                          : state.graph.nodeById(state.selectedNodeId!);

                      if (selectedNode != null && _mobileTab != 2) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) setState(() => _mobileTab = 2);
                        });
                      }

                      return Column(
                        children: [
                          _MobileNameBar(
                            theme: theme,
                            nameController: nameController,
                          ),
                          Expanded(
                            child: IndexedStack(
                              index: _mobileTab,
                              children: [
                                _LeftCatalog(
                                  theme: theme,
                                  onAddNode: (type, data) {
                                    _addNodeToCanvas(type, data);
                                    setState(() => _mobileTab = 1);
                                  },
                                ),
                                AutomationCanvas(
                                  initialGraph: canvasSeedGraph,
                                  onCanvasDoubleTap: _openNodePickerAt,
                                  onGraphChanged: (value) => graph = value,
                                ),
                                AutomationNodeConfigPanel(
                                  theme: theme,
                                  node: selectedNode,
                                  graph: state.graph,
                                  catalog: catalog,
                                  onDataChanged: (data) {
                                    if (selectedNode != null) {
                                      controller.updateNodeData(selectedNode.id, data);
                                      graph = ref.read(_canvasProvider).graph;
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          _MobileBottomNav(
                            theme: theme,
                            currentIndex: _mobileTab,
                            hasNodeSelected: selectedNode != null,
                            onTap: (i) => setState(() => _mobileTab = i),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _save() async {
    setState(() => saving = true);

    try {
      final api = ref.read(automationApiServiceProvider);

      final workflow = AutomationWorkflow(
        id: loadedWorkflow?.id ?? '',
        name: nameController.text.trim().isEmpty ? 'Untitled automation' : nameController.text.trim(),
        description: descriptionController.text.trim(),
        status: loadedWorkflow?.status ?? AutomationWorkflowStatus.draft,
        scopeType: scopeType,
        companyId: widget.contextData?.companyId ?? loadedWorkflow?.companyId,
        ownerId: widget.contextData?.userId ?? loadedWorkflow?.ownerId,
        graph: graph,
      );

      final saved = workflow.id.isEmpty
          ? await api.createWorkflow(workflow)
          : await api.updateWorkflow(workflow);

      if (mounted) {
        setState(() {
          loadedWorkflow = saved;
          graph = saved.graph;
          canvasSeedGraph = saved.graph;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Automation saved')),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
}

class _HeaderEditor extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final AutomationScopeType scopeType;
  final ValueChanged<AutomationScopeType> onScopeChanged;
  final AutomationContextData? contextData;
  final ThemeColors theme;

  const _HeaderEditor({
    required this.nameController,
    required this.descriptionController,
    required this.scopeType,
    required this.onScopeChanged,
    this.contextData,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        border: Border(bottom: BorderSide(color: theme.dashboardBoarder)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 260,
            child: CoreTextField(
              label: 'Name',
              controller: nameController,
              textInputAction: TextInputAction.next,
              prefixIcon: const Icon(Icons.title_rounded),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: CoreTextField(
              label: 'Description',
              controller: descriptionController,
              textInputAction: TextInputAction.done,
              prefixIcon: const Icon(Icons.notes_rounded),
            ),
          ),
          const SizedBox(width: 10),
          AutomationScopeSelector(
            value: scopeType,
            onChanged: onScopeChanged,
            companyId: contextData?.companyId,
            userId: contextData?.userId,
          ),
        ],
      ),
    );
  }
}

class _MobileNameBar extends StatelessWidget {
  final ThemeColors theme;
  final TextEditingController nameController;

  const _MobileNameBar({required this.theme, required this.nameController});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        border: Border(bottom: BorderSide(color: theme.dashboardBoarder)),
      ),
      child: CoreTextField(
        label: 'Name',
        controller: nameController,
        textInputAction: TextInputAction.done,
        prefixIcon: const Icon(Icons.title_rounded),
      ),
    );
  }
}

class _MobileBottomNav extends StatelessWidget {
  final ThemeColors theme;
  final int currentIndex;
  final bool hasNodeSelected;
  final ValueChanged<int> onTap;

  const _MobileBottomNav({
    required this.theme,
    required this.currentIndex,
    required this.hasNodeSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        border: Border(top: BorderSide(color: theme.dashboardBoarder)),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: theme.themeColor,
        unselectedItemColor: theme.textColor.withValues(alpha: 0.5),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.widgets_rounded),
            label: 'Nodes',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.account_tree_rounded),
            label: 'Canvas',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: hasNodeSelected && currentIndex != 2,
              child: const Icon(Icons.tune_rounded),
            ),
            label: 'Config',
          ),
        ],
      ),
    );
  }
}

class _LeftCatalog extends StatelessWidget {
  final void Function(String type, Map<String, dynamic> data) onAddNode;
  final ThemeColors theme;

  const _LeftCatalog({
    required this.onAddNode,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final templates = _defaultNodeTemplates();

    return Container(
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        border: Border(right: BorderSide(color: theme.dashboardBoarder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
            child: Text(
              'Nodes',
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            child: Text(
              'Click to add, or drag onto canvas',
              style: TextStyle(
                color: theme.textColor.withValues(alpha: 0.62),
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 14),
              itemCount: templates.length,
              itemBuilder: (context, index) {
                final item = templates[index];

                return AutomationPaletteDraggableItem(
                  type: item.type,
                  label: item.title,
                  subtitle: item.subtitle,
                  icon: item.icon,
                  data: item.data,
                  onTapAdd: () => onAddNode(item.type, item.data),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NodePickerSheet extends StatelessWidget {
  final ThemeColors theme;
  final List<_NodeTemplate> templates;

  const _NodePickerSheet({
    required this.theme,
    required this.templates,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(14),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        decoration: BoxDecoration(
          color: theme.dashboardContainer,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: theme.dashboardBoarder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 26,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: theme.themeColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.add_rounded, color: theme.themeColor, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Add node here',
                      style: TextStyle(
                        color: theme.textColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, color: theme.textColor.withValues(alpha: 0.72)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: templates.length,
                  separatorBuilder: (_, __) => Divider(color: theme.dashboardBoarder, height: 1),
                  itemBuilder: (context, index) {
                    final item = templates[index];

                    return ListTile(
                      dense: true,
                      leading: Icon(item.icon, color: theme.themeColor),
                      title: Text(
                        item.title,
                        style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w800),
                      ),
                      subtitle: item.subtitle.trim().isEmpty
                          ? null
                          : Text(
                              item.subtitle,
                              style: TextStyle(color: theme.textColor.withValues(alpha: 0.58)),
                            ),
                      onTap: () => Navigator.of(context).pop(item),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NodeTemplate {
  final String title;
  final String subtitle;
  final IconData icon;
  final String type;
  final Map<String, dynamic> data;

  const _NodeTemplate({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.type,
    required this.data,
  });
}

List<_NodeTemplate> _defaultNodeTemplates() {
  return const [
    _NodeTemplate(
      title: 'Trigger',
      subtitle: 'Start workflow from event',
      icon: Icons.flash_on_rounded,
      type: 'trigger',
      data: {
        'label': 'Trigger',
        'trigger_type': 'event',
      },
    ),
    _NodeTemplate(
      title: 'Condition',
      subtitle: 'If / then branch',
      icon: Icons.rule_rounded,
      type: 'condition',
      data: {
        'label': 'Condition',
        'conditions': {'all': []},
      },
    ),
    _NodeTemplate(
      title: 'Switch',
      subtitle: 'Route by field value',
      icon: Icons.alt_route_rounded,
      type: 'switch',
      data: {
        'label': 'Switch',
        'field': 'payload.status',
        'cases': [],
      },
    ),
    _NodeTemplate(
      title: 'Action',
      subtitle: 'Run automation action',
      icon: Icons.play_circle_fill_rounded,
      type: 'action',
      data: {
        'label': 'Action',
        'action_key': 'noop',
        'config': {},
      },
    ),
    _NodeTemplate(
      title: 'Delay',
      subtitle: 'Wait before next step',
      icon: Icons.schedule_rounded,
      type: 'delay',
      data: {
        'label': 'Delay',
        'delay': {'amount': 1, 'unit': 'days'},
      },
    ),
    _NodeTemplate(
      title: 'Approval',
      subtitle: 'Pause until approved',
      icon: Icons.verified_user_rounded,
      type: 'approval',
      data: {
        'label': 'Approval',
        'title': 'Approval required',
        'message': '',
        'expires_in_minutes': 1440,
      },
    ),
    _NodeTemplate(
      title: 'AI Prompt',
      subtitle: 'Ask Emma / AI and save output',
      icon: Icons.auto_awesome_rounded,
      type: 'ai_prompt',
      data: {
        'label': 'AI Prompt',
        'prompt': '',
        'output_key': 'text',
      },
    ),
    _NodeTemplate(
      title: 'For each',
      subtitle: 'Loop over a list of items',
      icon: Icons.repeat_rounded,
      type: 'for_each',
      data: {
        'label': 'For each',
        'items_path': 'outputs.find_records.records',
        'item_key': 'item',
        'max_iterations': 50,
        'actions': <Map<String, dynamic>>[],
      },
    ),
    _NodeTemplate(
      title: 'Parallel',
      subtitle: 'Fan-out to multiple branches',
      icon: Icons.call_split_rounded,
      type: 'parallel',
      data: {
        'label': 'Parallel',
        'branches': <Map<String, dynamic>>[
          {'handle': 'branch_1', 'label': 'Branch 1'},
          {'handle': 'branch_2', 'label': 'Branch 2'},
        ],
      },
    ),
    _NodeTemplate(
      title: 'Wait for event',
      subtitle: 'Pause until a signal arrives',
      icon: Icons.notifications_paused_rounded,
      type: 'wait_for_event',
      data: {
        'label': 'Wait for event',
        'signal_key': '',
        'timeout_minutes': 1440,
      },
    ),
    _NodeTemplate(
      title: 'Set variable',
      subtitle: 'Store computed values in context',
      icon: Icons.edit_note_rounded,
      type: 'set_variable',
      data: {
        'label': 'Set variable',
        'variables': <Map<String, dynamic>>[
          {'key': 'my_var', 'value': ''},
        ],
      },
    ),
    _NodeTemplate(
      title: 'Loop until',
      subtitle: 'Retry actions until condition met',
      icon: Icons.loop_rounded,
      type: 'loop_until',
      data: {
        'label': 'Loop until',
        'condition': <String, dynamic>{},
        'actions': <Map<String, dynamic>>[],
        'max_attempts': 10,
        'check_before_run': false,
      },
    ),
    _NodeTemplate(
      title: 'Subworkflow',
      subtitle: 'Run another workflow as a child',
      icon: Icons.account_tree_rounded,
      type: 'subworkflow',
      data: {
        'label': 'Subworkflow',
        'workflow_id': '',
        'output_key': 'sub_result',
        'pass_context_keys': <String>[],
      },
    ),
    _NodeTemplate(
      title: 'End',
      subtitle: 'Stop workflow path',
      icon: Icons.flag_rounded,
      type: 'end',
      data: {
        'label': 'End',
      },
    ),
  ];
}
