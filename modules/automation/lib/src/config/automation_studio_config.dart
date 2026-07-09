import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/common/chrome/side_menu_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:core/ui/device_type_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:core/theme/apptheme.dart';

/// Token is still kept in config for compatibility, but HTTP calls are routed
/// through your shared ApiServices in AutomationApiService.
typedef AutomationTokenProvider = Future<String?> Function();
typedef AutomationTranslate = String Function(BuildContext context, String key);

typedef AutomationRouteOpener = void Function(
  BuildContext context,
  String route,
  Map<String, dynamic> params,
);

class AutomationStudioColors {
  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color border;
  final Color primary;
  final Color text;
  final Color mutedText;
  final Color success;
  final Color danger;
  final Color warning;
  final Color shadow;

  const AutomationStudioColors({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.primary,
    required this.text,
    required this.mutedText,
    required this.success,
    required this.danger,
    required this.warning,
    required this.shadow,
  });

  factory AutomationStudioColors.fromMaterialTheme(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return AutomationStudioColors(
      background: theme.scaffoldBackgroundColor,
      surface: scheme.surface,
      surfaceAlt: isDark ? const Color(0xFF171A22) : const Color(0xFFF7F8FA),
      border: isDark ? const Color(0xFF2A2F3A) : const Color(0xFFE2E6EF),
      primary: scheme.primary,
      text: scheme.onSurface,
      mutedText: scheme.onSurface.withAlpha(165),
      success: const Color(0xFF28A745),
      danger: const Color(0xFFDC3545),
      warning: const Color(0xFFFFB020),
      shadow: Colors.black.withAlpha(isDark ? 82 : 26),
    );
  }

  /// Main colors mapping for the monorepo theme service.
  ///
  /// This intentionally uses dynamic because ThemeColors lives in the theme
  /// package and can evolve. Missing fields fall back to Material colors.
  factory AutomationStudioColors.fromThemeColors(
    BuildContext context,
    dynamic theme,
  ) {
    final fallback = AutomationStudioColors.fromMaterialTheme(context);

    Color readColor(String name, Color fallbackValue) {
      try {
        final value = switch (name) {
          'dashboardBackground' => theme.dashboardBackground,
          'dashboardContainer' => theme.dashboardContainer,
          'popupcontainercolor' => theme.popupcontainercolor,
          'dashboardBoarder' => theme.dashboardBoarder,
          'themeColor' => theme.themeColor,
          'textColor' => theme.textColor,
          _ => null,
        };

        if (value is Color) return value;
      } catch (_) {}

      return fallbackValue;
    }

    final text = readColor('textColor', fallback.text);

    return AutomationStudioColors(
      background: readColor('dashboardBackground', fallback.background),
      surface: readColor('dashboardContainer', fallback.surface),
      surfaceAlt: readColor('popupcontainercolor', fallback.surfaceAlt),
      border: readColor('dashboardBoarder', fallback.border),
      primary: readColor('themeColor', fallback.primary),
      text: text,
      mutedText: text.withAlpha(165),
      success: const Color(0xFF28A745),
      danger: const Color(0xFFDC3545),
      warning: const Color(0xFFFFB020),
      shadow: Colors.black.withAlpha(32),
    );
  }
}

enum AutomationShellPresentation {
  page,
  dialog,
  embedded,
}

class AutomationPresentationScope extends InheritedWidget {
  final AutomationShellPresentation presentation;

  const AutomationPresentationScope({
    super.key,
    required this.presentation,
    required super.child,
  });

  static AutomationShellPresentation of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AutomationPresentationScope>();

    return scope?.presentation ?? AutomationShellPresentation.page;
  }

  @override
  bool updateShouldNotify(covariant AutomationPresentationScope oldWidget) {
    return presentation != oldWidget.presentation;
  }
}

class AutomationShellData {
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final String module;
  final String screenKey;
  final AutomationShellPresentation presentation;

  const AutomationShellData({
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.module = 'automation',
    required this.screenKey,
    this.presentation = AutomationShellPresentation.page,
  });
}

