import 'package:flutter/material.dart';
import '../data/models/sprzet_model.dart';

class SprzetStatusBadge extends StatelessWidget {
  final StatusSprzetu status;
  const SprzetStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, bg) = switch (status) {
      StatusSprzetu.dostepny => ('DOSTĘPNY', const Color(0xFF1E7A3A)),
      StatusSprzetu.uzyciu => ('W UŻYCIU', const Color(0xFF691225)),
      StatusSprzetu.serwis => ('SERWIS', const Color(0xFF7B5E00)),
      StatusSprzetu.nieaktywny => ('NIEAKTYWNY', const Color(0xFF3A3A3A)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
