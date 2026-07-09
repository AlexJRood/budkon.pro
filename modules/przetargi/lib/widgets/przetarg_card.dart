import 'package:flutter/material.dart';

import '../data/models/przetarg_model.dart';
import 'ai_score_badge.dart';
import 'status_badge.dart';

class PrzetargCard extends StatelessWidget {
  final PrzetargListItem przetarg;
  final VoidCallback onTap;

  const PrzetargCard({super.key, required this.przetarg, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final p = przetarg;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant.withOpacity(0.5)),
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
                    _TerminChip(dni: p.dniDoTerminu!),
                ],
              ),
              const SizedBox(height: 10),

              // Tytuł
              Text(
                p.tytul,
                style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // Zamawiający
              Row(
                children: [
                  Icon(Icons.business_outlined,
                      size: 13, color: cs.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      p.zamawiajacy,
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Dolna belka: wartość + lokalizacja
              Row(
                children: [
                  if (p.wartoscSzacunkowa != null) ...[
                    Icon(Icons.payments_outlined,
                        size: 13, color: cs.primary),
                    const SizedBox(width: 4),
                    Text(
                      p.wartoscFormatted,
                      style: tt.bodySmall?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (p.lokalizacja.isNotEmpty) ...[
                    Icon(Icons.location_on_outlined,
                        size: 13, color: cs.onSurfaceVariant),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        p.lokalizacja,
                        style: tt.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  if (p.kosztorysId != null)
                    Tooltip(
                      message: 'Kosztorys gotowy',
                      child: Icon(Icons.description_outlined,
                          size: 16, color: cs.primary),
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
                      .map(
                        (u) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: cs.errorContainer.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            u,
                            style: tt.labelSmall
                                ?.copyWith(color: cs.onErrorContainer),
                          ),
                        ),
                      )
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
  const _TerminChip({required this.dni});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final urgent = dni <= 7;
    final color = urgent ? cs.error : cs.onSurfaceVariant;
    final bg = urgent
        ? cs.errorContainer.withOpacity(0.3)
        : cs.surfaceContainerHighest;

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
            '$dni dni',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: urgent ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
