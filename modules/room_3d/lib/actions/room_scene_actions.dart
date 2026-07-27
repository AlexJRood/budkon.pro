/// Public mutation API for the active [RoomScene]. Both the editor UI
/// (toolbar/panels) and, from Faza 3 onward, Emma's local tool executors go
/// through this single surface — see docs/sims_mode/ARCHITECTURE.md sections
/// 6-7. Nothing else is allowed to mutate `roomSceneProvider` directly.

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:furniture_catalog/furniture_catalog.dart';

import '../model/room_scene.dart';
import '../providers/room_scene_provider.dart';

/// Command sent to the three.js viewer after a state mutation. The viewer
/// bridge (`viewer/room_3d_webview.dart`, Faza 1) wires a listener here; kept
/// as a plain callback so actions/tests don't need a live WebView.
typedef RoomSceneCommand = void Function(String type, Map<String, dynamic> payload);

class RoomSceneActions {
  final Ref ref;
  final RoomSceneCommand? onCommand;

  const RoomSceneActions(this.ref, {this.onCommand});

  RoomSceneNotifier get _notifier => ref.read(roomSceneProvider.notifier);

  int get _activeFloorIndex => ref.read(roomSceneProvider).activeFloorIndex;

  /// Every mutation method below reads/writes exactly one entry of
  /// `scene.floors` — the one currently active — rather than top-level scene
  /// fields (pre-floors, `RoomScene` itself held the flat entity lists).
  /// Centralized here so each method keeps its existing single-floor-shaped
  /// logic (`floor.copyWith(...)`) unchanged, just wrapped.
  RoomScene _replaceActiveFloor(RoomScene scene, RoomFloor Function(RoomFloor floor) update) {
    final index = _activeFloorIndex.clamp(0, scene.floors.length - 1);
    final floors = List<RoomFloor>.from(scene.floors);
    floors[index] = update(floors[index]);
    return scene.copyWith(floors: floors);
  }

  /// `is_light`: true is a bridge-only rendering hint, deliberately NOT part
  /// of the canonical `RoomPlacedItem` (same pattern as `setWallZoneMaterial`'s
  /// `colorHex` — a denormalized fact the viewer needs but that belongs to
  /// the Flutter-side furniture_catalog, not the scene document). scene.js
  /// has no catalog access of its own, so any item json crossing the bridge
  /// needs this tagged on here first — see `buildItem`'s `is_light` handling
  /// in scene.js (FINAL_VISION.md §7.5: lamps as real THREE.PointLights).
  Map<String, dynamic> _itemJsonForViewer(RoomPlacedItem item) {
    final json = item.toJson();
    final catalogItem =
        ref.read(furnitureCatalogProvider).where((c) => c.id == item.catalogItemId).firstOrNull;
    if (catalogItem?.category == CatalogItemCategory.lighting) json['is_light'] = true;
    // Same bridge-only-hint pattern as `is_light` above: scene.js has no
    // catalog access, so a placed item needs its real glTF asset path (if
    // the catalog has one — dev items now do, see dev_catalog.dart) tagged
    // on here. Empty/missing `glb_url` falls back to the existing colored
    // box placeholder in `buildItem`.
    if (catalogItem != null && catalogItem.glbUrl.trim().isNotEmpty) {
      json['glb_url'] = catalogItem.glbUrl;
    }
    return json;
  }

