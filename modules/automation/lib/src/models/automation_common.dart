enum AutomationScopeType {
  user,
  company,
  team,
  system,
}

enum AutomationWorkflowStatus {
  draft,
  active,
  paused,
  archived,
}

enum AutomationWorkflowVisibility {
  private,
  company,
  companyManagers,
  team,
}

enum AutomationWorkflowRiskLevel {
  low,
  medium,
  high,
  critical,
}

enum AutomationWorkflowReviewStatus {
  notRequired,
  pending,
  approved,
  rejected,
  changesRequested,
  expired,
}

enum AutomationWorkflowSource {
  user,
  emma,
  api,
  system,
}

enum AutomationTriggerType {
  event,
  schedule,
  webhook,
  api,
  manual,
}

enum AutomationNodeKind {
  trigger,
  condition,
  switchNode,
  action,
  delay,
  approval,
  aiPrompt,
  subworkflow,
  end,
}

enum AutomationRunStatus {
  queued,
  running,
  waiting,
  waitingApproval,
  success,
  failed,
  cancelled,
  skipped,
}

enum AutomationCodeLanguage {
  safeExpression,
  python,
  javascript,
}

enum AutomationCodeBlockStatus {
  draft,
  pendingReview,
  approved,
  rejected,
  disabled,
  archived,
}

enum AutomationCodeRiskLevel {
  low,
  medium,
  high,
  critical,
}

enum AutomationCodeExecutionStatus {
  queued,
  running,
  success,
  failed,
  timeout,
  blocked,
  skipped,
}

enum AutomationTemplateVisibility {
  private,
  company,
  system,
  marketplace,
}

String enumName(Object value) {
  final raw = value.toString().split('.').last;
  final buffer = StringBuffer();

  for (var i = 0; i < raw.length; i++) {
    final char = raw[i];
    final isUpper = char.toUpperCase() == char && char.toLowerCase() != char;
    if (isUpper && i != 0) {
      buffer.write('_');
    }
    buffer.write(char.toLowerCase());
  }

  return buffer.toString();
}

String _normalizeEnumValue(String? value) {
  return (value ?? '').trim().toLowerCase().replaceAll('-', '_');
}

AutomationScopeType scopeTypeFromJson(String? value) {
  switch (_normalizeEnumValue(value)) {
    case 'company':
      return AutomationScopeType.company;
    case 'team':
      return AutomationScopeType.team;
    case 'system':
      return AutomationScopeType.system;
    case 'user':
    default:
      return AutomationScopeType.user;
  }
}

AutomationWorkflowStatus workflowStatusFromJson(String? value) {
  switch (_normalizeEnumValue(value)) {
    case 'active':
      return AutomationWorkflowStatus.active;
    case 'paused':
      return AutomationWorkflowStatus.paused;
    case 'archived':
      return AutomationWorkflowStatus.archived;
    case 'draft':
    default:
      return AutomationWorkflowStatus.draft;
  }
}

AutomationWorkflowVisibility workflowVisibilityFromJson(String? value) {
  switch (_normalizeEnumValue(value)) {
    case 'company':
      return AutomationWorkflowVisibility.company;
    case 'company_managers':
      return AutomationWorkflowVisibility.companyManagers;
    case 'team':
      return AutomationWorkflowVisibility.team;
    case 'private':
    default:
      return AutomationWorkflowVisibility.private;
  }
}

AutomationWorkflowRiskLevel workflowRiskFromJson(String? value) {
  switch (_normalizeEnumValue(value)) {
    case 'medium':
      return AutomationWorkflowRiskLevel.medium;
    case 'high':
      return AutomationWorkflowRiskLevel.high;
    case 'critical':
      return AutomationWorkflowRiskLevel.critical;
    case 'low':
    default:
      return AutomationWorkflowRiskLevel.low;
  }
}

AutomationWorkflowReviewStatus workflowReviewStatusFromJson(String? value) {
  switch (_normalizeEnumValue(value)) {
    case 'pending':
      return AutomationWorkflowReviewStatus.pending;
    case 'approved':
      return AutomationWorkflowReviewStatus.approved;
    case 'rejected':
      return AutomationWorkflowReviewStatus.rejected;
    case 'changes_requested':
      return AutomationWorkflowReviewStatus.changesRequested;
    case 'expired':
      return AutomationWorkflowReviewStatus.expired;
    case 'not_required':
    default:
      return AutomationWorkflowReviewStatus.notRequired;
  }
}

/// Backward-compatible alias used by older patch files.
AutomationWorkflowReviewStatus reviewStatusFromJson(String? value) {
  return workflowReviewStatusFromJson(value);
}

AutomationWorkflowSource workflowSourceFromJson(String? value) {
  switch (_normalizeEnumValue(value)) {
    case 'emma':
      return AutomationWorkflowSource.emma;
    case 'api':
      return AutomationWorkflowSource.api;
    case 'system':
      return AutomationWorkflowSource.system;
    case 'user':
    default:
      return AutomationWorkflowSource.user;
  }
}

