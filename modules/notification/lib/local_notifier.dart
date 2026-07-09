import 'dart:async';
import 'dart:convert';

import 'package:association/screens/notifications.dart';
import 'package:chat/models/chat_room_model.dart';
import 'package:emma/provider/emma_notifier.dart';
import 'package:emma/provider/emma_provider.dart';
import 'package:emma/provider/urls.dart';
import 'package:emma/runner.dart';
import 'package:chat/new_chat/provider/chat_message_provider.dart';
import 'package:chat/new_chat/provider/chat_room_provider.dart';
import 'package:chat/new_chat/provider/web_socket_provider.dart';
import 'package:chat/pages/chat_page.dart';
import 'package:cloud/cloud.dart';
import 'package:crm_agent/screens/agent_clients.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mail/mail.dart';
import 'package:mail/utils/api_services.dart';
import 'package:mail/utils/mail_filters.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/platform/url.dart';
import 'package:tms_app/todo/todo_page.dart';
import 'package:wall/wall_screen/wall_screen.dart';

import 'model/notification_model.dart';
import 'notif_type.dart';
import 'notification_beamer_navigation.dart';
import 'notification_mobile_screen.dart';

class LocalNotifier {
  LocalNotifier._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static GlobalKey<NavigatorState>? navigatorKey;

  static bool _initialized = false;
  static Future<void>? _initFuture;

