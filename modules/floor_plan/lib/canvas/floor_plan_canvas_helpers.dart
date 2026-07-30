part of 'floor_plan_canvas.dart';

double? _parseDouble(String value) {
  final normalized = value.replaceAll(',', '.').trim();
  return double.tryParse(normalized);
}

double _wallThicknessPxFromDocument(
  FloorPlanDocument document,
  FloorWall wall,
) {
  if (wall.isVirtual) return 2.0;

  final thicknessM = wall.thickness / 100.0;
  final px = thicknessM * document.scale.pixelsPerMeter;

  return px.clamp(2.0, 120.0).toDouble();
}

String _formatAngleLabel(double angleDeg) {
  final rounded = angleDeg.roundToDouble();

  if ((angleDeg - rounded).abs() < 0.05) {
    return '${rounded.toStringAsFixed(0)}°';
  }

  return '${angleDeg.toStringAsFixed(1)}°';
}

String _formatAreaLabel(double areaM2) {
  return '${areaM2.toStringAsFixed(2)} m²';
}

String _cornerKey(Offset point) {
  return '${point.dx.toStringAsFixed(2)}:${point.dy.toStringAsFixed(2)}';
}

double _normalizePositiveRadians(double value) {
  var normalized = value % (math.pi * 2);

  if (normalized < 0) {
    normalized += math.pi * 2;
  }

  return normalized;
}

double _smallestRadiansDiff(double a, double b) {
  final diff = (_normalizePositiveRadians(a - b)).abs();
  final inverse = math.pi * 2 - diff;

  return diff > inverse ? inverse : diff;
}

double _polygonAreaPx2(List<Offset> points) {
  if (points.length < 3) return 0;

  double sum = 0;

  for (var i = 0; i < points.length; i++) {
    final a = points[i];
    final b = points[(i + 1) % points.length];

    sum += a.dx * b.dy - b.dx * a.dy;
  }

  return sum.abs() / 2;
}

bool _pointInPolygon(Offset point, List<Offset> polygon) {
  if (polygon.length < 3) return false;

  var inside = false;

  for (var i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    final pi = polygon[i];
    final pj = polygon[j];

    final denominator = (pj.dy - pi.dy).abs() < 0.000001
        ? 0.000001
        : pj.dy - pi.dy;

    final intersects = ((pi.dy > point.dy) != (pj.dy > point.dy)) &&
        (point.dx <
            (pj.dx - pi.dx) * (point.dy - pi.dy) / denominator + pi.dx);

    if (intersects) {
      inside = !inside;
    }
  }

  return inside;
}

Offset _polygonCentroid(List<Offset> points) {
  if (points.isEmpty) return Offset.zero;

  double signedArea = 0;
  double cx = 0;
  double cy = 0;

  for (var i = 0; i < points.length; i++) {
    final a = points[i];
    final b = points[(i + 1) % points.length];

    final cross = a.dx * b.dy - b.dx * a.dy;

    signedArea += cross;
    cx += (a.dx + b.dx) * cross;
    cy += (a.dy + b.dy) * cross;
  }

  signedArea *= 0.5;

  if (signedArea.abs() < 0.001) {
    final x = points.map((e) => e.dx).reduce((a, b) => a + b) / points.length;
    final y = points.map((e) => e.dy).reduce((a, b) => a + b) / points.length;

    return Offset(x, y);
  }

  cx /= 6 * signedArea;
  cy /= 6 * signedArea;

  return Offset(cx, cy);
}

Rect _boundingBoxOf(List<Offset> points) {
  if (points.isEmpty) return Rect.zero;

  var minX = points.first.dx;
  var maxX = points.first.dx;
  var minY = points.first.dy;
  var maxY = points.first.dy;

  for (final p in points) {
    if (p.dx < minX) minX = p.dx;
    if (p.dx > maxX) maxX = p.dx;
    if (p.dy < minY) minY = p.dy;
    if (p.dy > maxY) maxY = p.dy;
  }

  return Rect.fromLTRB(minX, minY, maxX, maxY);
}

