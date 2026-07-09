import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/route_constant.dart';

import 'package:emma/blocks/core/block_definition.dart';
import 'package:emma/blocks/core/block_descriptor.dart';
import 'package:emma/blocks/definitions/shared/block_ui.dart';
import 'package:emma/provider/emma_notifier.dart';

class AutomationDryRunBlockDefinition extends EmmaBlockDefinition {
  const AutomationDryRunBlockDefinition();

  @override
  String get key => 'automation_dry_run';

  @override
  bool supports(EmmaBlockDescriptor block) {
    return block.type == EmmaBlockType.automationDryRun;
  }

  @override
  Widget buildBlock({
    required BuildContext context,
    required WidgetRef ref,
    required EmmaBlockDescriptor block,
    required double maxWidth,
    required String messageId,
  }) {
    return _AutomationDryRunCard(block: block, maxWidth: maxWidth);
  }
}

// ---------------------------------------------------------------------------

class _DryRunStep {
  final String nodeId;
  final String nodeName;
  final String kind;
  final String status;
  final String? message;
  final Map<String, dynamic> output;

  const _DryRunStep({
    required this.nodeId,
    required this.nodeName,
    required this.kind,
    required this.status,
    this.message,
    required this.output,
  });

  factory _DryRunStep.fromMap(Map<String, dynamic> m) {
    return _DryRunStep(
      nodeId: (m['node_id'] ?? '').toString(),
      nodeName: (m['node_name'] ?? m['name'] ?? 'Węzeł').toString(),
      kind: (m['kind'] ?? 'action').toString(),
      status: (m['status'] ?? 'ok').toString(),
      message: m['message']?.toString(),
      output: m['output'] is Map
          ? Map<String, dynamic>.from(m['output'] as Map)
          : {},
    );
  }

  bool get isOk => status == 'ok' || status == 'success';
  bool get isSkipped => status == 'skipped';
}

class _DryRunPayload {
  final String workflowId;
  final String workflowName;
  final String overallStatus;
  final List<_DryRunStep> steps;
  final String? errorMessage;
  final int duration;

  const _DryRunPayload({
    required this.workflowId,
    required this.workflowName,
    required this.overallStatus,
    required this.steps,
    this.errorMessage,
    required this.duration,
  });

  factory _DryRunPayload.fromBlock(EmmaBlockDescriptor block) {
    final root = block.raw;
    final dryRun = root['dry_run'] is Map
        ? Map<String, dynamic>.from(root['dry_run'] as Map)
        : root;

    final rawSteps = dryRun['steps'];
    final List<_DryRunStep> steps = rawSteps is List
        ? rawSteps
            .whereType<Map>()
            .map((e) => _DryRunStep.fromMap(Map<String, dynamic>.from(e)))
            .toList()
        : [];

    return _DryRunPayload(
      workflowId: (dryRun['workflow_id'] ?? '').toString(),
      workflowName: (dryRun['workflow_name'] ?? root['name'] ?? 'Automatyzacja').toString(),
      overallStatus: (dryRun['status'] ?? root['status'] ?? 'ok').toString(),
      steps: steps,
      errorMessage: dryRun['error']?.toString() ?? root['error']?.toString(),
      duration: (dryRun['duration_ms'] as int?) ?? 0,
    );
  }

  bool get isSuccess => overallStatus == 'ok' || overallStatus == 'success';
}

// ---------------------------------------------------------------------------

class _AutomationDryRunCard extends ConsumerWidget {
  final EmmaBlockDescriptor block;
  final double maxWidth;

  const _AutomationDryRunCard({
    required this.block,
    required this.maxWidth,
  });

  Color get _accent => const Color(0xFF00BCD4);

