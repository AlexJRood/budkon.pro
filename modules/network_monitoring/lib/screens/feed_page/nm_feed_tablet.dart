// ignore_for_file: prefer_const_constructors_in_immutables

import 'package:core/ui/anchors/anchor_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_monitoring/browselist/widget/tablet.dart';
import 'package:network_monitoring/screens/feed_page/widgets/grid_nm_tablet_page.dart';
import 'package:network_monitoring/widgets/filter/tablet_filter_monitoring_widget.dart';

/// Tablet layout for NM Feed (800 – 1 200 px).
///
/// Layout (left → right):
///  ┌─────────────────┬─────────────────────────────┬──────────┐
///  │ FilterSidebar   │       Grid (Expanded)        │ BrowseList│
///  │  flex: 2 (≈200) │       flex: 5                │ collapsed │
///  └─────────────────┴─────────────────────────────┴──────────┘
///
/// The filter uses [TabletFilterMonitoringWidget] providing a bespoke
/// dense layout for tablet sidebars.
///
/// The grid uses [GridNMTabletPage] which caps cross-axis count at 2 and uses
/// tighter padding to avoid overflows at 800 px.
///
/// The browse-list uses [BrowseListNetworkMonitoringTabletWidget] which starts
/// collapsed (56 px peek) and expands to 260 px.
class NMFeedTablet extends ConsumerWidget {
  const NMFeedTablet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Filter: fixed width that scales linearly 180 px @ 800 → 210 px @ 1200.
    final double filterWidth = (((screenWidth - 800) / 400) * 30 + 180).clamp(
      180.0,
      210.0,
    );

    return EmmaUiAnchorTarget(
      // @emma-backend: NetworkMonitoringEmmaAnchors.feedTabletRoot
      anchorKey: 'network_monitoring.feed.tablet.root',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Filter sidebar — fixed width, no flex ──────────────────────────
          SizedBox(
            width: filterWidth,
            child: const EmmaUiAnchorTarget(
              // @emma-backend: NetworkMonitoringEmmaAnchors.feedTabletFilters
              anchorKey: 'network_monitoring.feed.tablet.filters',
              child: TabletFilterMonitoringWidget(),
            ),
          ),

          // ── Property grid — takes all remaining space ──────────────────────
          // GridNMTabletPage wraps itself in Expanded so no extra Expanded needed.
          const EmmaUiAnchorTarget(
            // @emma-backend: NetworkMonitoringEmmaAnchors.feedTabletGrid
            anchorKey: 'network_monitoring.feed.tablet.grid',
            child: GridNMTabletPage(),
          ),

          // ── Browse-list panel — width managed internally ───────────────────
          const EmmaUiAnchorTarget(
            // @emma-backend: NetworkMonitoringEmmaAnchors.feedTabletBrowseList
            anchorKey: 'network_monitoring.feed.tablet.browse_list',
            child: BrowseListNetworkMonitoringTabletWidget(
              isWhiteSpaceNeeded: true,
            ),
          ),
        ],
      ),
    );
  }
}
