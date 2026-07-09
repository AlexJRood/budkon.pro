import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_monitoring/global_widgets/nm_map_pv_mobile.dart';
import 'package:network_monitoring/screens/feed_page/widgets/nm_grid_mobile.dart';
import 'package:network_monitoring/screens/map/map_state.dart';

/// Hosts the mobile Network Monitoring feed as a swipeable PageView:
/// page 0 = list/grid (default, matches pre-map behavior), page 1 = map.
/// Mirrors portal's PvMobilePage/MapPvMobile pattern, but without its own
/// Scaffold/appbar since BarManager already supplies those here.
class NmFeedPvMobile extends ConsumerStatefulWidget {
  const NmFeedPvMobile({super.key});

  @override
  ConsumerState<NmFeedPvMobile> createState() => _NmFeedPvMobileState();
}

class _NmFeedPvMobileState extends ConsumerState<NmFeedPvMobile> {
  late final PageController _pageViewController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageViewController = PageController();
  }

  @override
  void dispose() {
    _pageViewController.dispose();
    super.dispose();
  }

  void _handlePageViewChanged(int index) {
    _currentPage = index;
    ref.read(nmMapViewActiveProvider.notifier).state = index == 1;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(nmMapViewActiveProvider, (previous, isMapActive) {
      final targetPage = isMapActive ? 1 : 0;
      if (targetPage == _currentPage) return;

      _currentPage = targetPage;
      _pageViewController.animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    });

    return PageView(
      controller: _pageViewController,
      onPageChanged: _handlePageViewChanged,
      physics: const PageScrollPhysics(),
      children: [
        const NMGridViewMobile(),
        NmMapPvMobile(pageController: _pageViewController),
      ],
    );
  }
}
