import 'automation_common.dart';

class AutomationWorkflowReviewRequest {
  final String id;
  final String workflowId;
  final AutomationWorkflowReviewStatus status;
  final AutomationWorkflowRiskLevel riskLevel;
  final String title;
  final String message;
  final List<String> riskReasons;
  final DateTime? createdAt;

  const AutomationWorkflowReviewRequest({
    required this.id,
    required this.workflowId,
    required this.status,
    required this.riskLevel,
    this.title = '',
    this.message = '',
    this.riskReasons = const [],
    this.createdAt,
  });

  factory AutomationWorkflowReviewRequest.fromJson(Map<String, dynamic> json) {
    return AutomationWorkflowReviewRequest(
      id: json['id']?.toString() ?? '',
      workflowId: json['workflow_id']?.toString() ?? json['workflow']?.toString() ?? '',
      status: workflowReviewStatusFromJson(json['status']?.toString()),
      riskLevel: workflowRiskFromJson(json['risk_level']?.toString()),
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      riskReasons: asStringList(json['risk_reasons']),
      createdAt: asDate(json['created_at']),
    );
  }
}

class AutomationDryRunPlan {
  final bool ok;
  final List<Map<String, dynamic>> steps;
  final List<String> warnings;
  final Map<String, dynamic> raw;

  const AutomationDryRunPlan({
    this.ok = false,
    this.steps = const [],
    this.warnings = const [],
    this.raw = const {},
  });

  factory AutomationDryRunPlan.fromJson(Map<String, dynamic> json) {
    return AutomationDryRunPlan(
      ok: asBool(json['ok']),
      steps: asMapList(json['steps'] ?? json['would_execute']),
      warnings: asStringList(json['warnings']),
      raw: json,
    );
  }
}

class AutomationCompanyPolicy {
  final String id;
  final int? companyId;
  final bool allowEmmaCreate;
  final bool allowEmmaUpdate;
  final bool allowEmmaActivate;
  final bool requireReviewForEmma;
  final List<String> requireReviewRiskLevels;
  final List<String> blockedActionKeys;

  const AutomationCompanyPolicy({
    required this.id,
    this.companyId,
    this.allowEmmaCreate = true,
    this.allowEmmaUpdate = true,
    this.allowEmmaActivate = false,
    this.requireReviewForEmma = true,
    this.requireReviewRiskLevels = const ['medium', 'high', 'critical'],
    this.blockedActionKeys = const [],
  });

  factory AutomationCompanyPolicy.fromJson(Map<String, dynamic> json) {
    return AutomationCompanyPolicy(
      id: json['id']?.toString() ?? '',
      companyId: asInt(json['company_id'] ?? json['company']),
      allowEmmaCreate: asBool(json['allow_emma_create'], fallback: true),
      allowEmmaUpdate: asBool(json['allow_emma_update'], fallback: true),
      allowEmmaActivate: asBool(json['allow_emma_activate']),
      requireReviewForEmma: asBool(json['require_review_for_emma'], fallback: true),
      requireReviewRiskLevels: asStringList(json['require_review_risk_levels']),
      blockedActionKeys: asStringList(json['blocked_action_keys']),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id.isNotEmpty) 'id': id,
        'company': companyId,
        'allow_emma_create': allowEmmaCreate,
        'allow_emma_update': allowEmmaUpdate,
        'allow_emma_activate': allowEmmaActivate,
        'require_review_for_emma': requireReviewForEmma,
        'require_review_risk_levels': requireReviewRiskLevels,
        'blocked_action_keys': blockedActionKeys,
      }..removeWhere((_, value) => value == null);
}
