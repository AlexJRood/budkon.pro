import 'package:flutter/material.dart';
import '../data/models/budowa_model.dart';

class BudowaStatusBadge extends StatelessWidget {
  const BudowaStatusBadge({super.key, required this.status, this.small = false});
  final StatusBudowy status;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = _colors(status);
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
          color: fg,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  (Color, Color) _colors(StatusBudowy s) => switch (s) {
    StatusBudowy.oferta    => (Colors.white, const Color(0xFF7B5E00)),
    StatusBudowy.umowa     => (Colors.white, const Color(0xFF1A5276)),
    StatusBudowy.wToku     => (Colors.white, const Color(0xFF69212A)),
    StatusBudowy.zakonczona => (Colors.white, const Color(0xFF1E7A3A)),
    StatusBudowy.anulowana => (Colors.white, const Color(0xFF7B1F1F)),
  };
}
