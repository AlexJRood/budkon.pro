import 'package:flutter/material.dart';
import '../../data/models/projekt_model.dart';

class FloorPlanWidget extends StatefulWidget {
  final List<PomieszczenieProjekt> pomieszczenia;
  final bool editable;
  final ValueChanged<List<PomieszczenieProjekt>>? onChanged;
  final PomieszczenieProjekt? selected;
  final ValueChanged<PomieszczenieProjekt?>? onSelect;

  const FloorPlanWidget({
    super.key,
    required this.pomieszczenia,
    this.editable = false,
    this.onChanged,
    this.selected,
    this.onSelect,
  });

  @override
  State<FloorPlanWidget> createState() => _FloorPlanWidgetState();
}

class _FloorPlanWidgetState extends State<FloorPlanWidget> {
  String? _draggingId;
  Offset? _dragStart;
  Map<String, Offset> _roomStartPos = {};

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      return GestureDetector(
        onTapDown: widget.editable
            ? (d) => _handleTap(d.localPosition, size)
            : null,
        child: CustomPaint(
          size: size,
          painter: _FloorPlanPainter(
            pomieszczenia: widget.pomieszczenia,
            selectedId: widget.selected?.id,
            size: size,
          ),
          child: widget.editable
              ? _buildDragLayer(size)
              : const SizedBox.expand(),
        ),
      );
    });
  }

  Widget _buildDragLayer(Size size) {
    return Stack(
      children: widget.pomieszczenia.map((room) {
        final rect = _roomRect(room, size);
        return Positioned(
          left: rect.left,
          top: rect.top,
          width: rect.width,
          height: rect.height,
          child: GestureDetector(
            onPanStart: (d) {
              _draggingId = room.id;
              _dragStart = d.globalPosition;
              _roomStartPos = {room.id: Offset(room.x, room.y)};
            },
            onPanUpdate: (d) => _handleDrag(d, room, size),
            onPanEnd: (_) => _draggingId = null,
            onTap: () => widget.onSelect?.call(
              widget.selected?.id == room.id ? null : room,
            ),
            child: const ColoredBox(color: Colors.transparent),
          ),
        );
      }).toList(),
    );
  }

  Rect _roomRect(PomieszczenieProjekt room, Size size) {
    return Rect.fromLTWH(
      room.x * size.width,
      room.y * size.height,
      room.szerokosc * size.width,
      room.wysokosc * size.height,
    );
  }

  void _handleTap(Offset pos, Size size) {
    for (final room in widget.pomieszczenia.reversed) {
      if (_roomRect(room, size).contains(pos)) {
        widget.onSelect?.call(widget.selected?.id == room.id ? null : room);
        return;
      }
    }
    widget.onSelect?.call(null);
  }

  void _handleDrag(DragUpdateDetails d, PomieszczenieProjekt room, Size size) {
    if (_draggingId != room.id) return;
    final startPos = _roomStartPos[room.id] ?? Offset(room.x, room.y);
    // cumulative delta from pan start
    final delta = d.globalPosition - (_dragStart ?? d.globalPosition);
    final newX = (startPos.dx + delta.dx / size.width).clamp(0.0, 1.0 - room.szerokosc);
    final newY = (startPos.dy + delta.dy / size.height).clamp(0.0, 1.0 - room.wysokosc);
    final updated = widget.pomieszczenia
        .map((r) => r.id == room.id ? r.copyWith(x: newX, y: newY) : r)
        .toList();
    widget.onChanged?.call(updated);
  }
}

class _FloorPlanPainter extends CustomPainter {
  final List<PomieszczenieProjekt> pomieszczenia;
  final String? selectedId;
  final Size size;

  const _FloorPlanPainter({
    required this.pomieszczenia,
    this.selectedId,
    required this.size,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);
    for (final room in pomieszczenia) {
      _drawRoom(canvas, room, size);
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF333333).withAlpha(40)
      ..strokeWidth = 0.5;
    const step = 40.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawRoom(Canvas canvas, PomieszczenieProjekt room, Size size) {
    final rect = Rect.fromLTWH(
      room.x * size.width,
      room.y * size.height,
      room.szerokosc * size.width,
      room.wysokosc * size.height,
    );
    final isSelected = room.id == selectedId;

    // Fill
    canvas.drawRect(
      rect,
      Paint()..color = room.kolor.withAlpha(isSelected ? 80 : 50),
    );

    // Border
    canvas.drawRect(
      rect,
      Paint()
        ..color = isSelected ? Colors.white : room.kolor.withAlpha(200)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2.0 : 1.0,
    );

    // Label: name
    _drawLabel(
      canvas,
      rect,
      room.nazwa,
      '${room.powierzchnia.toStringAsFixed(1)} m²',
      isSelected,
    );
  }

  void _drawLabel(
      Canvas canvas, Rect rect, String nazwa, String area, bool selected) {
    final nameSpan = TextSpan(
      text: nazwa,
      style: TextStyle(
        color: selected ? Colors.white : const Color(0xFFDDDDDD),
        fontSize: (rect.height * 0.15).clamp(9.0, 14.0),
        fontWeight: FontWeight.w600,
      ),
    );
    final areSpan = TextSpan(
      text: '\n$area',
      style: TextStyle(
        color: selected
            ? Colors.white.withAlpha(200)
            : const Color(0xFFAAAAAA),
        fontSize: (rect.height * 0.12).clamp(8.0, 11.0),
      ),
    );

    final tp = TextPainter(
      text: TextSpan(children: [nameSpan, areSpan]),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: rect.width - 8);

    if (tp.height < rect.height - 8) {
      tp.paint(
        canvas,
        Offset(
          rect.left + (rect.width - tp.width) / 2,
          rect.top + (rect.height - tp.height) / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(_FloorPlanPainter old) =>
      old.pomieszczenia != pomieszczenia || old.selectedId != selectedId;
}
