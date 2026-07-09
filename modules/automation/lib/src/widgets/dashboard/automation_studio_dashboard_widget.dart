import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';

import '../../config/automation_studio_config.dart';
import '../../models/automation_common.dart';
import '../../models/automation_context.dart';
import '../../models/automation_run.dart';
import '../../models/automation_workflow.dart';
import '../../providers/automation_api_provider.dart';
import '../../providers/automation_history_provider.dart';
import '../../providers/automation_workflow_provider.dart';
import '../../screens/automation_builder_screen.dart';
import '../../screens/automation_history_screen.dart';
import '../../screens/automation_workflow_list_screen.dart';
import '../popup/automation_studio_popup.dart';

class AutomationStudioDashboardWidget extends ConsumerWidget {
  final bool isMobile;
  final bool isEditMode;
  final Map<String, dynamic> settings;
  final AutomationContextData? contextData;
  const AutomationStudioDashboardWidget({
    super.key,
    this.isMobile = false,
    this.isEditMode = false,
    this.settings = const {},
    this.contextData,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = automationColors(context, ref);
    final mode = _settingString(settings, 'mode', 'overview');
    final compact = _settingBool(settings, 'compact', false) || isMobile;
    final showHeader = _settingBool(settings, 'showHeader', true);
    final maxItems = _settingInt(settings, 'maxItems', compact ? 3 : 5);
    final workflowStatus = _nullableSettingString(settings, 'workflowStatus');
    final scopeType = _scopeTypeFromSettings(settings, contextData);
    final companyId = _settingIntNullable(settings, 'companyId') ?? contextData?.companyId;
    final ownerId = _settingIntNullable(settings, 'ownerId') ?? contextData?.userId;

    final query = AutomationWorkflowListQuery(
      scopeType: scopeType,
      companyId: companyId,
      ownerId: ownerId,
      status: workflowStatus,
    );

    final workflowsAsync = ref.watch(automationWorkflowListProvider(query));
    final runsAsync = ref.watch(automationRunsProvider(null));
    final approvalsAsync = ref.watch(automationApprovalsProvider);

    return Container(
      height: double.infinity,
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: DefaultTextStyle(
        style: TextStyle(color: colors.text),
        child: Column(
          children: [
            if (showHeader)
              _AutomationDashboardHeader(
                compact: compact,
                mode: mode,
                contextData: contextData,
                onOpenStudio: () => _openStudio(context, ref),
                onOpenCanvas: () => _openCanvas(context),
                onOpenHistory: () => _openHistory(context),
              ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  compact ? 10 : 14,
                  showHeader ? 0 : (compact ? 10 : 14),
                  compact ? 10 : 14,
                  compact ? 10 : 14,
                ),
                child: switch (mode) {
                  'workflows' => _WorkflowListPanel(
                      workflowsAsync: workflowsAsync,
                      maxItems: maxItems,
                      compact: compact,
                      query: query,
                    ),
                  'history' => _HistoryPanel(
                      runsAsync: runsAsync,
                      maxItems: maxItems,
                      compact: compact,
                    ),
                  'approvals' => _ApprovalsPanel(
                      approvalsAsync: approvalsAsync,
                      maxItems: maxItems,
                      compact: compact,
                    ),
                  _ => _OverviewPanel(
                      workflowsAsync: workflowsAsync,
                      runsAsync: runsAsync,
                      approvalsAsync: approvalsAsync,
                      maxItems: maxItems,
                      compact: compact,
                      query: query,
                    ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openStudio(BuildContext context, WidgetRef ref) {
    final ctx = contextData ?? _dashboardContextFromSettings(settings);
    
    final theme = ref.read(themeColorsProvider);

    showAutomationStudioPopup(
      theme,
      context,
      contextData: ctx,
    );
  }

  void _openCanvas(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AutomationBuilderScreen(
          contextData: contextData ?? _dashboardContextFromSettings(settings),
        ),
      ),
    );
  }

  void _openHistory(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AutomationHistoryScreen(),
      ),
    );
  }
}

class _AutomationDashboardHeader extends StatelessWidget {
  final bool compact;
  final String mode;
  final AutomationContextData? contextData;
  final VoidCallback onOpenStudio;
  final VoidCallback onOpenCanvas;
  final VoidCallback onOpenHistory;

  const _AutomationDashboardHeader({
    required this.compact,
    required this.mode,
    required this.contextData,
    required this.onOpenStudio,
    required this.onOpenCanvas,
    required this.onOpenHistory,
  });

  @override
  Widget build(BuildContext context) {
    final colors = automationColors(context);
    final title = automationT(context, 'automation.dashboard.title');
    final subtitle = contextData?.sourceLabel ?? automationT(context, 'automation.dashboard.subtitle');

    return Container(
      padding: EdgeInsets.fromLTRB(compact ? 10 : 14, compact ? 10 : 12, compact ? 8 : 12, compact ? 8 : 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 34 : 40,
            height: compact ? 34 : 40,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.auto_awesome_motion_rounded,
              color: colors.primary,
              size: compact ? 18 : 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title == 'automation.dashboard.title' ? 'Automation Studio' : title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 13 : 15,
                    fontWeight: FontWeight.w800,
                    color: colors.text,
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle == 'automation.dashboard.subtitle' ? 'Workflows, history and approvals' : subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.mutedText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!compact) ...[
            _HeaderButton(
              icon: Icons.history_rounded,
              label: 'History',
              onTap: onOpenHistory,
            ),
            const SizedBox(width: 6),
            _HeaderButton(
              icon: Icons.account_tree_rounded,
              label: 'Canvas',
              onTap: onOpenCanvas,
            ),
            const SizedBox(width: 6),
          ],
          IconButton(
            tooltip: 'Open Automation Studio',
            onPressed: onOpenStudio,
            icon: const Icon(Icons.open_in_new_rounded),
          ),
        ],
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HeaderButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = automationColors(context);

    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.text,
        side: BorderSide(color: colors.border),
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
    );
  }
}

class _OverviewPanel extends ConsumerWidget {
  final AsyncValue<List<AutomationWorkflow>> workflowsAsync;
  final AsyncValue<List<AutomationRun>> runsAsync;
  final AsyncValue<List<Map<String, dynamic>>> approvalsAsync;
  final AutomationWorkflowListQuery query;
  final int maxItems;
  final bool compact;

  const _OverviewPanel({
    required this.workflowsAsync,
    required this.runsAsync,
    required this.approvalsAsync,
    required this.query,
    required this.maxItems,
    required this.compact,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = automationColors(context);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                label: 'Active',
                icon: Icons.play_circle_fill_rounded,
                color: colors.success,
                value: workflowsAsync.maybeWhen(
                  data: (items) => items.where((e) => e.status == AutomationWorkflowStatus.active).length.toString(),
                  orElse: () => '…',
                ),
                compact: compact,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MetricTile(
                label: 'Runs',
                icon: Icons.bolt_rounded,
                color: colors.primary,
                value: runsAsync.maybeWhen(
                  data: (items) => items.length.toString(),
                  orElse: () => '…',
                ),
                compact: compact,
              ),
            ),
            if (!compact) ...[
              const SizedBox(width: 8),
              Expanded(
                child: _MetricTile(
                  label: 'Approvals',
                  icon: Icons.rate_review_rounded,
                  color: colors.warning,
                  value: approvalsAsync.maybeWhen(
                    data: (items) => items.length.toString(),
                    orElse: () => '…',
                  ),
                  compact: compact,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: _WorkflowListPanel(
            workflowsAsync: workflowsAsync,
            maxItems: maxItems,
            compact: compact,
            query: query,
          ),
        ),
      ],
    );
  }
}

class _WorkflowListPanel extends ConsumerWidget {
  final AsyncValue<List<AutomationWorkflow>> workflowsAsync;
  final AutomationWorkflowListQuery query;
  final int maxItems;
  final bool compact;

  const _WorkflowListPanel({
    required this.workflowsAsync,
    required this.query,
    required this.maxItems,
    required this.compact,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return workflowsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _InlineError(message: error.toString()),
      data: (items) {
        if (items.isEmpty) {
          return _InlineEmpty(
            icon: Icons.account_tree_rounded,
            title: 'No automations yet',
            message: 'Create a workflow for this dashboard or context.',
            compact: compact,
          );
        }

        final visible = items.take(maxItems).toList();

        return ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: visible.length,
          separatorBuilder: (_, __) => SizedBox(height: compact ? 6 : 8),
          itemBuilder: (context, index) {
            final item = visible[index];
            return _WorkflowRow(
              workflow: item,
              compact: compact,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AutomationBuilderScreen(workflowId: item.id),
                  ),
                );
              },
              onToggle: () async {
                final api = ref.read(automationApiServiceProvider);
                if (item.status == AutomationWorkflowStatus.active) {
                  await api.deactivateWorkflow(item.id);
                } else {
                  await api.activateWorkflow(item.id);
                }
                ref.invalidate(automationWorkflowListProvider(query));
              },
            );
          },
        );
      },
    );
  }
}

