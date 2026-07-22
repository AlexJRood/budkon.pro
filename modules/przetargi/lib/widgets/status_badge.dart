import 'package:flutter/material.dart';
import '../data/models/przetarg_model.dart';

class PrzetargStatusBadge extends StatelessWidget {
  final StatusPrzetargu status;

  const PrzetargStatusBadge(this.status, {super.key});

  (Color, Color) _colors() => switch (status) {
    StatusPrzetargu.nowy           => (Colors.white, const Color(0xFF1A5276)),
    StatusPrzetargu.analizowany    => (Colors.white, const Color(0xFF7B5E00)),
    StatusPrzetargu.kosztorysGotowy => (Colors.white, const Color(0xFF69212A)),
    StatusPrzetargu.zlozony        => (Colors.white, const Color(0xFF1A4A7A)),
    StatusPrzetargu.wygrany        => (Colors.white, const Color(0xFF1E7A3A)),
    StatusPrzetargu.przegrany      => (Colors.white, const Color(0xFF7B1F1F)),
    StatusPrzetargu.pominiety      => (const Color(0xFFBBBBBB), const Color(0xFF3A3A3A)),
  };

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = _colors();
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
