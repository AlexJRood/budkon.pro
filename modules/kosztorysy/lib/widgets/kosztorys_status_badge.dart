import 'package:flutter/material.dart';
import '../data/models/kosztorys_model.dart';

class KosztorysStatusBadge extends StatelessWidget {
  const KosztorysStatusBadge({super.key, required this.status});
  final StatusKosztorysu status;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (fg, bg) = switch (status) {
      StatusKosztorysu.roboczy => (cs.onSurfaceVariant, cs.surfaceContainerHighest),
      StatusKosztorysu.oferta => (cs.onTertiaryContainer, cs.tertiaryContainer),
      StatusKosztorysu.zatwierdzony => (Colors.green.shade800, Colors.green.shade100),
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
