import 'dart:async';
import 'package:portal/portal_urls.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:latlong2/latlong.dart';
import 'package:portal/screens/add_offer/provider/add_offer_provider.dart';
import 'package:portal/screens/feed/components/map/map_visuals.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/theme/apptheme.dart';

class MapaWidgetAddOffer extends ConsumerStatefulWidget {
  const MapaWidgetAddOffer({super.key});

  @override
  ConsumerState<MapaWidgetAddOffer> createState() => _MapaWidgetAddOfferState();
}

class _MapaWidgetAddOfferState extends ConsumerState<MapaWidgetAddOffer> {
  final MapController _mapController = MapController();

  final LatLng _defaultCenter = const LatLng(52.0693, 19.4803);

  Timer? _addressDebounce;
  Timer? _persistCenterDebounce;

  bool _mapReady = false;
  bool _isUserMovingMap = false;

  double _zoom = 13.0;
  LatLng _center = const LatLng(52.0693, 19.4803);

  String _lastGeocodedQuery = '';
  String _lastAppliedCoordinateSignature = '';

  late final List<TextEditingController> _addressControllers;
  late final List<TextEditingController> _coordinateControllers;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _bindControllerListeners();
      _applyCoordinatesFromProvider(forceMove: true);
      _scheduleAddressLookup(force: true);
    });
  }

  @override
  void dispose() {
    _addressDebounce?.cancel();
    _persistCenterDebounce?.cancel();

    for (final controller in _addressControllers) {
      controller.removeListener(_onAddressFieldsChanged);
    }
    for (final controller in _coordinateControllers) {
      controller.removeListener(_onCoordinateFieldsChanged);
    }

    super.dispose();
  }

  void _bindControllerListeners() {
    final addOfferState = ref.read(addOfferProvider);

    _addressControllers = [
      addOfferState.countryController,
      addOfferState.stateController,
      addOfferState.cityController,
      addOfferState.streetController,
      addOfferState.zipcodeController,
    ];

    _coordinateControllers = [
      addOfferState.latitudeController,
      addOfferState.longitudeController,
    ];

    for (final controller in _addressControllers) {
      controller.addListener(_onAddressFieldsChanged);
    }

    for (final controller in _coordinateControllers) {
      controller.addListener(_onCoordinateFieldsChanged);
    }
  }

  void _onAddressFieldsChanged() {
    if (!mounted) return;
    _scheduleAddressLookup();
    setState(() {});
  }

  void _onCoordinateFieldsChanged() {
    if (!mounted) return;
    _applyCoordinatesFromProvider();
  }

  String _textOf(TextEditingController controller) {
    return controller.text.trim();
  }

  String _buildGeocodeQuery(dynamic addOfferState) {
    final street = _textOf(addOfferState.streetController);
    final zipcode = _textOf(addOfferState.zipcodeController);
    final city = _textOf(addOfferState.cityController);
    final state = _textOf(addOfferState.stateController);
    final country = _textOf(addOfferState.countryController).isEmpty
        ? 'Poland'
        : _textOf(addOfferState.countryController);

    final parts = <String>[
      if (street.isNotEmpty) street,
      if (zipcode.isNotEmpty) zipcode,
      if (city.isNotEmpty) city,
      if (state.isNotEmpty) state,
      if (country.isNotEmpty) country,
    ];

    return parts.join(', ');
  }

  bool _hasPreciseAddress(dynamic addOfferState) {
    return _textOf(addOfferState.streetController).isNotEmpty ||
        _textOf(addOfferState.zipcodeController).isNotEmpty;
  }

  double _suggestedZoom(dynamic addOfferState) {
    if (_textOf(addOfferState.streetController).isNotEmpty ||
        _textOf(addOfferState.zipcodeController).isNotEmpty) {
      return 16.5;
    }

    if (_textOf(addOfferState.cityController).isNotEmpty) {
      return 12.5;
    }

    if (_textOf(addOfferState.stateController).isNotEmpty) {
      return 8.8;
    }

    return 6.2;
  }

  LatLng? _parseLatLngFromProvider(dynamic addOfferState) {
    final latText = _textOf(addOfferState.latitudeController);
    final lonText = _textOf(addOfferState.longitudeController);

    if (latText.isEmpty || lonText.isEmpty) return null;

    final lat = double.tryParse(latText);
    final lon = double.tryParse(lonText);

    if (lat == null || lon == null) return null;
    return LatLng(lat, lon);
  }

  void _moveMap(LatLng target, double zoom) {
    if (!_mapReady) return;
    _mapController.move(target, zoom);
  }

  void _persistCenterToProvider(LatLng point) {
    final notifier = ref.read(addOfferProvider.notifier);
    notifier.updateField('latitude', point.latitude);
    notifier.updateField('longitude', point.longitude);

    _lastAppliedCoordinateSignature =
        '${point.latitude.toStringAsFixed(6)},${point.longitude.toStringAsFixed(6)}';
  }

  void _applyCoordinatesFromProvider({bool forceMove = false}) {
    final addOfferState = ref.read(addOfferProvider);
    final point = _parseLatLngFromProvider(addOfferState);

    if (point == null) {
      return;
    }

    final signature =
        '${point.latitude.toStringAsFixed(6)},${point.longitude.toStringAsFixed(6)}';

    if (!forceMove && signature == _lastAppliedCoordinateSignature) {
      return;
    }

    _lastAppliedCoordinateSignature = signature;

    final targetZoom = _zoom < 16.0 ? 16.0 : _zoom;

    setState(() {
      _center = point;
      _zoom = targetZoom;
    });

    _moveMap(point, targetZoom);
  }

  void _scheduleAddressLookup({bool force = false}) {
    _addressDebounce?.cancel();
    _addressDebounce = Timer(
      const Duration(milliseconds: 450),
      () => _lookupAddressAndUpdateMap(force: force),
    );
  }

  Future<void> _lookupAddressAndUpdateMap({bool force = false}) async {
    final addOfferState = ref.read(addOfferProvider);

    final query = _buildGeocodeQuery(addOfferState);
    if (query.trim().isEmpty) {
      return;
    }

    if (!force && query == _lastGeocodedQuery) {
      return;
    }

    _lastGeocodedQuery = query;

    try {
      final response = await ApiServices.get(
        ref: ref,
        PortalUrls.nominatimMap(Uri.encodeComponent(query)),
        hasToken: false,
        headers: {'User-Agent': 'Hously1.0'},
      );

      if (!mounted) return;

      if (response == null || response.statusCode != 200) {
        return;
      }

      dynamic decoded;
      final body = response.data;

      if (body is List<int>) {
        decoded = json.decode(utf8.decode(body));
      } else if (body is String) {
        decoded = json.decode(body);
      } else {
        decoded = body;
      }

      if (decoded is! List || decoded.isEmpty) {
        return;
      }

      final currentQuery = _buildGeocodeQuery(ref.read(addOfferProvider));
      if (currentQuery.trim() != query.trim()) {
        return;
      }

      final first = Map<String, dynamic>.from(decoded.first);
      final lat = double.tryParse(first['lat']?.toString() ?? '');
      final lon = double.tryParse(first['lon']?.toString() ?? '');

      if (lat == null || lon == null) {
        return;
      }

      final point = LatLng(lat, lon);
      final targetZoom = _suggestedZoom(addOfferState);

      setState(() {
        _center = point;
        _zoom = targetZoom;
      });

      _moveMap(point, targetZoom);

      if (_hasPreciseAddress(addOfferState)) {
        _persistCenterToProvider(point);
      }
    } catch (_) {}
  }

  void _schedulePersistCenterFromCamera() {
    _persistCenterDebounce?.cancel();
    _persistCenterDebounce = Timer(
      const Duration(milliseconds: 220),
      () {
        if (!mounted || !_mapReady) return;
        final center = _mapController.camera.center;

        setState(() {
          _center = center;
        });

        _persistCenterToProvider(center);
      },
    );
  }

  void _zoomIn() {
    setState(() {
      _zoom = (_zoom + 1).clamp(AppMapConfig.minZoom, AppMapConfig.maxZoom);
    });

    _moveMap(_mapController.camera.center, _zoom);
    _schedulePersistCenterFromCamera();
  }

  void _zoomOut() {
    setState(() {
      _zoom = (_zoom - 1).clamp(AppMapConfig.minZoom, AppMapConfig.maxZoom);
    });

    _moveMap(_mapController.camera.center, _zoom);
    _schedulePersistCenterFromCamera();
  }

  void _focusCurrentLocation() {
    _moveMap(_center, _zoom);
  }

  void _clearMap() {
    final notifier = ref.read(addOfferProvider.notifier);
    notifier.updateField('latitude', null);
    notifier.updateField('longitude', null);

    setState(() {
      _center = _defaultCenter;
      _zoom = 6.2;
    });

    _moveMap(_defaultCenter, 6.2);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final mapTileStyleMode = ref.watch(mapTileStyleModeProvider);
    final mapTheme = ref.watch(mapOverlayPaletteProvider);
    final mapUiTextColor = mapTheme.textColor;
    final mapUiAccentColor = mapTheme.buttonColor;
    final addOfferState = ref.watch(addOfferProvider);

    final providerPoint = _parseLatLngFromProvider(addOfferState);
    if (providerPoint != null &&
        _lastAppliedCoordinateSignature !=
            '${providerPoint.latitude.toStringAsFixed(6)},${providerPoint.longitude.toStringAsFixed(6)}') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _applyCoordinatesFromProvider();
      });
    }

    return Container(
      width: double.infinity,
      height: 210,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dashboardBoarder.withAlpha(120),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned.fill(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  backgroundColor: theme.dashboardContainer,
                  initialCenter: providerPoint ?? _center,
                  initialZoom: _zoom,
                  minZoom: AppMapConfig.minZoom,
                  maxZoom: AppMapConfig.maxZoom,
                  cameraConstraint: AppMapConfig.worldConstraint,
                  onMapReady: () {
                    _mapReady = true;
                    _moveMap(providerPoint ?? _center, _zoom);
                  },
                  onPositionChanged: (position, hasGesture) {
                    if (!_mapReady) return;

                    final cameraCenter = _mapController.camera.center;

                    setState(() {
                      _center = cameraCenter;
                      _zoom = _mapController.camera.zoom;
                      _isUserMovingMap = hasGesture;
                    });

                    _schedulePersistCenterFromCamera();
                  },
                ),
                children: [
                  AppMapVisuals.buildStyledOsmTileLayer(
                    theme: theme,
                    selectedMode: mapTileStyleMode,
                  ),
                ],
              ),
            ),

            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: Transform.translate(
                    offset: const Offset(0, -18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: mapUiAccentColor,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                blurRadius: 10,
                                color: Colors.black26,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        Container(
                          width: 2,
                          height: 18,
                          color: Colors.white.withAlpha(170),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            Positioned(
              top: 10,
              left: 10,
              child: Column(
                children: [
                  _AddOfferMapButton(
                    tooltip: 'center_map'.tr,
                    icon: Icons.my_location_rounded,
                    backgroundColor: Colors.black.withAlpha(150),
                    borderColor: Colors.white.withAlpha(70),
                    iconColor: mapUiTextColor,
                    onTap: _focusCurrentLocation,
                  ),
                  const SizedBox(height: 8),
                  _AddOfferMapButton(
                    tooltip: 'clear_selected_point'.tr,
                    icon: Icons.delete_outline_rounded,
                    backgroundColor: Colors.black.withAlpha(150),
                    borderColor: Colors.white.withAlpha(70),
                    iconColor: mapUiTextColor,
                    onTap: _clearMap,
                  ),
                ],
              ),
            ),

            Positioned(
              top: 10,
              right: 10,
              child: Column(
                children: [
                  _AddOfferMapButton(
                    tooltip: 'zoom_in'.tr,
                    icon: Icons.add_rounded,
                    backgroundColor: Colors.black.withAlpha(150),
                    borderColor: Colors.white.withAlpha(70),
                    iconColor: mapUiTextColor,
                    onTap: _zoomIn,
                  ),
                  const SizedBox(height: 8),
                  _AddOfferMapButton(
                    tooltip: 'zoom_out'.tr,
                    icon: Icons.remove_rounded,
                    backgroundColor: Colors.black.withAlpha(150),
                    borderColor: Colors.white.withAlpha(70),
                    iconColor: mapUiTextColor,
                    onTap: _zoomOut,
                  ),
                ],
              ),
            ),

            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(145),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withAlpha(55),
                      ),
                    ),
                    child: Text(
                      _isUserMovingMap
                      ? 'move_map_pin_to_exact_location'.tr
                        : 'location_is_set_by_map_center'.tr,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: mapUiTextColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddOfferMapButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;

  const _AddOfferMapButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Ink(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}