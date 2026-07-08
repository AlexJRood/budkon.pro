import 'package:flutter/material.dart';
import '../data/models/budowa_model.dart';

class BudowaStatusBadge extends StatelessWidget {
  const BudowaStatusBadge({super.key, required this.status, this.small = false});
  final StatusBudowy status;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final (color, bg) = _colors(context, status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 6 : 10,
        vertical: small ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: small ? 10 : 12,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  (Color, Color) _colors(BuildContext context, StatusBudowy s) {
    final cs = Theme.of(context).colorScheme;
    return switch (s) {
      StatusBudowy.oferta => (cs.onTertiaryContainer, cs.tertiaryContainer),
      StatusBudowy.umowa => (cs.onSecondaryContainer, cs.secondaryContainer),
      StatusBudowy.wToku => (cs.onPrimaryContainer, cs.primaryContainer),
      StatusBudowy.zakonczona => (Colors.green.shade800, Colors.green.shade100),
      StatusBudowy.anulowana => (cs.onErrorContainer, cs.errorContainer),
    };
  }
}
