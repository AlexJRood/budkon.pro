import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/automation_studio_config.dart';
import '../providers/automation_history_provider.dart';
import '../widgets/common/automation_badge.dart';

class AutomationHistoryScreen extends ConsumerWidget {
  final String? workflowId;

  const AutomationHistoryScreen({
    super.key,
    this.workflowId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runsAsync = ref.watch(automationRunsProvider(workflowId));
    final eventsAsync = ref.watch(automationEventsProvider(null));

    return automationShell(
      context,
      ref: ref,
      title: 'Automation history',
      screenKey: 'automation.history',
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Runs'),
                Tab(text: 'Events'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  runsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Center(child: Text(error.toString())),
                    data: (runs) => ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemBuilder: (_, index) {
                        final run = runs[index];
                        return ListTile(
                          title: Text('Run ${run.id}'),
                          subtitle: Text(run.errorMessage.isEmpty ? run.workflowId : run.errorMessage),
                          trailing: AutomationBadge(
                            label: run.status.name,
                            color: run.status.name == 'success'
                                ? automationColors(context, ref).success
                                : automationColors(context, ref).warning,
                          ),
                        );
                      },
                      separatorBuilder: (_, __) => const Divider(),
                      itemCount: runs.length,
                    ),
                  ),
                  eventsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Center(child: Text(error.toString())),
                    data: (events) => ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemBuilder: (_, index) {
                        final event = events[index];
                        return ListTile(
                          title: Text(event.signalKey),
                          subtitle: Text(event.errorMessage.isEmpty ? event.id : event.errorMessage),
                          trailing: Text(event.status),
                        );
                      },
                      separatorBuilder: (_, __) => const Divider(),
                      itemCount: events.length,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
