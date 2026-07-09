import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/automation_event.dart';
import '../models/automation_run.dart';
import 'automation_api_provider.dart';

final automationRunsProvider =
    FutureProvider.family.autoDispose<List<AutomationRun>, String?>((ref, workflowId) async {
  return ref.watch(automationApiServiceProvider).fetchRuns(workflowId: workflowId);
});

final automationRunDetailProvider =
    FutureProvider.family.autoDispose<AutomationRun, String>((ref, runId) async {
  return ref.watch(automationApiServiceProvider).fetchRun(runId);
});

final automationEventsProvider =
    FutureProvider.family.autoDispose<List<AutomationEventLog>, String?>((ref, signalKey) async {
  return ref.watch(automationApiServiceProvider).fetchEvents(signalKey: signalKey);
});

final automationApprovalsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(automationApiServiceProvider).fetchApprovals();
});
