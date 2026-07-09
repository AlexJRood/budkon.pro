import 'package:core/shell/manager/bar_manager.dart';
import 'package:portal/bars/feed_bar_vertical.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:portal/global_widgets/ads_pv_mobile.dart';
import 'package:portal/global_widgets/map_pv_mobile.dart';

class PvMobilePage extends ConsumerStatefulWidget {
  const PvMobilePage({super.key});

  @override
  ConsumerState<PvMobilePage> createState() => _PvMobilePageState();
}

class _PvMobilePageState extends ConsumerState<PvMobilePage> {
  late final PageController _pageViewController;
  final sideMenuKey = GlobalKey<SideMenuState>();

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
    if (_currentPage == index) return;

    setState(() {
      _currentPage = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BarManager(
      sideMenuKey: sideMenuKey,
      appModule: AppModule.portal,
      isTopAppBarHoveroverUI: true,
      verticalButtons: FeedBarVerticalMobile(ref: ref),
      childMobile: PageView(
        controller: _pageViewController,
        onPageChanged: _handlePageViewChanged,
        physics: const PageScrollPhysics(),
        children: [
          MapPvMobile(pageController: _pageViewController),
          AdsPvMobile(pageController: _pageViewController),
        ],
      ),
    );
  }
}