  IconData _stepIcon(String kind) {
    switch (kind) {
      case 'trigger':
        return Icons.bolt;
      case 'condition':
        return Icons.call_split;
      case 'delay':
        return Icons.timer_outlined;
      case 'aiPrompt':
        return Icons.auto_awesome;
      case 'approval':
        return Icons.verified_outlined;
      default:
        return Icons.play_arrow;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = _DryRunPayload.fromBlock(block);
    final accent = _accent;
    final statusColor = p.isSuccess ? Colors.greenAccent : Colors.redAccent;

    return EmmaBlockCardShell(
      maxWidth: maxWidth,
      borderColor: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // nagłówek
          Row(
            children: [
              Icon(Icons.science_outlined, size: 13, color: accent),
              const SizedBox(width: 5),
              Text(
                'automation_dry_run_result'.tr,
                style: TextStyle(
                  color: accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Icon(
                p.isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                size: 14,
                color: statusColor,
              ),
              const SizedBox(width: 4),
              Text(
                p.isSuccess
                    ? 'automation_dry_run_ok'.tr
                    : 'automation_dry_run_failed'.tr,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),
          Text(
            p.workflowName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),

          if (p.duration > 0) ...[
            const SizedBox(height: 2),
            Text(
              '${p.duration} ms',
              style: const TextStyle(color: Colors.white38, fontSize: 10),
            ),
          ],

          // błąd globalny
          if (p.errorMessage != null && p.errorMessage!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.redAccent.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.redAccent.withAlpha(60)),
              ),
              child: Text(
                p.errorMessage!,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ),
          ],

          // kroki
          if (p.steps.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...p.steps.map((step) => _StepRow(step: step)),
          ],

          const SizedBox(height: 10),

          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (p.isSuccess && p.workflowId.isNotEmpty)
                EmmaActionPill(
                  label: 'automation_activate'.tr,
                  icon: Icons.rocket_launch_outlined,
                  onTap: () => ref
                      .read(chatAiMessageProvider.notifier)
                      .activateAutomationWorkflow(p.workflowId),
                ),
              if (p.workflowId.isNotEmpty)
                EmmaActionPill(
                  label: 'automation_open_builder'.tr,
                  icon: Icons.schema_outlined,
                  onTap: () => ref.read(navigationService).pushNamedScreen(
                        Routes.automationBuilderPattern
                            .replaceAll(':workflowId', p.workflowId),
                      ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatefulWidget {
  final _DryRunStep step;

  const _StepRow({required this.step});

  @override
  State<_StepRow> createState() => _StepRowState();
}

class _StepRowState extends State<_StepRow> {
  bool _expanded = false;

  Color get _statusColor {
    if (widget.step.isSkipped) return Colors.white38;
    if (widget.step.isOk) return Colors.greenAccent;
    return Colors.redAccent;
  }

  IconData get _statusIcon {
    if (widget.step.isSkipped) return Icons.remove_circle_outline;
    if (widget.step.isOk) return Icons.check_circle_outline;
    return Icons.cancel_outlined;
  }

  IconData get _kindIcon {
    switch (widget.step.kind) {
      case 'trigger':
        return Icons.bolt;
      case 'condition':
        return Icons.call_split;
      case 'delay':
        return Icons.timer_outlined;
      case 'aiPrompt':
        return Icons.auto_awesome;
      case 'approval':
        return Icons.verified_outlined;
      case 'code':
        return Icons.code;
      case 'webhook':
        return Icons.webhook_outlined;
      default:
        return Icons.play_arrow;
    }
  }

  bool get _hasOutput => widget.step.output.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: _hasOutput ? () => setState(() => _expanded = !_expanded) : null,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ikona rodzaju węzła
                Icon(_kindIcon, size: 12, color: Colors.white38),
                const SizedBox(width: 5),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.step.nodeName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (widget.step.message != null &&
                          widget.step.message!.isNotEmpty)
                        Text(
                          widget.step.message!,
                          style: TextStyle(
                            color: _statusColor.withAlpha(180),
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                // ikona statusu + opcjonalny chevron
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_statusIcon, size: 14, color: _statusColor),
                    if (_hasOutput) ...[
                      const SizedBox(width: 2),
                      Icon(
                        _expanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                        size: 14,
                        color: Colors.white38,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (_expanded && _hasOutput)
            Container(
              margin: const EdgeInsets.only(left: 17, top: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(8),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withAlpha(20)),
              ),
              child: Text(
                widget.step.output.entries
                    .map((e) => '${e.key}: ${e.value}')
                    .join('\n'),
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  fontFamily: 'monospace',
                  height: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
