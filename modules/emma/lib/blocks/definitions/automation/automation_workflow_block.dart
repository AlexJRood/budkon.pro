import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/route_constant.dart';

import 'package:emma/blocks/core/block_definition.dart';
import 'package:emma/blocks/core/block_descriptor.dart';
import 'package:emma/blocks/definitions/shared/block_ui.dart';
import 'package:emma/provider/emma_notifier.dart';

class AutomationWorkflowBlockDefinition extends EmmaBlockDefinition {
  const AutomationWorkflowBlockDefinition();

  @override
  String get key => 'automation_workflow';

  @override
  bool supports(EmmaBlockDescriptor block) {
    return block.type == EmmaBlockType.automationWorkflow;
  }

  @override
  Widget buildBlock({
    required BuildContext context,
    required WidgetRef ref,
    required EmmaBlockDescriptor block,
    required double maxWidth,
    required String messageId,
  }) {
    return _AutomationWorkflowCard(block: block, maxWidth: maxWidth);
  }
}

// ---------------------------------------------------------------------------

class _AutomationWorkflowPayload {
  final String workflowId;
  final String name;
  final String description;
  final String status;
  final String operation;
  final int triggerCount;
  final int nodeCount;
  final String scopeType;
  final List<String> triggerLabels;

  const _AutomationWorkflowPayload({
    required this.workflowId,
    required this.name,
    required this.description,
    required this.status,
    required this.operation,
    required this.triggerCount,
    required this.nodeCount,
    required this.scopeType,
    required this.triggerLabels,
  });

  factory _AutomationWorkflowPayload.fromBlock(EmmaBlockDescriptor block) {
    final root = block.raw;
    final wf = root['workflow'] is Map
        ? Map<String, dynamic>.from(root['workflow'] as Map)
        : root;

    final triggers = wf['trigger_labels'];
    final List<String> labels = triggers is List
        ? triggers.map((e) => e.toString()).toList()
        : [];

    return _AutomationWorkflowPayload(
      workflowId: (wf['id'] ?? '').toString(),
      name: (wf['name'] ?? root['name'] ?? 'Automatyzacja').toString(),
      description: (wf['description'] ?? root['description'] ?? '').toString(),
      status: (wf['status'] ?? root['status'] ?? 'draft').toString(),
      operation: (root['operation'] ?? wf['operation'] ?? 'create').toString(),
      triggerCount: (wf['trigger_count'] as int?) ?? labels.length,
      nodeCount: (wf['node_count'] as int?) ?? 0,
      scopeType: (wf['scope_type'] ?? 'user').toString(),
      triggerLabels: labels,
    );
  }

  bool get isActive => status == 'active';
  bool get isDraft => status == 'draft';
  bool get isPaused => status == 'paused';
}

// ---------------------------------------------------------------------------

class _AutomationWorkflowCard extends ConsumerWidget {
  final EmmaBlockDescriptor block;
  final double maxWidth;

  const _AutomationWorkflowCard({
    required this.block,
    required this.maxWidth,
  });

  Color get _accentColor => const Color(0xFF7C4DFF);

  String _operationLabel(_AutomationWorkflowPayload p) {
    switch (p.operation) {
      case 'create':
        return 'automation_emma_created'.tr;
      case 'update':
        return 'automation_emma_updated'.tr;
      case 'activate':
        return 'automation_emma_activated'.tr;
      case 'deactivate':
        return 'automation_emma_deactivated'.tr;
      default:
        return 'automation_emma_ready'.tr;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.greenAccent;
      case 'paused':
        return Colors.orangeAccent;
      case 'archived':
        return Colors.white38;
      default:
        return const Color(0xFF7C4DFF);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'active':
        return 'automation_status_active'.tr;
      case 'draft':
        return 'automation_status_draft'.tr;
      case 'paused':
        return 'automation_status_paused'.tr;
      case 'archived':
        return 'automation_status_archived'.tr;
      default:
        return status;
    }
  }

  String _scopeLabel(String scope) {
    switch (scope) {
      case 'company':
        return 'automation_scope_company'.tr;
      case 'team':
        return 'automation_scope_team'.tr;
      default:
        return 'automation_scope_user'.tr;
    }
  }

  IconData _scopeIcon(String scope) {
    switch (scope) {
      case 'company':
        return Icons.business_outlined;
      case 'team':
        return Icons.group_outlined;
      default:
        return Icons.person_outline;
    }
  }

