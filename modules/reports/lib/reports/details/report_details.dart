import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:flutter/material.dart';
import 'package:reports/reports/details/single_report_result_mobile.dart';
import 'package:reports/reports/details/single_report_result_pc.dart';

class SingleReportResultAll extends StatelessWidget {
  final int reportId;
  final Map<String, dynamic> reportPdfData;

  const SingleReportResultAll({
    super.key,
    required this.reportId,
    required this.reportPdfData,
  });

  @override
  Widget build(BuildContext context) {
    final sideMenuKey = GlobalKey<SideMenuState>();

    return BarManager(
      sideMenuKey: sideMenuKey,
      appModule: AppModule.portal,
      isChildExpanded: false,
      childPc: SingleReportResultPc(
        reportId: reportId,
        reportPdfData: reportPdfData,
      ),
      childMobile: SingleReportResultMobile(
        reportId: reportId,
        reportPdfData: reportPdfData,
      ),
    );
  }
}