import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/common/chrome/logo_hously.dart';
import 'package:portal/bars/appbar_map.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:latlong2/latlong.dart';
import 'package:portal/models/ad_list_view_model.dart';
import 'package:portal/pie_menu/feed.dart';
import 'package:map/map_state.dart';
import 'package:portal/screens/feed/components/map/map_visuals.dart';
import 'package:portal/screens/feed/widgets/map/map_page.dart';
import 'package:core/common/loading_widgets.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/backgroundgradient.dart';

import '../../components/browselist/widget/pc.dart';
import '../../components/cards/selected_card.dart';

import 'package:map/app_map_layer_service.dart';
import 'package:map/map_controls_panel.dart';
import 'package:map/map_layer_cache_manager.dart';
import 'package:map/providers.dart';
import 'package:emma/screens/overlay.dart';


class MapViewPcPage extends ConsumerStatefulWidget {
  const MapViewPcPage({super.key});

  @override
  ConsumerState<MapViewPcPage> createState() => _MapViewPcPageState();
}

class _MapViewPcPageState extends ConsumerState<MapViewPcPage> {
  final ScrollController scrollController = ScrollController();
  final sideMenuKey = GlobalKey<SideMenuState>();

  List<AdsListViewModel> filteredAds = [];

  void updateFilteredAds(List<AdsListViewModel> ads) {
    if (!mounted) return;
    setState(() {
      filteredAds = ads;
    });
  }

  LatLng? _calculatePolygonCenter(List<LatLng> points) {
    if (points.isEmpty) return null;

    final latSum = points.map((p) => p.latitude).reduce((a, b) => a + b);
    final lngSum = points.map((p) => p.longitude).reduce((a, b) => a + b);

    return LatLng(
      latSum / points.length,
      lngSum / points.length,
    );
  }

