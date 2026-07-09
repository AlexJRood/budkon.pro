// ignore_for_file: use_build_context_synchronously, unused_import

import 'dart:async';

import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/common/chrome/logo_hously.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:core/dndservice/models/dnd_payload.dart';
import 'package:core/dndservice/models/dnd_payload_type.dart';
import 'package:core/dndservice/widgets/dnd_sender.dart';
import 'package:core/dndservice/widgets/drag_feedback_builders.dart';
import 'package:emma/screens/overlay.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:latlong2/latlong.dart';
import 'package:network_monitoring/browselist/widget/pc.dart';
import 'package:network_monitoring/components/cards/selected_card.dart';
import 'package:network_monitoring/emma/anchors/anchors_nm.dart';
import 'package:network_monitoring/models/monitoring_ads_model.dart';
import 'package:network_monitoring/pie_menu/network_monitoring.dart';
import 'package:network_monitoring/providers/search_page/filters_provider.dart';
import 'package:network_monitoring/screens/map/map_page.dart';
import 'package:network_monitoring/screens/map/map_state.dart';
import 'package:network_monitoring/screens/network_home_page/widgets/network_home_filter_pop_widget.dart';
import 'package:portal/feed/components/view/slected_view_provider.dart';
import 'package:map/app_map_layer_service.dart';
import 'package:map/map_controls_panel.dart';
import 'package:map/map_layer_cache_manager.dart';
import 'package:map/providers.dart';
import 'package:portal/screens/feed/components/map/map_visuals.dart';
import 'package:portal/screens/filters/widgets/sort_feed.dart';
import 'package:core/common/loading_widgets.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/backgroundgradient.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';
import 'package:core/theme/lottie.dart';

class NetworkMonitoringMapViewPcPage extends ConsumerStatefulWidget {
  const NetworkMonitoringMapViewPcPage({super.key});

  @override
  ConsumerState<NetworkMonitoringMapViewPcPage> createState() =>
      _NetworkMonitoringMapViewPcPageState();
}

