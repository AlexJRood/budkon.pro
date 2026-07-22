import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import '../data/models/sprzet_model.dart';
import 'sprzet_status_badge.dart';

class SprzetCard extends ConsumerWidget {
  final SprzetModel sprzet;
  final VoidCallback? onTap;

  const SprzetCard({super.key, required this.sprzet, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    final przegladAlert = sprzet.przegladWygasl || sprzet.przegladWygasa;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: theme.userTile,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: przegladAlert
                ? (sprzet.przegladWygasl
                    ? const Color(0xFF7B1F1F).withAlpha(120)
                    : const Color(0xFF7B5E00).withAlpha(120))
                : theme.bordercolor.withAlpha(50),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Text(sprzet.kategoria.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(sprzet.nazwa,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: theme.textColor)),
                        ),
                        SprzetStatusBadge(status: sprzet.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (sprzet.nrSeryjny != null) ...[
                          Icon(Icons.tag, size: 12, color: theme.textColor.withAlpha(100)),
                          const SizedBox(width: 3),
                          Text(sprzet.nrSeryjny!,
                              style: TextStyle(
                                  fontSize: 11, color: theme.textColor.withAlpha(120))),
                          const SizedBox(width: 10),
                        ],
                        if (sprzet.lokalizacja != null) ...[
                          Icon(Icons.location_on_outlined,
                              size: 12, color: theme.textColor.withAlpha(100)),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(sprzet.lokalizacja!,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 11, color: theme.textColor.withAlpha(120))),
                          ),
                        ],
                      ],
                    ),
                    if (przegladAlert) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              size: 13,
                              color: sprzet.przegladWygasl
                                  ? const Color(0xFF7B1F1F)
                                  : const Color(0xFF7B5E00)),
                          const SizedBox(width: 4),
                          Text(
                            sprzet.przegladWygasl
                                ? 'Przegląd wygasł ${sprzet.dataKoncaFmt}'
                                : 'Przegląd do ${sprzet.dataKoncaFmt}',
                            style: TextStyle(
                              fontSize: 11,
                              color: sprzet.przegladWygasl
                                  ? const Color(0xFF7B1F1F)
                                  : const Color(0xFF7B5E00),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
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
