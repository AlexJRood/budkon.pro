import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/automation_code_block.dart';
import '../models/automation_governance.dart';
import '../models/automation_template.dart';
import '../services/automation_api_service_new_features.dart';
import 'automation_api_provider.dart';

final automationWorkflowReviewsProvider =
    FutureProvider.family.autoDispose<List<AutomationWorkflowReviewRequest>, int?>((ref, companyId) {
  return ref.watch(automationApiServiceProvider).fetchWorkflowReviews(companyId: companyId);
});

final automationCompanyPoliciesProvider =
    FutureProvider.family.autoDispose<List<AutomationCompanyPolicy>, int?>((ref, companyId) {
  return ref.watch(automationApiServiceProvider).fetchCompanyPolicies(companyId: companyId);
});

class AutomationCodeBlockQuery {
  final String? workflowId;
  final int? companyId;
  final String? status;
  const AutomationCodeBlockQuery({this.workflowId, this.companyId, this.status});

  @override
  bool operator ==(Object other) =>
      other is AutomationCodeBlockQuery &&
      other.workflowId == workflowId &&
      other.companyId == companyId &&
      other.status == status;

  @override
  int get hashCode => Object.hash(workflowId, companyId, status);
}

final automationCodeBlocksProvider =
    FutureProvider.family.autoDispose<List<AutomationCodeBlock>, AutomationCodeBlockQuery>((ref, query) {
  return ref.watch(automationApiServiceProvider).fetchCodeBlocks(
        workflowId: query.workflowId,
        companyId: query.companyId,
        status: query.status,
      );
});

final automationTemplatesProvider =
    FutureProvider.family.autoDispose<List<AutomationTemplate>, int?>((ref, companyId) {
  return ref.watch(automationApiServiceProvider).fetchTemplates(companyId: companyId);
});
