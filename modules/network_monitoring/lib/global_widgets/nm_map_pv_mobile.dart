import 'package:core/ui/device_type_util.dart';
import 'package:emma/screens/overlay.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:network_monitoring/models/monitoring_ads_model.dart';
import 'package:network_monitoring/screens/map/map_page.dart';
import 'package:network_monitoring/screens/map/map_state.dart';
import 'package:map/app_map_layer_service.dart';
import 'package:map/map_layer_cache_manager.dart';
import 'package:map/map_controls_panel.dart';
import 'package:map/providers.dart';
import 'package:portal/screens/feed/components/map/map_visuals.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/backgroundgradient.dart';

final nmFilteredAdsProvider = StateProvider<List<MonitoringAdsModel>>((ref) {
  return [];
});

class NmMapPvMobile extends ConsumerStatefulWidget {
  const NmMapPvMobile({
    super.key,
    required this.pageController,
  });

  final PageController pageController;

  @override
  ConsumerState<NmMapPvMobile> createState() => _NmMapPvMobileState();
}

class _NmMapPvMobileState extends ConsumerState<NmMapPvMobile>
    with AutomaticKeepAliveClientMixin {
  final ValueNotifier<bool> _refreshingLayers = ValueNotifier(false);
  Future<void> Function()? _refreshLayersHandler;

  void updateFilteredAds(List<MonitoringAdsModel> ads) {
    ref.read(nmFilteredAdsProvider.notifier).state = ads;
  }

  Future<void> _refreshMapLayers() async {
    await _refreshLayersHandler?.call();
  }

  @override
  void dispose() {
    _refreshingLayers.dispose();
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

  void _toggleDrawMode() {
    final notifier = ref.read(nmMapInteractionModeProvider.notifier);
    final current = ref.read(nmMapInteractionModeProvider);

    notifier.state = current == NmMapInteractionMode.draw
        ? NmMapInteractionMode.browse
        : NmMapInteractionMode.draw;
  }

  void _openAdsPage() {
    widget.pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final screenWidth = MediaQuery.of(context).size.width;
    final theme = ref.watch(themeColorsProvider);
    final interactionMode = ref.watch(nmMapInteractionModeProvider);
    final polygonPoints = ref.watch(nmFreehandPolygonProvider);
    final mapOverlayPalette = ref.watch(mapOverlayPaletteProvider);
    final visibleAdsCount = ref.watch(nmFilteredAdsProvider).length;

    return Container(
      decoration: BoxDecoration(
        gradient: CustomBackgroundGradients.getMainMenuBackground(
          context,
          ref,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: NetworkMonitoringMapPage(
              onFilteredAdsChanged: updateFilteredAds,
              showTopRightControls: false,
              onExposeLayerRefresh: (refresh) {
                _refreshLayersHandler = refresh;
              },
              onLayerRefreshingChanged: (value) {
                _refreshingLayers.value = value;
              },
            ),
          ),

          Positioned(
            bottom: BottomBarSize.resolve(context) + 5,
            left: 5,
            child: _NmMapPvMobileActions(
              buttonColor: mapOverlayPalette.buttonColor,
              panelColor: theme.dashboardContainer.withAlpha(235),
              interactionMode: interactionMode,
              visibleAdsCount: visibleAdsCount,
              hasPolygon: polygonPoints.length >= 3,
              refreshingLayers: _refreshingLayers,
              onToggleDrawMode: _toggleDrawMode,
              onClearSelection: () => nmClearMapSelectionKeepViewport(ref),
              onOpenLayers: _openMapSettingsOverlay,
              onOpenCache: _openMapCacheOverlay,
              onRefreshLayers: _refreshMapLayers,
              onOpenAdsPage: _openAdsPage,
            ),
          ),

          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: _NmMapToListSwipeHandle(
              width: calculateNmDynamicWidth(screenWidth),
              onOpenList: _openAdsPage,
              color: mapOverlayPalette.buttonColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _NmMapPvMobileActions extends StatelessWidget {
  const _NmMapPvMobileActions({
    required this.buttonColor,
    required this.panelColor,
    required this.interactionMode,
    required this.visibleAdsCount,
    required this.hasPolygon,
    required this.refreshingLayers,
    required this.onToggleDrawMode,
    required this.onClearSelection,
    required this.onOpenLayers,
    required this.onOpenCache,
    required this.onRefreshLayers,
    required this.onOpenAdsPage,
  });

  final Color buttonColor;
  final Color panelColor;
  final NmMapInteractionMode interactionMode;
  final int visibleAdsCount;
  final bool hasPolygon;
  final ValueListenable<bool> refreshingLayers;
  final VoidCallback onToggleDrawMode;
  final VoidCallback onClearSelection;
  final VoidCallback onOpenLayers;
  final VoidCallback onOpenCache;
  final VoidCallback onRefreshLayers;
  final VoidCallback onOpenAdsPage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _NmMapPvMobileActionButton(
          icon: interactionMode == NmMapInteractionMode.draw
              ? Icons.pan_tool_alt_rounded
              : Icons.gesture_rounded,
          tooltip: interactionMode == NmMapInteractionMode.draw
              ? 'switch_to_browse_mode'.tr
              : 'switch_to_draw_mode'.tr,
          color: buttonColor,
          backgroundColor: panelColor,
          onTap: onToggleDrawMode,
        ),
        const SizedBox(height: 8),
        ValueListenableBuilder<bool>(
          valueListenable: refreshingLayers,
          builder: (context, spinning, _) {
            return _NmMapPvMobileActionButton(
              icon: Icons.refresh_rounded,
              tooltip: 'refresh_map_layers'.tr,
              color: buttonColor,
              backgroundColor: panelColor,
              spinning: spinning,
              onTap: onRefreshLayers,
            );
          },
        ),
        const SizedBox(height: 8),
        _NmMapPvMobileActionButton(
          icon: Icons.layers_outlined,
          tooltip: 'map_layers'.tr,
          color: buttonColor,
          backgroundColor: panelColor,
          onTap: onOpenLayers,
        ),
        const SizedBox(height: 8),
        _NmMapPvMobileActionButton(
          icon: Icons.storage_rounded,
          tooltip: 'cache_management'.tr,
          color: buttonColor,
          backgroundColor: panelColor,
          onTap: onOpenCache,
        ),
        if (hasPolygon) ...[
          const SizedBox(height: 8),
          _NmMapPvMobileActionButton(
            icon: Icons.clear_rounded,
            tooltip: 'clear_drawing'.tr,
            color: buttonColor,
            backgroundColor: panelColor,
            onTap: onClearSelection,
          ),
        ],
        const SizedBox(height: 8),
        Material(
          color: panelColor,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onOpenAdsPage,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.list_alt_rounded,
                    color: buttonColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$visibleAdsCount',
                    style: TextStyle(
                      color: buttonColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NmMapPvMobileActionButton extends StatelessWidget {
  const _NmMapPvMobileActionButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.backgroundColor,
    required this.onTap,
    this.spinning = false,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final Color backgroundColor;
  final VoidCallback onTap;
  final bool spinning;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: spinning
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: color,
                      ),
                    )
                  : Icon(
                      icon,
                      color: color,
                      size: 22,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NmMapToListSwipeHandle extends StatelessWidget {
  const _NmMapToListSwipeHandle({
    required this.width,
    required this.onOpenList,
    required this.color,
  });

  final double width;
  final VoidCallback onOpenList;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onOpenList,
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity > 120) {
          onOpenList();
        }
      },
      child: Container(
        width: width,
        color: Colors.transparent,
        alignment: Alignment.centerLeft,
        child: Container(
          width: 26,
          height: 120,
          margin: const EdgeInsets.only(left: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
              colors: [
                Colors.transparent,
                Colors.black.withAlpha(22),
                Colors.black.withAlpha(38),
              ],
            ),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Icon(
            Icons.chevron_right_rounded,
            color: color.withAlpha(220),
            size: 28,
          ),
        ),
      ),
    );
  }
}

double calculateNmDynamicWidth(double screenWidth) {
  if (screenWidth <= 350) {
    return screenWidth * 0.18;
  } else if (screenWidth >= 1080) {
    return screenWidth * 0.08;
  } else {
    final factor =
        0.18 - ((screenWidth - 350) / (1080 - 350)) * (0.18 - 0.08);
    return screenWidth * factor;
  }
}