  void _openBuilder(BuildContext context, WidgetRef ref, String workflowId) {
    if (workflowId.isEmpty) {
      ref.read(navigationService).pushNamedScreen(Routes.automationCreate);
      return;
    }
    ref.read(navigationService).pushNamedScreen(
      Routes.automationBuilderPattern.replaceAll(':workflowId', workflowId),
    );
  }

  Future<void> _confirmAndActivate(
    BuildContext context,
    WidgetRef ref,
    String workflowId,
    String name,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'automation_activate_confirm_title'.tr,
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
        content: Text(
          '${'automation_activate_confirm_body'.tr} "$name"?',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'cancel'.tr,
              style: const TextStyle(color: Colors.white54),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.greenAccent,
              foregroundColor: Colors.black87,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text('automation_activate'.tr),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      ref
          .read(chatAiMessageProvider.notifier)
          .activateAutomationWorkflow(workflowId);
    }
  }

  Future<void> _confirmAndDeactivate(
    BuildContext context,
    WidgetRef ref,
    String workflowId,
    String name,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'automation_deactivate_confirm_title'.tr,
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
        content: Text(
          '${'automation_deactivate_confirm_body'.tr} "$name"?',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'cancel'.tr,
              style: const TextStyle(color: Colors.white54),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orangeAccent,
              foregroundColor: Colors.black87,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text('automation_deactivate'.tr),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      ref
          .read(chatAiMessageProvider.notifier)
          .deactivateAutomationWorkflow(workflowId);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = _AutomationWorkflowPayload.fromBlock(block);
    final accent = _accentColor;
    final statusColor = _statusColor(p.status);

    return EmmaBlockCardShell(
      maxWidth: maxWidth,
      borderColor: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // nagłówek operacji
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 13, color: accent),
              const SizedBox(width: 5),
              Text(
                _operationLabel(p),
                style: TextStyle(
                  color: accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(28),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withAlpha(80)),
                ),
                child: Text(
                  _statusLabel(p.status),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // nazwa
          Text(
            p.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),

          if (p.description.trim().isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              p.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withAlpha(180),
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ],

          // metadane: zakres, węzły, triggery
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              if (p.nodeCount > 0)
                EmmaTag(
                  label: '${'automation_nodes'.tr}: ${p.nodeCount}',
                  color: Colors.white54,
                ),
              EmmaTag(
                icon: _scopeIcon(p.scopeType),
                label: _scopeLabel(p.scopeType),
                color: Colors.white38,
              ),
              ...p.triggerLabels.take(3).map(
                    (t) => EmmaTag(label: t, color: accent),
                  ),
            ],
          ),

          const SizedBox(height: 12),

          // przyciski akcji
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              EmmaActionPill(
                label: 'automation_open_builder'.tr,
                icon: Icons.schema_outlined,
                onTap: () => _openBuilder(context, ref, p.workflowId),
              ),
              if (p.isDraft && p.workflowId.isNotEmpty)
                EmmaActionPill(
                  label: 'automation_dry_run'.tr,
                  icon: Icons.play_circle_outline,
                  onTap: () => ref
                      .read(chatAiMessageProvider.notifier)
                      .runAutomationDryRun(p.workflowId),
                ),
              if ((p.isDraft || p.isPaused) && p.workflowId.isNotEmpty)
                EmmaActionPill(
                  label: 'automation_activate'.tr,
                  icon: Icons.rocket_launch_outlined,
                  color: Colors.greenAccent,
                  onTap: () => _confirmAndActivate(
                    context,
                    ref,
                    p.workflowId,
                    p.name,
                  ),
                ),
              if (p.isActive && p.workflowId.isNotEmpty)
                EmmaActionPill(
                  label: 'automation_deactivate'.tr,
                  icon: Icons.pause_circle_outline,
                  color: Colors.orangeAccent,
                  onTap: () => _confirmAndDeactivate(
                    context,
                    ref,
                    p.workflowId,
                    p.name,
                  ),
                ),
              if (p.isActive)
                EmmaActionPill(
                  label: 'automation_runs'.tr,
                  icon: Icons.history_outlined,
                  onTap: () => ref
                      .read(navigationService)
                      .pushNamedScreen(Routes.automationHistory),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
