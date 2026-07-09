import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/materialy_model.dart';
import '../../data/providers/materialy_provider.dart';
import '../../data/services/materialy_api.dart';
import '../../widgets/sparkline.dart';
import '../historia_cen/historia_cen_screen.dart';

class MaterialyListScreen extends ConsumerStatefulWidget {
  final int budowaId;
  final String budowaNazwa;

  const MaterialyListScreen({
    super.key,
    required this.budowaId,
    required this.budowaNazwa,
  });

  @override
  ConsumerState<MaterialyListScreen> createState() =>
      _MaterialyListScreenState();
}

class _MaterialyListScreenState extends ConsumerState<MaterialyListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  String? _filterStatus;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pozycjeProvider(widget.budowaId));
    final cs = Theme.of(context).colorScheme;

    // Grupowanie po statusie
    final doZamowienia = state.lista
        .where((p) => p.status == StatusPozycji.doZamowienia)
        .toList();
    final wTrakcie = state.lista
        .where((p) =>
            p.status == StatusPozycji.zamowione ||
            p.status == StatusPozycji.wDostawie)
        .toList();
    final dostarczone = state.lista
        .where((p) => p.status == StatusPozycji.dostarczone)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Materiały'),
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
            icon: const Icon(Icons.trending_up),
            tooltip: 'Trendy cen',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const TrendyCenScreen(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(pozycjeProvider(widget.budowaId).notifier).load(),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: 'Do zamówienia (${doZamowienia.length})'),
            Tab(text: 'W trakcie (${wTrakcie.length})'),
            Tab(text: 'Dostarczone'),
          ],
        ),
      ),

      body: state.loading && state.lista.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabs,
              children: [
                _ListaTab(
                  pozycje: doZamowienia,
                  budowaId: widget.budowaId,
                  emptyLabel: 'Brak materiałów do zamówienia',
                  emptyIcon: Icons.check_circle_outline,
                ),
                _ListaTab(
                  pozycje: wTrakcie,
                  budowaId: widget.budowaId,
                  emptyLabel: 'Brak zamówionych materiałów',
                  emptyIcon: Icons.local_shipping_outlined,
                ),
                _ListaTab(
                  pozycje: dostarczone,
                  budowaId: widget.budowaId,
                  emptyLabel: 'Brak dostarczonych materiałów',
                  emptyIcon: Icons.inventory_2_outlined,
                ),
              ],
            ),

      floatingActionButton: _tabs.index == 0
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: const Text('Dodaj'),
              onPressed: () => _dodajPozycje(context),
            )
          : null,
    );
  }

  Future<void> _dodajPozycje(BuildContext context) async {
    // Uproszczona wersja — szukanie materiału w katalogu
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _DodajPozycjeSheet(budowaId: widget.budowaId),
    );
    if (mounted) {
      ref.read(pozycjeProvider(widget.budowaId).notifier).load();
    }
  }
}

// ---- Tab z listą pozycji ---------------------------------------------------

class _ListaTab extends ConsumerWidget {
  final List<PozycjaZamowieniaModel> pozycje;
  final int budowaId;
  final String emptyLabel;
  final IconData emptyIcon;

  const _ListaTab({
    required this.pozycje,
    required this.budowaId,
    required this.emptyLabel,
    required this.emptyIcon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (pozycje.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(emptyIcon,
                size: 56, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text(emptyLabel,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    )),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(pozycjeProvider(budowaId).notifier).load(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: pozycje.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) =>
            _PozycjaCard(pozycja: pozycje[i], budowaId: budowaId),
      ),
    );
  }
}

// ---- Karta pojedynczej pozycji zamówienia ----------------------------------

class _PozycjaCard extends ConsumerWidget {
  final PozycjaZamowieniaModel pozycja;
  final int budowaId;

  const _PozycjaCard({required this.pozycja, required this.budowaId});