  /// Full payload for the viewer's `loadScene` command: the active floor's
  /// own data (as before floors existed) plus, for FINAL_VISION.md §6's true
  /// floor stacking, the immediately adjacent floors (±1 only — bounds how
  /// much extra geometry the viewer holds regardless of building size) as
  /// dimmed, non-interactive context at their correct relative Y offset.
  /// Reads the "sąsiednie piętra" toggle from `roomSceneProvider` itself
  /// (view state, see `RoomSceneState.showAdjacentFloors`) rather than
  /// taking it as a parameter — every call site already has a `ref` handy,
  /// and threading a bool through every caller for state this method can
  /// read itself would just be noise. Used wherever a floor's full data
  /// crosses the bridge in one shot (floor switch/undo/redo via
  /// [_reloadViewerFromState]; the initial load and pending-load flush in
  /// `room_3d_editor_page.dart`).
  Map<String, dynamic> floorStackPayload(RoomScene scene, int activeIndex) {
    final index = activeIndex.clamp(0, scene.floors.length - 1);
    final active = scene.floors[index];
    final showAdjacentFloors = ref.read(roomSceneProvider).showAdjacentFloors;

    Map<String, dynamic>? neighborPayload(RoomFloor floor, double yOffset) {
      final payload = floor.toViewerPayload();
      final items = floor.items.map(_itemJsonForViewer).toList();
      return {...payload, 'items': items, 'y_offset': yOffset};
    }

    final payload = active.toViewerPayload();
    final items = active.items.map(_itemJsonForViewer).toList();

    return {
      ...payload,
      'items': items,
      'below': showAdjacentFloors && index > 0
          ? neighborPayload(scene.floors[index - 1], -scene.floors[index - 1].storyHeightM)
          : null,
      'above': showAdjacentFloors && index < scene.floors.length - 1
          ? neighborPayload(scene.floors[index + 1], active.storyHeightM)
          : null,
    };
  }

  /// Changes a floor's story height (FINAL_VISION.md §6's vertical stacking
  /// — per-floor, user-editable, not one global constant, since real
  /// buildings often vary this per storey). Editing a LOWER floor's height
  /// shifts every floor above it too — that's not special-cased here, it
  /// falls out naturally from `floorStackPayload` always recomputing offsets
  /// from `storyHeightM` fresh rather than caching absolute Y positions.
  void setFloorStoryHeight(int floorIndex, double heightM) {
    _notifier.applyMutation((scene) {
      if (floorIndex < 0 || floorIndex >= scene.floors.length) return scene;
      final floors = List<RoomFloor>.from(scene.floors);
      floors[floorIndex] = floors[floorIndex].copyWith(storyHeightM: heightM);
      return scene.copyWith(floors: floors);
    });

    _reloadViewerFromState();
  }

  void placeItem({
    required String id,
    required String catalogItemId,
    required String roomId,
    required RoomPoint3 position,
    double rotationDeg = 0.0,
    double scale = 1.0,
  }) {
    final item = RoomPlacedItem(
      id: id,
      catalogItemId: catalogItemId,
      position: position,
      rotationDeg: rotationDeg,
      scale: scale,
      roomId: roomId,
    );

    _notifier.applyMutation(
      (scene) => _replaceActiveFloor(scene, (floor) => floor.copyWith(items: [...floor.items, item])),
    );

    onCommand?.call('placeItem', _itemJsonForViewer(item));
  }

  void moveItem({
    required String itemId,
    RoomPoint3? position,
    double? rotationDeg,
    double? scale,
  }) {
    _notifier.applyMutation((scene) {
      return _replaceActiveFloor(scene, (floor) {
        final items = floor.items.map((item) {
          if (item.id != itemId) return item;
          return item.copyWith(position: position, rotationDeg: rotationDeg, scale: scale);
        }).toList();

        return floor.copyWith(items: items);
      });
    });

    onCommand?.call('moveItem', {
      'id': itemId,
      if (position != null) 'position': position.toJson(),
      if (rotationDeg != null) 'rotation_deg': rotationDeg,
      if (scale != null) 'scale': scale,
    });
  }

  void removeItem(String itemId) {
    _notifier.applyMutation(
      (scene) => _replaceActiveFloor(
        scene,
        (floor) => floor.copyWith(items: floor.items.where((item) => item.id != itemId).toList()),
      ),
    );

    onCommand?.call('removeItem', {'id': itemId});
  }

