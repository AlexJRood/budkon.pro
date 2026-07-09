import 'package:core/ui/anchors/anchor_spec.dart';

class EmmaAnchors {

static const reportsDashboardAllRoot = EmmaUiAnchorSpec(
  anchorKey: 'reports.dashboard.all.root',
  frontendRef: 'EmmaAnchors.reportsDashboardAllRoot',
  label: 'Reports dashboard root',
  description:
      'Responsive reports dashboard wrapper rendered inside BarManager with desktop and mobile layouts.',
  module: 'reports',
  screenKey: 'reports_dashboard_all',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.section,
  runtimeMode: EmmaUiAnchorRuntimeMode.always,
  tapMode: EmmaUiAnchorTapMode.disabled,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['reports', 'dashboard', 'root', 'responsive'],
);

static const reportsDashboardPcRoot = EmmaUiAnchorSpec(
  anchorKey: 'reports.dashboard.pc.root',
  frontendRef: 'EmmaAnchors.reportsDashboardPcRoot',
  label: 'Reports dashboard desktop',
  description: 'Desktop reports dashboard with recent reports, charts and market statistics.',
  module: 'reports',
  screenKey: 'reports_dashboard_pc',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.section,
  runtimeMode: EmmaUiAnchorRuntimeMode.always,
  tapMode: EmmaUiAnchorTapMode.disabled,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['reports', 'dashboard', 'desktop'],
);

static const reportsDashboardPcHeader = EmmaUiAnchorSpec(
  anchorKey: 'reports.dashboard.pc.header',
  frontendRef: 'EmmaAnchors.reportsDashboardPcHeader',
  label: 'Reports dashboard header',
  description: 'Header area with dashboard title and market snapshot description.',
  module: 'reports',
  screenKey: 'reports_dashboard_pc',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.section,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.disabled,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['reports', 'dashboard', 'header', 'title'],
);

static const reportsDashboardPcRecentReportsSection = EmmaUiAnchorSpec(
  anchorKey: 'reports.dashboard.pc.recent_reports_section',
  frontendRef: 'EmmaAnchors.reportsDashboardPcRecentReportsSection',
  label: 'Recent reports section',
  description: 'Desktop section with recent property reports and quick report actions.',
  module: 'reports',
  screenKey: 'reports_dashboard_pc',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.section,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.disabled,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['reports', 'recent', 'property_reports', 'section'],
);

static const reportsDashboardPcRefreshButton = EmmaUiAnchorSpec(
  anchorKey: 'reports.dashboard.pc.refresh_button',
  frontendRef: 'EmmaAnchors.reportsDashboardPcRefreshButton',
  label: 'Refresh reports button',
  description: 'Button refreshing dashboard report data.',
  module: 'reports',
  screenKey: 'reports_dashboard_pc',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.button,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['reports', 'refresh', 'button'],
  meta: {'action': 'refresh_dashboard_reports'},
);

static const reportsDashboardPcViewAllButton = EmmaUiAnchorSpec(
  anchorKey: 'reports.dashboard.pc.view_all_button',
  frontendRef: 'EmmaAnchors.reportsDashboardPcViewAllButton',
  label: 'View all reports button',
  description: 'Button opening the full reports list.',
  module: 'reports',
  screenKey: 'reports_dashboard_pc',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.button,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['reports', 'view_all', 'button', 'navigation'],
  meta: {'opens': 'all_reports'},
);

static const reportsDashboardPcCompareButton = EmmaUiAnchorSpec(
  anchorKey: 'reports.dashboard.pc.compare_button',
  frontendRef: 'EmmaAnchors.reportsDashboardPcCompareButton',
  label: 'Compare reports button',
  description: 'Button opening the property reports comparison dialog.',
  module: 'reports',
  screenKey: 'reports_dashboard_pc',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.button,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['reports', 'compare', 'button', 'dialog'],
  meta: {'opens': 'property_comparison_dialog'},
);

static const reportsDashboardPcPropertyList = EmmaUiAnchorSpec(
  anchorKey: 'reports.dashboard.pc.property_list',
  frontendRef: 'EmmaAnchors.reportsDashboardPcPropertyList',
  label: 'Recent property reports list',
  description: 'List of recent property reports on desktop dashboard.',
  module: 'reports',
  screenKey: 'reports_dashboard_pc',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.section,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.disabled,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['reports', 'property', 'list', 'recent'],
);

static const reportsDashboardPcPriceChart = EmmaUiAnchorSpec(
  anchorKey: 'reports.dashboard.pc.price_chart',
  frontendRef: 'EmmaAnchors.reportsDashboardPcPriceChart',
  label: 'Price chart',
  description: 'Main price line chart for report dashboard.',
  module: 'reports',
  screenKey: 'reports_dashboard_pc',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.widget,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.disabled,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['reports', 'chart', 'price', 'line_graph'],
);

static const reportsDashboardPcSalesChart = EmmaUiAnchorSpec(
  anchorKey: 'reports.dashboard.pc.sales_chart',
  frontendRef: 'EmmaAnchors.reportsDashboardPcSalesChart',
  label: 'Sales chart',
  description: 'Sales / distribution chart in reports dashboard.',
  module: 'reports',
  screenKey: 'reports_dashboard_pc',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.widget,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.disabled,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['reports', 'chart', 'sales', 'pie'],
);

static const reportsDashboardPcCategoryChart = EmmaUiAnchorSpec(
  anchorKey: 'reports.dashboard.pc.category_chart',
  frontendRef: 'EmmaAnchors.reportsDashboardPcCategoryChart',
  label: 'Report category chart',
  description: 'Chart showing report categories.',
  module: 'reports',
  screenKey: 'reports_dashboard_pc',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.widget,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.disabled,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['reports', 'chart', 'category'],
);

static const reportsDashboardPcInterestChart = EmmaUiAnchorSpec(
  anchorKey: 'reports.dashboard.pc.interest_chart',
  frontendRef: 'EmmaAnchors.reportsDashboardPcInterestChart',
  label: 'Interest levels chart',
  description: 'Chart showing user or market interest levels.',
  module: 'reports',
  screenKey: 'reports_dashboard_pc',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.widget,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.disabled,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['reports', 'chart', 'interest'],
);

static const reportsDashboardPcStats = EmmaUiAnchorSpec(
  anchorKey: 'reports.dashboard.pc.stats',
  frontendRef: 'EmmaAnchors.reportsDashboardPcStats',
  label: 'Report stats',
  description: 'Statistics summary widget for report dashboard.',
  module: 'reports',
  screenKey: 'reports_dashboard_pc',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.widget,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.disabled,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['reports', 'stats', 'summary'],
);

static const reportsDashboardMobileRoot = EmmaUiAnchorSpec(
  anchorKey: 'reports.dashboard.mobile.root',
  frontendRef: 'EmmaAnchors.reportsDashboardMobileRoot',
  label: 'Reports dashboard mobile',
  description: 'Mobile reports dashboard with recent reports, compare action and charts.',
  module: 'reports',
  screenKey: 'reports_dashboard_mobile',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.section,
  runtimeMode: EmmaUiAnchorRuntimeMode.always,
  tapMode: EmmaUiAnchorTapMode.disabled,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['reports', 'dashboard', 'mobile'],
);

static const reportsDashboardMobileHeader = EmmaUiAnchorSpec(
  anchorKey: 'reports.dashboard.mobile.header',
  frontendRef: 'EmmaAnchors.reportsDashboardMobileHeader',
  label: 'Mobile reports header',
  description: 'Mobile dashboard greeting and report update description.',
  module: 'reports',
  screenKey: 'reports_dashboard_mobile',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.section,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.disabled,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['reports', 'mobile', 'header'],
);

static const reportsDashboardMobileRecentReportsSection = EmmaUiAnchorSpec(
  anchorKey: 'reports.dashboard.mobile.recent_reports_section',
  frontendRef: 'EmmaAnchors.reportsDashboardMobileRecentReportsSection',
  label: 'Mobile recent reports section',
  description: 'Mobile section with recent reports and view all action.',
  module: 'reports',
  screenKey: 'reports_dashboard_mobile',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.section,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.disabled,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['reports', 'mobile', 'recent', 'section'],
);

static const reportsDashboardMobileViewAllButton = EmmaUiAnchorSpec(
  anchorKey: 'reports.dashboard.mobile.view_all_button',
  frontendRef: 'EmmaAnchors.reportsDashboardMobileViewAllButton',
  label: 'Mobile view all reports button',
  description: 'Mobile button opening all reports list.',
  module: 'reports',
  screenKey: 'reports_dashboard_mobile',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.button,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['reports', 'mobile', 'view_all', 'button'],
  meta: {'opens': 'all_reports'},
);

static const reportsDashboardMobilePropertyList = EmmaUiAnchorSpec(
  anchorKey: 'reports.dashboard.mobile.property_list',
  frontendRef: 'EmmaAnchors.reportsDashboardMobilePropertyList',
  label: 'Mobile recent property list',
  description: 'Mobile list of recent property reports.',
  module: 'reports',
  screenKey: 'reports_dashboard_mobile',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.section,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.disabled,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['reports', 'mobile', 'property', 'list'],
);

static const reportsDashboardMobileCompareButton = EmmaUiAnchorSpec(
  anchorKey: 'reports.dashboard.mobile.compare_button',
  frontendRef: 'EmmaAnchors.reportsDashboardMobileCompareButton',
  label: 'Mobile compare reports button',
  description: 'Mobile button opening property reports comparison dialog.',
  module: 'reports',
  screenKey: 'reports_dashboard_mobile',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.button,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['reports', 'mobile', 'compare', 'button'],
  meta: {'opens': 'property_comparison_dialog'},
);

static const reportsDashboardMobileSalesChart = EmmaUiAnchorSpec(
  anchorKey: 'reports.dashboard.mobile.sales_chart',
  frontendRef: 'EmmaAnchors.reportsDashboardMobileSalesChart',
  label: 'Mobile sales chart',
  description: 'Mobile sales chart in reports dashboard.',
  module: 'reports',
  screenKey: 'reports_dashboard_mobile',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.widget,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.disabled,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['reports', 'mobile', 'chart', 'sales'],
);

static const reportsDashboardMobilePriceChart = EmmaUiAnchorSpec(
  anchorKey: 'reports.dashboard.mobile.price_chart',
  frontendRef: 'EmmaAnchors.reportsDashboardMobilePriceChart',
  label: 'Mobile price chart',
  description: 'Mobile price line chart in reports dashboard.',
  module: 'reports',
  screenKey: 'reports_dashboard_mobile',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.widget,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.disabled,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['reports', 'mobile', 'chart', 'price'],
);

static const reportsDashboardMobileInterestChart = EmmaUiAnchorSpec(
  anchorKey: 'reports.dashboard.mobile.interest_chart',
  frontendRef: 'EmmaAnchors.reportsDashboardMobileInterestChart',
  label: 'Mobile interest chart',
  description: 'Mobile interest levels chart.',
  module: 'reports',
  screenKey: 'reports_dashboard_mobile',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.widget,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.disabled,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['reports', 'mobile', 'chart', 'interest'],
);

static const reportsDashboardMobileCategoryChart = EmmaUiAnchorSpec(
  anchorKey: 'reports.dashboard.mobile.category_chart',
  frontendRef: 'EmmaAnchors.reportsDashboardMobileCategoryChart',
  label: 'Mobile report category chart',
  description: 'Mobile report category chart.',
  module: 'reports',
  screenKey: 'reports_dashboard_mobile',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.widget,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.disabled,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['reports', 'mobile', 'chart', 'category'],
);

static const reportsDashboardMobileStats = EmmaUiAnchorSpec(
  anchorKey: 'reports.dashboard.mobile.stats',
  frontendRef: 'EmmaAnchors.reportsDashboardMobileStats',
  label: 'Mobile report stats',
  description: 'Mobile report statistics summary.',
  module: 'reports',
  screenKey: 'reports_dashboard_mobile',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.widget,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.disabled,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['reports', 'mobile', 'stats'],
);

// ── Report PDF page ───────────────────────────────────────────────────────────

static const reportsPdfRoot = EmmaUiAnchorSpec(
  anchorKey: 'reports.pdf.root',
  frontendRef: 'EmmaAnchors.reportsPdfRoot',
  label: 'Report PDF page root',
  description: 'Full report PDF preview page with report list and detail view.',
  module: 'reports',
  screenKey: 'reports_pdf_pc',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.section,
  runtimeMode: EmmaUiAnchorRuntimeMode.always,
  tapMode: EmmaUiAnchorTapMode.disabled,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['reports', 'pdf', 'root'],
);

static const reportsPdfShareButton = EmmaUiAnchorSpec(
  anchorKey: 'reports.pdf.share_button',
  frontendRef: 'EmmaAnchors.reportsPdfShareButton',
  label: 'Share report button',
  description: 'Button that opens the share sheet to send the report link or email it to a CRM client.',
  module: 'reports',
  screenKey: 'reports_pdf_pc',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.button,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['reports', 'share', 'button', 'crm'],
  meta: {'opens': 'share_bottom_sheet'},
);

static const reportsPdfDownloadButton = EmmaUiAnchorSpec(
  anchorKey: 'reports.pdf.download_button',
  frontendRef: 'EmmaAnchors.reportsPdfDownloadButton',
  label: 'Download PDF button',
  description: 'Button that generates and downloads the property report as a PDF.',
  module: 'reports',
  screenKey: 'reports_pdf_pc',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.button,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['reports', 'pdf', 'download', 'button'],
  meta: {'action': 'download_pdf'},
);

static const reportsPdfMarketVelocitySection = EmmaUiAnchorSpec(
  anchorKey: 'reports.pdf.market_velocity_section',
  frontendRef: 'EmmaAnchors.reportsPdfMarketVelocitySection',
  label: 'Market velocity section',
  description: 'Section showing market velocity score, KPIs and histogram for the report property location.',
  module: 'reports',
  screenKey: 'reports_pdf_pc',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.section,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.disabled,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['reports', 'market', 'velocity', 'section'],
);

static const reportsPdfDailyMarketOverviewSection = EmmaUiAnchorSpec(
  anchorKey: 'reports.pdf.daily_market_overview_section',
  frontendRef: 'EmmaAnchors.reportsPdfDailyMarketOverviewSection',
  label: 'Daily market overview section',
  description: 'Section with daily market pulse, KPIs and narrative for the report city.',
  module: 'reports',
  screenKey: 'reports_pdf_pc',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.section,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.disabled,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['reports', 'market', 'overview', 'daily', 'section'],
);

static const reportsPdfAgentNotesSection = EmmaUiAnchorSpec(
  anchorKey: 'reports.pdf.agent_notes_section',
  frontendRef: 'EmmaAnchors.reportsPdfAgentNotesSection',
  label: 'Agent notes section',
  description: 'Private notes field for the agent, persisted locally per report.',
  module: 'reports',
  screenKey: 'reports_pdf_pc',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.section,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.disabled,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['reports', 'notes', 'agent', 'section'],
);

static const reportsPdfValueHistorySection = EmmaUiAnchorSpec(
  anchorKey: 'reports.pdf.value_history_section',
  frontendRef: 'EmmaAnchors.reportsPdfValueHistorySection',
  label: 'Estimate history section',
  description: 'Sparkline chart and table showing the history of estimated property values across visits.',
  module: 'reports',
  screenKey: 'reports_pdf_pc',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.section,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.disabled,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['reports', 'estimate', 'history', 'chart', 'section'],
);

static const reportsPdfExportCsvButton = EmmaUiAnchorSpec(
  anchorKey: 'reports.pdf.export_csv_button',
  frontendRef: 'EmmaAnchors.reportsPdfExportCsvButton',
  label: 'Export comparables CSV button',
  description: 'Button that exports the comparable properties table to a CSV file.',
  module: 'reports',
  screenKey: 'reports_pdf_pc',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.button,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['reports', 'comparables', 'csv', 'export', 'button'],
  meta: {'action': 'export_csv'},
);



