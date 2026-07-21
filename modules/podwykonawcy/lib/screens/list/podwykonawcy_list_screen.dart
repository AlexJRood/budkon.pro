import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import '../../data/models/podwykonawcy_model.dart';
import '../../data/providers/podwykonawcy_provider.dart';
import '../../data/services/podwykonawcy_api.dart';
import '../../widgets/kontrahent_picker_dialog.dart';
import '../detail/kontrahent_detail_screen.dart';

class PodwykonawcyListScreen extends ConsumerStatefulWidget {
  final int budowaId;
  final String budowaNazwa;

  const PodwykonawcyListScreen({super.key, required this.budowaId, required this.budowaNazwa});

  @override
  ConsumerState<PodwykonawcyListScreen> createState() => _PodwykonawcyListScreenState();
}

class _PodwykonawcyListScreenState extends ConsumerState<PodwykonawcyListScreen> {
  String? _filterStatus;

  Future<void> _dodajPodwykonawce() async {
    final kontrahent = await KontrahentPickerDialog.show(context);
    if (kontrahent == null || !mounted) return;

    final powiazanie = await _showPowiazanieDialog(kontrahent);
    if (powiazanie == null || !mounted) return;

    try {
      final nowe = await podwykonawcyApi.dodajPowiazanie({
        'budowa_id': widget.budowaId,
        'kontrahent_id': kontrahent.id,
        ...powiazanie,
      });
      ref.read(powiazaniaProvider(widget.budowaId).notifier).add(nowe);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Błąd: $e')));
    }
  }

  Future<Map<String, dynamic>?> _showPowiazanieDialog(KontrahentModel k) async {
    final rolaCtrl = TextEditingController(text: k.branza?.label ?? '');
    String status = 'aktywny';
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text('Dodaj: ${k.displayName}'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: rolaCtrl,
                decoration: const InputDecoration(labelText: 'Rola na tej budowie', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: status,
              decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'zaproszony', child: Text('Zaproszony')),
                DropdownMenuItem(value: 'aktywny', child: Text('Aktywny')),
              ],
              onChanged: (v) => setLocal(() => status = v!),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Anuluj')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, {'rola': rolaCtrl.text.trim(), 'status': status}),
              child: const Text('Dodaj'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);
    final state = ref.watch(powiazaniaProvider(widget.budowaId));
    final lista = _filterStatus == null
        ? state.lista
        : state.lista.where((p) => p.status.name == _filterStatus).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Podwykonawcy', style: TextStyle(color: theme.textColor)),
          Text(widget.budowaNazwa, style: TextStyle(color: theme.textColor.withAlpha(160), fontSize: 11)),
        ]),
        iconTheme: IconThemeData(color: theme.textColor),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: theme.textColor),
            onPressed: () => ref.read(powiazaniaProvider(widget.budowaId).notifier).load(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: theme.themeColor,
        icon: Icon(Icons.person_add_outlined, color: theme.buttonTextColor),
        label: Text('Dodaj', style: TextStyle(color: theme.buttonTextColor)),
        onPressed: _dodajPodwykonawce,
      ),
      body: Column(children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(children: [
            _FilterChip(label: 'Wszyscy', selected: _filterStatus == null, theme: theme,
                onTap: () => setState(() => _filterStatus = null)),
            ...StatusPowiazania.values.map((s) => _FilterChip(
              label: s.label, selected: _filterStatus == s.name, theme: theme,
              onTap: () => setState(() => _filterStatus = s.name),
            )),
          ]),
        ),
        Expanded(child: Builder(builder: (_) {
          if (state.loading && lista.isEmpty) {
            return Center(child: CircularProgressIndicator(color: theme.themeColor));
          }
          if (state.error != null && lista.isEmpty) {
            return Center(child: Text(state.error!, style: TextStyle(color: theme.textColor)));
          }
          if (lista.isEmpty) {
            return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.groups_outlined, size: 64, color: theme.textColor.withAlpha(80)),
              const SizedBox(height: 16),
              Text('Brak podwykonawców', style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('Dodaj pierwszego podwykonawcę',
                  style: TextStyle(color: theme.textColor.withAlpha(150))),
            ]));
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(powiazaniaProvider(widget.budowaId).notifier).load(),
            color: theme.themeColor,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              itemCount: lista.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) => _PowiazanieCard(powiazanie: lista[i], budowaId: widget.budowaId, theme: theme),
            ),
          );
        })),
      ]),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ThemeColors theme;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.theme, required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      selectedColor: theme.themeColor.withAlpha(60),
      checkmarkColor: theme.themeColor,
      labelStyle: TextStyle(color: selected ? theme.themeColor : theme.textColor),
      side: BorderSide(color: selected ? theme.themeColor : theme.bordercolor.withAlpha(60)),
      backgroundColor: theme.userTile,
    ),
  );
}

