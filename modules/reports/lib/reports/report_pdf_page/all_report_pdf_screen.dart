import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:flutter/material.dart';
import 'package:reports/reports/all_report_page/model/report_list_model.dart';
import 'package:reports/reports/report_pdf_page/screens/report_pdf_screen_mobile.dart';
import 'package:reports/reports/report_pdf_page/screens/report_pdf_screen_pc.dart';
import 'package:reports/reports/report_pdf_page/screens/report_pdf_screen_tablet.dart';

class AllReportPdfScreen extends StatelessWidget {
  final List<int>? reportIds;
  final List<ReportsListModel>? reports;
  final bool isSampleData;

  const AllReportPdfScreen({
    super.key,
    this.reportIds,
    this.reports,
    this.isSampleData = false,
  });

  @override
  Widget build(BuildContext context) {
    final sideMenuKey = GlobalKey<SideMenuState>();

    return BarManager(
      sideMenuKey: sideMenuKey,
      appModule: AppModule.portal,
      isChildExpanded: false,
      childPc: ReportPdfScreenPc(
        reportIds: reportIds,
        reports: reports,
        isSampleData: isSampleData,
      ),
      childTablet: ReportPdfScreenTablet(
        reportIds: reportIds,
        reports: reports,
        isSampleData: isSampleData,
      ),
      childMobile: ReportPdfScreenMobile(
        reportIds: reportIds,
        reports: reports,
        isSampleData: isSampleData,
      ),
    );
  }
}