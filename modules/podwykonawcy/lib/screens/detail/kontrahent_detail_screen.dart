import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/podwykonawcy_model.dart';
import '../../data/providers/podwykonawcy_provider.dart';
import '../../data/services/podwykonawcy_api.dart';

class KontrahentDetailScreen extends ConsumerWidget {
  final PowiazanieModel powiazanie;
  final int budowaId;

  const KontrahentDetailScreen({
    super.key,
    required this.powiazanie,
    required this.budowaId,
  });

  static final _fmt = DateFormat('dd.MM.yyyy');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final k = powiazanie.kontrahent;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(k.displayName),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'status') {
                await _zmienStatus(context, ref);
              } else if (v == 'usun') {
                await _usunPowiazanie(context, ref);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'status',
                child: ListTile(
                  leading: Icon(Icons.swap_horiz),
                  title: Text('Zmień status'),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'usun',
                child: ListTile(
                  leading: Icon(Icons.link_off, color: Colors.red),
                  title: Text('Usuń z budowy',
                      style: TextStyle(color: Colors.red)),
                  dense: true,
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Karta kontaktu — styl CRM contact panel
          _ContactCard(kontrahent: k),

          const SizedBox(height: 20),

          // Szczegóły powiązania z budową
          Text(
            'Na tej budowie',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: cs.primary,
                ),
          ),
          const SizedBox(height: 12),

          _InfoRow(
            icon: Icons.work_outline,
            label: 'Rola',
            value: powiazanie.rola.isNotEmpty ? powiazanie.rola : '—',
          ),
          _InfoRow(
            icon: Icons.flag_outlined,
            label: 'Status',
            value: powiazanie.status.label,
            valueColor: _statusColor(cs, powiazanie.status),
          ),
          if (powiazanie.etapNazwa != null)
            _InfoRow(
              icon: Icons.construction,
              label: 'Etap',
              value: powiazanie.etapNazwa!,
            ),
          if (powiazanie.wartoscUmowy != null)
            _InfoRow(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Wartość umowy',
              value:
                  '${powiazanie.wartoscUmowy!.toStringAsFixed(0)} PLN',
            ),
          if (powiazanie.dataOd != null || powiazanie.dataDo != null)
            _InfoRow(
              icon: Icons.date_range_outlined,
              label: 'Okres',
              value: [
                if (powiazanie.dataOd != null)
                  _fmt.format(powiazanie.dataOd!),
                if (powiazanie.dataDo != null)
                  _fmt.format(powiazanie.dataDo!),
              ].join(' – '),
            ),
          if (powiazanie.uwagi.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Uwagi',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: cs.outline,
                  ),
            ),
            const SizedBox(height: 4),
            Text(powiazanie.uwagi),
          ],

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Color _statusColor(ColorScheme cs, StatusPowiazania s) => switch (s) {
        StatusPowiazania.aktywny => cs.primary,
        StatusPowiazania.zakonczony => cs.secondary,
        StatusPowiazania.zaproszony => cs.tertiary,
        StatusPowiazania.odrzucony => cs.error,
      };

  Future<void> _zmienStatus(BuildContext context, WidgetRef ref) async {
    final newStatus = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Zmień status'),
        children: StatusPowiazania.values
            .map((s) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, s.name),
                  child: Text(s.label),
                ))
            .toList(),
      ),
    );
    if (newStatus == null) return;
    try {
      final updated =
          await podwykonawcyApi.zmienStatus(powiazanie.id, newStatus);
      ref.read(powiazaniaProvider(budowaId).notifier).update(updated);
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Błąd: $e')));
      }
    }
  }

  Future<void> _usunPowiazanie(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Usuń podwykonawcę'),
        content: Text(
            'Usuń ${powiazanie.kontrahent.displayName} z tej budowy?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Anuluj')),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await podwykonawcyApi.usunPowiazanie(powiazanie.id);
      ref.read(powiazaniaProvider(budowaId).notifier).remove(powiazanie.id);
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Błąd: $e')));
      }
    }
  }
}

// ---- Karta kontaktu (styl contact panel) --------------------------------

class _ContactCard extends StatelessWidget {
  final KontrahentModel kontrahent;
  const _ContactCard({required this.kontrahent});

  String get _initials {
    final parts = kontrahent.displayName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (kontrahent.displayName.isNotEmpty)
      return kontrahent.displayName[0].toUpperCase();
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        children: [
          // Avatar + name
          CircleAvatar(
            radius: 36,
            backgroundColor: cs.primaryContainer,
            backgroundImage: kontrahent.avatarUrl != null
                ? NetworkImage(kontrahent.avatarUrl!)
                : null,
            child: kontrahent.avatarUrl == null
                ? Text(
                    _initials,
                    style: TextStyle(
                      fontSize: 24,
                      color: cs.onPrimaryContainer,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            kontrahent.displayName,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          if (kontrahent.branza != null) ...[
            const SizedBox(height: 4),
            Text(
              '${kontrahent.branza!.emoji}  ${kontrahent.branza!.label}',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: cs.outline),
            ),
          ],
          if (kontrahent.firma.isNotEmpty &&
              kontrahent.firma != kontrahent.displayName) ...[
            const SizedBox(height: 4),
            Text(
              kontrahent.firma,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.outline),
            ),
          ],

          const SizedBox(height: 16),

          // Akcje kontaktowe
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (kontrahent.telefon.isNotEmpty)
                _ActionButton(
                  icon: Icons.phone_outlined,
                  label: kontrahent.telefon,
                ),
              if (kontrahent.email.isNotEmpty) ...[
                const SizedBox(width: 12),
                _ActionButton(
                  icon: Icons.email_outlined,
                  label: kontrahent.email,
                  compact: true,
                ),
              ],
            ],
          ),

          if (kontrahent.nip.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'NIP: ${kontrahent.nip}',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: cs.outline),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool compact;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        icon: Icon(icon, size: 16),
        label: Text(
          compact && label.length > 20
              ? '${label.substring(0, 18)}…'
              : label,
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        onPressed: () {},
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon,
                size: 18, color: Theme.of(context).colorScheme.outline),
            const SizedBox(width: 10),
            SizedBox(
              width: 100,
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: valueColor,
                    ),
              ),
            ),
          ],
        ),
      );
}
