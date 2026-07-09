// Dashboard widget specs for modules that don't yet have their own AppModule
// (cloud, tms_app, emma). Once those modules gain AppModule support they can
// self-register via registerDashboardWidgetSpecs() in their own init().
//
// mail — already has MailModule but cross-registering here avoids a circular
// dependency (crm → mail already exists through other paths).
import 'package:cloud/dashboard/cloud_shortcut_picker.dart';
import 'package:cloud/dashboard/cloud_widget.dart';
import 'package:cloud/dashboard/shortcut_widget.dart';
import 'package:crm/dynamic_dashboard/models/dashboard_models.dart';
import 'package:crm/dynamic_dashboard/providers/dashboard_layout_provider.dart';
import 'package:crm/dynamic_dashboard/registry/dashboard_widget_spec.dart';
import 'package:emma/dashboard/emma_suggestions_widget.dart';
import 'package:mail/dashboard/mail_widget.dart';
import 'package:tms_app/dashboard/tms_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

List<DashboardWidgetSpec> crossModuleDashboardSpecs() => const [
      MailDashboardWidgetSpec(),
      TmsDashboardWidgetSpec(),
      CloudRecentWidgetSpec(),
      CloudShortcutWidgetSpec(),
      EmmaSuggestionsWidgetSpec(),
    ];

// ---------------------------------------------------------------------------
// Mail
// ---------------------------------------------------------------------------

class MailDashboardWidgetSpec extends DashboardWidgetSpec {
  const MailDashboardWidgetSpec();

  @override
  String get type => 'mail';

  @override
  String get title => 'Mail';

  @override
  IconData get icon => Icons.mail_outline_rounded;

  @override
  bool get allowMultiple => true;

  @override
  DashboardGridSize defaultSize(DashboardBreakpoint breakpoint) =>
      switch (breakpoint) {
        DashboardBreakpoint.desktop => const DashboardGridSize(w: 4, h: 5),
        DashboardBreakpoint.tablet  => const DashboardGridSize(w: 4, h: 5),
        DashboardBreakpoint.mobile  => const DashboardGridSize(w: 4, h: 5),
      };

  @override
  DashboardWidgetConstraints get constraints => const DashboardWidgetConstraints(
        minW: 2, maxW: 12, minH: 3, maxH: 10,
      );

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
    DashboardWidgetInstance instance,
    DashboardBreakpoint breakpoint,
    bool isEditMode,
  ) =>
      DashboardMailWidget(
        isMobile: breakpoint == DashboardBreakpoint.mobile,
        settings: instance.settings,
      );
}

// ---------------------------------------------------------------------------
// TMS Tasks
// ---------------------------------------------------------------------------

class TmsDashboardWidgetSpec extends DashboardWidgetSpec {
  const TmsDashboardWidgetSpec();

  @override
  String get type => 'tms_tasks';

  @override
  String get title => 'TMS Tasks';

  @override
  IconData get icon => Icons.fact_check_outlined;

  @override
  bool get allowMultiple => true;

  @override
  DashboardGridSize defaultSize(DashboardBreakpoint breakpoint) =>
      switch (breakpoint) {
        DashboardBreakpoint.desktop => const DashboardGridSize(w: 4, h: 5),
        DashboardBreakpoint.tablet  => const DashboardGridSize(w: 4, h: 5),
        DashboardBreakpoint.mobile  => const DashboardGridSize(w: 4, h: 5),
      };

  @override
  DashboardWidgetConstraints get constraints => const DashboardWidgetConstraints(
        minW: 2, maxW: 12, minH: 3, maxH: 10,
      );

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
    DashboardWidgetInstance instance,
    DashboardBreakpoint breakpoint,
    bool isEditMode,
  ) =>
      DashboardTmsWidget(
        isMobile: breakpoint == DashboardBreakpoint.mobile,
        settings: instance.settings,
      );
}

// ---------------------------------------------------------------------------
// Cloud Recent Files
// ---------------------------------------------------------------------------

class CloudRecentWidgetSpec extends DashboardWidgetSpec {
  const CloudRecentWidgetSpec();

  @override
  String get type => 'cloud_recent';

  @override
  String get title => 'Recent Files & Folders';

  @override
  IconData get icon => Icons.cloud_outlined;

  @override
  bool get allowMultiple => true;

  @override
  DashboardGridSize defaultSize(DashboardBreakpoint breakpoint) =>
      switch (breakpoint) {
        DashboardBreakpoint.desktop => const DashboardGridSize(w: 4, h: 5),
        DashboardBreakpoint.tablet  => const DashboardGridSize(w: 4, h: 5),
        DashboardBreakpoint.mobile  => const DashboardGridSize(w: 4, h: 5),
      };

