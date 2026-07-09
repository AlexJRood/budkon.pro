





import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:flutter/material.dart';
import 'package:reports/reports/all_report_page/screens/all_reports_screen_mobile.dart';
import 'package:reports/reports/all_report_page/screens/all_reports_screen_pc.dart';



class AllReportScreen extends StatelessWidget {
  const AllReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sideMenuKey = GlobalKey<SideMenuState>();
    return BarManager(
      sideMenuKey: sideMenuKey,
      appModule: AppModule.back,
      isChildExpanded: false,
      childPc: AllReportsScreenPc(),
      childMobile:  AllReportScreenMobile(),
    );
  }
}

