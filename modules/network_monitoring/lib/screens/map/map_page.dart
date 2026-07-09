// ignore_for_file: unused_import

import 'dart:async';

import 'package:core/ui/anchors/anchor_target.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:latlong2/latlong.dart';
import 'package:network_monitoring/components/open_nm_ad.dart';
import 'package:network_monitoring/emma/anchors/anchors_nm.dart';
import 'package:network_monitoring/models/monitoring_ads_model.dart';
import 'package:network_monitoring/models/nm_map_pins.dart';
import 'package:network_monitoring/providers/map_query.dart';
import 'package:network_monitoring/screens/map/map_state.dart';
import 'package:map/app_map_shell.dart';
import 'package:map/map_pins_service.dart';
import 'package:map/providers.dart';
import 'package:map/map_pin_model.dart';
import 'package:portal/screens/feed/components/map/map_visuals.dart';
import 'package:core/theme/apptheme.dart';
import 'package:url_launcher/url_launcher.dart';

class NetworkMonitoringMapPage extends ConsumerStatefulWidget {
  const NetworkMonitoringMapPage({
    super.key,
    required this.onFilteredAdsChanged,
    this.isInteractive = true,
    this.isToggle = false,
    this.transactionId,
    this.clientId,
    this.showTopRightControls = true,
    this.onExposeLayerRefresh,
    this.onLayerRefreshingChanged,
  });

  final ValueChanged<List<MonitoringAdsModel>> onFilteredAdsChanged;
  final bool isInteractive;
  final bool isToggle;
  final int? transactionId;
  final int? clientId;
  final bool showTopRightControls;
  final void Function(Future<void> Function() refreshLayers)?
      onExposeLayerRefresh;
  final ValueChanged<bool>? onLayerRefreshingChanged;

  @override
  ConsumerState<NetworkMonitoringMapPage> createState() =>
      _NetworkMonitoringMapPageState();
}