List<_CornerAngleLabelHit> _buildCornerAngleLabels(
  FloorPlanDocument document,
) {
  final cornerPoints = <String, Offset>{};
  final connectionsByCorner = <String, List<_CornerConnection>>{};

  for (final wall in document.walls) {
    final start = wall.start.toOffset();
    final end = wall.end.toOffset();

    final vector = end - start;
    final length = vector.distance;

    if (length <= 0.001) continue;

    final startDirection = Offset(
      vector.dx / length,
      vector.dy / length,
    );

    final endDirection = Offset(
      -vector.dx / length,
      -vector.dy / length,
    );

    final startKey = _cornerKey(start);
    final endKey = _cornerKey(end);

    cornerPoints[startKey] = start;
    cornerPoints[endKey] = end;

    connectionsByCorner.putIfAbsent(startKey, () => []);
    connectionsByCorner.putIfAbsent(endKey, () => []);

    connectionsByCorner[startKey]!.add(
      _CornerConnection(
        wallId: wall.id,
        direction: startDirection,
        thicknessPx: _wallThicknessPxFromDocument(document, wall),
      ),
    );

    connectionsByCorner[endKey]!.add(
      _CornerConnection(
        wallId: wall.id,
        direction: endDirection,
        thicknessPx: _wallThicknessPxFromDocument(document, wall),
      ),
    );
  }

  final labels = <_CornerAngleLabelHit>[];

  for (final entry in connectionsByCorner.entries) {
    final corner = cornerPoints[entry.key];
    if (corner == null) continue;

    final connections = _dedupeCornerConnections(entry.value);
    if (connections.length < 2) continue;

    if (connections.length == 2) {
      final a = connections[0];
      final b = connections[1];

      final angleA = math.atan2(a.direction.dy, a.direction.dx);
      final angleB = math.atan2(b.direction.dy, b.direction.dx);

      var sweep = _normalizePositiveRadians(angleB - angleA);

      var sign = 1;

      if (sweep > math.pi) {
        sweep = math.pi * 2 - sweep;
        sign = -1;
      }

      final angleDeg = sweep * 180.0 / math.pi;
      if (angleDeg < 2 || angleDeg > 178) continue;

      final midAngle = angleA + sign * sweep / 2;

      final radius = math.max(
        24.0,
        math.max(a.thicknessPx, b.thicknessPx) / 2 + 18,
      );

      labels.add(
        _createCornerAngleLabelHit(
          corner: corner,
          wallAId: a.wallId,
          wallBId: b.wallId,
          angleDeg: angleDeg,
          sweepSign: sign,
          midAngle: midAngle,
          radius: radius,
        ),
      );
    } else {
      final sorted = [...connections]..sort((a, b) {
          final angleA = math.atan2(a.direction.dy, a.direction.dx);
          final angleB = math.atan2(b.direction.dy, b.direction.dx);

          return angleA.compareTo(angleB);
        });

      for (var i = 0; i < sorted.length; i++) {
        final current = sorted[i];
        final next = sorted[(i + 1) % sorted.length];

        final angleA = _normalizePositiveRadians(
          math.atan2(
            current.direction.dy,
            current.direction.dx,
          ),
        );

        final angleB = _normalizePositiveRadians(
          math.atan2(
            next.direction.dy,
            next.direction.dx,
          ),
        );

        final sweep = _normalizePositiveRadians(angleB - angleA);
        final angleDeg = sweep * 180.0 / math.pi;

        if (angleDeg < 2 || angleDeg > 178) continue;

        final midAngle = angleA + sweep / 2;

        final radius = math.max(
          24.0,
          math.max(current.thicknessPx, next.thicknessPx) / 2 + 18,
        );

        labels.add(
          _createCornerAngleLabelHit(
            corner: corner,
            wallAId: current.wallId,
            wallBId: next.wallId,
            angleDeg: angleDeg,
            sweepSign: 1,
            midAngle: midAngle,
            radius: radius,
          ),
        );
      }
    }
  }

  return labels;
}

_CornerAngleLabelHit _createCornerAngleLabelHit({
  required Offset corner,
  required String wallAId,
  required String wallBId,
  required double angleDeg,
  required int sweepSign,
  required double midAngle,
  required double radius,
}) {
  final labelPosition = corner +
      Offset(
        math.cos(midAngle) * (radius + 16),
        math.sin(midAngle) * (radius + 16),
      );

  final text = _formatAngleLabel(angleDeg);

  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w900,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  final rect = Rect.fromCenter(
    center: labelPosition,
    width: painter.width + 18,
    height: painter.height + 12,
  );

  return _CornerAngleLabelHit(
    corner: corner,
    wallAId: wallAId,
    wallBId: wallBId,
    angleDeg: angleDeg,
    sweepSign: sweepSign,
    labelPosition: labelPosition,
    labelRect: rect,
  );
}

List<_CornerConnection> _dedupeCornerConnections(
  List<_CornerConnection> source,
) {
  final result = <_CornerConnection>[];

  for (final item in source) {
    final angle = math.atan2(
      item.direction.dy,
      item.direction.dx,
    );

    final alreadyExists = result.any((existing) {
      final existingAngle = math.atan2(
        existing.direction.dy,
        existing.direction.dx,
      );

      return _smallestRadiansDiff(angle, existingAngle) < 0.02;
    });

    if (!alreadyExists) {
      result.add(item);
    }
  }

  return result;
}

class _CornerConnection {
  final String wallId;
  final Offset direction;
  final double thicknessPx;

  const _CornerConnection({
    required this.wallId,
    required this.direction,
    required this.thicknessPx,
  });
}

extension _FloorPlanCanvasHelpers on _FloorPlanCanvasState {
  void _requestFocus() {
    if (_focusNode.hasFocus) return;

    _focusNode.requestFocus();
  }
}