  static void attachNavigatorKey(GlobalKey<NavigatorState> key) {
    navigatorKey = key;
  }

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'hously_high',
    'Hously High',
    description: 'High priority notifications',
    importance: Importance.high,
    playSound: true,
  );

  static const WindowsInitializationSettings _windowsInit =
      WindowsInitializationSettings(
        appName: 'Hously',
        appUserModelId: 'Hously.Hously.Desktop.1',
        guid: '8d8f6a58-80e2-4d31-9f62-5f4fc705f181',
      );

  static Future<void> init() async {
    if (_initialized) return;
    if (_initFuture != null) return _initFuture!;

    _initFuture = _doInit();
    return _initFuture!;
  }

  static Future<void> _doInit() async {
    try {
      const android = AndroidInitializationSettings('@drawable/ic_stat_notif');

      const darwin = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        defaultPresentAlert: true,
        defaultPresentBadge: true,
        defaultPresentSound: true,
        defaultPresentBanner: true,
        defaultPresentList: true,
        notificationCategories: <DarwinNotificationCategory>[
          DarwinNotificationCategory('MESSAGE'),
        ],
      );

      await _plugin.initialize(
        const InitializationSettings(
          android: android,
          iOS: darwin,
          macOS: darwin,
          windows: _windowsInit,
        ),
        onDidReceiveNotificationResponse: (resp) async {
          if (kDebugMode) {
            debugPrint(
              '[LOCAL] tap/action id=${resp.actionId} payload=${resp.payload}',
            );
          }

          if (resp.payload?.isNotEmpty == true) {
            await openFromPayload(resp.payload!);
          }
        },
      );

      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);

      await _requestDarwinPermissions();

      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.iOS ||
              defaultTargetPlatform == TargetPlatform.macOS)) {
        try {
          await FirebaseMessaging.instance
              .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );
        } catch (e, stack) {
          debugPrint(
            '[LOCAL] setForegroundNotificationPresentationOptions error: $e\n$stack',
          );
        }
      }

      _initialized = true;
      debugPrint('[LOCAL] LocalNotifier initialized');
    } catch (e, stack) {
      debugPrint('[LOCAL] init error: $e\n$stack');
      rethrow;
    } finally {
      _initFuture = null;
    }
  }

  static Future<void> _requestDarwinPermissions() async {
    try {
      final darwinPlugin = _plugin.resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin>();

      final granted = await darwinPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );

      debugPrint('[LOCAL] Darwin notification permission granted=$granted');
    } catch (e, stack) {
      debugPrint('[LOCAL] Darwin permission error: $e\n$stack');
    }
  }

  static Future<String?> getLaunchPayloadIfAny() async {
    try {
      final details = await _plugin.getNotificationAppLaunchDetails();
      final didLaunch = details?.didNotificationLaunchApp ?? false;

      if (!didLaunch) return null;

      final payload = details?.notificationResponse?.payload;
      if (payload == null || payload.isEmpty) return null;

      debugPrint('[LOCAL] launch payload from app start: $payload');
      return payload;
    } catch (e, stack) {
      debugPrint('[LOCAL] getLaunchPayloadIfAny error: $e\n$stack');
      return null;
    }
  }

  static Future<void> show({
    required String title,
    required String body,
    Map<String, dynamic>? data,
    int? id,
  }) async {
    await init();

    final payload = jsonEncode(data ?? const <String, dynamic>{});

    final android = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/ic_stat_notif',
      category: AndroidNotificationCategory.message,
    );

    const darwin = DarwinNotificationDetails(
      categoryIdentifier: 'MESSAGE',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final windows = WindowsNotificationDetails(
      subtitle: null,
      timestamp: DateTime.now(),
    );

    await _plugin.show(
      id ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
        android: android,
        iOS: darwin,
        macOS: darwin,
        windows: windows,
      ),
      payload: payload,
    );
  }

  static Future<void> openFromPayload(String payload) async {
    await _handleNotificationPayload(payload);
  }

  static Future<BuildContext?> _waitForNavigationContext({
    Duration timeout = const Duration(seconds: 2),
  }) async {
    final deadline = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(deadline)) {
      final nav = navigatorKey?.currentState;
      final context = navigatorKey?.currentContext;

      if (nav != null && nav.mounted && context != null && context.mounted) {
        return context;
      }

      await Future.delayed(const Duration(milliseconds: 30));
    }

    return null;
  }

  static Future<void> _handleNotificationPayload(String payload) async {
    if (kDebugMode) {
      debugPrint('[LOCAL] Handling notification payload: $payload');
    }

    try {
      Map<String, dynamic> data = {};

      try {
        if (payload.isNotEmpty) {
          data = Map<String, dynamic>.from(jsonDecode(payload));
        }
      } catch (e) {
        debugPrint('[LOCAL] Error decoding payload: $e');
        return;
      }

      final notification = _createNotificationModelFromData(data);

      if (notification == null) {
        debugPrint('[LOCAL] Failed to create NotificationModel from data');
        return;
      }

      final context = await _waitForNavigationContext();
      if (context == null) {
        debugPrint('[LOCAL] navigatorKey/context not ready – cannot navigate');
        return;
      }

      try {
        final container = ProviderScope.containerOf(context, listen: false);

        _navigateWithContainer(context, container, notification);
      } catch (e) {
        debugPrint('[LOCAL] Error getting container: $e');
        _navigateWithBeamerOnly(context, notification);
      }
    } catch (e) {
      debugPrint('[LOCAL] Error in handleNotificationPayload: $e');
    }
  }

  static void _navigateWithContainer(
    BuildContext context,
    ProviderContainer container,
    NotificationModel notification,
  ) {
    if (notification.contentType == NotifType.savedSearchNewAd) {
      NotificationBeamerNavigation.openSavedSearchRoute(
        context,
        notification,
      );
      return;
    }

    final NotificationAction? firstAction =
        notification.actions.isNotEmpty ? notification.actions.first : null;
    final actionType = firstAction?.type ?? '';

    switch (actionType) {
      case BNotifType.chat:
        unawaited(_openChatWithContainer(context, container, notification));
        break;

      case BNotifType.email:
        final id = int.tryParse(notification.objectId);
        if (id != null) {
          unawaited(_openEmailWithContainer(context, container, id));
        }
        break;

      case BNotifType.savedSearch:
      case BNotifType.savedSearchAd:
      case BNotifType.ad:
        NotificationBeamerNavigation.openSavedSearchRoute(
          context,
          notification,
        );
        break;

      case BNotifType.wallPost:
      case BNotifType.wall:
        _openWallPostWithContainer(context, container, notification);
        break;

      case BNotifType.cloudStorage:
        _openCloudNotificationWithContainer(context, container, notification);
        break;

      case BNotifType.tmsTask:
        _openTmsNewTaskWithContainer(context, container, notification);
        break;

      case BNotifType.scheduledEmailSent:
        _openScheduledEmailSentWithContainer(context, container, notification);
        break;

      case BNotifType.openEmmaSession:
      case BNotifType.askEmmaAboutEmail:
        unawaited(
            _openEmmaSessionWithContainer(context, container, notification));
        break;

      default:
        switch (notification.contentType) {
          case NotifType.chat:
            unawaited(_openChatWithContainer(context, container, notification));
            break;

          case NotifType.email:
            final id = int.tryParse(notification.objectId);
            if (id != null) {
              unawaited(_openEmailWithContainer(context, container, id));
            }
            break;

          case NotifType.associationNotification:
            _openAssociationNotificationWithContainer(
              context,
              container,
              notification,
            );
            break;

          case NotifType.wallPost:
          case NotifType.wallComment:
            _openWallPostWithContainer(context, container, notification);
            break;

          case NotifType.agentSuggestion:
            _openAgentSuggestionWithContainer(context, container, notification);
            break;

          case NotifType.scheduledEmailSent:
            _openScheduledEmailSentWithContainer(
              context,
              container,
              notification,
            );
            break;

          case NotifType.cloudNotification:
            _openCloudNotificationWithContainer(
              context,
              container,
              notification,
            );
            break;

          case NotifType.tmsNewTask:
            _openTmsNewTaskWithContainer(context, container, notification);
            break;

          default:
            if (!_routeByCategoryWithContainer(
              context,
              container,
              notification,
            )) {
              _openNotificationsScreen(context);
            }
        }
    }
  }

  /// Last-resort routing based on the stable [NotificationModel.notificationType]
  /// string. Used when neither the action type nor the numeric content type
  /// resolved to a destination (e.g. a push sent without explicit actions and
  /// with a content type the client does not map). Returns `true` if it
  /// navigated somewhere, `false` if the category has no dedicated screen and
  /// the caller should fall back to the notifications list.
  static bool _routeByCategoryWithContainer(
    BuildContext context,
    ProviderContainer container,
    NotificationModel notif,
  ) {
    debugPrint(
      '[NOTIF] Falling back to category routing: "${notif.notificationType}"',
    );

    switch (notif.notificationType) {
      case NotifCategory.message:
        unawaited(_openChatWithContainer(context, container, notif));
        return true;

      case NotifCategory.email:
        final id = int.tryParse(notif.objectId);
        if (id != null) {
          unawaited(_openEmailWithContainer(context, container, id));
          return true;
        }
        return false;

      case NotifCategory.savedSearch:
        NotificationBeamerNavigation.openSavedSearchRoute(context, notif);
        return true;

      case NotifCategory.tms:
        _openTmsNewTaskWithContainer(context, container, notif);
        return true;

      case NotifCategory.cloudStorage:
        _openCloudNotificationWithContainer(context, container, notif);
        return true;

      case NotifCategory.association:
      case NotifCategory.community:
        _openWallPostWithContainer(context, container, notif);
        return true;

      case NotifCategory.emma:
        unawaited(_openEmmaSessionWithContainer(context, container, notif));
        return true;

      case NotifCategory.crm:
        _openAgentSuggestionWithContainer(context, container, notif);
        return true;

      default:
        return false;
    }
  }

  /// Opens the in-app notifications list as a graceful fallback so a tap always
  /// lands somewhere useful instead of showing an error snackbar.
  static void _openNotificationsScreen(BuildContext context) {
    debugPrint('[NOTIF] No dedicated destination – opening notifications list');
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => const NotificationMobileScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  static void _navigateWithBeamerOnly(
    BuildContext context,
    NotificationModel notification,
  ) {
    if (notification.contentType == NotifType.savedSearchNewAd) {
      NotificationBeamerNavigation.openSavedSearchRoute(
        context,
        notification,
      );
      return;
    }

    final NotificationAction? firstAction =
        notification.actions.isNotEmpty ? notification.actions.first : null;
    final actionType = firstAction?.type ?? '';

    switch (actionType) {
      case BNotifType.chat:
        Navigator.of(context).push(
          PageRouteBuilder(
            opaque: false,
            pageBuilder: (_, __, ___) => const ChatPage(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
          ),
        );
        break;

      case BNotifType.email:
        Navigator.of(context).push(
          PageRouteBuilder(
            opaque: false,
            barrierColor: Colors.black54,
            pageBuilder: (_, __, ___) => EmailView(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
          ),
        );
        break;

      case BNotifType.savedSearch:
      case BNotifType.savedSearchAd:
      case BNotifType.ad:
        NotificationBeamerNavigation.openSavedSearchRoute(
          context,
          notification,
        );
        break;

      case BNotifType.wallPost:
      case BNotifType.wall:
        Navigator.of(context).push(
          PageRouteBuilder(
            opaque: false,
            pageBuilder: (_, __, ___) => const WallScreen(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
          ),
        );
        break;

      case BNotifType.cloudStorage:
        Navigator.of(context).push(
          PageRouteBuilder(
            opaque: false,
            pageBuilder: (_, __, ___) => const CloudStoragePage(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
          ),
        );
        break;

      case BNotifType.tmsTask:
        Navigator.of(context).push(
          PageRouteBuilder(
            opaque: false,
            pageBuilder: (_, __, ___) => const ToDoPage(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
          ),
        );
        break;

      case BNotifType.openEmmaSession:
      case BNotifType.askEmmaAboutEmail:
        Navigator.of(context).push(
          PageRouteBuilder(
            opaque: false,
            pageBuilder: (_, __, ___) => const ChatAiPage(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
          ),
        );
        break;

      default:
        switch (notification.contentType) {
          case NotifType.chat:
            Navigator.of(context).push(
              PageRouteBuilder(
                opaque: false,
                pageBuilder: (_, __, ___) => const ChatPage(),
                transitionsBuilder: (_, anim, __, child) =>
                    FadeTransition(opacity: anim, child: child),
              ),
            );
            break;

          case NotifType.email:
            Navigator.of(context).push(
              PageRouteBuilder(
                opaque: false,
                barrierColor: Colors.black54,
                pageBuilder: (_, __, ___) => EmailView(),
                transitionsBuilder: (_, anim, __, child) =>
                    FadeTransition(opacity: anim, child: child),
              ),
            );
            break;

          case NotifType.savedSearchNewAd:
            NotificationBeamerNavigation.openSavedSearchRoute(
              context,
              notification,
            );
            break;

          case NotifType.wallPost:
          case NotifType.wallComment:
            Navigator.of(context).push(
              PageRouteBuilder(
                opaque: false,
                pageBuilder: (_, __, ___) => const WallScreen(),
                transitionsBuilder: (_, anim, __, child) =>
                    FadeTransition(opacity: anim, child: child),
              ),
            );
            break;

          case NotifType.cloudNotification:
            Navigator.of(context).push(
              PageRouteBuilder(
                opaque: false,
                pageBuilder: (_, __, ___) => const CloudStoragePage(),
                transitionsBuilder: (_, anim, __, child) =>
                    FadeTransition(opacity: anim, child: child),
              ),
            );
            break;

          case NotifType.tmsNewTask:
            Navigator.of(context).push(
              PageRouteBuilder(
                opaque: false,
                pageBuilder: (_, __, ___) => const ToDoPage(),
                transitionsBuilder: (_, anim, __, child) =>
                    FadeTransition(opacity: anim, child: child),
              ),
            );
            break;

          default:
            if (!_routeByCategoryBeamer(context, notification)) {
              _openNotificationsScreen(context);
            }
        }
    }
  }

  /// Beamer-only counterpart of [_routeByCategoryWithContainer]: routes by the
  /// stable category string without a provider container (data is loaded lazily
  /// by the destination screen). Returns `true` when it navigated.
  static bool _routeByCategoryBeamer(
    BuildContext context,
    NotificationModel notif,
  ) {
    debugPrint(
      '[NOTIF] Beamer fallback category routing: "${notif.notificationType}"',
    );

    Widget? page;
    switch (notif.notificationType) {
      case NotifCategory.message:
        page = const ChatPage();
        break;
      case NotifCategory.email:
        page = EmailView();
        break;
      case NotifCategory.savedSearch:
        NotificationBeamerNavigation.openSavedSearchRoute(context, notif);
        return true;
      case NotifCategory.tms:
        page = const ToDoPage();
        break;
      case NotifCategory.cloudStorage:
        page = const CloudStoragePage();
        break;
      case NotifCategory.association:
      case NotifCategory.community:
        page = const WallScreen();
        break;
      case NotifCategory.emma:
        page = const ChatAiPage();
        break;
      case NotifCategory.crm:
        page = const ClientsPage();
        break;
      default:
        return false;
    }

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => page!,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
    return true;
  }

  static Future<void> _openChatWithContainer(
    BuildContext context,
    ProviderContainer container,
    NotificationModel notif,
  ) async {
    debugPrint('[NOTIF] Chat click from background');

    try {
      final action = notif.actions.firstWhere(
        (a) => a.type == BNotifType.chat,
        orElse: () => NotificationAction(text: '', type: '', chatRoomId: null),
      );

      final roomId = action.chatRoomUuid;
      if (roomId == null) {
        debugPrint('[NOTIF] No chat_room_id found in actions');

        Navigator.of(context).push(
          PageRouteBuilder(
            opaque: false,
            pageBuilder: (_, __, ___) => const ChatPage(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
          ),
        );
        return;
      }

      try {
        await container.read(fetchRoomsProvider.notifier).fetchRooms();
        container.read(selectedChatId.notifier).state = roomId;
        container.read(isChatSelected.notifier).state = true;

        final rooms = container.read(fetchRoomsProvider);
        final room = rooms.cast<Room?>().firstWhere(
              (r) => r?.id == roomId,
              orElse: () => null,
            );

        if (room != null && room.otherUser != null) {
          container.read(otherUserData.notifier).state = room.otherUser!;
        }

        final token = ApiServices.token;
        if (token != null) {
          final wsUrl = URLs.webSocketChat(roomId, token);
          container.read(webSocketProvider.notifier).connect(wsUrl);
        }
      } catch (e) {
        debugPrint('[NOTIF] Error loading chat data: $e');
      }

      Navigator.of(context).push(
        PageRouteBuilder(
          opaque: false,
          pageBuilder: (_, __, ___) => const ChatPage(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
    } catch (e) {
      debugPrint('[NOTIF] Error in _openChatWithContainer: $e');

      Navigator.of(context).push(
        PageRouteBuilder(
          opaque: false,
          pageBuilder: (_, __, ___) => const ChatPage(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
    }
  }

  static Future<void> _openEmailWithContainer(
    BuildContext context,
    ProviderContainer container,
    int emailUUID,
  ) async {
    debugPrint('[NOTIF] Email click from background');

    try {
      container.read(selectedEmailFromNotificationProvider.notifier).state =
          emailUUID;
      await container.read(emailDetailsProvider(emailUUID).future);
    } catch (e) {
      debugPrint('[NOTIF] Error loading email data: $e');
    }

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

  static void _openAssociationNotificationWithContainer(
    BuildContext context,
    ProviderContainer container,
    NotificationModel notif,
  ) {
    debugPrint('[NOTIF] Opening association campaign from background');

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

  static void _openWallPostWithContainer(
    BuildContext context,
    ProviderContainer container,
    NotificationModel notif,
  ) {
    debugPrint('[NOTIF] Opening wall post from background');

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => const WallScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  static void _openAgentSuggestionWithContainer(
    BuildContext context,
    ProviderContainer container,
    NotificationModel notif,
  ) {
    debugPrint('[NOTIF] Opening agent suggestion from background');

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => const ClientsPage(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  static void _openScheduledEmailSentWithContainer(
    BuildContext context,
    ProviderContainer container,
    NotificationModel notif,
  ) {
    debugPrint('[NOTIF] Opening scheduled email from background');

    final scheduledEmailId = int.tryParse(notif.objectId) ?? 0;
    if (scheduledEmailId == 0) {
      debugPrint('[NOTIF] Invalid scheduled email ID');
      return;
    }

    try {
      container.read(mailTypeProvider.notifier).state = 'scheduled';
    } catch (e) {
      debugPrint('[NOTIF] Error setting mail type: $e');
    }

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

  static void _openCloudNotificationWithContainer(
    BuildContext context,
    ProviderContainer container,
    NotificationModel notif,
  ) {
    debugPrint('[NOTIF] Opening cloud notification from background');

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => const CloudStoragePage(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  static void _openTmsNewTaskWithContainer(
    BuildContext context,
    ProviderContainer container,
    NotificationModel notif,
  ) {
    debugPrint('[NOTIF] Opening TMS task from background');

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => const ToDoPage(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  static Future<void> _openEmmaSessionWithContainer(
    BuildContext context,
    ProviderContainer container,
    NotificationModel notif,
  ) async {
    debugPrint('[NOTIF] Opening Emma proactive session');

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
            ref: container,
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
        container.read(selectedAiRoomProvider.notifier).state =
            sessionId.toString();
        await container
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

  static NotificationModel? _createNotificationModelFromData(
    Map<String, dynamic> data,
  ) {
    try {
      final actionsData = _safeDecodeActions(data['actions']);
      final actions = actionsData
          .map((a) => NotificationAction.fromJson(a))
          .toList();

      return NotificationModel(
        id: int.tryParse(
              data['notification_id']?.toString() ??
                  data['id']?.toString() ??
                  '0',
            ) ??
            0,
        title: data['title']?.toString() ??
            data['notification_title']?.toString() ??
            'Notification',
        text: data['body']?.toString() ?? data['text']?.toString() ?? '',
        image: data['image']?.toString(),
        objectId: data['object_id']?.toString() ?? '',
        createAt:
            data['create_at']?.toString() ?? DateTime.now().toIso8601String(),
        user: int.tryParse(data['user']?.toString() ?? '0') ?? 0,
        fcmDevice: data['fcm_device'] != null
            ? int.tryParse(data['fcm_device'].toString())
            : null,
        contentType: int.tryParse(data['content_type']?.toString() ?? '0') ?? 0,
        actions: actions,
        raw: Map<String, dynamic>.from(data),
      );
    } catch (e) {
      debugPrint('[LOCAL] Error creating NotificationModel: $e');
      return null;
    }
  }

  static List<Map<String, dynamic>> _safeDecodeActions(dynamic raw) {
    if (raw == null) return const [];

    try {
      if (raw is List) {
        return raw
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }

      if (raw is String && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      }
    } catch (_) {}

    return const [];
  }

  static Future<void> showFromRemote(RemoteMessage m) async {
    final title = m.notification?.title ?? m.data['title'] ?? 'Notification';
    final rawBody = m.notification?.body ?? m.data['body'] ?? '';

    String senderName = rawBody;
    String messageText = rawBody;
    final idx = rawBody.indexOf(':');

    if (idx != -1) {
      senderName = rawBody.substring(0, idx).trim();
      messageText = rawBody.substring(idx + 1).trim();
    }

    final conversationTitle = title;

    final me = const Person(name: 'You');
    final sender = Person(name: senderName.isEmpty ? title : senderName);

    final style = MessagingStyleInformation(
      me,
      groupConversation: true,
      conversationTitle: conversationTitle,
      messages: <Message>[
        Message(
          messageText.isEmpty ? rawBody : messageText,
          DateTime.now(),
          sender,
        ),
      ],
    );

    final android = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: style,
      icon: '@drawable/ic_stat_notif',
      category: AndroidNotificationCategory.message,
    );

    const darwin = DarwinNotificationDetails(
      categoryIdentifier: 'MESSAGE',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final windows = WindowsNotificationDetails(
      subtitle: conversationTitle,
      timestamp: DateTime.now(),
    );

    final payload = jsonEncode(m.data);

    await _plugin.show(
      int.tryParse('${m.data['notification_id'] ?? 0}') ??
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      messageText.isEmpty ? rawBody : messageText,
      NotificationDetails(
        android: android,
        iOS: darwin,
        macOS: darwin,
        windows: windows,
      ),
      payload: payload,
    );
  }
}