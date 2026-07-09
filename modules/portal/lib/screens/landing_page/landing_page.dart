import 'dart:developer';

import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:portal/screens/home_page/widgets/home_page/recently_viewed_ads.dart';
import 'package:portal/screens/landing_page/widgets/landing_page_mobile/ai_precision_mobile_widget.dart';
import 'package:portal/screens/landing_page/widgets/landing_page_mobile/exclusive_offer_mobile_widget.dart';
import 'package:portal/screens/landing_page/widgets/landing_page_mobile/footer_mobile_widget.dart';
import 'package:portal/screens/landing_page/widgets/landing_page_mobile/header_mobile_widget.dart';
import 'package:portal/screens/landing_page/widgets/landing_page_mobile/over_mission_mobile_widget.dart';
import 'package:portal/screens/landing_page/widgets/landing_page_pc/ai_precision_widget.dart';
import 'package:portal/screens/landing_page/widgets/landing_page_pc/ask_user_widget.dart';
import 'package:portal/screens/landing_page/widgets/landing_page_pc/exclusive_offers_widget.dart';
import 'package:portal/screens/landing_page/widgets/landing_page_pc/featured_news_widget.dart';
import 'package:portal/screens/landing_page/widgets/landing_page_pc/featured_properties_widget.dart';
import 'package:portal/screens/landing_page/widgets/landing_page_pc/footer_widget.dart';
import 'package:portal/screens/landing_page/widgets/landing_page_pc/get_home_recommendations_widget.dart';
import 'package:portal/screens/landing_page/widgets/landing_page_pc/global_scroll_listener.dart';
import 'package:portal/screens/landing_page/widgets/landing_page_pc/header_widget.dart';
import 'package:portal/screens/landing_page/widgets/landing_page_pc/here_to_help_widget.dart';
import 'package:portal/screens/landing_page/widgets/landing_page_pc/map_widget.dart';
import 'package:portal/screens/landing_page/widgets/landing_page_pc/over_mission_widget.dart'
    show OverMissionWidget;
import 'package:core/platform/api_services.dart';
import 'package:core/theme/apptheme.dart';

class LandingPage extends ConsumerStatefulWidget {
  const LandingPage({super.key});

  @override
  ConsumerState<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends ConsumerState<LandingPage> with AutomaticKeepAliveClientMixin {
  final GlobalKey<SideMenuState> sideMenuKey = GlobalKey<SideMenuState>();
  final FocusNode _focusNode = FocusNode();

  static double _savedLandingOffset = 0;
  late final ScrollController _landingScrollController;

  static const double _scrollStep = 120.0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    _landingScrollController = ScrollController();

    _landingScrollController.addListener(() {
      _savedLandingOffset = _landingScrollController.offset;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_landingScrollController.hasClients && _savedLandingOffset > 0) {
        _landingScrollController.jumpTo(_savedLandingOffset);
      }
    });
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (!_landingScrollController.hasClients) return KeyEventResult.ignored;

