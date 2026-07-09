import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:latlong2/latlong.dart';
import 'package:map/map_pin_model.dart';
import 'package:core/theme/apptheme.dart';

import 'app_map_cacheable_service.dart';
import 'app_map_layer_service.dart';
import 'map_layer_cache_manager.dart';
import 'map_pins_service.dart';

class AppMapShell extends ConsumerStatefulWidget {
  final ThemeColors theme;
  final Widget baseTileLayer;
  final LatLng initialCenter;
  final double initialZoom;
  final double minZoom;
  final double maxZoom;
  final CameraConstraint cameraConstraint;

  final bool isInteractive;
  final bool isToggle;
  final bool showCacheManagerButton;
  final bool showTopRightControls;

  /// Called once with the layer-refresh handler so a caller can trigger it
  /// from its own UI instead of the built-in top-right button.
  final void Function(Future<void> Function() refreshLayers)?
      onExposeLayerRefresh;
  final ValueChanged<bool>? onRefreshingChanged;

  final List<MapPinsSource> pinSources;
  final List<AppMapLayerService> layerServices;

  final void Function(MapController controller)? onMapReady;
  final void Function(MapController controller)? onViewportChanged;
  final void Function(List<MapPinEntry<dynamic>> entries)? onPinsResolved;

  /// Important:
  /// This callback may navigate / open popup.
  /// We call it deferred (post-frame), not directly inside tap arena.
  final void Function(MapPinEntry<dynamic> entry, BuildContext context)? onPinTap;

  final List<Widget> Function(
    BuildContext context,
    WidgetRef ref,
    ThemeColors theme,
    double zoom,
    MapController controller,
  )? extraMapLayersBuilder;

  final List<Widget> Function(
    BuildContext context,
    WidgetRef ref,
    ThemeColors theme,
    double zoom,
    MapController controller,
  )? extraOverlaysBuilder;

  const AppMapShell({
    super.key,
    required this.theme,
    required this.baseTileLayer,
    required this.initialCenter,
    required this.initialZoom,
    required this.minZoom,
    required this.maxZoom,
    required this.pinSources,
    required this.layerServices,
    required this.cameraConstraint,
    this.isInteractive = true,
    this.isToggle = false,
    this.showCacheManagerButton = true,
    this.showTopRightControls = true,
    this.onExposeLayerRefresh,
    this.onRefreshingChanged,
    this.onMapReady,
    this.onViewportChanged,
    this.onPinsResolved,
    this.onPinTap,
    this.extraMapLayersBuilder,
    this.extraOverlaysBuilder,
  });

  @override
  ConsumerState<AppMapShell> createState() => _AppMapShellState();
}

class _AppMapShellState extends ConsumerState<AppMapShell> {
  final MapController _mapController = MapController();
  final MapPinsService _pinsService = const MapPinsService();

  Timer? _debounce;
  String? _hoveredPinKey;
  String _lastPinsSignature = '';

  bool _isMapReady = false;
  bool _isDisposed = false;
  bool _refreshingLayers = false;

  late double _currentZoom;
  late LatLng _currentCenter;

  MapPinsSnapshot? _lastStablePinsSnapshot;

  bool get _isAlive => mounted && !_isDisposed;

  @override
  void initState() {
    super.initState();
    _currentZoom = widget.initialZoom;
    _currentCenter = widget.initialCenter;
    _attachLayerListeners(widget.layerServices);
    widget.onExposeLayerRefresh?.call(_refreshVisibleLayers);
  }

  @override
  void didUpdateWidget(covariant AppMapShell oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.layerServices != widget.layerServices) {
      _detachLayerListeners(oldWidget.layerServices);
      _attachLayerListeners(widget.layerServices);
    }

