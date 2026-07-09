import 'package:flutter/material.dart';
import 'package:core/theme/apptheme.dart';

import '../../models/automation_graph.dart';
import 'automation_node_ports.dart';

class AutomationEdgePainter extends CustomPainter {
  final AutomationGraph graph;
  final ThemeColors theme;
  final String? selectedEdgeId;
  final String? connectingFromNodeId;
  final Offset? connectionPreviewStart;
  final Offset? connectionPreviewEnd;
  final bool showGrid;
  final double gridSize;
  final Rect? selectionRect;
  final double edgePulse;

  AutomationEdgePainter({
    required this.graph,
    required this.theme,
    this.selectedEdgeId,
    this.connectingFromNodeId,
    this.connectionPreviewStart,
    this.connectionPreviewEnd,
    this.showGrid = true,
    this.gridSize = 24,
    this.selectionRect,
    this.edgePulse = 0,
  });

  static const nodeWidth = AutomationNodePortResolver.nodeWidth;

  Offset _outputPoint(AutomationGraphNode node, {String? sourceHandle}) {
    return AutomationNodePortResolver.outputPoint(node, sourceHandle: sourceHandle);
  }

  Offset _inputPoint(AutomationGraphNode node, {String? targetHandle}) {
    return AutomationNodePortResolver.inputPoint(node, targetHandle: targetHandle);
  }

  double _handleDistance(Offset start, Offset end) {
    final distance = (end.dx - start.dx).abs();
    return distance.clamp(80.0, 180.0).toDouble();
  }

  Offset _cubicPoint(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
    final mt = 1 - t;
    final a = mt * mt * mt;
    final b = 3 * mt * mt * t;
    final c = 3 * mt * t * t;
    final d = t * t * t;

    return Offset(
      a * p0.dx + b * p1.dx + c * p2.dx + d * p3.dx,
      a * p0.dy + b * p1.dy + c * p2.dy + d * p3.dy,
    );
  }