  Color _statusColor(BuildContext ctx, StatusPozycji s) {
    final cs = Theme.of(ctx).colorScheme;
    return switch (s) {
      StatusPozycji.doZamowienia => cs.primary,
      StatusPozycji.zamowione => cs.tertiary,
      StatusPozycji.wDostawie => const Color(0xFFFF9800),
      StatusPozycji.dostarczone => const Color(0xFF4CAF50),
      StatusPozycji.zwrocone => cs.error,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mat = pozycja.material;
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _szczegoly(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                // Emoji kategorii
                Text(mat.kategoria.emoji,
                    style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mat.nazwa,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      if (mat.producent.isNotEmpty)
                        Text(
                          mat.producent,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: cs.outline),
                        ),
                    ],
                  ),
                ),

                // Sparkline trendu
                if (mat.trend != null)
                  PriceSparkline(
                    ceny: const [], // mini — bez historii na liście
                    trend: mat.trend,
                    width: 0,
                    height: 0,
                  ),

                TrendBadge(trend: mat.trend, showPorada: true),
              ]),

              const SizedBox(height: 10),

              Row(children: [
                // Ilość
                _InfoChip(
                  icon: Icons.inventory_2_outlined,
                  label: pozycja.iloscStr,
                ),
                const SizedBox(width: 8),

                // Cena
                if (mat.cenaNetto != null)
                  _InfoChip(
                    icon: Icons.payments_outlined,
                    label: '${mat.cenaFormatted}/${mat.jednostka}',
                  ),

                const Spacer(),

                // Wartość
                if (pozycja.wartoscNetto != null)
                  Text(
                    '${pozycja.wartoscNetto!.toStringAsFixed(0)} PLN',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
              ]),

              if (pozycja.dataPotrzeby != null) ...[
                const SizedBox(height: 6),
                Row(children: [
                  Icon(Icons.event, size: 13, color: cs.outline),
                  const SizedBox(width: 4),
                  Text(
                    'Potrzebne: ${pozycja.dataPotrzeby}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: cs.outline),
                  ),
                ]),
              ],

              const SizedBox(height: 10),

              // Status + akcje
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        _statusColor(context, pozycja.status).withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          _statusColor(context, pozycja.status).withAlpha(80),
                    ),
                  ),
                  child: Text(
                    pozycja.status.label,
                    style: TextStyle(
                      color: _statusColor(context, pozycja.status),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.show_chart, size: 16),
                  label: const Text('Historia cen'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          HistoriaCenScreen(material: mat),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _szczegoly(BuildContext context, WidgetRef ref) async {
    final nowyStatus = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => _StatusSheet(pozycja: pozycja),
    );
    if (nowyStatus == null) return;
    try {
      final updated = await materialyApi.zmienStatus(pozycja.id, nowyStatus);
      ref.read(pozycjeProvider(budowaId).notifier).update(updated);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Błąd: $e')));
      }
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 13, color: Theme.of(context).colorScheme.outline),
          const SizedBox(width: 4),
          Text(label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  )),
        ],
      );
}

// ---- Bottom sheet zmiany statusu -------------------------------------------

class _StatusSheet extends StatelessWidget {
  final PozycjaZamowieniaModel pozycja;
  const _StatusSheet({required this.pozycja});

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pozycja.material.nazwa,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              ...StatusPozycji.values.map(
                (s) => ListTile(
                  title: Text(s.label),
                  selected: s == pozycja.status,
                  selectedColor: Theme.of(context).colorScheme.primary,
                  leading: Radio<StatusPozycji>(
                    value: s,
                    groupValue: pozycja.status,
                    onChanged: (_) => Navigator.pop(context, s.value),
                  ),
                  onTap: () => Navigator.pop(context, s.value),
                ),
              ),
            ],
          ),
        ),
      );
}

// ---- Bottom sheet dodawania pozycji ----------------------------------------

class _DodajPozycjeSheet extends ConsumerStatefulWidget {
  final int budowaId;
  const _DodajPozycjeSheet({required this.budowaId});

  @override
  ConsumerState<_DodajPozycjeSheet> createState() =>
      _DodajPozycjeSheetState();
}