class _HistoryPanel extends StatelessWidget {
  final AsyncValue<List<AutomationRun>> runsAsync;
  final int maxItems;
  final bool compact;

  const _HistoryPanel({
    required this.runsAsync,
    required this.maxItems,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return runsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _InlineError(message: error.toString()),
      data: (items) {
        if (items.isEmpty) {
          return _InlineEmpty(
            icon: Icons.history_rounded,
            title: 'No runs yet',
            message: 'Automation executions will appear here.',
            compact: compact,
          );
        }

        final visible = items.take(maxItems).toList();

        return ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: visible.length,
          separatorBuilder: (_, __) => SizedBox(height: compact ? 6 : 8),
          itemBuilder: (context, index) {
            final run = visible[index];
            return _RunRow(run: run, compact: compact);
          },
        );
      },
    );
  }
}

class _ApprovalsPanel extends StatelessWidget {
  final AsyncValue<List<Map<String, dynamic>>> approvalsAsync;
  final int maxItems;
  final bool compact;

  const _ApprovalsPanel({
    required this.approvalsAsync,
    required this.maxItems,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return approvalsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _InlineError(message: error.toString()),
      data: (items) {
        if (items.isEmpty) {
          return _InlineEmpty(
            icon: Icons.rate_review_rounded,
            title: 'No approvals',
            message: 'Pending approvals will appear here.',
            compact: compact,
          );
        }

        final visible = items.take(maxItems).toList();

        return ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: visible.length,
          separatorBuilder: (_, __) => SizedBox(height: compact ? 6 : 8),
          itemBuilder: (context, index) {
            final item = visible[index];
            return _ApprovalRow(item: item, compact: compact);
          },
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool compact;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final colors = automationColors(context);

    return Container(
      padding: EdgeInsets.all(compact ? 8 : 10),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: compact ? 16 : 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: colors.mutedText, fontSize: compact ? 10 : 11),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: colors.text,
              fontWeight: FontWeight.w900,
              fontSize: compact ? 13 : 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkflowRow extends StatelessWidget {
  final AutomationWorkflow workflow;
  final bool compact;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  const _WorkflowRow({
    required this.workflow,
    required this.compact,
    required this.onTap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = automationColors(context);
    final active = workflow.status == AutomationWorkflowStatus.active;

    return Material(
      color: colors.surfaceAlt,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: compact ? 9 : 12, vertical: compact ? 8 : 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Icon(
                active ? Icons.play_circle_fill_rounded : Icons.pause_circle_outline_rounded,
                color: active ? colors.success : colors.warning,
                size: compact ? 18 : 21,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workflow.name.isEmpty ? 'Untitled automation' : workflow.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.text,
                        fontSize: compact ? 12 : 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (!compact) ...[
                      const SizedBox(height: 3),
                      Text(
                        workflow.triggerKeys.isEmpty ? workflow.description : workflow.triggerKeys.join(', '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: colors.mutedText, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
              Switch(
                value: active,
                onChanged: (_) => onToggle(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RunRow extends StatelessWidget {
  final AutomationRun run;
  final bool compact;

  const _RunRow({required this.run, required this.compact});

  @override
  Widget build(BuildContext context) {
    final colors = automationColors(context);
    final ok = run.status == AutomationRunStatus.success;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 9 : 12, vertical: compact ? 8 : 10),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle_rounded : Icons.error_outline_rounded,
            color: ok ? colors.success : colors.warning,
            size: compact ? 18 : 21,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Run ${run.id}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.text,
                    fontSize: compact ? 12 : 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(height: 3),
                  Text(
                    run.errorMessage.isEmpty ? run.workflowId : run.errorMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.mutedText, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          Text(
            enumName(run.status),
            style: TextStyle(
              color: ok ? colors.success : colors.warning,
              fontWeight: FontWeight.w800,
              fontSize: compact ? 10 : 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _ApprovalRow extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool compact;

  const _ApprovalRow({required this.item, required this.compact});

  @override
  Widget build(BuildContext context) {
    final colors = automationColors(context);
    final title = item['title']?.toString() ?? item['id']?.toString() ?? 'Approval';
    final status = item['status']?.toString() ?? 'pending';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 9 : 12, vertical: compact ? 8 : 10),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.rate_review_rounded, color: colors.warning, size: compact ? 18 : 21),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              title,
              maxLines: compact ? 1 : 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.text,
                fontSize: compact ? 12 : 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            status,
            style: TextStyle(color: colors.warning, fontWeight: FontWeight.w800, fontSize: compact ? 10 : 11),
          ),
        ],
      ),
    );
  }
}

class _InlineEmpty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final bool compact;

  const _InlineEmpty({
    required this.icon,
    required this.title,
    required this.message,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final colors = automationColors(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: colors.mutedText, size: compact ? 28 : 38),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.text, fontWeight: FontWeight.w800, fontSize: compact ? 13 : 15),
            ),
            if (!compact) ...[
              const SizedBox(height: 4),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.mutedText, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;

  const _InlineError({required this.message});

  @override
  Widget build(BuildContext context) {
    final colors = automationColors(context);

    return Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(color: colors.danger, fontSize: 12),
      ),
    );
  }
}

String _settingString(Map<String, dynamic> settings, String key, String fallback) {
  final value = settings[key];
  if (value == null) return fallback;
  final text = value.toString();
  return text.isEmpty ? fallback : text;
}

String? _nullableSettingString(Map<String, dynamic> settings, String key) {
  final value = settings[key];
  if (value == null) return null;
  final text = value.toString();
  return text.isEmpty || text == 'all' ? null : text;
}

bool _settingBool(Map<String, dynamic> settings, String key, bool fallback) {
  final value = settings[key];
  if (value is bool) return value;
  if (value is String) return value.toLowerCase() == 'true';
  return fallback;
}

int _settingInt(Map<String, dynamic> settings, String key, int fallback) {
  return _settingIntNullable(settings, key) ?? fallback;
}

int? _settingIntNullable(Map<String, dynamic> settings, String key) {
  final value = settings[key];
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

AutomationScopeType? _scopeTypeFromSettings(
  Map<String, dynamic> settings,
  AutomationContextData? contextData,
) {
  final raw = settings['scopeType']?.toString();
  if (raw == null || raw.isEmpty || raw == 'auto') {
    return contextData?.defaultScopeType;
  }
  return scopeTypeFromJson(raw);
}

AutomationContextData _dashboardContextFromSettings(Map<String, dynamic> settings) {
  return AutomationContextData.dashboard(
    dashboardId: settings['dashboardId']?.toString(),
    dashboardName: settings['dashboardName']?.toString(),
    dashboardType: settings['dashboardType']?.toString() ?? 'main',
    companyId: _settingIntNullable(settings, 'companyId'),
    userId: _settingIntNullable(settings, 'userId'),
  );
}
