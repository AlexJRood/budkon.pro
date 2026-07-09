import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:latlong2/latlong.dart';
import 'package:portal/screens/feed/components/map/map_visuals.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';

class MapAd extends ConsumerStatefulWidget {
  final double latitude;
  final double longitude;
  final Function()? onMapActivated;

  const MapAd({
    super.key,
    required this.latitude,
    required this.longitude,
    this.onMapActivated,
  });

  @override
  ConsumerState<MapAd> createState() => _MapAdState();
}

class _MapAdState extends ConsumerState<MapAd> {
  bool _ignoreMapInteraction = true;

  void _toggleMapInteraction() {
    if (_ignoreMapInteraction && widget.onMapActivated != null) {
      widget.onMapActivated!();
    }

    setState(() {
      _ignoreMapInteraction = !_ignoreMapInteraction;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final mapTileStyleMode = ref.watch(mapTileStyleModeProvider);

    return Column(
      children: [
        Expanded(
          child: IgnorePointer(
            ignoring: _ignoreMapInteraction,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.0),
              child: FlutterMap(
                options: MapOptions(
                  backgroundColor: theme.dashboardContainer,
                  initialCenter: LatLng(widget.latitude, widget.longitude),
                  initialZoom: 13.0,
                  minZoom: AppMapConfig.minZoom,
                  maxZoom: AppMapConfig.maxZoom,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                  ),
                  cameraConstraint: AppMapConfig.worldConstraint,
                ),
                children: [
                  AppMapVisuals.buildStyledOsmTileLayer(
                    theme: theme,
                    selectedMode: mapTileStyleMode,
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        width: 35,
                        height: 35,
                        point: LatLng(widget.latitude, widget.longitude),
                        child: AppIcons.location(
                          color: theme.themeColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: _toggleMapInteraction,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              _ignoreMapInteraction
                  ? 'click_here_to_activate_map_interactions'.tr
                  : 'map_interaction_is_active'.tr,
              style: AppTextStyles.interMedium.copyWith(
                color: theme.textColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}