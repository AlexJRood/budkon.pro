
// lib/firebase_background.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:developer' as dev;

@pragma('vm:entry-point') // <- required so iOS can find it in background isolate
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  dev.log('📩 [BG] message: '
      'title=${message.notification?.title} '
      'body=${message.notification?.body} '
      'data=${message.data}');
  // TODO: optional – persist to local storage, schedule local notif, etc.
}
