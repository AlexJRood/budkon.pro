/// Editor toolbar — 3 tryby (Meble / Ściany-Płytki / Podłoga), wzorem
/// [floor_plan_canvas_toolbar.dart](../../../floor_plan/lib/canvas/floor_plan_canvas_toolbar.dart)
/// (ten sam breakpoint mobile <600px, ten sam wizualny język grup/przycisków,
/// `ref.read(themeColorsProvider)` zamiast `Theme.of(context)` — konwencja
/// projektu). Widgety pomocnicze (_ToolbarGroup/_ToolButton/_ToolbarIconButton)
/// są świadomie zduplikowane, nie importowane — floor_plan trzyma je jako
/// prywatne klasy `part of`, więc nie da się ich reużyć stąd.
library;

import 'package:core/theme/apptheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum Room3dTool {
  furniture,
  walls,
  floor,
  build;

  String get label => switch (this) {
        Room3dTool.furniture => 'Meble',
        Room3dTool.walls => 'Ściany / Płytki',
        Room3dTool.floor => 'Podłoga',
        Room3dTool.build => 'Buduj',
      };

  IconData get icon => switch (this) {
        Room3dTool.furniture => Icons.weekend_outlined,
        Room3dTool.walls => Icons.format_paint_outlined,
        Room3dTool.floor => Icons.grid_on_outlined,
        Room3dTool.build => Icons.architecture_outlined,
      };
}

class Room3dToolbar extends ConsumerWidget {
  final Room3dTool selectedTool;
  final ValueChanged<Room3dTool> onToolChanged;

  final bool canUndo;
  final bool canRedo;
  final VoidCallback onUndo;
  final VoidCallback onRedo;

  final ValueChanged<String> onCameraPreset;
  final VoidCallback onLoadTestScene;

  final bool isSaving;
  final String saveStatusLabel;
  final VoidCallback? onSave;

  final bool cutawayEnabled;
  final ValueChanged<bool> onCutawayEnabledChanged;

  final bool walkModeEnabled;
  final ValueChanged<bool> onWalkModeEnabledChanged;

  final bool measureModeEnabled;
  final ValueChanged<bool> onMeasureModeEnabledChanged;

  /// "Zrzut ekranu" (FINAL_VISION.md §7.4) — captures the current viewport
  /// as a PNG and opens a native "Save As" dialog.
  final VoidCallback onScreenshot;

  /// Eksport glTF (§7.4, ostatni/najniższy priorytet w tej grupie) — cała
  /// geometria aktywnego piętra jako pojedynczy plik .glb.
  final VoidCallback onGltfExport;

  /// "Plan z góry" (§7.4's "rzut z góry z wymiarami") — rzut ortograficzny
  /// z góry z wypalonymi długościami ścian, zapisany jako PNG.
  final VoidCallback onTopDownPlanExport;

  /// "Wymiary" (FINAL_VISION.md §7.1) — permanent per-wall length labels,
  /// distinct from the on-demand Miarka tool.
  final bool dimensionsEnabled;
  final ValueChanged<bool> onDimensionsEnabledChanged;

  /// "Tryb prezentacyjny" (FINAL_VISION.md §7.3) — soft shadows + warmer
  /// fill light, off by default (more expensive than the flat working mode).
  final bool presentationModeEnabled;
  final ValueChanged<bool> onPresentationModeEnabledChanged;

  /// "Sąsiednie piętra" (FINAL_VISION.md §6's true floor stacking) —
  /// whether the floor below/above render as dimmed 3D context you can
  /// click to switch to. No-op if there's no floor there.
  final bool showAdjacentFloors;
  final ValueChanged<bool> onShowAdjacentFloorsChanged;

  /// Floor switcher (Option A: `RoomScene.floors`, see `room_scene.dart`).
  /// `floorLabels` is deliberately just labels, not full `RoomFloor`s — the
  /// toolbar only ever needs to show/select by name.
  final List<String> floorLabels;
  final int activeFloorIndex;
  final ValueChanged<int> onFloorSelected;
  final VoidCallback onAddFloor;
  final VoidCallback onRemoveActiveFloor;

  /// Active floor's story height (§6) — the per-floor, user-editable
  /// vertical stacking height, edited inline in the floor switcher's
  /// dropdown.
  final double activeFloorStoryHeightM;
  final ValueChanged<double> onStoryHeightChanged;

