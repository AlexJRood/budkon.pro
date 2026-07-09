class AutomationNewFeatureURLs {
  static const baseUrl = 'https://www.superbee.cloud/automation/';
  static String u(String path) => '$baseUrl$path';

  static String workflowAssessRisk(String id) => u('workflows/$id/assess-risk/');
  static String workflowDryRun(String id) => u('workflows/$id/dry-run/');
  static String workflowRequestReview(String id) => u('workflows/$id/request-review/');
  static String workflowApproveReview(String id) => u('workflows/$id/approve-review/');
  static String workflowRejectReview(String id) => u('workflows/$id/reject-review/');
  static String workflowIncomingApi(String id) => u('workflows/$id/incoming-api/');

  static final workflowReviews = u('workflow-reviews/');
  static String respondWorkflowReview(String id) => u('workflow-reviews/$id/respond/');

  static final companyPolicies = u('company-policies/');
  static String companyPolicyDetail(String id) => u('company-policies/$id/');

  static final templates = u('templates/');
  static String createWorkflowFromTemplate(String id) => u('templates/$id/create-workflow/');

  static final codeBlocks = u('code-blocks/');
  static final codeExecutions = u('code-executions/');
  static final validateInlineCodeBlock = u('code-blocks/validate-inline/');
  static String codeBlockDetail(String id) => u('code-blocks/$id/');
  static String validateCodeBlock(String id) => u('code-blocks/$id/validate/');
  static String dryRunCodeBlock(String id) => u('code-blocks/$id/dry-run/');
  static String requestCodeBlockReview(String id) => u('code-blocks/$id/request-review/');
  static String approveCodeBlock(String id) => u('code-blocks/$id/approve/');
  static String rejectCodeBlock(String id) => u('code-blocks/$id/reject/');
  static String executeCodeBlock(String id) => u('code-blocks/$id/execute/');

  static final ifttt = u('ifttt/');
  static String emitApiEvent(String signalKey) => u('events/$signalKey/');
}
