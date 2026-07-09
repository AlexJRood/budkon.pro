import 'dart:math' as math;

import 'package:core/ui/anchors/anchor_spec.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/ui/buttons/app_buttons.dart';
import 'package:core/theme/backgroundgradient.dart';

import '../../compare_report/compare_report_popup.dart';
import '../provider/dashboard_provider.dart';
import '../widgets/intrest_level_pc.dart';
import '../widgets/last_report_pc.dart';
import '../widgets/report_category_pc.dart';
import '../widgets/report_line_graph_pc.dart';
import '../widgets/report_pie_graph.dart';
import '../widgets/report_stats_widget_pc.dart';

class DashboardReportTablet extends ConsumerWidget {
  const DashboardReportTablet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dashboardAsync = ref.watch(dashboardDataProvider);

    final double baseWidth = 1920;
    final double chartSectionMinHeight = 615;
    final double chartSectionHeight =
    screenWidth <= baseWidth
        ? chartSectionMinHeight
        : math.min(750, chartSectionMinHeight + (screenWidth - baseWidth) * 0.09);

    final double statsSectionMinHeight = 390;
    final double statsSectionHeight =
    screenWidth <= baseWidth
        ? statsSectionMinHeight
        : math.min(520, statsSectionMinHeight + (screenWidth - baseWidth) * 0.07);

    final focusCities = dashboardAsync.valueOrNull?.focusCities ?? [];
    final focusCitiesText =
    focusCities.isEmpty
        ? 'market_snapshot_based_on_recent_activity'.tr
        : 'market_snapshot_for'.trParams({'cities': focusCities.join(', ')});

    return EmmaUiAnchorTarget(
      // @emma-backend: EmmaAnchors.reportsDashboardTabletRoot
      anchorKey: 'reports.dashboard.tablet.root',
      runtimeMode: EmmaUiAnchorRuntimeMode.always,
      tapMode: EmmaUiAnchorTapMode.disabled,
      child: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Row(
                    children: [
                      SizedBox(width: constraints.maxWidth * 0.05),
                      SizedBox(
                        width: constraints.maxWidth * 0.9,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 70),
                            EmmaUiAnchorTarget(
                              // @emma-backend: EmmaAnchors.reportsDashboardTabletHeader
                              anchorKey: 'reports.dashboard.tablet.header',
                              tapMode: EmmaUiAnchorTapMode.disabled,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'reports_dashboard'.tr,
                                    style: TextStyle(
                                      color: CustomColors.gradientTextcolor(context, ref),
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    focusCitiesText,
                                    style: TextStyle(
                                      color: CustomColors.gradientTextcolor(context, ref),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 25),
                            EmmaUiAnchorTarget(
                              // @emma-backend: EmmaAnchors.reportsDashboardTabletRecentReportsSection
                              anchorKey: 'reports.dashboard.tablet.recent_reports_section',
                              tapMode: EmmaUiAnchorTapMode.disabled,
                              child: Row(
                                children: [
                                  Text(
                                    'recent_reports'.tr,
                                    style: TextStyle(
                                      color: CustomColors.gradientTextcolor(context, ref),
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),

                                  EmmaUiAnchorTarget(
                                    // @emma-backend: EmmaAnchors.reportsDashboardTabletRefreshButton
                                    anchorKey: 'reports.dashboard.tablet.refresh_button',
                                    child: IconButton(
                                      onPressed: () {
                                        ref.read(dashboardDataProvider.notifier).refresh();
                                      },
                                      icon: Icon(
                                        Icons.refresh_rounded,
                                        color: CustomColors.gradientTextcolor(context, ref),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 6),

                                  EmmaUiAnchorTarget(
                                    // @emma-backend: EmmaAnchors.reportsDashboardTabletViewAllButton
                                    anchorKey: 'reports.dashboard.tablet.view_all_button',
                                    child: TextButton(
                                      onPressed: () {
                                        ref
                                            .read(navigationService)
                                            .pushNamedScreen(Routes.allReports);
                                      },
                                      child: Text(
                                        "View All".tr,
                                        style: TextStyle(
                                          color: CustomColors.gradientTextcolor(context, ref),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 8),

                                  EmmaUiAnchorTarget(
                                    // @emma-backend: EmmaAnchors.reportsDashboardTabletCompareButton
                                    anchorKey: 'reports.dashboard.tablet.compare_button',
                                    child: SettingsButton(
                                      isPc: false,
                                      buttonheight: 36,
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => PropertyComparisonDialog(),
                                        );
                                      },
                                      text: 'compare_reports'.tr,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 6),

                            const EmmaUiAnchorTarget(
                              // @emma-backend: EmmaAnchors.reportsDashboardTabletPropertyList
                              anchorKey: 'reports.dashboard.tablet.property_list',
                              tapMode: EmmaUiAnchorTapMode.disabled,
                              child: PropertyList(isMobile: false),
                            ),

                            const SizedBox(height: 20),

                            /// 🔥 CHART SECTION
                            SizedBox(
                              height: chartSectionHeight + 650,
                              child: const Row(
                                children: [
                                  Expanded(
                                    flex: 60,
                                    child: EmmaUiAnchorTarget(
                                      // @emma-backend: EmmaAnchors.reportsDashboardTabletPriceChart
                                      anchorKey: 'reports.dashboard.tablet.price_chart',
                                      tapMode: EmmaUiAnchorTapMode.disabled,
                                      child: PriceChartWidget(),
                                    ),
                                  ),
                                  Expanded(child: SizedBox()),
                                  Expanded(
                                    flex: 40,
                                    child: EmmaUiAnchorTarget(
                                      // @emma-backend: EmmaAnchors.reportsDashboardTabletSalesChart
                                      anchorKey: 'reports.dashboard.tablet.sales_chart',
                                      tapMode: EmmaUiAnchorTapMode.disabled,
                                      child: SalesChart(isTablet: true),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 15),

                            /// 🔥 FIXED STATS SECTION
                            SizedBox(
                              height: statsSectionHeight + 260,
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: const [
                                        Expanded(
                                          flex: 30,
                                          child: EmmaUiAnchorTarget(
                                            // @emma-backend: EmmaAnchors.reportsDashboardTabletCategoryChart
                                            anchorKey: 'reports.dashboard.tablet.category_chart',
                                            tapMode: EmmaUiAnchorTapMode.disabled,
                                            child: ReportsCategoryWidget(),
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          flex: 38,
                                          child: EmmaUiAnchorTarget(
                                            // @emma-backend: EmmaAnchors.reportsDashboardTabletInterestChart
                                            anchorKey: 'reports.dashboard.tablet.interest_chart',
                                            tapMode: EmmaUiAnchorTapMode.disabled,
                                            child: InterestLevelsChart(),
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          flex: 32,
                                          child: EmmaUiAnchorTarget(
                                            // @emma-backend: EmmaAnchors.reportsDashboardTabletStats
                                            anchorKey: 'reports.dashboard.tablet.stats',
                                            tapMode: EmmaUiAnchorTapMode.disabled,
                                            child: ReportStatsWidgetPc(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 100),
                          ],
                        ),
                      ),

                      SizedBox(width: constraints.maxWidth * 0.05),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}