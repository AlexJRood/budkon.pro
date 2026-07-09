import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:intl/intl.dart';
import 'package:portal/browselist/components/card.dart';
import 'package:portal/models/ad_list_view_model.dart';
import 'package:map/map_state.dart';
import 'package:portal/screens/feed/widgets/map/map_page.dart';
import 'package:portal/screens/home_page/providers/listing_provider.dart';
import 'package:core/common/drad_scroll_widget.dart';
import 'package:core/common/loading_widgets.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';

class MapWidget extends ConsumerStatefulWidget {
  final bool haveAds;
  final bool isMobile;

  const MapWidget({
    super.key,
    this.haveAds = true,
    this.isMobile = false,
  });

  @override
  ConsumerState<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends ConsumerState<MapWidget> {
  final ScrollController _scrollController = ScrollController();
  final NumberFormat customFormat = NumberFormat.decimalPattern('fr');

  List<AdsListViewModel> filteredAds = [];
  bool _hasMapDrivenResults = false;
  bool _isMapActive = false;

  void updateFilteredAds(List<AdsListViewModel> ads) {
    if (!mounted) return;
    setState(() {
      filteredAds = ads;
      _hasMapDrivenResults = true;
    });
  }

  void _activateMap() {
    if (!mounted) return;

    setState(() {
      _isMapActive = true;
    });

    // Refresh pins after the map becomes active and rebuild completes.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      refreshMapPins(ref);
    });
  }

  void _deactivateMap() {
    if (!mounted) return;

    ref.read(mapInteractionModeProvider.notifier).state =
        MapInteractionMode.browse;
    ref.read(freehandPolygonProvider.notifier).clear();

    setState(() {
      _isMapActive = false;
      _hasMapDrivenResults = false;
      filteredAds = [];
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      refreshMapPins(ref);
    });
  }

  void _setBrowseMode() {
    ref.read(mapInteractionModeProvider.notifier).state =
        MapInteractionMode.browse;
  }

  void _setDrawMode() {
    ref.read(mapInteractionModeProvider.notifier).state =
        MapInteractionMode.draw;
  }

  void _clearSelectionFilter() {
    ref.read(freehandPolygonProvider.notifier).clear();
    ref.read(mapInteractionModeProvider.notifier).state =
        MapInteractionMode.browse;

    setState(() {
      _hasMapDrivenResults = false;
      filteredAds = [];
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      refreshMapPins(ref);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _buildStatusText({
    required bool hasPolygonFilter,
    required MapInteractionMode interactionMode,
  }) {
    if (hasPolygonFilter) {
      return 'filter_active'.tr;
    }
    if (interactionMode == MapInteractionMode.draw) {
      return 'draw_mode'.tr;
    }
    return 'map_active'.tr;
  }

  @override
  Widget build(BuildContext context) {
    final listingsAsyncValue = ref.watch(listingsProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final itemWidth = max(150.0, min(screenWidth / 1500 * 240, 250.0));
    final itemHeight = itemWidth * (300 / 260);
    final theme = ref.watch(themeColorsProvider);
    final polygonPoints = ref.watch(freehandPolygonProvider);
    final interactionMode = ref.watch(mapInteractionModeProvider);

    final bool hasPolygonFilter = polygonPoints.length >= 3;

    final double collapsedHeight = widget.haveAds ? 550 : 180;
    final double expandedHeight = widget.isMobile
        ? (screenHeight * 0.55).clamp(360.0, 520.0)
        : (screenHeight * 0.50).clamp(420.0, 560.0);

    final double currentHeight = _isMapActive ? expandedHeight : collapsedHeight;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      height: currentHeight,
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedScale(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              scale: 1,
              child: PortalMapPage(
                isInteractive: _isMapActive,
                isToggle: true,
                onFilteredAdsChanged: updateFilteredAds,
              ),
            ),
          ),

          if (!_isMapActive)
            Positioned.fill(
              child: Material(
                color: Colors.black.withAlpha(140),
                child: InkWell(
                  onTap: _activateMap,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 18,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.touch_app,
                            size: 48,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'click_to_activate_map'.tr,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'after_activation_you_can_move_map_and_draw_selection'.tr,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withAlpha(220),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          if (_isMapActive)
            Positioned(
              top: 12,
              left: 12,
              right: widget.haveAds && !widget.isMobile ? 370 : 12,
              child: SafeArea(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: widget.isMobile ? 6 : 10,
                      vertical: widget.isMobile ? 6 : 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(145),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withAlpha(55),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: widget.isMobile ? 8 : 10,
                            vertical: widget.isMobile ? 6 : 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(18),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withAlpha(35),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                hasPolygonFilter
                                    ? Icons.filter_alt_rounded
                                    : interactionMode == MapInteractionMode.draw
                                        ? Icons.gesture_rounded
                                        : Icons.map_rounded,
                                size: widget.isMobile ? 14 : 16,
                                color: Colors.white,
                              ),
                              SizedBox(width: widget.isMobile ? 4 : 6),
                              Text(
                                _buildStatusText(
                                  hasPolygonFilter: hasPolygonFilter,
                                  interactionMode: interactionMode,
                                ),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: widget.isMobile ? 11 : null,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: widget.isMobile ? 4 : 8),
                        _MapActionButton(
                          icon: Icons.pan_tool_alt_rounded,
                          tooltip: 'browse_mode'.tr,
                          selected: interactionMode == MapInteractionMode.browse,
                          onPressed: _setBrowseMode,
                          isMobile: widget.isMobile,
                        ),
                        SizedBox(width: widget.isMobile ? 4 : 6),
                        _MapActionButton(
                          icon: Icons.gesture_rounded,
                          tooltip: 'draw_selection'.tr,
                          selected: interactionMode == MapInteractionMode.draw,
                          onPressed: _setDrawMode,
                          isMobile: widget.isMobile,
                        ),
                        SizedBox(width: widget.isMobile ? 4 : 6),
                        _MapActionButton(
                          icon: Icons.auto_fix_high_rounded,
                          tooltip: hasPolygonFilter
                              ? 'selection_filter_active'.tr
                              : 'no_active_selection'.tr,
                          selected: hasPolygonFilter,
                          onPressed:
                              hasPolygonFilter ? _setBrowseMode : _setDrawMode,
                          isMobile: widget.isMobile,
                        ),
                        SizedBox(width: widget.isMobile ? 4 : 6),
                        _MapActionButton(
                          icon: Icons.clear_rounded,
                          tooltip: 'clear_selection'.tr,
                          onPressed: _clearSelectionFilter,
                          isMobile: widget.isMobile,
                        ),
                        SizedBox(width: widget.isMobile ? 6 : 8),
                        _MapActionButton(
                          icon: Icons.close_fullscreen_rounded,
                          tooltip: 'close_active_map'.tr,
                          onPressed: _deactivateMap,
                          backgroundColor: theme.themeColor,
                          borderColor: Colors.white,
                          isMobile: widget.isMobile,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          if (widget.haveAds)
            Positioned(
              right: widget.isMobile ? 0 : 10,
              bottom: widget.isMobile ? 10 : 0,
              child: SizedBox(
                height: widget.isMobile ? 120 : currentHeight,
                width: widget.isMobile ? screenWidth : 350,
                child: listingsAsyncValue.when(
                  data: (ads) {
                    final effectiveAds =
                        (_hasMapDrivenResults || hasPolygonFilter) ? filteredAds : ads;

                    if (effectiveAds.isEmpty && !hasPolygonFilter) {
                      return const SizedBox.shrink();
                    }

                    if (effectiveAds.isEmpty && hasPolygonFilter) {
                      return Container(
                        margin: EdgeInsets.only(
                          top: widget.isMobile ? 0 : 10,
                        ),
                        decoration: BoxDecoration(
                          color: theme.dashboardContainer.withAlpha(235),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              'no_listings_in_selected_area'.tr,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: theme.textColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ),
                      );
                    }

                    return DragScrollView(
                      controller: _scrollController,
                      child: ListView.builder(
                        controller: _scrollController,
                        scrollDirection:
                            widget.isMobile ? Axis.horizontal : Axis.vertical,
                        padding: EdgeInsets.zero,
                        itemCount: effectiveAds.length,
                        itemBuilder: (context, index) {
                          final ad = effectiveAds[index];
                          final tag = 'mapViewPc_${ad.id}_${UniqueKey()}';
                          final mainImageUrl =
                              ad.images.isNotEmpty ? ad.images.first : '';
                          final formattedPrice = customFormat.format(ad.price);

                          return Padding(
                            padding: EdgeInsets.only(
                              top: widget.isMobile
                                  ? 0
                                  : index == 0
                                      ? 10
                                      : 0,
                              left: widget.isMobile
                                  ? index == 0
                                      ? 10
                                      : 0
                                  : 0,
                            ),
                            child: PortalBrowseListCardWidget(
                              isMobile: widget.isMobile,
                              isHidden: false,
                              remove: false,
                              feedAd: ad,
                              keyTag: tag,
                              mainImageUrl: mainImageUrl,
                              formattedPrice: formattedPrice,
                            ),
                          );
                        },
                      ),
                    );
                  },
                  loading: () => Padding(
                    padding: EdgeInsets.only(left:40),
                    child: ShimmerLoadingRow(
                      shimmerItemsCount: 1,
                      itemWidth: itemWidth,
                      itemHeight: itemHeight,
                      placeholderwidget: ShimmerPlaceholder(
                        width: itemWidth,
                        height: itemHeight,
                      ),
                    ),
                  ),
                  error: (error, stack) => Center(
                    child: Text('${'error_loading_ads'.tr}: $error'.tr),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MapActionButton extends ConsumerWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool selected;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool isMobile;

  const _MapActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.selected = false,
    this.backgroundColor,
    this.borderColor,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    final Color resolvedBackgroundColor = backgroundColor ??
        (selected ? theme.themeColor : Colors.black.withAlpha(145));

    final Color resolvedBorderColor =
        borderColor ?? (selected ? Colors.white : Colors.white.withAlpha(70));

    final double size = isMobile ? 34 : 40;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onPressed,
          child: Ink(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: resolvedBackgroundColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: resolvedBorderColor,
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: isMobile ? 16 : 19,
            ),
          ),
        ),
      ),
    );
  }
}