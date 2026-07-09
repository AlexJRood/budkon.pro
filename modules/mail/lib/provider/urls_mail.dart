class EmailsURLs {
  static const baseUrl = 'https://www.superbee.cloud/mail/';

  static String appendBaseUrl(String url) => '$baseUrl$url';

  static final emails = appendBaseUrl('emails/');
  static final emailSearch = appendBaseUrl('emails/');
  static final emailAccount = appendBaseUrl('email-accounts/');

  static final cacheSync = appendBaseUrl('emails/cache-sync/');
  static final loadOlder = appendBaseUrl('emails/load-older/');

  static final emailTags = appendBaseUrl('email-tags/');
  static final emailTabs = appendBaseUrl('email-tabs/');
  static final emailTabRules = appendBaseUrl('email-tab-rules/');

  static String emailDetail(int emailId) => appendBaseUrl('emails/$emailId/');
  static String markRead(int emailId) => appendBaseUrl('emails/$emailId/mark-read/');
  static String markUnread(int emailId) => appendBaseUrl('emails/$emailId/mark-unread/');
  static String touchEmmaSeen(int emailId) => appendBaseUrl('emails/$emailId/touch-emma-seen/');
  static String touchEmmaUsed(int emailId) => appendBaseUrl('emails/$emailId/touch-emma-used/');
  static String markSpam(int emailId) => appendBaseUrl('emails/$emailId/mark-spam/');
  static String markNotSpam(int emailId) => appendBaseUrl('emails/$emailId/mark-not-spam/');
  static String moveToTab(int emailId) => appendBaseUrl('emails/$emailId/move-to-tab/');
  static String bulkMoveToTab() => appendBaseUrl('emails/bulk-move-to-tab/');
  static String setTags(int emailId) => appendBaseUrl('emails/$emailId/set-tags/');
  static String unsubscribe(int emailId) => appendBaseUrl('emails/$emailId/unsubscribe/');

  static String tagDetail(int tagId) => appendBaseUrl('email-tags/$tagId/');
  static String tabDetail(int tabId) => appendBaseUrl('email-tabs/$tabId/');
  static String tabsBulkOrder() => appendBaseUrl('email-tabs/bulk-order/');

  static String thread(int emailId) => appendBaseUrl('emails/$emailId/thread/');
  static String forward(int emailId) => appendBaseUrl('emails/$emailId/forward/');
}