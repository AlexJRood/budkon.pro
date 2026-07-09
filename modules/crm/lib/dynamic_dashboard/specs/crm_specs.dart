import 'package:crm/dynamic_dashboard/models/dashboard_models.dart';
import 'package:crm/dynamic_dashboard/registry/dashboard_widget_spec.dart';
import 'package:crm/dynamic_dashboard/widgets/dashboard_widget_settings_panels.dart';
import 'package:core/theme/apptheme.dart';
import 'package:crm/dynamic_dashboard/widgets/company_members_dashboard_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

List<DashboardWidgetSpec> crmDashboardSpecs() => const [
      WelcomeHeaderWidgetSpec(),
      CompanyMembersWidgetSpec(),
    ];

// ---------------------------------------------------------------------------
// Welcome Header
// ---------------------------------------------------------------------------

class WelcomeHeaderWidgetSpec extends DashboardWidgetSpec {
  const WelcomeHeaderWidgetSpec();

  @override
  String get type => 'welcome_header';

  @override
  String get title => 'Welcome Header';

  @override
  IconData get icon => Icons.waving_hand_rounded;

  @override
  bool get hasSettings => true;

  @override
  DashboardGridSize defaultSize(DashboardBreakpoint breakpoint) =>
      switch (breakpoint) {
        DashboardBreakpoint.desktop => const DashboardGridSize(w: 12, h: 1),
        DashboardBreakpoint.tablet  => const DashboardGridSize(w: 8, h: 1),
        DashboardBreakpoint.mobile  => const DashboardGridSize(w: 4, h: 1),
      };

  @override
  DashboardWidgetConstraints get constraints => const DashboardWidgetConstraints(
        minW: 2, maxW: 12, minH: 1, maxH: 2,
      );

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
    DashboardWidgetInstance instance,
    DashboardBreakpoint breakpoint,
    bool isEditMode,
  ) {
    final theme = ref.watch(themeColorsProvider);
    final settings = instance.settings;
    final showSubtitle = settings['showSubtitle'] is bool
        ? settings['showSubtitle'] as bool
        : true;

    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            instance.titleOverride ?? 'Hi, Welcome back!'.tr,
            style: TextStyle(
              fontFamily: 'LibreCaslonText',
              fontWeight: FontWeight.w400,
              fontSize: breakpoint == DashboardBreakpoint.mobile ? 20.sp : 24,
              color: theme.textColor,
            ),
          ),
          if (showSubtitle) ...[
            const SizedBox(height: 4),
            Text(
              'Real Estate Property Management Dashboard.'.tr,
              style: TextStyle(
                color: theme.textColor.withAlpha((255 * 0.75).toInt()),
                fontSize: breakpoint == DashboardBreakpoint.mobile ? 12.sp : 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget buildSettingsPanel(
    BuildContext context,
    WidgetRef ref,
    DashboardWidgetInstance instance,
    ValueChanged<Map<String, dynamic>> onSettingsChanged,
  ) =>
      WelcomeHeaderSettingsPanel(
        settings: instance.settings,
        onSettingsChanged: onSettingsChanged,
      );
}

// ---------------------------------------------------------------------------
// Company Members
// ---------------------------------------------------------------------------

class CompanyMembersWidgetSpec extends DashboardWidgetSpec {
  const CompanyMembersWidgetSpec();

  @override
  String get type => 'company_members';

  @override
  String get title => 'Company Members';

  @override
  IconData get icon => Icons.groups_2_rounded;

  @override
  bool get allowMultiple => true;

  @override
  bool get hasSettings => true;

  @override
  DashboardGridSize defaultSize(DashboardBreakpoint breakpoint) =>
      switch (breakpoint) {
        DashboardBreakpoint.desktop => const DashboardGridSize(w: 4, h: 3),
        DashboardBreakpoint.tablet  => const DashboardGridSize(w: 4, h: 3),
        DashboardBreakpoint.mobile  => const DashboardGridSize(w: 4, h: 2),
      };

  @override
  DashboardWidgetConstraints get constraints => const DashboardWidgetConstraints(
        minW: 1, maxW: 12, minH: 1, maxH: 8,
      );

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
    DashboardWidgetInstance instance,
    DashboardBreakpoint breakpoint,
    bool isEditMode,
  ) {
    final s = instance.settings;
    return DashboardCompanyMembersWidget(
      isMobile: breakpoint == DashboardBreakpoint.mobile,
      compact: s['compact'] is bool ? s['compact'] as bool : false,
      backgroundMode: (s['backgroundMode'] ?? 'card').toString(),
      itemStyle: (s['itemStyle'] ?? 'card').toString(),
      showHeader: s['showHeader'] is bool ? s['showHeader'] as bool : true,
      isEditMode: isEditMode,
    );
  }

  @override
  Widget buildSettingsPanel(
    BuildContext context,
    WidgetRef ref,
    DashboardWidgetInstance instance,
    ValueChanged<Map<String, dynamic>> onSettingsChanged,
  ) =>
      CompanyMembersSettingsPanel(
        settings: instance.settings,
        onSettingsChanged: onSettingsChanged,
      );
}