  /// Sets the material for a rectangular wall zone. [zoneId] should normally
  /// be caller-provided and deterministic (e.g. `zone_<wallId>_backsplash`)
  /// so re-picking a material for the same named zone updates it in place
  /// instead of creating an overlapping duplicate — the material picker UI
  /// does this. If omitted, a fresh id is generated (Emma's local executor,
  /// once built, will need this path since it won't know existing zone ids).
  /// [colorHex] is a denormalized rendering hint (surface_materials'
  /// `previewColorHex`) so the viewer can tint the zone without querying a
  /// catalog itself — it's not persisted as part of the canonical
  /// `RoomWallZone` (only `materialId` is), only forwarded to the viewer.
  void setWallZoneMaterial({
    required String wallId,
    required String materialId,
    String? zoneId,
    List<double> heightRange = const [0.0, 1.0],
    List<double> positionRange = const [0.0, 1.0],
    String? colorHex,
  }) {
    final resolvedZoneId = zoneId ??
        'zone_${wallId}_${DateTime.now().microsecondsSinceEpoch}';

    _notifier.applyMutation((scene) {
      return _replaceActiveFloor(scene, (floor) {
        final zones = List<RoomWallZone>.from(floor.wallSurfaceZones);
        final existingIndex = zones.indexWhere((zone) => zone.id == resolvedZoneId);

        if (existingIndex >= 0) {
          zones[existingIndex] = zones[existingIndex].copyWith(materialId: materialId);
        } else {
          zones.add(RoomWallZone(
            id: resolvedZoneId,
            wallId: wallId,
            materialId: materialId,
            heightRange: heightRange,
            positionRange: positionRange,
          ));
        }

        return floor.copyWith(wallSurfaceZones: zones);
      });
    });

    onCommand?.call('setWallZoneMaterial', {
      'wall_id': wallId,
      'zone_id': resolvedZoneId,
      'material_id': materialId,
      'height_range': heightRange,
      'position_range': positionRange,
      if (colorHex != null) 'color': colorHex,
    });
  }

  /// Changes an EXISTING wall's thickness (the Buduj panel's thickness
  /// slider only sets it at draw time — this is for a wall already in the
  /// scene, e.g. one that came in from floor_plan). The viewer mutates the
  /// wall's geometry in place (`updateWallThickness` in scene.js) rather
  /// than removing and rebuilding the mesh, so any material zones already
  /// painted on it survive — though their position is computed from the
  /// wall's dimensions at paint time and won't retroactively re-center
  /// itself around the new thickness; a known, minor rough edge, not a bug.
  void setWallThickness({required String wallId, required double thicknessM}) {
    _notifier.applyMutation((scene) {
      return _replaceActiveFloor(scene, (floor) {
        final walls = floor.walls.map((wall) {
          if (wall.id != wallId) return wall;
          return RoomWall(
            id: wall.id,
            start: wall.start,
            end: wall.end,
            heightM: wall.heightM,
            thicknessM: thicknessM,
            isVirtual: wall.isVirtual,
          );
        }).toList();

        return floor.copyWith(walls: walls);
      });
    });

    onCommand?.call('updateWallThickness', {
      'wall_id': wallId,
      'thickness_m': thicknessM,
    });
  }

  /// Moves one endpoint of an EXISTING wall (FINAL_VISION.md §4's "edit a
  /// wall after the fact" debt item). Unlike setWallThickness/
  /// setWallZoneMaterial above, this can't be applied as a small incremental
  /// JS command — the wall's real segmented geometry (openings, corner-fill,
  /// cutaway) would all need re-deriving for the new length/angle, and doing
  /// that correctly a second time in JS would just duplicate logic
  /// `loadScene`'s full rebuild already gets right. So scene.js only ever
  /// shows a lightweight preview during the drag itself (a moved handle +
  /// a rubber-band line, never the real wall mesh — see its
  /// `wallEndpointDragState` doc comment) and this commits by fully
  /// reloading the active floor from the just-updated canonical state —
  /// the same mechanism undo/redo already use, for the same reason.
  void updateWallEndpoint({
    required String wallId,
    required String endpoint,
    required RoomPoint2 point,
  }) {
    _notifier.applyMutation((scene) {
      return _replaceActiveFloor(scene, (floor) {
        final walls = floor.walls.map((wall) {
          if (wall.id != wallId) return wall;
          return RoomWall(
            id: wall.id,
            start: endpoint == 'start' ? point : wall.start,
            end: endpoint == 'end' ? point : wall.end,
            heightM: wall.heightM,
            thicknessM: wall.thicknessM,
            isVirtual: wall.isVirtual,
          );
        }).toList();

        return floor.copyWith(walls: walls);
      });
    });

    _reloadViewerFromState();
  }