    if (!_isMapReady) {
      _currentZoom = widget.initialZoom;
      _currentCenter = widget.initialCenter;
    }
  }

  void _safeSetState(VoidCallback fn) {
    if (!_isAlive) return;
    setState(fn);
  }

  void _attachLayerListeners(List<AppMapLayerService> services) {
    for (final service in services) {
      service.addListener(_handleLayerChanged);
    }
  }

  void _detachLayerListeners(List<AppMapLayerService> services) {
    for (final service in services) {
      service.removeListener(_handleLayerChanged);
    }
  }

  void _handleLayerChanged() {
    _safeSetState(() {});
  }

  void _syncLocalCameraSnapshot() {
    if (!_isMapReady) return;

    final camera = _mapController.camera;
    _currentZoom = camera.zoom;
    _currentCenter = camera.center;
  }

  void _runDeferred(VoidCallback action) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isAlive) return;
      action();
    });
  }

  Future<void> _handleMapReadyAsync() async {
    if (!_isAlive) return;

    _isMapReady = true;
    _syncLocalCameraSnapshot();
    _safeSetState(() {});

    if (_isAlive && _isMapReady) {
      await Future.wait(
        widget.layerServices.map(
          (service) => service.onViewportChanged(
            ref: ref,
            mapController: _mapController,
          ),
        ),
        eagerError: false,
      );
    }

    if (!_isAlive) return;
    widget.onMapReady?.call(_mapController);
  }

  Future<void> _handleMapTapAsync(TapPosition tapPosition) async {
    if (!_isAlive || !_isMapReady) return;

    for (final service in widget.layerServices) {
      if (!_isAlive || !_isMapReady) return;

      final handled = await service.onTap(
        ref: ref,
        mapController: _mapController,
        tapPosition: tapPosition,
      );

      if (!_isAlive || !_isMapReady) return;

      if (handled) {
        break;
      }
    }
  }

  void _debouncedViewportSync() {
    if (!_isAlive || !_isMapReady) return;

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (!_isAlive || !_isMapReady) return;

      await Future.wait(
        widget.layerServices.map(
          (service) => service.onViewportChanged(
            ref: ref,
            mapController: _mapController,
          ),
        ),
        eagerError: false,
      );

      if (!_isAlive) return;
      widget.onViewportChanged?.call(_mapController);
    });
  }

  void _setRefreshing(bool value) {
    _refreshingLayers = value;
    widget.onRefreshingChanged?.call(value);
    _safeSetState(() {});
  }

  Future<void> _refreshVisibleLayers() async {
    if (!_isAlive || !_isMapReady || _refreshingLayers) return;

    _debounce?.cancel();

    _setRefreshing(true);

    try {
      await Future.wait(
        widget.layerServices.map(
          (service) => service.refreshCurrentViewport(
            ref: ref,
            mapController: _mapController,
          ),
        ),
        eagerError: false,
      );

      if (!_isAlive) return;
      widget.onViewportChanged?.call(_mapController);
    } finally {
      if (!_isAlive) return;

      _setRefreshing(false);
    }
  }

  MapPinsSnapshot _resolveDisplaySnapshot(MapPinsSnapshot raw) {
    final previous = _lastStablePinsSnapshot;
    final hasFreshEntries = raw.entries.isNotEmpty;
    final hadPreviousEntries = previous?.entries.isNotEmpty == true;

    if (hasFreshEntries) {
      _lastStablePinsSnapshot = raw.copyWith();
      return _lastStablePinsSnapshot!;
    }

    if (raw.isLoading && hadPreviousEntries) {
      final merged = previous!.copyWith(
        isLoading: true,
        error: raw.error,
      );
      _lastStablePinsSnapshot = merged;
      return merged;
    }

    if (raw.error != null && hadPreviousEntries) {
      final merged = previous!.copyWith(
        isLoading: false,
        error: raw.error,
      );
      _lastStablePinsSnapshot = merged;
      return merged;
    }

    _lastStablePinsSnapshot = raw;
    return raw;
  }

  String _pinsSignature(List<MapPinEntry<dynamic>> entries) {
    return entries.map((e) => e.uniqueKey).join('|');
  }

  void _emitPinsResolvedIfNeeded(List<MapPinEntry<dynamic>> entries) {
    if (widget.onPinsResolved == null) return;

    final signature = _pinsSignature(entries);
    if (signature == _lastPinsSignature) return;

    _lastPinsSignature = signature;
    final safeEntries = List<MapPinEntry<dynamic>>.from(entries);

    _runDeferred(() {
      widget.onPinsResolved?.call(safeEntries);
    });
  }

  int _paintPriority(MapPinModel pin, String? hoveredKey, String entryKey) {
    if (hoveredKey == entryKey) return 999;
    if (pin.isCluster) return 3;
    if (pin.isArchive) return 0;
    if (pin.isPremium) return 2;
    return 1;
  }

  String _formatPrice(int value) {
    final raw = value.toString();
    return raw.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ' ',
    );
  }

  String _formatClusterCount(int value) {
    if (value >= 1000000) {
      final formatted = (value / 1000000).toStringAsFixed(
        value % 1000000 == 0 ? 0 : 1,
      );
      return '${formatted}M';
    }
    if (value >= 1000) {
      final formatted = (value / 1000).toStringAsFixed(
        value % 1000 == 0 ? 0 : 1,
      );
      return '${formatted}k';
    }
    return value.toString();
  }

  bool _shouldShowPriceLabel(
    MapPinModel pin,
    double zoom,
    bool isHovered,
  ) {
    if (pin.isCluster) return false;
    return (zoom >= 11.8 && pin.price != null) || isHovered;
  }

  String _formatPriceLabel(MapPinModel pin) {
    if (pin.isCluster) {
      return _formatClusterCount(pin.clusterCount);
    }

    if (pin.price == null) return pin.title;

    final rounded = pin.price!.round();
    final formatted = _formatPrice(rounded);
    final currency = (pin.currency ?? '').trim().toUpperCase();

    if (currency.isEmpty || currency == 'PLN') {
      return formatted;
    }

    return '$formatted $currency';
  }

  double _labelMarkerWidth(String label) {
    final estimated = (label.length * 8.5) + 26;
    return estimated.clamp(74.0, 170.0);
  }

  double _clusterMarkerSize(MapPinModel pin, {required bool isHovered}) {
    double size;
    if (pin.clusterCount >= 1000) {
      size = 70;
    } else if (pin.clusterCount >= 100) {
      size = 64;
    } else if (pin.clusterCount >= 10) {
      size = 58;
    } else {
      size = 52;
    }

    if (isHovered) {
      size += 4;
    }

    return size;
  }

  Widget _buildClusterMarkerChild(
    MapPinModel pin,
    ThemeColors theme, {
    required bool isHovered,
  }) {
    final backgroundColor = pin.isArchive
        ? Colors.grey.shade700
        : pin.isPremium
            ? Colors.amber.shade700
            : theme.themeColor;

    final borderColor = isHovered ? Colors.greenAccent : Colors.white;
    final borderWidth = isHovered ? 3.0 : 2.0;
    final size = _clusterMarkerSize(pin, isHovered: isHovered);

    return AnimatedScale(
      scale: isHovered ? 1.08 : 1.0,
      duration: const Duration(milliseconds: 120),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: [
            BoxShadow(
              blurRadius: isHovered ? 16 : 10,
              color: isHovered
                  ? Colors.greenAccent.withAlpha(90)
                  : Colors.black26,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              _formatClusterCount(pin.clusterCount),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: pin.clusterCount >= 1000 ? 12 : 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSinglePinMarkerChild(
    MapPinModel pin,
    double zoom,
    ThemeColors theme, {
    required bool isHovered,
  }) {
    final showPriceLabel = _shouldShowPriceLabel(pin, zoom, isHovered);

    final backgroundColor = pin.isArchive
        ? Colors.grey.shade700
        : pin.isPremium
            ? Colors.amber.shade700
            : theme.themeColor;

    final borderColor = isHovered ? Colors.greenAccent : Colors.white;
    final borderWidth = isHovered ? 3.0 : 2.0;
    final extraScale = isHovered ? 1.12 : 1.0;

    if (showPriceLabel) {
      final label = _formatPriceLabel(pin);

      return AnimatedScale(
        scale: extraScale,
        duration: const Duration(milliseconds: 120),
        child: Container(
          constraints: BoxConstraints(
            minWidth: _labelMarkerWidth(label),
            minHeight: 34,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: borderColor, width: borderWidth),
            boxShadow: [
              BoxShadow(
                blurRadius: isHovered ? 14 : 8,
                color: isHovered
                    ? Colors.greenAccent.withAlpha(90)
                    : Colors.black26,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    return AnimatedScale(
      scale: extraScale,
      duration: const Duration(milliseconds: 120),
      child: Container(
        width: pin.isPremium ? 42 : 34,
        height: pin.isPremium ? 42 : 34,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: [
            BoxShadow(
              blurRadius: isHovered ? 14 : 6,
              color: isHovered
                  ? Colors.greenAccent.withAlpha(90)
                  : Colors.black26,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.location_on,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildMarkerChild(
    MapPinModel pin,
    double zoom,
    ThemeColors theme, {
    bool isHovered = false,
  }) {
    if (pin.isCluster) {
      return _buildClusterMarkerChild(
        pin,
        theme,
        isHovered: isHovered,
      );
    }

    return _buildSinglePinMarkerChild(
      pin,
      zoom,
      theme,
      isHovered: isHovered,
    );
  }

  double _markerWidth(
    MapPinModel pin,
    double zoom, {
    required bool isHovered,
  }) {
    if (pin.isCluster) {
      return _clusterMarkerSize(pin, isHovered: isHovered);
    }

    final showPriceLabel = _shouldShowPriceLabel(pin, zoom, isHovered);
    if (showPriceLabel) {
      return _labelMarkerWidth(_formatPriceLabel(pin)) + (isHovered ? 10 : 0);
    }

    return 48;
  }

  double _markerHeight(
    MapPinModel pin,
    double zoom, {
    required bool isHovered,
  }) {
    if (pin.isCluster) {
      return _clusterMarkerSize(pin, isHovered: isHovered);
    }

    final showPriceLabel = _shouldShowPriceLabel(pin, zoom, isHovered);
    return showPriceLabel ? 46 : 48;
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

  bool get _hasCacheableServices =>
      widget.layerServices.whereType<AppMapCacheableService>().isNotEmpty;

  Widget _buildTopRightButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool spinning = false,
  }) {
    final iconWidget = Icon(
      icon,
      color: widget.theme.textColor,
      size: 22,
    );

    return Material(
      color: widget.theme.dashboardContainer.withAlpha(235),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _runDeferred(onTap),
        child: SizedBox(
          width: 46,
          height: 46,
          child: Tooltip(
            message: tooltip,
            child: Center(
              child: spinning
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: widget.theme.textColor,
                      ),
                    )
                  : iconWidget,
            ),
          ),
        ),
      ),
    );
  }

  void _openCacheManager() {
    showDialog<void>(
      context: context,
      builder: (_) {
        return Dialog(
          backgroundColor: widget.theme.dashboardContainer,
          insetPadding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(color: widget.theme.dashboardBoarder),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: MapLayerCacheManagerPanel(
              services: widget.layerServices,
              theme: widget.theme,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final shellContext = context;

    final rawPinsSnapshot = _pinsService.watch(ref, widget.pinSources);
    final pinsSnapshot = _resolveDisplaySnapshot(rawPinsSnapshot);

    _emitPinsResolvedIfNeeded(pinsSnapshot.entries);

    final zoom = _currentZoom;

    final orderedEntries = [...pinsSnapshot.entries]
      ..sort((a, b) {
        final pa = _paintPriority(a.pin, _hoveredPinKey, a.uniqueKey);
        final pb = _paintPriority(b.pin, _hoveredPinKey, b.uniqueKey);

        if (pa != pb) {
          return pa.compareTo(pb);
        }

        if (a.pin.isCluster || b.pin.isCluster) {
          return a.pin.clusterCount.compareTo(b.pin.clusterCount);
        }

        final aPrice = a.pin.price ?? 0;
        final bPrice = b.pin.price ?? 0;
        return aPrice.compareTo(bPrice);
      });

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            backgroundColor: widget.theme.dashboardContainer,
            initialCenter: widget.initialCenter,
            initialZoom: widget.initialZoom,
            minZoom: widget.minZoom,
            maxZoom: widget.maxZoom,
            cameraConstraint: widget.cameraConstraint,
            onMapReady: () {
              unawaited(_handleMapReadyAsync());
            },
            onTap: (tapPosition, point) {
              if (!_isMapReady) return;
              unawaited(_handleMapTapAsync(tapPosition));
            },
            interactionOptions: InteractionOptions(
              flags: widget.isToggle
                  ? (widget.isInteractive
                      ? InteractiveFlag.all
                      : InteractiveFlag.none)
                  : InteractiveFlag.all,
            ),
            onPositionChanged: (position, hasGesture) {
              if (!_isAlive || !_isMapReady) return;

              _currentZoom = position.zoom ?? _currentZoom;
              _currentCenter = position.center ?? _currentCenter;

              _safeSetState(() {});

              if (!hasGesture) return;
              _debouncedViewportSync();
            },
          ),
          children: [
            widget.baseTileLayer,
            for (final service in widget.layerServices)
              ...service.buildLayers(
                context: context,
                ref: ref,
                mapController: _mapController,
                theme: widget.theme,
                zoom: zoom,
              ),
            ...?widget.extraMapLayersBuilder?.call(
              context,
              ref,
              widget.theme,
              zoom,
              _mapController,
            ),
            MarkerLayer(
              markers: orderedEntries.map((entry) {
                final pin = entry.pin;
                final isHovered = _hoveredPinKey == entry.uniqueKey;

                return Marker(
                  point: pin.point,
                  width: _markerWidth(
                    pin,
                    zoom,
                    isHovered: isHovered,
                  ),
                  height: _markerHeight(
                    pin,
                    zoom,
                    isHovered: isHovered,
                  ),
                  child: MouseRegion(
                    onEnter: (_) {
                      _safeSetState(() {
                        _hoveredPinKey = entry.uniqueKey;
                      });
                    },
                    onExit: (_) {
                      if (_hoveredPinKey == entry.uniqueKey) {
                        _safeSetState(() {
                          _hoveredPinKey = null;
                        });
                      }
                    },
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        _runDeferred(() {
                          if (!_isAlive) return;
                          widget.onPinTap?.call(entry, shellContext);
                        });
                      },
                      child: _buildMarkerChild(
                        pin,
                        zoom,
                        widget.theme,
                        isHovered: isHovered,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),

        for (final service in widget.layerServices)
          ...service.buildOverlays(
            context: context,
            ref: ref,
            theme: widget.theme,
          ),

        ...?widget.extraOverlaysBuilder?.call(
          context,
          ref,
          widget.theme,
          zoom,
          _mapController,
        ),

        if (widget.showTopRightControls)
          Positioned(
            top: 16,
            right: 16,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTopRightButton(
                    icon: Icons.refresh_rounded,
                    tooltip: 'refresh_map_layers'.tr,
                    spinning: _refreshingLayers,
                    onTap: () {
                      unawaited(_refreshVisibleLayers());
                    },
                  ),
                  if (widget.showCacheManagerButton &&
                      _hasCacheableServices) ...[
                    const SizedBox(height: 8),
                    _buildTopRightButton(
                      icon: Icons.storage_rounded,
                      tooltip: 'map_cache_manager'.tr,
                      onTap: _openCacheManager,
                    ),
                  ],
                ],
              ),
            ),
          ),

        Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            minimum: const EdgeInsets.only(bottom: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (pinsSnapshot.isLoading)
                  _buildMapNotice(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'loading_map_pins'.tr,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                if (pinsSnapshot.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _buildMapNotice(
                      backgroundColor: Colors.red.withAlpha(220),
                      child: Text(
                        'map_pins_error'.tr + pinsSnapshot.error.toString(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                for (final service in widget.layerServices) ...[
                  if (service.isBusy)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _buildMapNotice(
                        child: Text(
                          service.busyText ?? 'loading'.tr,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  if (service.errorText != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _buildMapNotice(
                        backgroundColor: Colors.red.withAlpha(220),
                        child: Text(
                          service.errorText!,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _debounce?.cancel();
    _detachLayerListeners(widget.layerServices);
    super.dispose();
  }
}