
import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:flutter/material.dart';
import 'package:reports/reports/create_report_page/screens/create_report_mobile.dart';
import 'package:reports/reports/create_report_page/screens/create_report_pc.dart';


class CreateReportAll extends StatelessWidget {
  const CreateReportAll({super.key});

  @override
  Widget build(BuildContext context) {
    final sideMenuKey = GlobalKey<SideMenuState>();
    return BarManager(
      sideMenuKey: sideMenuKey,
      appModule: AppModule.portal,
      isChildExpanded: false,
      childPc: CreateReportPc(),
      childMobile: CreateReportMobile(),
    );
  }
}

