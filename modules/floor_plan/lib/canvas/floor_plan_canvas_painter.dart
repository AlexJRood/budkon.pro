part of 'floor_plan_canvas.dart';

class FloorPlanPainter extends CustomPainter {
  final FloorPlanCanvasTheme canvasTheme;

  final FloorPlanDocument document;
  final Offset? previewStart;
  final Offset? previewEnd;
  final bool previewIsVirtual;

  final _SelectedObject? selectedObject;
  final Set<String> selectedWallIds;
  final _SelectedVertex? selectedVertex;
  final Set<String> selectedVertexKeys;
  final Rect? selectionRect;
  final _GuideSnapResult? guideSnap;
  final _DetectedRoomCandidate? hoveredRoomCandidate;

  final bool showCornerAngles;
  final bool showRoomLabels;
  final bool showRoomAreas;

  FloorPlanPainter({
    required this.canvasTheme,
    required this.document,
    required this.previewStart,
    required this.previewEnd,
    required this.previewIsVirtual,
    required this.selectedObject,
    required this.selectedWallIds,
    required this.selectedVertex,
    required this.selectedVertexKeys,
    required this.selectionRect,
    required this.guideSnap,
    required this.showCornerAngles,
    required this.showRoomLabels,
    required this.showRoomAreas,
    this.hoveredRoomCandidate,
  });

  Color get _canvasBackgroundColor => canvasTheme.background;
  Color get _wallColor => canvasTheme.wall;
  Color get _selectedWallColor => canvasTheme.selectedWall;
  Color get _blueColor => canvasTheme.accent;
  Color get _cyanColor => canvasTheme.window;
  Color get _purpleColor => canvasTheme.guide;
  Color get _orangeColor => canvasTheme.garageDoor;

  bool _isVirtualWall(FloorWall wall) {
    if (wall.isVirtual) return true;

    final kind = wall.kind.toString().trim().toLowerCase();

    return kind == 'virtual' ||
        kind == 'virtual_wall' ||
        kind == 'fictional' ||
        kind == 'fake' ||
        kind == 'divider';
  }

  bool _isLoadBearingWall(FloorWall wall) {
    if (_isVirtualWall(wall)) return false;

    final kind = wall.kind.toString().trim().toLowerCase();

    return kind == 'load_bearing' ||
        kind == 'bearing' ||
        kind == 'structural' ||
        kind == 'carrier' ||
        kind == 'nosna' ||
        kind == 'nośna';
  }

  bool _isPartitionWall(FloorWall wall) {
    return !_isVirtualWall(wall) && !_isLoadBearingWall(wall);
  }

  String _wallKindLabel(FloorWall wall) {
    if (_isVirtualWall(wall)) return 'fikcyjna';
    if (_isLoadBearingWall(wall)) return 'nośna';
    if (_isPartitionWall(wall)) return 'działowa';

    return 'ściana';
  }

  double _wallThicknessPx(FloorWall wall) {
    if (_isVirtualWall(wall)) return 2.0;

    // wall.thickness is interpreted as centimeters.
    // Example: 12 = 12 cm = 0.12 m.
    final thicknessM = wall.thickness / 100.0;
    final px = thicknessM * document.scale.pixelsPerMeter;

    return px.clamp(2.0, 120.0).toDouble();
  }