  @override
  DashboardWidgetConstraints get constraints => const DashboardWidgetConstraints(
        minW: 2, maxW: 12, minH: 3, maxH: 10,
      );

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
    DashboardWidgetInstance instance,
    DashboardBreakpoint breakpoint,
    bool isEditMode,
  ) =>
      DashboardCloudRecentWidget(
        isMobile: breakpoint == DashboardBreakpoint.mobile,
        isEditMode: isEditMode,
        settings: instance.settings,
      );
}

// ---------------------------------------------------------------------------
// Cloud Shortcut
// ---------------------------------------------------------------------------

class CloudShortcutWidgetSpec extends DashboardWidgetSpec {
  const CloudShortcutWidgetSpec();

  @override
  String get type => 'cloud_shortcut';

  @override
  String get title => 'Cloud Shortcut';

  @override
  IconData get icon => Icons.push_pin_outlined;

  @override
  bool get allowMultiple => true;

  @override
  bool get needsFirstSetup => true;

  @override
  Future<Map<String, dynamic>?> runFirstSetup(
    BuildContext context,
    WidgetRef ref,
    String instanceId,
    String dashboardKey,
    String zoneKey,
  ) =>
      showCloudShortcutPicker(
        context: context,
        ref: ref,
        dashboardKey: dashboardKey,
        zoneKey: zoneKey,
      );

  @override
  DashboardGridSize defaultSize(DashboardBreakpoint breakpoint) =>
      switch (breakpoint) {
        DashboardBreakpoint.desktop => const DashboardGridSize(w: 1, h: 1),
        DashboardBreakpoint.tablet  => const DashboardGridSize(w: 1, h: 1),
        DashboardBreakpoint.mobile  => const DashboardGridSize(w: 2, h: 1),
      };

  @override
  DashboardWidgetConstraints get constraints => const DashboardWidgetConstraints(
        minW: 1, maxW: 2, minH: 1, maxH: 2,
      );

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
    DashboardWidgetInstance instance,
    DashboardBreakpoint breakpoint,
    bool isEditMode,
  ) =>
      buildWithDashboardKey(context, ref, instance, breakpoint, isEditMode, '');

  @override
  Widget buildWithDashboardKey(
    BuildContext context,
    WidgetRef ref,
    DashboardWidgetInstance instance,
    DashboardBreakpoint breakpoint,
    bool isEditMode,
    String dashboardKey,
  ) =>
      DashboardCloudShortcutWidget(
        isMobile: breakpoint == DashboardBreakpoint.mobile,
        settings: instance.settings,
        isEditMode: isEditMode,
        onReconfigure: dashboardKey.isNotEmpty
            ? (ctx, r) async {
                final newSettings = await showCloudShortcutPicker(
                  context: ctx,
                  ref: r,
                  dashboardKey: dashboardKey,
                  zoneKey: instance.zoneKey,
                );
                if (newSettings != null) {
                  r.read(dashboardLayoutProvider(dashboardKey).notifier)
                      .updateWidgetSettings(
                    instanceId: instance.id,
                    settings: newSettings,
                  );
                }
              }
            : null,
      );
}

// ---------------------------------------------------------------------------
// Emma Suggestions
// ---------------------------------------------------------------------------

class EmmaSuggestionsWidgetSpec extends DashboardWidgetSpec {
  const EmmaSuggestionsWidgetSpec();

  @override
  String get type => 'emma_suggestions';

  @override
  String get title => 'Emma Suggestions';

  @override
  IconData get icon => Icons.auto_awesome_rounded;

  @override
  DashboardGridSize defaultSize(DashboardBreakpoint breakpoint) =>
      switch (breakpoint) {
        DashboardBreakpoint.desktop => const DashboardGridSize(w: 4, h: 5),
        DashboardBreakpoint.tablet  => const DashboardGridSize(w: 4, h: 5),
        DashboardBreakpoint.mobile  => const DashboardGridSize(w: 4, h: 5),
      };

  @override
  DashboardWidgetConstraints get constraints => const DashboardWidgetConstraints(
        minW: 2, maxW: 12, minH: 3, maxH: 10,
      );

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
    DashboardWidgetInstance instance,
    DashboardBreakpoint breakpoint,
    bool isEditMode,
  ) =>
      EmmaSuggestionsDashboardWidget(
        isMobile: breakpoint == DashboardBreakpoint.mobile,
        isEditMode: isEditMode,
      );
}