class _PowiazanieCard extends StatelessWidget {
  final PowiazanieModel powiazanie;
  final int budowaId;
  final ThemeColors theme;

  const _PowiazanieCard({required this.powiazanie, required this.budowaId, required this.theme});

  Color _statusColor(StatusPowiazania s) => switch (s) {
    StatusPowiazania.aktywny => const Color(0xFF4CAF50),
    StatusPowiazania.zakonczony => theme.textColor.withAlpha(120),
    StatusPowiazania.zaproszony => const Color(0xFF2196F3),
    StatusPowiazania.odrzucony => Colors.red,
  };

  @override
  Widget build(BuildContext context) {
    final k = powiazanie.kontrahent;
    final statusColor = _statusColor(powiazanie.status);

    return Container(
      decoration: BoxDecoration(
        color: theme.userTile,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.bordercolor.withAlpha(60)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => KontrahentDetailScreen(powiazanie: powiazanie, budowaId: budowaId))),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            _ContactAvatar(kontrahent: k, theme: theme),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(k.displayName,
                    style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w600, fontSize: 14))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withAlpha(80)),
                  ),
                  child: Text(powiazanie.status.label,
                      style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ]),
              if (powiazanie.rola.isNotEmpty || k.branza != null) ...[
                const SizedBox(height: 4),
                Text(
                  [if (powiazanie.rola.isNotEmpty) powiazanie.rola,
                   if (k.branza != null) '${k.branza!.emoji} ${k.branza!.label}'].join('  •  '),
                  style: TextStyle(color: theme.textColor.withAlpha(140), fontSize: 12),
                ),
              ],
              if (k.telefon.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.phone_outlined, size: 13, color: theme.textColor.withAlpha(120)),
                  const SizedBox(width: 4),
                  Text(k.telefon, style: TextStyle(color: theme.textColor, fontSize: 12)),
                ]),
              ],
              if (powiazanie.etapNazwa != null) ...[
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.construction, size: 13, color: theme.textColor.withAlpha(120)),
                  const SizedBox(width: 4),
                  Text(powiazanie.etapNazwa!, style: TextStyle(color: theme.textColor, fontSize: 12)),
                ]),
              ],
            ])),
            Icon(Icons.chevron_right, color: theme.textColor.withAlpha(120)),
          ]),
        ),
      ),
    );
  }
}

class _ContactAvatar extends StatelessWidget {
  final KontrahentModel kontrahent;
  final ThemeColors theme;
  const _ContactAvatar({required this.kontrahent, required this.theme});

  String get _initials {
    final n = kontrahent.displayName;
    final parts = n.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (n.isNotEmpty) return n[0].toUpperCase();
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    if (kontrahent.avatarUrl != null) {
      return CircleAvatar(backgroundImage: NetworkImage(kontrahent.avatarUrl!));
    }
    return CircleAvatar(
      backgroundColor: theme.themeColor.withAlpha(60),
      child: Text(_initials, style: TextStyle(color: theme.themeColor, fontWeight: FontWeight.w700)),
    );
  }
}
