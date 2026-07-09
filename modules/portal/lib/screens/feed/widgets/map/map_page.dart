import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:latlong2/latlong.dart';
import 'package:map/app_map_shell.dart';
import 'package:map/map_pins_service.dart';
import 'package:map/providers.dart';
import 'package:portal/models/ad_list_view_model.dart';
import 'package:map/map_pin_model.dart';
import 'package:portal/pie_menu/feed.dart';
import 'package:portal/screens/feed/components/map/map_query_providers.dart';
import 'package:map/map_state.dart';
import 'package:portal/screens/feed/components/map/map_visuals.dart';
import 'package:portal/screens/filter_landing_page/providers/filter_provider.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/theme/apptheme.dart';

class PortalMapPage extends ConsumerStatefulWidget {
  const PortalMapPage({
    super.key,
    required this.onFilteredAdsChanged,
    this.isInteractive = true,
    this.isToggle = false,
    this.showTopRightControls = true,
    this.onExposeLayerRefresh,
    this.onLayerRefreshingChanged,
  });

  final void Function(List<AdsListViewModel>) onFilteredAdsChanged;
  final bool isInteractive;
  final bool isToggle;
  final bool showTopRightControls;
  final void Function(Future<void> Function() refreshLayers)?
      onExposeLayerRefresh;
  final ValueChanged<bool>? onLayerRefreshingChanged;

  @override
  ConsumerState<PortalMapPage> createState() => _PortalMapPageState();
}

class _PortalMapPageState extends ConsumerState<PortalMapPage> {
  MapController? _shellMapController;

  late final StateController<MapController?> _portalMapControllerState;
  late final ProviderSubscription<AsyncValue<dynamic>> _resolvedTargetSub;

  bool _isDisposed = false;

  List<AdsListViewModel> _allAds = [];
  String _lastSyncedAdsSignature = '';
  String? _lastAppliedInitialTargetSignature;

  bool _viewportWriteScheduled = false;
  MapViewportState? _pendingViewportState;
  LatLng? _pendingCenter;
  double? _pendingZoom;

  @override
  void initState() {
    super.initState();

    _portalMapControllerState =
        ref.read(portalMapControllerProvider.notifier);

    _resolvedTargetSub = ref.listenManual<AsyncValue<dynamic>>(
      resolvedDefaultMapTargetProvider,
      (previous, next) {
        if (_isDisposed || !mounted) return;

        final target = next.valueOrNull;
        if (target == null) return;

        _scheduleApplyResolvedInitialTarget(target as MapInitialTarget);
      },
    );
  }

