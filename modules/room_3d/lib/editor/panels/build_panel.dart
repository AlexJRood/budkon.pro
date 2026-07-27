/// Panel dla trybu "Buduj" — rysowanie nowych ścian, wirtualnych pokoi i
/// schodów bezpośrednio w viewporcie 3D. Sam klik-w-podłogę żyje w scene.js
/// (`handleBuildClick`/`redrawBuildPreview`); ten panel tylko wybiera tryb
/// (ściana/wirtualny pokój/schody), przełącza "wirtualna ściana" i pokazuje
/// przycisk "Zakończ" dla wirtualnego pokoju (bo tylko użytkownik wie, kiedy
/// obrys jest gotowy — nie da się tego wywnioskować z samej liczby kliknięć).
library;

import 'package:core/theme/apptheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BuildPanel extends ConsumerWidget {
  /// `'wall'` | `'room'` | `'stair'` | `null` (nic nie wybrane — kliknięcia w
  /// viewporcie nic nie robią, dopóki użytkownik nie wybierze trybu).
  final String? buildMode;
  final bool isVirtualWall;
  final double thicknessM;
  final int pointCount;

  /// Angle-lock while placing points (FINAL_VISION.md §4) — ported from
  /// floor_plan's toggle + 15/30/45/90° step-picker convention. Shown
  /// regardless of buildMode (applies to both Ściana and Wirtualny pokój).
  final bool angleLockEnabled;
  final double angleStepDegrees;

  final ValueChanged<String?> onModeChanged;
  final ValueChanged<bool> onVirtualWallChanged;
  final ValueChanged<double> onThicknessChanged;
  final ValueChanged<bool> onAngleLockEnabledChanged;
  final ValueChanged<double> onAngleStepDegreesChanged;
  final VoidCallback onFinishRoom;
  final VoidCallback onCancel;

  const BuildPanel({
    super.key,
    required this.buildMode,
    required this.isVirtualWall,
    required this.thicknessM,
    required this.pointCount,
    required this.angleLockEnabled,
    required this.angleStepDegrees,
    required this.onModeChanged,
    required this.onVirtualWallChanged,
    required this.onThicknessChanged,
    required this.onAngleLockEnabledChanged,
    required this.onAngleStepDegreesChanged,
    required this.onFinishRoom,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Buduj',
          style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w900, fontSize: 15),
        ),
        const SizedBox(height: 4),
        Text(
          'Kliknij w podłogę, żeby dodać punkty. Rogi łapią do istniejących ścian — '
          'kliknij blisko narożnika, żeby zobaczyć pierścień potwierdzający zaczep. '
          'Przytrzymaj Shift, żeby wyprostować odcinek do poziomu/pionu (ma pierwszeństwo '
          'przed blokadą kąta poniżej). Przytrzymaj Alt, żeby na chwilę wyłączyć blokadę kąta. '
          'Esc, V lub S anuluje rysowanie.',
          style: TextStyle(color: theme.textColor.withAlpha(170), fontSize: 12),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Switch(value: angleLockEnabled, onChanged: onAngleLockEnabledChanged),
            Expanded(
              child: Text(
                'Blokada kąta',
                style: TextStyle(color: theme.textColor.withAlpha(200), fontSize: 12),
              ),
            ),
          ],
        ),
        if (angleLockEnabled) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children: [15.0, 30.0, 45.0, 90.0].map((step) {
              final selected = angleStepDegrees == step;
              return ChoiceChip(
                label: Text('${step.round()}°'),
                selected: selected,
                onSelected: (_) => onAngleStepDegreesChanged(step),
                labelStyle: TextStyle(
                  fontSize: 12,
                  color: selected ? theme.themeColor : theme.textColor.withAlpha(200),
                ),
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 14),
        _ModeCard(
          theme: theme,
          icon: Icons.straighten,
          title: 'Ściana',
          subtitle: 'Klik = kolejny narożnik, ściany łączą się w łańcuch · skrót W',
          selected: buildMode == 'wall',
          onTap: () => onModeChanged(buildMode == 'wall' ? null : 'wall'),
        ),
        if (buildMode == 'wall') ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Row(
              children: [
                Switch(
                  value: isVirtualWall,
                  onChanged: onVirtualWallChanged,
                ),
                Expanded(
                  child: Text(
                    'Ściana wirtualna (tylko podział, bez pełnej bryły)',
                    style: TextStyle(color: theme.textColor.withAlpha(200), fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Grubość ściany: ${(thicknessM * 100).round()} cm',
                  style: TextStyle(color: theme.textColor.withAlpha(200), fontSize: 12),
                ),
                Slider(
                  value: thicknessM.clamp(0.05, 0.30),
                  min: 0.05,
                  max: 0.30,
                  divisions: 25,
                  onChanged: onThicknessChanged,
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 10),
        _ModeCard(
          theme: theme,
          icon: Icons.crop_square,
          title: 'Wirtualny pokój',
          subtitle: 'Obrys strefy (np. aneks) — kliknij blisko startu, żeby zamknąć · skrót R',
          selected: buildMode == 'room',
          onTap: () => onModeChanged(buildMode == 'room' ? null : 'room'),
        ),
        if (buildMode == 'room') ...[
          const SizedBox(height: 10),
          Text(
            'Punkty: $pointCount${pointCount < 3 ? ' (min. 3)' : ''}',
            style: TextStyle(color: theme.textColor.withAlpha(200), fontSize: 12),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: pointCount >= 3 ? onFinishRoom : null,
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Zakończ obrys'),
          ),
        ],
        const SizedBox(height: 10),
        _ModeCard(
          theme: theme,
          icon: Icons.stairs,
          title: 'Schody',
          subtitle: 'Klik na start, klik na koniec biegu — łączy się z piętrem wyżej',
          selected: buildMode == 'stair',
          onTap: () => onModeChanged(buildMode == 'stair' ? null : 'stair'),
        ),
        if (buildMode != null) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onCancel,
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Anuluj'),
          ),
        ],
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  final dynamic theme;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ModeCard({
    required this.theme,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? theme.themeColor.withAlpha(40) : theme.textColor.withAlpha(8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? theme.themeColor.withAlpha(200) : theme.dashboardBoarder,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: selected ? theme.themeColor : theme.textColor.withAlpha(180)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: theme.textColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: theme.textColor.withAlpha(170), fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
