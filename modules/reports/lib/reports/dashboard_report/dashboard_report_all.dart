import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:core/ui/anchors/anchor_spec.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:flutter/material.dart';
import 'package:reports/reports/dashboard_report/screens/dashboard_report_mobile.dart';
import 'package:reports/reports/dashboard_report/screens/dashboard_report_pc.dart';
import 'package:reports/reports/dashboard_report/screens/dashboard_report_tablet.dart';

class DashboardReportAll extends StatelessWidget {
  const DashboardReportAll({super.key});

  @override
  Widget build(BuildContext context) {
    final sideMenuKey = GlobalKey<SideMenuState>();

    return EmmaUiAnchorTarget(
      // @emma-backend: EmmaAnchors.reportsDashboardAllRoot
      anchorKey: 'reports.dashboard.all.root',
      runtimeMode: EmmaUiAnchorRuntimeMode.always,
      tapMode: EmmaUiAnchorTapMode.disabled,
      child: BarManager(
        sideMenuKey: sideMenuKey,
        appModule: AppModule.portal,
        isChildExpanded: false,
        childPc: const DashboardReportPc(),
        childTablet: DashboardReportTablet(),
      childMobile: const DashboardReportMobile(),
      ),
    );
  }
}