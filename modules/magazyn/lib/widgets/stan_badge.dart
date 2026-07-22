import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import '../data/models/magazyn_model.dart';

class StanBadge extends ConsumerWidget {
  final MagazynPozycjaModel pozycja;
  const StanBadge({super.key, required this.pozycja});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    if (pozycja.pusty) {
      return _badge('BRAK', const Color(0xFF7B1F1F), Colors.white, theme);
    }
    if (pozycja.niski) {
      return _badge('NISKI', const Color(0xFF7B5E00), Colors.white, theme);
    }
    return _badge('OK', const Color(0xFF1E7A3A), Colors.white, theme);
  }

  Widget _badge(String label, Color bg, Color fg, ThemeColors theme) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label, style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold)),
      );
}