  const Room3dToolbar({
    super.key,
    required this.selectedTool,
    required this.onToolChanged,
    required this.canUndo,
    required this.canRedo,
    required this.onUndo,
    required this.onRedo,
    required this.onCameraPreset,
    required this.onLoadTestScene,
    required this.isSaving,
    required this.saveStatusLabel,
    required this.onSave,
    required this.walkModeEnabled,
    required this.onWalkModeEnabledChanged,
    required this.measureModeEnabled,
    required this.onMeasureModeEnabledChanged,
    required this.cutawayEnabled,
    required this.onCutawayEnabledChanged,
    required this.onScreenshot,
    required this.onGltfExport,
    required this.onTopDownPlanExport,
    required this.dimensionsEnabled,
    required this.onDimensionsEnabledChanged,
    required this.presentationModeEnabled,
    required this.onPresentationModeEnabledChanged,
    required this.showAdjacentFloors,
    required this.onShowAdjacentFloorsChanged,
    required this.floorLabels,
    required this.activeFloorIndex,
    required this.onFloorSelected,
    required this.onAddFloor,
    required this.onRemoveActiveFloor,
    required this.activeFloorStoryHeightM,
    required this.onStoryHeightChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (isMobile) return _buildMobileBar(theme);

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        border: Border(bottom: BorderSide(color: theme.dashboardBoarder)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _ToolbarGroup(
            theme: theme,
            children: [
              _ToolbarIconButton(
                theme: theme,
                icon: Icons.undo,
                tooltip: 'Cofnij',
                onPressed: canUndo ? onUndo : null,
              ),
              _ToolbarIconButton(
                theme: theme,
                icon: Icons.redo,
                tooltip: 'Ponów',
                onPressed: canRedo ? onRedo : null,
              ),
            ],
          ),
          const SizedBox(width: 10),
          _ToolbarGroup(
            theme: theme,
            label: 'Tryb edycji',
            children: Room3dTool.values
                .map(
                  (tool) => _ToolButton(
                    theme: theme,
                    selected: selectedTool == tool,
                    icon: tool.icon,
                    label: tool.label,
                    tooltip: tool.label,
                    onTap: () => onToolChanged(tool),
                  ),
                )
                .toList(),
          ),
          const SizedBox(width: 10),
          _FloorSwitcher(
            theme: theme,
            floorLabels: floorLabels,
            activeFloorIndex: activeFloorIndex,
            onFloorSelected: onFloorSelected,
            onAddFloor: onAddFloor,
            onRemoveActiveFloor: onRemoveActiveFloor,
            activeFloorStoryHeightM: activeFloorStoryHeightM,
            onStoryHeightChanged: onStoryHeightChanged,
          ),
          const SizedBox(width: 10),
          _ToolbarGroup(
            theme: theme,
            label: 'Kamera',
            children: [
              _ToolbarIconButton(
                theme: theme,
                icon: Icons.vertical_align_top,
                tooltip: 'Widok z góry',
                onPressed: () => onCameraPreset('topDown'),
              ),
              _ToolbarIconButton(
                theme: theme,
                icon: Icons.threed_rotation,
                tooltip: 'Widok swobodny',
                onPressed: () => onCameraPreset('orbit'),
              ),
              _ToolbarIconButton(
                theme: theme,
                icon: Icons.restart_alt,
                tooltip: 'Reset widoku',
                onPressed: () => onCameraPreset('reset'),
              ),
              _ToolbarIconButton(
                theme: theme,
                icon: cutawayEnabled ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                tooltip: cutawayEnabled
                    ? 'Chowanie bliskich ścian: włączone (skrót C)'
                    : 'Chowanie bliskich ścian: wyłączone (skrót C)',
                onPressed: () => onCutawayEnabledChanged(!cutawayEnabled),
              ),
              _ToolbarIconButton(
                theme: theme,
                icon: Icons.directions_walk,
                tooltip: walkModeEnabled
                    ? 'Zwiedzanie (pierwsza osoba): włączone — WASD/strzałki, przeciągnij żeby się rozejrzeć (skrót F)'
                    : 'Zwiedzanie (pierwsza osoba): wyłączone (skrót F)',
                onPressed: () => onWalkModeEnabledChanged(!walkModeEnabled),
                selected: walkModeEnabled,
              ),
              _ToolbarIconButton(
                theme: theme,
                icon: Icons.straighten,
                tooltip: measureModeEnabled
                    ? 'Miarka: włączona — kliknij dwa punkty, Esc czyści pomiar (skrót M)'
                    : 'Miarka: wyłączona (skrót M)',
                onPressed: () => onMeasureModeEnabledChanged(!measureModeEnabled),
                selected: measureModeEnabled,
              ),
              _ToolbarIconButton(
                theme: theme,
                icon: Icons.photo_camera_outlined,
                tooltip: 'Zrzut ekranu',
                onPressed: onScreenshot,
              ),
              _ToolbarIconButton(
                theme: theme,
                icon: Icons.view_in_ar_outlined,
                tooltip: 'Eksportuj do glTF (.glb)',
                onPressed: onGltfExport,
              ),
              _ToolbarIconButton(
                theme: theme,
                icon: Icons.map_outlined,
                tooltip: 'Plan z góry z wymiarami (PNG)',
                onPressed: onTopDownPlanExport,
              ),
              _ToolbarIconButton(
                theme: theme,
                icon: Icons.square_foot_outlined,
                tooltip: dimensionsEnabled
                    ? 'Wymiary ścian: włączone'
                    : 'Wymiary ścian: wyłączone',
                onPressed: () => onDimensionsEnabledChanged(!dimensionsEnabled),
                selected: dimensionsEnabled,
              ),
              _ToolbarIconButton(
                theme: theme,
                icon: Icons.wb_incandescent_outlined,
                tooltip: presentationModeEnabled
                    ? 'Tryb prezentacyjny (miękkie cienie): włączony'
                    : 'Tryb prezentacyjny (miękkie cienie): wyłączony',
                onPressed: () => onPresentationModeEnabledChanged(!presentationModeEnabled),
                selected: presentationModeEnabled,
              ),
              _ToolbarIconButton(
                theme: theme,
                icon: Icons.layers_outlined,
                tooltip: showAdjacentFloors
                    ? 'Sąsiednie piętra (klik = przełącz): włączone'
                    : 'Sąsiednie piętra (klik = przełącz): wyłączone',
                onPressed: () => onShowAdjacentFloorsChanged(!showAdjacentFloors),
                selected: showAdjacentFloors,
              ),
            ],
          ),
          const Spacer(),
          Text(
            saveStatusLabel,
            style: TextStyle(color: theme.textColor.withAlpha(150), fontSize: 11),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: isSaving ? null : onSave,
            icon: isSaving
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined, size: 18),
            label: const Text('Zapisz'),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: onLoadTestScene,
            icon: const Icon(Icons.science_outlined, size: 18),
            label: const Text('Scena testowa'),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileBar(dynamic theme) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        border: Border(bottom: BorderSide(color: theme.dashboardBoarder)),
      ),
      child: Row(
        children: [
          _ToolbarGroup(
            theme: theme,
            children: [
              _ToolbarIconButton(
                theme: theme,
                icon: Icons.undo,
                tooltip: 'Cofnij',
                onPressed: canUndo ? onUndo : null,
              ),
              _ToolbarIconButton(
                theme: theme,
                icon: Icons.redo,
                tooltip: 'Ponów',
                onPressed: canRedo ? onRedo : null,
              ),
            ],
          ),
          const SizedBox(width: 6),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: Room3dTool.values
                    .map(
                      (tool) => _ToolButton(
                        theme: theme,
                        selected: selectedTool == tool,
                        icon: tool.icon,
                        label: tool.label,
                        tooltip: tool.label,
                        onTap: () => onToolChanged(tool),
                        forceIconOnly: true,
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          _ToolbarIconButton(
            theme: theme,
            icon: Icons.vertical_align_top,
            tooltip: 'Widok z góry',
            onPressed: () => onCameraPreset('topDown'),
          ),
          _ToolbarIconButton(
            theme: theme,
            icon: Icons.restart_alt,
            tooltip: 'Reset widoku',
            onPressed: () => onCameraPreset('reset'),
          ),
          isSaving
              ? const Padding(
                  padding: EdgeInsets.all(10),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : _ToolbarIconButton(
                  theme: theme,
                  icon: Icons.save_outlined,
                  tooltip: 'Zapisz',
                  onPressed: onSave,
                ),
        ],
      ),
    );
  }
}

class _ToolbarGroup extends StatelessWidget {
  final dynamic theme;
  final String? label;
  final List<Widget> children;

  const _ToolbarGroup({required this.theme, required this.children, this.label});

  @override
  Widget build(BuildContext context) {
    final content = Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: theme.textColor.withAlpha(10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dashboardBoarder.withAlpha(180)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
    );

    if (label == null) return content;

    return Tooltip(
      message: label!,
      waitDuration: const Duration(milliseconds: 600),
      child: content,
    );
  }
}

class _ToolButton extends StatelessWidget {
  final dynamic theme;
  final bool selected;
  final IconData icon;
  final String label;
  final String tooltip;
  final VoidCallback onTap;
  final bool forceIconOnly;

  const _ToolButton({
    required this.theme,
    required this.selected,
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.onTap,
    this.forceIconOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final showLabel = !forceIconOnly && MediaQuery.of(context).size.width >= 600;
    final color = selected ? theme.textColor : theme.textColor.withAlpha(150);
    final background =
        selected ? theme.themeColor.withAlpha(210) : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 130),
            height: 36,
            padding: EdgeInsets.symmetric(horizontal: showLabel ? 10 : 8),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? theme.themeColor.withAlpha(230) : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: color),
                if (showLabel) ...[
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Piętro (floor) switcher — a compact dropdown of floor labels plus
/// add/remove icon buttons. Kept as a `PopupMenuButton` rather than a row of
/// chips (as `_ToolButton` does for the 4 fixed edit modes) since the floor
/// count is unbounded and a wide multi-storey building shouldn't blow out
/// the toolbar's width.
class _FloorSwitcher extends StatelessWidget {
  final dynamic theme;
  final List<String> floorLabels;
  final int activeFloorIndex;
  final ValueChanged<int> onFloorSelected;
  final VoidCallback onAddFloor;
  final VoidCallback onRemoveActiveFloor;
  final double activeFloorStoryHeightM;
  final ValueChanged<double> onStoryHeightChanged;

  const _FloorSwitcher({
    required this.theme,
    required this.floorLabels,
    required this.activeFloorIndex,
    required this.onFloorSelected,
    required this.onAddFloor,
    required this.onRemoveActiveFloor,
    required this.activeFloorStoryHeightM,
    required this.onStoryHeightChanged,
  });

  /// A dialog rather than a slider inside the `PopupMenuButton` above —
  /// popup menu items dismiss the menu on interaction, which fights with
  /// dragging a slider. Sliders in this codebase commit via `onChangeEnd`
  /// only (an established convention — see `WallMaterialPanel`'s thickness
  /// slider), not `onChanged`, so a full floor-stacking reload doesn't fire
  /// on every pixel of drag, only once when you let go.
  Future<void> _showStoryHeightDialog(BuildContext context) async {
    double pending = activeFloorStoryHeightM;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Wysokość kondygnacji'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${pending.toStringAsFixed(2)} m'),
              Slider(
                value: pending.clamp(2.0, 4.5),
                min: 2.0,
                max: 4.5,
                divisions: 25,
                onChanged: (value) => setDialogState(() => pending = value),
                onChangeEnd: onStoryHeightChanged,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Zamknij'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeLabel = activeFloorIndex >= 0 && activeFloorIndex < floorLabels.length
        ? floorLabels[activeFloorIndex]
        : '—';

    return _ToolbarGroup(
      theme: theme,
      label: 'Piętra',
      children: [
        PopupMenuButton<int>(
          tooltip: 'Wybierz piętro',
          initialValue: activeFloorIndex,
          onSelected: onFloorSelected,
          itemBuilder: (context) => [
            for (var i = 0; i < floorLabels.length; i++)
              PopupMenuItem<int>(
                value: i,
                child: Row(
                  children: [
                    if (i == activeFloorIndex)
                      Icon(Icons.check, size: 16, color: theme.themeColor)
                    else
                      const SizedBox(width: 16),
                    const SizedBox(width: 8),
                    Text(floorLabels[i]),
                  ],
                ),
              ),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.layers_outlined, size: 18, color: theme.textColor.withAlpha(180)),
                const SizedBox(width: 6),
                Text(
                  activeLabel,
                  style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w700, fontSize: 12),
                ),
                Icon(Icons.arrow_drop_down, size: 18, color: theme.textColor.withAlpha(150)),
              ],
            ),
          ),
        ),
        _ToolbarIconButton(
          theme: theme,
          icon: Icons.add,
          tooltip: 'Dodaj piętro',
          onPressed: onAddFloor,
        ),
        _ToolbarIconButton(
          theme: theme,
          icon: Icons.delete_outline,
          tooltip: floorLabels.length > 1 ? 'Usuń bieżące piętro' : 'Nie można usunąć jedynego piętra',
          onPressed: floorLabels.length > 1 ? onRemoveActiveFloor : null,
        ),
        _ToolbarIconButton(
          theme: theme,
          icon: Icons.height,
          tooltip: 'Wysokość kondygnacji: ${activeFloorStoryHeightM.toStringAsFixed(2)} m',
          onPressed: () => _showStoryHeightDialog(context),
        ),
      ],
    );
  }
}

class _ToolbarIconButton extends StatelessWidget {
  final dynamic theme;
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool selected;

  const _ToolbarIconButton({
    required this.theme,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    return Tooltip(
      message: tooltip,
      child: IconButton(
        visualDensity: VisualDensity.compact,
        onPressed: onPressed,
        style: selected
            ? IconButton.styleFrom(backgroundColor: theme.themeColor.withAlpha(60))
            : null,
        icon: Icon(
          icon,
          size: 20,
          color: selected
              ? theme.themeColor
              : (enabled ? theme.textColor : theme.textColor.withAlpha(70)),
        ),
      ),
    );
  }
}
