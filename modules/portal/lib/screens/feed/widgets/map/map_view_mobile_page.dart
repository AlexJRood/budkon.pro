import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/common/chrome/appbar_mobile.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:emma/screens/overlay.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:map/app_map_layer_service.dart';
import 'package:map/map_layer_cache_manager.dart';
import 'package:map/map_controls_panel.dart';
import 'package:map/providers.dart';
import 'package:portal/models/ad_list_view_model.dart';
import 'package:portal/pie_menu/feed.dart';
import 'package:map/map_state.dart';
import 'package:portal/screens/feed/components/map/map_visuals.dart';
import 'package:portal/screens/feed/widgets/map/map_page.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/common/install_popup.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/backgroundgradient.dart';
import 'package:core/theme/design.dart';

class MapViewMobilePage extends ConsumerStatefulWidget {
  const MapViewMobilePage({super.key});

  @override
  ConsumerState<MapViewMobilePage> createState() => _MapViewMobilePageState();
}

class _MapViewMobilePageState extends ConsumerState<MapViewMobilePage> {
  final sideMenuKey = GlobalKey<SideMenuState>();
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  List<AdsListViewModel> filteredAds = [];
  double _sheetExtent = 0.30;

  void updateFilteredAds(List<AdsListViewModel> ads) {
    if (!mounted) return;
    setState(() {
      filteredAds = ads;
    });
  }

  void _openAd(AdsListViewModel ad) {
    final tag = 'mapViewMobile_${ad.id}';

    handleDisplayedAction(ref, ad.id, context);

    ref.read(navigationService).pushNamedScreen(
      '${Routes.mapView}/${ad.id}',
      data: {
        'tag': tag,
        'ad': ad,
      },
    );
  }

  Future<void> _toggleSheet() async {
    if (!_sheetController.isAttached) return;

    final target = _sheetExtent < 0.55 ? 0.82 : 0.20;

    await _sheetController.animateTo(
      target,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
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
    final notifier = ref.read(mapInteractionModeProvider.notifier);
    final current = ref.read(mapInteractionModeProvider);

    notifier.state = current == MapInteractionMode.draw
        ? MapInteractionMode.browse
        : MapInteractionMode.draw;
  }

  void _clearMapSelection() {
    clearMapSelectionKeepViewport(ref);
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final primaryColor = theme.dashboardContainer.withAlpha(120);
    final textColor = theme.themeTextColor;
    final textFieldColor = theme.textFieldColor;
    final backgroundColor = theme.adPopBackground;

    final interactionMode = ref.watch(mapInteractionModeProvider);
    final polygonPoints = ref.watch(freehandPolygonProvider);
    final mapOverlayPalette = ref.watch(mapOverlayPaletteProvider);

    final screenPadding = MediaQuery.of(context).size.width / 430 * 15;
    final topInset = MediaQuery.of(context).padding.top;
    final isSheetExpanded = _sheetExtent >= 0.55;
    final hasPolygon = polygonPoints.length >= 3;

    return PopupListener(
      child: BarManager(
        sideMenuKey: sideMenuKey,
        appModule: AppModule.portal,
        isTopAppBarHoveroverUI: true,
        specialAppBar: ShaderMask(
          shaderCallback: (bounds) =>
              BackgroundGradients.appBarGradient.createShader(bounds),
          child: AppBarMobile(sideMenuKey: sideMenuKey),
        ),
        childMobile: Stack(
          children: [
            Positioned.fill(
              child: PortalMapPage(
                onFilteredAdsChanged: updateFilteredAds,
              ),
            ),

            Positioned(
              top: topInset + 72,
              right: 12,
              child: _MobileMapActions(
                      buttonColor: mapOverlayPalette.buttonColor,
                      panelColor: theme.dashboardContainer.withAlpha(235),
                      interactionMode: interactionMode,
                      visibleAdsCount: filteredAds.length,
                      hasPolygon: hasPolygon,
                      isSheetExpanded: isSheetExpanded,
                      onToggleDrawMode: _toggleDrawMode,
                      onClearSelection: _clearMapSelection,
                      onOpenLayers: _openMapSettingsOverlay,
                      onOpenCache: _openMapCacheOverlay,
                      onToggleSheet: _toggleSheet,
                    ),
                  ),

                  NotificationListener<DraggableScrollableNotification>(
                    onNotification: (notification) {
                      final next = notification.extent.clamp(0.16, 0.88);
                      if ((next - _sheetExtent).abs() > 0.01 && mounted) {
                        setState(() {
                          _sheetExtent = next;
                        });
                      }
                      return false;
                    },
                    child: DraggableScrollableSheet(
                      controller: _sheetController,
                      initialChildSize: 0.30,
                      minChildSize: 0.16,
                      maxChildSize: 0.88,
                      snap: true,
                      snapSizes: const [0.16, 0.30, 0.60, 0.88],
                      builder: (context, scrollController) {
                        return _MobileAdsSheet(
                          ads: filteredAds,
                          scrollController: scrollController,
                          theme: theme,
                          backgroundColor: backgroundColor,
                          primaryColor: primaryColor,
                          textColor: textColor,
                          textFieldColor: textFieldColor,
                          horizontalPadding: screenPadding,
                          interactionMode: interactionMode,
                          isExpanded: isSheetExpanded,
                          onToggleSheet: _toggleSheet,
                          onOpenAd: _openAd,
                        );
                      },
                    ),
                  ),

          ],
        ),
      ),
    );
  }
}

class _MobileMapActions extends StatelessWidget {
  const _MobileMapActions({
    required this.buttonColor,
    required this.panelColor,
    required this.interactionMode,
    required this.visibleAdsCount,
    required this.hasPolygon,
    required this.isSheetExpanded,
    required this.onToggleDrawMode,
    required this.onClearSelection,
    required this.onOpenLayers,
    required this.onOpenCache,
    required this.onToggleSheet,
  });

