// notification/lib/notification_service.dart

import 'dart:convert';
import 'package:notification/notification_urls.dart';
import 'package:flutter/foundation.dart';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notification/model/device_model.dart';
import 'package:core/platform/secure_storage.dart';
import 'package:core/platform/url.dart';
import 'package:notification/model/notification_model.dart';
import 'package:core/user/user/user_provider.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/platform/live/live.dart';
// packages/notification/lib/notification_service.dart

import 'dart:async';

import 'package:core/platform/platforms/html_utils_stub.dart'
    if (dart.library.html) 'package:core/platform/platforms/html_utils_web.dart';

String _mask(String? s, {int head = 6, int tail = 6}) {
  if (s == null) return 'null';
  if (s.length <= head + tail) return s;
  return '${s.substring(0, head)}...${s.substring(s.length - tail)}';
}

Map<String, dynamic> _decodeResponseToMap(dynamic data) {
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return Map<String, dynamic>.from(data);

  if (data is List<int>) {
    return Map<String, dynamic>.from(jsonDecode(utf8.decode(data)));
  }

  if (data is String) {
    return Map<String, dynamic>.from(jsonDecode(data));
  }

  throw FormatException('Unsupported response data type: ${data.runtimeType}');
}

final notificationProvider = ChangeNotifierProvider<NotificationProvider>((ref) {
  final provider = NotificationProvider();

  // Live badge (owner-scoped): sygnał notification:unread niesie świeży licznik
  // w payloadzie -> ustaw bezpośrednio, bez round-tripa. Brak payloadu ->
  // fallback na dociągnięcie z endpointu.
  final off = ref.read(liveClientProvider).registry.on(
    'notification:unread',
    (sig) {
      final raw = sig.payload?['count'];
      if (raw is int) {
        provider.applyLiveCount(raw);
      } else if (raw != null) {
        provider.applyLiveCount(int.tryParse('$raw') ?? provider.unreadCount);
      } else {
        provider.getUnreadCount();
      }
    },
  );
  ref.onDispose(off);

  // Resync po (re)connekcie — dociągnij licznik, gdyby sygnały umknęły offline.
  ref.listen(liveConnectionProvider, (_, next) {
    if (next.valueOrNull == LiveConnectionState.connected) {
      provider.getUnreadCount();
    }
  });

  return provider;
});

