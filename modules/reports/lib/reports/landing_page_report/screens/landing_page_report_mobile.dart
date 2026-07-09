import 'package:flutter/material.dart';
// ignore_for_file: use_build_context_synchronously, prefer_const_constructors_in_immutables

import 'package:core/ui/device_type_util.dart';
import 'package:portal/screens/landing_page/widgets/landing_page_mobile/footer_mobile_widget.dart';
import 'package:reports/reports/landing_page_report/widgets/mobile/proprty_report_overview_widget_mobile.dart';
import 'package:reports/reports/landing_page_report/widgets/frequent_asked_questions.dart';
import 'package:reports/reports/landing_page_report/widgets/search_widget_report.dart';

class LandingPageReportMobile extends StatelessWidget {
  const LandingPageReportMobile({super.key});

  @override
  Widget build(BuildContext context) {
    final scrollController = ScrollController();
    return Column(
      children: [
        SizedBox(height: TopAppBarSize.resolve(context)),
        Expanded(
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              children: [
                SizedBox(height: 60),
                ResponsivePropertySearchWidget(),
                Column(
                  children: [
                    PropertyReportOverviewWidgetMobile(),
                    SizedBox(height: 60),
                    PropertySearchStepsWidgetMobile(),
                    PropertySelectWidgetMobile(),
                    PropertyPurchaseWidgetMobile(),
                    ReportsFAQPage(isMobile: true),
                  ],
                ),
                const FooterWidgetMobile(isMobile: true, paddingDynamic: 10),
              ],
            ),
          ),
        ),
        SizedBox(
          height: DeviceTypeUtil.isCenterButtonIPhone(context) ? 30 : 50,
        ),
      ],
    );
  }
}