class _DodajPozycjeSheetState extends ConsumerState<_DodajPozycjeSheet> {
  final _searchCtrl = TextEditingController();
  MaterialModel? _selected;
  final _iloscCtrl = TextEditingController(text: '1');
  bool _saving = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _iloscCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wyniki = ref.watch(materialPickerProvider);
    final cs = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, ctrl) => Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: cs.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Dodaj materiał',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Szukaj w katalogu...',
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
              onChanged: (v) => ref
                  .read(materialPickerProvider.notifier)
                  .szukaj(v),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: wyniki.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Błąd: $e')),
              data: (lista) => ListView.builder(
                controller: ctrl,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: lista.length,
                itemBuilder: (_, i) {
                  final m = lista[i];
                  return ListTile(
                    leading: Text(m.kategoria.emoji,
                        style: const TextStyle(fontSize: 20)),
                    title: Text(m.nazwa),
                    subtitle: Text(
                        '${m.cenaFormatted}/${m.jednostka}${m.producent.isNotEmpty ? '  •  ${m.producent}' : ''}'),
                    trailing: TrendBadge(trend: m.trend, showPorada: true),
                    selected: _selected?.id == m.id,
                    selectedTileColor:
                        cs.primaryContainer.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    onTap: () => setState(() => _selected = m),
                  );
                },
              ),
            ),
          ),
          if (_selected != null) ...[
            const Divider(),
            Padding(
              padding: EdgeInsets.fromLTRB(
                16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 16),
              child: Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selected!.nazwa,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        _selected!.cenaFormatted,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: cs.outline),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _iloscCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: _selected!.jednostka,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _saving ? null : _dodaj,
                  child: _saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Dodaj'),
                ),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _dodaj() async {
    final m = _selected;
    if (m == null) return;
    final ilosc = double.tryParse(_iloscCtrl.text.replaceAll(',', '.')) ?? 1;
    setState(() => _saving = true);
    try {
      await materialyApi.listaPozycji(); // dummy — replace with create endpoint
      // TODO: wywołać POST /zamowienia-pozycje/ z material_id, budowa_id, ilosc
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Błąd: $e')));
      }
    }
  }
}

// ---- Ekran trendów ---------------------------------------------------------

class TrendyCenScreen extends ConsumerWidget {
  const TrendyCenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(trendyProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Trendy cen materiałów')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Błąd: $e')),
        data: (trendy) {
          if (trendy.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.trending_flat,
                      size: 56, color: cs.outline),
                  const SizedBox(height: 16),
                  const Text('Brak danych o trendach'),
                  const SizedBox(height: 8),
                  Text(
                    'Dodaj historię cen dla materiałów',
                    style: TextStyle(color: cs.outline),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: trendy.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              final t = trendy[i];
              final trend =
                  TrendCeny.fromValue(t['trend']?.toString());
              final cenySkrot = (t['historia_skrot'] as List? ?? [])
                  .map((c) => (c as num).toDouble())
                  .toList();
              final zmianaProc =
                  (t['zmiana_procent'] as num?)?.toDouble();
              final cenaNetto =
                  (t['cena_netto'] as num?)?.toDouble();

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: cs.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (t['nazwa'] ?? '').toString(),
                            style:
                                Theme.of(context).textTheme.titleSmall,
                          ),
                          if (cenaNetto != null)
                            Text(
                              '${cenaNetto.toStringAsFixed(2)} PLN',
                              style: TextStyle(
                                  color: cs.outline, fontSize: 12),
                            ),
                          const SizedBox(height: 4),
                          if (trend == TrendCeny.rosnacy)
                            Text(
                              trend.porada,
                              style: const TextStyle(
                                color: Color(0xFFEF5350),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          else if (trend == TrendCeny.spadajacy)
                            Text(
                              trend.porada,
                              style: const TextStyle(
                                color: Color(0xFF66BB6A),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    PriceSparkline(
                      ceny: cenySkrot,
                      trend: trend,
                      width: 80,
                      height: 36,
                    ),
                    const SizedBox(width: 10),
                    TrendBadge(
                      trend: trend,
                      zmianaProc: zmianaProc,
                      showPorada: false,
                    ),
                  ]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
