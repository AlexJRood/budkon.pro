import 'package:core/ui/device_type_util.dart';
import 'package:core/ui/anchors/anchor_spec.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
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

class DashboardReportMobile extends ConsumerStatefulWidget {
  const DashboardReportMobile({super.key});

  @override
  ConsumerState<DashboardReportMobile> createState() =>
      _DashboardReportMobileState();
}

class _DashboardReportMobileState extends ConsumerState<DashboardReportMobile> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _openCompareReportsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => PropertyComparisonDialog(
        isMobile: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardDataProvider);
    final focusCities = dashboardAsync.valueOrNull?.focusCities ?? [];

    final focusCitiesText =
    focusCities.isEmpty
        ? 'market_snapshot_based_on_recent_activity'.tr
        : 'market_snapshot_for'.tr + focusCities.join(', ');

    return EmmaUiAnchorTarget(
      // @emma-backend: EmmaAnchors.reportsDashboardMobileRoot
      anchorKey: 'reports.dashboard.mobile.root',
      runtimeMode: EmmaUiAnchorRuntimeMode.always,
      tapMode: EmmaUiAnchorTapMode.disabled,
      child: Column(
        children: [
          SizedBox(
            height: TopAppBarSize.resolve(context),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    EmmaUiAnchorTarget(
                                      // @emma-backend: EmmaAnchors.reportsDashboardMobileHeader
                                      anchorKey:
                                          'reports.dashboard.mobile.header',
                                      tapMode: EmmaUiAnchorTapMode.disabled,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 20),
                                          Text(
                                            'reports_dashboard'.tr,
                                            style: TextStyle(
                                              color: CustomColors
                                                  .gradientTextcolor(
                                                context,
                                                ref,
                                              ),
                                              fontSize: 24.0,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 16.0),
                                          Text(
                                            focusCitiesText,
                                            style: TextStyle(
                                              color: CustomColors
                                                  .gradientTextcolor(
                                                context,
                                                ref,
                                              ),
                                              fontSize: 14.0,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    EmmaUiAnchorTarget(
                                      // @emma-backend: EmmaAnchors.reportsDashboardMobileRecentReportsSection
                                      anchorKey:
                                          'reports.dashboard.mobile.recent_reports_section',
                                      tapMode: EmmaUiAnchorTapMode.disabled,
                                      child: Row(
                                        children: [
                                          Text(
                                            'recent_reports'.tr,
                                            style: TextStyle(
                                              color: CustomColors
                                                  .gradientTextcolor(
                                                context,
                                                ref,
                                              ),
                                              fontSize: 16.0,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const Spacer(),
                                          EmmaUiAnchorTarget(
                                            // @emma-backend: EmmaAnchors.reportsDashboardMobileViewAllButton
                                            anchorKey:
                                                'reports.dashboard.mobile.view_all_button',
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
                                                  color: CustomColors
                                                      .gradientTextcolor(
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
                                        ],
                                      ),
                                    ),
                                    const EmmaUiAnchorTarget(
                                      // @emma-backend: EmmaAnchors.reportsDashboardMobilePropertyList
                                      anchorKey:
                                          'reports.dashboard.mobile.property_list',
                                      tapMode: EmmaUiAnchorTapMode.disabled,
                                      child: PropertyList(isMobile: true),
                                    ),
                                    const SizedBox(height: 15),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
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
                                        EmmaUiAnchorTarget(
                                          // @emma-backend: EmmaAnchors.reportsDashboardMobileCompareButton
                                          anchorKey:
                                              'reports.dashboard.mobile.compare_button',
                                          child: SettingsButton(
                                            isPc: true,
                                            buttonheight: 40,
                                            onTap: () =>
                                                _openCompareReportsDialog(context),
                                            text: 'Compare Reports'.tr,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          tooltip: 'report_editor'.tr,
                                          icon: const Icon(Icons.tune),
                                          color: CustomColors.gradientTextcolor(context, ref),
                                          onPressed: () => Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => const ReportEditorAll(),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 30),
                                    SizedBox(
                                      height: 1220,
                                      child: _ChartScrollForwarder(
                                        controller: _scrollController,
                                        child: const EmmaUiAnchorTarget(
                                          anchorKey: 'reports.dashboard.mobile.sales_chart',
                                          tapMode: EmmaUiAnchorTapMode.disabled,
                                          child: SalesChartMobile(),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 15),
                                    SizedBox(
                                      height: 400,
                                      child: _ChartScrollForwarder(
                                        controller: _scrollController,
                                        child: EmmaUiAnchorTarget(
                                          // @emma-backend: EmmaAnchors.reportsDashboardMobilePriceChart
                                          anchorKey:
                                              'reports.dashboard.mobile.price_chart',
                                          tapMode: EmmaUiAnchorTapMode.disabled,
                                          child: const PriceChartWidget(
                                            isMobile: true,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 15),
                                    SizedBox(
                                      height: 360,
                                      child: _ChartScrollForwarder(
                                        controller: _scrollController,
                                        child: EmmaUiAnchorTarget(
                                          // @emma-backend: EmmaAnchors.reportsDashboardMobileInterestChart
                                          anchorKey:
                                              'reports.dashboard.mobile.interest_chart',
                                          tapMode: EmmaUiAnchorTapMode.disabled,
                                          child: const InterestLevelsChart(
                                            isMobile: true,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 15),
                                    const SizedBox(
                                      height: 360,
                                      child: EmmaUiAnchorTarget(
                                        // @emma-backend: EmmaAnchors.reportsDashboardMobileCategoryChart
                                        anchorKey:
                                            'reports.dashboard.mobile.category_chart',
                                        tapMode: EmmaUiAnchorTapMode.disabled,
                                        child: ReportsCategoryWidget(
                                          isMobile: true,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 15),
                                    const EmmaUiAnchorTarget(
                                      // @emma-backend: EmmaAnchors.reportsDashboardMobileStats
                                      anchorKey:
                                          'reports.dashboard.mobile.stats',
                                      tapMode: EmmaUiAnchorTapMode.disabled,
                                      child: ReportStatsWidgetPc(isMobile: true,),
                                    ),
                                    const SizedBox(height: 60),
                                    SizedBox(
                                      height: TopAppBarSize.withTopAppBar(context),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Forwards vertical drag movement that starts over [child] to [controller].
///
/// Syncfusion charts install their own gesture recognizers for tooltips,
/// which can win the gesture arena against the ancestor [SingleChildScrollView]
/// and swallow vertical drags on touch devices. This widget reads raw pointer
/// events (outside the gesture arena) so the page keeps scrolling even when
/// a drag starts directly on top of a chart.
class _ChartScrollForwarder extends StatefulWidget {
  final ScrollController controller;
  final Widget child;

  const _ChartScrollForwarder({
    required this.controller,
    required this.child,
  });

  @override
  State<_ChartScrollForwarder> createState() => _ChartScrollForwarderState();
}

class _ChartScrollForwarderState extends State<_ChartScrollForwarder> {
  double? _lastDy;

  void _onPointerMove(PointerMoveEvent event) {
    final lastDy = _lastDy;
    if (lastDy == null || !widget.controller.hasClients) return;

    _lastDy = event.position.dy;

    final position = widget.controller.position;
    final next = (position.pixels + (lastDy - event.position.dy)).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    widget.controller.jumpTo(next);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) => _lastDy = event.position.dy,
      onPointerMove: _onPointerMove,
      onPointerUp: (_) => _lastDy = null,
      onPointerCancel: (_) => _lastDy = null,
      child: widget.child,
    );
  }
}