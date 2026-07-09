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

class ResultReportTablet extends ConsumerStatefulWidget {
  final List<int>? reportIds;
  final List<ReportsListModel>? reports;

  const ResultReportTablet({super.key, this.reportIds, this.reports});

  @override
  ConsumerState<ResultReportTablet> createState() =>
      _ResultReportTabletState();
}

class _ResultReportTabletState
    extends ConsumerState<ResultReportTablet> {

  @override
  void initState() {
    super.initState();

    if (widget.reports == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        List<int> ids = widget.reportIds ?? [];

        if (ids.isEmpty) {
          final routeArgs = ModalRoute.of(context)?.settings.arguments;
          if (routeArgs is List<int>) {
            ids = routeArgs;
          }
        }

        if (ids.isNotEmpty) {
          ref.read(compareReportsProvider.notifier).fetchCompareReports(ids);
        }
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(compareReportsProvider.notifier)
            .setReports(widget.reports!);
      });
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        'no_reports_selected_for_comparison'.tr,
        style: TextStyle(fontSize: 18),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scrollController = ScrollController();

    if ((widget.reportIds != null && widget.reportIds!.isEmpty) &&
        (widget.reports == null || widget.reports!.isEmpty)) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      controller: scrollController,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 40),

            ResponsivePropertySearchWidget(),

            const SizedBox(height: 20),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                widget.reports?.isEmpty ?? true
                    ? Center(
                  child: Text('no_reports_to_compare'.tr),
                )
                    : Row(
                  children: widget.reports!
                      .take(3) // ✅ keep 3 cards
                      .toList()
                      .asMap()
                      .entries
                      .map((entry) {
                    final index = entry.key;
                    final report = entry.value;

                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: index < 2 ? 10 : 0, // spacing between cards
                        ),
                        child: ReprtPropertyCard(
                          reportId: report.id!,
                          isBlur: false,
                          backgroundColor:
                          CustomColors.secondaryWidgetColor(context, ref),
                          imageUrl:
                          'https://images.unsplash.com/photo-1565402170291-8491f14678db',
                          address:
                          '${report.streetAddress ?? 'Unknown'}, ${report.city ?? 'Unknown'}',
                          price: report.valueEstimate != null
                              ? '\$${report.valueEstimate!.toStringAsFixed(0)}'
                              : 'price_not_available'.tr,

                          isMobile: false,
                          isTablet: true,
                          ref: ref,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Text(
                  "Features".tr,
                  style: TextStyle(
                    fontSize: 24, // smaller than PC
                    color: CustomColors.secondaryWidgetTextColor(context, ref),
                  ),
                ),

              ],
            ),

            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: SettingsButton(
                isPc: false,
                buttonheight: 35,
                onTap: () {
                  String url =
                      '/compare-pdf/${widget.reportIds!.join('/')}';
                  ref.read(navigationService).pushNamedScreen(url);
                },
                text: 'pdf_report'.tr,
              ),
            ),

            const SizedBox(height: 20),

            ComparisonTable(reports: widget.reports ?? []),
          ],
        ),
      ),
    );
  }
}