    final pos = _landingScrollController.position;
    double target = _landingScrollController.offset;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      target = (target + _scrollStep).clamp(0.0, pos.maxScrollExtent);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      target = (target - _scrollStep).clamp(0.0, pos.maxScrollExtent);
    } else if (event.logicalKey == LogicalKeyboardKey.pageDown) {
      target = (target + pos.viewportDimension * 0.85).clamp(0.0, pos.maxScrollExtent);
    } else if (event.logicalKey == LogicalKeyboardKey.pageUp) {
      target = (target - pos.viewportDimension * 0.85).clamp(0.0, pos.maxScrollExtent);
    } else {
      return KeyEventResult.ignored;
    }

    _landingScrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
    return KeyEventResult.handled;
  }

  @override
  void dispose() {
    _landingScrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final double width = MediaQuery.of(context).size.width;
    final double dynamicPadding = width / 7;
    const double tabletPadding = 40.0;

    final bool isUserLoggedIn = ApiServices.isUserLoggedIn();
    final theme = ref.watch(themeColorsProvider);

    log('LandingPage width: ${width.toStringAsFixed(2)}');

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        onTap: _focusNode.requestFocus,
        behavior: HitTestBehavior.translucent,
        child: GlobalScrollListener(
          child: BarManager(
        appModule: AppModule.portal,
        isTopAppBarHoveroverUI: true,
        onHoverBar: OnHoverBar.agentCrm,
        enableScrool: true,
        scrollController: _landingScrollController,
        layoutTypeMobile: LayoutTypeMobile.column,
        sideMenuKey: sideMenuKey,

        childrenPc: [
          HeaderWidget(paddingDynamic: dynamicPadding),

          if (isUserLoggedIn) RecentlyViewedAds(paddingDynamic: dynamicPadding),

          ExclusiveOffersWidget(paddingDynamic: dynamicPadding),
          OverMissionWidget(paddingDynamic: dynamicPadding),
          AiPrecisionWidget(paddingDynamic: dynamicPadding),
          HereToHelpWidget(paddingDynamic: dynamicPadding),
          FeaturedPropertiesWidget(paddingDynamic: dynamicPadding),

          if (!isUserLoggedIn)
            GetHomeRecommendationsWidget(paddingDynamic: dynamicPadding),

          FeaturedNewsWidget(paddingDynamic: dynamicPadding),

          // Worth keeping as standalone if map is heavy.
          const RepaintBoundary(child: MapWidget()),

          AskUserWidget(paddingDynamic: dynamicPadding),
          FooterWidget(paddingDynamic: dynamicPadding),
        ],

        childrenTablet: [
          HeaderWidget(paddingDynamic: tabletPadding, isTablet: true),

          if (isUserLoggedIn)
            RecentlyViewedAds(paddingDynamic: tabletPadding, isTablet: true),

          ExclusiveOffersWidget(paddingDynamic: tabletPadding, isTablet: true),
          OverMissionWidget(paddingDynamic: tabletPadding, isTablet: true),
          AiPrecisionWidget(paddingDynamic: tabletPadding, isTablet: true),
          HereToHelpWidget(paddingDynamic: tabletPadding),
          FeaturedPropertiesWidget(paddingDynamic: tabletPadding),

          if (!isUserLoggedIn)
            GetHomeRecommendationsWidget(paddingDynamic: tabletPadding),

          FeaturedNewsWidget(paddingDynamic: tabletPadding),

          const RepaintBoundary(child: MapWidget()),

          AskUserWidget(paddingDynamic: tabletPadding, isTablet: true),
          FooterWidget(paddingDynamic: tabletPadding, isTablet: true),
        ],

        childrenMobile: [
          const HeaderWidgetMobile(isMobile: true),
          const SizedBox(height: 20),

          if (isUserLoggedIn)
            RecentlyViewedAds(paddingDynamic: 16, isMobile: true),

          const SizedBox(height: 50),
          const ExclusiveOffersWidgetMobile(),
          const SizedBox(height: 50),

          if (isUserLoggedIn) OverMissionWidgetMobile(theme: theme, ref: ref),

          if (isUserLoggedIn) const SizedBox(height: 50),

          const AiPrecisionWidgetMobile(),
          const SizedBox(height: 50),

          const FeaturedPropertiesWidget(paddingDynamic: 16, isMobile: true),

          if (!isUserLoggedIn)
            GetHomeRecommendationsWidget(paddingDynamic: 16, isMobile: true),

          const SizedBox(height: 50),

          const FeaturedNewsWidget(paddingDynamic: 16, isMobile: true),

          const SizedBox(height: 50),

          const RepaintBoundary(child: MapWidget(isMobile: true)),

          const FooterWidgetMobile(isMobile: true, paddingDynamic: 10),
        ],
          ),
        ),
      ),
    );
  }
}
