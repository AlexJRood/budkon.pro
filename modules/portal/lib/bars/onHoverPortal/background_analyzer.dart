import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

Future<bool> isBackgroundDark(ImageProvider imageProvider) async {
  final PaletteGenerator paletteGenerator = await PaletteGenerator.fromImageProvider(
    imageProvider,
    size: const Size(200, 100), // ograniczenie dla wydajności
  );

  final Color? dominantColor = paletteGenerator.dominantColor?.color;
  if (dominantColor == null) return false;

  // Prosta analiza jasności
  final double brightness = (dominantColor.r * 299 + dominantColor.g * 587 + dominantColor.b * 114) / 1000;

  return brightness < 128; // true = ciemne tło
}
