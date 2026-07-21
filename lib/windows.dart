import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:map/portal_tile_cache_service.dart';

import 'package:core/shell/bar_manager.dart';
import 'package:beamer/beamer.dart';

import 'app_modules.dart';
import 'package:calendar/emma/emma_meeting_overlay.dart';
import 'package:calendar/emma/widgets/phone_call_overlay.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:feedback/feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:notification/local_notifier.dart';
import 'package:notification/notification_seam.dart' show notificationSeamOverrides;
import 'package:chat/chat_seam.dart' show chatSeamOverrides;
import 'package:calendar/calendar_seam.dart' show calendarSeamOverrides;
import 'package:feedback/feedback_seam.dart' show feedbackSeamOverrides;
import 'package:emma/emma_seam.dart' show emmaSeamOverrides;
import 'package:portal/portal_seam.dart' show portalSeamOverrides;
import 'package:profile/profile_seam.dart' show profileSeamOverrides;
import 'package:core/user/user_session_seam.dart' show userSessionOverrides;
import 'package:core/settings/settings_gateway_seam.dart' show settingsSeamOverrides;
import 'package:core/platform/api_services.dart';
import 'package:core/platform/internet_checker/internet_checker_widget.dart';
import 'package:company_cat/company_cat.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/platform/values.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:core/translate/language_provider.dart';
import 'package:core/settings/api/starting_point_repository.dart';
import 'package:core/settings/model/starting_point.dart';
import 'package:core/settings/provider/setting_provider.dart';
import 'package:core/settings/provider/starting_point_provider.dart';

import 'package:core/shell/app_router.dart' as router;
import 'package:emma/provider/emma_route_sync.dart';
import 'package:emma/tools/actions/global_bridge.dart';
import 'package:core/ui/highlight/highlight_overlay.dart';
import 'package:emma/sync/emma_local_db_bootstrap.dart';

late final BeamerDelegate routerDelegate;
late final PlatformRouteInformationProvider appRouteInformationProvider;
String _startupInitialRoutePath = '/budowa';

String _normalizeStartupPath(String value) {
  if (value.trim().isEmpty) return Routes.entry;

  final uri = Uri.tryParse(value);
  var path = uri?.path ?? value;

  if ((path.isEmpty || path == '/') && uri?.fragment.isNotEmpty == true) {
    final fragment = uri!.fragment.startsWith('/')
        ? uri.fragment
        : '/${uri.fragment}';
    path = Uri.tryParse(fragment)?.path ?? fragment;
  }

  if (path.isEmpty) return Routes.entry;
  if (path.length > 1 && path.endsWith('/')) {
    return path.substring(0, path.length - 1);
  }
  return path;
}

bool _looksLikeStartupAuthPath(String path) {
  final lower = path.toLowerCase();
  return lower.contains('login') ||
      lower.contains('register') ||
      lower.contains('signup') ||
      lower.contains('verify') ||
      lower.contains('verification') ||
      lower.contains('password') ||
      lower.contains('reset') ||
      lower.contains('logout');
}

bool _isStartupDefaultRoute(String rawPath) {
  final path = _normalizeStartupPath(rawPath);
  if (_looksLikeStartupAuthPath(path)) return false;

  final entry = _normalizeStartupPath(Routes.entry);
  final portal = _normalizeStartupPath(Routes.portalOffer);

  return path == '/' || path == entry || path == portal;
}

bool _isValidStartupTarget(String rawPath) {
  final path = _normalizeStartupPath(rawPath);
  if (path.isEmpty || path == '/') return false;
  if (path == _normalizeStartupPath(Routes.entry)) return false;
  if (_looksLikeStartupAuthPath(path)) return false;
  return true;
}

const _budkonDefaultRoute = '/budowa';

String _resolveStartupInitialRoute(StartingPoint point) {
  final platformInitialRoute = WidgetsBinding
      .instance.platformDispatcher.defaultRouteName;
  final normalizedPlatformRoute = _normalizeStartupPath(platformInitialRoute);

  if (!_isStartupDefaultRoute(normalizedPlatformRoute)) {
    return normalizedPlatformRoute;
  }

  final targetPath = _normalizeStartupPath(point.route);
  if (!_isValidStartupTarget(targetPath)) {
    return _budkonDefaultRoute;
  }

  return targetPath;
}

class _NoopTranslations extends Translations {
  _NoopTranslations();

  @override
  Map<String, Map<String, String>> get keys =>
      const <String, Map<String, String>>{};
}

