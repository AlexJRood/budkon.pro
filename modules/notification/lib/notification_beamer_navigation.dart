// notification/notification_beamer_navigation.dart

import 'dart:async';

import 'package:association/screens/notifications.dart';
import 'package:beamer/beamer.dart';
import 'package:emma/provider/emma_notifier.dart';
import 'package:emma/provider/emma_provider.dart';
import 'package:emma/provider/urls.dart';
import 'package:emma/runner.dart';
import 'package:chat/models/chat_room_model.dart';
import 'package:chat/new_chat/provider/chat_message_provider.dart';
import 'package:chat/new_chat/provider/chat_room_provider.dart';
import 'package:chat/new_chat/provider/web_socket_provider.dart';
import 'package:chat/pages/chat_page.dart';
import 'package:cloud/cloud.dart';
import 'package:crm_agent/screens/agent_clients.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mail/mail.dart';
import 'package:mail/utils/api_services.dart';
import 'package:mail/utils/mail_filters.dart';
import 'package:notification/model/notification_model.dart';
import 'package:notification/notif_type.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/platform/url.dart';
import 'package:tms_app/todo/todo_page.dart';
import 'package:wall/wall_screen/wall_screen.dart';

final selectedEmailFromNotificationProvider = StateProvider<int?>(
  (ref) => null,
);

int? _notifAsInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}

int? _firstInt(List<dynamic> values) {
  for (final value in values) {
    final parsed = _notifAsInt(value);
    if (parsed != null) return parsed;
  }
  return null;
}

class SavedSearchNotificationTarget {
  final int? savedSearchId;
  final int? adId;

  const SavedSearchNotificationTarget({
    this.savedSearchId,
    this.adId,
  });

  bool get canOpen => savedSearchId != null || adId != null;

  Map<String, String> get queryParameters => {
        if (savedSearchId != null) 'saved_search_id': '$savedSearchId',
        if (adId != null) 'ad_id': '$adId',
        'from_notification': '1',
      };
}

class NotificationBeamerNavigation {
  static SavedSearchNotificationTarget extractSavedSearchTarget(
    NotificationModel notif,
  ) {
    final NotificationAction? firstAction =
        notif.actions.isNotEmpty ? notif.actions.first : null;

    final actionType = firstAction?.type ?? '';
    final actionRaw = firstAction?.raw ?? const <String, dynamic>{};
    final rootRaw = notif.raw;

    final savedSearchId = _firstInt([
      actionRaw['saved_search_id'],
      actionRaw['savedSearchId'],
      actionRaw['saved_search'],
      rootRaw['saved_search_id'],
      rootRaw['savedSearchId'],
      rootRaw['saved_search'],
      actionType == BNotifType.savedSearch ? notif.objectId : null,
    ]);

    final adId = _firstInt([
      actionRaw['ad_id'],
      actionRaw['adId'],
      actionRaw['advertisement_id'],
      actionRaw['listing_id'],
      rootRaw['ad_id'],
      rootRaw['adId'],
      rootRaw['advertisement_id'],
      rootRaw['listing_id'],
      actionType == BNotifType.savedSearchAd ? notif.objectId : null,
      actionType == BNotifType.ad ? notif.objectId : null,
      notif.contentType == NotifType.savedSearchNewAd ? notif.objectId : null,
    ]);

    return SavedSearchNotificationTarget(
      savedSearchId: savedSearchId,
      adId: adId,
    );
  }

