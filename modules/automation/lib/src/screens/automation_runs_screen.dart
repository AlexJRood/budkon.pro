import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/automation_studio_config.dart';
import '../models/automation_common.dart';
import '../models/automation_run.dart';
import '../providers/automation_history_provider.dart';
import '../widgets/common/automation_badge.dart';
import 'automation_run_detail_screen.dart';

class AutomationRunsScreen extends ConsumerStatefulWidget {
  final String? workflowId;

  const AutomationRunsScreen({super.key, this.workflowId});

  @override
  ConsumerState<AutomationRunsScreen> createState() => _AutomationRunsScreenState();
}

class _AutomationRunsScreenState extends ConsumerState<AutomationRunsScreen> {
  String? _statusFilter;

  @override
  Widget build(BuildContext context) {
    final runsAsync = ref.watch(automationRunsProvider(widget.workflowId));
    final colors = automationColors(context, ref);

    return automationShell(
      context,
      ref: ref,
      title: widget.workflowId != null ? 'Workflow runs' : 'All runs',
      screenKey: 'automation.runs',
      child: Column(
        children: [
          _FilterBar(
            selected: _statusFilter,
            onChanged: (v) => setState(() => _statusFilter = v),
          ),
          Expanded(
            child: runsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (runs) {
                final filtered = _statusFilter == null
                    ? runs
                    : runs.where((r) => r.status.name == _statusFilter).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history_toggle_off_rounded, size: 48, color: colors.mutedText),
                        const SizedBox(height: 12),
                        Text('No runs found', style: TextStyle(color: colors.mutedText)),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(automationRunsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      return _RunCard(
                        run: filtered[index],
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AutomationRunDetailScreen(runId: filtered[index].id),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onChanged;

  const _FilterBar({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final statuses = [null, 'success', 'failed', 'running', 'waiting'];
    final labels = ['All', 'Success', 'Failed', 'Running', 'Waiting'];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: statuses.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final isSelected = selected == statuses[i];
          return FilterChip(
            label: Text(labels[i]),
            selected: isSelected,
            onSelected: (_) => onChanged(isSelected ? null : statuses[i]),
            visualDensity: VisualDensity.compact,
          );
        },
      ),
    );
  }
}

class _RunCard extends StatelessWidget {
  final AutomationRun run;
  final VoidCallback onTap;

  const _RunCard({required this.run, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final statusColor = switch (run.status) {
      AutomationRunStatus.success => Colors.green,
      AutomationRunStatus.failed => Colors.redAccent,
      AutomationRunStatus.running => Colors.blue,
      AutomationRunStatus.waiting || AutomationRunStatus.waitingApproval => Colors.orange,
      _ => Colors.grey,
    };

    final duration = _formatDuration(run.startedAt, run.finishedAt);
    final shortId = run.id.length > 8 ? '${run.id.substring(0, 8)}…' : run.id;
    final stepCount = run.nodeRuns.length;

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              _StatusDot(color: statusColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(shortId, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (run.createdAt != null) _formatDate(run.createdAt!),
                        if (stepCount > 0) '$stepCount steps',
                        if (duration != null) duration,
                      ].join(' · '),
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                    if (run.errorMessage.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        run.errorMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.redAccent),
                      ),
                    ],
                  ],
                ),
              ),
              AutomationBadge(label: run.status.name, color: statusColor),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  String? _formatDuration(DateTime? start, DateTime? end) {
    if (start == null || end == null) return null;
    final ms = end.difference(start).inMilliseconds;
    if (ms < 0) return null;
    if (ms < 1000) return '${ms}ms';
    return '${(ms / 1000).toStringAsFixed(1)}s';
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day}.${dt.month.toString().padLeft(2, '0')}';
  }
}

class _StatusDot extends StatelessWidget {
  final Color color;

  const _StatusDot({required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}
