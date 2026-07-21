import 'package:flutter/material.dart';
import '../data/models/budowa_model.dart';

class EtapTile extends StatelessWidget {
  const EtapTile({super.key, required this.etap, required this.onStatusChange});
  final EtapBudowyModel etap;
  final ValueChanged<StatusEtapu> onStatusChange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: etap.status == StatusEtapu.wToku
            ? BorderSide(color: cs.primary, width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            _StatusIcon(status: etap.status),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    etap.nazwa,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      decoration: etap.status == StatusEtapu.zakonczony
                          ? TextDecoration.lineThrough
                          : null,
                      color: etap.status == StatusEtapu.zakonczony
                          ? cs.outline
                          : null,
                    ),
                  ),
                  if (etap.dataStart != null || etap.dataKoniec != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _dateRange(etap),
                      style: theme.textTheme.labelSmall?.copyWith(color: cs.outline),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            _StatusMenu(etap: etap, onStatusChange: onStatusChange),
          ],
        ),
      ),
    );
  }

  String _dateRange(EtapBudowyModel e) {
    final start = e.dataStart != null ? _fmt(e.dataStart!) : '—';
    final end = e.dataKoniec != null ? _fmt(e.dataKoniec!) : '—';
    return '$start → $end';
  }

  String _fmt(DateTime d) => '${d.day}.${d.month}.${d.year}';
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status});
  final StatusEtapu status;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return switch (status) {
      StatusEtapu.planowany => Icon(Icons.radio_button_unchecked, size: 22, color: cs.outline),
      StatusEtapu.wToku => Icon(Icons.pending_outlined, size: 22, color: cs.primary),
      StatusEtapu.zakonczony => Icon(Icons.check_circle, size: 22, color: Colors.green),
    };
  }
}

class _StatusMenu extends StatelessWidget {
  const _StatusMenu({required this.etap, required this.onStatusChange});
  final EtapBudowyModel etap;
  final ValueChanged<StatusEtapu> onStatusChange;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<StatusEtapu>(
      initialValue: etap.status,
      onSelected: onStatusChange,
      tooltip: 'Zmień status',
      itemBuilder: (_) => StatusEtapu.values
          .map((s) => PopupMenuItem(value: s, child: Text(s.label)))
          .toList(),
      child: const Icon(Icons.more_vert, size: 20),
    );
  }
}

