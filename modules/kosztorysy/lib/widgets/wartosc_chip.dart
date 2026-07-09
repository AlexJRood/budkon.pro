import 'package:flutter/material.dart';

class WartoscChip extends StatelessWidget {
  const WartoscChip({super.key, required this.wartosc, this.large = false});
  final double wartosc;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 14 : 10,
        vertical: large ? 8 : 4,
      ),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _fmt(wartosc),
        style: TextStyle(
          fontSize: large ? 18 : 13,
          fontWeight: FontWeight.w700,
          color: cs.onPrimaryContainer,
        ),
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(2)} mln zł';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)} tys. zł';
    return '${v.toStringAsFixed(2)} zł';
  }
}
