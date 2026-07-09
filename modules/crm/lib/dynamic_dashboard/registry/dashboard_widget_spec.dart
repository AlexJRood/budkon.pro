export 'package:crm/dynamic_dashboard/models/dashboard_models.dart';

import 'package:crm/dynamic_dashboard/models/dashboard_models.dart';
import 'package:crm/dynamic_dashboard/models/screenshot_spec.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef DashboardWidgetBuilder = Widget Function(
  BuildContext context,
  WidgetRef ref,
  DashboardWidgetInstance instance,
  DashboardBreakpoint breakpoint,
  bool isEditMode,
);

abstract class DashboardWidgetSpec {
  const DashboardWidgetSpec();

  String get type;
  String get title;
  IconData get icon;
  bool get allowMultiple => false;
  bool get canMove => true;
  bool get canResize => true;
  bool get hasSettings => false;

  /// If true, [runFirstSetup] is called immediately after the widget is added.
  /// Returning null cancels the add.
  bool get needsFirstSetup => false;

  Future<Map<String, dynamic>?> runFirstSetup(
    BuildContext context,
    WidgetRef ref,
    String instanceId,
    String dashboardKey,
    String zoneKey,
  ) async =>
      null;

  List<WidgetScreenshotSpec> get screenshotSpecs => kDefaultScreenshotSpecs;

  DashboardGridSize defaultSize(DashboardBreakpoint breakpoint);
  DashboardWidgetConstraints get constraints;

  Widget build(
    BuildContext context,
    WidgetRef ref,
    DashboardWidgetInstance instance,
    DashboardBreakpoint breakpoint,
    bool isEditMode,
  );

  /// Override to receive [dashboardKey] — used by specs that update their own
  /// settings (e.g. cloud shortcut reconfiguration). Default delegates to [build].
  Widget buildWithDashboardKey(
    BuildContext context,
    WidgetRef ref,
    DashboardWidgetInstance instance,
    DashboardBreakpoint breakpoint,
    bool isEditMode,
    String dashboardKey,
  ) =>
      build(context, ref, instance, breakpoint, isEditMode);

  Widget buildSettingsPanel(
    BuildContext context,
    WidgetRef ref,
    DashboardWidgetInstance instance,
    ValueChanged<Map<String, dynamic>> onSettingsChanged,
  ) =>
      const SizedBox.shrink();
}

class DashboardWidgetRegistry {
  final Map<String, DashboardWidgetSpec> _map;

  DashboardWidgetRegistry(List<DashboardWidgetSpec> specs)
      : _map = {for (final spec in specs) spec.type: spec};

  List<DashboardWidgetSpec> get all => _map.values.toList(growable: false);

  DashboardWidgetSpec? byType(String type) => _map[type];
}
