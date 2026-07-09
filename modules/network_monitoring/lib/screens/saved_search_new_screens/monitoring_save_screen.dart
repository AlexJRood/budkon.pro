// import 'package:core/shell/manager/bar_manager.dart';
// import 'package:core/ui/side_menu/slide_rotate_menu.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:network_monitoring/screens/feed_page/widgets/nm_grid_mobile.dart';
// import 'package:network_monitoring/screens/saved_search_new_screens/monitoring_save_pc.dart';
// import 'package:network_monitoring/saved_search/saved_search_new_screens/widgets/network_monitoring_feed_bar_vertical.dart';

// class MonitoringSaveScreen extends ConsumerWidget {
//   const MonitoringSaveScreen({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final sideMenuKey = GlobalKey<SideMenuState>();

//     return BarManager(
//       sideMenuKey: sideMenuKey,
//       appModule: AppModule.networkMonitoring,
//       verticalButtons: NetworkMonitoringFeedBarVerticalMobile(ref: ref),
      
//       childPc:MonitoringSavePc(),
//       childMobile: NMGridViewMobile(),
//     );
//   }
// }
