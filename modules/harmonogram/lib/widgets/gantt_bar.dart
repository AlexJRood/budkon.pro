import 'package:flutter/material.dart';
import '../data/models/harmonogram_model.dart';

class GanttBar extends StatelessWidget {
  final ZadanieModel zadanie;
  final DateTime projectStart;
  final DateTime projectEnd;

  const GanttBar({
    super.key,
    required this.zadanie,
    required this.projectStart,
    required this.projectEnd,
  });

  Color _barColor(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    if (zadanie.isOpoznione) return Colors.orange.shade700;
    return switch (zadanie.status) {
      StatusZadania.zakonczone => cs.secondary,
      StatusZadania.w_toku => cs.primary,
      StatusZadania.wstrzymane => cs.outline,
      _ => cs.primaryContainer,
    };
  }

  @override
  Widget build(BuildContext context) {
    final totalDays =
        projectEnd.difference(projectStart).inDays.clamp(1, 9999).toDouble();

    final start = zadanie.dataStart ?? projectStart;
    final end = zadanie.dataKoniec ??
        start.add(Duration(days: zadanie.durationDni));

    final offsetDays =
        start.difference(projectStart).inDays.clamp(0, totalDays.toInt());
    final durationDays =
        end.difference(start).inDays.clamp(1, totalDays.toInt()).toDouble();

    final offsetFrac = offsetDays / totalDays;
    final widthFrac = durationDays / totalDays;
    final progressFrac = zadanie.postepProcent / 100;

    return LayoutBuilder(builder: (ctx, constraints) {
      final total = constraints.maxWidth;

      return SizedBox(
        height: 24,
        child: Stack(
          children: [
            // Tło
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(ctx)
                      .colorScheme
                      .surfaceContainerHighest
                      .withOpacity(0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            // Pasek zadania
            Positioned(
              left: (offsetFrac * total).clamp(0.0, total - 4),
              top: 2,
              bottom: 2,
              child: Container(
                width: (widthFrac * total).clamp(4.0, total),
                decoration: BoxDecoration(
                  color: _barColor(ctx).withOpacity(0.25),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progressFrac.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _barColor(ctx),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
            // Opóźnienie marker
            if (zadanie.isOpoznione)
              Positioned(
                right: 4,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Text(
                    '+${zadanie.opoznienieDni}d',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.orange.shade900,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}

