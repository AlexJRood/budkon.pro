import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/kontakty_model.dart';
import '../../data/providers/kontakty_provider.dart';
import '../form/kontrahent_form_screen.dart';
import '../profil/kontrahent_profil_screen.dart';

class KontaktyListScreen extends ConsumerStatefulWidget {
  const KontaktyListScreen({super.key});

  @override
  ConsumerState<KontaktyListScreen> createState() => _KontaktyListScreenState();
}

class _KontaktyListScreenState extends ConsumerState<KontaktyListScreen> {
  final _searchCtrl = TextEditingController();
  Branza? _filterBranza;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(kontaktyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kontakty'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Szukaj firmy, nazwiska, NIP…',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          ref.read(kontaktyProvider.notifier).load();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (v) {
                setState(() {});
                ref.read(kontaktyProvider.notifier).load(
                      q: v,
                      branza: _filterBranza?.name,
                    );
              },
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Nowy kontakt'),
        onPressed: () async {
          final wynik = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const KontrahentFormScreen()),
          );
          if (wynik == true) ref.read(kontaktyProvider.notifier).load();
        },
      ),
      body: Column(
        children: [
          // Filtr branży
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              children: [
                _BranzaChip(
                  label: 'Wszyscy',
                  selected: _filterBranza == null,
                  onTap: () {
                    setState(() => _filterBranza = null);
                    ref.read(kontaktyProvider.notifier).load(q: _searchCtrl.text);
                  },
                ),
                ...Branza.values.map((b) => _BranzaChip(
                      label: '${b.emoji} ${b.label}',
                      selected: _filterBranza == b,
                      onTap: () {
                        setState(() => _filterBranza = b);
                        ref.read(kontaktyProvider.notifier).load(
                              q: _searchCtrl.text,
                              branza: b.name,
                            );
                      },
                    )),
              ],
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: Builder(builder: (_) {
              if (state.loading && state.lista.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.error != null && state.lista.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(state.error!),
                      TextButton(
                        onPressed: () => ref.read(kontaktyProvider.notifier).load(),
                        child: const Text('Spróbuj ponownie'),
                      ),
                    ],
                  ),
                );
              }
              if (state.lista.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.contacts_outlined,
                          size: 56, color: Theme.of(context).colorScheme.outline),
                      const SizedBox(height: 12),
                      const Text('Brak kontaktów'),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => ref.read(kontaktyProvider.notifier).load(
                      q: _searchCtrl.text,
                      branza: _filterBranza?.name,
                    ),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: state.lista.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (ctx, i) =>
                      _KontrahentTile(kontrahent: state.lista[i]),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _BranzaChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _BranzaChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilterChip(
          label: Text(label, style: const TextStyle(fontSize: 12)),
          selected: selected,
          onSelected: (_) => onTap(),
          showCheckmark: false,
          padding: const EdgeInsets.symmetric(horizontal: 4),
        ),
      );
}

class _KontrahentTile extends StatelessWidget {
  final KontrahentListItem kontrahent;
  const _KontrahentTile({required this.kontrahent});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final branza = kontrahent.branza;

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
                  KontrahentProfilScreen(kontrahentId: kontrahent.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: cs.secondaryContainer,
                child: Text(
                  kontrahent.inicjaly,
                  style: TextStyle(
                      color: cs.onSecondaryContainer,
                      fontWeight: FontWeight.w700,
                      fontSize: 13),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kontrahent.displayName,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (kontrahent.pelneImie.isNotEmpty &&
                        kontrahent.firma.isNotEmpty)
                      Text(kontrahent.pelneImie,
                          style:
                              TextStyle(color: cs.outline, fontSize: 12)),
                    if (branza != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          '${branza.emoji} ${branza.label}',
                          style: TextStyle(color: cs.outline, fontSize: 11),
                        ),
                      ),
                    if (kontrahent.telefon.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(children: [
                          Icon(Icons.phone_outlined,
                              size: 11, color: cs.outline),
                          const SizedBox(width: 4),
                          Text(kontrahent.telefon,
                              style:
                                  TextStyle(color: cs.outline, fontSize: 11)),
                        ]),
                      ),
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
