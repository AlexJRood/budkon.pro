import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:floor_plan/models/floor_plan_document.dart';

void main() {
  group('floorPlanDistance', () {
    test('computes Euclidean distance between two offsets', () {
      expect(floorPlanDistance(const Offset(0, 0), const Offset(3, 4)), 5.0);
    });

    test('is zero for identical points', () {
      expect(floorPlanDistance(const Offset(2, 2), const Offset(2, 2)), 0.0);
    });
  });

  group('FloorPoint', () {
    test('toOffset/fromOffset round-trip', () {
      const point = FloorPoint(x: 1.5, y: 2.5);
      expect(FloorPoint.fromOffset(point.toOffset()).x, 1.5);
    });

    test('fromJson defaults x/y to 0 when absent', () {
      final point = FloorPoint.fromJson({});
      expect(point.x, 0);
      expect(point.y, 0);
    });
  });

  group('FloorWall', () {
    FloorWall wall({FloorPoint? start, FloorPoint? end}) => FloorWall(
          id: 'w1',
          start: start ?? const FloorPoint(x: 0, y: 0),
          end: end ?? const FloorPoint(x: 3, y: 4),
        );

    test('lengthPx computes the Euclidean distance between start/end', () {
      expect(wall().lengthPx(), 5.0);
    });

    test('lengthM divides lengthPx by pixelsPerMeter', () {
      expect(wall().lengthM(100), 0.05);
    });

    test('lengthM is 0 for a non-positive pixelsPerMeter (avoids div-by-zero)',
        () {
      expect(wall().lengthM(0), 0);
      expect(wall().lengthM(-10), 0);
    });

    test('isVirtual reflects the kind field', () {
      final structural = FloorWall(
        id: 'w1',
        start: const FloorPoint(x: 0, y: 0),
        end: const FloorPoint(x: 1, y: 1),
      );
      expect(structural.isVirtual, isFalse);

      final virtualWall = FloorWall(
        id: 'w2',
        start: const FloorPoint(x: 0, y: 0),
        end: const FloorPoint(x: 1, y: 1),
        kind: FloorWall.kindVirtual,
      );
      expect(virtualWall.isVirtual, isTrue);
    });

    test('fromJson accepts both snake_case and default values', () {
      final parsed = FloorWall.fromJson({
        'id': 'w1',
        'start': {'x': 0, 'y': 0},
        'end': {'x': 3, 'y': 4},
        'height_m': 3.0,
      });
      expect(parsed.heightM, 3.0);
      expect(parsed.thickness, 12); // default
      expect(parsed.kind, FloorWall.kindStructural);
    });

    test('toJson round-trips through fromJson', () {
      final original = wall();
      final restored = FloorWall.fromJson(original.toJson());
      expect(restored.lengthPx(), original.lengthPx());
      expect(restored.thickness, original.thickness);
    });
  });

  group('FloorRoom.areaM2 (shoelace formula)', () {
    test('computes the area of a simple square room', () {
      // A 100x100 px square at 100 px/m = 1m x 1m = 1 m^2.
      final room = FloorRoom(
        id: 'r1',
        name: 'Room',
        points: const [
          FloorPoint(x: 0, y: 0),
          FloorPoint(x: 100, y: 0),
          FloorPoint(x: 100, y: 100),
          FloorPoint(x: 0, y: 100),
        ],
      );
      expect(room.areaM2(100), closeTo(1.0, 1e-9));
    });

    test('is independent of winding direction (abs of the signed area)', () {
      final clockwise = FloorRoom(
        id: 'r1',
        name: 'Room',
        points: const [
          FloorPoint(x: 0, y: 0),
          FloorPoint(x: 0, y: 100),
          FloorPoint(x: 100, y: 100),
          FloorPoint(x: 100, y: 0),
        ],
      );
      expect(clockwise.areaM2(100), closeTo(1.0, 1e-9));
    });

    test('is 0 for fewer than 3 points or non-positive scale', () {
      final line = FloorRoom(
        id: 'r1',
        name: 'Room',
        points: const [FloorPoint(x: 0, y: 0), FloorPoint(x: 1, y: 1)],
      );
      expect(line.areaM2(100), 0);

      final square = FloorRoom(
        id: 'r1',
        name: 'Room',
        points: const [
          FloorPoint(x: 0, y: 0),
          FloorPoint(x: 100, y: 0),
          FloorPoint(x: 100, y: 100),
        ],
      );
      expect(square.areaM2(0), 0);
    });
  });

  group('FloorRoom.centroid', () {
    test('is the geometric center of a square', () {
      final room = FloorRoom(
        id: 'r1',
        name: 'Room',
        points: const [
          FloorPoint(x: 0, y: 0),
          FloorPoint(x: 100, y: 0),
          FloorPoint(x: 100, y: 100),
          FloorPoint(x: 0, y: 100),
        ],
      );
      final centroid = room.centroid();
      expect(centroid.dx, closeTo(50, 1e-6));
      expect(centroid.dy, closeTo(50, 1e-6));
    });

    test('falls back to Offset.zero for an empty point list', () {
      final room = FloorRoom(id: 'r1', name: 'Room', points: const []);
      expect(room.centroid(), Offset.zero);
    });

    test('falls back to the arithmetic mean for a degenerate (zero-area) shape',
        () {
      // Three collinear points -> signed area ~0, triggers the fallback.
      final room = FloorRoom(
        id: 'r1',
        name: 'Room',
        points: const [
          FloorPoint(x: 0, y: 0),
          FloorPoint(x: 10, y: 0),
          FloorPoint(x: 20, y: 0),
        ],
      );
      final centroid = room.centroid();
      expect(centroid.dx, closeTo(10, 1e-6));
      expect(centroid.dy, 0);
    });
  });

  group('FloorPlanDocument', () {
    test('empty() provides sensible canvas/scale defaults', () {
      final doc = FloorPlanDocument.empty();
      expect(doc.canvas.width, 2400);
      expect(doc.scale.pixelsPerMeter, 100);
      expect(doc.walls, isEmpty);
    });

    test('fromJson/toJson round-trips walls, rooms, and assets', () {
      final doc = FloorPlanDocument.fromJson({
        'canvas': {'width': 1000, 'height': 800, 'grid_size': 10},
        'scale': {'pixels_per_meter': 50},
        'walls': [
          {
            'id': 'w1',
            'start': {'x': 0, 'y': 0},
            'end': {'x': 10, 'y': 0},
          },
        ],
        'rooms': [
          {
            'id': 'r1',
            'name': 'Kitchen',
            'points': [
              {'x': 0, 'y': 0},
            ],
          },
        ],
        'assets': [
          {
            'id': 'a1',
            'type': 'door',
            'position': {'x': 1, 'y': 1},
            'width_m': 0.9,
            'depth_m': 0.1,
          },
        ],
      });

      expect(doc.canvas.width, 1000);
      expect(doc.scale.pixelsPerMeter, 50);
      expect(doc.walls.single.id, 'w1');
      expect(doc.rooms.single.name, 'Kitchen');
      expect(doc.assets.single.type, 'door');

      final restored = FloorPlanDocument.fromJson(doc.toJson());
      expect(restored.walls.single.id, 'w1');
      expect(restored.assets.single.widthM, 0.9);
    });

    test('copyWith overrides only the given fields', () {
      final doc = FloorPlanDocument.empty();
      final copy = doc.copyWith(unit: 'ft');
      expect(copy.unit, 'ft');
      expect(copy.canvas, doc.canvas);
    });
  });
}
