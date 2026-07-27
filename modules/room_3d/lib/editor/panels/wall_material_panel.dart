/// Picker materiału ścian — tryb Ściany/Płytki. Zamiast dowolnego
/// rysowania prostokąta na ścianie (osobny, dużo większy build: przeciąganie
/// gestem po powierzchni 3D, projekcja na lokalny UV ściany, podgląd na
/// żywo — nieproporcjonalne dla MVP), wybór celuje w nazwane presety stref.
/// To spina się 1:1 z `wall_selector: "all"|"backsplash"|"zone:<id>"` już
/// zdefiniowanym w Emma tools (`room3d_set_wall_material` po stronie
/// backendu) — ten sam mały zestaw nazwanych selektorów, nie osobny system.
library;

import 'package:core/theme/apptheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:surface_materials/surface_materials.dart';

import '../../actions/room_scene_actions.dart';
import '../../model/room_scene.dart';
import '../../providers/room_scene_provider.dart';

enum WallZonePreset {
  all,
  upperHalf,
  lowerHalf,
  backsplash;

  String get label => switch (this) {
        WallZonePreset.all => 'Cała ściana',
        WallZonePreset.upperHalf => 'Górna połowa',
        WallZonePreset.lowerHalf => 'Dolna połowa',
        WallZonePreset.backsplash => 'Fartuch (za szafkami)',
      };

  /// [min, max], both 0-1 of the wall's heightM. Not used for [all], which
  /// goes through `setWholeWallMaterial` instead of a zone — see
  /// `WallMaterialPanel._applyMaterial`.
  List<double> get heightRange => switch (this) {
        WallZonePreset.all => const [0.0, 1.0],
        WallZonePreset.upperHalf => const [0.5, 1.0],
        WallZonePreset.lowerHalf => const [0.0, 0.5],
        WallZonePreset.backsplash => const [0.35, 0.65],
      };
}

class WallMaterialPanel extends ConsumerStatefulWidget {
  final String? selectedWallId;

  /// 'door' | 'window' | null — placing a new opening directly on the
  /// selected wall (FINAL_VISION.md §4's last Buduj debt item). Owned by
  /// the editor page (not local widget state) since scene.js's next click
  /// needs to know about it too, via setPlacingOpening.
  final String? placingOpeningKind;
  final ValueChanged<String?> onPlacingOpeningKindChanged;

  const WallMaterialPanel({
    super.key,
    this.selectedWallId,
    required this.placingOpeningKind,
    required this.onPlacingOpeningKindChanged,
  });

  @override
  ConsumerState<WallMaterialPanel> createState() => _WallMaterialPanelState();
}

class _WallMaterialPanelState extends ConsumerState<WallMaterialPanel> {
  WallZonePreset _preset = WallZonePreset.all;

  void _applyMaterial(MaterialItem material) {
    final wallId = widget.selectedWallId;
    if (wallId == null) return;

    final actions = ref.read(roomSceneActionsProvider);

    if (_preset == WallZonePreset.all) {
      actions.setWholeWallMaterial(
        wallId: wallId,
        materialId: material.id,
        colorHex: material.previewColorHex,
      );
      return;
    }

    actions.setWallZoneMaterial(
      wallId: wallId,
      // Deterministic per wall+preset: re-picking a material for the same
      // named zone updates it in place instead of stacking duplicates.
      zoneId: 'zone_${wallId}_${_preset.name}',
      materialId: material.id,
      heightRange: _preset.heightRange,
      colorHex: material.previewColorHex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);

    if (widget.selectedWallId == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Materiały ścian',
            style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w900, fontSize: 15),
          ),
          const SizedBox(height: 10),
          Text(
            'Tap na ścianę w viewporcie, żeby ją zaznaczyć.',
            style: TextStyle(color: theme.textColor.withAlpha(170), fontSize: 12),
          ),
        ],
      );
    }

    final materials = ref.watch(surfaceMaterialsProvider);
    final floor = ref.watch(roomSceneProvider).activeFloor;
    RoomWall? selectedWall;
    for (final wall in floor?.walls ?? const <RoomWall>[]) {
      if (wall.id == widget.selectedWallId) {
        selectedWall = wall;
        break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Materiały ścian',
          style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w900, fontSize: 15),
        ),
        if (selectedWall != null) ...[
          const SizedBox(height: 10),
          Text(
            'Grubość ściany: ${(selectedWall.thicknessM * 100).round()} cm',
            style: TextStyle(color: theme.textColor.withAlpha(200), fontSize: 12),
          ),
          Slider(
            value: selectedWall.thicknessM.clamp(0.05, 0.30),
            min: 0.05,
            max: 0.30,
            divisions: 25,
            onChanged: (value) => ref.read(roomSceneActionsProvider).setWallThickness(
                  wallId: selectedWall!.id,
                  thicknessM: value,
                ),
          ),
          TextButton.icon(
            onPressed: () => ref.read(roomSceneActionsProvider).removeWall(selectedWall!.id),
            icon: const Icon(Icons.delete_outline, size: 16),
            label: const Text('Usuń ścianę'),
          ),
          const SizedBox(height: 6),
          Text(
            widget.placingOpeningKind != null
                ? 'Kliknij na ścianę, żeby postawić otwór.'
                : 'Dodaj otwór w tej ścianie:',
            style: TextStyle(color: theme.textColor.withAlpha(200), fontSize: 12),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => widget.onPlacingOpeningKindChanged(
                    widget.placingOpeningKind == 'door' ? null : 'door',
                  ),
                  icon: const Icon(Icons.sensor_door_outlined, size: 16),
                  label: const Text('Drzwi', style: TextStyle(fontSize: 12)),
                  style: widget.placingOpeningKind == 'door'
                      ? OutlinedButton.styleFrom(backgroundColor: theme.themeColor.withAlpha(40))
                      : null,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => widget.onPlacingOpeningKindChanged(
                    widget.placingOpeningKind == 'window' ? null : 'window',
                  ),
                  icon: const Icon(Icons.window_outlined, size: 16),
                  label: const Text('Okno', style: TextStyle(fontSize: 12)),
                  style: widget.placingOpeningKind == 'window'
                      ? OutlinedButton.styleFrom(backgroundColor: theme.themeColor.withAlpha(40))
                      : null,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: WallZonePreset.values
              .map(
                (preset) => ChoiceChip(
                  label: Text(preset.label, style: const TextStyle(fontSize: 11)),
                  selected: _preset == preset,
                  onSelected: (_) => setState(() => _preset = preset),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: materials.length,
            itemBuilder: (context, index) {
              final material = materials[index];
              final color = _parseHexColor(material.previewColorHex);

              return Tooltip(
                message: material.name,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => _applyMaterial(material),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: theme.dashboardBoarder),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

Color _parseHexColor(String hex) {
  final cleaned = hex.replaceFirst('#', '');
  final value = int.tryParse(cleaned, radix: 16) ?? 0xCCCCCC;
  return Color(0xFF000000 | value);
}
