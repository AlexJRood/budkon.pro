// Verifies room3d_emma_tool_seam.dart's override actually resolves through
// core's localToolExecutorRegistryProvider the same way the app shell wires
// it — the exact seam-plumbing this feature depends on, previously the
// missing half of Emma's Faza 3 dispatch gap (see
// docs/sims_mode/IMPLEMENTATION_CHECKLIST.md).
import 'package:core/kernel/kernel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:room_3d/room_3d.dart';
import 'package:room_3d/room3d_emma_tool_seam.dart';

void main() {
  test('room3dEmmaToolSeamOverrides registers all 7 executors by name', () {
    final container = ProviderContainer(overrides: room3dEmmaToolSeamOverrides);
    addTearDown(container.dispose);

    final registry = container.read(localToolExecutorRegistryProvider);

    expect(registry.keys, containsAll(<String>[
      'room3d_place_item',
      'room3d_move_item',
      'room3d_remove_item',
      'room3d_set_wall_material',
      'room3d_set_floor_material',
      'room3d_list_scene_items',
      'room3d_search_catalog',
    ]));
  });

  test('dispatching room3d_list_scene_items through the registry reads the live scene', () async {
    final container = ProviderContainer(overrides: room3dEmmaToolSeamOverrides);
    addTearDown(container.dispose);

    final scene = RoomScene.singleFloor(
      sourceKind: RoomSceneSourceKind.floorPlan,
      sourceId: 'test',
      walls: const [],
      rooms: const [RoomRoom(id: 'room_1', name: 'Salon')],
      items: const [
        RoomPlacedItem(
          id: 'item_1',
          catalogItemId: 'sofa_1',
          roomId: 'room_1',
          position: RoomPoint3(x: 0, y: 0, z: 0),
        ),
      ],
    );
    container.read(roomSceneProvider.notifier).loadScene(scene);

    final executor = container.read(localToolExecutorRegistryProvider)['room3d_list_scene_items']!;
    final result = await executor(const {'room_name': 'Salon'});

    expect(result['ok'], isTrue);
    expect(result['count'], 1);
    expect((result['items'] as List).first, containsPair('item_id', 'item_1'));
  });

  test('an ambiguous room name surfaces {ok:false, matches:[...]} for Emma to ask for clarification', () async {
    final container = ProviderContainer(overrides: room3dEmmaToolSeamOverrides);
    addTearDown(container.dispose);

    final scene = RoomScene.singleFloor(
      sourceKind: RoomSceneSourceKind.floorPlan,
      sourceId: 'test',
      walls: const [],
      rooms: const [
        RoomRoom(id: 'room_1', name: 'Sypialnia dziecka'),
        RoomRoom(id: 'room_2', name: 'Sypialnia rodziców'),
      ],
      items: const [],
    );
    container.read(roomSceneProvider.notifier).loadScene(scene);

    final executor = container.read(localToolExecutorRegistryProvider)['room3d_list_scene_items']!;
    final result = await executor(const {'room_name': 'Sypialnia'});

    expect(result['ok'], isFalse);
    expect(result['matches'], isA<List>());
    expect((result['matches'] as List).length, 2);
  });
}
