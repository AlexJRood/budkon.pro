// notification/notif_type.dart

class NotifType {
  const NotifType();

  static const chat = 62;
  static const email = 267;
  static const associationNotification = 414;
  static const wallPost = 120;
  static const wallComment = 122;
  static const agentSuggestion = 114;
  static const scheduledEmailSent = 268;
  static const savedSearchNewAd = 50;
  static const cloudNotification = 303;
  static const tmsNewTask = 77;
}

class BNotifType {
  const BNotifType();

  static const chat = 'open_chat';
  static const email = 'open_email';

  // Email notifications
  static const scheduledEmailSent = 'open_scheduled_email';

  // Saved search / network monitoring
  static const savedSearch = 'open_saved_search';
  static const savedSearchAd = 'open_saved_search_ad';

  // Wall notifications
  static const wallPost = 'open_wall_post';
  static const wall = 'open_wall';

  // Ad notifications
  static const ad = 'open_ad';

  // TMS notifications
  static const tmsBoard = 'open_tms_board';
  static const tmsTask = 'open_tms_task';

  // Calendar notifications
  static const calendar = 'open_calendar';
  static const calendarEvent = 'open_calendar_event';

  // Report notifications
  static const report = 'open_report';

  // Client/Transaction notifications
  static const clientPanel = 'open_client_panel';
  static const transaction = 'open_transaction';

  // Invoice notifications
  static const invoice = 'open_invoice';

  // Emma/AI Assistant notifications
  static const emma = 'open_emma';
  static const openEmmaSession = 'open_emma_session';
  static const openEventInvite = 'open_event_invite';
  static const askEmmaAboutEmail = 'ask_emma_about_email';

  // Cloud storage notifications
  static const cloudStorage = 'open_cloud_storage';
  static const cloudFile = 'open_cloud_file';
  static const cloudFolder = 'open_cloud_folder';
}

/// Stable notification categories sent by the backend as the `type`
/// (FCM data) / `notification_type` (list API) field. Unlike [NotifType]
/// (which are DB-specific ContentType PKs) these strings are stable across
/// environments, so they are the safest signal for routing a push tap.
///
/// Keep in sync with `Notification.NotificationType` on the backend.
class NotifCategory {
  const NotifCategory();

  static const email = 'email';
  static const message = 'message';
  static const savedSearch = 'saved_search';
  static const system = 'system';
  static const finance = 'finance';
  static const emma = 'emma';
  static const payments = 'payments';
  static const tms = 'tms';
  static const calendar = 'calendar';
  static const community = 'community';
  static const association = 'association';
  static const cloudStorage = 'cloud_storage';
  static const crm = 'crm';
  static const others = 'others';
}