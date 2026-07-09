import 'dart:math' as math;

import 'package:core/ui/anchors/anchor_spec.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:reports/reports/compare_report/compare_report_popup.dart';
import 'package:reports/reports/report_editor/report_editor_all.dart';
import 'package:reports/reports/dashboard_report/provider/dashboard_provider.dart';
import 'package:reports/reports/dashboard_report/widgets/intrest_level_pc.dart';
import 'package:reports/reports/dashboard_report/widgets/last_report_pc.dart';
import 'package:reports/reports/dashboard_report/widgets/report_category_pc.dart';
import 'package:reports/reports/dashboard_report/widgets/report_line_graph_pc.dart';
import 'package:reports/reports/dashboard_report/widgets/report_pie_graph.dart';
import 'package:reports/reports/dashboard_report/widgets/report_stats_widget_pc.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/ui/buttons/app_buttons.dart';
import 'package:core/theme/backgroundgradient.dart';

class DashboardReportPc extends ConsumerWidget {
  const DashboardReportPc({super.key});

  void _openCompareReportsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => PropertyComparisonDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dashboardAsync = ref.watch(dashboardDataProvider);

    const double baseWidth = 1920;
    const double chartSectionMinHeight = 615;
    final double chartSectionHeight = screenWidth <= baseWidth
        ? chartSectionMinHeight
        : math.min(
            750,
            chartSectionMinHeight + (screenWidth - baseWidth) * 0.09,
          );

    const double statsSectionMinHeight = 390;
    final double statsSectionHeight = screenWidth <= baseWidth
        ? statsSectionMinHeight
        : math.min(
            520,
            statsSectionMinHeight + (screenWidth - baseWidth) * 0.07,
          );

    final focusCities = dashboardAsync.valueOrNull?.focusCities ?? [];
    final focusCitiesText =
        focusCities.isEmpty
             ? 'market_snapshot_based_on_recent_activity'.tr
             : 'market_snapshot_for'.tr + focusCities.join(', ');