class AutomationStudioConfig {
  final String baseUrl;
  final AutomationTokenProvider? tokenProvider;
  final AutomationTranslate? translate;
  final AutomationRouteOpener? routeOpener;

  /// If null, Automation Studio falls back to a regular Scaffold.
  /// Set this to your module, e.g. AppModule.automation or AppModule.crm,
  /// to render screens directly inside BarManager.
  final AppModule? appModule;

  final Map<String, String> defaultHeaders;
  final bool useTokenAuthHeader;
  final String tokenHeaderPrefix;

  final bool enableScroll;
  final bool isTopAppBarOff;
  final double paddingPc;
  final double paddingTablet;
  final double paddingMobile;

  const AutomationStudioConfig({
    required this.baseUrl,
    this.tokenProvider,
    this.translate,
    this.routeOpener,
    this.appModule,
    this.defaultHeaders = const {'X-API': '1'},
    this.useTokenAuthHeader = true,
    this.tokenHeaderPrefix = 'Token',
    this.enableScroll = false,
    this.isTopAppBarOff = false,
    this.paddingPc = 0,
    this.paddingTablet = 0,
    this.paddingMobile = 0,
  });

  AutomationStudioConfig copyWith({
    String? baseUrl,
    AutomationTokenProvider? tokenProvider,
    AutomationTranslate? translate,
    AutomationRouteOpener? routeOpener,
    AppModule? appModule,
    Map<String, String>? defaultHeaders,
    bool? useTokenAuthHeader,
    String? tokenHeaderPrefix,
    bool? enableScroll,
    bool? isTopAppBarOff,
    double? paddingPc,
    double? paddingTablet,
    double? paddingMobile,
  }) {
    return AutomationStudioConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      tokenProvider: tokenProvider ?? this.tokenProvider,
      translate: translate ?? this.translate,
      routeOpener: routeOpener ?? this.routeOpener,
      appModule: appModule ?? this.appModule,
      defaultHeaders: defaultHeaders ?? this.defaultHeaders,
      useTokenAuthHeader: useTokenAuthHeader ?? this.useTokenAuthHeader,
      tokenHeaderPrefix: tokenHeaderPrefix ?? this.tokenHeaderPrefix,
      enableScroll: enableScroll ?? this.enableScroll,
      isTopAppBarOff: isTopAppBarOff ?? this.isTopAppBarOff,
      paddingPc: paddingPc ?? this.paddingPc,
      paddingTablet: paddingTablet ?? this.paddingTablet,
      paddingMobile: paddingMobile ?? this.paddingMobile,
    );
  }

  String t(BuildContext context, String key) {
    return translate?.call(context, key) ?? key.tr;
  }
}

class AutomationStudioDefaults {
  const AutomationStudioDefaults._();

  static const AutomationStudioConfig defaultConfig = AutomationStudioConfig(
    baseUrl: '',
    appModule: AppModule.automation,
    defaultHeaders: {'X-API': '1'},
    useTokenAuthHeader: true,
    tokenHeaderPrefix: 'Token',
    enableScroll: false,
    isTopAppBarOff: false,
    paddingPc: 0,
    paddingTablet: 0,
    paddingMobile: 0,
  );
}

class AutomationStudioConfigScope extends InheritedWidget {
  final AutomationStudioConfig config;

  const AutomationStudioConfigScope({
    super.key,
    required this.config,
    required super.child,
  });

  static AutomationStudioConfig? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AutomationStudioConfigScope>()
        ?.config;
  }

  static AutomationStudioConfig of(BuildContext context) {
    return maybeOf(context) ?? AutomationStudioDefaults.defaultConfig;
  }

  @override
  bool updateShouldNotify(covariant AutomationStudioConfigScope oldWidget) {
    return config != oldWidget.config;
  }
}

