import 'dart:math' as math;
import 'package:floor_plan/models/floor_plan_document.dart';
import '../data/models/projekt_budowlany_model.dart';

/// Converts a list of [PomieszczenieProjektuModel] (from a parsed PDF project)
/// into a [FloorPlanDocument] that can be opened in [FloorPlanCanvas].
///
/// Algorithm:
///   1. Shelf-pack rooms by real metric dimensions (wymiarA × wymiarB).
///   2. Convert each packed rectangle → [FloorRoom] polygon (4 corners, px).
///   3. Generate perimeter [FloorWall] segments for each room.
///      Shared segments between adjacent rooms get `kind = virtual`
///      (thin partition line); non-shared segments = structural (25 cm).
///   4. Place doors/windows on the appropriate wall using [liczbaOkien] /
///      [liczbaDrzwi] metadata — distributed evenly along the outer walls.
///
/// The resulting document uses pixelsPerMeter = 100 so 1 m → 100 px.
class ProjektFloorPlanConverter {
  static const double _ppm = 100.0; // pixels per metre
  static const double _wallExternal = 25.0; // cm — external structural wall
  static const double _wallInternal = 12.0; // cm — internal / partition

  static FloorPlanDocument convert(List<PomieszczenieProjektuModel> src) {
    final withDims = src.where((p) => p.wymiarAm != null && p.wymiarBm != null).toList();
    if (withDims.isEmpty) return FloorPlanDocument.empty();

    // ── 1. Shelf-pack ───────────────────────────────────────────────────────
    final totalAreaM2 = withDims.fold(0.0, (s, p) => s + p.wymiarAm! * p.wymiarBm!);
    final targetRowWidthM = math.sqrt(totalAreaM2 * 1.6);

    final sorted = [...withDims]..sort((a, b) => b.wymiarBm!.compareTo(a.wymiarBm!));

    final _PackedRoom rects = _PackedRoom();
    double shelfX = 0, shelfY = 0, shelfH = 0;
    for (final p in sorted) {
      final wM = p.wymiarAm!;
      final hM = p.wymiarBm!;
      if (shelfX > 0 && shelfX + wM > targetRowWidthM) {
        shelfY += shelfH;
        shelfX = 0;
        shelfH = 0;
      }
      rects.add(_RoomRect(p, shelfX, shelfY, wM, hM));
      shelfX += wM;
      shelfH = math.max(shelfH, hM);
    }

    final totalWM = rects.items.fold(0.0, (s, r) => math.max(s, r.x + r.w));
    final totalHM = rects.items.fold(0.0, (s, r) => math.max(s, r.y + r.h));

    // Canvas: add 1 m padding on each side
    final canvasWPx = (totalWM + 2.0) * _ppm;
    final canvasHPx = (totalHM + 2.0) * _ppm;
    final offsetXPx = _ppm; // 1 m margin
    final offsetYPx = _ppm;

    // ── 2. Build FloorRoom list ─────────────────────────────────────────────
    final rooms = <FloorRoom>[];
    for (final r in rects.items) {
      final x1 = r.x * _ppm + offsetXPx;
      final y1 = r.y * _ppm + offsetYPx;
      final x2 = x1 + r.w * _ppm;
      final y2 = y1 + r.h * _ppm;

      rooms.add(FloorRoom(
        id: 'room_${r.pom.pomId}',
        name: '${r.pom.nazwa}\n${(r.pom.powierzchniaM2 ?? r.pom.wymiarAm! * r.pom.wymiarBm!).toStringAsFixed(1)} m²',
        points: [
          FloorPoint(x: x1, y: y1),
          FloorPoint(x: x2, y: y1),
          FloorPoint(x: x2, y: y2),
          FloorPoint(x: x1, y: y2),
        ],
        colorHex: _colorForTyp(r.pom.typ),
      ));
    }

    // ── 3. Build walls (deduped shared edges → virtual) ─────────────────────
    final walls = <FloorWall>[];
    final seenEdges = <String>{};
    int wallIdx = 0;

    for (final r in rects.items) {
      final x1 = r.x * _ppm + offsetXPx;
      final y1 = r.y * _ppm + offsetYPx;
      final x2 = x1 + r.w * _ppm;
      final y2 = y1 + r.h * _ppm;

      // 4 sides: top, right, bottom, left
      final sides = [
        (FloorPoint(x: x1, y: y1), FloorPoint(x: x2, y: y1)),
        (FloorPoint(x: x2, y: y1), FloorPoint(x: x2, y: y2)),
        (FloorPoint(x: x2, y: y2), FloorPoint(x: x1, y: y2)),
        (FloorPoint(x: x1, y: y2), FloorPoint(x: x1, y: y1)),
      ];

      for (final (s, e) in sides) {
        final key = _edgeKey(s, e);
        final isShared = !seenEdges.add(key);
        walls.add(FloorWall(
          id: 'w_${wallIdx++}',
          start: s,
          end: e,
          thickness: isShared ? _wallInternal : _wallExternal,
          heightM: r.pom.wysokoscM ?? 2.6,
          kind: isShared ? FloorWall.kindVirtual : FloorWall.kindStructural,
        ));
      }
    }

    // ── 4. Doors + windows ──────────────────────────────────────────────────
    final doorsOut = <Map<String, dynamic>>[];
    final windowsOut = <Map<String, dynamic>>[];

    for (final r in rects.items) {
      final x1 = r.x * _ppm + offsetXPx;
      final y1 = r.y * _ppm + offsetYPx;
      final x2 = x1 + r.w * _ppm;
      final y2 = y1 + r.h * _ppm;

      // Find walls belonging to this room
      final roomWalls = walls.where((w) {
        return _wallBelongsToRect(w, x1, y1, x2, y2);
      }).toList();

      final nDrzwi = r.pom.liczbaDrzwi ?? 0;
      final nOkien = r.pom.liczbaOkien ?? 0;

      // Place doors on structural (outer) walls first, then virtual
      final structuralWalls = roomWalls.where((w) => !w.isVirtual).toList();
      final allWalls = [...structuralWalls, ...roomWalls.where((w) => w.isVirtual)];

      for (int i = 0; i < nDrzwi && i < allWalls.length; i++) {
        doorsOut.add({
          'id': 'door_${r.pom.pomId}_$i',
          'wall_id': allWalls[i].id,
          'position': 0.5,
          'width_m': 0.9,
          'type': 'single',
          'swing_direction': 'left',
        });
      }

      for (int i = 0; i < nOkien && i < structuralWalls.length; i++) {
        final wallIdx2 = (i + nDrzwi) % structuralWalls.length;
        windowsOut.add({
          'id': 'window_${r.pom.pomId}_$i',
          'wall_id': structuralWalls[wallIdx2].id,
          'position': 0.5,
          'width_m': 1.2,
          'sill_height_m': 0.9,
          'height_m': 1.4,
        });
      }
    }

    return FloorPlanDocument(
      canvas: FloorPlanCanvasConfig(
        width: canvasWPx,
        height: canvasHPx,
        gridSize: 20,
      ),
      scale: const FloorPlanScale(pixelsPerMeter: _ppm),
      walls: walls,
      rooms: rooms,
      doors: doorsOut,
      windows: windowsOut,
    );
  }

