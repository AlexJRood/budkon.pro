import 'package:crm/dynamic_dashboard/models/dashboard_models.dart';
import 'package:crm/dynamic_dashboard/models/screenshot_spec.dart';
import 'package:crm/dynamic_dashboard/registry/dashboard_widget_spec.dart';
import 'package:crm/dynamic_dashboard/widgets/dashboard_widget_settings_panels.dart';
import 'package:crm_agent/crm/components/transactions_slider.dart';
import 'package:crm_agent/crm/new_dashboard/widget/dashboard_daily_market_overview_widget.dart';
import 'package:crm_agent/crm/new_dashboard/widget/dashboard_last_mount_view_widget.dart';
import 'package:crm_agent/crm/new_dashboard/widget/db_calendar_widget.dart';
import 'package:crm_agent/crm/new_dashboard/widget/db_earning_chart_widget.dart';
import 'package:crm_agent/crm/new_dashboard/widget/db_favorite_ad_widget.dart';
import 'package:crm_agent/crm/new_dashboard/widget/db_recent_leads_and_chart_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

List<DashboardWidgetSpec> crmAgentDashboardSpecs() => const [
      MarketOverviewWidgetSpec(),
      LastMonthStatsWidgetSpec(),
      CalendarWidgetSpec(),
      RecentLeadsWidgetSpec(),
      FavoriteAdsWidgetSpec(),
      FinancialWidgetSpec(),
      EarningsChartWidgetSpec(),
    ];

// ---------------------------------------------------------------------------
// Market Overview
// ---------------------------------------------------------------------------

class MarketOverviewWidgetSpec extends DashboardWidgetSpec {
  const MarketOverviewWidgetSpec();

  @override
  String get type => 'market_overview';

  @override
  String get title => 'Daily Market Overview';

  @override
  IconData get icon => Icons.auto_graph_rounded;

  @override
  DashboardGridSize defaultSize(DashboardBreakpoint breakpoint) =>
      switch (breakpoint) {
        DashboardBreakpoint.desktop => const DashboardGridSize(w: 12, h: 2),
        DashboardBreakpoint.tablet  => const DashboardGridSize(w: 8, h: 2),
        DashboardBreakpoint.mobile  => const DashboardGridSize(w: 4, h: 3),
      };

  @override
  DashboardWidgetConstraints get constraints => const DashboardWidgetConstraints(
        minW: 3, maxW: 12, minH: 2, maxH: 5,
      );

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
    DashboardWidgetInstance instance,
    DashboardBreakpoint breakpoint,
    bool isEditMode,
  ) =>
      const DashboardDailyMarketOverviewWidget();
}

// ---------------------------------------------------------------------------
// Last Month Stats
// ---------------------------------------------------------------------------

class LastMonthStatsWidgetSpec extends DashboardWidgetSpec {
  const LastMonthStatsWidgetSpec();

  @override
  String get type => 'last_month_stats';

  @override
  String get title => 'Last Month Stats';

  @override
  IconData get icon => Icons.bar_chart_rounded;

  @override
  DashboardGridSize defaultSize(DashboardBreakpoint breakpoint) =>
      switch (breakpoint) {
        DashboardBreakpoint.desktop => const DashboardGridSize(w: 3, h: 2),
        DashboardBreakpoint.tablet  => const DashboardGridSize(w: 3, h: 2),
        DashboardBreakpoint.mobile  => const DashboardGridSize(w: 4, h: 3),
      };

  @override
  DashboardWidgetConstraints get constraints => const DashboardWidgetConstraints(
        minW: 2, maxW: 8, minH: 1, maxH: 4,
      );

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
    DashboardWidgetInstance instance,
    DashboardBreakpoint breakpoint,
    bool isEditMode,
  ) =>
      DashboardLastMountViewWidget(
        isMobile: breakpoint == DashboardBreakpoint.mobile,
        isTablet: breakpoint == DashboardBreakpoint.tablet,
      );
}

// ---------------------------------------------------------------------------
// Calendar
// ---------------------------------------------------------------------------

class CalendarWidgetSpec extends DashboardWidgetSpec {
  const CalendarWidgetSpec();

  @override
  String get type => 'calendar';

  @override
  String get title => 'Calendar';

  @override
  IconData get icon => Icons.calendar_month_rounded;

  @override
  DashboardGridSize defaultSize(DashboardBreakpoint breakpoint) =>
      switch (breakpoint) {
        DashboardBreakpoint.desktop => const DashboardGridSize(w: 4, h: 7),
        DashboardBreakpoint.tablet  => const DashboardGridSize(w: 4, h: 6),
        DashboardBreakpoint.mobile  => const DashboardGridSize(w: 4, h: 5),
      };

  @override
  DashboardWidgetConstraints get constraints => const DashboardWidgetConstraints(
        minW: 2, maxW: 8, minH: 3, maxH: 12,
      );

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
    DashboardWidgetInstance instance,
    DashboardBreakpoint breakpoint,
    bool isEditMode,
  ) =>
      ClipRect(
        child: DbCalendarWidget(
          isMobile: breakpoint == DashboardBreakpoint.mobile,
        ),
      );
}

