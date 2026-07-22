import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import '../data/models/budowa_model.dart';

class EtapTile extends ConsumerWidget {
  const EtapTile({super.key, required this.etap, required this.onStatusChange});
  final EtapBudowyModel etap;
  final ValueChanged<StatusEtapu> onStatusChange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);

    return Card(
      elevation: 0,
      color: theme.userTile,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: etap.status == StatusEtapu.wToku
            ? BorderSide(color: theme.themeColor, width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            _StatusIcon(status: etap.status, theme: theme),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    etap.nazwa,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: etap.status == StatusEtapu.zakonczony
                          ? theme.textColor.withAlpha(80)
                          : theme.textColor,
                      decoration: etap.status == StatusEtapu.zakonczony
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  if (etap.dataStart != null || etap.dataKoniec != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _dateRange(etap),
                      style: TextStyle(
                        color: theme.textColor.withAlpha(100),
                        fontSize: 11,
                      ),
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
    final start = e.dataStart != null ? _fmt(e.dataStart!) : 'â€”';
    final end = e.dataKoniec != null ? _fmt(e.dataKoniec!) : 'â€”';
    return '$start â†’ $end';
  }

  String _fmt(DateTime d) => '${d.day}.${d.month}.${d.year}';
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status, required this.theme});
  final StatusEtapu status;
  final ThemeColors theme;

  @override
  Widget build(BuildContext context) => switch (status) {
    StatusEtapu.planowany => Icon(Icons.radio_button_unchecked, size: 22, color: theme.textColor.withAlpha(100)),
    StatusEtapu.wToku     => Icon(Icons.pending_outlined, size: 22, color: theme.themeColor),
    StatusEtapu.zakonczony => const Icon(Icons.check_circle, size: 22, color: Colors.green),
  };
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
      tooltip: 'ZmieĹ„ status',
      itemBuilder: (_) => StatusEtapu.values
          .map((s) => PopupMenuItem(value: s, child: Text(s.label)))
          .toList(),
      child: const Icon(Icons.more_vert, size: 20),
    );
  }
}


