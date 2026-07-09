import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:flutter/material.dart';
import 'package:reports/reports/all_report_page/model/report_list_model.dart';
import 'package:reports/reports/comparison_result_report/screens/result_report_mobile.dart';
import 'package:reports/reports/comparison_result_report/screens/result_report_pc.dart';
import 'package:reports/reports/comparison_result_report/screens/result_report_tablet.dart';

class ResultReportAll extends StatelessWidget {
  final List<int>? reportIds;
  final List<ReportsListModel>? reports;

  const ResultReportAll({super.key, this.reportIds, this.reports});

  @override
  Widget build(BuildContext context) {
    final sideMenuKey = GlobalKey<SideMenuState>();
    return BarManager(
      sideMenuKey: sideMenuKey,
      appModule: AppModule.portal,
      isChildExpanded: false,
      childPc: ResultReportPc(reportIds: reportIds, reports: reports),
      childTablet: ResultReportTablet(reportIds: reportIds, reports: reports),
      childMobile: ResultReportMobile(reportIds: reportIds, reports: reports),
    );
  }
}
