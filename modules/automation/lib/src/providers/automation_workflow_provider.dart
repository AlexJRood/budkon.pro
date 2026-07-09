import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/automation_common.dart';
import '../models/automation_workflow.dart';
import 'automation_api_provider.dart';

class AutomationWorkflowListQuery {
  final AutomationScopeType? scopeType;
  final int? companyId;
  final int? ownerId;
  final String? status;

  const AutomationWorkflowListQuery({
    this.scopeType,
    this.companyId,
    this.ownerId,
    this.status,
  });

  @override
  bool operator ==(Object other) {
    return other is AutomationWorkflowListQuery &&
        other.scopeType == scopeType &&
        other.companyId == companyId &&
        other.ownerId == ownerId &&
        other.status == status;
  }

  @override
  int get hashCode => Object.hash(scopeType, companyId, ownerId, status);
}

final automationWorkflowListProvider = FutureProvider.family
    .autoDispose<List<AutomationWorkflow>, AutomationWorkflowListQuery>((ref, query) async {
  return ref.watch(automationApiServiceProvider).fetchWorkflows(
        scopeType: query.scopeType,
        companyId: query.companyId,
        ownerId: query.ownerId,
        status: query.status,
      );
});

final automationWorkflowProvider =
    FutureProvider.family.autoDispose<AutomationWorkflow, String>((ref, id) async {
  return ref.watch(automationApiServiceProvider).fetchWorkflow(id);
});