class _NetworkMonitoringMapPageState
    extends ConsumerState<NetworkMonitoringMapPage> {
  MapController? _shellMapController;

  List<MonitoringAdsModel> _allAds = [];
  String _lastSyncedAdsSignature = '';
  String? _lastAppliedInitialTargetSignature;

  void _syncViewportToProvider(MapController controller) {
    final bounds = controller.camera.visibleBounds;
    final polygon = ref.read(nmFreehandPolygonProvider);

    ref.read(nmMapViewportProvider.notifier).state = NmMapViewportState(
      bbox: '${bounds.west},${bounds.south},${bounds.east},${bounds.north}',
      polygon: polygon.length >= 3 ? polygon : const [],
    );

    ref.read(nmMapCenterProvider.notifier).state = controller.camera.center;
    ref.read(nmMapZoomProvider.notifier).state = controller.camera.zoom;
  }

  void _scheduleApplyInitialTarget(NmMapInitialTarget target) {
    final controller = _shellMapController;
    if (controller == null) return;
    if (_lastAppliedInitialTargetSignature == target.signature) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final liveController = _shellMapController;
      if (liveController == null) return;
      if (_lastAppliedInitialTargetSignature == target.signature) return;

      _lastAppliedInitialTargetSignature = target.signature;
      liveController.move(target.center, target.zoom);

      ref.read(nmMapCenterProvider.notifier).state = target.center;
      ref.read(nmMapZoomProvider.notifier).state = target.zoom;

      _syncViewportToProvider(liveController);
      unawaited(_refreshStreetLayerIfNeeded());
    });
  }

  void _handleMapReady(
    MapController controller,
    NmMapInitialTarget? initialTarget,
  ) {
    _shellMapController = controller;
    _syncViewportToProvider(controller);

    if (initialTarget != null) {
      _scheduleApplyInitialTarget(initialTarget);
    } else {
      unawaited(_refreshStreetLayerIfNeeded());
    }
  }

  Future<void> _refreshStreetLayerIfNeeded() async {
    final controller = _shellMapController;
    if (controller == null) return;

    final streetService = ref.read(streetLayerServiceProvider);
    if (!streetService.showLayer) return;

    await streetService.onViewportChanged(
      ref: ref,
      mapController: controller,
    );
  }

  LatLng _offsetToLatLng(Offset localOffset) {
    final controller = _shellMapController;
    if (controller == null) {
      return const LatLng(52.2297, 21.0122);
    }

    return controller.camera.screenOffsetToLatLng(localOffset);
  }

  void _startDraw(Offset localOffset) {
    final point = _offsetToLatLng(localOffset);
    ref.read(nmFreehandPolygonProvider.notifier).start(point);
  }

  void _appendDraw(Offset localOffset) {
    final point = _offsetToLatLng(localOffset);
    ref.read(nmFreehandPolygonProvider.notifier).add(point);
  }

  void _finishDraw() {
    ref.read(nmFreehandPolygonProvider.notifier).finish();

    final polygon = ref.read(nmFreehandPolygonProvider);
    if (polygon.length >= 3) {
      ref.read(nmMapInteractionModeProvider.notifier).state =
          NmMapInteractionMode.browse;
    }

    final controller = _shellMapController;
    if (controller != null) {
      _syncViewportToProvider(controller);
    }
  }

  MonitoringAdsModel? _findAdById(int id) {
    for (final ad in _allAds) {
      if (ad.id == id) return ad;
    }
    return null;
  }

  Future<void> _openFallbackPinUrl(MapPinModel pin) async {
    final raw = pin.url?.trim();
    if (raw == null || raw.isEmpty || raw == 'null') return;

    final uri = Uri.tryParse(raw);
    if (uri == null) return;

    if (kIsWeb) {
      await launchUrl(uri, webOnlyWindowName: '_blank');
      return;
    }

    await launchUrl(uri, mode: LaunchMode.externalApplication);
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

  Future<void> _openAdFromPin(MapPinModel pin) async {
    if (pin.isCluster) {
      _zoomToCluster(pin);
      return;
    }

    final matchedAd = _findAdById(pin.id);

    if (matchedAd != null) {
      await openAdUrl(
        context,
        ref,
        matchedAd,
        widget.transactionId,
        widget.clientId,
        'networkAd_${matchedAd.id}',
      );
      return;
    }

    await _openFallbackPinUrl(pin);
  }

  String _buildAdsSignature(List<MapPinModel> pins) {
    final visibleSingleOfferIds = pins
        .where((e) => !e.isCluster)
        .map((e) => e.id)
        .toList()
      ..sort();

    return visibleSingleOfferIds.join(',');
  }

  void _scheduleAdsListSyncFromPins(List<MapPinModel> pins) {
    final visibleSinglePins = pins.where((pin) => !pin.isCluster).toList();
    final signature = _buildAdsSignature(visibleSinglePins);

    if (signature == _lastSyncedAdsSignature) return;

    _lastSyncedAdsSignature = signature;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

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
  Widget build(BuildContext context) {
    final adsAsync = ref.watch(networkMonitoringMapAdvertisementsProvider);
    final theme = ref.watch(themeColorsProvider);
    final mapTileStyleMode = ref.watch(mapTileStyleModeProvider);

    final savedCenter = ref.watch(nmMapCenterProvider);
    final savedZoom = ref.watch(nmMapZoomProvider);
    final interactionMode = ref.watch(nmMapInteractionModeProvider);

    _allAds = adsAsync.valueOrNull ?? [];

    final initialTarget = savedCenter != null
        ? NmMapInitialTarget(
            center: savedCenter,
            zoom: savedZoom,
            source: 'saved',
            signature:
                'saved_${savedCenter.latitude}_${savedCenter.longitude}_$savedZoom',
          )
        : nmPolandDefaultMapTarget;

    final initialCenter = initialTarget.center;
    final initialZoom = initialTarget.zoom;

    final shellIsToggle =
        interactionMode == NmMapInteractionMode.draw ? true : widget.isToggle;

    final shellIsInteractive = interactionMode == NmMapInteractionMode.draw
        ? false
        : (widget.isToggle ? widget.isInteractive : true);

    return EmmaUiAnchorTarget(
      // @emma-backend: NetworkMonitoringEmmaAnchors.mapInnerRoot
      anchorKey: 'network_monitoring.map.inner_root',
      child: AppMapShell(
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
          ProviderMapPinsSource<NetworkMonitoringMapPinModel>(
            sourceId: 'nm_ads',
            provider: networkMonitoringMapPinsProvider,
            pinMapper: (pin) => MapPinModel(
              id: pin.id,
              lat: pin.lat,
              lon: pin.lon,
              title: pin.title,
              price: pin.price,
              currency: pin.currency,
              isPremium: pin.isPremium,
              isArchive: pin.isArchive,
              thumb: pin.thumb,
              url: pin.url,
              isCluster: pin.isCluster,
              clusterCount: pin.clusterCount,
              clusterKey: pin.clusterKey,
              clusterBbox: pin.clusterBbox,
            ),
          ),
        ],
        layerServices: [
          ref.watch(streetLayerServiceProvider),
          ref.watch(parcelLayerServiceProvider),
          ref.watch(mpzpLayerServiceProvider),
          ref.watch(gesutLayerServiceProvider),
        ],
        onMapReady: (controller) {
          _handleMapReady(controller, initialTarget);
        },
        onViewportChanged: (controller) {
          _syncViewportToProvider(controller);
        },
        onPinsResolved: (entries) {
          final pins = entries.map((entry) => entry.pin).toList();
          _scheduleAdsListSyncFromPins(pins);
        },
        onPinTap: (entry, context) {
          unawaited(_openAdFromPin(entry.pin));
        },
        extraMapLayersBuilder: (context, ref, theme, zoom, controller) {
          final polygonPoints = ref.watch(nmFreehandPolygonProvider);

          return [
            if (polygonPoints.length >= 3)
              EmmaUiAnchorTarget(
                // @emma-backend: NetworkMonitoringEmmaAnchors.mapDrawnPolygonLayer
                anchorKey: 'network_monitoring.map.drawn_polygon_layer',
                child: PolygonLayer(
                  polygons: [
                    Polygon(
                      points: polygonPoints,
                      color: Colors.greenAccent.withAlpha(40),
                      borderColor: Colors.greenAccent.withAlpha(160),
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
              ),
            if (polygonPoints.length >= 2)
              EmmaUiAnchorTarget(
                // @emma-backend: NetworkMonitoringEmmaAnchors.mapDrawnPolylineLayer
                anchorKey: 'network_monitoring.map.drawn_polyline_layer',
                child: PolylineLayer(
                  polylines: [
                    Polyline(
                      points: polygonPoints,
                      strokeWidth: 3,
                      color: Colors.greenAccent.withAlpha(160),
                    ),
                  ],
                ),
              ),
          ];
        },
        extraOverlaysBuilder: (context, ref, theme, zoom, controller) {
          final interactionMode = ref.watch(nmMapInteractionModeProvider);

          return [
            if (interactionMode == NmMapInteractionMode.draw)
              EmmaUiAnchorTarget(
                // @emma-backend: NetworkMonitoringEmmaAnchors.mapDrawOverlay
                anchorKey: 'network_monitoring.map.draw_overlay',
                child: Positioned.fill(
                  child: Listener(
                    behavior: HitTestBehavior.translucent,
                    onPointerDown: (event) => _startDraw(event.localPosition),
                    onPointerMove: (event) => _appendDraw(event.localPosition),
                    onPointerUp: (_) => _finishDraw(),
                    onPointerCancel: (_) => _finishDraw(),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            EmmaUiAnchorTarget(
              // @emma-backend: NetworkMonitoringEmmaAnchors.mapStatusOverlay
              anchorKey: 'network_monitoring.map.status_overlay',
              child: Align(
                alignment: Alignment.bottomCenter,
                child: SafeArea(
                  minimum: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (adsAsync.isLoading)
                        EmmaUiAnchorTarget(
                          // @emma-backend: NetworkMonitoringEmmaAnchors.mapLoadingNotice
                          anchorKey: 'network_monitoring.map.loading_notice',
                          child: _buildMapNotice(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'loading_map_ads'.tr,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (adsAsync.hasError)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: EmmaUiAnchorTarget(
                            // @emma-backend: NetworkMonitoringEmmaAnchors.mapErrorNotice
                            anchorKey: 'network_monitoring.map.error_notice',
                            child: _buildMapNotice(
                              backgroundColor: Colors.red.withAlpha(220),
                              child: Text(
                                '${'map_ads_error'.tr}: ${adsAsync.error}',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
      ),
    );
  }
}