  double _calculatePolygonRadiusMeters(List<LatLng> points) {
    if (points.length < 2) return 0;

    final center = _calculatePolygonCenter(points);
    if (center == null) return 0;

    const distance = Distance();

    double maxDistance = 0;
    for (final point in points) {
      final current = distance.as(LengthUnit.Meter, center, point);
      if (current > maxDistance) {
        maxDistance = current;
      }
    }

    return maxDistance;
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
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final theme = ref.watch(themeColorsProvider);
    final textColor = theme.themeTextColor;
    final textFieldColor = theme.textFieldColor;
    final primaryColor = Theme.of(context).primaryColor;
    final isDefaultDarkSystem = ref.watch(isDefaultDarkSystemProvider);
    final cardType = ref.watch(selectedCardProvider);

    final polygonPoints = ref.watch(freehandPolygonProvider);
    final interactionMode = ref.watch(mapInteractionModeProvider);
    final hoveredAdId = ref.watch(hoveredMapAdIdProvider);
    final mapOverlayPalette = ref.watch(mapOverlayPaletteProvider);

    return BarManager(
      sideMenuKey: sideMenuKey,
      isTopAppBarOff: true,
      appModule: AppModule.portal,
      childPc: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    child: SizedBox(
                      width: screenWidth * 0.625,
                      height: double.infinity,
                      child: PortalMapPage(
                        onFilteredAdsChanged: updateFilteredAds,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 10,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: mapOverlayPalette.buttonColor,
                          ),
                          tooltip: 'clear_drawing'.tr,
                          onPressed: () {
                            ref.read(freehandPolygonProvider.notifier).clear();
                            ref.read(mapInteractionModeProvider.notifier).state =
                                MapInteractionMode.browse;
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            interactionMode == MapInteractionMode.draw
                                ? Icons.pan_tool_alt
                                : Icons.gesture,
                            color: mapOverlayPalette.buttonColor,
                          ),
                          tooltip: interactionMode == MapInteractionMode.draw
                              ? 'switch_to_browse_mode'.tr
                              : 'switch_to_draw_mode'.tr,
                          onPressed: () {
                            final notifier =
                                ref.read(mapInteractionModeProvider.notifier);

                            notifier.state =
                                notifier.state == MapInteractionMode.draw
                                ? MapInteractionMode.browse
                                : MapInteractionMode.draw;
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.layers_outlined,
                            color: mapOverlayPalette.buttonColor,
                          ),
                          tooltip: 'map_layers'.tr,
                          onPressed: _openMapSettingsOverlay,
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.storage_rounded,
                            color: mapOverlayPalette.buttonColor,
                          ),
                          tooltip: 'cache_management'.tr,
                          onPressed: _openMapCacheOverlay,
                        ),
                        LogoHouslyWidget(
                          textColor: mapOverlayPalette.buttonColor,
                          horizontalPadding: 20,
                          enableBackdropFilter: false,
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: screenWidth * 0.35,
                    child: const TopAppBarMap(),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    bottom: 0,
                    child: SizedBox(
                      width: screenWidth * 0.35,
                      height: screenHeight,
                      child: Material(
                        color: Colors.transparent,
                        child: Listener(
                          behavior: HitTestBehavior.opaque,
                          onPointerSignal: _handlePointerSignal,
                          child: ScrollConfiguration(
                            behavior: const MaterialScrollBehavior().copyWith(
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
                              padding: const EdgeInsets.only(
                                left: 20,
                                right: 20,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(1),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                ),
                              ),
                              child: Scrollbar(
                                controller: scrollController,
                                thumbVisibility: true,
                                child: ListView.builder(
                                  controller: scrollController,
                                  primary: false,
                                  physics: const AlwaysScrollableScrollPhysics(
                                    parent: ClampingScrollPhysics(),
                                  ),
                                  padding: const EdgeInsets.only(
                                    top: 20,
                                    bottom: 40,
                                  ),
                                  addAutomaticKeepAlives: false,
                                  cacheExtent: 300.0,
                                  itemCount: filteredAds.length,
                                  itemBuilder: (context, index) {
                                    final ad = filteredAds[index];
                                    final tag = 'mapViewPc_${ad.id}';
                                    final mainImageUrl = ad.images.isNotEmpty
                                        ? ad.images.first
                                        : 'default_image_url';
                                    final isPro = ad.isPro;
                                    final isHovered = hoveredAdId == ad.id;

                                    return MouseRegion(
                                      onEnter: (_) {
                                        ref
                                            .read(
                                              hoveredMapAdIdProvider.notifier,
                                            )
                                            .state = ad.id;
                                      },
                                      onExit: (_) {
                                        final currentHovered =
                                            ref.read(hoveredMapAdIdProvider);
                                        if (currentHovered == ad.id) {
                                          ref
                                              .read(
                                                hoveredMapAdIdProvider.notifier,
                                              )
                                              .state = null;
                                        }
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 120,
                                        ),
                                        margin: const EdgeInsets.only(
                                          bottom: 8,
                                          right: 20,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: isHovered
                                                ? Colors.greenAccent
                                                : Colors.transparent,
                                            width: isHovered ? 2 : 0,
                                          ),
                                          boxShadow: isHovered
                                              ? [
                                                  BoxShadow(
                                                    blurRadius: 16,
                                                    spreadRadius: 1,
                                                    color: Colors.greenAccent
                                                        .withAlpha(40),
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: SelectedCardWidget(
                                          isMobile: false,
                                          aspectRatio:
                                              cardType.mapAspectRatio,
                                          ad: ad,
                                          tag: tag,
                                          mainImageUrl: mainImageUrl,
                                          isPro: isPro,
                                          isDefaultDarkSystem:
                                              isDefaultDarkSystem,
                                          color: primaryColor,
                                          textColor: textColor,
                                          textFieldColor: textFieldColor,
                                          buildShimmerPlaceholder:
                                              ShimmerPlaceholder(
                                                width: screenWidth * 0.4,
                                                height:
                                                    (screenWidth * 0.4) *
                                                    (16 / 9),
                                              ),
                                          buildPieMenuActions:
                                              buildPieMenuActions(
                                                ref,
                                                ad,
                                                context,
                                              ),
                                        ),
                                      ),
                                    );
                                  },
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
          const BrowseListPcWidget(
            isWhiteSpaceNeeded: false,
          ),
        ],
      ),
    );
  }
}