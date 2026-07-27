/// Picker materiału podłogi — tryb Podłoga. Celuje w pokój wskazany kliknięciem
/// podłogi w viewporcie (`selectedRoomId`, patrz scene.js's onPointerDown
/// floor-hit branch + room_3d_editor_page.dart's 'roomSelected' handler);
/// dopóki nic nie zostało kliknięte (albo scena ma tylko jeden pokój), pada
/// z powrotem na pierwszy pokój sceny, tak jak wcześniej.
library;

import 'package:core/theme/apptheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:surface_materials/surface_materials.dart';

import '../../actions/room_scene_actions.dart';
import '../../model/room_scene.dart';
import '../../providers/room_scene_provider.dart';

/// Shoelace formula — `RoomRoom.points` are already a simple (non-self-
/// intersecting) polygon in meters, same assumption `_synthesizeRoomFromWalls`
/// in `room_scene_builder.dart` makes when tracing one from wall endpoints.
double _polygonAreaM2(List<RoomPoint2> points) {
  if (points.length < 3) return 0;
  var sum = 0.0;
  for (var i = 0; i < points.length; i++) {
    final a = points[i];
    final b = points[(i + 1) % points.length];
    sum += a.x * b.y - b.x * a.y;
  }
  return sum.abs() / 2;
}

class FloorMaterialPanel extends ConsumerWidget {
  final String? selectedRoomId;

  const FloorMaterialPanel({super.key, this.selectedRoomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    final rooms = ref.watch(roomSceneProvider).activeFloor?.rooms ?? const [];

    if (rooms.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Materiał podłogi',
            style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w900, fontSize: 15),
          ),
          const SizedBox(height: 10),
          Text(
            'Wczytaj najpierw scenę.',
            style: TextStyle(color: theme.textColor.withAlpha(170), fontSize: 12),
          ),
        ],
      );
    }

    final room = rooms.firstWhere(
      (r) => r.id == selectedRoomId,
      orElse: () => rooms.first,
    );
    final materials = ref.watch(surfaceMaterialsProvider);
    final woodAndPanel = materials
        .where((m) => m.category == MaterialCategory.wood || m.category == MaterialCategory.panel)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Materiał podłogi',
          style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w900, fontSize: 15),
        ),
        const SizedBox(height: 4),
        Text(
          'Pokój: ${room.name}',
          style: TextStyle(color: theme.textColor.withAlpha(170), fontSize: 12),
        ),
        Text(
          'Powierzchnia: ${_polygonAreaM2(room.points).toStringAsFixed(1)} m²',
          style: TextStyle(color: theme.textColor.withAlpha(170), fontSize: 12),
        ),
        if (selectedRoomId != null) ...[
          const SizedBox(height: 8),
          // Gated on selectedRoomId (an explicit click), not just `room` —
          // `room` falls back to the first room in the scene when nothing's
          // been clicked, and offering to delete THAT unprompted would be a
          // surprising, easy-to-misclick destructive action.
          TextButton.icon(
            onPressed: () => ref.read(roomSceneActionsProvider).removeRoom(room.id),
            icon: const Icon(Icons.delete_outline, size: 16),
            label: const Text('Usuń pokój'),
          ),
        ],
        const SizedBox(height: 12),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: woodAndPanel.length,
            itemBuilder: (context, index) {
              final material = woodAndPanel[index];
              final color = _parseHexColor(material.previewColorHex);

              return Tooltip(
                message: material.name,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => ref.read(roomSceneActionsProvider).setFloorMaterial(
                        roomId: room.id,
                        materialId: material.id,
                        colorHex: material.previewColorHex,
                      ),
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