  static const all = <EmmaUiAnchorSpec>[
    reportsDashboardAllRoot,
    reportsDashboardPcRoot,
    reportsDashboardPcHeader,
    reportsDashboardPcRecentReportsSection,
    reportsDashboardPcRefreshButton,
    reportsDashboardPcViewAllButton,
    reportsDashboardPcCompareButton,
    reportsDashboardPcPropertyList,
    reportsDashboardPcPriceChart,
    reportsDashboardPcSalesChart,
    reportsDashboardPcCategoryChart,
    reportsDashboardPcInterestChart,
    reportsDashboardPcStats,
    reportsDashboardMobileRoot,
    reportsDashboardMobileHeader,
    reportsDashboardMobileRecentReportsSection,
    reportsDashboardMobileViewAllButton,
    reportsDashboardMobilePropertyList,
    reportsDashboardMobileCompareButton,
    reportsDashboardMobileSalesChart,
    reportsDashboardMobilePriceChart,
    reportsDashboardMobileInterestChart,
    reportsDashboardMobileCategoryChart,
    reportsDashboardMobileStats,
    reportsPdfRoot,
    reportsPdfShareButton,
    reportsPdfDownloadButton,
    reportsPdfMarketVelocitySection,
    reportsPdfDailyMarketOverviewSection,
    reportsPdfAgentNotesSection,
    reportsPdfValueHistorySection,
    reportsPdfExportCsvButton,
  ];

}