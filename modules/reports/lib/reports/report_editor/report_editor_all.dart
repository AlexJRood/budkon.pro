import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:flutter/material.dart';

import 'report_editor_screen.dart';

class ReportEditorAll extends StatelessWidget {
  const ReportEditorAll({super.key});

  @override
  Widget build(BuildContext context) {
    final sideMenuKey = GlobalKey<SideMenuState>();

    return BarManager(
      sideMenuKey: sideMenuKey,
      appModule: AppModule.back,
      isChildExpanded: true,
      childPc: const ReportEditorScreen(),
      childMobile: const ReportEditorScreen(),
    );
  }
}
