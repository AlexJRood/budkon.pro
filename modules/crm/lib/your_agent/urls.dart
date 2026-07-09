class URLsAgentClientPortal {
  static const String yourAgentBase = 'https://www.superbee.cloud/your-agent';

  static String managePortal(String transactionId) =>
      '$yourAgentBase/agent/transactions/$transactionId/portal/';

  static String previewPortal(String transactionId) =>
      '$yourAgentBase/agent/transactions/$transactionId/portal/preview/';

  static String resendInvite(String transactionId) =>
      '$yourAgentBase/agent/transactions/$transactionId/portal/resend-invite/';

  static String suggestions(String transactionId) =>
      '$yourAgentBase/agent/transactions/$transactionId/portal/suggestions/';

  static String reviewSuggestion(String transactionId, String suggestionId) =>
      '$yourAgentBase/agent/transactions/$transactionId/portal/suggestions/$suggestionId/review/';

      
  static String statusPortal(String transactionId) =>
      '$yourAgentBase/agent/transactions/$transactionId/portal/status/';
}

class URLsClientPortal {
  static const String yourAgentBase = 'https://www.superbee.cloud/your-agent';

  static String clientPortalCases = '$yourAgentBase/cases/';

  static String clientPortalCaseDetail(String portalId) =>
      '$yourAgentBase/cases/$portalId/';

  static String clientPortalSuggestions(String portalId) =>
      '$yourAgentBase/cases/$portalId/suggest-listing/';

  static String clientPortalTransactionPresentations(String txId) =>
      '$yourAgentBase/transactions/$txId/presentations/';

  static String inviteStatus(String token) =>
      '$yourAgentBase/invite/$token/';

  static String inviteBind(String token) =>
      '$yourAgentBase/invite/$token/bind/';
      
  static String clientPortalTrackEvent(String portalId) =>
      '$yourAgentBase/cases/$portalId/track-event/';
}