class NotificationProvider extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications => _notifications;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  String? _nextUrl;
  String? _previousUrl;
  int _totalCount = 0;
  int get totalCount => _totalCount;

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  /// Ustaw licznik nieprzeczytanych z sygnału live (delta). Idempotentne.
  void applyLiveCount(int count) {
    if (count < 0 || count == _unreadCount) return;
    _unreadCount = count;
    notifyListeners();
  }

  List<NotificationCategory> _categories = [];
  List<NotificationCategory> get categories => _categories;

  bool _isLoadingCategories = false;
  bool get isLoadingCategories => _isLoadingCategories;

  NotificationFilters _currentFilters = NotificationFilters();
  NotificationFilters get currentFilters => _currentFilters;

  // Existing method
  Future<void> addDevices(DeviceModel notificationModel) async {
    try {
      debugPrint('[NOTIF] addDevices() -> POST ${URLs.fcmAddDevice}');
      final response = await ApiServices.post(
        URLs.fcmAddDevice,
        hasToken: true,
        data: notificationModel.toJson(),
      );

      if (response != null && response.statusCode == 200) {
        debugPrint('[NOTIF] addDevices() ✔ 200');
      } else {
        debugPrint(
          '[NOTIF] addDevices() ✖ status=${response?.statusCode} body=${response?.data}',
        );
      }
    } catch (e) {
      debugPrint('[NOTIF] addDevices() EX: $e');
    }
  }

  Future<void> getUserNotifications(WidgetRef ref) async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('[NOTIF] getUserNotifications() -> GET ${NotificationUrls.userNotifications}');

      final response = await ApiServices.get(
        ref: ref,
        NotificationUrls.userNotifications,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        debugPrint('[NOTIF] getUserNotifications() ✔ 200');

        final decodedResponse = _decodeResponseToMap(response.data);
        final userNotificationResponse = UserNotificationResponse.fromJson(
          decodedResponse,
        );

        _notifications = userNotificationResponse.results;
        _nextUrl = userNotificationResponse.next;
        _previousUrl = userNotificationResponse.previous;
        _totalCount = userNotificationResponse.count;
        
        notifyListeners();
      } else {
        debugPrint('[NOTIF] getUserNotifications() ✖ status=${response?.statusCode}');
      }
    } catch (e) {
      debugPrint('[NOTIF] getUserNotifications() EX: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> makeNotificationSeen(int notificationId) async {
    try {
      final url = NotificationUrls.notificationsSeen('$notificationId');
      debugPrint('[NOTIF] makeNotificationSeen($notificationId) -> POST $url');

      final response = await ApiServices.post(url, hasToken: true);

      if (response != null && response.statusCode == 200) {
        debugPrint('[NOTIF] makeNotificationSeen() ✔ 200');
      } else {
        debugPrint('[NOTIF] makeNotificationSeen() ✖ status=${response?.statusCode}');
      }
    } catch (e) {
      debugPrint('[NOTIF] makeNotificationSeen() EX: $e');
    }
  }

Future<void> getAvailableCategories({bool onlyNonEmpty = false, WidgetRef? ref}) async {
  _isLoadingCategories = true;
  notifyListeners();

  try {
    final url = onlyNonEmpty 
        ? '${NotificationUrls.availableNotificationCategories}?only_non_empty=true'
        : NotificationUrls.availableNotificationCategories;
    
    debugPrint('[NOTIF] getAvailableCategories() -> GET $url');

    final response = await ApiServices.get(
      url,
      hasToken: true,
      ref: ref,
    );

    if (response != null && response.statusCode == 200) {
      final rawData = response.data;
      _categories = [];
      
      if (rawData is List) {
        for (var item in rawData) {
          if (item is Map) {
            final convertedMap = Map<String, dynamic>.from(item);
            _categories.add(NotificationCategory.fromJson(convertedMap));
          }
        }
      } else if (rawData is Map) {
        final convertedMap = Map<String, dynamic>.from(rawData);
        
        if (convertedMap.containsKey('results')) {
          final results = convertedMap['results'];
          if (results is List) {
            for (var item in results) {
              if (item is Map) {
                final convertedItem = Map<String, dynamic>.from(item);
                _categories.add(NotificationCategory.fromJson(convertedItem));
              }
            }
          }
        } else {
          _categories.add(NotificationCategory.fromJson(convertedMap));
        }
      }
      
      debugPrint('[NOTIF] getAvailableCategories() ✔ Got ${_categories.length} categories');
      notifyListeners();
    }
  } catch (e) {
    debugPrint('[NOTIF] getAvailableCategories() EX: $e');
  }

  _isLoadingCategories = false;
  notifyListeners();
}

  Future<int> getUnreadCount({WidgetRef? ref}) async {
    try {
      debugPrint('[NOTIF] getUnreadCount() -> GET ${NotificationUrls.notificationUnreadCount}');

      final response = await ApiServices.get(
        NotificationUrls.notificationUnreadCount,
        hasToken: true,
        ref: ref,
      );

      if (response != null && response.statusCode == 200) {
        final decodedResponse = _decodeResponseToMap(response.data);
        _unreadCount = decodedResponse['unread_count'] ?? 0;
        debugPrint('[NOTIF] getUnreadCount() ✔ count=$_unreadCount');
        notifyListeners();
        return _unreadCount;
      }
      return 0;
    } catch (e) {
      debugPrint('[NOTIF] getUnreadCount() EX: $e');
      return 0;
    }
  }
  Future<bool> makeAllNotificationsSeen() async {
    try {
      final response = await ApiServices.post(
        NotificationUrls.makeAllNotificationsSeen,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        _unreadCount = 0;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[NOTIF] makeAllNotificationsSeen() EX: $e');
      return false;
    }
  }

  Future<bool> bulkMarkSeenByIds(List<int> ids) async {
    if (ids.isEmpty) return false;

    try {
      final response = await ApiServices.post(
        NotificationUrls.bulkSeenNotifications,
        data: {'ids': ids},
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        await getUnreadCount();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[NOTIF] bulkMarkSeenByIds() EX: $e');
      return false;
    }
  }

  Future<bool> deleteNotification(int notificationId) async {
    try {
      final url = NotificationUrls.deleteNotification('$notificationId');
      final response = await ApiServices.delete(url, hasToken: true);

      if (response != null && response.statusCode == 204) {
        _notifications.removeWhere((n) => n.id == notificationId);
        _totalCount--;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[NOTIF] deleteNotification() EX: $e');
      return false;
    }
  }

  Future<bool> bulkDeleteNotifications(List<int> ids) async {
    if (ids.isEmpty) return false;

    try {
      final response = await ApiServices.post(
        NotificationUrls.bulkDeleteNotifications,
        data: {'ids': ids},
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        _notifications.removeWhere((n) => ids.contains(n.id));
        _totalCount -= ids.length;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[NOTIF] bulkDeleteNotifications() EX: $e');
      return false;
    }
  }

  Future<void> refreshAllData({WidgetRef? ref}) async {
    await Future.wait([
      getUnreadCount(ref: ref),
      getUserNotifications(ref!),
      getAvailableCategories(ref: ref),
    ]);
  }
}

final fcmTokenProvider = StateNotifierProvider<FCMTokenNotifier, String?>(
  (ref) => FCMTokenNotifier(ref),
);

class FCMTokenNotifier extends StateNotifier<String?> {
  FCMTokenNotifier(this._ref) : super(null);

  final Ref _ref;

  bool _isInitializing = false;
  bool _initialized = false;
  StreamSubscription<String>? _tokenRefreshSub;

  Future<void> initFCM() async {
    if (_initialized || _isInitializing) {
      debugPrint(
        '[FCM] initFCM skipped. initialized=$_initialized initializing=$_isInitializing',
      );
      return;
    }

    _isInitializing = true;
    final stopwatch = Stopwatch()..start();

    debugPrint(
      '[FCM] initFCM() starting... '
      'platform=${defaultTargetPlatform.name} '
      'firebaseApps=${Firebase.apps.length} '
      'apiToken=${ApiServices.token == null ? "null" : _mask(ApiServices.token)} '
      'userId=${_ref.read(userProvider).valueOrNull?.userId}',
    );

    try {
      if (Firebase.apps.isEmpty) {
        debugPrint('[FCM] Firebase is not initialized yet.');
        return;
      }

      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('[FCM] requestPermission -> ${settings.authorizationStatus}');

      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        debugPrint('[FCM] Permission not granted; aborting FCM init.');
        return;
      }

      await FirebaseMessaging.instance.setAutoInitEnabled(true);
      debugPrint('[FCM] AutoInitEnabled = true');

      final bool isApple =
          !kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.iOS ||
              defaultTargetPlatform == TargetPlatform.macOS);

      String? apnsToken;

      if (isApple) {
        for (var i = 0; i < 12; i++) {
          try {
            apnsToken = await FirebaseMessaging.instance.getAPNSToken();
            debugPrint(
              '[FCM] APNs attempt ${i + 1}/12 -> ${_mask(apnsToken)} '
              '(platform=${defaultTargetPlatform.name})',
            );

            if (apnsToken != null && apnsToken.isNotEmpty) {
              debugPrint('[FCM] APNs token became available on attempt ${i + 1}');
              break;
            }
          } catch (e, stack) {
            debugPrint('[FCM] APNs warmup EX: $e\n$stack');
          }

          await Future.delayed(const Duration(seconds: 2));
        }

        if (apnsToken == null || apnsToken.isEmpty) {
          debugPrint(
            '[FCM] APNs token still missing. '
            'Skipping getToken() for now and waiting for native registration.',
          );
          return;
        }
      }

      String? token;

      for (var i = 0; i < 12; i++) {
        try {
          debugPrint('[FCM] getToken() attempt ${i + 1}/12 -> start');

          token = kIsWeb
              ? await FirebaseMessaging.instance.getToken(
                  vapidKey:
                      'BL6jlkeVsuV5n8H-EGMiRbm1LHd2NnbFU66w7LGPZPjZYOdt8YS4ziu8YWNes_UUT2py04geB5Opq7Xqp0zkd5o',
                )
              : await FirebaseMessaging.instance.getToken();

          debugPrint('[FCM] getToken() attempt ${i + 1}/12 -> ${_mask(token)}');

          if (token != null && token.isNotEmpty) {
            break;
          }
        } catch (e, stack) {
          debugPrint('[FCM] getToken EX on attempt ${i + 1}/12: $e\n$stack');
        }

        await Future.delayed(const Duration(seconds: 2));
      }

      if (token == null || token.isEmpty) {
        debugPrint(
          '[FCM] Could not get FCM token. '
          'elapsed=${stopwatch.elapsedMilliseconds} ms '
          'apiToken=${ApiServices.token == null ? "null" : _mask(ApiServices.token)} '
          'userId=${_ref.read(userProvider).valueOrNull?.userId}',
        );
        return;
      }

      state = token;
      debugPrint('✅ [FCM] FINAL TOKEN: ${_mask(token)}');

      await _registerDeviceToServerWithRetry(token);

      await _tokenRefreshSub?.cancel();
      _tokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen(
        (newToken) async {
          debugPrint('[FCM] onTokenRefresh -> ${_mask(newToken)}');
          state = newToken;
          await _registerDeviceToServerWithRetry(newToken);
        },
      );

      _initialized = true;
      debugPrint('[FCM] initFCM() done in ${stopwatch.elapsedMilliseconds} ms');
    } catch (e, stack) {
      debugPrint('[FCM] initFCM ERROR: $e\n$stack');
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> reRegister() async {
    if (state == null || state!.isEmpty) {
      debugPrint('[FCM] reRegister: token missing, trying initFCM first...');
      await initFCM();
    }

    final token = state;
    if (token == null || token.isEmpty) {
      debugPrint('[FCM] reRegister aborted: still no token.');
      return;
    }

    await _registerDeviceToServerWithRetry(token);
  }

  Future<void> _registerDeviceToServerWithRetry(
    String token, {
    int maxAttempts = 8,
  }) async {
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      final authToken = ApiServices.token;
      final userAsyncValue = _ref.read(userProvider);
      final userId = userAsyncValue.valueOrNull?.userId;

      final authReady = authToken != null && authToken.isNotEmpty;
      final userReady = userId != null;

      if (!authReady || !userReady) {
        debugPrint(
          '[FCM] register postponed ($attempt/$maxAttempts) '
          'authReady=$authReady userId=$userId',
        );

        if (attempt < maxAttempts) {
          await Future.delayed(const Duration(seconds: 2));
        }
        continue;
      }

      final success = await _registerDeviceToServer(token);
      if (success) return;

      if (attempt < maxAttempts) {
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    debugPrint('[FCM] register failed after all retry attempts.');
  }

  Future<bool> _registerDeviceToServer(String token) async {
    debugPrint('[FCM] registerDeviceToServer() begin');

    final authToken = ApiServices.token;
    if (authToken == null || authToken.isEmpty) {
      debugPrint('[FCM] skip register: no auth token yet');
      return false;
    }

    final userAsyncValue = _ref.read(userProvider);
    final userId = userAsyncValue.valueOrNull?.userId;

    debugPrint(
      '[FCM] userProvider -> isLoading=${userAsyncValue.isLoading} hasValue=${userAsyncValue.hasValue} userId=$userId',
    );

    if (userId == null) {
      debugPrint('[FCM] skip register: user is not loaded yet');
      return false;
    }

    final deviceId = await SecureStorage().getOrCreateDeviceId();
    final deviceInfoPlugin = DeviceInfoPlugin();

    String deviceName = 'Unknown Device';
    String platformType = 'unknown';

    try {
      if (kIsWeb) {
        final webInfo = await deviceInfoPlugin.webBrowserInfo;
        deviceName = webInfo.browserName.name;
        platformType = 'web';
      } else {
        final type = await getDeviceType();
        debugPrint('[FCM] getDeviceType() -> $type');

        switch (type) {
          case 'android':
            final androidInfo = await deviceInfoPlugin.androidInfo;
            deviceName = androidInfo.model;
            platformType = 'android';
            break;
          case 'ios':
            final iosInfo = await deviceInfoPlugin.iosInfo;
            deviceName = iosInfo.utsname.machine;
            platformType = 'ios';
            break;
          case 'macos':
            final macInfo = await deviceInfoPlugin.macOsInfo;
            deviceName = macInfo.computerName.isNotEmpty
                ? macInfo.computerName
                : macInfo.model;
            platformType = 'macos';
            break;
          case 'windows':
            final windowsInfo = await deviceInfoPlugin.windowsInfo;
            deviceName = windowsInfo.computerName;
            platformType = 'windows';
            break;
          case 'linux':
            final linuxInfo = await deviceInfoPlugin.linuxInfo;
            deviceName = linuxInfo.prettyName;
            platformType = 'linux';
            break;
          default:
            platformType = type;
            break;
        }
      }
    } catch (e) {
      debugPrint('[FCM] device info EX: $e');
    }

    final payload = <String, dynamic>{
      'registration_id': token,
      'type': platformType,
      'name': deviceName,
      'user': '$userId',
      'active': true,
      'device_id': deviceId,
    };

    debugPrint('[FCM] About to POST ${URLs.fcmAddDevice}');
    debugPrint(
      '[FCM] Payload: '
      'reg=${_mask(token)} type=$platformType name="$deviceName" '
      'user=$userId device_id=$deviceId',
    );

    try {
      final response = await ApiServices.post(
        URLs.fcmAddDevice,
        data: payload,
        hasToken: true,
        ref: _ref,
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        debugPrint('✅ [FCM] device registered (status ${response.statusCode})');
        return true;
      }

      debugPrint(
        '❌ [FCM] register failed: status=${response?.statusCode} body=${response?.data}',
      );
      return false;
    } catch (e) {
      debugPrint('❌ [FCM] register EX: $e');
      return false;
    }
  }

  Future<void> logOut() async {
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;

    try {
      await FirebaseMessaging.instance.setAutoInitEnabled(false);
      await FirebaseMessaging.instance.deleteToken();
      debugPrint('[FCM] Token deleted from Firebase on logout');
    } catch (e) {
      debugPrint('[FCM] deleteToken error (non-fatal): $e');
    }

    state = null;
    _initialized = false;
    _isInitializing = false;
  }

  @override
  void dispose() {
    _tokenRefreshSub?.cancel();
    super.dispose();
  }
}