  void _runAfterFrame(VoidCallback action) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isDisposed || !mounted) return;
      action();
    });
  }

  void _clearPortalMapControllerLater() {
    final controllerState = _portalMapControllerState;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controllerState.state = null;
    });
  }

  void _syncViewportToProvider(MapController controller) {
    if (_isDisposed || !mounted) return;

    final bounds = controller.camera.visibleBounds;
    final polygon = ref.read(freehandPolygonProvider);

    _pendingViewportState = MapViewportState(
      bbox: '${bounds.west},${bounds.south},${bounds.east},${bounds.north}',
      polygon: polygon.length >= 3 ? polygon : const [],
    );
    _pendingCenter = controller.camera.center;
    _pendingZoom = controller.camera.zoom;

    if (_viewportWriteScheduled) return;
    _viewportWriteScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewportWriteScheduled = false;

      if (_isDisposed || !mounted) return;
      if (_pendingViewportState == null ||
          _pendingCenter == null ||
          _pendingZoom == null) {
        return;
      }

      ref.read(mapViewportProvider.notifier).state = _pendingViewportState!;
      ref.read(mapCenterProvider.notifier).state = _pendingCenter!;
      ref.read(mapZoomProvider.notifier).state = _pendingZoom!;
    });
  }

  void _scheduleApplyResolvedInitialTarget(MapInitialTarget target) {
    final controller = _shellMapController;
    if (controller == null) return;
    if (_lastAppliedInitialTargetSignature == target.signature) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isDisposed || !mounted) return;

      final liveController = _shellMapController;
      if (liveController == null) return;
      if (_lastAppliedInitialTargetSignature == target.signature) return;

      _lastAppliedInitialTargetSignature = target.signature;
      liveController.move(target.center, target.zoom);

      _syncViewportToProvider(liveController);
      unawaited(_refreshStreetLayerIfNeeded());
    });
  }

  LatLng _offsetToLatLng(Offset localOffset) {
    final controller = _shellMapController;
    if (controller == null) {
      return const LatLng(52.2297, 21.0122);
    }
    return controller.camera.screenOffsetToLatLng(localOffset);
  }

  void _startDraw(Offset localOffset) {
    if (_isDisposed || !mounted) return;
    final point = _offsetToLatLng(localOffset);
    ref.read(freehandPolygonProvider.notifier).start(point);
  }

  void _appendDraw(Offset localOffset) {
    if (_isDisposed || !mounted) return;
    final point = _offsetToLatLng(localOffset);
    ref.read(freehandPolygonProvider.notifier).add(point);
  }

  void _finishDraw() {
    if (_isDisposed || !mounted) return;

    ref.read(freehandPolygonProvider.notifier).finish();

    final polygon = ref.read(freehandPolygonProvider);
    if (polygon.length >= 3) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_isDisposed || !mounted) return;
        ref.read(mapInteractionModeProvider.notifier).state =
            MapInteractionMode.browse;
      });
    }

    final controller = _shellMapController;
    if (controller != null) {
      _syncViewportToProvider(controller);
    }
  }

  AdsListViewModel? _findAdById(int id) {
    for (final ad in _allAds) {
      if (ad.id == id) return ad;
    }
    return null;
  }

  String? _extractRouteSlugFromPin(MapPinModel pin) {
    if (pin.slug != null && pin.slug!.trim().isNotEmpty) {
      return pin.slug!.trim();
    }

    final rawUrl = pin.url?.trim();
    if (rawUrl == null || rawUrl.isEmpty) return null;

    final cleaned = rawUrl.split('?').first.split('#').first;
    final segments = cleaned
        .split('/')
        .where((e) => e.trim().isNotEmpty)
        .toList();

    if (segments.isEmpty) return null;
    return segments.last;
  }

  void _zoomToCluster(MapPinModel pin) {
    final controller = _shellMapController;
    final bbox = pin.clusterBbox;

    if (controller == null || bbox == null || !bbox.isValid) {
      return;
    }

    controller.fitCamera(
      CameraFit.bounds(
        bounds: bbox.toBounds(),
        padding: const EdgeInsets.all(56),
      ),
    );
  }

  void _openAdFromPin(MapPinModel pin, BuildContext context) {
    if (_isDisposed || !mounted) return;

    if (pin.isCluster) {
      _zoomToCluster(pin);
      return;
    }

    final currentPath = ref.read(navigationService).currentPath;
    final path = currentPath == '/' ? '' : currentPath;

    final matchedAd = _findAdById(pin.id);
    final tag = 'mapViewPc_${pin.id}';

    if (matchedAd != null) {
      handleDisplayedAction(ref, matchedAd, context);
      ref.read(navigationService).openPopup(
        '$path/offer/${matchedAd.slug}',
        data: {
          'tag': tag,
          'ad': matchedAd,
        },
      );
      return;
    }

    final routeSlug = _extractRouteSlugFromPin(pin);
    if (routeSlug != null && routeSlug.isNotEmpty) {
      ref.read(navigationService).openPopup(
        '$path/offer/$routeSlug',
        data: {
          'tag': tag,
        },
      );
      return;
    }

    debugPrint(
      '[PortalMapPage] Cannot open pin ${pin.id} - missing route slug',
    );
  }

  String _buildAdsSignature(List<MapPinModel> pins) {
    final visibleSingleOfferIds = pins
        .where((e) => e.isSingleOffer)
        .map((e) => e.id)
        .toList()
      ..sort();

    return visibleSingleOfferIds.join(',');
  }

  void _scheduleAdsListSyncFromPins(List<MapPinModel> pins) {
    final visibleSinglePins = pins.where((pin) => pin.isSingleOffer).toList();
    final signature = _buildAdsSignature(visibleSinglePins);
    if (signature == _lastSyncedAdsSignature) return;

    _lastSyncedAdsSignature = signature;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isDisposed || !mounted) return;

      final pinIds = visibleSinglePins.map((e) => e.id).toSet();
      final filteredAds = _allAds.where((ad) => pinIds.contains(ad.id)).toList();

      final orderMap = <int, int>{
        for (int i = 0; i < visibleSinglePins.length; i++)
          visibleSinglePins[i].id: i,
      };

      filteredAds.sort((a, b) {
        final aIndex = orderMap[a.id] ?? 999999;
        final bIndex = orderMap[b.id] ?? 999999;
        return aIndex.compareTo(bIndex);
      });

      widget.onFilteredAdsChanged(filteredAds);
    });
  }

  Future<void> _refreshStreetLayerIfNeeded() async {
    final controller = _shellMapController;
    if (controller == null) return;
    if (_isDisposed || !mounted) return;

    final streetService = ref.read(streetLayerServiceProvider);
    if (!streetService.showLayer) return;

    await streetService.onViewportChanged(
      ref: ref,
      mapController: controller,
    );
  }

  void _handleMapReady(
    MapController controller,
    MapInitialTarget? resolvedTarget,
  ) {
    if (_isDisposed || !mounted) return;

    _shellMapController = controller;

    _runAfterFrame(() {
      _portalMapControllerState.state = controller;
    });

    _syncViewportToProvider(controller);

    if (resolvedTarget != null) {
      _scheduleApplyResolvedInitialTarget(resolvedTarget);
    } else {
      unawaited(_refreshStreetLayerIfNeeded());
    }
  }

  Widget _buildMapNotice({
    required Widget child,
    Color backgroundColor = const Color(0xCC000000),
  }) {
    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: child,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _shellMapController = null;
    _resolvedTargetSub.close();
    _clearPortalMapControllerLater();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adsAsync = ref.watch(filterProvider);
    final theme = ref.watch(themeColorsProvider);
    final mapTileStyleMode = ref.watch(mapTileStyleModeProvider);
    final resolvedTargetAsync = ref.watch(resolvedDefaultMapTargetProvider);

    final savedCenter = ref.watch(mapCenterProvider);
    final savedZoom = ref.watch(mapZoomProvider);
    final interactionMode = ref.watch(mapInteractionModeProvider);

    final resolvedTarget = resolvedTargetAsync.valueOrNull as MapInitialTarget?;
    _allAds = adsAsync.valueOrNull ?? [];

    final initialCenter =
        resolvedTarget?.center ?? savedCenter ?? polandDefaultMapTarget.center;

    final initialZoom = resolvedTarget?.zoom ??
        (savedCenter != null ? savedZoom : polandDefaultMapTarget.zoom);

    final shellIsToggle =
        interactionMode == MapInteractionMode.draw ? true : widget.isToggle;

    final shellIsInteractive = interactionMode == MapInteractionMode.draw
        ? false
        : (widget.isToggle ? widget.isInteractive : true);

    return AppMapShell(
      theme: theme,
      baseTileLayer: AppMapVisuals.buildStyledOsmTileLayer(
        theme: theme,
        selectedMode: mapTileStyleMode,
      ),
      initialCenter: initialCenter,
      initialZoom: initialZoom,
      minZoom: AppMapConfig.minZoom,
      maxZoom: AppMapConfig.maxZoom,
      cameraConstraint: AppMapConfig.worldConstraint,
      isToggle: shellIsToggle,
      isInteractive: shellIsInteractive,
      showTopRightControls: widget.showTopRightControls,
      onExposeLayerRefresh: widget.onExposeLayerRefresh,
      onRefreshingChanged: widget.onLayerRefreshingChanged,
      pinSources: [
        ProviderMapPinsSource<MapPinModel>(
          sourceId: 'portal_ads',
          provider: mapPinsProvider,
          pinMapper: (pin) => pin,
        ),
      ],
      layerServices: [
        ref.watch(streetLayerServiceProvider),
        ref.watch(landUseLayerServiceProvider),
        ref.watch(propertyPriceLayerServiceProvider),
        ref.watch(bdotCategoriesLayerServiceProvider),
        ref.watch(parcelLayerServiceProvider),
        ref.watch(mpzpLayerServiceProvider),
        ref.watch(gesutLayerServiceProvider),
        ref.watch(fiberLayerServiceProvider),
      ],
      onMapReady: (controller) {
        _handleMapReady(controller, resolvedTarget);
      },
      onViewportChanged: (controller) {
        if (_isDisposed || !mounted) return;
        _syncViewportToProvider(controller);
      },
      onPinsResolved: (entries) {
        if (_isDisposed || !mounted) return;
        final pins = entries.map((entry) => entry.pin).toList();
        _scheduleAdsListSyncFromPins(pins);
      },
      onPinTap: (entry, context) {
        if (_isDisposed || !mounted) return;
        _openAdFromPin(entry.pin, context);
      },
      extraMapLayersBuilder: (context, ref, theme, zoom, controller) {
        final polygonPoints = ref.watch(freehandPolygonProvider);

        return [
          if (polygonPoints.length >= 3)
            PolygonLayer(
              polygons: [
                Polygon(
                  points: polygonPoints,
                  color: Colors.greenAccent.withAlpha(40),
                  borderColor: Colors.greenAccent.withAlpha(160),
                  borderStrokeWidth: 2,
                ),
              ],
            ),
          if (polygonPoints.length >= 2)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: polygonPoints,
                  strokeWidth: 3,
                  color: Colors.greenAccent.withAlpha(160),
                ),
              ],
            ),
        ];
      },
      extraOverlaysBuilder: (context, ref, theme, zoom, controller) {
        final interactionMode = ref.watch(mapInteractionModeProvider);

        return [
          if (resolvedTargetAsync.isLoading)
            SafeArea(
              minimum: const EdgeInsets.only(top: 16),
              child: Align(
                alignment: Alignment.topCenter,
                child: _buildMapNotice(
                  child: Text(
                    'locating_map'.tr,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          if (interactionMode == MapInteractionMode.draw)
            Positioned.fill(
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (event) => _startDraw(event.localPosition),
                onPointerMove: (event) => _appendDraw(event.localPosition),
                onPointerUp: (_) => _finishDraw(),
                onPointerCancel: (_) => _finishDraw(),
                child: const SizedBox.expand(),
              ),
            ),
        ];
      },
    );
  }
}