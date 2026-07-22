import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import '../data/models/odbiory_model.dart';
import 'protokol_status_badge.dart';

class ProtokolCard extends ConsumerWidget {
  final ProtokołOdbioruModel protokol;
  final VoidCallback? onTap;

  const ProtokolCard({super.key, required this.protokol, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    final p = protokol;

    return Card(
      elevation: 0,
      color: theme.userTile,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.bordercolor.withAlpha(40)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(p.typ.emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      p.tytul,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.textColor,
                      ),
                    ),
                  ),
                  ProtokolStatusBadge(p.status),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 13, color: theme.textColor.withAlpha(120)),
                  const SizedBox(width: 4),
                  Text(p.dataFmt,
                      style: TextStyle(fontSize: 12, color: theme.textColor.withAlpha(150))),
                  const SizedBox(width: 16),
                  if (p.kierownikImie.isNotEmpty) ...[
                    Icon(Icons.person_outline, size: 13, color: theme.textColor.withAlpha(120)),
                    const SizedBox(width: 4),
                    Text(p.kierownikImie,
                        style:
                            TextStyle(fontSize: 12, color: theme.textColor.withAlpha(150))),
                  ],
                ],
              ),
              if (p.punkty.isNotEmpty || p.usterkiOtwarte > 0) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (p.punkty.isNotEmpty) ...[
                      _StatChip(
                        icon: Icons.check,
                        label: '${p.punktyOk}/${p.punkty.length}',
                        color: Colors.green,
                        theme: theme,
                      ),
                      const SizedBox(width: 8),
                      if (p.punktyNok > 0)
                        _StatChip(
                          icon: Icons.close,
                          label: '${p.punktyNok} niezg.',
                          color: Colors.red,
                          theme: theme,
                        ),
                    ],
                    const Spacer(),
                    if (p.usterkiOtwarte > 0)
                      _StatChip(
                        icon: Icons.warning_amber_outlined,
                        label: '${p.usterkiOtwarte} uster.',
                        color: Colors.orange,
                        theme: theme,
                      ),
                    // Podpisy
                    const SizedBox(width: 8),
                    _PodpisIcon(
                      podpisany: p.podpisanyPrzezKierownika,
                      tooltip: 'Kierownik',
                      theme: theme,
                    ),
                    const SizedBox(width: 4),
                    _PodpisIcon(
                      podpisany: p.podpisanyPrzezInwestora,
                      tooltip: 'Inwestor',
                      theme: theme,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final ThemeColors theme;
  const _StatChip(
      {required this.icon,
      required this.label,
      required this.color,
      required this.theme});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 3),
            Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

class _PodpisIcon extends StatelessWidget {
  final bool podpisany;
  final String tooltip;
  final ThemeColors theme;
  const _PodpisIcon(
      {required this.podpisany, required this.tooltip, required this.theme});

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: Icon(
          podpisany ? Icons.draw : Icons.draw_outlined,
          size: 16,
          color: podpisany ? Colors.green : theme.textColor.withAlpha(60),
        ),
      );
}