Future<void> _initDesktopDatabaseFactory() async {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}

Future<void> main() async {
  if (!kDebugMode) debugPrint = (String? message, {int? wrapWidth}) {};
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(PortalTileCacheService.instance.ensureInitialized());

  await _initDesktopDatabaseFactory();

  final initialColorScheme = await loadColorScheme();
  final initialThemeMode = await loadSavedThemeMode();

  // Budkon always starts at the construction overview — ignore any cached
  // Hously starting point (different product, shared SharedPreferences key).
  _startupInitialRoutePath = _budkonDefaultRoute;

  // Register modules BEFORE building the router so the router can source
  // module-contributed routes (RouteSpec) from moduleRegistry.allRoutes().
  registerAppModules();

  routerDelegate = router.generateRouterDelegate();
  appRouteInformationProvider = PlatformRouteInformationProvider(
    initialRouteInformation: RouteInformation(
      location: _startupInitialRoutePath,
    ),
  );

  // Budkon: starting-point redirect disabled — always start at _budkonDefaultRoute.

  // This should only restore local API/token state. The expensive ref-based
  // user/settings sync runs after the first frame and must never block startup
  // routing.
  await ApiServices.init(null);

  await bootstrapEmmaLocalDb();

  // Modules were registered above (before the router) via registerAppModules().
  await initAppModules();

  final container = ProviderContainer(overrides: [
    colorSchemeProvider.overrideWith((ref) => initialColorScheme),
    themeProvider.overrideWith((ref) => initialThemeMode),
    ...notificationSeamOverrides,
    ...chatSeamOverrides,
    ...calendarSeamOverrides,
    ...feedbackSeamOverrides,
    ...emmaSeamOverrides,
    ...portalSeamOverrides,
    ...profileSeamOverrides,
    ...userSessionOverrides,
    ...settingsSeamOverrides,
  ]);
  ApiServices.setupInterceptors(container: container);

  runApp(
    BeamerProvider(
      routerDelegate: routerDelegate,
      child: UncontrolledProviderScope(
        container: container,
        child: const HouslyWindows(),
      ),
    ),
  );
}

class HouslyWindows extends ConsumerStatefulWidget {
  const HouslyWindows({super.key});

  @override
  ConsumerState<HouslyWindows> createState() => _HouslyWindowsState();
}

class _HouslyWindowsState extends ConsumerState<HouslyWindows> {
  bool _emmaRouteSyncScheduled = false;
  String? _emmaRoutePendingPath;

  StreamSubscription<Map<String, dynamic>>? _desktopNotificationSub;
  bool _notificationsBootstrapped = false;
  bool _startingPointNavigationBootstrapped = false;
  bool _notificationStartupNavigationInProgress = false;

  String? _pendingWindowsNotificationPayload;

  String _normalizePath(String value) {
    if (value.trim().isEmpty) return Routes.entry;

    final uri = Uri.tryParse(value);
    final path = uri?.path ?? value;

    if (path.isEmpty) return Routes.entry;
    if (path.length > 1 && path.endsWith('/')) {
      return path.substring(0, path.length - 1);
    }
    return path;
  }

  String _currentBeamerPath() {
    try {
      final state = routerDelegate.currentBeamLocation.state;
      final routeInfo = state.toRouteInformation();
      final location = routeInfo.location ?? Routes.entry;

      final uri = Uri.tryParse(location);
      if (uri == null) return _normalizePath(location);

      if (uri.path.isNotEmpty && uri.path != '/') {
        return _normalizePath(uri.path);
      }

      if (uri.fragment.isNotEmpty) {
        final frag =
            uri.fragment.startsWith('/') ? uri.fragment : '/${uri.fragment}';
        final fragUri = Uri.tryParse(frag);
        return _normalizePath(fragUri?.path ?? frag);
      }

      return _normalizePath(uri.path.isEmpty ? Routes.entry : uri.path);
    } catch (_) {
      return Routes.entry;
    }
  }

  bool _looksLikeAuthPath(String path) {
    final lower = path.toLowerCase();
    return lower.contains('login') ||
        lower.contains('register') ||
        lower.contains('signup') ||
        lower.contains('verify') ||
        lower.contains('verification') ||
        lower.contains('password') ||
        lower.contains('reset') ||
        lower.contains('logout');
  }

