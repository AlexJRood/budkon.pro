import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:portal/screens/feed/components/map/map_visuals.dart';
import 'package:core/theme/apptheme.dart';

class MapStyleSelector extends ConsumerWidget {
  final bool compact;
  final VoidCallback? onMenuOpened;
  final VoidCallback? onMenuClosed;

  const MapStyleSelector({
    super.key,
    this.compact = true,
    this.onMenuOpened,
    this.onMenuClosed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final selectedMode = ref.watch(mapTileStyleModeProvider);

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: PopupMenuButton<MapTileStyleMode>(
        tooltip: 'map_style'.tr,
        onOpened: onMenuOpened,
        onCanceled: () {
          onMenuClosed?.call();
        },
        onSelected: (mode) {
          ref.read(mapTileStyleModeProvider.notifier).setMode(mode);

          Future.delayed(const Duration(milliseconds: 150), () {
            onMenuClosed?.call();
          });
        },
        itemBuilder: (context) {
          return MapTileStyleMode.values.map((mode) {
            final isSelected = mode == selectedMode;

            return PopupMenuItem<MapTileStyleMode>(
              value: mode,
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    size: 18,
                    color: isSelected ? theme.themeColor : theme.textColor,
                  ),
                  const SizedBox(width: 10),
                  Text(mode.label),
                ],
              ),
            );
          }).toList();
        },
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.layers_rounded,
                size: 18,
                color: theme.textColor,
              ),
              if (!compact) ...[
                const SizedBox(width: 8),
                Text(
                  'map_style'.tr,
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(width: 6),
              Icon(
                Icons.arrow_drop_down_rounded,
                color: theme.textColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}