class _NetworkMonitoringMapViewPcPageState
    extends ConsumerState<NetworkMonitoringMapViewPcPage> {
  static const int _pageSize = 20;

  final ScrollController scrollController = ScrollController();
  final sideMenuKey = GlobalKey<SideMenuState>();

  final PagingController<int, MonitoringAdsModel> _pagingController =
      PagingController(firstPageKey: 1);

  Timer? _refreshDebounce;

  ProviderSubscription<dynamic>? _viewportSub;
  ProviderSubscription<dynamic>? _filtersSub;
  ProviderSubscription<dynamic>? _pinsRefreshSub;

  void updateFilteredAds(List<MonitoringAdsModel> ads) {
    // Kept for compatibility with NetworkMonitoringMapPage callback.
  }

  Map<String, dynamic> _buildSpatialQuery() {
    final viewport = ref.read(nmMapViewportProvider);
    final query = <String, dynamic>{};

    if (viewport.bbox != null && viewport.bbox!.trim().isNotEmpty) {
      query['bbox'] = viewport.bbox!;
    }

    if (viewport.polygon.length >= 3) {
      query['polygon'] = viewport.polygon
          .map((p) => '${p.latitude},${p.longitude}')
          .join('|');
    }

    return query;
  }

  void _scheduleRefresh() {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      if (scrollController.hasClients) {
        scrollController.jumpTo(0);
      }

      _pagingController.refresh();
    });
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final spatialQuery = _buildSpatialQuery();

      final advertisements = await ref
          .read(networkMonitoringFilterProvider.notifier)
          .fetchAdvertisementsNM(
            pageKey,
            _pageSize,
            extraQueryParameters: spatialQuery,
          );

      if (!mounted) return;

      if (advertisements.isEmpty) {
        _pagingController.appendLastPage(const <MonitoringAdsModel>[]);
        return;
      }

      final isLastPage = advertisements.length < _pageSize;

      if (isLastPage) {
        _pagingController.appendLastPage(advertisements);
      } else {
        _pagingController.appendPage(advertisements, pageKey + 1);
      }
    } catch (error) {
      if (!mounted) return;
      _pagingController.error = error;
    }
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    if (!scrollController.hasClients) return;

    final position = scrollController.position;
    final targetOffset = (scrollController.offset + event.scrollDelta.dy).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );

    scrollController.jumpTo(targetOffset.toDouble());
  }

  @override
  void initState() {
    super.initState();

    _pagingController.addPageRequestListener(_fetchPage);

    _viewportSub = ref.listenManual(
      nmMapViewportProvider,
      (prev, next) => _scheduleRefresh(),
      fireImmediately: false,
    );

    _filtersSub = ref.listenManual(
      networkMonitoringMapFiltersProvider,
      (prev, next) => _scheduleRefresh(),
      fireImmediately: false,
    );

    _pinsRefreshSub = ref.listenManual(
      nmMapPinsRefreshTriggerProvider,
      (prev, next) => _scheduleRefresh(),
      fireImmediately: false,
    );
  }

  @override
  void dispose() {
    _refreshDebounce?.cancel();
    _viewportSub?.close();
    _filtersSub?.close();
    _pinsRefreshSub?.close();
    _pagingController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void _openMapSettingsOverlay() {
    final theme = ref.read(themeColorsProvider);
    final container = ProviderScope.containerOf(context, listen: false);

    showGenericAiSheet(
      context: context,
      theme: theme,
      title: 'map_layers'.tr,
      child: const PortalMapControlsPanel(),
      useScroll: false,
      cancelRow: false,
      container: container,
    );
  }

  void _openMapCacheOverlay() {
    final theme = ref.read(themeColorsProvider);
    final container = ProviderScope.containerOf(context, listen: false);

    final services = <AppMapLayerService>[
      ref.read(streetLayerServiceProvider),
      ref.read(parcelLayerServiceProvider),
      ref.read(mpzpLayerServiceProvider),
      ref.read(gesutLayerServiceProvider),
    ];

    showGenericAiSheet(
      context: context,
      theme: theme,
      title: 'map_cache_manager'.tr,
      child: MapLayerCacheManagerPanel(
        theme: theme,
        services: services,
      ),
      useScroll: false,
      cancelRow: false,
      container: container,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final theme = ref.watch(themeColorsProvider);
    final mapOverlayPalette = ref.watch(mapOverlayPaletteProvider);
    final interactionMode = ref.watch(nmMapInteractionModeProvider);
    final hoveredAdId = ref.watch(nmHoveredMapAdIdProvider);
    final cardProvider = ref.watch(selectedCardProviderNM);
    final count = ref.watch(networkMonitoringTotalCountProvider);
    final rightPanelWidth = (screenWidth * 0.35).clamp(320.0, 500.0);
    final bool isTablet = screenWidth > 650 && screenWidth <= 1800;
    final cardHeight =
        ((rightPanelWidth - 60) / cardProvider.aspectRatio).clamp(220.0, 420.0);
    debugPrint("Screen Width: $screenWidth");

    Widget buildTabletView(
        BuildContext context,
        WidgetRef ref,
        double screenWidth,
        double screenHeight,
        theme,
        int count,
        ) {
      final mapOverlayPalette = ref.watch(mapOverlayPaletteProvider);
      final interactionMode = ref.watch(nmMapInteractionModeProvider);
      final cardProvider = ref.watch(selectedCardProviderNM);

      final rightPanelWidth = screenWidth * 0.35;
      final cardHeight =
      ((rightPanelWidth - 60) / cardProvider.aspectRatio)
          .clamp(220.0, 420.0);

      return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: CustomBackgroundGradients.backgroundGradientRight1(
                context,
                ref,
              ),
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  child: SizedBox(
                    width: screenWidth * 0.65,
                    height: double.infinity,
                    child: NetworkMonitoringMapPage(
                      onFilteredAdsChanged: updateFilteredAds,
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: rightPanelWidth + 10,
                  left: 10,
                  child: Column(
                    children: [

                      // 🔹 ROW 1
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: theme.dashboardContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const DropdownSortSelector(
                                isNetworkMonitoring: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                          ElevatedButton(
                            style: elevatedButtonStyleRounded10withoutPadding,
                            onPressed: () {
                              Navigator.of(context).push(
                                PageRouteBuilder(
                                  opaque: false,
                                  pageBuilder: (_, __, ___) =>
                                      NetworkHomeFilterPopWidget(
                                        needNavigate: false,
                                      ),
                                  transitionsBuilder: (_, anim, __, child) {
                                    return FadeTransition(
                                      opacity: anim,
                                      child: child,
                                    );
                                  },
                                ),
                              );
                            },
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: theme.dashboardContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Row(
                                children: [
                                  AppIcons.filterAlt(color: theme.textColor),
                                  const SizedBox(width: 8),
                                  Text(
                                    'All filters'.tr,
                                    style: AppTextStyles.interMedium12dark.copyWith(
                                      color: theme.textColor,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            height: 40,
                            padding:
                            const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: theme.dashboardContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text("$count ${'ads found'.tr}",
                                style: TextStyle(
                                color: theme.textColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),),
                            ),
                          ),
                          const SizedBox(width: 4),

                          const MapFeedToggleSelector(
                            currentView: FeedMapViewMode.map,
                            feedRoute: '/network-monitoring',
                            mapRoute: '/network-monitoring/map',
                          ),

                          const Spacer(),

                          const SizedBox(
                            height: 40,
                            child: CardTypeSelector(
                              isNetworkMonitoring: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: Icon(Icons.clear,
                            color: mapOverlayPalette.buttonColor),
                        onPressed: () {
                          nmClearMapSelectionKeepViewport(ref);
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          interactionMode == NmMapInteractionMode.draw
                              ? Icons.pan_tool_alt
                              : Icons.gesture,
                          color: mapOverlayPalette.buttonColor,
                        ),
                        onPressed: () {
                          final notifier = ref.read(
                              nmMapInteractionModeProvider.notifier);
                          notifier.state =
                          notifier.state == NmMapInteractionMode.draw
                              ? NmMapInteractionMode.browse
                              : NmMapInteractionMode.draw;
                        },
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  bottom: 0,
                  child: SizedBox(
                    width: rightPanelWidth,
                    child: Container(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: theme.dashboardContainer.withAlpha(245),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 60), // space for header

                          Expanded(
                            child: PagedListView<int, MonitoringAdsModel>(
                              pagingController: _pagingController,
                              scrollController: scrollController,
                              builderDelegate:
                              PagedChildBuilderDelegate<
                                  MonitoringAdsModel>(
                                itemBuilder: (context, ad, index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                        bottom: 12),
                                    child: _MapSideAdCard(
                                      ad: ad,
                                      cardHeight: cardHeight,
                                      isHovered: false,
                                      isTablet: isTablet,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        BrowseListNetworkMonitoringPcWidget(
          isWhiteSpaceNeeded: false,
        ),
      ],
      );
    }
    return EmmaUiAnchorTarget(
      // @emma-backend: NetworkMonitoringEmmaAnchors.mapRoot
      anchorKey: 'network_monitoring.map.root',
      child: BarManager(
        sideMenuKey: sideMenuKey,
        isTopAppBarOff: true,
        appModule: AppModule.networkMonitoring,
      childTablet: buildTabletView(
        context,
        ref,
        screenWidth,
        screenHeight,
        theme,
        count,
      ),
        childPc: Row(
          children: [
            Expanded(
              child: Container(
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: CustomBackgroundGradients.backgroundGradientRight1(
                    context,
                    ref,
                  ),
                ),
                child: Stack(
                  children: [
                    EmmaUiAnchorTarget(
                      // @emma-backend: NetworkMonitoringEmmaAnchors.mapCanvas
                      anchorKey: 'network_monitoring.map.canvas',
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                        child: SizedBox(
                          width: screenWidth * 0.65,
                          height: double.infinity,
                          child: NetworkMonitoringMapPage(
                            onFilteredAdsChanged: updateFilteredAds,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: rightPanelWidth + 10,
                      left: 10,
                      child: EmmaUiAnchorTarget(
                        // @emma-backend: NetworkMonitoringEmmaAnchors.mapTopToolbar
                        anchorKey: 'network_monitoring.map.top_toolbar',
                        child: Row(
                          spacing: 10,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            EmmaUiAnchorTarget(
                              // @emma-backend: NetworkMonitoringEmmaAnchors.mapSortSelector
                              anchorKey:
                                  'network_monitoring.map.sort_selector',
                              child: Container(
                                decoration: BoxDecoration(
                                  color: theme.dashboardContainer,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                width: 200,
                                height: 40,
                                child: const DropdownSortSelector(
                                  isNetworkMonitoring: true,
                                ),
                              ),
                            ),
                            EmmaUiAnchorTarget(
                              // @emma-backend: NetworkMonitoringEmmaAnchors.mapFiltersButton
                              anchorKey:
                                  'network_monitoring.map.filters_button',
                              child: ElevatedButton(
                                style:
                                    elevatedButtonStyleRounded10withoutPadding,
                                onPressed: () {
                                  Navigator.of(context).push(
                                    PageRouteBuilder(
                                      opaque: false,
                                      pageBuilder: (_, __, ___) =>
                                          NetworkHomeFilterPopWidget(
                                        needNavigate: false,
                                      ),
                                      transitionsBuilder:
                                          (_, anim, __, child) {
                                        return FadeTransition(
                                          opacity: anim,
                                          child: child,
                                        );
                                      },
                                    ),
                                  );
                                },
                                child: Container(
                                  height: 40.h,
                                  decoration: BoxDecoration(
                                    color: theme.dashboardContainer,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      AppIcons.filterAlt(
                                        color: theme.textColor,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'All filters'.tr,
                                        style: AppTextStyles.interMedium12dark
                                            .copyWith(
                                          color: theme.textColor,
                                          fontSize: 12.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const Spacer(),
                            EmmaUiAnchorTarget(
                              // @emma-backend: NetworkMonitoringEmmaAnchors.mapResultsCount
                              anchorKey:
                                  'network_monitoring.map.results_count',
                              child: Container(
                                decoration: BoxDecoration(
                                  color: theme.dashboardContainer,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                height: 40,
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    child: Text(
                                      "$count ${'ads found'.tr}",
                                      style: TextStyle(
                                        color: theme.textColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const EmmaUiAnchorTarget(
                              // @emma-backend: NetworkMonitoringEmmaAnchors.mapFeedToggle
                              anchorKey: 'network_monitoring.map.feed_toggle',
                              child: MapFeedToggleSelector(
                                currentView: FeedMapViewMode.map,
                                feedRoute: '/network-monitoring',
                                mapRoute: '/network-monitoring/map',
                              ),
                            ),
                            const EmmaUiAnchorTarget(
                              // @emma-backend: NetworkMonitoringEmmaAnchors.mapCardTypeSelector
                              anchorKey:
                                  'network_monitoring.map.card_type_selector',
                              child: SizedBox(
                                height: 40,
                                child: CardTypeSelector(
                                  isNetworkMonitoring: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 10,
                      child: EmmaUiAnchorTarget(
                        // @emma-backend: NetworkMonitoringEmmaAnchors.mapDrawingControls
                        anchorKey: 'network_monitoring.map.drawing_controls',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            EmmaUiAnchorTarget(
                              // @emma-backend: NetworkMonitoringEmmaAnchors.mapClearDrawingButton
                              anchorKey:
                                  'network_monitoring.map.clear_drawing_button',
                              child: IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: mapOverlayPalette.buttonColor,
                                ),
                                tooltip: 'clear_drawing'.tr,
                                onPressed: () {
                                  nmClearMapSelectionKeepViewport(ref);
                                },
                              ),
                            ),
                            EmmaUiAnchorTarget(
                              // @emma-backend: NetworkMonitoringEmmaAnchors.mapDrawModeButton
                              anchorKey:
                                  'network_monitoring.map.draw_mode_button',
                              child: IconButton(
                                icon: Icon(
                                  interactionMode == NmMapInteractionMode.draw
                                      ? Icons.pan_tool_alt
                                      : Icons.gesture,
                                  color: mapOverlayPalette.buttonColor,
                                ),
                                tooltip:
                                    interactionMode == NmMapInteractionMode.draw
                                        ? 'switch_to_browse_mode'.tr
                                        : 'switch_to_draw_mode'.tr,
                                onPressed: () {
                                  final notifier = ref.read(
                                    nmMapInteractionModeProvider.notifier,
                                  );

                                  notifier.state =
                                      notifier.state ==
                                              NmMapInteractionMode.draw
                                          ? NmMapInteractionMode.browse
                                          : NmMapInteractionMode.draw;
                                },
                              ),
                            ),
                            EmmaUiAnchorTarget(
                              // @emma-backend: NetworkMonitoringEmmaAnchors.mapLayersButton
                              anchorKey:
                                  'network_monitoring.map.layers_button',
                              child: IconButton(
                                icon: Icon(
                                  Icons.layers_outlined,
                                  color: mapOverlayPalette.buttonColor,
                                ),
                                tooltip: 'map_layers'.tr,
                                onPressed: _openMapSettingsOverlay,
                              ),
                            ),
                            EmmaUiAnchorTarget(
                              // @emma-backend: NetworkMonitoringEmmaAnchors.mapCacheButton
                              anchorKey: 'network_monitoring.map.cache_button',
                              child: IconButton(
                                icon: Icon(
                                  Icons.storage_rounded,
                                  color: mapOverlayPalette.buttonColor,
                                ),
                                tooltip: 'cache_management'.tr,
                                onPressed: _openMapCacheOverlay,
                              ),
                            ),
                            LogoHouslyWidget(
                              textColor: mapOverlayPalette.buttonColor,
                              horizontalPadding: 20,
                              enableBackdropFilter: false,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      bottom: 0,
                      child: EmmaUiAnchorTarget(
                        // @emma-backend: NetworkMonitoringEmmaAnchors.mapSidePanel
                        anchorKey: 'network_monitoring.map.side_panel',
                        child: SizedBox(
                          width: rightPanelWidth,
                          height: screenHeight,
                          child: Material(
                            color: Colors.transparent,
                            child: Listener(
                              behavior: HitTestBehavior.opaque,
                              onPointerSignal: _handlePointerSignal,
                              child: ScrollConfiguration(
                                behavior:
                                    const MaterialScrollBehavior().copyWith(
                                  dragDevices: {
                                    PointerDeviceKind.touch,
                                    PointerDeviceKind.mouse,
                                    PointerDeviceKind.trackpad,
                                    PointerDeviceKind.stylus,
                                    PointerDeviceKind.unknown,
                                  },
                                  scrollbars: false,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        theme.dashboardContainer.withAlpha(245),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(20),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      EmmaUiAnchorTarget(
                                        // @emma-backend: NetworkMonitoringEmmaAnchors.mapSidePanelHeader
                                        anchorKey:
                                            'network_monitoring.map.side_panel_header',
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            top: 20,
                                            bottom: 12,
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  '$count ${'ads found'.tr}',
                                                  style: TextStyle(
                                                    color: theme.textColor,
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(
                                                height: 40,
                                                child: CardTypeSelector(
                                                  isNetworkMonitoring: true,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: EmmaUiAnchorTarget(
                                          // @emma-backend: NetworkMonitoringEmmaAnchors.mapSideResultsList
                                          anchorKey:
                                              'network_monitoring.map.side_results_list',
                                          child: Scrollbar(
                                            controller: scrollController,
                                            thumbVisibility: true,
                                            child: PagedListView<int,
                                                MonitoringAdsModel>(
                                              pagingController:
                                                  _pagingController,
                                              scrollController:
                                                  scrollController,
                                              primary: false,
                                              physics:
                                                  const AlwaysScrollableScrollPhysics(
                                                parent:
                                                    ClampingScrollPhysics(),
                                              ),
                                              padding: const EdgeInsets.only(
                                                top: 4,
                                                bottom: 40,
                                              ),
                                              builderDelegate:
                                                  PagedChildBuilderDelegate<
                                                      MonitoringAdsModel>(
                                                itemBuilder:
                                                    (context, ad, index) {
                                                  final isHovered =
                                                      hoveredAdId == ad.id;

                                                  return EmmaUiAnchorTarget(
                                                    // @emma-backend: NetworkMonitoringEmmaAnchors.mapSideCard
                                                    anchorKey:
                                                        'network_monitoring.map.side_card.${ad.id}',
                                                    child: MouseRegion(
                                                      onEnter: (_) {
                                                        ref
                                                            .read(
                                                              nmHoveredMapAdIdProvider
                                                                  .notifier,
                                                            )
                                                            .state = ad.id;
                                                      },
                                                      onExit: (_) {
                                                        final currentHovered =
                                                            ref.read(
                                                          nmHoveredMapAdIdProvider,
                                                        );

                                                        if (currentHovered ==
                                                            ad.id) {
                                                          ref
                                                              .read(
                                                                nmHoveredMapAdIdProvider
                                                                    .notifier,
                                                              )
                                                              .state = null;
                                                        }
                                                      },
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(
                                                          bottom: 12,
                                                          right: 8,
                                                        ),
                                                        child: _MapSideAdCard(
                                                          ad: ad,
                                                          cardHeight:
                                                              cardHeight,
                                                          isHovered: isHovered,
                                                          isTablet: isTablet,
                                                        ),
                                                        
                                                ),
                                                    ),
                                                  );
                                                },
                                                firstPageProgressIndicatorBuilder:
                                                    (_) => _MapCardShimmerList(
                                                  cardHeight: cardHeight,
                                                  count: 3,
                                                ),
                                                newPageProgressIndicatorBuilder:
                                                    (_) => _MapCardShimmerList(
                                                  cardHeight: cardHeight,
                                                  count: 1,
                                                ),
                                                noItemsFoundIndicatorBuilder:
                                                    (_) => EmmaUiAnchorTarget(
                                                  // @emma-backend: NetworkMonitoringEmmaAnchors.mapNoResults
                                                  anchorKey:
                                                      'network_monitoring.map.no_results',
                                                  child: Center(
                                                    child:
                                                        AppLottie.noResults(
                                                      size: 320,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            EmmaUiAnchorTarget(
              // @emma-backend: NetworkMonitoringEmmaAnchors.mapBrowseList
              anchorKey: 'network_monitoring.map.browse_list',
              child: BrowseListNetworkMonitoringPcWidget(
                isWhiteSpaceNeeded: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapSideAdCard extends ConsumerWidget {
  const _MapSideAdCard({
    required this.ad,
    required this.cardHeight,
    required this.isHovered,
    required this.isTablet,
  });

  final MonitoringAdsModel ad;
  final double cardHeight;
  final bool isHovered;
  final bool isTablet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themecolors = ref.watch(themeColorsProvider);
    final currentThemeMode = ref.watch(themeProvider);
    final textFieldColor =
        currentThemeMode == ThemeMode.system ? Colors.black : Colors.white;
    final textColor = themecolors.themeTextColor;
    final color = Theme.of(context).primaryColor;
    final isDefaultDarkSystem = ref.watch(isDefaultDarkSystemProvider);

    final tag = 'networkAd_${ad.id}';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      height: cardHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isHovered ? Colors.greenAccent : Colors.transparent,
          width: isHovered ? 2 : 1,
        ),
        boxShadow: isHovered
            ? [
                BoxShadow(
                  blurRadius: 14,
                  color: Colors.greenAccent.withAlpha(70),
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: DndSender(
          payload: DndPayload(
            action: 'add_to_favorites',
            type: DndPayloadType.nm_ad,
            id: ad.id.toString(),
            data: {
              'advertisement': ad.id,
              'advertisement_id': ad.id,
              'title': ad.title,
              'source': 'network_monitoring',
            },
          ),
          feedbackBuilder: (context) => DragFeedbackBuilders.nmAdFeedback(
            context,
            ad.title ?? 'Property Ad',
          ),
          child: SelectedCardWidgetNM(
            isMobile: false,
            isTablet: isTablet,
            aspectRatio: ref.watch(selectedCardProviderNM).aspectRatio,
            ad: ad,
            tag: tag,
            mainImageUrl: ad.mainImageUrl,
            isPro: ad.isPro,
            isDefaultDarkSystem: isDefaultDarkSystem,
            color: color,
            textColor: textColor,
            textFieldColor: textFieldColor,
            buildShimmerPlaceholder: _MapCardShimmerPlaceholder(
              cardHeight: cardHeight,
            ),
            buildPieMenuActions: buildPieMenuActionsNM(
              ref,
              ad,
              context,
              null,
              null,
            ),
          ),
        ),
      ),
    );
  }
}

class _MapCardShimmerPlaceholder extends StatelessWidget {
  const _MapCardShimmerPlaceholder({
    required this.cardHeight,
  });

  final double cardHeight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: cardHeight,
      width: double.infinity,
      child: const ShimmerAdvertisementGrid(crossAxisCount: 1),
    );
  }
}

class _MapCardShimmerList extends StatelessWidget {
  const _MapCardShimmerList({
    required this.cardHeight,
    required this.count,
  });

  final double cardHeight;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        count,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: 12, right: 8),
          child: _MapCardShimmerPlaceholder(cardHeight: cardHeight),
        ),
      ),
    );
  }
}