  bool _isStartupRedirectCandidate(String rawPath) {
    final path = _normalizePath(rawPath);

    if (_looksLikeAuthPath(path)) return false;

    final entry = _normalizePath(Routes.entry);
    final portal = _normalizePath(Routes.portalOffer);

    return path == '/' || path == entry || path == portal ||
        path == _normalizePath(_budkonDefaultRoute);
  }

  bool _isValidStartingPointTarget(String rawPath) {
    final path = _normalizePath(rawPath);
    if (path.isEmpty || path == '/') return false;
    if (path == _normalizePath(Routes.entry)) return false;
    if (_looksLikeAuthPath(path)) return false;
    return true;
  }

  Future<void> _bootstrapStartingPointNavigation() async {
    if (_startingPointNavigationBootstrapped) return;
    _startingPointNavigationBootstrapped = true;

    // Budkon always starts at _budkonDefaultRoute — skip starting-point redirect.
    unawaited(_syncSettingsAfterStartup(allowBackendRedirectIfNoLocalCache: false));
    return;

    // ignore: dead_code
    final notifier = ref.read(startingPointProvider.notifier);
    final hadCachedStartingPoint = await notifier.hasCachedStartingPoint();

    final initialPath = _currentBeamerPath();
    if (!_isStartupRedirectCandidate(initialPath)) {
      debugPrint('🚦 Starting point skipped. Current route: $initialPath');
      unawaited(
        _syncSettingsAfterStartup(
          allowBackendRedirectIfNoLocalCache: false,
        ),
      );
      return;
    }

    try {
      // This only waits for local SharedPreferences cache. Never wait for API
      // before opening the startup route.
      await notifier.ensureLoaded(
        timeout: const Duration(milliseconds: 120),
      );
    } catch (error, stack) {
      debugPrint('⚠️ Failed to load local starting point: $error\n$stack');
    }

    if (!mounted) return;

    final currentPath = _currentBeamerPath();
    if (!_isStartupRedirectCandidate(currentPath)) {
      debugPrint('🚦 Starting point skipped after local cache. Current route: $currentPath');
      unawaited(
        _syncSettingsAfterStartup(
          allowBackendRedirectIfNoLocalCache: false,
        ),
      );
      return;
    }

    final selectedPoint = ref.read(startingPointProvider);
    final targetPath = _normalizePath(selectedPoint.route);

    if (_isValidStartingPointTarget(targetPath) &&
        _normalizePath(currentPath) != targetPath) {
      debugPrint(
        '⚡ Opening cached starting point instantly: ${selectedPoint.displayName} → $targetPath',
      );

      ref.read(navigationService).pushNamedReplacementScreen(targetPath);
    } else {
      debugPrint('🚦 Starting point already open or invalid: $targetPath');
    }

    // Backend sync is deliberately background-only. It updates local cache for
    // the next launch. On a brand-new device, where no cache exists yet, it may
    // also redirect once if the user is still sitting on the default route.
    unawaited(
      _syncSettingsAfterStartup(
        allowBackendRedirectIfNoLocalCache: !hadCachedStartingPoint,
      ),
    );
  }

  Future<void> _syncSettingsAfterStartup({
    required bool allowBackendRedirectIfNoLocalCache,
  }) async {
    try {
      await ref
          .read(settingProvider.notifier)
          .fetchSettingData()
          .timeout(const Duration(seconds: 8));
    } catch (error, stack) {
      debugPrint('⚠️ Startup settings sync skipped: $error\n$stack');
      return;
    }

    if (!mounted || !allowBackendRedirectIfNoLocalCache) return;
    if (_notificationStartupNavigationInProgress) return;

    final currentPath = _currentBeamerPath();
    if (!_isStartupRedirectCandidate(currentPath)) return;

    final selectedPoint = ref.read(startingPointProvider);
    final targetPath = _normalizePath(selectedPoint.route);

    if (!_isValidStartingPointTarget(targetPath) ||
        _normalizePath(currentPath) == targetPath) {
      return;
    }

    debugPrint(
      '☁️ Opening backend starting point on first cache sync: ${selectedPoint.displayName} → $targetPath',
    );

    ref.read(navigationService).pushNamedReplacementScreen(targetPath);
  }

