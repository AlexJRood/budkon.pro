import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import '../data/models/harmonogram_model.dart';

class GanttBar extends ConsumerWidget {
  final ZadanieModel zadanie;
  final DateTime projectStart;
  final DateTime projectEnd;

  const GanttBar({
    super.key,
    required this.zadanie,
    required this.projectStart,
    required this.projectEnd,
  });

  Color _barColor(ThemeColors theme) {
    if (zadanie.isOpoznione) return Colors.orange.shade700;
    return switch (zadanie.status) {
      StatusZadania.zakonczone => Colors.green,
      StatusZadania.w_toku    => theme.themeColor,
      StatusZadania.wstrzymane => theme.textColor.withAlpha(100),
      _                       => theme.themeColor.withAlpha(120),
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
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
    final barColor = _barColor(theme);

    return LayoutBuilder(builder: (ctx, constraints) {
      final total = constraints.maxWidth;

      return SizedBox(
        height: 24,
        child: Stack(
          children: [
            // TĹ‚o
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.bordercolor.withAlpha(30),
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
                  color: barColor.withAlpha(60),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progressFrac.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
            // OpĂłĹşnienie marker
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
                      color: Colors.orange.shade300,
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