AutomationTriggerType triggerTypeFromJson(String? value) {
  switch (_normalizeEnumValue(value)) {
    case 'schedule':
      return AutomationTriggerType.schedule;
    case 'webhook':
      return AutomationTriggerType.webhook;
    case 'api':
      return AutomationTriggerType.api;
    case 'manual':
      return AutomationTriggerType.manual;
    case 'event':
    default:
      return AutomationTriggerType.event;
  }
}

AutomationRunStatus runStatusFromJson(String? value) {
  switch (_normalizeEnumValue(value)) {
    case 'running':
      return AutomationRunStatus.running;
    case 'waiting':
      return AutomationRunStatus.waiting;
    case 'waiting_approval':
      return AutomationRunStatus.waitingApproval;
    case 'success':
      return AutomationRunStatus.success;
    case 'failed':
      return AutomationRunStatus.failed;
    case 'cancelled':
      return AutomationRunStatus.cancelled;
    case 'skipped':
      return AutomationRunStatus.skipped;
    case 'queued':
    default:
      return AutomationRunStatus.queued;
  }
}

AutomationCodeLanguage codeLanguageFromJson(String? value) {
  switch (_normalizeEnumValue(value)) {
    case 'python':
      return AutomationCodeLanguage.python;
    case 'javascript':
      return AutomationCodeLanguage.javascript;
    case 'safe_expression':
    default:
      return AutomationCodeLanguage.safeExpression;
  }
}

AutomationCodeBlockStatus codeBlockStatusFromJson(String? value) {
  switch (_normalizeEnumValue(value)) {
    case 'pending_review':
      return AutomationCodeBlockStatus.pendingReview;
    case 'approved':
      return AutomationCodeBlockStatus.approved;
    case 'rejected':
      return AutomationCodeBlockStatus.rejected;
    case 'disabled':
      return AutomationCodeBlockStatus.disabled;
    case 'archived':
      return AutomationCodeBlockStatus.archived;
    case 'draft':
    default:
      return AutomationCodeBlockStatus.draft;
  }
}

AutomationCodeRiskLevel codeRiskFromJson(String? value) {
  switch (_normalizeEnumValue(value)) {
    case 'low':
      return AutomationCodeRiskLevel.low;
    case 'medium':
      return AutomationCodeRiskLevel.medium;
    case 'critical':
      return AutomationCodeRiskLevel.critical;
    case 'high':
    default:
      return AutomationCodeRiskLevel.high;
  }
}

AutomationCodeExecutionStatus codeExecutionStatusFromJson(String? value) {
  switch (_normalizeEnumValue(value)) {
    case 'running':
      return AutomationCodeExecutionStatus.running;
    case 'success':
      return AutomationCodeExecutionStatus.success;
    case 'failed':
      return AutomationCodeExecutionStatus.failed;
    case 'timeout':
      return AutomationCodeExecutionStatus.timeout;
    case 'blocked':
      return AutomationCodeExecutionStatus.blocked;
    case 'skipped':
      return AutomationCodeExecutionStatus.skipped;
    case 'queued':
    default:
      return AutomationCodeExecutionStatus.queued;
  }
}

AutomationTemplateVisibility templateVisibilityFromJson(String? value) {
  switch (_normalizeEnumValue(value)) {
    case 'company':
      return AutomationTemplateVisibility.company;
    case 'system':
      return AutomationTemplateVisibility.system;
    case 'marketplace':
      return AutomationTemplateVisibility.marketplace;
    case 'private':
    default:
      return AutomationTemplateVisibility.private;
  }
}

int? asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

bool asBool(
  dynamic value, {
  bool defaultValue = false,
  bool? fallback,
}) {
  final effectiveDefault = fallback ?? defaultValue;

  if (value == null) return effectiveDefault;
  if (value is bool) return value;
  if (value is num) return value != 0;

  final normalized = value.toString().trim().toLowerCase();
  if (['true', '1', 'yes', 'y', 'tak'].contains(normalized)) return true;
  if (['false', '0', 'no', 'n', 'nie'].contains(normalized)) return false;

  return effectiveDefault;
}

DateTime? asDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;

  final raw = value.toString().trim();
  if (raw.isEmpty) return null;

  return DateTime.tryParse(raw);
}

Map<String, dynamic> asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

List<Map<String, dynamic>> asMapList(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

List<String> asStringList(dynamic value) {
  if (value == null) return const [];

  if (value is List) {
    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList();
  }

  final raw = value.toString().trim();
  if (raw.isEmpty) return const [];

  return raw
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
}

/// Backward-compatible alias used by older patch files.
List<String> asStrings(dynamic value) => asStringList(value);