  /// Places a new door/window opening directly on an existing wall
  /// (FINAL_VISION.md §4's last remaining Buduj debt item — previously
  /// `RoomOpening` only ever came in pre-existing from a `floor_plan`
  /// import, nothing in room_3d's own Buduj could add one). [position] is
  /// the 0-1 fraction along the wall's length scene.js already computed
  /// from where the user clicked (see `openingPlaced`'s handling in
  /// `room_3d_editor_page.dart`). Same reasoning as [updateWallEndpoint] —
  /// the wall's real cutout geometry only gets correctly rebuilt via a full
  /// floor reload, not an incremental JS command.
  void addOpening({
    required String wallId,
    required RoomOpeningKind kind,
    required double position,
  }) {
    final opening = RoomOpening(
      id: 'opening_${DateTime.now().microsecondsSinceEpoch}',
      wallId: wallId,
      kind: kind,
      position: position.clamp(0.0, 1.0),
      widthM: kind == RoomOpeningKind.window ? kDefaultWindowWidthM : kDefaultDoorWidthM,
      sillHeightM: kind == RoomOpeningKind.window ? kDefaultWindowSillHeightM : 0.0,
      heightM: kind == RoomOpeningKind.window ? kDefaultWindowHeightM : kDefaultDoorHeightM,
    );

    _notifier.applyMutation(
      (scene) => _replaceActiveFloor(
        scene,
        (floor) => floor.copyWith(openings: [...floor.openings, opening]),
      ),
    );

    _reloadViewerFromState();
  }

  void setWholeWallMaterial({
    required String wallId,
    required String materialId,
    String? colorHex,
  }) {
    _notifier.applyMutation((scene) {
      return _replaceActiveFloor(scene, (floor) {
        final materials = Map<String, String>.from(floor.wallSurfaceMaterials);
        materials[wallId] = materialId;
        return floor.copyWith(wallSurfaceMaterials: materials);
      });
    });

    onCommand?.call('setWholeWallMaterial', {
      'wall_id': wallId,
      'material_id': materialId,
      if (colorHex != null) 'color': colorHex,
    });
  }

  void setFloorMaterial({
    required String roomId,
    required String materialId,
    String? colorHex,
  }) {
    _notifier.applyMutation((scene) {
      return _replaceActiveFloor(scene, (floor) {
        final rooms = floor.rooms.map((room) {
          if (room.id != roomId) return room;
          return RoomRoom(
            id: room.id,
            name: room.name,
            points: room.points,
            floorMaterialId: materialId,
            ceilingMaterialId: room.ceilingMaterialId,
          );
        }).toList();

        return floor.copyWith(rooms: rooms);
      });
    });

    onCommand?.call('setFloorMaterial', {
      'room_id': roomId,
      'material_id': materialId,
      if (colorHex != null) 'color': colorHex,
    });
  }

  /// Adds a wall drawn in the "Buduj" tool (see `build_panel.dart` +
  /// scene.js's build-mode click handling). [isVirtual] walls render
  /// translucent (existing `RoomWall.isVirtual` rendering, unchanged) —
  /// useful as a pure room divider with no real construction implied.
  void addWall({
    required String id,
    required RoomPoint2 start,
    required RoomPoint2 end,
    double heightM = kDefaultWallHeightM,
    double thicknessM = 0.15,
    bool isVirtual = false,
  }) {
    final wall = RoomWall(
      id: id,
      start: start,
      end: end,
      heightM: heightM,
      thicknessM: thicknessM,
      isVirtual: isVirtual,
    );

    _notifier.applyMutation(
      (scene) => _replaceActiveFloor(scene, (floor) => floor.copyWith(walls: [...floor.walls, wall])),
    );

    onCommand?.call('addWall', wall.toJson());
  }

