import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:intl/intl.dart';
import '../../data/models/podwykonawcy_model.dart';
import '../../data/providers/podwykonawcy_provider.dart';
import '../../data/services/podwykonawcy_api.dart';

class KontrahentDetailScreen extends ConsumerWidget {
  final PowiazanieModel powiazanie;
  final int budowaId;

  const KontrahentDetailScreen({super.key, required this.powiazanie, required this.budowaId});

  static final _fmt = DateFormat('dd.MM.yyyy');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sideMenuKey = GlobalKey<SideMenuState>();
    final theme = ref.read(themeColorsProvider);
    final k = powiazanie.kontrahent;

    return BarManager(
      sideMenuKey: sideMenuKey,
      appModule: AppModule.budkon,
      verticalButtonsPc: PopupMenuButton<String>(
          iconColor: theme.textColor,
          onSelected: (v) async {
            if (v == 'status') await _zmienStatus(context, ref);
            else if (v == 'usun') await _usunPowiazanie(context, ref);
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'status',
                child: ListTile(leading: Icon(Icons.swap_horiz), title: Text('Zmień status'), dense: true)),
            const PopupMenuItem(value: 'usun',
                child: ListTile(leading: Icon(Icons.link_off, color: Colors.red),
                    title: Text('Usuń z budowy', style: TextStyle(color: Colors.red)), dense: true)),
          ],
        ),
      childPc: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ContactCard(kontrahent: k, theme: theme),

          const SizedBox(height: 20),

          Text('Na tej budowie',
              style: TextStyle(color: theme.themeColor, fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),

          _InfoRow(icon: Icons.work_outline, label: 'Rola',
              value: powiazanie.rola.isNotEmpty ? powiazanie.rola : '—', theme: theme),
          _InfoRow(icon: Icons.flag_outlined, label: 'Status',
              value: powiazanie.status.label, theme: theme,
              valueColor: _statusColor(theme, powiazanie.status)),
          if (powiazanie.etapNazwa != null)
            _InfoRow(icon: Icons.construction, label: 'Etap', value: powiazanie.etapNazwa!, theme: theme),
          if (powiazanie.wartoscUmowy != null)
            _InfoRow(icon: Icons.account_balance_wallet_outlined, label: 'Wartość umowy',
                value: '${powiazanie.wartoscUmowy!.toStringAsFixed(0)} PLN', theme: theme),
          if (powiazanie.dataOd != null || powiazanie.dataDo != null)
            _InfoRow(icon: Icons.date_range_outlined, label: 'Okres',
                value: [
                  if (powiazanie.dataOd != null) _fmt.format(powiazanie.dataOd!),
                  if (powiazanie.dataDo != null) _fmt.format(powiazanie.dataDo!),
                ].join(' – '), theme: theme),
          if (powiazanie.uwagi.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Uwagi', style: TextStyle(color: theme.textColor.withAlpha(140), fontSize: 12)),
            const SizedBox(height: 4),
            Text(powiazanie.uwagi, style: TextStyle(color: theme.textColor)),
          ],

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Color _statusColor(ThemeColors theme, StatusPowiazania s) => switch (s) {
    StatusPowiazania.aktywny => const Color(0xFF4CAF50),
    StatusPowiazania.zakonczony => theme.textColor.withAlpha(120),
    StatusPowiazania.zaproszony => const Color(0xFF2196F3),
    StatusPowiazania.odrzucony => Colors.red,
  };

  Future<void> _zmienStatus(BuildContext context, WidgetRef ref) async {
    final newStatus = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Zmień status'),
        children: StatusPowiazania.values.map((s) =>
          SimpleDialogOption(onPressed: () => Navigator.pop(context, s.name), child: Text(s.label))).toList(),
      ),
    );
    if (newStatus == null) return;
    try {
      final updated = await podwykonawcyApi.zmienStatus(powiazanie.id, newStatus);
      ref.read(powiazaniaProvider(budowaId).notifier).update(updated);
      if (context.mounted) ref.read(navigationService).beamPop();
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Błąd: $e')));
    }
  }

  Future<void> _usunPowiazanie(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Usuń podwykonawcę'),
        content: Text('Usuń ${powiazanie.kontrahent.displayName} z tej budowy?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Anuluj')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
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
      if (context.mounted) ref.read(navigationService).beamPop();
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Błąd: $e')));
    }
  }
}

class _ContactCard extends StatelessWidget {
  final KontrahentModel kontrahent;
  final ThemeColors theme;
  const _ContactCard({required this.kontrahent, required this.theme});

  String get _initials {
    final parts = kontrahent.displayName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (kontrahent.displayName.isNotEmpty) return kontrahent.displayName[0].toUpperCase();
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.secondaryWidgetColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.bordercolor.withAlpha(60)),
      ),
      child: Column(children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: theme.themeColor.withAlpha(60),
          backgroundImage: kontrahent.avatarUrl != null ? NetworkImage(kontrahent.avatarUrl!) : null,
          child: kontrahent.avatarUrl == null
              ? Text(_initials, style: TextStyle(fontSize: 24, color: theme.themeColor, fontWeight: FontWeight.w700))
              : null,
        ),
        const SizedBox(height: 12),
        Text(kontrahent.displayName,
            style: TextStyle(color: theme.textColor, fontSize: 18, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center),
        if (kontrahent.branza != null) ...[
          const SizedBox(height: 4),
          Text('${kontrahent.branza!.emoji}  ${kontrahent.branza!.label}',
              style: TextStyle(color: theme.textColor.withAlpha(150))),
        ],
        if (kontrahent.firma.isNotEmpty && kontrahent.firma != kontrahent.displayName) ...[
          const SizedBox(height: 4),
          Text(kontrahent.firma, style: TextStyle(color: theme.textColor.withAlpha(150), fontSize: 12)),
        ],
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (kontrahent.telefon.isNotEmpty)
            _ActionButton(icon: Icons.phone_outlined, label: kontrahent.telefon, theme: theme),
          if (kontrahent.email.isNotEmpty) ...[
            const SizedBox(width: 12),
            _ActionButton(icon: Icons.email_outlined, label: kontrahent.email, compact: true, theme: theme),
          ],
        ]),
        if (kontrahent.nip.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('NIP: ${kontrahent.nip}',
              style: TextStyle(color: theme.textColor.withAlpha(120), fontSize: 11)),
        ],
      ]),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final ThemeColors theme;
  final bool compact;

  const _ActionButton({required this.icon, required this.label, required this.theme, this.compact = false});

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    icon: Icon(icon, size: 16, color: theme.themeColor),
    label: Text(
      compact && label.length > 20 ? '${label.substring(0, 18)}…' : label,
      style: TextStyle(color: theme.textColor),
    ),
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      side: BorderSide(color: theme.bordercolor.withAlpha(80)),
    ),
    onPressed: () {},
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ThemeColors theme;
  final Color? valueColor;

  const _InfoRow({required this.icon, required this.label, required this.value, required this.theme, this.valueColor});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Icon(icon, size: 18, color: theme.textColor.withAlpha(120)),
      const SizedBox(width: 10),
      SizedBox(width: 100, child: Text(label,
          style: TextStyle(color: theme.textColor.withAlpha(140), fontSize: 12))),
      Expanded(child: Text(value,
          style: TextStyle(color: valueColor ?? theme.textColor, fontWeight: FontWeight.w500))),
    ]),
  );
}
