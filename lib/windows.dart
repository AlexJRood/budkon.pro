import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:beamer/beamer.dart';
import 'package:get/get.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:core/shell/bar_manager.dart';
import 'package:core/shell/app_router.dart' as router;
import 'package:core/platform/api_services.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/platform/values.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:core/translate/language_provider.dart';
import 'package:core/settings/provider/setting_provider.dart';
import 'package:core/user/user_session_seam.dart' show userSessionOverrides;
import 'package:core/settings/settings_gateway_seam.dart' show settingsSeamOverrides;

import 'app_modules.dart';

late final BeamerDelegate routerDelegate;
late final PlatformRouteInformationProvider appRouteInformationProvider;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // 1. Register modules BEFORE router so allRoutes() is populated
  registerAppModules();
  await initAppModules();

  // 2. Build router
  routerDelegate = router.generateRouterDelegate();
  appRouteInformationProvider = PlatformRouteInformationProvider(
    initialRouteInformation: const RouteInformation(uri: Uri(path: Routes.entry)),
  );

  runApp(
    ProviderScope(
      overrides: [
        ...userSessionOverrides,
        ...settingsSeamOverrides,
        // TODO: add feature seam overrides as modules grow
      ],
      child: const BudkonApp(),
    ),
  );
}

class BudkonApp extends ConsumerWidget {
  const BudkonApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingProvider);
    final language = ref.watch(languageProvider);

    return ScreenUtilInit(
      designSize: const Size(1440, 900),
      minTextAdapt: true,
      builder: (context, child) {
        return GetMaterialApp.router(
          title: 'budkon.pro',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme(settings?.colorScheme ?? Design.defaultColorScheme),
          darkTheme: AppTheme.darkTheme(settings?.colorScheme ?? Design.defaultColorScheme),
          themeMode: settings?.themeMode ?? ThemeMode.system,
          locale: language,
          routerDelegate: routerDelegate,
          routeInformationParser: BeamerParser(),
          routeInformationProvider: appRouteInformationProvider,
          builder: (context, child) => BarManager(child: child ?? const SizedBox.shrink()),
        );
      },
    );
  }
}
