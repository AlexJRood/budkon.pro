import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_monitoring/global_widgets/nm_feed_pv_mobile.dart';
import 'package:network_monitoring/screens/feed_page/nm_feed_pc.dart';
import 'package:network_monitoring/screens/feed_page/nm_feed_tablet.dart';
import 'package:network_monitoring/screens/saved_search_new_screens/widgets/network_monitoring_feed_bar_vertical.dart';

class NMFeedPage extends ConsumerStatefulWidget {
  const NMFeedPage({super.key});

  @override
  ConsumerState<NMFeedPage> createState() => _NMFeedPageState();
}

class _NMFeedPageState extends ConsumerState<NMFeedPage> {
  final GlobalKey<SideMenuState> _sideMenuKey = GlobalKey<SideMenuState>();

  @override
  Widget build(BuildContext context) {
    return EmmaUiAnchorTarget(
      // @emma-backend: NetworkMonitoringEmmaAnchors.feedRoot
      anchorKey: 'network_monitoring.feed.root',
      child: BarManager(
        sideMenuKey: _sideMenuKey,
        appModule: AppModule.networkMonitoring,
        isTopAppBarHoveroverUI: true,
        verticalButtons: const NetworkMonitoringFeedBarVerticalMobile(),
        showClientToggle: true,
        childPc: const NMFeedPc(),
        childTablet: NMFeedTablet(),
        childMobile: const NmFeedPvMobile(),
      ),
    );
  }
}