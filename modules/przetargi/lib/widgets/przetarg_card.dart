import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import '../data/models/przetarg_model.dart';
import 'ai_score_badge.dart';
import 'status_badge.dart';

class PrzetargCard extends ConsumerWidget {
  final PrzetargListItem przetarg;
  final VoidCallback onTap;

  const PrzetargCard({super.key, required this.przetarg, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    final p = przetarg;

    return Container(
      decoration: BoxDecoration(
        color: theme.userTile,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.bordercolor.withAlpha(60)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Górna belka: status + score + termin
              Row(
                children: [
                  PrzetargStatusBadge(p.status),
                  const Spacer(),
                  if (p.aiScore != null) ...[
                    AiScoreBadge(score: p.aiScore!, compact: true),
                    const SizedBox(width: 8),
                  ],
                  if (p.dniDoTerminu != null)
                    _TerminChip(dni: p.dniDoTerminu!, theme: theme),
                ],
              ),
              const SizedBox(height: 10),

              // Tytuł
              Text(
                p.tytul,
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // Zamawiający
              Row(
                children: [
                  Icon(Icons.business_outlined,
                      size: 13, color: theme.textColor.withAlpha(120)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      p.zamawiajacy,
                      style: TextStyle(
                          color: theme.textColor.withAlpha(120), fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Dolna belka: wartość + lokalizacja + kosztorys
              Row(
                children: [
                  if (p.wartoscSzacunkowa != null) ...[
                    Icon(Icons.payments_outlined,
                        size: 13, color: theme.themeColor),
                    const SizedBox(width: 4),
                    Text(
                      p.wartoscFormatted,
                      style: TextStyle(
                        color: theme.themeColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (p.lokalizacja.isNotEmpty) ...[
                    Icon(Icons.location_on_outlined,
                        size: 13, color: theme.textColor.withAlpha(100)),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        p.lokalizacja,
                        style: TextStyle(
                            color: theme.textColor.withAlpha(120), fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  if (p.kosztorysId != null)
                    Tooltip(
                      message: 'Kosztorys gotowy',
                      child: Icon(Icons.description_outlined,
                          size: 16, color: theme.themeColor),
                    ),
                ],
              ),

              // AI uwagi
              if (p.aiUwagi.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: p.aiUwagi
                      .take(3)
                      .map((u) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7B1F1F).withAlpha(60),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              u,
                              style: TextStyle(
                                  color: theme.textColor.withAlpha(200),
                                  fontSize: 11),
                            ),
                          ))
                      .toList(),
                ),
              ],

              // CPV kody
              if (p.cpvKody.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: p.cpvKody
                      .take(4)
                      .map((cpv) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.bordercolor.withAlpha(30),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: theme.bordercolor.withAlpha(60)),
                            ),
                            child: Text(
                              cpv,
                              style: TextStyle(
                                  color: theme.textColor.withAlpha(150),
                                  fontSize: 10),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TerminChip extends StatelessWidget {
  final int dni;
  final ThemeColors theme;
  const _TerminChip({required this.dni, required this.theme});

  @override
  Widget build(BuildContext context) {
    final urgent = dni <= 7;
    final overdue = dni < 0;
    final color = overdue || urgent
        ? const Color(0xFFE57373)
        : theme.textColor.withAlpha(160);
    final bg = overdue || urgent
        ? const Color(0xFF7B1F1F).withAlpha(60)
        : theme.bordercolor.withAlpha(30);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            overdue ? 'Termin minął' : '$dni dni',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: urgent || overdue ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
