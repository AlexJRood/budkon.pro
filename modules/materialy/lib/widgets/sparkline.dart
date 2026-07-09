import 'dart:math';
import 'package:flutter/material.dart';
import '../data/models/materialy_model.dart';

/// Miniaturowy wykres cen rysowany CustomPainterem.
/// Nie wymaga żadnej biblioteki zewnętrznej.
class PriceSparkline extends StatelessWidget {
  final List<double> ceny;
  final TrendCeny? trend;
  final double width;
  final double height;
  final bool showDots;

  const PriceSparkline({
    super.key,
    required this.ceny,
    this.trend,
    this.width = 80,
    this.height = 32,
    this.showDots = false,
  });

  Color get _color => switch (trend) {
        TrendCeny.rosnacy => const Color(0xFFEF5350),
        TrendCeny.spadajacy => const Color(0xFF66BB6A),
        _ => const Color(0xFF90A4AE),
      };

  @override
  Widget build(BuildContext context) {
    if (ceny.length < 2) {
      return SizedBox(width: width, height: height);
    }
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _SparklinePainter(
          values: ceny,
          color: _color,
          showDots: showDots,
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final bool showDots;

  _SparklinePainter({
    required this.values,
    required this.color,
    required this.showDots,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final minV = values.reduce(min);
    final maxV = values.reduce(max);
    final range = maxV - minV;

    double toX(int i) =>
        i / (values.length - 1) * size.width;
    double toY(double v) {
      if (range == 0) return size.height / 2;
      return size.height - ((v - minV) / range) * size.height * 0.85 -
          size.height * 0.075;
    }

    final path = Path();
    path.moveTo(toX(0), toY(values[0]));
    for (int i = 1; i < values.length; i++) {
      // Smooth cubic bezier
      final prev = Offset(toX(i - 1), toY(values[i - 1]));
      final curr = Offset(toX(i), toY(values[i]));
      final cp1 = Offset((prev.dx + curr.dx) / 2, prev.dy);
      final cp2 = Offset((prev.dx + curr.dx) / 2, curr.dy);
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, curr.dx, curr.dy);
    }

    // Fill gradient pod linią
    final fillPath = Path.from(path)
      ..lineTo(toX(values.length - 1), size.height)
      ..lineTo(toX(0), size.height)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withAlpha(60), color.withAlpha(0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Linia
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Ostatni punkt — duży dot
    final lastX = toX(values.length - 1);
    final lastY = toY(values.last);
    canvas.drawCircle(
      Offset(lastX, lastY),
      3,
      Paint()..color = color,
    );

    if (showDots) {
      for (int i = 0; i < values.length - 1; i++) {
        canvas.drawCircle(
          Offset(toX(i), toY(values[i])),
          2,
          Paint()..color = color.withAlpha(160),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) =>
      old.values != values || old.color != color;
}

/// Badge trendu: strzałka + procent + porada na tap
class TrendBadge extends StatelessWidget {
  final TrendCeny? trend;
  final double? zmianaProc;
  final bool showPorada;

  const TrendBadge({
    super.key,
    required this.trend,
    this.zmianaProc,
    this.showPorada = false,
  });

  Color get _bg => switch (trend) {
        TrendCeny.rosnacy => const Color(0x33EF5350),
        TrendCeny.spadajacy => const Color(0x3366BB6A),
        _ => const Color(0x2290A4AE),
      };

  Color get _fg => switch (trend) {
        TrendCeny.rosnacy => const Color(0xFFEF5350),
        TrendCeny.spadajacy => const Color(0xFF66BB6A),
        _ => const Color(0xFF90A4AE),
      };

  @override
  Widget build(BuildContext context) {
    if (trend == null) return const SizedBox.shrink();

    final zStr = zmianaProc != null
        ? '${zmianaProc! > 0 ? '+' : ''}${zmianaProc!.toStringAsFixed(1)}%'
        : trend!.symbol;

    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _fg.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            trend!.symbol,
            style: TextStyle(color: _fg, fontSize: 11, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 3),
          Text(
            zStr,
            style: TextStyle(color: _fg, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );

    if (!showPorada) return badge;

    return Tooltip(
      message: trend!.porada,
      child: badge,
    );
  }
}
