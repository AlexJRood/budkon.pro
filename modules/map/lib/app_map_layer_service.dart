import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';

abstract class AppMapLayerService extends ChangeNotifier {
  String get id;

  bool get isBusy => false;
  String? get busyText => null;
  String? get errorText => null;

  Future<void> onViewportChanged({
    required WidgetRef ref,
    required MapController mapController,
  }) async {}

  /// Force-refreshes the current viewport.
  ///
  /// Default behavior is the same as normal viewport sync.
  /// Cache-aware layers can override this method to bypass/remove cache.
  Future<void> refreshCurrentViewport({
    required WidgetRef ref,
    required MapController mapController,
  }) async {
    await onViewportChanged(
      ref: ref,
      mapController: mapController,
    );
  }

  Future<bool> onTap({
    required WidgetRef ref,
    required MapController mapController,
    required TapPosition tapPosition,
  }) async {
    return false;
  }

  List<Widget> buildLayers({
    required BuildContext context,
    required WidgetRef ref,
    required MapController mapController,
    required ThemeColors theme,
    required double zoom,
  });

  List<Widget> buildOverlays({
    required BuildContext context,
    required WidgetRef ref,
    required ThemeColors theme,
  }) {
    return const [];
  }
}