  void _onBeamerChange() {
    _emmaRoutePendingPath = _currentBeamerPath();

    if (_emmaRouteSyncScheduled) return;
    _emmaRouteSyncScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _emmaRouteSyncScheduled = false;
      if (!mounted) return;

      final path = _emmaRoutePendingPath ?? _currentBeamerPath();
      syncEmmaRoute(ref, path);
    });
  }

  Future<void> _bootstrapNotifications() async {
    if (_notificationsBootstrapped) return;
    _notificationsBootstrapped = true;

    try {
      LocalNotifier.attachNavigatorKey(routerDelegate.navigatorKey);
      await LocalNotifier.init();

      final launchPayload = await LocalNotifier.getLaunchPayloadIfAny();
      if (launchPayload != null && launchPayload.isNotEmpty) {
        _pendingWindowsNotificationPayload = launchPayload;
      }

      await _bindDesktopNotificationStream();
    } catch (e, stack) {
      debugPrint('Windows notification bootstrap error: $e\n$stack');
      _notificationsBootstrapped = false;
    }
  }

  Future<void> _bindDesktopNotificationStream() async {
    // TODO:
    // Connect your desktop notifications stream here.
  }

  SnackBarThemeData _buildResponsiveSnackBarTheme({
    required ThemeData theme,
    required BuildContext context,
    required double desktopBottom,
    required double mobileBottom,
  }) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= 900;

    const right = 16.0;
    const targetWidth = 400.0;

    final double left = isDesktop
        ? ((screenWidth - targetWidth - right) > 16.0
            ? (screenWidth - targetWidth - right)
            : 16.0)
        : 16.0;

    final double bottom = isDesktop ? desktopBottom : mobileBottom;

    return theme.snackBarTheme.copyWith(
      behavior: SnackBarBehavior.floating,
      width: isDesktop ? targetWidth : null,
      insetPadding: EdgeInsets.only(
        left: left,
        right: right,
        bottom: bottom,
      ),
    );
  }

  Size _resolveDesignSize(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    if (w <= 600) {
      return const Size(375, 812);
    } else if (w <= 1080) {
      return const Size(768, 1024);
    } else {
      return const Size(1920, 1080);
    }
  }

  @override
  void initState() {
    super.initState();

    LocalNotifier.attachNavigatorKey(routerDelegate.navigatorKey);
    ref.read(navigationService).navigatorKey = routerDelegate.navigatorKey;
    routerDelegate.addListener(_onBeamerChange);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      // Startup navigation must happen before ref-based API init. The previous
      // order waited for user/settings API first, so the portal/landing route
      // had time to build and load map/listing providers.
      await _bootstrapStartingPointNavigation();
      if (!mounted) return;

      initializeLogicalKeyboardKeys(ref);
      if (!mounted) return;

      // Notification startup is allowed to override the cached starting point,
      // but it must not block normal startup.
      unawaited(
        _bootstrapNotifications().then((_) async {
          if (!mounted) return;

          final pendingPayload = _pendingWindowsNotificationPayload;
          if (pendingPayload == null || pendingPayload.isEmpty) return;

          _notificationStartupNavigationInProgress = true;
          _pendingWindowsNotificationPayload = null;

          unawaited(
            LocalNotifier.openFromPayload(pendingPayload).whenComplete(() {
              _notificationStartupNavigationInProgress = false;
            }),
          );
        }),
      );

      // Ref-based API init can be expensive on desktop/macOS. Run it after the
      // route is already selected, and do not await it in the first-frame path.
      unawaited(
        ApiServices.init(ref).catchError((error, stack) {
          debugPrint('⚠️ Background ApiServices.init(ref) failed: $error\n$stack');
        }),
      );

      if (!mounted) return;
      _onBeamerChange();
    });
  }

  @override
  void dispose() {
    _desktopNotificationSub?.cancel();
    routerDelegate.removeListener(_onBeamerChange);
    super.dispose();
  }

  Widget _routedShell({
    Locale? locale,
    Translations? translations,
    ThemeMode? themeMode,
    required Widget overlay,
  }) {
    final ThemeData baseLight = ThemeData();
    final ThemeData baseDark = ThemeData.dark();

    return ScreenUtilInit(
      designSize: const Size(1920, 1080),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, _) => GetMaterialApp.router(
        scaffoldMessengerKey: scaffoldMessengerKey,
        translations: translations,
        locale: locale,
        fallbackLocale: const Locale('en', 'US'),
        supportedLocales: mobilecodes,
        localizationsDelegates: const [
          FlutterQuillLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          CountryLocalizations.delegate,
        ],
        theme: baseLight,
        darkTheme: baseDark,
        themeMode: themeMode ?? ThemeMode.system,
        title: 'Hously',
        routeInformationProvider: appRouteInformationProvider,
        routeInformationParser: BeamerParser(),
        backButtonDispatcher: BeamerBackButtonDispatcher(
          delegate: routerDelegate,
        ),
        debugShowCheckedModeBanner: false,
        routerDelegate: routerDelegate,
        builder: (context, child) {
          final theme = Theme.of(context);

          final snackTheme = _buildResponsiveSnackBarTheme(
            theme: theme,
            context: context,
            desktopBottom: 16.0,
            mobileBottom: 505.0,
          );

          return Theme(
            data: theme.copyWith(snackBarTheme: snackTheme),
            child: Stack(
              children: [
                overlay,
                const EmmaUiHighlightOverlay(),
                const EmmaFrontendBridge(),
                const EmmaMeetingOverlay(),
                const PhoneCallOverlay(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _routedApp({
    required Locale locale,
    required Translations translations,
  }) {
    final currentThemeMode = ref.watch(themeProvider);
    final colorScheme = ref.watch(colorSchemeProvider);
    final theme = ref.read(themeColorsProvider);

    return ScreenUtilInit(
      designSize: _resolveDesignSize(context),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, _) => BetterFeedback(
        localeOverride: locale,
        mode: FeedbackMode.draw,
        pixelRatio: 1,
        theme: FeedbackThemeData(
          background: theme.adPopBackground,
          feedbackSheetColor: theme.dashboardContainer,
          dragHandleColor: theme.themeColor,
          drawColors: const [
            Colors.red,
            Colors.green,
            Colors.blue,
            Colors.yellow,
          ],
        ),
        localizationsDelegates: [
          FlutterQuillLocalizations.delegate,
          GlobalFeedbackLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          CountryLocalizations.delegate,
        ],
        child: GetMaterialApp.router(
          scaffoldMessengerKey: scaffoldMessengerKey,
          translations: translations,
          locale: locale,
          fallbackLocale: const Locale('en', 'US'),
          supportedLocales: mobilecodes,
          localizationsDelegates: const [
            FlutterQuillLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            CountryLocalizations.delegate,
          ],
          theme: resolveAppTheme(
            colorScheme: colorScheme,
            context: context,
            currentThemeMode: currentThemeMode ?? ThemeMode.system,
            ref: ref,
          ),
          darkTheme: getDarkTheme(
            colorScheme: colorScheme,
            context: context,
            currentThemeMode: currentThemeMode ?? ThemeMode.system,
            ref: ref,
          ),
          themeMode: currentThemeMode ?? ThemeMode.system,
          routeInformationProvider: appRouteInformationProvider,
          routeInformationParser: BeamerParser(),
          backButtonDispatcher: BeamerBackButtonDispatcher(
            delegate: routerDelegate,
          ),
          debugShowCheckedModeBanner: false,
          title: Routes.getWebsiteTitle(context),
          routerDelegate: routerDelegate,
          builder: (context, child) {
            final theme = Theme.of(context);
            final routedChild = child ?? const SizedBox.shrink();

            final snackTheme = _buildResponsiveSnackBarTheme(
              theme: theme,
              context: context,
              desktopBottom: 16.0,
              mobileBottom: 55.0,
            );

            return Theme(
              data: theme.copyWith(snackBarTheme: snackTheme),
              child: Stack(
                children: [
                  InternetCheckWidget(child: routedChild),
                  const EmmaUiHighlightOverlay(),
                  const EmmaFrontendBridge(),
                  const EmmaMeetingOverlay(),
                  const PhoneCallOverlay(),
                  const CompanyCatMount(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localeAsync = ref.watch(languageProvider);
    final translationsAsync = ref.watch(appTranslationProvider);

    return localeAsync.when(
      loading: () => _routedShell(
        overlay: const Scaffold(
          backgroundColor: Colors.black,
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => _routedShell(
        overlay: Scaffold(
          body: Center(child: Text('Locale error: $e')),
        ),
      ),
      data: (locale) {
        return translationsAsync.when(
          loading: () => _routedShell(
            locale: locale,
            overlay: const Scaffold(
              backgroundColor: Colors.black,
              body: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (e, _) => _routedShell(
            locale: locale,
            overlay: Scaffold(
              body: Center(child: Text('Translations error: $e')),
            ),
          ),
          data: (translations) {
            Translations safe = _NoopTranslations();

            try {
              final _ = translations.keys;
              safe = translations;
            } catch (_) {}

            return _routedApp(
              locale: locale,
              translations: safe,
            );
          },
        );
      },
    );
  }
}