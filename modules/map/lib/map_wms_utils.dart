import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

Widget buildWmsTileLayer({
  required String baseUrl,
  required List<String> layers,
  required double opacity,
  String? layerKey,
  Color? tintColor,
  double tintStrength = 0.0,
  // Pass explicit styles when the server rejects 'default' (e.g. GeoServer
  // named styles). Leave null to fall back to 'default' per layer.
  List<String>? styles,
}) {
  if (layers.isEmpty) {
    return const SizedBox.shrink();
  }

  Widget child = TileLayer(
    key: ValueKey(
      layerKey ?? '$baseUrl|${layers.join(",")}|${opacity.toStringAsFixed(2)}',
    ),
    panBuffer: 0,
    keepBuffer: 0,
    wmsOptions: WMSTileLayerOptions(
      baseUrl: baseUrl,
      layers: layers,
      styles: styles ?? List<String>.filled(layers.length, 'default'),
      format: 'image/png',
      transparent: true,
      version: '1.3.0',
    ),
  );

  final safeTintStrength = tintStrength.clamp(0.0, 1.0);
  if (tintColor != null && safeTintStrength > 0) {
    child = ColorFiltered(
      colorFilter: ColorFilter.mode(
        tintColor.withOpacity(safeTintStrength),
        BlendMode.srcATop,
      ),
      child: child,
    );
  }

  return Opacity(
    opacity: opacity.clamp(0.0, 1.0),
    child: child,
  );
}