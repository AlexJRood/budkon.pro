import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notification/local_notifier.dart';
import 'package:notification/notification_service.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/user/user/user_provider.dart';

enum NotificationBootstrapMode {
  fcm,
  desktopOnly,
}

typedef DesktopNotificationBinder = Future<StreamSubscription<Map<String, dynamic>>?> Function(
  WidgetRef ref,
);

class NotificationBootstrapService {
  NotificationBootstrapService({
    required this.ref,
    required this.navigatorKey,
    required this.mode,
    this.desktopNotificationBinder,
    this.logPrefix = 'NOTIF',
  });

  final WidgetRef ref;
  final GlobalKey<NavigatorState> navigatorKey;
  final NotificationBootstrapMode mode;
  final DesktopNotificationBinder? desktopNotificationBinder;
  final String logPrefix;

  bool _initialized = false;
  bool _desktopStreamBound = false;
  bool _navigationInProgress = false;

  Map<String, dynamic>? _pendingPayload;

  ProviderSubscription? _userProviderSub;
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onMessageOpenedSub;
  StreamSubscription<Map<String, dynamic>>? _desktopNotificationSub;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    await LocalNotifier.init();
    LocalNotifier.attachNavigatorKey(navigatorKey);

    _bindUserListener();

    if (mode == NotificationBootstrapMode.fcm) {
      await _initFcmMode();
    } else {
      await _bindDesktopStreamIfPossible();
    }
  }


  Future<void> _initFcmMode() async {
    try {
      await ref.read(fcmTokenProvider.notifier).initFCM();

      await _onMessageSub?.cancel();
      _onMessageSub = FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        debugPrint(
          '[$logPrefix] onMessage '
          'title="${message.notification?.title}" '
          'body="${message.notification?.body}" '
          'data=${message.data}',
        );

        await LocalNotifier.showFromRemote(message);
      });

      await _onMessageOpenedSub?.cancel();
      _onMessageOpenedSub =
          FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('[$logPrefix] onMessageOpenedApp: ${message.data}');
        _navigationInProgress = true;

        final data = Map<String, dynamic>.from(message.data);
        if (_canHandlePayloadNow()) {
          _handlePayloadNow(data);
        } else {
          _pendingPayload = data;
        }
      });

      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('[$logPrefix] getInitialMessage: ${initialMessage.data}');
        _navigationInProgress = true;

        final data = Map<String, dynamic>.from(initialMessage.data);
        if (_canHandlePayloadNow()) {
          _handlePayloadNow(data);
        } else {
          _pendingPayload = data;
        }
      }

      Future.delayed(const Duration(seconds: 3), () {
        unawaited(ref.read(fcmTokenProvider.notifier).reRegister());
      });
    } catch (e, stack) {
      debugPrint('[$logPrefix] FCM bootstrap error: $e\n$stack');
    }
  }

  void _bindUserListener() {
    _userProviderSub = ref.listenManual(userProvider, (previous, next) {
      final userId = next.valueOrNull?.userId;
      if (userId == null) return;

      debugPrint('[$logPrefix] userProvider loaded -> userId=$userId');

      if (mode == NotificationBootstrapMode.fcm) {
        unawaited(ref.read(fcmTokenProvider.notifier).reRegister());
      } else {
        unawaited(rebindDesktopNotifications());
      }

      flushPendingPayloadIfPossible();
    });
  }

  Future<void> _bindDesktopStreamIfPossible() async {
    if (_desktopStreamBound) return;
    if (desktopNotificationBinder == null) return;

    final authToken = ApiServices.token;
    final userId = ref.read(userProvider).valueOrNull?.userId;

    if (authToken == null || authToken.isEmpty) {
      debugPrint('[$logPrefix] skip desktop bind: no auth token yet');
      return;
    }

    if (userId == null) {
      debugPrint('[$logPrefix] skip desktop bind: user not loaded yet');
      return;
    }

    _desktopStreamBound = true;

    await _desktopNotificationSub?.cancel();
    _desktopNotificationSub = await desktopNotificationBinder!(ref);
  }

  Future<void> rebindDesktopNotifications() async {
    _desktopStreamBound = false;
    await _bindDesktopStreamIfPossible();
  }

  bool get hasPendingPayload => _pendingPayload != null;
  bool get navigationInProgress => _navigationInProgress;

  void markNavigationFinished() {
    _navigationInProgress = false;
  }

  void flushPendingPayloadIfPossible() {
    if (!_canHandlePayloadNow()) return;
    final payload = _pendingPayload;
    if (payload == null) return;

    _handlePayloadNow(payload);
    _pendingPayload = null;
  }

  bool _canHandlePayloadNow() {
    return LocalNotifier.navigatorKey?.currentState != null;
  }

  void _handlePayloadNow(Map<String, dynamic> payload) {
    final encoded = jsonEncode(payload);
    LocalNotifier.openFromPayload(encoded);
    _navigationInProgress = false;
  }

  Future<void> dispose() async {
    await _onMessageSub?.cancel();
    await _onMessageOpenedSub?.cancel();
    await _desktopNotificationSub?.cancel();
    _userProviderSub?.close();
  }
}