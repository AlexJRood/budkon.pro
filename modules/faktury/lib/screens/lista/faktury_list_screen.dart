import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/faktury_model.dart';
import '../../data/providers/faktury_provider.dart';
import '../detail/faktura_detail_screen.dart';
import '../form/faktura_form_screen.dart';

class FakturyListScreen extends ConsumerStatefulWidget {
  final int? budowaId;
  const FakturyListScreen({super.key, this.budowaId});

  @override
  ConsumerState<FakturyListScreen> createState() => _FakturyListScreenState();
}

class _FakturyListScreenState extends ConsumerState<FakturyListScreen> {
  static final _dateFmt = DateFormat('dd.MM.yyyy', 'pl_PL');
  StatusFaktury? _filterStatus;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(fakturyProvider);
    final lista = _filterStatus == null
        ? state.lista
        : state.lista.where((f) => f.status == _filterStatus).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Faktury')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Nowa faktura'),
        onPressed: () async {
          final wynik = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
                builder: (_) => FakturaFormScreen(budowaId: widget.budowaId)),
          );
          if (wynik == true) ref.read(fakturyProvider.notifier).load();
        },
      ),
      body: Column(
        children: [
          // Filtr statusów
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              children: [
                _StatusChip(
                  label: 'Wszystkie',
                  color: Colors.grey,
                  selected: _filterStatus == null,
                  onTap: () => setState(() => _filterStatus = null),
                ),
                ...StatusFaktury.values.map((s) => _StatusChip(
                      label: s.label,
                      color: s.color,
                      selected: _filterStatus == s,
                      onTap: () => setState(() => _filterStatus = s),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 4),

          Expanded(
            child: Builder(builder: (_) {
              if (state.loading && lista.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (lista.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_long_outlined,
                          size: 56,
                          color: Theme.of(context).colorScheme.outline),
                      const SizedBox(height: 12),
                      const Text('Brak faktur'),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () =>
                    ref.read(fakturyProvider.notifier).load(budowaId: widget.budowaId),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: lista.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (ctx, i) =>
                      _FakturaTile(faktura: lista[i], dateFmt: _dateFmt),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _StatusChip(
      {required this.label,
      required this.color,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilterChip(
          label: Text(label, style: const TextStyle(fontSize: 12)),
          selected: selected,
          selectedColor: color.withAlpha(40),
          checkmarkColor: color,
          onSelected: (_) => onTap(),
          showCheckmark: selected,
          side: BorderSide(color: selected ? color : Colors.transparent),
        ),
      );
}

class _FakturaTile extends StatelessWidget {
  final FakturaListItem faktura;
  final DateFormat dateFmt;
  const _FakturaTile({required this.faktura, required this.dateFmt});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final statusColor = faktura.jestPrzeterminowana
        ? const Color(0xFFEF5350)
        : faktura.status.color;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: faktura.jestPrzeterminowana
              ? const Color(0xFFEF5350).withAlpha(120)
              : cs.outlineVariant,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => FakturaDetailScreen(fakturaId: faktura.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Status dot
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                    shape: BoxShape.circle, color: statusColor),
              ),
              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(
                        faktura.numerDisplay,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          faktura.jestPrzeterminowana
                              ? 'PRZETERMINOWANA'
                              : faktura.status.label.toUpperCase(),
                          style: TextStyle(
                              color: statusColor,
                              fontSize: 9,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 3),
                    Text(faktura.nabywcaNazwa,
                        style: TextStyle(color: cs.outline, fontSize: 12)),
                    const SizedBox(height: 3),
                    Row(children: [
                      Text(
                        'Termin: ${dateFmt.format(faktura.terminPlatnosci)}',
                        style: TextStyle(
                          color: faktura.jestPrzeterminowana
                              ? const Color(0xFFEF5350)
                              : cs.outline,
                          fontSize: 11,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${faktura.wartoscBrutto.toStringAsFixed(2)} zł',
                        style: TextStyle(
                          color: cs.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right, color: cs.outline),
            ],
          ),
        ),
      ),
    );
  }
}
