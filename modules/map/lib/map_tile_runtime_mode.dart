import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum MapTileRuntimeMode {
  smartCache,
  live,
}

final mapTileRuntimeModeProvider =
    StateProvider<MapTileRuntimeMode>((ref) {
  // Na Windows bezpieczniej startować od live.
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
    return MapTileRuntimeMode.live;
  }
  return MapTileRuntimeMode.smartCache;
});