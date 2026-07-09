import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/automation_studio_config.dart';
import '../models/automation_common.dart';
import '../models/automation_run.dart';
import '../providers/automation_history_provider.dart';
import '../widgets/common/automation_badge.dart';

class AutomationRunDetailScreen extends ConsumerWidget {
  final String runId;

  const AutomationRunDetailScreen({super.key, required this.runId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runAsync = ref.watch(automationRunDetailProvider(runId));

    return automationShell(
      context,
      ref: ref,
      title: 'Run detail',
      screenKey: 'automation.run_detail',
      child: runAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (run) => _RunDetailView(run: run),
      ),
    );
  }
}

class _RunDetailView extends StatelessWidget {
  final AutomationRun run;

  const _RunDetailView({required this.run});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final duration = _duration(run.startedAt, run.finishedAt);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _RunHeader(run: run, duration: duration),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          sliver: SliverToBoxAdapter(
            child: Text('Node trace', style: theme.textTheme.titleMedium),
          ),
        ),
        if (run.nodeRuns.isEmpty)
          const SliverFillRemaining(
            child: Center(child: Text('No node runs recorded.')),
          )
        else
          SliverList.separated(
            itemCount: run.nodeRuns.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
            itemBuilder: (context, index) {
              return _NodeRunTile(nodeRun: run.nodeRuns[index], index: index);
            },
          ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
      ],
    );
  }

  String? _duration(DateTime? start, DateTime? end) {
    if (start == null || end == null) return null;
    final ms = end.difference(start).inMilliseconds;
    if (ms < 1000) return '${ms}ms';
    return '${(ms / 1000).toStringAsFixed(1)}s';
  }
}

class _RunHeader extends StatelessWidget {
  final AutomationRun run;
  final String? duration;

  const _RunHeader({required this.run, this.duration});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Run ${run.id.length > 8 ? run.id.substring(0, 8) : run.id}…',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                _StatusBadge(status: run.status),
              ],
            ),
            const SizedBox(height: 8),
            _InfoRow(label: 'Workflow', value: run.workflowId),
            if (run.eventId != null) _InfoRow(label: 'Event', value: run.eventId!),
            if (run.createdAt != null)
              _InfoRow(label: 'Started', value: _formatDate(run.createdAt!)),
            if (duration != null) _InfoRow(label: 'Duration', value: duration!),
            if (run.nodeRuns.isNotEmpty)
              _InfoRow(label: 'Steps', value: '${run.nodeRuns.length}'),
            if (run.errorMessage.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                run.errorMessage,
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.redAccent),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}'
        '.${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(label, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final AutomationRunStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      AutomationRunStatus.success => Colors.green,
      AutomationRunStatus.failed => Colors.redAccent,
      AutomationRunStatus.running => Colors.blue,
      AutomationRunStatus.waiting || AutomationRunStatus.waitingApproval => Colors.orange,
      _ => Colors.grey,
    };
    return AutomationBadge(label: status.name, color: color);
  }
}

class _NodeRunTile extends StatelessWidget {
  final AutomationNodeRun nodeRun;
  final int index;

  const _NodeRunTile({required this.nodeRun, required this.index});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final statusColor = switch (nodeRun.status) {
      AutomationRunStatus.success => Colors.green,
      AutomationRunStatus.failed => Colors.redAccent,
      AutomationRunStatus.running => Colors.blue,
      _ => Colors.grey,
    };

    final icon = _iconForType(nodeRun.nodeType);
    final subtitle = nodeRun.actionKey.isNotEmpty
        ? nodeRun.actionKey
        : nodeRun.nodeType;

    final handle = nodeRun.outputData['selected_handle']?.toString();

    return ExpansionTile(
      leading: CircleAvatar(
        radius: 14,
        backgroundColor: statusColor.withOpacity(0.15),
        child: Icon(icon, size: 16, color: statusColor),
      ),
      title: Text(
        nodeRun.nodeId.length > 16
            ? '${nodeRun.nodeId.substring(0, 16)}…'
            : nodeRun.nodeId,
        style: theme.textTheme.bodyMedium,
      ),
      subtitle: Text(
        [subtitle, if (handle != null && handle.isNotEmpty) '→ $handle'].join('  '),
        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
      ),
      trailing: AutomationBadge(label: nodeRun.status.name, color: statusColor),
      children: [
        if (nodeRun.errorMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              nodeRun.errorMessage,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.redAccent),
            ),
          ),
        if (nodeRun.outputData.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _OutputChips(output: nodeRun.outputData),
          ),
      ],
    );
  }

  IconData _iconForType(String type) => switch (type) {
        'trigger' => Icons.bolt_rounded,
        'condition' => Icons.call_split_rounded,
        'switch' => Icons.alt_route_rounded,
        'action' => Icons.play_arrow_rounded,
        'ai_prompt' => Icons.psychology_rounded,
        'approval' => Icons.approval_rounded,
        'delay' => Icons.timer_rounded,
        'for_each' => Icons.repeat_rounded,
        'parallel' => Icons.account_tree_rounded,
        'loop_until' => Icons.loop_rounded,
        'subworkflow' => Icons.account_tree_outlined,
        'wait_for_event' => Icons.notifications_active_rounded,
        'set_variable' => Icons.data_object,
        'end' => Icons.stop_circle_outlined,
        _ => Icons.circle_outlined,
      };
}

class _OutputChips extends StatelessWidget {
  final Map<String, dynamic> output;

  const _OutputChips({required this.output});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final interesting = output.entries
        .where((e) =>
            !['selected_handles', 'input_data'].contains(e.key) &&
            e.value != null &&
            e.value.toString().isNotEmpty)
        .take(6)
        .toList();

    if (interesting.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        for (final entry in interesting)
          Chip(
            label: Text(
              '${entry.key}: ${entry.value.toString().length > 30 ? '${entry.value.toString().substring(0, 30)}…' : entry.value}',
              style: theme.textTheme.labelSmall,
            ),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
      ],
    );
  }
}
