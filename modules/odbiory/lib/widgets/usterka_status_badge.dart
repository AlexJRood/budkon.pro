import 'package:flutter/material.dart';
import '../data/models/odbiory_model.dart';

class UsterkaStatusBadge extends StatelessWidget {
  final StatusUsterki status;
  const UsterkaStatusBadge(this.status, {super.key});

  (Color, Color) get _colors => switch (status) {
        StatusUsterki.otwarta => (Colors.white, const Color(0xFF7B1F1F)),
        StatusUsterki.naprawiana => (Colors.white, const Color(0xFF7B5E00)),
        StatusUsterki.naprawiona => (Colors.white, const Color(0xFF1E7A3A)),
        StatusUsterki.odrzucona => (const Color(0xFFBBBBBB), const Color(0xFF3A3A3A)),
      };

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = _colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        status.label,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