  static void openSavedSearchRoute(
    BuildContext context,
    NotificationModel notif,
  ) {
    final target = extractSavedSearchTarget(notif);

    if (!target.canOpen) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Missing saved search notification data'),
        ),
      );
      return;
    }

    final uri = Uri(
      path: Routes.saveNetworkMonitoring,
      queryParameters: target.queryParameters,
    );

    Beamer.of(context).beamToNamed(uri.toString());
  }

  static Future<void> _openEmmaSession(
    BuildContext context,
    WidgetRef ref,
    NotificationModel notif,
  ) async {
    final action = notif.actions.firstWhere(
      (a) =>
          a.type == BNotifType.openEmmaSession ||
          a.type == BNotifType.askEmmaAboutEmail,
      orElse: () => NotificationAction(text: '', type: ''),
    );

    int? sessionId = int.tryParse(
      (action.raw['session_id'] ?? '').toString(),
    );

    // For ask_emma_about_email: trigger analysis if we only have email_id.
    if (action.type == BNotifType.askEmmaAboutEmail && sessionId == null) {
      final emailId = int.tryParse(
        (action.raw['email_id'] ?? '').toString(),
      );
      if (emailId != null) {
        try {
          final res = await ApiServices.post(
            URLsEmma.emmaProactiveEmail(emailId),
            data: <String, dynamic>{},
            hasToken: true,
            ref: ref,
          );
          final data = res?.data;
          if (data is Map) {
            sessionId = int.tryParse(
              (data['session_id'] ?? '').toString(),
            );
          }
        } catch (e) {
          debugPrint('[NOTIF] askEmmaAboutEmail trigger error: $e');
        }
      }
    }

    try {
      if (sessionId != null) {
        ref.read(selectedAiRoomProvider.notifier).state = sessionId.toString();
        await ref
            .read(chatAiMessageProvider.notifier)
            .connectToSession(sessionId);
      }
    } catch (e) {
      debugPrint('[NOTIF] Error connecting to Emma session: $e');
    }

    if (!context.mounted) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => const ChatAiPage(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  static void navigate(
    BuildContext context,
    WidgetRef ref,
    NotificationModel notif,
  ) {
    // Action-type routing takes priority over content-type routing.
    final firstActionType =
        notif.actions.isNotEmpty ? notif.actions.first.type : '';
    if (firstActionType == BNotifType.openEmmaSession ||
        firstActionType == BNotifType.askEmmaAboutEmail) {
      unawaited(_openEmmaSession(context, ref, notif));
      return;
    }

    final type = notif.contentType;

    switch (type) {
      case NotifType.chat:
        _openChat(context, ref, notif);
        break;

      case NotifType.email:
        final id = int.tryParse(notif.objectId);
        if (id != null) {
          _openEmail(context, ref, id);
        }
        break;

      case NotifType.associationNotification:
        _openAssociationNotification(context, ref, notif);
        break;

      case NotifType.wallPost:
        _openWallPost(context, ref, notif);
        break;

      case NotifType.wallComment:
        _openWallComment(context, ref, notif);
        break;

      case NotifType.agentSuggestion:
        _openAgentSuggestion(context, ref, notif);
        break;

      case NotifType.scheduledEmailSent:
        _openScheduledEmailSent(context, ref, notif);
        break;

      case NotifType.savedSearchNewAd:
        _openSavedSearchNewAd(context, ref, notif);
        break;

      case NotifType.cloudNotification:
        _openCloudNotification(context, ref, notif);
        break;

      case NotifType.tmsNewTask:
        _openTmsNewTask(context, ref, notif);
        break;

      default:
        if (!_routeByCategory(context, ref, notif)) {
          // No dedicated destination (e.g. system / finance / payments /
          // others). The item is already visible in the list – stay put
          // instead of showing an error snackbar.
          debugPrint(
            '[NOTIF] No destination for notification type '
            '"${notif.notificationType}" (contentType=$type) – ignoring tap',
          );
        }
    }
  }

  /// Routes by the stable [NotificationModel.notificationType] category string
  /// when neither the action type nor the numeric content type resolved to a
  /// destination. Returns `true` if it navigated.
  static bool _routeByCategory(
    BuildContext context,
    WidgetRef ref,
    NotificationModel notif,
  ) {
    debugPrint(
      '[NOTIF] Falling back to category routing: "${notif.notificationType}"',
    );

    switch (notif.notificationType) {
      case NotifCategory.message:
        unawaited(_openChat(context, ref, notif));
        return true;

      case NotifCategory.email:
        final id = int.tryParse(notif.objectId);
        if (id != null) {
          unawaited(_openEmail(context, ref, id));
          return true;
        }
        return false;

      case NotifCategory.savedSearch:
        _openSavedSearchNewAd(context, ref, notif);
        return true;

      case NotifCategory.tms:
        _openTmsNewTask(context, ref, notif);
        return true;

      case NotifCategory.cloudStorage:
        _openCloudNotification(context, ref, notif);
        return true;

      case NotifCategory.association:
        _openAssociationNotification(context, ref, notif);
        return true;

      case NotifCategory.community:
        _openWallPost(context, ref, notif);
        return true;

      case NotifCategory.emma:
        unawaited(_openEmmaSession(context, ref, notif));
        return true;

      case NotifCategory.crm:
        _openAgentSuggestion(context, ref, notif);
        return true;

      default:
        return false;
    }
  }

  static void _openSavedSearchNewAd(
    BuildContext context,
    WidgetRef ref,
    NotificationModel notif,
  ) {
    debugPrint('[NOTIF] Opening saved search / NM notification');
    openSavedSearchRoute(context, notif);
  }

  static void _openAssociationNotification(
    BuildContext context,
    WidgetRef ref,
    NotificationModel notif,
  ) {
    debugPrint('[NOTIF] Opening association campaign');
    final campaignId = notif.objectId;

    if (campaignId.isEmpty) {
      debugPrint('[NOTIF] No campaign ID found');
      return;
    }

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => AssociationNotificationsScreen(
          baseUrl: URLs.baseUrl,
          associationId: 1,
          notificationId: campaignId,
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  static Future<void> _openChat(
    BuildContext context,
    WidgetRef ref,
    NotificationModel notif,
  ) async {
    debugPrint('[NOTIF] Opening chat');

    final action = notif.actions.firstWhere(
      (a) => a.type == BNotifType.chat,
      orElse: () => NotificationAction(text: '', type: '', chatRoomId: null),
    );

    final roomId = action.chatRoomUuid;
    if (roomId == null) {
      debugPrint('[NOTIF] No chat_room_id found in actions');
      return;
    }

    await ref.read(fetchRoomsProvider.notifier).fetchRooms();
    ref.read(selectedChatId.notifier).state = roomId;
    ref.read(isChatSelected.notifier).state = true;

    final rooms = ref.read(fetchRoomsProvider);
    final room = rooms.cast<Room?>().firstWhere(
          (r) => r?.id == roomId,
          orElse: () => null,
        );

    if (room != null && room.otherUser != null) {
      ref.read(otherUserData.notifier).state = room.otherUser!;
    } else {
      debugPrint(
        '[NOTIF] Room not found or otherUser is null for roomId=$roomId',
      );
    }

    final token = ApiServices.token;
    if (token != null) {
      final wsUrl = URLs.webSocketChat(roomId, token);
      ref.read(webSocketProvider.notifier).connect(wsUrl);
    }

    await ref
        .read(chatMessageRoomProvider.notifier)
        .fetchRoomMessages(roomId, ref);

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => const ChatPage(),
        transitionsBuilder:
            (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  static Future<void> _openEmail(
    BuildContext context,
    WidgetRef ref,
    int emailUUID,
  ) async {
    debugPrint('[NOTIF] Opening email');

    ref.read(selectedEmailFromNotificationProvider.notifier).state = emailUUID;
    await ref.read(emailDetailsProvider(emailUUID).future);

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black54,
        pageBuilder: (_, __, ___) => EmailView(),
        transitionsBuilder:
            (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  static void _openWallPost(
    BuildContext context,
    WidgetRef ref,
    NotificationModel notif,
  ) {
    debugPrint('[NOTIF] Opening wall post');

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => const WallScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  static void _openWallComment(
    BuildContext context,
    WidgetRef ref,
    NotificationModel notif,
  ) {
    debugPrint('[NOTIF] Opening wall comment');

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => const WallScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  static void _openAgentSuggestion(
    BuildContext context,
    WidgetRef ref,
    NotificationModel notif,
  ) {
    debugPrint('[NOTIF] Opening agent suggestion');

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => const ClientsPage(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  static void _openScheduledEmailSent(
    BuildContext context,
    WidgetRef ref,
    NotificationModel notif,
  ) {
    debugPrint('[NOTIF] Opening scheduled email sent');

    final scheduledEmailId = int.tryParse(notif.objectId) ?? 0;
    if (scheduledEmailId == 0) {
      debugPrint('[NOTIF] Invalid scheduled email ID');
      return;
    }

    ref.read(mailTypeProvider.notifier).state = 'scheduled';

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black54,
        pageBuilder: (_, __, ___) => EmailView(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  static void _openCloudNotification(
    BuildContext context,
    WidgetRef ref,
    NotificationModel notif,
  ) {
    debugPrint('[NOTIF] Opening cloud notification');

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => const CloudStoragePage(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  static void _openTmsNewTask(
    BuildContext context,
    WidgetRef ref,
    NotificationModel notif,
  ) {
    debugPrint('[NOTIF] Opening TMS new task');

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => const ToDoPage(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }
}