// ---------------------------------------------------------------------------
// Recent Leads
// ---------------------------------------------------------------------------

class RecentLeadsWidgetSpec extends DashboardWidgetSpec {
  const RecentLeadsWidgetSpec();

  @override
  String get type => 'recent_leads';

  @override
  String get title => 'Recent Leads';

  @override
  IconData get icon => Icons.groups_rounded;

  @override
  bool get allowMultiple => true;

  @override
  bool get hasSettings => true;

  @override
  List<WidgetScreenshotSpec> get screenshotSpecs => const [
        WidgetScreenshotSpec(
          key: 'dark_desktop_card',
          label: 'Dark · Desktop – Cards',
          themeMode: ThemeMode.light,
          breakpoint: DashboardBreakpoint.desktop,
          settings: {'itemStyle': 'card', 'backgroundMode': 'card', 'showHeader': true, 'compact': false},
        ),
        WidgetScreenshotSpec(
          key: 'dark_desktop_list',
          label: 'Dark · Desktop – List',
          themeMode: ThemeMode.light,
          breakpoint: DashboardBreakpoint.desktop,
          settings: {'itemStyle': 'list', 'backgroundMode': 'card', 'showHeader': true, 'compact': false},
        ),
        WidgetScreenshotSpec(
          key: 'light_desktop_card',
          label: 'Light · Desktop – Cards',
          themeMode: ThemeMode.system,
          breakpoint: DashboardBreakpoint.desktop,
          settings: {'itemStyle': 'card', 'backgroundMode': 'card', 'showHeader': true, 'compact': false},
        ),
        WidgetScreenshotSpec(
          key: 'light_desktop_list',
          label: 'Light · Desktop – List',
          themeMode: ThemeMode.system,
          breakpoint: DashboardBreakpoint.desktop,
          settings: {'itemStyle': 'list', 'backgroundMode': 'card', 'showHeader': true, 'compact': false},
        ),
        WidgetScreenshotSpec(
          key: 'dark_mobile',
          label: 'Dark · Mobile',
          themeMode: ThemeMode.light,
          breakpoint: DashboardBreakpoint.mobile,
          settings: {'itemStyle': 'card', 'compact': true, 'showHeader': true},
        ),
        WidgetScreenshotSpec(
          key: 'light_mobile',
          label: 'Light · Mobile',
          themeMode: ThemeMode.system,
          breakpoint: DashboardBreakpoint.mobile,
          settings: {'itemStyle': 'card', 'compact': true, 'showHeader': true},
        ),
      ];

  @override
  DashboardGridSize defaultSize(DashboardBreakpoint breakpoint) =>
      switch (breakpoint) {
        DashboardBreakpoint.desktop => const DashboardGridSize(w: 4, h: 4),
        DashboardBreakpoint.tablet  => const DashboardGridSize(w: 4, h: 4),
        DashboardBreakpoint.mobile  => const DashboardGridSize(w: 4, h: 4),
      };

  @override
  DashboardWidgetConstraints get constraints => const DashboardWidgetConstraints(
        minW: 1, maxW: 12, minH: 1, maxH: 10,
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
    return DbRecentLeadsWidget(
      isMobile: breakpoint == DashboardBreakpoint.mobile,
      backgroundMode: (s['backgroundMode'] ?? 'card').toString(),
      showHeader: s['showHeader'] is bool ? s['showHeader'] as bool : true,
      itemStyle: (s['itemStyle'] ?? 'card').toString(),
      compact: s['compact'] is bool ? s['compact'] as bool : false,
    );
  }

  @override
  Widget buildSettingsPanel(
    BuildContext context,
    WidgetRef ref,
    DashboardWidgetInstance instance,
    ValueChanged<Map<String, dynamic>> onSettingsChanged,
  ) =>
      RecentLeadsSettingsPanel(
        settings: instance.settings,
        onSettingsChanged: onSettingsChanged,
      );
}

// ---------------------------------------------------------------------------
// Favorite Ads
// ---------------------------------------------------------------------------

class FavoriteAdsWidgetSpec extends DashboardWidgetSpec {
  const FavoriteAdsWidgetSpec();

  @override
  String get type => 'favorite_ads';

  @override
  String get title => 'Favorite Ads';

  @override
  IconData get icon => Icons.favorite_rounded;

  @override
  DashboardGridSize defaultSize(DashboardBreakpoint breakpoint) =>
      switch (breakpoint) {
        DashboardBreakpoint.desktop => const DashboardGridSize(w: 4, h: 4),
        DashboardBreakpoint.tablet  => const DashboardGridSize(w: 4, h: 4),
        DashboardBreakpoint.mobile  => const DashboardGridSize(w: 4, h: 4),
      };

