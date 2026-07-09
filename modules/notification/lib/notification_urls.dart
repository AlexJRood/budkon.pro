import 'package:core/platform/url.dart';

/// notification feature API endpoints, decentralized out of core's URLs God-package.
class NotificationUrls {
  const NotificationUrls._();

static final availableNotificationCategories =
    URLs.appendBaseUrl('/api/notifications/available-categories/');
static final bulkDeleteNotifications =
    URLs.appendBaseUrl('/api/notifications/bulk-delete/');
static final bulkSeenNotifications =
    URLs.appendBaseUrl('/api/notifications/bulk-seen/');
static String deleteNotification(String id) =>
    URLs.appendBaseUrl('/api/notifications/$id/');
static final makeAllNotificationsSeen =
    URLs.appendBaseUrl('/api/notifications/make-all-seen/');
static final notificationUnreadCount =
    URLs.appendBaseUrl('/api/notifications/unread-count/');
static String notificationsSeen(String id) =>
    URLs.appendBaseUrl('/api/notifications/$id/make-notification-seen/');
static final userNotifications = URLs.appendBaseUrl('/api/notifications/');
}