  static String _edgeKey(FloorPoint a, FloorPoint b) {
    final pts = [
      '${a.x.round()},${a.y.round()}',
      '${b.x.round()},${b.y.round()}',
    ]..sort();
    return pts.join('|');
  }

  static bool _wallBelongsToRect(FloorWall w, double x1, double y1, double x2, double y2) {
    bool onEdge(FloorPoint p) {
      return (p.x.round() == x1.round() || p.x.round() == x2.round() ||
              p.y.round() == y1.round() || p.y.round() == y2.round());
    }
    return onEdge(w.start) && onEdge(w.end);
  }

  static String _colorForTyp(String typ) {
    switch (typ) {
      case 'dzienny':   return '#BA68C8';
      case 'sypialnia': return '#81C784';
      case 'kuchnia':   return '#FFB74D';
      case 'lazienka':  return '#4FC3F7';
      case 'techniczny':return '#90A4AE';
      case 'komunikacja': return '#4DB6AC';
      case 'garaz':     return '#8D6E63';
      default:          return '#607D8B';
    }
  }
}

class _PackedRoom {
  final items = <_RoomRect>[];
  void add(_RoomRect r) => items.add(r);
}

class _RoomRect {
  final PomieszczenieProjektuModel pom;
  final double x, y, w, h;
  const _RoomRect(this.pom, this.x, this.y, this.w, this.h);
}
