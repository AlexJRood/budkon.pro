import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:crm/dynamic_dashboard/dynamic_dashboard_page.dart';
import 'package:crm/dynamic_dashboard/widgets/dashboard_vertical_bar.dart';
import 'package:flutter/material.dart';
import 'package:crm_agent/screens/pro_dashboard_tablet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NewDashboardScreen extends ConsumerStatefulWidget {
  const NewDashboardScreen({super.key});

  @override
  ConsumerState<NewDashboardScreen> createState() => _NewDashboardScreenState();
}

class _NewDashboardScreenState extends ConsumerState<NewDashboardScreen> {
  final GlobalKey<SideMenuState> sideMenuKey = GlobalKey<SideMenuState>();
  static const dashboardKey = 'crm_main';

  @override
  Widget build(BuildContext context) {
    return BarManager(
      sideMenuKey: sideMenuKey,
      appModule: AppModule.agentCrm,
      enableScrool: false,
      isTopAppBarHoveroverUI: true,
      paddingPc: 20,
      paddingTablet: 16,
      paddingMobile: 10,

      /// Desktop / tablet floating controls
      verticalButtonsPc: const DashboardVerticalBar(dashboardKey: dashboardKey),

      /// Optional mobile floating controls too
      verticalButtons: const DashboardVerticalBar(dashboardKey: dashboardKey),

      childPc: const DynamicDashboardPage(dashboardKey: dashboardKey),
      childTablet: const ProDashboardTablet(dashboardKey: dashboardKey),
      childMobile: const DynamicDashboardPage(dashboardKey: dashboardKey),
    );
  }
}
