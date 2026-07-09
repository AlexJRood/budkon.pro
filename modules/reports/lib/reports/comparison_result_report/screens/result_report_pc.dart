import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:reports/reports/dashboard_report/widgets/components/report_proprty_card.dart';
import 'package:reports/reports/landing_page_report/widgets/search_widget_report.dart';
import 'package:reports/reports/comparison_result_report/widgets/report_data_widget.dart';
import 'package:reports/reports/compare_report/provider/compare_reports_api_provider.dart';
import 'package:reports/reports/all_report_page/model/report_list_model.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/ui/buttons/app_buttons.dart';
import 'package:core/theme/backgroundgradient.dart';

class ResultReportPc extends ConsumerStatefulWidget {
  final List<int>? reportIds;
  final List<ReportsListModel>? reports;

  const ResultReportPc({super.key, this.reportIds, this.reports});

  @override
  ConsumerState<ResultReportPc> createState() => _ResultReportPcState();
}

class _ResultReportPcState extends ConsumerState<ResultReportPc> {
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
            'no_reports_selected_for_comparison'.tr,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: CustomColors.secondaryWidgetTextColor(context, ref),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'please_select_at_least_one_report'.tr,
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
            child: Text('Go Back'.tr, style: TextStyle(fontSize: 16)),
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
    return SingleChildScrollView(
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
                    SizedBox(width: constraints.maxWidth * 0.1),
                    SizedBox(
                      width: constraints.maxWidth * 0.8,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,

                        children: [
                          SizedBox(height: 30),
                          Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: Container(
                                  height: 200,
                                  alignment: Alignment(-1, 1),
                                  child: Text(
                                    "Features".tr,
                                    style: TextStyle(
                                      color:
                                          CustomColors.secondaryWidgetTextColor(
                                            context,
                                            ref,
                                          ),
                                      fontSize: 30,
                                    ),
                                  ),
                                ),
                              ),

                              // Property cards from widget.reports
                              Expanded(
                                flex: 3,
                                child:
                                    widget.reports?.isEmpty ?? true
                                        ? Center(
                                          child: Text(
                                            'no_reports_to_compare'.tr,
                                            style: TextStyle(
                                              color:
                                                  CustomColors.secondaryWidgetTextColor(
                                                    context,
                                                    ref,
                                                  ).withAlpha(204),
                                              fontSize: 16,
                                            ),
                                          ),
                                        )
                                        : Row(
                                          children:
                                              widget.reports!
                                                  .take(3)
                                                  .toList()
                                                  .asMap()
                                                  .entries
                                                  .map((entry) {
                                                    final index = entry.key;
                                                    final report = entry.value;

                                                    return [
                                                      Expanded(
                                                        flex: 1,
                                                        child: ReprtPropertyCard(
                                                          reportId: report.id!,
                                                          isBlur: false,
                                                          backgroundColor:
                                                              CustomColors.secondaryWidgetColor(
                                                                context,
                                                                ref,
                                                              ),
                                                          imageUrl:
                                                              'https://images.unsplash.com/photo-1565402170291-8491f14678db?w=600&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Nnx8cmVhbCUyMGVzdGF0ZXxlbnwwfHwwfHx8MA%3D%3D',
                                                          address:
                                                              '${report.streetAddress ?? 'Unknown'}, ${report.city ?? 'Unknown'}',
                                                          price:
                                                              report.valueEstimate !=
                                                                      null
                                                                  ? '\$${report.valueEstimate!.toStringAsFixed(0)}'
                                                                  : 'price_not_available'.tr,
                                                          isMobile: false,
                                                          ref: ref,
                                                        ),
                                                      ),
                                                      if (index <
                                                          widget.reports!
                                                                  .take(3)
                                                                  .length -
                                                              1)
                                                        SizedBox(width: 10),
                                                    ];
                                                  })
                                                  .expand((widgets) => widgets)
                                                  .toList(),
                                        ),
                              ),
                              SizedBox(width: 10),
                            ],
                          ),

                          // Download PDF Button - positioned prominently after property cards
                          SizedBox(height: 20),
                          Align(
                            alignment: Alignment.centerRight,
                            child: SettingsButton(
                              isPc: true,
                              buttonheight: 30,
                              onTap: () {
                                // Build URL dynamically based on available report IDs
                                String url =
                                    '/compare-pdf/${widget.reportIds!.join('/')}';
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
                              text: 'pdf_report'.tr,
                            ),
                          ),

                          SizedBox(height: 20),
                          ComparisonTable(reports: widget.reports ?? []),
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
    );
  }
}
