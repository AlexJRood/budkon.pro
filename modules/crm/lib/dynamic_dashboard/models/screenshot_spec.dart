import 'package:flutter/material.dart';

import 'dashboard_models.dart';

@immutable
class WidgetScreenshotSpec {
  const WidgetScreenshotSpec({
    required this.key,
    required this.label,
    required this.themeMode,
    required this.breakpoint,
    this.settings = const {},
  });

  final String key;
  final String label;
  final ThemeMode themeMode;
  final DashboardBreakpoint breakpoint;
  final Map<String, dynamic> settings;

  // ThemeMode.system = light UI; ThemeMode.light = dark UI (naming is inverted in this app).
  bool get isLightUi => themeMode == ThemeMode.system;
  Color get bgColor => isLightUi ? const Color(0xFFFFFFFF) : const Color(0xFF212020);
  double get renderWidth =>
      breakpoint == DashboardBreakpoint.desktop ? 640.0 : 360.0;
}

/// The four canonical variants every widget gets unless it overrides [screenshotSpecs].
const kDefaultScreenshotSpecs = <WidgetScreenshotSpec>[
  WidgetScreenshotSpec(
    key: 'light_desktop',
    label: 'Light · Desktop',
    themeMode: ThemeMode.system,
    breakpoint: DashboardBreakpoint.desktop,
  ),
  WidgetScreenshotSpec(
    key: 'dark_desktop',
    label: 'Dark · Desktop',
    themeMode: ThemeMode.light,
    breakpoint: DashboardBreakpoint.desktop,
  ),
  WidgetScreenshotSpec(
    key: 'light_mobile',
    label: 'Light · Mobile',
    themeMode: ThemeMode.system,
    breakpoint: DashboardBreakpoint.mobile,
  ),
  WidgetScreenshotSpec(
    key: 'dark_mobile',
    label: 'Dark · Mobile',
    themeMode: ThemeMode.light,
    breakpoint: DashboardBreakpoint.mobile,
  ),
];