  /// Adds a virtual room polygon drawn in the "Buduj" tool — a `RoomRoom`
  /// like any other (floor_plan-sourced or synthesized), just with no
  /// physical walls of its own. Its floor mesh renders as an overlay inside
  /// whichever room it geometrically sits within (see scene.js's
  /// `floorLayerCounter`), so the existing per-room `FloorMaterialPanel` +
  /// floor click-to-select flow (no changes needed there) is enough to give
  /// it its own material — e.g. tiling just a kitchen alcove while the rest
  /// of the room keeps panel flooring, the motivating use case for this.
  void addRoom({
    required String id,
    required String name,
    required List<RoomPoint2> points,
  }) {
    final room = RoomRoom(id: id, name: name, points: points);

    _notifier.applyMutation(
      (scene) => _replaceActiveFloor(scene, (floor) => floor.copyWith(rooms: [...floor.rooms, room])),
    );

    onCommand?.call('addRoom', room.toJson());
  }

  /// Adds a stair run drawn in the "Buduj" tool (FINAL_VISION.md §6's
  /// "rendered stairs", the last item in the floors arc). Unlike [addWall]/
  /// [addRoom] this goes through a full [_reloadViewerFromState] rather than
  /// an incremental `onCommand`, because the stair's rise depends on the
  /// active floor's `storyHeightM` — data that only flows to scene.js via
  /// `toViewerPayload`/`floorStackPayload`, not a standalone JS command.
  void addStair({
    required String id,
    required RoomPoint2 start,
    required RoomPoint2 end,
    double widthM = 1.0,
  }) {
    final stair = RoomStair(id: id, start: start, end: end, widthM: widthM);

    _notifier.applyMutation(
      (scene) => _replaceActiveFloor(scene, (floor) => floor.copyWith(stairs: [...floor.stairs, stair])),
    );

    _reloadViewerFromState();
  }

  /// Removes a wall — from Buduj (undo-drawing a mistake) or any other
  /// source (floor_plan-derived walls are just as removable; nothing in the
  /// model distinguishes "drawn in Buduj" from "came from floor_plan").
  /// Also drops any wall-zone materials/whole-wall material painted on it
  /// (`wallSurfaceZones`/`wallSurfaceMaterials`), since a zone referencing a
  /// wall that no longer exists is pure clutter, never shown again.
  void removeWall(String wallId) {
    _notifier.applyMutation((scene) {
      return _replaceActiveFloor(scene, (floor) {
        final materials = Map<String, String>.from(floor.wallSurfaceMaterials)..remove(wallId);
        return floor.copyWith(
          walls: floor.walls.where((wall) => wall.id != wallId).toList(),
          wallSurfaceZones: floor.wallSurfaceZones.where((zone) => zone.wallId != wallId).toList(),
          wallSurfaceMaterials: materials,
        );
      });
    });

    onCommand?.call('removeWall', {'wall_id': wallId});
  }

  /// Removes a room — including a virtual room added via Buduj (see
  /// [addRoom]), which is what this is mainly for. Deliberately does NOT
  /// cascade-delete furniture whose `roomId` pointed at it: for a virtual
  /// room (a floor-material overlay, not a real enclosing space) items
  /// physically inside it almost always belong to the PARENT room instead,
  /// so cascading would delete furniture that has nothing to do with the
  /// removed overlay. A leftover dangling `roomId` on an item after removing
  /// a real (non-virtual) room is an accepted minor rough edge, not
  /// something this cleans up.
  void removeRoom(String roomId) {
    _notifier.applyMutation(
      (scene) => _replaceActiveFloor(
        scene,
        (floor) => floor.copyWith(rooms: floor.rooms.where((room) => room.id != roomId).toList()),
      ),
    );

    onCommand?.call('removeRoom', {'room_id': roomId});
  }

