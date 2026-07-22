import 'package:flutter/material.dart';
import '../data/models/rozliczenia_model.dart';

class FakturaStatusBadge extends StatelessWidget {
  final StatusFaktury status;
  const FakturaStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, bg) = switch (status) {
      StatusFaktury.szkic => ('SZKIC', const Color(0xFF3A3A3A)),
      StatusFaktury.wystawiona => ('WYSTAWIONA', const Color(0xFF7B5E00)),
      StatusFaktury.oplacona => ('OPŁACONA', const Color(0xFF1E7A3A)),
      StatusFaktury.przeterminowana => ('PRZETERMINOWANA', const Color(0xFF7B1F1F)),
      StatusFaktury.anulowana => ('ANULOWANA', const Color(0xFF4A4A4A)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
