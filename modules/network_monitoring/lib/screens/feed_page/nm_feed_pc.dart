// ignore_for_file: use_build_context_synchronously, prefer_const_constructors_in_immutables

import 'package:core/ui/anchors/anchor_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_monitoring/browselist/widget/pc.dart';
import 'package:network_monitoring/screens/feed_page/widgets/grid_nm_pc_page.dart';
import 'package:network_monitoring/widgets/filter/filter_monitoring_widget.dart';

class NMFeedPc extends ConsumerWidget {
  const NMFeedPc({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const EmmaUiAnchorTarget(
      // @emma-backend: NetworkMonitoringEmmaAnchors.feedPcRoot
      anchorKey: 'network_monitoring.feed.pc.root',
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: EmmaUiAnchorTarget(
              // @emma-backend: NetworkMonitoringEmmaAnchors.feedPcFilters
              anchorKey: 'network_monitoring.feed.pc.filters',
              child: FilterMonitoringWidget(),
            ),
          ),
          Expanded(
            flex: 3,
            child: EmmaUiAnchorTarget(
              // @emma-backend: NetworkMonitoringEmmaAnchors.feedPcGrid
              anchorKey: 'network_monitoring.feed.pc.grid',
              child: GridNMPcPage(),
            ),
          ),
          EmmaUiAnchorTarget(
            // @emma-backend: NetworkMonitoringEmmaAnchors.feedPcBrowseList
            anchorKey: 'network_monitoring.feed.pc.browse_list',
            child: BrowseListNetworkMonitoringPcWidget(
              isWhiteSpaceNeeded: true,
            ),
          ),
        ],
      ),
    );
  }
}