  String _wallThicknessLabel(FloorWall wall) {
    if (_isVirtualWall(wall)) return 'fikcyjna';

    return '${_wallKindLabel(wall)} · ${wall.thickness.toStringAsFixed(0)} cm';
  }

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);
    _drawRooms(canvas);
    _drawHoveredRoomCandidate(canvas);
    _drawGuides(canvas);
    _drawWalls(canvas);
    _drawOpenings(canvas);
    _drawAssets(canvas);

    if (showCornerAngles) {
      _drawCornerAngles(canvas);
    }

    _drawPreviewWall(canvas);
    _drawCornerHandles(canvas);
    _drawSelectedVertex(canvas);
    _drawSelectionRect(canvas);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final grid = document.canvas.gridSize;
    if (grid <= 0) return;

    final paint = Paint()
      ..color = canvasTheme.gridMinor
      ..strokeWidth = 1;

    for (double x = 0; x <= size.width; x += grid) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    for (double y = 0; y <= size.height; y += grid) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    final majorPaint = Paint()
      ..color = canvasTheme.gridMajor
      ..strokeWidth = 1.2;

    final majorGrid = grid * 5;

    if (majorGrid <= 0) return;

    for (double x = 0; x <= size.width; x += majorGrid) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        majorPaint,
      );
    }

    for (double y = 0; y <= size.height; y += majorGrid) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        majorPaint,
      );
    }
  }

  void _drawRooms(Canvas canvas) {
    for (final room in document.rooms) {
      final points = room.offsets;
      if (points.length < 3) continue;

      final selected =
          selectedObject?.isRoom == true && selectedObject?.id == room.id;

      final path = Path()..moveTo(points.first.dx, points.first.dy);

      for (final point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }

      path.close();

      final fill = Paint()
        ..color = selected ? canvasTheme.selectedRoomFill : canvasTheme.roomFill
        ..style = PaintingStyle.fill;

      final border = Paint()
        ..color =
            selected ? canvasTheme.selectedRoomBorder : canvasTheme.roomBorder
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 2.0 : 1.2;

      canvas.drawPath(path, fill);
      canvas.drawPath(path, border);

      if (showRoomLabels || showRoomAreas) {
        _drawRoomLabel(canvas, room, selected: selected);
      }
    }
  }

  void _drawHoveredRoomCandidate(Canvas canvas) {
    final candidate = hoveredRoomCandidate;
    if (candidate == null) return;
    if (candidate.points.length < 3) return;

    final path = Path()
      ..moveTo(candidate.points.first.dx, candidate.points.first.dy);

    for (final point in candidate.points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }

    path.close();

    final fill = Paint()
      ..color = canvasTheme.accent.withOpacity(0.12)
      ..style = PaintingStyle.fill;

    final border = Paint()
      ..color = canvasTheme.accent.withOpacity(0.78)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawPath(path, fill);
    canvas.drawPath(path, border);

    final center = _polygonCentroid(candidate.points);
    final text = '${candidate.areaM2.toStringAsFixed(2)} m²';

    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: canvasTheme.accent,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final rect = Rect.fromCenter(
      center: center,
      width: painter.width + 18,
      height: painter.height + 12,
    );

    final bg = Paint()
      ..color = canvasTheme.labelBackground.withOpacity(0.92)
      ..style = PaintingStyle.fill;

    final labelBorder = Paint()
      ..color = canvasTheme.accent.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final rrect = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(8),
    );

    canvas.drawRRect(rrect, bg);
    canvas.drawRRect(rrect, labelBorder);

    painter.paint(
      canvas,
      Offset(
        rect.left + 9,
        rect.top + 6,
      ),
    );
  }

  void _drawRoomLabel(
    Canvas canvas,
    FloorRoom room, {
    required bool selected,
  }) {
    final area = room.areaM2(document.scale.pixelsPerMeter);

    final fullLines = <String>[
      if (showRoomLabels && room.showName) room.name,
      if (showRoomAreas && room.showArea) _formatAreaLabel(area),
    ];
    final areaOnlyLines = <String>[
      if (showRoomAreas && room.showArea) _formatAreaLabel(area),
    ];

    if (fullLines.isEmpty) return;

    final center = room.centroid();

    // Pokój może być węższy niż etykieta (korytarz, łazienka, garderoba) —
    // bez tego tło etykiety wylewało się poza granice pokoju i zachodziło na
    // sąsiednie pomieszczenia. Zmniejsz czcionkę, aż etykieta zmieści się w
    // obrysie pokoju (z marginesem); jeśli nazwa to pojedyncze długie słowo
    // (np. "GARDEROBNA") i nawet najmniejsza czcionka się nie mieści, samo
    // zmniejszanie nie pomaga — TextPainter nie potrafi złamać słowa bez
    // spacji, więc tekst i tak wystaje i zostaje fizycznie przycięty przez
    // obrys pokoju (widać wtedy tylko środek słowa, np. "RDEROB"). W takim
    // wypadku porzuć linię z nazwą i pokaż samo pole powierzchni.
    final bounds = _boundingBoxOf(room.offsets);
    final maxLabelWidth = math.max(bounds.width - 12, 24.0);
    final maxLabelHeight = math.max(bounds.height - 12, 16.0);

    const fontSizes = [13.0, 12.0, 11.0, 10.0, 9.0];

    TextPainter layoutFor(List<String> lines, double fontSize) {
      return TextPainter(
        text: TextSpan(
          text: lines.join('\n'),
          style: TextStyle(
            color: selected ? canvasTheme.accent : canvasTheme.labelText,
            fontSize: selected ? fontSize + 1 : fontSize,
            fontWeight: FontWeight.w900,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: maxLabelWidth);
    }

    bool fits(TextPainter p) =>
        p.width <= maxLabelWidth && p.height <= maxLabelHeight;

    late TextPainter painter;
    for (final fontSize in fontSizes) {
      painter = layoutFor(fullLines, fontSize);
      if (fits(painter)) break;
    }

    if (!fits(painter) && areaOnlyLines.isNotEmpty) {
      for (final fontSize in fontSizes) {
        painter = layoutFor(areaOnlyLines, fontSize);
        if (fits(painter)) break;
      }
    }

    final rect = Rect.fromCenter(
      center: center,
      width: math.min(painter.width + 18, maxLabelWidth + 12),
      height: math.min(painter.height + 12, maxLabelHeight + 12),
    );

    final bg = Paint()
      ..color = canvasTheme.labelBackground
      ..style = PaintingStyle.fill;

    final border = Paint()
      ..color = selected
          ? canvasTheme.accent.withOpacity(0.8)
          : canvasTheme.roomBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = selected ? 1.5 : 1;

    final rrect = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(8),
    );

    canvas.drawRRect(rrect, bg);
    canvas.drawRRect(rrect, border);

    painter.paint(
      canvas,
      Offset(
        center.dx - painter.width / 2,
        center.dy - painter.height / 2,
      ),
    );
  }

  void _drawGuides(Canvas canvas) {
    final guide = guideSnap;
    if (guide == null) return;

    final paint = Paint()
      ..color = _purpleColor.withOpacity(0.58)
      ..strokeWidth = 1.3;

    for (final line in guide.lines) {
      _drawDashedLine(
        canvas,
        line.start,
        line.end,
        paint,
        dashLength: 10,
        gapLength: 7,
      );
    }

    final pointPaint = Paint()
      ..color = _purpleColor
      ..style = PaintingStyle.fill;

    final pointBorder = Paint()
      ..color = canvasTheme.handleFill
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(guide.point, 6, pointPaint);
    canvas.drawCircle(guide.point, 6, pointBorder);

    final label = guide.label;
    if (label == null || label.isEmpty) return;

    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: _purpleColor,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final labelPosition = guide.point + const Offset(10, 10);

    final rect = Rect.fromLTWH(
      labelPosition.dx - 5,
      labelPosition.dy - 3,
      painter.width + 10,
      painter.height + 6,
    );

    final bg = Paint()
      ..color = canvasTheme.labelBackground
      ..style = PaintingStyle.fill;

    final border = Paint()
      ..color = _purpleColor.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final rrect = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(7),
    );

    canvas.drawRRect(rrect, bg);
    canvas.drawRRect(rrect, border);

    painter.paint(canvas, labelPosition);
  }

  void _drawWalls(Canvas canvas) {
    for (final wall in document.walls) {
      final selected = selectedWallIds.contains(wall.id) ||
          (selectedObject?.isWall == true && selectedObject?.id == wall.id);

      if (_isVirtualWall(wall)) {
        _drawVirtualWall(canvas, wall, selected: selected);
      } else {
        _drawStructuralWall(canvas, wall, selected: selected);
      }

      if (selected) {
        final highlight = Paint()
          ..color = canvasTheme.accent
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

        canvas.drawCircle(wall.start.toOffset(), 14, highlight);
        canvas.drawCircle(wall.end.toOffset(), 14, highlight);
      }

      _drawWallLength(canvas, wall, selected: selected);
      _drawWallLocks(canvas, wall);
      _drawWallThicknessLabel(canvas, wall, selected: selected);
    }
  }

  void _drawStructuralWall(
    Canvas canvas,
    FloorWall wall, {
    required bool selected,
  }) {
    final thicknessPx = _wallThicknessPx(wall);

    final baseColor = _isLoadBearingWall(wall)
        ? _wallColor.withOpacity(0.98)
        : _wallColor.withOpacity(0.92);

    final paint = Paint()
      ..color = selected ? _selectedWallColor : baseColor
      ..strokeWidth = selected ? thicknessPx + 3 : thicknessPx
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final start = wall.start.toOffset();
    final end = wall.end.toOffset();

    canvas.drawLine(start, end, paint);

    if (_isLoadBearingWall(wall)) {
      _drawLoadBearingWallDetails(
        canvas,
        wall: wall,
        start: start,
        end: end,
        thicknessPx: thicknessPx,
        selected: selected,
      );
    }
  }

  void _drawLoadBearingWallDetails(
    Canvas canvas, {
    required FloorWall wall,
    required Offset start,
    required Offset end,
    required double thicknessPx,
    required bool selected,
  }) {
    final vector = end - start;
    final length = vector.distance;

    if (length <= 0.001) return;

    final unit = Offset(
      vector.dx / length,
      vector.dy / length,
    );

    final normal = Offset(-unit.dy, unit.dx);

    final innerPaint = Paint()
      ..color = selected
          ? canvasTheme.accent.withOpacity(0.28)
          : _canvasBackgroundColor.withOpacity(0.24)
      ..strokeWidth = math.max(1.2, thicknessPx * 0.12)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    final offset = normal * math.max(2.0, thicknessPx * 0.22);

    canvas.drawLine(start + offset, end + offset, innerPaint);
    canvas.drawLine(start - offset, end - offset, innerPaint);

    if (length < 90) return;

    final hatchPaint = Paint()
      ..color = selected
          ? canvasTheme.accent.withOpacity(0.36)
          : _canvasBackgroundColor.withOpacity(0.20)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    final hatchSpacing = math.max(26.0, thicknessPx * 1.3);
    final hatchHalf = math.max(5.0, thicknessPx * 0.26);

    for (double current = hatchSpacing; current < length; current += hatchSpacing) {
      final center = start + unit * current;

      canvas.drawLine(
        center - normal * hatchHalf - unit * hatchHalf,
        center + normal * hatchHalf + unit * hatchHalf,
        hatchPaint,
      );
    }
  }

  void _drawVirtualWall(
    Canvas canvas,
    FloorWall wall, {
    required bool selected,
  }) {
    final paint = Paint()
      ..color = selected ? canvasTheme.selectedWall : canvasTheme.virtualWall
      ..strokeWidth = selected ? 3.0 : 2.0
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    _drawDashedLine(
      canvas,
      wall.start.toOffset(),
      wall.end.toOffset(),
      paint,
      dashLength: 14,
      gapLength: 9,
    );
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint, {
    double dashLength = 12,
    double gapLength = 8,
  }) {
    _floorPlanDrawDashedLine(
      canvas: canvas,
      start: start,
      end: end,
      paint: paint,
      dash: dashLength,
      gap: gapLength,
    );
  }

  void _drawWallLocks(Canvas canvas, FloorWall wall) {
    if (!wall.angleLocked && !wall.lengthLocked) return;

    final start = wall.start.toOffset();
    final end = wall.end.toOffset();

    final vector = end - start;
    final length = vector.distance;

    if (length <= 0.001) return;

    final normal = Offset(-vector.dy / length, vector.dx / length);

    final center = Offset(
      (start.dx + end.dx) / 2,
      (start.dy + end.dy) / 2,
    );

    final icons = <String>[
      if (wall.angleLocked) '∠',
      if (wall.lengthLocked) 'L',
    ].join(' ');

    final painter = TextPainter(
      text: TextSpan(
        text: icons,
        style: TextStyle(
          color: _purpleColor,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final position = center + normal * 8 + const Offset(8, 8);

    final rect = Rect.fromLTWH(
      position.dx - 4,
      position.dy - 2,
      painter.width + 8,
      painter.height + 4,
    );

    final bg = Paint()
      ..color = canvasTheme.labelBackground
      ..style = PaintingStyle.fill;

    final rrect = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(5),
    );

    canvas.drawRRect(rrect, bg);
    painter.paint(canvas, position);
  }

  void _drawWallLength(
    Canvas canvas,
    FloorWall wall, {
    required bool selected,
  }) {
    final lengthM = wall.lengthM(document.scale.pixelsPerMeter);
    final text = '${lengthM.toStringAsFixed(2)} m';

    final start = wall.start.toOffset();
    final end = wall.end.toOffset();

    final vector = end - start;
    final length = vector.distance;

    if (length <= 0.001) return;

    final normal = Offset(-vector.dy / length, vector.dx / length);

    final center = Offset(
      (start.dx + end.dx) / 2,
      (start.dy + end.dy) / 2,
    );

    final thicknessPx = _wallThicknessPx(wall);
    final labelPosition = center - normal * ((thicknessPx / 2) + 18);

    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: selected ? canvasTheme.accent : canvasTheme.labelText,
          fontSize: selected ? 13 : 12,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final rect = Rect.fromCenter(
      center: labelPosition,
      width: painter.width + 12,
      height: painter.height + 8,
    );

    final bg = Paint()
      ..color = canvasTheme.labelBackground
      ..style = PaintingStyle.fill;

    final border = Paint()
      ..color = selected
          ? canvasTheme.accent.withOpacity(0.45)
          : canvasTheme.labelBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final rrect = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(7),
    );

    canvas.drawRRect(rrect, bg);
    canvas.drawRRect(rrect, border);

    painter.paint(
      canvas,
      labelPosition - Offset(painter.width / 2, painter.height / 2),
    );
  }

  void _drawWallThicknessLabel(
    Canvas canvas,
    FloorWall wall, {
    required bool selected,
  }) {
    if (!selected) return;

    final text = _wallThicknessLabel(wall);

    final start = wall.start.toOffset();
    final end = wall.end.toOffset();

    final vector = end - start;
    final length = vector.distance;

    if (length <= 0.001) return;

    final normal = Offset(-vector.dy / length, vector.dx / length);

    final center = Offset(
      (start.dx + end.dx) / 2,
      (start.dy + end.dy) / 2,
    );

    final thicknessPx = _wallThicknessPx(wall);
    final labelPosition = center + normal * ((thicknessPx / 2) + 18);

    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: _purpleColor,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final rect = Rect.fromCenter(
      center: labelPosition,
      width: painter.width + 12,
      height: painter.height + 8,
    );

    final bg = Paint()
      ..color = canvasTheme.labelBackground
      ..style = PaintingStyle.fill;

    final border = Paint()
      ..color = _purpleColor.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final rrect = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(7),
    );

    canvas.drawRRect(rrect, bg);
    canvas.drawRRect(rrect, border);

    painter.paint(
      canvas,
      labelPosition - Offset(painter.width / 2, painter.height / 2),
    );
  }

  void _drawOpenings(Canvas canvas) {
    for (final door in document.doors) {
      _drawOpening(
        canvas,
        data: door,
        isDoor: true,
        selected: selectedObject?.isDoor == true &&
            selectedObject?.id == door['id']?.toString(),
      );
    }

    for (final window in document.windows) {
      _drawOpening(
        canvas,
        data: window,
        isDoor: false,
        selected: selectedObject?.isWindow == true &&
            selectedObject?.id == window['id']?.toString(),
      );
    }
  }

  void _drawOpening(
    Canvas canvas, {
    required Map<String, dynamic> data,
    required bool isDoor,
    required bool selected,
  }) {
    final wallId = data['wall_id']?.toString();
    if (wallId == null) return;

    final wall = _findPainterWall(wallId);
    if (wall == null) return;

    final start = wall.start.toOffset();
    final end = wall.end.toOffset();

    final vector = end - start;
    final length = vector.distance;

    if (length <= 0) return;

    final unit = Offset(vector.dx / length, vector.dy / length);
    final normal = Offset(-unit.dy, unit.dx);

    final position = (data['position'] as num?)?.toDouble() ?? 0.5;
    final widthM =
        (data['width_m'] as num?)?.toDouble() ?? (isDoor ? 0.9 : 1.2);
    final widthPx = widthM * document.scale.pixelsPerMeter;

    final center = Offset(
      start.dx + vector.dx * position,
      start.dy + vector.dy * position,
    );

    final gapStart = center - unit * (widthPx / 2);
    final gapEnd = center + unit * (widthPx / 2);

    final thicknessPx = _wallThicknessPx(wall);

    final eraser = Paint()
      ..color = _canvasBackgroundColor
      ..strokeWidth = _isVirtualWall(wall) ? 8 : thicknessPx + 8
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    canvas.drawLine(gapStart, gapEnd, eraser);

    if (isDoor) {
      _drawDoor(
        canvas,
        data: data,
        wall: wall,
        gapStart: gapStart,
        gapEnd: gapEnd,
        unit: unit,
        normal: normal,
        widthPx: widthPx,
        selected: selected,
      );
    } else {
      _drawWindow(
        canvas,
        wall: wall,
        gapStart: gapStart,
        gapEnd: gapEnd,
        normal: normal,
        selected: selected,
      );
    }

    if (selected) {
      final selectPaint = Paint()
        ..color = _blueColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..isAntiAlias = true;

      final fill = Paint()
        ..color = canvasTheme.handleFill
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;

      canvas.drawCircle(center, 13, fill);
      canvas.drawCircle(center, 13, selectPaint);

      _drawOpeningResizeHandles(
        canvas,
        gapStart: gapStart,
        gapEnd: gapEnd,
        normal: normal,
        isDoor: isDoor,
      );
    }
  }

  void _drawOpeningResizeHandles(
    Canvas canvas, {
    required Offset gapStart,
    required Offset gapEnd,
    required Offset normal,
    required bool isDoor,
  }) {
    final color = isDoor ? canvasTheme.door : canvasTheme.window;

    final fill = Paint()
      ..color = canvasTheme.handleFill
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final border = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    final tickPaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    for (final point in [gapStart, gapEnd]) {
      canvas.drawCircle(point, 8, fill);
      canvas.drawCircle(point, 8, border);

      canvas.drawLine(
        point - normal * 10,
        point + normal * 10,
        tickPaint,
      );
    }
  }

  void _drawDoor(
    Canvas canvas, {
    required Map<String, dynamic> data,
    required FloorWall wall,
    required Offset gapStart,
    required Offset gapEnd,
    required Offset unit,
    required Offset normal,
    required double widthPx,
    required bool selected,
  }) {
    final type = data['type']?.toString() ?? 'single';

    if (type == 'garage_door') {
      _drawGarageDoor(
        canvas,
        gapStart: gapStart,
        gapEnd: gapEnd,
        normal: normal,
        selected: selected,
      );
      return;
    }

    final swingDirection = data['swing_direction']?.toString() ?? 'left';

    final doorPaint = Paint()
      ..color = selected ? canvasTheme.selectedWall : canvasTheme.door
      ..strokeWidth = selected ? 4 : 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    if (type == 'sliding') {
      canvas.drawLine(
        gapStart - normal * 8,
        gapEnd - normal * 8,
        doorPaint,
      );
      canvas.drawLine(
        gapStart + normal * 8,
        gapEnd + normal * 8,
        doorPaint,
      );
      return;
    }

    final hinge = swingDirection == 'right' ? gapEnd : gapStart;
    final direction = swingDirection == 'right' ? -1.0 : 1.0;
    final doorEnd = hinge + normal * widthPx * direction;

    canvas.drawLine(hinge, doorEnd, doorPaint);

    final rect = Rect.fromCircle(
      center: hinge,
      radius: widthPx,
    );

    final startAngle = math.atan2(unit.dy, unit.dx);
    final sweep = swingDirection == 'right' ? -math.pi / 2 : math.pi / 2;

    canvas.drawArc(
      rect,
      startAngle,
      sweep,
      false,
      doorPaint,
    );

    if (type == 'double') {
      final secondHinge = swingDirection == 'right' ? gapStart : gapEnd;
      final secondDoorEnd = secondHinge - normal * widthPx * 0.5 * direction;

      canvas.drawLine(secondHinge, secondDoorEnd, doorPaint);
    }
  }

  void _drawGarageDoor(
    Canvas canvas, {
    required Offset gapStart,
    required Offset gapEnd,
    required Offset normal,
    required bool selected,
  }) {
    final garagePaint = Paint()
      ..color = selected ? canvasTheme.selectedWall : _orangeColor
      ..strokeWidth = selected ? 5 : 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    canvas.drawLine(gapStart, gapEnd, garagePaint);

    const segmentCount = 5;

    for (var i = 1; i < segmentCount; i++) {
      final t = i / segmentCount;
      final p = Offset(
        gapStart.dx + (gapEnd.dx - gapStart.dx) * t,
        gapStart.dy + (gapEnd.dy - gapStart.dy) * t,
      );

      canvas.drawLine(
        p - normal * 10,
        p + normal * 10,
        garagePaint,
      );
    }
  }

  void _drawWindow(
    Canvas canvas, {
    required FloorWall wall,
    required Offset gapStart,
    required Offset gapEnd,
    required Offset normal,
    required bool selected,
  }) {
    final windowPaint = Paint()
      ..color = selected ? canvasTheme.selectedWall : _cyanColor
      ..strokeWidth = selected ? 4 : 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final thicknessPx = _wallThicknessPx(wall);
    final offset = normal * ((thicknessPx / 2) + 2);

    canvas.drawLine(
      gapStart + offset,
      gapEnd + offset,
      windowPaint,
    );

    canvas.drawLine(
      gapStart - offset,
      gapEnd - offset,
      windowPaint,
    );

    canvas.drawLine(
      gapStart,
      gapEnd,
      windowPaint,
    );
  }

  void _drawAssets(Canvas canvas) {
    for (final asset in document.assets) {
      _drawAsset(canvas, asset);
    }
  }

  void _drawAsset(Canvas canvas, FloorPlanAsset asset) {
    final type = floorPlanAssetTypeFromKey(asset.type);
    final selected =
        selectedObject?.isAsset == true && selectedObject?.id == asset.id;

    final center = asset.position.toOffset();
    final widthPx = asset.widthM * document.scale.pixelsPerMeter;
    final depthPx = asset.depthM * document.scale.pixelsPerMeter;

    canvas.save();

    canvas.translate(center.dx, center.dy);
    canvas.rotate(asset.rotationDeg * math.pi / 180.0);

    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: widthPx,
      height: depthPx,
    );

    final fill = Paint()
      ..color = selected ? canvasTheme.selectedAssetFill : canvasTheme.assetFill
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final border = Paint()
      ..color =
          selected ? canvasTheme.selectedAssetBorder : canvasTheme.assetBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = selected ? 2.5 : 2
      ..isAntiAlias = true;

    final rrect = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(8),
    );

    canvas.drawRRect(rrect, fill);
    canvas.drawRRect(rrect, border);

    _drawAssetShape(canvas, type, rect, selected: selected);

    final painter = TextPainter(
      text: TextSpan(
        text: asset.label ?? type.label,
        style: TextStyle(
          color: selected ? canvasTheme.accent : canvasTheme.labelText,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: math.max(widthPx - 6, 20));

    painter.paint(
      canvas,
      Offset(
        -painter.width / 2,
        -painter.height / 2,
      ),
    );

    if (selected) {
      final handlePaint = Paint()
        ..color = canvasTheme.handleFill
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;

      final handleBorder = Paint()
        ..color = canvasTheme.accent
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true;

      for (final point in [
        rect.topLeft,
        rect.topRight,
        rect.bottomLeft,
        rect.bottomRight,
      ]) {
        canvas.drawCircle(point, 5, handlePaint);
        canvas.drawCircle(point, 5, handleBorder);
      }
    }

    canvas.restore();
  }

  void _drawAssetShape(
    Canvas canvas,
    FloorPlanAssetType type,
    Rect rect, {
    required bool selected,
  }) {
    final color = selected ? canvasTheme.accent : canvasTheme.assetBorder;

    final paint = Paint()
      ..color = color.withOpacity(0.75)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    switch (type) {
      case FloorPlanAssetType.bed:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            rect.deflate(8),
            const Radius.circular(8),
          ),
          paint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              rect.left + 10,
              rect.top + 10,
              rect.width - 20,
              rect.height * 0.22,
            ),
            const Radius.circular(5),
          ),
          paint,
        );
        break;

      case FloorPlanAssetType.sofa:
        final seat = RRect.fromRectAndRadius(
          rect.deflate(8),
          const Radius.circular(10),
        );
        canvas.drawRRect(seat, paint);
        canvas.drawLine(
          Offset(rect.left + 10, rect.top + rect.height * 0.35),
          Offset(rect.right - 10, rect.top + rect.height * 0.35),
          paint,
        );
        break;

      case FloorPlanAssetType.car:
        final car = RRect.fromRectAndRadius(
          rect.deflate(8),
          const Radius.circular(18),
        );
        canvas.drawRRect(car, paint);
        canvas.drawLine(
          Offset(rect.left + rect.width * 0.25, rect.top + 8),
          Offset(rect.left + rect.width * 0.25, rect.bottom - 8),
          paint,
        );
        canvas.drawLine(
          Offset(rect.right - rect.width * 0.25, rect.top + 8),
          Offset(rect.right - rect.width * 0.25, rect.bottom - 8),
          paint,
        );
        break;

      case FloorPlanAssetType.table:
        canvas.drawOval(rect.deflate(8), paint);
        break;

      case FloorPlanAssetType.bathtub:
      case FloorPlanAssetType.shower:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            rect.deflate(8),
            const Radius.circular(12),
          ),
          paint,
        );
        canvas.drawCircle(
          rect.center,
          math.min(rect.width, rect.height) / 8,
          paint,
        );
        break;

      case FloorPlanAssetType.toilet:
        canvas.drawOval(rect.deflate(10), paint);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(rect.center.dx, rect.top + rect.height * 0.25),
              width: rect.width * 0.45,
              height: rect.height * 0.22,
            ),
            const Radius.circular(5),
          ),
          paint,
        );
        break;

      case FloorPlanAssetType.sink:
        canvas.drawOval(rect.deflate(8), paint);
        canvas.drawLine(
          Offset(rect.left + 8, rect.center.dy),
          Offset(rect.right - 8, rect.center.dy),
          paint,
        );
        break;

      case FloorPlanAssetType.stairs:
        const steps = 5;
        for (var i = 1; i < steps; i++) {
          final y = rect.top + rect.height * i / steps;
          canvas.drawLine(
            Offset(rect.left + 8, y),
            Offset(rect.right - 8, y),
            paint,
          );
        }
        break;

      case FloorPlanAssetType.kitchen:
      case FloorPlanAssetType.wardrobe:
      case FloorPlanAssetType.chair:
      case FloorPlanAssetType.custom:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            rect.deflate(8),
            const Radius.circular(7),
          ),
          paint,
        );
        break;
    }
  }

  void _drawCornerAngles(Canvas canvas) {
    final labels = _buildCornerAngleLabels(document);

    for (final label in labels) {
      final wallA = _findPainterWall(label.wallAId);
      final wallB = _findPainterWall(label.wallBId);

      if (wallA == null || wallB == null) continue;

      final aDirection = _directionFromCorner(wallA, label.corner);
      final bDirection = _directionFromCorner(wallB, label.corner);

      if (aDirection == null || bDirection == null) continue;

      final startAngle = math.atan2(aDirection.dy, aDirection.dx);
      final endAngle = math.atan2(bDirection.dy, bDirection.dx);

      var sweep = _normalizePositiveRadians(endAngle - startAngle);

      if (label.sweepSign < 0) {
        sweep = -(math.pi * 2 - sweep);
      }

      final radius = math.max(
        14.0,
        (label.labelPosition - label.corner).distance - 16,
      );

      final arcPaint = Paint()
        ..color = _purpleColor.withOpacity(0.72)
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true;

      canvas.drawArc(
        Rect.fromCircle(center: label.corner, radius: radius),
        startAngle,
        sweep,
        false,
        arcPaint,
      );

      _drawAngleLabel(canvas, label);
    }
  }

  void _drawAngleLabel(Canvas canvas, _CornerAngleLabelHit label) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: _formatAngleLabel(label.angleDeg),
        style: TextStyle(
          color: _purpleColor,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final backgroundPaint = Paint()
      ..color = canvasTheme.labelBackground
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = _purpleColor.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final rrect = RRect.fromRectAndRadius(
      label.labelRect,
      const Radius.circular(6),
    );

    canvas.drawRRect(rrect, backgroundPaint);
    canvas.drawRRect(rrect, borderPaint);

    textPainter.paint(
      canvas,
      Offset(
        label.labelPosition.dx - textPainter.width / 2,
        label.labelPosition.dy - textPainter.height / 2,
      ),
    );
  }

  void _drawCornerHandles(Canvas canvas) {
    final used = <String>{};

    for (final wall in document.walls) {
      final points = [
        wall.start.toOffset(),
        wall.end.toOffset(),
      ];

      for (final point in points) {
        final key = _cornerKey(point);

        if (used.contains(key)) continue;

        used.add(key);

        final selected = selectedVertexKeys.contains(key);

        if (selected) {
          final pulse = Paint()
            ..color = canvasTheme.accent.withOpacity(0.12)
            ..style = PaintingStyle.fill
            ..isAntiAlias = true;

          canvas.drawCircle(point, 18, pulse);
        }

        final fill = Paint()
          ..color = selected
              ? canvasTheme.accent.withOpacity(0.18)
              : canvasTheme.handleFill
          ..style = PaintingStyle.fill
          ..isAntiAlias = true;

        final stroke = Paint()
          ..color = selected ? canvasTheme.accent : canvasTheme.handleBorder
          ..strokeWidth = selected ? 3 : 2
          ..style = PaintingStyle.stroke
          ..isAntiAlias = true;

        final radius = selected ? 10.0 : 7.0;

        canvas.drawCircle(point, radius, fill);
        canvas.drawCircle(point, radius, stroke);
      }
    }
  }

  void _drawSelectedVertex(Canvas canvas) {
    final vertex = selectedVertex;
    if (vertex == null) return;

    final key = _cornerKey(vertex.point);

    if (selectedVertexKeys.contains(key)) {
      return;
    }

    final pulse = Paint()
      ..color = canvasTheme.accent.withOpacity(0.16)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final fill = Paint()
      ..color = canvasTheme.handleFill
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final border = Paint()
      ..color = canvasTheme.accent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    canvas.drawCircle(vertex.point, 18, pulse);
    canvas.drawCircle(vertex.point, 9, fill);
    canvas.drawCircle(vertex.point, 9, border);
  }

  void _drawPreviewWall(Canvas canvas) {
    if (previewStart == null || previewEnd == null) return;

    final paint = Paint()
      ..color = (previewIsVirtual ? canvasTheme.virtualWall : _wallColor)
          .withOpacity(0.72)
      ..strokeWidth = previewIsVirtual ? 2.5 : 12
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    if (previewIsVirtual) {
      _drawDashedLine(
        canvas,
        previewStart!,
        previewEnd!,
        paint,
        dashLength: 14,
        gapLength: 9,
      );
    } else {
      canvas.drawLine(previewStart!, previewEnd!, paint);
    }

    final handlePaint = Paint()
      ..color = canvasTheme.handleFill
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final handleStroke = Paint()
      ..color = previewIsVirtual ? canvasTheme.virtualWall : _wallColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    canvas.drawCircle(previewStart!, 7, handlePaint);
    canvas.drawCircle(previewStart!, 7, handleStroke);

    canvas.drawCircle(previewEnd!, 7, handlePaint);
    canvas.drawCircle(previewEnd!, 7, handleStroke);

    _drawPreviewLength(canvas);
  }

  void _drawPreviewLength(Canvas canvas) {
    final start = previewStart;
    final end = previewEnd;

    if (start == null || end == null) return;

    final vector = end - start;
    final lengthPx = vector.distance;

    if (lengthPx <= 0.001 || document.scale.pixelsPerMeter <= 0) return;

    final lengthM = lengthPx / document.scale.pixelsPerMeter;
    final text = '${lengthM.toStringAsFixed(2)} m';

    final center = Offset(
      (start.dx + end.dx) / 2,
      (start.dy + end.dy) / 2,
    );

    final normal = Offset(-vector.dy / lengthPx, vector.dx / lengthPx);
    final position = center - normal * 22;

    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: canvasTheme.labelText,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final rect = Rect.fromCenter(
      center: position,
      width: painter.width + 12,
      height: painter.height + 8,
    );

    final bg = Paint()
      ..color = canvasTheme.labelBackground
      ..style = PaintingStyle.fill;

    final rrect = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(7),
    );

    canvas.drawRRect(rrect, bg);

    painter.paint(
      canvas,
      position - Offset(painter.width / 2, painter.height / 2),
    );
  }

  void _drawSelectionRect(Canvas canvas) {
    final rect = selectionRect;
    if (rect == null) return;

    final fill = Paint()
      ..color = canvasTheme.accent.withOpacity(0.08)
      ..style = PaintingStyle.fill;

    final stroke = Paint()
      ..color = canvasTheme.accent.withOpacity(0.8)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawRect(rect, fill);
    canvas.drawRect(rect, stroke);
  }

  FloorWall? _findPainterWall(String id) {
    for (final wall in document.walls) {
      if (wall.id == id) return wall;
    }

    return null;
  }

  Offset? _directionFromCorner(FloorWall wall, Offset corner) {
    final start = wall.start.toOffset();
    final end = wall.end.toOffset();

    Offset vector;

    if ((start - corner).distance < 2) {
      vector = end - start;
    } else if ((end - corner).distance < 2) {
      vector = start - end;
    } else {
      return null;
    }

    final length = vector.distance;
    if (length <= 0.001) return null;

    return Offset(vector.dx / length, vector.dy / length);
  }

  @override
  bool shouldRepaint(covariant FloorPlanPainter oldDelegate) {
    return oldDelegate.canvasTheme != canvasTheme ||
        oldDelegate.document != document ||
        oldDelegate.previewStart != previewStart ||
        oldDelegate.previewEnd != previewEnd ||
        oldDelegate.previewIsVirtual != previewIsVirtual ||
        oldDelegate.selectedObject?.id != selectedObject?.id ||
        oldDelegate.selectedObject?.type != selectedObject?.type ||
        oldDelegate.selectedWallIds != selectedWallIds ||
        oldDelegate.selectedVertexKeys != selectedVertexKeys ||
        oldDelegate.selectedVertex?.point != selectedVertex?.point ||
        oldDelegate.selectedVertex?.connectedHandles.length !=
            selectedVertex?.connectedHandles.length ||
        oldDelegate.selectionRect != selectionRect ||
        oldDelegate.guideSnap != guideSnap ||
        oldDelegate.hoveredRoomCandidate != hoveredRoomCandidate ||
        oldDelegate.showCornerAngles != showCornerAngles ||
        oldDelegate.showRoomLabels != showRoomLabels ||
        oldDelegate.showRoomAreas != showRoomAreas;
  }
}

/// Shared dashed-line helper accessible to all painters in this library.
///
/// Both [FloorPlanPainter] and [_StyledFloorPlanExportPainter] use this
/// function to draw dashed lines, eliminating the previous duplication.
void _floorPlanDrawDashedLine({
  required Canvas canvas,
  required Offset start,
  required Offset end,
  required Paint paint,
  double dash = 12,
  double gap = 8,
}) {
  final vector = end - start;
  final length = vector.distance;

  if (length <= 0.001) return;

  final unit = Offset(
    vector.dx / length,
    vector.dy / length,
  );

  double current = 0;

  while (current < length) {
    final from = start + unit * current;
    final to = start + unit * math.min(current + dash, length);

    canvas.drawLine(from, to, paint);

    current += dash + gap;
  }
}
