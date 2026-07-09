import 'automation_common.dart';
import 'automation_graph.dart';

class AutomationWorkflowMeta {
  final AutomationWorkflowVisibility visibility;
  final AutomationWorkflowSource createdVia;
  final AutomationWorkflowRiskLevel riskLevel;
  final AutomationWorkflowReviewStatus reviewStatus;
  final AutomationTriggerType triggerType;
  final int? companyId;
  final int? teamId;
  final int? createdById;
  final int? requestedById;
  final bool createdViaEmma;
  final bool requiresReview;
  final String emmaSessionId;
  final String emmaRequestText;
  final List<String> riskReasons;
  final Map<String, dynamic> riskSnapshot;
  final Map<String, dynamic> emmaContext;

  const AutomationWorkflowMeta({
    this.visibility = AutomationWorkflowVisibility.private,
    this.createdVia = AutomationWorkflowSource.user,
    this.riskLevel = AutomationWorkflowRiskLevel.low,
    this.reviewStatus = AutomationWorkflowReviewStatus.notRequired,
    this.triggerType = AutomationTriggerType.event,
    this.companyId,
    this.teamId,
    this.createdById,
    this.requestedById,
    this.createdViaEmma = false,
    this.requiresReview = false,
    this.emmaSessionId = '',
    this.emmaRequestText = '',
    this.riskReasons = const [],
    this.riskSnapshot = const {},
    this.emmaContext = const {},
  });

  factory AutomationWorkflowMeta.fromJson(Map<String, dynamic> json) {
    return AutomationWorkflowMeta(
      visibility: workflowVisibilityFromJson(json['visibility']?.toString()),
      createdVia: workflowSourceFromJson(json['created_via']?.toString()),
      riskLevel: workflowRiskFromJson(json['risk_level']?.toString()),
      reviewStatus: workflowReviewStatusFromJson(json['review_status']?.toString()),
      triggerType: triggerTypeFromJson(json['trigger_type']?.toString()),
      companyId: asInt(json['company_id'] ?? json['company']),
      teamId: asInt(json['team_id'] ?? json['team']),
      createdById: asInt(json['created_by_id'] ?? json['created_by']),
      requestedById: asInt(json['requested_by_id'] ?? json['requested_by']),
      createdViaEmma: asBool(json['created_via_emma']),
      requiresReview: asBool(json['requires_review']),
      emmaSessionId: json['emma_session_id']?.toString() ?? '',
      emmaRequestText: json['emma_request_text']?.toString() ?? '',
      riskReasons: asStringList(json['risk_reasons']),
      riskSnapshot: asMap(json['risk_snapshot']),
      emmaContext: asMap(json['emma_context']),
    );
  }

  Map<String, dynamic> toJsonForSave() => {
        'visibility': enumName(visibility),
        'trigger_type': enumName(triggerType),
        'company': companyId,
        'team': teamId,
        'requested_by': requestedById,
      }..removeWhere((_, value) => value == null);
}

/// Use this helper if you do not want to immediately replace your current
/// AutomationWorkflow model. It extracts the new backend fields from workflow json.
AutomationWorkflowMeta automationWorkflowMetaFromJson(Map<String, dynamic> json) {
  return AutomationWorkflowMeta.fromJson(json);
}

Map<String, dynamic> mergeWorkflowMetaForSave({
  required Map<String, dynamic> workflowPayload,
  required AutomationWorkflowMeta meta,
  AutomationGraph? graph,
}) {
  return {
    ...workflowPayload,
    ...meta.toJsonForSave(),
    if (graph != null) 'graph_json': graph.toJson(),
  };
}
