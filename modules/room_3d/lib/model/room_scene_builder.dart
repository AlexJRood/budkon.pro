/// Converts a floor_plan [FloorPlanDocument] into a source-agnostic
/// [RoomScene]. This is the ONLY file in room_3d allowed to depend on the
/// floor_plan package — see docs/sims_mode/ARCHITECTURE.md section 1. When
/// room_scan ships, it gets an analogous, separate builder; room_3d itself
/// never imports floor_plan directly anywhere else.

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:floor_plan/models/floor_plan_document.dart';
import 'package:floor_plan/providers/floor_plan_api_service.dart';

import 'room_scene.dart';

class RoomSceneBuilder {
  const RoomSceneBuilder._();

  /// Fetches a `floor_plans.FloorPlanProject`'s latest document over the
  /// network and converts it — the entry point used when opening room_3d
  /// from floor_plan's "Tryb 3D" button. Mirrors
  /// FloorPlanBuilderConnectedView._safeGetLatestVersion's fallback: if the
  /// dedicated latest-version fetch fails (e.g. a brand new project with no
  /// version rows yet), fall back to the version embedded in the project
  /// payload itself rather than failing outright.
  static Future<RoomScene> loadFromFloorPlanProject({
    required WidgetRef ref,
    required String floorPlanProjectId,
  }) async {
    final api = ref.read(floorPlanApiServiceProvider);

    final project = await api.getProject(ref: ref, projectId: floorPlanProjectId);

    FloorPlanDocument document;
    try {
      final latest = await api.getLatestVersion(ref: ref, projectId: floorPlanProjectId);
      document = latest.document;
    } catch (_) {
      document = project.latestVersion?.document ?? FloorPlanDocument.empty();
    }

    return fromFloorPlan(document, sourceId: floorPlanProjectId);
  }

  static RoomScene fromFloorPlan(
    FloorPlanDocument document, {
    required String sourceId,
  }) {
    final pixelsPerMeter = document.scale.pixelsPerMeter;

    final walls = document.walls
        .map((wall) => _wallToRoomWall(wall, pixelsPerMeter))
        .toList();

    var rooms = document.rooms
        .map((room) => RoomRoom(
              id: room.id,
              name: room.name,
              points: room.points
                  .map((point) => _toMeters(point.x, point.y, pixelsPerMeter))
                  .toList(),
            ))
        .toList();

    // floor_plan's "room" concept requires the user to explicitly draw a
    // room polygon with the Room tool — a document that only has walls
    // drawn (no rooms) is common and produces an empty rooms list here,
    // which silently breaks every room-scoped room_3d feature (furniture
    // placement, floor material — both need a target room). Fall back to
    // tracing a single room polygon by chaining wall endpoints into a
    // closed loop, when the walls actually form one simple closed shape.
    if (rooms.isEmpty && walls.isNotEmpty) {
      final synthesized = _synthesizeRoomFromWalls(walls);
      if (synthesized != null) rooms = [synthesized];
    }

    final openings = <RoomOpening>[
      ...document.doors.map(
        (door) => _openingFromMap(door, RoomOpeningKind.door),
      ),
      ...document.windows.map(
        (window) => _openingFromMap(window, RoomOpeningKind.window),
      ),
    ];

    return RoomScene.singleFloor(
      sourceKind: RoomSceneSourceKind.floorPlan,
      sourceId: sourceId,
      walls: walls,
      rooms: rooms,
      openings: openings,
      // items / wallSurfaceMaterials / wallSurfaceZones start empty — floor_plan
      // has no concept of them, they're authored in the room_3d editor itself.
    );
  }

  static RoomWall _wallToRoomWall(FloorWall wall, double pixelsPerMeter) {
    return RoomWall(
      id: wall.id,
      start: _toMeters(wall.start.x, wall.start.y, pixelsPerMeter),
      end: _toMeters(wall.end.x, wall.end.y, pixelsPerMeter),
      heightM: wall.heightM,
      thicknessM: pixelsPerMeter > 0 ? wall.thickness / 100 : 0.15,
      isVirtual: wall.isVirtual,
    );
  }

  static RoomOpening _openingFromMap(
    Map<String, dynamic> raw,
    RoomOpeningKind fallbackKind,
  ) {
    final kind = raw['type']?.toString() == 'garage_door'
        ? RoomOpeningKind.garageDoor
        : fallbackKind;

    return RoomOpening(
      id: raw['id']?.toString() ??
          '${kind.key}_${raw['wall_id']}_${raw['position']}',
      wallId: raw['wall_id'].toString(),
      kind: kind,
      position: (raw['position'] as num?)?.toDouble() ?? 0.5,
      widthM: (raw['width_m'] as num?)?.toDouble() ??
          (kind == RoomOpeningKind.window
              ? kDefaultWindowWidthM
              : kDefaultDoorWidthM),
      sillHeightM: kind == RoomOpeningKind.window ? kDefaultWindowSillHeightM : 0.0,
      heightM: kind == RoomOpeningKind.window
          ? kDefaultWindowHeightM
          : kDefaultDoorHeightM,
    );
  }

  static RoomPoint2 _toMeters(double xPx, double yPx, double pixelsPerMeter) {
    if (pixelsPerMeter <= 0) return RoomPoint2(x: xPx, y: yPx);
    return RoomPoint2(x: xPx / pixelsPerMeter, y: yPx / pixelsPerMeter);
  }

  /// Chains walls end-to-start (either direction — floor_plan doesn't
  /// guarantee consistent winding) into a closed loop, within a small
  /// tolerance. Returns null rather than a wrong guess if the walls don't
  /// form exactly one simple closed shape (multiple rooms, an open floor
  /// plan, disconnected walls) — better to leave rooms empty (and show the
  /// existing "no room" messaging) than synthesize a bogus polygon.
  static RoomRoom? _synthesizeRoomFromWalls(List<RoomWall> walls) {
    const eps = 0.05; // 5cm — matches the tolerance used elsewhere for wall/room matching

    final remaining = List<RoomWall>.from(walls);
    final first = remaining.removeAt(0);

    final loop = <RoomPoint2>[first.start];
    var currentEnd = first.end;

    while (remaining.isNotEmpty) {
      final nextIndex = remaining.indexWhere(
        (w) => _pointsClose(w.start, currentEnd, eps) || _pointsClose(w.end, currentEnd, eps),
      );
      if (nextIndex == -1) return null;

      final next = remaining.removeAt(nextIndex);
      final forward = _pointsClose(next.start, currentEnd, eps);

      loop.add(currentEnd);
      currentEnd = forward ? next.end : next.start;
    }

    if (!_pointsClose(currentEnd, loop.first, eps)) return null;

    return RoomRoom(id: 'room_auto', name: 'Pokój', points: loop);
  }

  static bool _pointsClose(RoomPoint2 a, RoomPoint2 b, double eps) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    return dx * dx + dy * dy <= eps * eps;
  }
}
