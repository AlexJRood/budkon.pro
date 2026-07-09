import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/automation_studio_config.dart';
import '../models/automation_common.dart';
import '../models/automation_context.dart';
import '../models/automation_workflow.dart';
import '../providers/automation_api_provider.dart';
import '../providers/automation_workflow_provider.dart';
import '../widgets/common/automation_badge.dart';
import '../widgets/common/automation_empty_state.dart';
import 'automation_builder_screen.dart';
import 'automation_history_screen.dart';

class AutomationWorkflowListScreen extends ConsumerWidget {
  final AutomationScopeType? scopeType;
  final int? companyId;
  final int? ownerId;
  final AutomationContextData? contextData;
  final ScrollController? scrollController;

  const AutomationWorkflowListScreen({
    super.key,
    this.scopeType,
    this.companyId,
    this.ownerId,
    this.contextData,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = AutomationWorkflowListQuery(
      scopeType: scopeType,
      companyId: companyId,
      ownerId: ownerId,
    );

    final workflowsAsync = ref.watch(automationWorkflowListProvider(query));

    return automationShell(
      context,
      ref: ref,
      title: automationT(context, 'automation.workflows.title'),
      screenKey: 'automation.workflows',
      actions: [
        IconButton(
          tooltip: 'History',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AutomationHistoryScreen()),
            );
          },
          icon: const Icon(Icons.history_rounded),
        ),
        IconButton(
          tooltip: 'Create',
          onPressed: () => _openBuilder(context),
          icon: const Icon(Icons.add_rounded),
        ),
      ],
      child: workflowsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return AutomationEmptyState(
              icon: Icons.account_tree_rounded,
              title: 'No automations yet',
              message: 'Create your first workflow and connect signals with actions.',
              action: FilledButton.icon(
                onPressed: () => _openBuilder(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create automation'),
              ),
            );
          }

          return ListView.separated(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            itemBuilder: (_, index) {
              final workflow = items[index];
              return _WorkflowTile(
                workflow: workflow,
                onOpen: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AutomationBuilderScreen(workflowId: workflow.id),
                    ),
                  );
                },
                onToggle: () async {
                  final api = ref.read(automationApiServiceProvider);
                  if (workflow.status == AutomationWorkflowStatus.active) {
                    await api.deactivateWorkflow(workflow.id);
                  } else {
                    await api.activateWorkflow(workflow.id);
                  }
                  ref.invalidate(automationWorkflowListProvider(query));
                },
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemCount: items.length,
          );
        },
        error: (error, stack) {
          final colors = automationColors(context, ref);
          return Center(
            child: Text(
              error.toString(),
              style: TextStyle(color: colors.danger, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          );
        },
        loading: () {
          final colors = automationColors(context, ref);
          return Center(
            child: CircularProgressIndicator(color: colors.primary),
          );
        },
      ),
    );
  }

  void _openBuilder(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AutomationBuilderScreen(contextData: contextData),
      ),
    );
  }
}

class _WorkflowTile extends ConsumerWidget {
  final AutomationWorkflow workflow;
  final VoidCallback onOpen;
  final VoidCallback onToggle;

  const _WorkflowTile({
    required this.workflow,
    required this.onOpen,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = automationColors(context, ref);
    final active = workflow.status == AutomationWorkflowStatus.active;
    final statusColor = active ? colors.success : colors.warning;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(18, 12, 14, 12),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: colors.primary.withAlpha(22),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.account_tree_rounded,
                      color: colors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          workflow.name.isEmpty ? 'Untitled automation' : workflow.name,
                          style: TextStyle(
                            color: colors.text,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          workflow.description.isEmpty
                              ? workflow.triggerKeys.join(', ')
                              : workflow.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: colors.mutedText, fontSize: 12),
                        ),
                        if (workflow.lastRunAt != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            _formatLastRun(workflow.lastRunAt!),
                            style: TextStyle(
                              color: colors.mutedText.withAlpha(140),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AutomationBadge(
                        label: active ? 'Active' : enumName(workflow.status),
                        color: statusColor,
                      ),
                      const SizedBox(height: 6),
                      Transform.scale(
                        scale: 0.85,
                        alignment: Alignment.centerRight,
                        child: Switch(
                          value: active,
                          onChanged: (_) => onToggle(),
                          activeColor: colors.success,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatLastRun(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return 'Last run: today';
    if (diff.inDays == 1) return 'Last run: yesterday';
    if (diff.inDays < 30) return 'Last run: ${diff.inDays}d ago';
    return 'Last run: ${date.day}.${date.month}.${date.year}';
  }
}