  final Color buttonColor;
  final Color panelColor;
  final MapInteractionMode interactionMode;
  final int visibleAdsCount;
  final bool hasPolygon;
  final bool isSheetExpanded;
  final VoidCallback onToggleDrawMode;
  final VoidCallback onClearSelection;
  final VoidCallback onOpenLayers;
  final VoidCallback onOpenCache;
  final VoidCallback onToggleSheet;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.only(right: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Material(
            color: panelColor,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onToggleSheet,
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
                    const SizedBox(width: 6),
                    Icon(
                      isSheetExpanded
                          ? Icons.keyboard_arrow_down_rounded
                          : Icons.keyboard_arrow_up_rounded,
                      color: buttonColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _MapActionButton(
            icon: interactionMode == MapInteractionMode.draw
                ? Icons.pan_tool_alt_rounded
                : Icons.gesture_rounded,
            tooltip: interactionMode == MapInteractionMode.draw
                ? 'switch_to_browse_mode'.tr
                : 'switch_to_draw_mode'.tr,
            color: buttonColor,
            backgroundColor: panelColor,
            onTap: onToggleDrawMode,
          ),
          const SizedBox(height: 8),
          _MapActionButton(
            icon: Icons.layers_outlined,
            tooltip: 'map_layers'.tr,
            color: buttonColor,
            backgroundColor: panelColor,
            onTap: onOpenLayers,
          ),
          const SizedBox(height: 8),
          _MapActionButton(
            icon: Icons.storage_rounded,
            tooltip: 'cache_management'.tr,
            color: buttonColor,
            backgroundColor: panelColor,
            onTap: onOpenCache,
          ),
          if (hasPolygon) ...[
            const SizedBox(height: 8),
            _MapActionButton(
              icon: Icons.clear_rounded,
              tooltip: 'clear_drawing'.tr,
              color: buttonColor,
              backgroundColor: panelColor,
              onTap: onClearSelection,
            ),
          ],
        ],
      ),
    );
  }
}

