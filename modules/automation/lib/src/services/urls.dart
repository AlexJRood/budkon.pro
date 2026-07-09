class AutomationURLs {
  static const baseUrl = 'https://www.superbee.cloud/automation/';

  static String appendBaseUrl(String url) => '$baseUrl$url';

  // =====================================================================
  // Catalog
  // =====================================================================

  static final catalog = appendBaseUrl('catalog/');

  // =====================================================================
  // Workflows
  // =====================================================================

  static final workflows = appendBaseUrl('workflows/');
  static final workflowSearch = appendBaseUrl('workflows/');

  static String workflowDetail(String workflowId) {
    return appendBaseUrl('workflows/$workflowId/');
  }

  static String activateWorkflow(String workflowId) {
    return appendBaseUrl('workflows/$workflowId/activate/');
  }

  static String deactivateWorkflow(String workflowId) {
    return appendBaseUrl('workflows/$workflowId/deactivate/');
  }

  static String testWorkflow(String workflowId) {
    return appendBaseUrl('workflows/$workflowId/test/');
  }

  // =====================================================================
  // Runs / Events / History
  // =====================================================================

  static final runs = appendBaseUrl('runs/');
  static final events = appendBaseUrl('events/');

  static String runDetail(String runId) {
    return appendBaseUrl('runs/$runId/');
  }

  static String eventDetail(String eventId) {
    return appendBaseUrl('events/$eventId/');
  }

  // =====================================================================
  // Approvals
  // =====================================================================

  static final approvals = appendBaseUrl('approvals/');

  static String approvalDetail(String approvalId) {
    return appendBaseUrl('approvals/$approvalId/');
  }

  static String respondApproval(String approvalId) {
    return appendBaseUrl('approvals/$approvalId/respond/');
  }

  // =====================================================================
  // Resources / Actions / Signals
  // =====================================================================

  static final signals = appendBaseUrl('signals/');
  static final actions = appendBaseUrl('actions/');
  static final resources = appendBaseUrl('resources/');

  static String signalDetail(String signalKey) {
    return appendBaseUrl('signals/$signalKey/');
  }

  static String actionDetail(String actionKey) {
    return appendBaseUrl('actions/$actionKey/');
  }

  static String resourceDetail(String resourceKey) {
    return appendBaseUrl('resources/$resourceKey/');
  }

  // =====================================================================
  // Optional future endpoints
  // =====================================================================

  static final schedules = appendBaseUrl('schedules/');
  static final webhooks = appendBaseUrl('webhooks/');
  static final deadLetters = appendBaseUrl('dead-letters/');
  static final auditLogs = appendBaseUrl('audit-logs/');

  static String scheduleDetail(String scheduleId) {
    return appendBaseUrl('schedules/$scheduleId/');
  }

  static String webhookDetail(String webhookId) {
    return appendBaseUrl('webhooks/$webhookId/');
  }

  static String deadLetterDetail(String deadLetterId) {
    return appendBaseUrl('dead-letters/$deadLetterId/');
  }

  static String auditLogDetail(String auditLogId) {
    return appendBaseUrl('audit-logs/$auditLogId/');
  }
}