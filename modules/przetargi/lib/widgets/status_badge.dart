import 'package:flutter/material.dart';

import '../data/models/przetarg_model.dart';

class PrzetargStatusBadge extends StatelessWidget {
  final StatusPrzetargu status;

  const PrzetargStatusBadge(this.status, {super.key});

  (Color, Color) _colors(ColorScheme cs) => switch (status) {
        StatusPrzetargu.nowy => (cs.onSecondaryContainer, cs.secondaryContainer),
        StatusPrzetargu.analizowany => (cs.onTertiaryContainer, cs.tertiaryContainer),
        StatusPrzetargu.kosztorysGotowy =>
          (cs.onPrimaryContainer, cs.primaryContainer),
        StatusPrzetargu.zlozony => (Colors.blue.shade800, Colors.blue.shade100),
        StatusPrzetargu.wygrany => (Colors.green.shade800, Colors.green.shade100),
        StatusPrzetargu.przegrany => (Colors.red.shade800, Colors.red.shade100),
        StatusPrzetargu.pominiety => (cs.onSurfaceVariant, cs.surfaceContainerHighest),
      };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (fg, bg) = _colors(cs);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