  Path _curvePath(Offset start, Offset end) {
    final handle = _handleDistance(start, end);
    final c1 = start + Offset(handle, 0);
    final c2 = end - Offset(handle, 0);

    return Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy);
  }

  void _drawArrow(Canvas canvas, Paint paint, Offset start, Offset end) {
    final direction = end - start;
    if (direction.distance == 0) return;

    final unit = direction / direction.distance;
    final normal = Offset(-unit.dy, unit.dx);
    final p1 = end - unit * 11 + normal * 6;
    final p2 = end - unit * 11 - normal * 6;

    final arrow = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(p1.dx, p1.dy)
      ..moveTo(end.dx, end.dy)
      ..lineTo(p2.dx, p2.dy);

    canvas.drawPath(arrow, paint);
  }

  void _drawSelectedEdgePulse(Canvas canvas, Offset start, Offset end) {
    final handle = _handleDistance(start, end);
    final c1 = start + Offset(handle, 0);
    final c2 = end - Offset(handle, 0);
    final t = (0.16 + edgePulse * 0.68).clamp(0.0, 1.0).toDouble();
    final point = _cubicPoint(start, c1, c2, end, t);

    final haloPaint = Paint()
      ..color = theme.themeColor.withAlpha(70)
      ..style = PaintingStyle.fill;

    final dotPaint = Paint()
      ..color = Colors.white.withAlpha(240)
      ..style = PaintingStyle.fill;

    final corePaint = Paint()
      ..color = theme.themeColor.withAlpha(245)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(point, 9, haloPaint);
    canvas.drawCircle(point, 5.5, dotPaint);
    canvas.drawCircle(point, 3.2, corePaint);
  }



  void _drawEdgeLabel(
    Canvas canvas,
    AutomationGraphNode source,
    String? sourceHandle,
    Offset start,
    Offset end,
    Color color,
  ) {
    if (sourceHandle == null || sourceHandle == 'default') return;

    final label = AutomationNodePortResolver.outputLabel(source, sourceHandle);
    if (label.trim().isEmpty) return;

    final handle = _handleDistance(start, end);
    final c1 = start + Offset(handle, 0);
    final c2 = end - Offset(handle, 0);
    final p = _cubicPoint(start, c1, c2, end, 0.20);

    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: theme.textColor.withAlpha(230),
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: 96);

    final rect = Rect.fromLTWH(
      p.dx - 4,
      p.dy - painter.height / 2 - 4,
      painter.width + 12,
      painter.height + 8,
    );

    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(999));

    final fill = Paint()
      ..color = theme.dashboardContainer.withAlpha(235)
      ..style = PaintingStyle.fill;
    final border = Paint()
      ..color = color.withAlpha(125)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawRRect(rrect, fill);
    canvas.drawRRect(rrect, border);
    painter.paint(canvas, Offset(rect.left + 6, rect.top + 4));
  }

  void _drawGrid(Canvas canvas, Size size) {
    if (!showGrid || gridSize <= 1) return;

    final paint = Paint()
      ..color = theme.dashboardBoarder.withAlpha(42)
      ..strokeWidth = 0.6;

    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final majorPaint = Paint()
      ..color = theme.dashboardBoarder.withAlpha(70)
      ..strokeWidth = 0.9;
    final major = gridSize * 5;

    for (double x = 0; x <= size.width; x += major) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), majorPaint);
    }

    for (double y = 0; y <= size.height; y += major) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), majorPaint);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);

    final nodesById = {
      for (final node in graph.nodes) node.id: node,
    };

    for (final edge in graph.edges) {
      final source = nodesById[edge.source];
      final target = nodesById[edge.target];
      if (source == null || target == null) continue;

      final selected = selectedEdgeId == edge.id;
      final portColor = AutomationNodePortResolver.outputColor(source, edge.sourceHandle);
      final isFalsePath = edge.sourceHandle == 'false' || edge.sourceHandle == 'else' || edge.sourceHandle == 'rejected' || edge.sourceHandle == 'error';
      final isTruePath = edge.sourceHandle == 'true' || edge.sourceHandle == 'approved' || edge.sourceHandle == 'success';

      final edgeColor = selected
          ? theme.themeColor
          : isFalsePath
              ? Colors.deepOrange.withAlpha(184)
              : isTruePath
                  ? Colors.green.withAlpha(184)
                  : (portColor ?? theme.themeColor).withAlpha(168);

      final glowPaint = Paint()
        ..color = theme.themeColor.withAlpha(selected ? 82 : 20)
        ..strokeWidth = selected ? 11 : 5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final shadowPaint = Paint()
        ..color = theme.themeColor.withAlpha(selected ? 60 : 20)
        ..strokeWidth = selected ? 7 : 5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final paint = Paint()
        ..color = edgeColor
        ..strokeWidth = selected ? 3.8 : 2.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final start = _outputPoint(source, sourceHandle: edge.sourceHandle);
      final end = _inputPoint(target, targetHandle: edge.targetHandle);
      final path = _curvePath(start, end);

      if (selected) {
        canvas.drawPath(path, glowPaint);
      }
      canvas.drawPath(path, shadowPaint);
      canvas.drawPath(path, paint);
      _drawArrow(canvas, paint, start, end);
      _drawEdgeLabel(canvas, source, edge.sourceHandle, start, end, edgeColor);

      if (selected) {
        _drawSelectedEdgePulse(canvas, start, end);
      }
    }

    if (connectionPreviewStart != null && connectionPreviewEnd != null) {
      final previewShadowPaint = Paint()
        ..color = theme.themeColor.withAlpha(55)
        ..strokeWidth = 8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final previewPaint = Paint()
        ..color = theme.themeColor.withAlpha(225)
        ..strokeWidth = 2.9
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final path = _curvePath(connectionPreviewStart!, connectionPreviewEnd!);
      canvas.drawPath(path, previewShadowPaint);
      canvas.drawPath(path, previewPaint);
      _drawArrow(canvas, previewPaint, connectionPreviewStart!, connectionPreviewEnd!);
    }

    if (selectionRect != null) {
      final fill = Paint()
        ..color = theme.themeColor.withAlpha(22)
        ..style = PaintingStyle.fill;
      final border = Paint()
        ..color = theme.themeColor.withAlpha(140)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4;

      canvas.drawRRect(RRect.fromRectAndRadius(selectionRect!, const Radius.circular(8)), fill);
      canvas.drawRRect(RRect.fromRectAndRadius(selectionRect!, const Radius.circular(8)), border);
    }
  }

  @override
  bool shouldRepaint(covariant AutomationEdgePainter oldDelegate) {
    return oldDelegate.graph != graph ||
        oldDelegate.theme != theme ||
        oldDelegate.selectedEdgeId != selectedEdgeId ||
        oldDelegate.connectingFromNodeId != connectingFromNodeId ||
        oldDelegate.connectionPreviewStart != connectionPreviewStart ||
        oldDelegate.connectionPreviewEnd != connectionPreviewEnd ||
        oldDelegate.showGrid != showGrid ||
        oldDelegate.gridSize != gridSize ||
        oldDelegate.selectionRect != selectionRect ||
        oldDelegate.edgePulse != edgePulse;
  }
}
