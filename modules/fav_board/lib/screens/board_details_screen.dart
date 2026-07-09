import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:flutter/material.dart';

import '../widgets/board_details_mobile_screen.dart';
import '../widgets/board_details_pc_screen.dart';

class BoardDetailsScreen extends StatelessWidget {
  BoardDetailsScreen({super.key});

  final sideMenuKey = GlobalKey<SideMenuState>();

  @override
  Widget build(BuildContext context) {
    return BarManager(
      sideMenuKey: sideMenuKey,
      appModule: AppModule.back,
      enableScrool: true,
      childPc: const BoardDetailsPcScreen(),
      childMobile: const BoardDetailsMobileScreen(),
      tabletScaffoldMode: TabletScaffoldMode.mobile,
      tabletBreakpoint: 900,
    );
  }
}