class _MapActionButton extends StatelessWidget {
  const _MapActionButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.backgroundColor,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final Color backgroundColor;
  final VoidCallback onTap;

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
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileAdsSheet extends StatelessWidget {
  const _MobileAdsSheet({
    required this.ads,
    required this.scrollController,
    required this.theme,
    required this.backgroundColor,
    required this.primaryColor,
    required this.textColor,
    required this.textFieldColor,
    required this.horizontalPadding,
    required this.interactionMode,
    required this.isExpanded,
    required this.onToggleSheet,
    required this.onOpenAd,
  });

  final List<AdsListViewModel> ads;
  final ScrollController scrollController;
  final ThemeColors theme;
  final Color backgroundColor;
  final Color primaryColor;
  final Color textColor;
  final Color textFieldColor;
  final double horizontalPadding;
  final MapInteractionMode interactionMode;
  final bool isExpanded;
  final VoidCallback onToggleSheet;
  final void Function(AdsListViewModel ad) onOpenAd;

  @override
  Widget build(BuildContext context) {

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(26),
            topRight: Radius.circular(26),
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 18,
              color: Colors.black.withAlpha(35),
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            GestureDetector(
              onTap: onToggleSheet,
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 5,
                    decoration: BoxDecoration(
                      color: theme.dashboardContainer.withAlpha(120),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                left: horizontalPadding,
                right: horizontalPadding,
                bottom: 10,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      interactionMode == MapInteractionMode.draw
                          ? 'Rysowanie obszaru aktywne'
                          : 'Ogłoszenia na mapie',
                      style: AppTextStyles.interSemiBold.copyWith(
                        fontSize: 16,
                        color: theme.textColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${ads.length}',
                    style: AppTextStyles.interBold.copyWith(
                      fontSize: 15,
                      color: theme.textColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: onToggleSheet,
                    icon: Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_down_rounded
                          : Icons.keyboard_arrow_up_rounded,
                      color: theme.textColor,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ads.isEmpty
                  ? _EmptyMobileAdsState(
                      theme: theme,
                      interactionMode: interactionMode,
                    )
                  : Scrollbar(
                      controller: scrollController,
                      thumbVisibility: false,
                      child: ListView.separated(
                        controller: scrollController,
                        padding: EdgeInsets.only(
                          left: horizontalPadding,
                          right: horizontalPadding,
                          top: 2,
                          bottom: 110,
                        ),
                        physics: const ClampingScrollPhysics(),
                        itemCount: ads.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final ad = ads[index];
                          return _MobileAdCard(
                            ad: ad,
                            textColor: textColor,
                            textFieldColor: textFieldColor,
                            primaryColor: primaryColor,
                            onOpenAd: () => onOpenAd(ad),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyMobileAdsState extends StatelessWidget {
  const _EmptyMobileAdsState({
    required this.theme,
    required this.interactionMode,
  });

  final ThemeColors theme;
  final MapInteractionMode interactionMode;

  @override
  Widget build(BuildContext context) {
    final title = interactionMode == MapInteractionMode.draw
        ? 'Narysuj obszar na mapie'
        : 'Brak ogłoszeń w tym widoku';

    final subtitle = interactionMode == MapInteractionMode.draw
        ? 'Po zakończeniu rysowania lista odświeży się automatycznie.'
        : 'Przesuń mapę, przybliż widok albo zmień warstwy i filtry.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              interactionMode == MapInteractionMode.draw
                  ? Icons.gesture_rounded
                  : Icons.map_outlined,
              size: 34,
              color: theme.textColor.withAlpha(170),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.interSemiBold.copyWith(
                color: theme.textColor,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.interRegular.copyWith(
                color: theme.textColor.withAlpha(170),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileAdCard extends ConsumerWidget {
  const _MobileAdCard({
    required this.ad,
    required this.textColor,
    required this.textFieldColor,
    required this.primaryColor,
    this.isDefaultDarkSystem = true,
    required this.onOpenAd,
  });

  final AdsListViewModel ad;
  final Color textColor;
  final Color textFieldColor;
  final Color primaryColor;
  final bool isDefaultDarkSystem;
  final VoidCallback onOpenAd;

  String _locationLine(AdsListViewModel ad) {
    final parts = <String>[
      if (ad.city.trim().isNotEmpty) ad.city.trim(),
      if (ad.street.trim().isNotEmpty) ad.street.trim(),
    ];
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tag = 'mapViewMobile_${ad.id}';
    final mainImageUrl =
        ad.images.isNotEmpty ? ad.images.first : 'default_image_url';

    final overlayColor = isDefaultDarkSystem
        ? textFieldColor.withAlpha(180)
        : primaryColor.withAlpha(180);

    return AspectRatio(
      aspectRatio: 16 / 10,
      child: PieMenu(
        theme: PieTheme.of(context).copyWith(
          overlayColor: (textColor.computeLuminance() > 0.5
                  ? Colors.black
                  : Colors.white)
              .withAlpha(180),
        ),
        onPressedWithDevice: (kind) {
          if (kind == PointerDeviceKind.mouse ||
              kind == PointerDeviceKind.touch ||
              kind == PointerDeviceKind.stylus ||
              kind == PointerDeviceKind.unknown) {
            onOpenAd();
          }
        },
        actions: buildPieMenuActions(ref, ad, context),
        child: Hero(
          tag: tag,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: ad.isPro
                  ? Border.all(color: Colors.white, width: 4)
                  : null,
              boxShadow: [
                BoxShadow(
                  blurRadius: 10,
                  color: Colors.black.withAlpha(20),
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    mainImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey,
                      alignment: Alignment.center,
                      child: Text(
                        'no_image'.tr,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  if (ad.isPro)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.light,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Sponsored'.tr,
                          style: AppTextStyles.interMedium12dark,
                        ),
                      ),
                    ),
                  Positioned(
                    left: 8,
                    right: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: overlayColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${NumberFormat.decimalPattern().format(ad.price)} ${ad.currency}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.interBold.copyWith(
                              fontSize: 18,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ad.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.interSemiBold.copyWith(
                              color: textColor,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _locationLine(ad),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.interRegular.copyWith(
                              fontSize: 12,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}