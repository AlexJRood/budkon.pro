import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/podwykonawcy_model.dart';
import '../../data/providers/podwykonawcy_provider.dart';
import '../../data/services/podwykonawcy_api.dart';
import '../../widgets/kontrahent_picker_dialog.dart';
import '../detail/kontrahent_detail_screen.dart';

class PodwykonawcyListScreen extends ConsumerStatefulWidget {
  final int budowaId;
  final String budowaNazwa;

  const PodwykonawcyListScreen({
    super.key,
    required this.budowaId,
    required this.budowaNazwa,
  });

  @override
  ConsumerState<PodwykonawcyListScreen> createState() =>
      _PodwykonawcyListScreenState();
}

class _PodwykonawcyListScreenState
    extends ConsumerState<PodwykonawcyListScreen> {
  String? _filterStatus;

  Future<void> _dodajPodwykonawce() async {
    final kontrahent = await KontrahentPickerDialog.show(context);
    if (kontrahent == null || !mounted) return;

    // Dialog z rolą i statusem powiązania
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd: $e')),
        );
      }
    }
  }

  Future<Map<String, dynamic>?> _showPowiazanieDialog(
      KontrahentModel k) async {
    final rolaCtrl = TextEditingController(
        text: k.branza?.label ?? '');
    String status = 'aktywny';

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text('Dodaj: ${k.displayName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: rolaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Rola na tej budowie',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'zaproszony', child: Text('Zaproszony')),
                  DropdownMenuItem(value: 'aktywny', child: Text('Aktywny')),
                ],
                onChanged: (v) => setLocal(() => status = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Anuluj')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, {
                'rola': rolaCtrl.text.trim(),
                'status': status,
              }),
              child: const Text('Dodaj'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(powiazaniaProvider(widget.budowaId));

    final lista = _filterStatus == null
        ? state.lista
        : state.lista
            .where((p) => p.status.name == _filterStatus)
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Podwykonawcy'),
            Text(
              widget.budowaNazwa,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(powiazaniaProvider(widget.budowaId).notifier).load(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Dodaj'),
        onPressed: _dodajPodwykonawce,
      ),
      body: Column(
        children: [
          // Filtr statusu
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Wszyscy',
                  selected: _filterStatus == null,
                  onTap: () => setState(() => _filterStatus = null),
                ),
                ...StatusPowiazania.values.map((s) => _FilterChip(
                      label: s.label,
                      selected: _filterStatus == s.name,
                      onTap: () =>
                          setState(() => _filterStatus = s.name),
                    )),
              ],
            ),
          ),

          // Lista
          Expanded(
            child: Builder(builder: (_) {
              if (state.loading && lista.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.error != null && lista.isEmpty) {
                return Center(child: Text(state.error!));
              }
              if (lista.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.groups_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline),
                      const SizedBox(height: 16),
                      const Text('Brak podwykonawców'),
                      const SizedBox(height: 8),
                      const Text('Dodaj pierwszego podwykonawcę'),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => ref
                    .read(powiazaniaProvider(widget.budowaId).notifier)
                    .load(),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: lista.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) => _PowiazanieCard(
                    powiazanie: lista[i],
                    budowaId: widget.budowaId,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilterChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap(),
          showCheckmark: false,
        ),
      );
}

class _PowiazanieCard extends ConsumerWidget {
  final PowiazanieModel powiazanie;
  final int budowaId;

  const _PowiazanieCard({
    required this.powiazanie,
    required this.budowaId,
  });

  Color _statusColor(BuildContext ctx, StatusPowiazania s) {
    final cs = Theme.of(ctx).colorScheme;
    return switch (s) {
      StatusPowiazania.aktywny => cs.primaryContainer,
      StatusPowiazania.zakonczony => cs.secondaryContainer,
      StatusPowiazania.zaproszony => cs.tertiaryContainer,
      StatusPowiazania.odrzucony => cs.errorContainer,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final k = powiazanie.kontrahent;
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => KontrahentDetailScreen(
              powiazanie: powiazanie,
              budowaId: budowaId,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Avatar
              _ContactAvatar(kontrahent: k),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            k.displayName,
                            style:
                                Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _statusColor(
                                context, powiazanie.status),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            powiazanie.status.label,
                            style:
                                Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                      ],
                    ),
                    if (powiazanie.rola.isNotEmpty ||
                        k.branza != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        [
                          if (powiazanie.rola.isNotEmpty)
                            powiazanie.rola,
                          if (k.branza != null)
                            '${k.branza!.emoji} ${k.branza!.label}',
                        ].join('  •  '),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: cs.outline),
                      ),
                    ],
                    if (k.telefon.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.phone_outlined,
                              size: 13, color: cs.outline),
                          const SizedBox(width: 4),
                          Text(k.telefon,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall),
                        ],
                      ),
                    ],
                    if (powiazanie.etapNazwa != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.construction,
                              size: 13, color: cs.outline),
                          const SizedBox(width: 4),
                          Text(powiazanie.etapNazwa!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              Icon(Icons.chevron_right, color: cs.outline),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactAvatar extends StatelessWidget {
  final KontrahentModel kontrahent;
  const _ContactAvatar({required this.kontrahent});

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
      return CircleAvatar(
          backgroundImage: NetworkImage(kontrahent.avatarUrl!));
    }
    return CircleAvatar(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      child: Text(
        _initials,
        style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimaryContainer),
      ),
    );
  }
}
