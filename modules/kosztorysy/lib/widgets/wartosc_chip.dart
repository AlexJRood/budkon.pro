import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';

class WartoscChip extends ConsumerWidget {
  const WartoscChip({super.key, required this.wartosc, this.large = false});
  final double wartosc;
  final bool large;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 14 : 10,
        vertical: large ? 8 : 4,
      ),
      decoration: BoxDecoration(
        color: theme.themeColor.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _fmt(wartosc),
        style: TextStyle(
          fontSize: large ? 18 : 13,
          fontWeight: FontWeight.w700,
          color: theme.themeColor,
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
