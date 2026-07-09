import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map/portal_tile_cache_service.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:core/theme/apptheme.dart';
import 'package:get/get_utils/get_utils.dart';

enum MapTileStyleMode {
  followTheme,
  grayscale,
  darkInverted,
  none,
}

extension MapTileStyleModeX on MapTileStyleMode {
  String get storageValue {
    switch (this) {
      case MapTileStyleMode.followTheme:
        return 'followTheme';
      case MapTileStyleMode.grayscale:
        return 'grayscale';
      case MapTileStyleMode.darkInverted:
        return 'darkInverted';
      case MapTileStyleMode.none:
        return 'none';
    }
  }

  String get label {
    switch (this) {
      case MapTileStyleMode.followTheme:
        return 'map_style_follow_theme'.tr;
      case MapTileStyleMode.grayscale:
        return 'map_style_grayscale'.tr;
      case MapTileStyleMode.darkInverted:
        return 'map_style_dark_map'.tr;
      case MapTileStyleMode.none:
        return 'map_style_no_filter'.tr;
    }
  }

  static MapTileStyleMode fromStorage(String? value) {
    switch (value) {
      case 'grayscale':
        return MapTileStyleMode.grayscale;
      case 'darkInverted':
        return MapTileStyleMode.darkInverted;
      case 'none':
        return MapTileStyleMode.none;
      case 'followTheme':
      default:
        return MapTileStyleMode.followTheme;
    }
  }
}

class MapTileStyleNotifier extends StateNotifier<MapTileStyleMode> {
  static const String _prefsKey = 'map_tile_style_mode';

  MapTileStyleNotifier() : super(MapTileStyleMode.followTheme) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    state = MapTileStyleModeX.fromStorage(raw);
  }

  Future<void> setMode(MapTileStyleMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, mode.storageValue);
  }
}

final mapTileStyleModeProvider =
    StateNotifierProvider<MapTileStyleNotifier, MapTileStyleMode>(
  (ref) => MapTileStyleNotifier(),
);

class AppMapConfig {
  static const double minZoom = 4.8;
  static const double maxZoom = 19.0;

  static final LatLngBounds worldBounds = LatLngBounds(
    const LatLng(-85.0, -180.0),
    const LatLng(85.0, 180.0),
  );

  static CameraConstraint get worldConstraint => CameraConstraint.contain(
        bounds: worldBounds,
      );
}

class MapOverlayPalette {
  final Color textColor;
  final Color buttonColor;

  const MapOverlayPalette({
    required this.textColor,
    required this.buttonColor,
  });

  MapOverlayPalette copyWith({
    Color? textColor,
    Color? buttonColor,
  }) {
    return MapOverlayPalette(
      textColor: textColor ?? this.textColor,
      buttonColor: buttonColor ?? this.buttonColor,
    );
  }
}

class AppMapVisuals {
  static bool isDarkUi(ThemeColors theme) {
    return theme.sideBarbackground.computeLuminance() < 0.35;
  }

  static MapTileStyleMode resolveEffectiveMode({
    required ThemeColors theme,
    required MapTileStyleMode selectedMode,
  }) {
    if (selectedMode != MapTileStyleMode.followTheme) {
      return selectedMode;
    }

    return isDarkUi(theme)
        ? MapTileStyleMode.darkInverted
        : MapTileStyleMode.grayscale;
  }

  static bool isDarkMapMode(MapTileStyleMode mode) {
    return mode == MapTileStyleMode.darkInverted;
  }

  static const ColorFilter _softGrayFilter = ColorFilter.matrix(<double>[
    0.62, 0.28, 0.10, 0, 0,
    0.18, 0.72, 0.10, 0, 0,
    0.18, 0.28, 0.54, 0, 0,
    0.00, 0.00, 0.00, 1, 0,
  ]);

  static const ColorFilter _grayscaleFilter = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0.0000, 0.0000, 0.0000, 1, 0,
  ]);

  /// Soft dark map — readable, not too aggressive.
  static const ColorFilter _softInvertDarkFilter = ColorFilter.matrix(<double>[
    -0.60, 0.00, 0.00, 0, 210,
     0.00,-0.60, 0.00, 0, 210,
     0.00, 0.00,-0.60, 0, 216,
     0.00, 0.00, 0.00, 1,   0,
  ]);

  static Widget buildStyledTile({
    required Widget tileWidget,
    required ThemeColors theme,
    required MapTileStyleMode selectedMode,
  }) {
    final effectiveMode = resolveEffectiveMode(
      theme: theme,
      selectedMode: selectedMode,
    );

    switch (effectiveMode) {
      case MapTileStyleMode.none:
        return tileWidget;

      case MapTileStyleMode.grayscale:
        return ColorFiltered(
          colorFilter: _softGrayFilter,
          child: tileWidget,
        );

      case MapTileStyleMode.darkInverted:
        return ColorFiltered(
          colorFilter: _softInvertDarkFilter,
          child: ColorFiltered(
            colorFilter: _grayscaleFilter,
            child: tileWidget,
          ),
        );

      case MapTileStyleMode.followTheme:
        return tileWidget;
    }
  }

  static TileLayer buildStyledOsmTileLayer({
    required ThemeColors theme,
    required MapTileStyleMode selectedMode,
    String urlTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    String userAgentPackageName = 'com.hously.app',
  }) {
    return TileLayer(
      urlTemplate: urlTemplate,
      userAgentPackageName: userAgentPackageName,
      tileProvider: PortalTileCacheService.instance.buildProvider(),
      tileBuilder: (context, tileWidget, tile) {
        return buildStyledTile(
          tileWidget: tileWidget,
          theme: theme,
          selectedMode: selectedMode,
        );
      },
    );
  }
}

final effectiveMapTileStyleModeProvider = Provider<MapTileStyleMode>((ref) {
  final theme = ref.watch(themeColorsProvider);
  final selectedMode = ref.watch(mapTileStyleModeProvider);

  return AppMapVisuals.resolveEffectiveMode(
    theme: theme,
    selectedMode: selectedMode,
  );
});

final mapOverlayPaletteProvider = Provider<MapOverlayPalette>((ref) {
  final theme = ref.watch(themeColorsProvider);
  final effectiveMode = ref.watch(effectiveMapTileStyleModeProvider);

  final bool isDarkMap = AppMapVisuals.isDarkMapMode(effectiveMode);

  final Color foregroundColor = isDarkMap
      ? theme.textColor
      : theme.textFieldColor;

  return MapOverlayPalette(
    textColor: foregroundColor,
    buttonColor: foregroundColor,
  );
});