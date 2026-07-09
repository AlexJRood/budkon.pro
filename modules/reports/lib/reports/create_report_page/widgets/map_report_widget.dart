import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:portal/screens/feed/components/map/map_visuals.dart';
import 'package:reports/reports/create_report_page/providers/providers_report.dart';
import 'package:core/theme/apptheme.dart';
import 'package:get/get_utils/get_utils.dart';

class MapaWidget extends ConsumerStatefulWidget {
  const MapaWidget({super.key});

  @override
  ConsumerState<MapaWidget> createState() => _MapaWidgetState();
}

class _MapaWidgetState extends ConsumerState<MapaWidget> {
  double _zoom = 13.0;
  final MapController _mapController = MapController();

  LatLng _center = const LatLng(51.9194, 19.1451); // Default: Poland
  LatLng? _selectedPoint;

  void _zoomIn() {
    setState(() {
      _zoom++;
      final target = _selectedPoint ?? _center;
      _mapController.move(target, _zoom);
    });
  }

  void _zoomOut() {
    setState(() {
      _zoom--;
      final target = _selectedPoint ?? _center;
      _mapController.move(target, _zoom);
    });
  }

  void _indicateLocation() {
    // Example: maybe recenter to selected point
    if (_selectedPoint != null) {
      _mapController.move(_selectedPoint!, _zoom);
    }
  }

  void _clearMap() {
    setState(() {
      _selectedPoint = null;
    });

    // Clear from provider
    ref
        .read(propertyValuationFormProvider.notifier)
        .updateField('latitude', null);
    ref
        .read(propertyValuationFormProvider.notifier)
        .updateField('longitude', null);
  }

  void _onMapTap(TapPosition tapPosition, LatLng latlng) {
    setState(() {
      _selectedPoint = latlng;
    });

    // Update form state
    ref
        .read(propertyValuationFormProvider.notifier)
        .updateField('latitude', latlng.latitude);
    ref
        .read(propertyValuationFormProvider.notifier)
        .updateField('longitude', latlng.longitude);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final mapTileStyleMode = ref.watch(mapTileStyleModeProvider);
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Theme.of(context).iconTheme.color!),
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: double.infinity,
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[300],
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    backgroundColor: theme.dashboardContainer,
                    initialCenter: _center,
                    initialZoom: _zoom,
                    onTap: _onMapTap,
                  ),
                  children: [
                    AppMapVisuals.buildStyledOsmTileLayer(
                      theme: theme,
                      selectedMode: mapTileStyleMode,
                    ),
                    if (_selectedPoint != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedPoint!,
                            width: 30,
                            height: 30,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // Left side buttons
              Positioned(
                left: 8,
                top: 8,
                child: Column(
                  children: [
                    Tooltip(
                      message: 'indicate_the_location'.tr,
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        child: IconButton(
                          icon: const Icon(
                            Icons.location_on,
                            color: Colors.black,
                          ),
                          onPressed: _indicateLocation,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      child: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.black,
                        ),
                        onPressed: _clearMap,
                      ),
                    ),
                  ],
                ),
              ),

              // Right side zoom buttons
              Positioned(
                right: 8,
                top: 8,
                child: Column(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      child: IconButton(
                        icon: const Icon(Icons.add, color: Colors.black),
                        onPressed: _zoomIn,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      child: IconButton(
                        icon: const Icon(Icons.remove, color: Colors.black),
                        onPressed: _zoomOut,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
