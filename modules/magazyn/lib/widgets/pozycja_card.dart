import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import '../data/models/magazyn_model.dart';
import 'stan_badge.dart';

class PozycjaCard extends ConsumerWidget {
  final MagazynPozycjaModel pozycja;
  final VoidCallback? onTap;

  const PozycjaCard({super.key, required this.pozycja, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: theme.userTile,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: pozycja.pusty
                ? const Color(0xFF7B1F1F).withAlpha(120)
                : pozycja.niski
                    ? const Color(0xFF7B5E00).withAlpha(120)
                    : theme.bordercolor.withAlpha(50),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Text(pozycja.kategoria.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(pozycja.nazwa,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: theme.textColor)),
                        ),
                        StanBadge(pozycja: pozycja),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _InfoChip(
                          label: 'Stan: ${pozycja.stanAktualny.toStringAsFixed(1)} ${pozycja.jednostka}',
                          color: theme.textColor,
                        ),
                        const SizedBox(width: 8),
                        if (pozycja.zamowione > 0)
                          _InfoChip(
                            label: 'Zam: ${pozycja.zamowione.toStringAsFixed(1)}',
                            color: const Color(0xFF7B5E00),
                          ),
                      ],
                    ),
                    if (pozycja.cenaJednostkowa > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Wartość: ${pozycja.wartoscCalkowita.toStringAsFixed(2)} zł',
                        style: TextStyle(fontSize: 11, color: theme.textColor.withAlpha(120)),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 18, color: theme.textColor.withAlpha(80)),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final Color color;
  const _InfoChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, color: color)),
      );
}
