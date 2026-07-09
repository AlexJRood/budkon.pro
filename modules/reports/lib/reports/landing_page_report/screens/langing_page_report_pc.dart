import 'package:flutter/material.dart';
// ignore_for_file: use_build_context_synchronously, prefer_const_constructors_in_immutables

import 'package:portal/screens/landing_page/widgets/landing_page_pc/footer_widget.dart';
import 'package:reports/reports/landing_page_report/widgets/frequent_asked_questions.dart';
import 'package:reports/reports/landing_page_report/widgets/pc/proprty_report_overview_widget_pc.dart';
import 'package:reports/reports/landing_page_report/widgets/search_widget_report.dart';

class LandingPageReportPc extends StatelessWidget {
  const LandingPageReportPc({super.key});

  @override
  Widget build(BuildContext context) {
    final _scrollController = ScrollController();
    double dynamicPadding = MediaQuery.of(context).size.width / 6;
    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        children: [
          SizedBox(height: 60),
          ResponsivePropertySearchWidget(),
          Column(
            children: [
              PropertyReportOverviewWidgetPc(),
              SizedBox(height: 60),
              PropertySearchStepsWidgetPc(),
              PropertySelectWidgetPc(),
              PropertyPurchaseWidgetPc(),
              ReportsFAQPage(isMobile: false),
            ],
          ),
          FooterWidget(paddingDynamic: dynamicPadding),
          // PropertyValuationForm(),
        ],
      ),
    );
  }
}