  @override
  DashboardWidgetConstraints get constraints => const DashboardWidgetConstraints(
        minW: 2, maxW: 8, minH: 2, maxH: 7,
      );

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
    DashboardWidgetInstance instance,
    DashboardBreakpoint breakpoint,
    bool isEditMode,
  ) =>
      DbFavoriteAdWidget(isMobile: breakpoint == DashboardBreakpoint.mobile);
}

// ---------------------------------------------------------------------------
// Financial
// ---------------------------------------------------------------------------

class FinancialWidgetSpec extends DashboardWidgetSpec {
  const FinancialWidgetSpec();

  @override
  String get type => 'financial';

  @override
  String get title => 'Financial';

  @override
  IconData get icon => Icons.payments_rounded;

  @override
  bool get hasSettings => true;

  @override
  List<WidgetScreenshotSpec> get screenshotSpecs => const [
        WidgetScreenshotSpec(
          key: 'dark_desktop_horizontal',
          label: 'Dark · Desktop – Horizontal',
          themeMode: ThemeMode.light,
          breakpoint: DashboardBreakpoint.desktop,
          settings: {'vertical': false, 'alignRight': false, 'isExpanded': false},
        ),
        WidgetScreenshotSpec(
          key: 'dark_desktop_vertical',
          label: 'Dark · Desktop – Vertical',
          themeMode: ThemeMode.light,
          breakpoint: DashboardBreakpoint.desktop,
          settings: {'vertical': true, 'alignRight': false, 'isExpanded': false},
        ),
        WidgetScreenshotSpec(
          key: 'light_desktop_horizontal',
          label: 'Light · Desktop – Horizontal',
          themeMode: ThemeMode.system,
          breakpoint: DashboardBreakpoint.desktop,
          settings: {'vertical': false, 'alignRight': false, 'isExpanded': false},
        ),
        WidgetScreenshotSpec(
          key: 'light_desktop_vertical',
          label: 'Light · Desktop – Vertical',
          themeMode: ThemeMode.system,
          breakpoint: DashboardBreakpoint.desktop,
          settings: {'vertical': true, 'alignRight': false, 'isExpanded': false},
        ),
        WidgetScreenshotSpec(
          key: 'dark_mobile',
          label: 'Dark · Mobile',
          themeMode: ThemeMode.light,
          breakpoint: DashboardBreakpoint.mobile,
        ),
        WidgetScreenshotSpec(
          key: 'light_mobile',
          label: 'Light · Mobile',
          themeMode: ThemeMode.system,
          breakpoint: DashboardBreakpoint.mobile,
        ),
      ];

  @override
  DashboardGridSize defaultSize(DashboardBreakpoint breakpoint) =>
      switch (breakpoint) {
        DashboardBreakpoint.desktop => const DashboardGridSize(w: 4, h: 3),
        DashboardBreakpoint.tablet  => const DashboardGridSize(w: 4, h: 3),
        DashboardBreakpoint.mobile  => const DashboardGridSize(w: 4, h: 2),
      };

  @override
  DashboardWidgetConstraints get constraints => const DashboardWidgetConstraints(
        minW: 2, maxW: 8, minH: 1, maxH: 8,
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
    return FinancialWidget(
      isMobile: breakpoint == DashboardBreakpoint.mobile,
      alignRight: s['alignRight'] is bool ? s['alignRight'] as bool : false,
      vertical: s['vertical'] is bool ? s['vertical'] as bool : false,
      isExpanded: s['isExpanded'] is bool ? s['isExpanded'] as bool : false,
    );
  }

  @override
  Widget buildSettingsPanel(
    BuildContext context,
    WidgetRef ref,
    DashboardWidgetInstance instance,
    ValueChanged<Map<String, dynamic>> onSettingsChanged,
  ) =>
      FinancialWidgetSettingsPanel(
        settings: instance.settings,
        onSettingsChanged: onSettingsChanged,
      );
}

// ---------------------------------------------------------------------------
// Earnings Chart
// ---------------------------------------------------------------------------

class EarningsChartWidgetSpec extends DashboardWidgetSpec {
  const EarningsChartWidgetSpec();

  @override
  String get type => 'earnings_chart';

  @override
  String get title => 'Earnings Chart';

  @override
  IconData get icon => Icons.show_chart_rounded;

  @override
  DashboardGridSize defaultSize(DashboardBreakpoint breakpoint) =>
      switch (breakpoint) {
        DashboardBreakpoint.desktop => const DashboardGridSize(w: 4, h: 4),
        DashboardBreakpoint.tablet  => const DashboardGridSize(w: 4, h: 4),
        DashboardBreakpoint.mobile  => const DashboardGridSize(w: 4, h: 4),
      };

  @override
  DashboardWidgetConstraints get constraints => const DashboardWidgetConstraints(
        minW: 2, maxW: 8, minH: 2, maxH: 6,
      );

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
    DashboardWidgetInstance instance,
    DashboardBreakpoint breakpoint,
    bool isEditMode,
  ) =>
      const DbEarningChartWidget();
}
