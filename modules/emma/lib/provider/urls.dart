// emma/provider/urls.dart

class URLsEmma {
  static const httpOrHttps = 'https';
  static const wsOrWss = 'wss';
  static const host = 'www.superbee.cloud';

  static const baseUrl = '$httpOrHttps://$host/emma/';
  static const urlNetworkMonitoring = 'http://www.hously.space';





  static const String superbeeToken = String.fromEnvironment(
    'SUPERBEE_TOKEN',
    defaultValue: 'dev-superbee-token',
  );

  static const String superbeeBaseUrl = 'http://127.0.0.1:43890';

  static const String superbeeTtsSpeech = '$superbeeBaseUrl/tts/speech/';

  static const String superbeeSttHealth = '$superbeeBaseUrl/stt/health/';
  static const String superbeeSttModels = '$superbeeBaseUrl/stt/models/';
  static const String superbeeSttModelLoad = '$superbeeBaseUrl/stt/models/load/';
  static const String superbeeSttModelUnload = '$superbeeBaseUrl/stt/models/unload/';
  static const String superbeeSttTranscribe = '$superbeeBaseUrl/stt/transcribe/';

  static const String superbeeTalkHealth = '$superbeeBaseUrl/talk/health/';
  static const String superbeeTalkSpeech = '$superbeeBaseUrl/talk/speech/';
  static const String superbeeTalkStream = '$superbeeBaseUrl/talk/stream/';



  static String appendBaseUrl(String url) => '$baseUrl$url';

  static String emmaWebSocketChat(String sessionId, String token) {
    return '$wsOrWss://$host/ws/emma/$sessionId/?token=$token';
  }

  // --- REST endpoints ---
  static final emmaChatSession = appendBaseUrl('chat/sessions/');
  static final emmaToolManifest = appendBaseUrl('tools/manifest/');
  static final emmaToolExecuteOnly = appendBaseUrl('tools/execute-only/');
  static final emmaLocalResoult = appendBaseUrl('chat/local-result/');


  static String emmaChatSessionId(String sessionId) => appendBaseUrl('chat/sessions/$sessionId/');

  static String emmaMessagesId(String sessionId) => appendBaseUrl('chat/messages/?session=$sessionId');

  static String emmaMessages(String sessionId) => appendBaseUrl('chat/messages/?session=$sessionId');

  static String emmaMentionsSearch(String q, String types) => appendBaseUrl('mentions/?q=$q&types=$types');

  static final emmaChatSync = appendBaseUrl('chat/sync/');

  // --- Proactive Emma endpoints ---
  static final emmaProactiveAccept = appendBaseUrl('proactive/accept/');
  static final emmaProactiveDismiss = appendBaseUrl('proactive/dismiss/');
  static final emmaProactiveInbox = appendBaseUrl('proactive/inbox/');
  static final emmaProactivePending = appendBaseUrl('proactive/pending/');
  static String emmaProactiveEmail(int emailId) =>
      appendBaseUrl('proactive/email/$emailId/');
  static final emmaListingInquiry     = appendBaseUrl('proactive/listing-inquiry/');
  static final emmaEmailAnalyze       = appendBaseUrl('proactive/email-analyze/');
  static String emmaEmailSuggestions(int emailId) =>
      appendBaseUrl('proactive/email-suggestions/?email_id=$emailId');
  static final emmaTravelTime           = appendBaseUrl('travel-time/');
  static String emmaCalendarTravelTimes(String date) =>
      appendBaseUrl('calendar-travel-times/?date=$date');
  static final emmaConfirmRedaction     = appendBaseUrl('proactive/confirm-redaction/');

  /// NEW: mark seen (REST fallback)
  /// Backend suggested shape:
  /// POST /emma/chat/messages/seen/
  /// { "session": 123, "last_seen_id": 456 }
  static final emmaMessagesSeen = appendBaseUrl('chat/messages/seen/');

  // --- Emma × Automation endpoints ---
  // POST  { description, scope_type?, context? } → { workflow, questions? }
  static final emmaAutomationCreate =
      appendBaseUrl('automation/create-workflow/');

  // POST  { workflow_id, answers } → { workflow }  (refinement after wizard)
  static String emmaAutomationRefine(String workflowId) =>
      appendBaseUrl('automation/workflows/$workflowId/refine/');

  // POST  { workflow_id } → { dry_run }
  static String emmaAutomationDryRun(String workflowId) =>
      appendBaseUrl('automation/workflows/$workflowId/dry-run/');

  // POST  { workflow_id } → { workflow }
  static String emmaAutomationActivate(String workflowId) =>
      appendBaseUrl('automation/workflows/$workflowId/activate/');

  // POST  { workflow_id } → { workflow }
  static String emmaAutomationDeactivate(String workflowId) =>
      appendBaseUrl('automation/workflows/$workflowId/deactivate/');

  // GET   → { workflow }
  static String emmaAutomationGet(String workflowId) =>
      appendBaseUrl('automation/workflows/$workflowId/');

  // GET   → { workflows: [...] }
  static final emmaAutomationList = appendBaseUrl('automation/workflows/');

  // POST  { workflow_id } → { explanation: "..." }
  static String emmaAutomationExplain(String workflowId) =>
      appendBaseUrl('automation/workflows/$workflowId/explain/');

  // POST  { name, base_url, auth_type, credentials? } → { connector }
  static final emmaAutomationConnectorCreate =
      appendBaseUrl('automation/connectors/');

  // POST  { connector_id } → { ok, latency_ms, sample_response }
  static String emmaAutomationConnectorTest(String connectorId) =>
      appendBaseUrl('automation/connectors/$connectorId/test/');
}
