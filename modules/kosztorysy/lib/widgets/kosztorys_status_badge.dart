import 'package:flutter/material.dart';
import '../data/models/kosztorys_model.dart';

class KosztorysStatusBadge extends StatelessWidget {
  const KosztorysStatusBadge({super.key, required this.status});
  final StatusKosztorysu status;

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = switch (status) {
      StatusKosztorysu.roboczy      => (const Color(0xFFBBBBBB), const Color(0xFF3A3A3A)),
      StatusKosztorysu.oferta       => (Colors.white, const Color(0xFF7B5E00)),
      StatusKosztorysu.zatwierdzony => (Colors.white, const Color(0xFF1E7A3A)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}