  /// Undo/redo mutate `roomSceneProvider` state directly (not through
  /// `applyMutation`, which would itself push a new undo entry), so they
  /// don't go through the per-mutation `onCommand` calls above. Instead they
  /// force a full `loadScene` re-render — simpler and more robust than
  /// trying to compute+replay an inverse JS command for whatever the last
  /// mutation happened to be. Known limitation: wall zone colors aren't
  /// persisted in RoomScene (only materialId is, see setWallZoneMaterial
  /// doc above), so zones repaint in a neutral color after undo/redo until
  /// re-applied — acceptable until Faza 2's real material catalog lands.
  void undo() {
    _notifier.undo();
    _reloadViewerFromState();
  }

  void redo() {
    _notifier.redo();
    _reloadViewerFromState();
  }

  /// Adds a new, empty storey after the current last one and switches to it
  /// — matches `RoomFloor`'s "just another entry in `scene.floors`" design,
  /// so this is a scene mutation like any other (goes through
  /// `applyMutation`, is undoable) followed by the (non-undoable) view-state
  /// switch to make it active.
  void addFloor({String? label}) {
    _notifier.applyMutation((scene) {
      final nextIndex = scene.floors.length;
      final floor = RoomFloor(
        id: 'floor_${DateTime.now().microsecondsSinceEpoch}',
        index: nextIndex,
        label: label ?? 'Piętro $nextIndex',
      );
      return scene.copyWith(floors: [...scene.floors, floor]);
    });

    final newIndex = (ref.read(roomSceneProvider).scene?.floors.length ?? 1) - 1;
    setActiveFloor(newIndex);
  }

  /// Removes a floor. Refuses to remove the last remaining one — a scene
  /// with zero floors has nothing for the viewer/editor to show, and there's
  /// no meaningful "which floor is active" answer at that point.
  void removeFloor(int index) {
    final scene = ref.read(roomSceneProvider).scene;
    if (scene == null || scene.floors.length <= 1) return;
    if (index < 0 || index >= scene.floors.length) return;

    _notifier.applyMutation((scene) {
      final remaining = List<RoomFloor>.from(scene.floors)..removeAt(index);
      return scene.copyWith(floors: remaining);
    });

    final newActiveIndex = ref.read(roomSceneProvider).activeFloorIndex;
    setActiveFloor(newActiveIndex);
  }

  /// Switches the active floor and re-renders the viewer with just that
  /// floor's data — view state, not a scene mutation, so it does NOT go
  /// through `applyMutation`/undo history.
  void setActiveFloor(int index) {
    _notifier.setActiveFloorIndex(index);
    _reloadViewerFromState();
  }

  /// Public escape hatch for view-state-only changes that need the viewer
  /// resent but aren't a scene mutation and don't touch which floor is
  /// active — currently just the "sąsiednie piętra" toggle
  /// (`room_3d_editor_page.dart`'s `_setShowAdjacentFloors`).
  void refreshViewer() => _reloadViewerFromState();

  void _reloadViewerFromState() {
    final state = ref.read(roomSceneProvider);
    final scene = state.scene;
    if (scene == null || scene.floors.isEmpty) return;

    final index = state.activeFloorIndex.clamp(0, scene.floors.length - 1);
    onCommand?.call('loadScene', floorStackPayload(scene, index));
  }
}

final roomSceneActionsProvider = Provider<RoomSceneActions>((ref) {
  return RoomSceneActions(ref);
});

/// Signature every Emma local tool executor implements. Keys in
/// `buildRoomSceneToolExecutors` (see `emma_tool_executors.dart`) MUST match
/// the Django-side tool names exactly (`room3d_place_item` etc.) so the
/// client-side Emma dispatcher finds them with no extra name-mapping layer —
/// see docs/sims_mode/ARCHITECTURE.md section 7.
typedef RoomSceneToolExecutor = Future<Map<String, dynamic>> Function(
  Map<String, dynamic> params,
);