    return EmmaUiAnchorTarget(
      // @emma-backend: EmmaAnchors.reportsDashboardPcRoot
      anchorKey: 'reports.dashboard.pc.root',
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
                      SizedBox(width: constraints.maxWidth * 0.1),
                      SizedBox(
                        width: constraints.maxWidth * 0.8,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            EmmaUiAnchorTarget(
                              // @emma-backend: EmmaAnchors.reportsDashboardPcHeader
                              anchorKey: 'reports.dashboard.pc.header',
                              tapMode: EmmaUiAnchorTapMode.disabled,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 90),
                                  Text(
                                    'reports_dashboard'.tr,
                                    style: TextStyle(
                                      color: CustomColors.gradientTextcolor(
                                        context,
                                        ref,
                                      ),
                                      fontSize: 24.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12.0),
                                  Text(
                                    focusCitiesText,
                                    style: TextStyle(
                                      color: CustomColors.gradientTextcolor(
                                        context,
                                        ref,
                                      ),
                                      fontSize: 14.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 30),
                            EmmaUiAnchorTarget(
                              // @emma-backend: EmmaAnchors.reportsDashboardPcRecentReportsSection
                              anchorKey:
                                  'reports.dashboard.pc.recent_reports_section',
                              tapMode: EmmaUiAnchorTapMode.disabled,
                              child: Row(
                                children: [
                                  Text(
                                    'recent_reports'.tr,
                                    style: TextStyle(
                                      color: CustomColors.gradientTextcolor(
                                        context,
                                        ref,
                                      ),
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  EmmaUiAnchorTarget(
                                    // @emma-backend: EmmaAnchors.reportsDashboardPcRefreshButton
                                    anchorKey:
                                        'reports.dashboard.pc.refresh_button',
                                    child: IconButton(
                                      onPressed: () {
                                        ref
                                            .read(
                                              dashboardDataProvider.notifier,
                                            )
                                            .refresh();
                                      },
                                      icon: Icon(
                                        Icons.refresh_rounded,
                                        color: CustomColors.gradientTextcolor(
                                          context,
                                          ref,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  EmmaUiAnchorTarget(
                                    // @emma-backend: EmmaAnchors.reportsDashboardPcViewAllButton
                                    anchorKey:
                                        'reports.dashboard.pc.view_all_button',
                                    child: TextButton(
                                      onPressed: () {
                                        ref
                                            .read(navigationService)
                                            .pushNamedScreen(
                                              Routes.allReports,
                                            );
                                      },
                                      child: Text(
                                        'View All'.tr,
                                        style: TextStyle(
                                          color:
                                              CustomColors.gradientTextcolor(
                                            context,
                                            ref,
                                          ),
                                          fontSize: 12.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  EmmaUiAnchorTarget(
                                    // @emma-backend: EmmaAnchors.reportsDashboardPcCompareButton
                                    anchorKey:
                                        'reports.dashboard.pc.compare_button',
                                    child: SettingsButton(
                                      isPc: true,
                                      buttonheight: 40,
                                      onTap: () =>
                                          _openCompareReportsDialog(context),
                                      text: 'compare_reports'.tr,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  SettingsButton(
                                    isPc: true,
                                    buttonheight: 40,
                                    icon: Icons.tune,
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const ReportEditorAll(),
                                      ),
                                    ),
                                    text: 'report_editor'.tr,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            const EmmaUiAnchorTarget(
                              // @emma-backend: EmmaAnchors.reportsDashboardPcPropertyList
                              anchorKey: 'reports.dashboard.pc.property_list',
                              tapMode: EmmaUiAnchorTapMode.disabled,
                              child: PropertyList(isMobile: false),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: chartSectionHeight + 300,
                              child: const Row(
                                children: [
                                  Expanded(
                                    flex: 68,
                                    child: EmmaUiAnchorTarget(
                                      // @emma-backend: EmmaAnchors.reportsDashboardPcPriceChart
                                      anchorKey:
                                          'reports.dashboard.pc.price_chart',
                                      tapMode: EmmaUiAnchorTapMode.disabled,
                                      child: PriceChartWidget(),
                                    ),
                                  ),
                                  Expanded(child: SizedBox()),
                                  Expanded(
                                    flex: 32,
                                    child: EmmaUiAnchorTarget(
                                      // @emma-backend: EmmaAnchors.reportsDashboardPcSalesChart
                                      anchorKey:
                                          'reports.dashboard.pc.sales_chart',
                                      tapMode: EmmaUiAnchorTapMode.disabled,
                                      child: SalesChart(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 15),
                            SizedBox(
                              height: statsSectionHeight + 200,
                              child: const Row(
                                children: [
                                  Expanded(
                                    flex: 30,
                                    child: EmmaUiAnchorTarget(
                                      // @emma-backend: EmmaAnchors.reportsDashboardPcCategoryChart
                                      anchorKey:
                                          'reports.dashboard.pc.category_chart',
                                      tapMode: EmmaUiAnchorTapMode.disabled,
                                      child: ReportsCategoryWidget(),
                                    ),
                                  ),
                                  Expanded(child: SizedBox()),
                                  Expanded(
                                    flex: 38,
                                    child: EmmaUiAnchorTarget(
                                      // @emma-backend: EmmaAnchors.reportsDashboardPcInterestChart
                                      anchorKey:
                                          'reports.dashboard.pc.interest_chart',
                                      tapMode: EmmaUiAnchorTapMode.disabled,
                                      child: InterestLevelsChart(),
                                    ),
                                  ),
                                  Expanded(child: SizedBox()),
                                  Expanded(
                                    flex: 32,
                                    child: EmmaUiAnchorTarget(
                                      // @emma-backend: EmmaAnchors.reportsDashboardPcStats
                                      anchorKey: 'reports.dashboard.pc.stats',
                                      tapMode: EmmaUiAnchorTapMode.disabled,
                                      child: ReportStatsWidgetPc(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 120),
                          ],
                        ),
                      ),
                      SizedBox(width: constraints.maxWidth * 0.1),
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