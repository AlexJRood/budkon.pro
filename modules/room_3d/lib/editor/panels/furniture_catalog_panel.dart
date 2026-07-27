/// Katalog mebli — tryb Meble. Renderuje siatkę pozycji z
/// `furniture_catalog` (na razie `devFurnitureCatalog`, seed bez prawdziwych
/// assetów — Faza 2 podmienia to na realny katalog partnera, kształt
/// `List<CatalogItem>` się nie zmienia). Tap stawia mebel w pierwszym pokoju
/// aktywnej sceny przez `RoomSceneActions.placeItem` — jeśli scena nie jest
/// wczytana, pokazuje komunikat zamiast cichego no-opa.
library;

import 'package:core/theme/apptheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:furniture_catalog/furniture_catalog.dart';

import '../../actions/room_scene_actions.dart';
import '../../model/room_scene.dart';
import '../../providers/room_scene_provider.dart';

IconData _iconForCategory(CatalogItemCategory category) => switch (category) {
      CatalogItemCategory.sofa => Icons.weekend_outlined,
      CatalogItemCategory.bed => Icons.bed_outlined,
      CatalogItemCategory.table => Icons.table_restaurant_outlined,
      CatalogItemCategory.chair => Icons.chair_outlined,
      CatalogItemCategory.kitchen => Icons.kitchen_outlined,
      CatalogItemCategory.wardrobe => Icons.door_sliding_outlined,
      CatalogItemCategory.bathroom => Icons.bathtub_outlined,
      CatalogItemCategory.lighting => Icons.light_outlined,
      CatalogItemCategory.decor => Icons.local_florist_outlined,
      CatalogItemCategory.other => Icons.category_outlined,
    };

class FurnitureCatalogPanel extends ConsumerWidget {
  const FurnitureCatalogPanel({super.key});

  RoomRoom? _targetRoom(WidgetRef ref) {
    final rooms = ref.read(roomSceneProvider).activeFloor?.rooms ?? const [];
    return rooms.isEmpty ? null : rooms.first;
  }

  RoomPoint3 _placementPosition(WidgetRef ref, RoomRoom room) {
    final placedCount = ref
        .read(roomSceneProvider)
        .activeFloor!
        .items
        .where((item) => item.roomId == room.id)
        .length;

    final origin = room.points.isNotEmpty ? room.points.first : const RoomPoint2(x: 0, y: 0);
    // Naive stagger so repeated taps don't stack items exactly on top of
    // each other — a real "drop where the user is looking" flow belongs to
    // the viewport interaction, not this panel.
    return RoomPoint3(x: origin.x + 0.8 + placedCount * 0.7, y: origin.y + 0.8, z: 0);
  }

  void _placeItem(BuildContext context, WidgetRef ref, CatalogItem catalogItem) {
    final room = _targetRoom(ref);

    if (room == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wczytaj najpierw scenę, żeby postawić mebel.')),
      );
      return;
    }

    ref.read(roomSceneActionsProvider).placeItem(
          id: 'item_${DateTime.now().microsecondsSinceEpoch}',
          catalogItemId: catalogItem.id,
          roomId: room.id,
          position: _placementPosition(ref, room),
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    final catalog = ref.watch(furnitureCatalogProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Katalog mebli',
          style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w900, fontSize: 15),
        ),
        const SizedBox(height: 4),
        Text(
          'Tap na pozycję, żeby postawić ją w pokoju.',
          style: TextStyle(color: theme.textColor.withAlpha(170), fontSize: 12),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.85,
            ),
            itemCount: catalog.length,
            itemBuilder: (context, index) {
              final item = catalog[index];

              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _placeItem(context, ref, item),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.textColor.withAlpha(10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.dashboardBoarder),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: Icon(
                          _iconForCategory(item.category),
                          size: 32,
                          color: theme.themeColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.textColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        '${item.dimensions.widthM.toStringAsFixed(1)}×'
                        '${item.dimensions.depthM.toStringAsFixed(1)} m',
                        style: TextStyle(color: theme.textColor.withAlpha(140), fontSize: 10),
                      ),
                    ],
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
