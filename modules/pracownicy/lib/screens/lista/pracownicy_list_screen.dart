import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/pracownicy_model.dart';
import '../../data/providers/pracownicy_provider.dart';
import '../../widgets/skill_matrix.dart';
import '../profil/pracownik_profil_screen.dart';
import '../umiejetnosci/nowy_pracownik_screen.dart';

class PracownicyListScreen extends ConsumerStatefulWidget {
  final int? budowaId;
  final String budowaNazwa;

  const PracownicyListScreen({
    super.key,
    this.budowaId,
    this.budowaNazwa = 'Wszyscy',
  });

  @override
  ConsumerState<PracownicyListScreen> createState() =>
      _PracownicyListScreenState();
}

class _PracownicyListScreenState extends ConsumerState<PracownicyListScreen> {
  Specjalizacja? _filterSpec;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pracownicyProvider);
    final lista = _filterSpec == null
        ? state.lista
        : state.lista
            .where((p) => p.specjalizacje
                .any((s) => s['specjalizacja'] == _filterSpec!.value))
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Zespół'),
            if (widget.budowaId != null)
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
                ref.read(pracownicyProvider.notifier).load(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Dodaj pracownika'),
        onPressed: () async {
          final wynik = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
                builder: (_) => const NowyPracownikScreen()),
          );
          if (wynik == true) {
            ref.read(pracownicyProvider.notifier).load();
          }
        },
      ),
      body: Column(
        children: [
          // Filtr specjalizacji
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _SpecFilter(
                  label: 'Wszyscy',
                  selected: _filterSpec == null,
                  onTap: () => setState(() => _filterSpec = null),
                ),
                ...Specjalizacja.values.map(
                  (s) => _SpecFilter(
                    label: '${s.emoji} ${s.label.split('/').first}',
                    selected: _filterSpec == s,
                    onTap: () => setState(() => _filterSpec = s),
                  ),
                ),
              ],
            ),
          ),

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
                          size: 56,
                          color: Theme.of(context).colorScheme.outline),
                      const SizedBox(height: 16),
                      const Text('Brak pracowników'),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () =>
                    ref.read(pracownicyProvider.notifier).load(),
                child: ListView.separated(
                  padding:
                      const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: lista.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 8),
                  itemBuilder: (ctx, i) =>
                      _PracownikCard(pracownik: lista[i]),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _SpecFilter extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SpecFilter(
      {required this.label, required this.selected, required this.onTap});

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

class _PracownikCard extends StatelessWidget {
  final PracownikListItem pracownik;
  const _PracownikCard({required this.pracownik});

  @override
  Widget build(BuildContext context) {
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
            builder: (_) =>
                PracownikProfilScreen(pracownikId: pracownik.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: cs.primaryContainer,
                child: Text(
                  pracownik.inicjaly,
                  style: TextStyle(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(
                          pracownik.pelneImie,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      if (pracownik.aktualnaStawka != null)
                        Text(
                          '${pracownik.aktualnaStawka!.toStringAsFixed(0)} PLN/h',
                          style: TextStyle(
                            color: cs.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                    ]),

                    const SizedBox(height: 4),

                    Row(children: [
                      Text(
                        pracownik.glownaSpecjalizacja.emoji,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        pracownik.glownaSpecjalizacja.label,
                        style: TextStyle(
                            color: cs.outline, fontSize: 12),
                      ),
                    ]),

                    if (pracownik.specjalizacje.length > 1) ...[
                      const SizedBox(height: 6),
                      SkillChips(
                          specjalizacje: pracownik.specjalizacje,
                          max: 4),
                    ],

                    if (pracownik.telefon.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(children: [
                        Icon(Icons.phone_outlined,
                            size: 12, color: cs.outline),
                        const SizedBox(width: 4),
                        Text(pracownik.telefon,
                            style: TextStyle(
                                color: cs.outline, fontSize: 11)),
                      ]),
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