Widget automationShell(
  BuildContext context, {
  required WidgetRef ref,
  required String title,
  String? subtitle,
  required String screenKey,
  required Widget child,
  List<Widget> actions = const [],
  AutomationShellPresentation? presentation,
}) {
  final config = AutomationStudioConfigScope.of(context);
  final resolvedPresentation =
      presentation ?? AutomationPresentationScope.of(context);

  final data = AutomationShellData(
    title: title,
    subtitle: subtitle,
    screenKey: screenKey,
    actions: actions,
    presentation: resolvedPresentation,
  );

  if (resolvedPresentation != AutomationShellPresentation.page) {
    return child;
  }

  final appModule = config.appModule;

  if (appModule == null) {
    return Scaffold(
      appBar: config.isTopAppBarOff
          ? null
          : AppBar(
              title: Text(config.t(context, title)),
              actions: actions,
            ),
      body: child,
    );
  }

  return _AutomationBarManagerScreenShell(
    data: data,
    appModule: appModule,
    config: config,
    child: child,
  );
}

class _AutomationBarManagerScreenShell extends ConsumerStatefulWidget {
  const _AutomationBarManagerScreenShell({
    required this.data,
    required this.appModule,
    required this.config,
    required this.child,
  });

  final AutomationShellData data;
  final AppModule appModule;
  final AutomationStudioConfig config;
  final Widget child;

  @override
  ConsumerState<_AutomationBarManagerScreenShell> createState() =>
      _AutomationBarManagerScreenShellState();
}

class _AutomationBarManagerScreenShellState
    extends ConsumerState<_AutomationBarManagerScreenShell> {
  final GlobalKey<SideMenuState> _sideMenuKey = GlobalKey<SideMenuState>();

  @override
  Widget build(BuildContext context) {
    return BarManager(
      sideMenuKey: _sideMenuKey,
      appModule: widget.appModule,
      isChildExpanded: true,
      enableScrool: widget.config.enableScroll,
      // isTopAppBarOff: widget.config.isTopAppBarOff,
      isTopAppBarOff: true,
      isBottomBarOff: true,
      isTopAppBarOffMobile: false,
      layoutTypePc: LayoutTypePc.stack,
      layoutTypeTablet: LayoutTypeTablet.stack,
      layoutTypeMobile: LayoutTypeMobile.stack,
      paddingPc: widget.config.paddingPc,
      paddingTablet: widget.config.paddingTablet,
      paddingMobile: widget.config.paddingMobile,
      childPc: widget.child,
      childTablet: widget.child,
      childMobile: Builder(
        builder: (context) {
          final topPadding = TopAppBarSize.resolve(context);
          return Column(
            children: [
              SizedBox(height: topPadding),
              Expanded(child: widget.child),
            ],
          );
        },
      ),
      specialAppBar: widget.config.isTopAppBarOff
          ? null
          : _AutomationTopBar(data: widget.data, sideMenuKey: _sideMenuKey),
    );
  }
}

class _AutomationTopBar extends ConsumerWidget {
  const _AutomationTopBar({
    required this.data,
    required this.sideMenuKey,
  });

  final AutomationShellData data;
  final GlobalKey<SideMenuState> sideMenuKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    final title = automationT(context, data.title);
    final subtitle =
        data.subtitle == null ? null : automationT(context, data.subtitle!);

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        border: Border(
          bottom: BorderSide(color: theme.dashboardBoarder),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => SideMenuManager.toggleMenu(
              ref: ref,
              menuKey: sideMenuKey,
            ),
            icon: Icon(Icons.menu, color: theme.textColor),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.account_tree_rounded,
            color: theme.themeColor,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                if (subtitle != null && subtitle.trim().isNotEmpty)
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.textColor.withAlpha(170),
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          ...data.actions,
        ],
      ),
    );
  }
}

String automationT(BuildContext context, String key) {
  return AutomationStudioConfigScope.of(context).t(context, key);
}

AutomationStudioColors automationColors(BuildContext context, [WidgetRef? ref]) {
  if (ref != null) {
    final theme = ref.read(themeColorsProvider);
    return AutomationStudioColors.fromThemeColors(context, theme);
  }

  return AutomationStudioColors.fromMaterialTheme(context);
}