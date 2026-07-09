import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:core/ui/device_type_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:reports/reports/landing_page_report/widgets/search_widget_report.dart';
import 'package:reports/reports/comparison_result_report/widgets/report_data_widget.dart';
import 'package:reports/reports/compare_report/provider/compare_reports_api_provider.dart';
import 'package:reports/reports/all_report_page/model/report_list_model.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/ui/buttons/app_buttons.dart';
import 'package:core/theme/backgroundgradient.dart';

class ResultReportMobile extends ConsumerStatefulWidget {
  final List<int>? reportIds;
  final List<ReportsListModel>? reports;

  const ResultReportMobile({super.key, this.reportIds, this.reports});

  @override
  ConsumerState<ResultReportMobile> createState() => _ResultReportMobileState();
}

class _ResultReportMobileState extends ConsumerState<ResultReportMobile> {
  @override
  void initState() {
    super.initState();
    // Only load reports if we don't have pre-fetched data and have IDs
    if (widget.reports == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        List<int> ids = widget.reportIds ?? [];

        // Try to get IDs from route arguments if not provided directly
        if (ids.isEmpty) {
          final routeArgs = ModalRoute.of(context)?.settings.arguments;
          if (routeArgs is List<int>) {
            ids = routeArgs;
          }
        }

        // Fallback to demo IDs if still empty

        if (ids.isNotEmpty) {
          ref.read(compareReportsProvider.notifier).fetchCompareReports(ids);
        }
      });
    } else {
      // If we have pre-fetched reports, set them in the provider
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(compareReportsProvider.notifier).setReports(widget.reports!);
      });
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.compare_arrows,
            size: 80,
            color: CustomColors.secondaryWidgetTextColor(
              context,
              ref,
            ).withAlpha(76),
          ),
          SizedBox(height: 24),
          Text(
            'No Reports Selected for Comparison',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: CustomColors.secondaryWidgetTextColor(context, ref),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Please select at least one report to compare properties.',
            style: TextStyle(
              fontSize: 16,
              color: CustomColors.secondaryWidgetTextColor(
                context,
                ref,
              ).withAlpha(178),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyan,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Go Back', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final _scrollController = ScrollController();
    final sideMenuKey = GlobalKey<SideMenuState>();
    double dynamicPadding = MediaQuery.of(context).size.width / 6;

    // Show empty state if no report IDs or reports provided
    if ((widget.reportIds != null && widget.reportIds!.isEmpty) &&
        (widget.reports == null || widget.reports!.isEmpty)) {
      return _buildEmptyState();
    }
    return Column(
      children: [
        SizedBox(height: TopAppBarSize.resolve(context)),
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                SizedBox(height: 60),
                ResponsivePropertySearchWidget(),
                SizedBox(
                  width: double.infinity,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Row(
                        children: [
                          Expanded(
                            child: Container(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 30),
                                    Row(
                                      children: [
                                        SizedBox(
                                          child: Text(
                                            "Features".tr,
                                            style: TextStyle(
                                              color:
                                                  CustomColors.mainBackgroundtextColor(
                                                    context,
                                                    ref,
                                                  ),
                                              fontSize: 30,
                                            ),
                                          ),
                                        ),
                                        Spacer(),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: SettingsButton(
                                            isPc: true,
                                            buttonheight: 30,
                                            onTap: () {
                                              String url =
                                                  '/compare-pdf/${widget.reportIds![0]}/${widget.reportIds![1]}/${widget.reportIds![2]}';
                                              ref
                                                  .read(navigationService)
                                                  .pushNamedScreen(url);

                                              //  ref.read(navigationService).pushNamedScreen(url);
                                              //     Navigator.of(context).push(
                                              //       MaterialPageRoute(
                                              //         builder:
                                              //             (context) => AllReportPdfScreen(
                                              //               reportIds: widget.reportIds,
                                              //               reports: widget.reports,
                                              //             ),
                                              //       ),
                                              //     );
                                            },
                                            text: "pdf_report".tr,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 15),
                                    // Get reports from provider or widget
                                    Consumer(
                                      builder: (context, ref, child) {
                                        final reportsState = ref.watch(
                                          compareReportsProvider,
                                        );
                                        final List<ReportsListModel> reports;

                                        if (widget.reports != null) {
                                          reports = widget.reports!;
                                        } else if (reportsState
                                            .reports
                                            .isNotEmpty) {
                                          reports = reportsState.reports;
                                        } else {
                                          reports = [];
                                        }

                                        return ComparisonTableMobile(
                                          reports: reports,
                                        );
                                      },
                                    ),
                                    SizedBox(height: 70),
                                  ],
                                ),
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
        SizedBox(height: TopAppBarSize.withTopAppBar(context)),
      ],
    );
  }
}
