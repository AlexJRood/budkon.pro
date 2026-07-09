import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/materialy_model.dart';
import '../../data/providers/materialy_provider.dart';
import '../../data/services/materialy_api.dart';
import '../../widgets/sparkline.dart';

class HistoriaCenScreen extends ConsumerWidget {
  final MaterialModel material;

  const HistoriaCenScreen({super.key, required this.material});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(historiaCenProvider(material.id));
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(material.nazwa),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Dodaj cenę',
            onPressed: () => _dodajCene(context, ref),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Błąd: $e')),
        data: (historia) {
          if (historia.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.show_chart, size: 56, color: cs.outline),
                  const SizedBox(height: 16),
                  const Text('Brak historii cen'),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Dodaj pierwszą cenę'),
                    onPressed: () => _dodajCene(context, ref),
                  ),
                ],
              ),
            );
          }

          final ceny = historia.map((h) => h.cenaNetto).toList();
          final minC = ceny.reduce(min);
          final maxC = ceny.reduce(max);
          final ostatnia = historia.last;
          final zmiana = historia.length >= 2
              ? ostatnia.cenaNetto - historia.first.cenaNetto
              : 0.0;
          final zmianaProc = historia.length >= 2 && historia.first.cenaNetto > 0
              ? zmiana / historia.first.cenaNetto * 100
              : 0.0;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Duży wykres
              _BigChart(
                historia: historia,
                trend: material.trend,
                ceny: ceny,
              ),

              const SizedBox(height: 20),

              // Statystyki
              Row(children: [
                _StatCard(
                  label: 'Aktualna',
                  value: '${ostatnia.cenaNetto.toStringAsFixed(2)} PLN',
                  sub: material.jednostka,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  label: 'Min',
                  value: '${minC.toStringAsFixed(2)} PLN',
                  valueColor: const Color(0xFF66BB6A),
                ),
                const SizedBox(width: 12),
                _StatCard(
                  label: 'Max',
                  value: '${maxC.toStringAsFixed(2)} PLN',
                  valueColor: const Color(0xFFEF5350),
                ),
              ]),

              const SizedBox(height: 12),

              // Trend summary
              if (historia.length >= 2)
                _TrendSummaryCard(
                  trend: material.trend,
                  zmiana: zmiana.toDouble(),
                  zmianaProc: zmianaProc.toDouble(),
                  odData: historia.first.data,
                  doData: historia.last.data,
                ),

              const SizedBox(height: 24),

              Text(
                'Historia wpisów',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),

              // Lista wpisów — odwrócona (najnowsze na górze)
              ...historia.reversed.map((h) => _HistoriaRow(wpis: h)),
            ],
          );
        },
      ),
    );
  }

  Future<void> _dodajCene(BuildContext context, WidgetRef ref) async {
    final cena = await showDialog<double>(
      context: context,
      builder: (_) => _DodajCeneDialog(material: material),
    );
    if (cena == null) return;

    try {
      await materialyApi.dodajCene(material.id, cenaNetto: cena);
      ref.invalidate(historiaCenProvider(material.id));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Błąd: $e')));
      }
    }
  }
}

// ---- Duży wykres CustomPainter ----------------------------------------

class _BigChart extends StatelessWidget {
  final List<HistoriaCenyModel> historia;
  final TrendCeny? trend;
  final List<double> ceny;

  const _BigChart({
    required this.historia,
    required this.trend,
    required this.ceny,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            TrendBadge(trend: trend, showPorada: true),
            const Spacer(),
            if (historia.isNotEmpty)
              Text(
                '${historia.first.data} – ${historia.last.data}',
                style: TextStyle(color: cs.outline, fontSize: 11),
              ),
          ]),
          const SizedBox(height: 8),
          Expanded(
            child: PriceSparkline(
              ceny: ceny,
              trend: trend,
              width: double.infinity,
              height: 120,
              showDots: historia.length <= 10,
            ),
          ),
          // Etykiety min/max
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                historia.first.data,
                style: TextStyle(color: cs.outline, fontSize: 10),
              ),
              Text(
                historia.last.data,
                style: TextStyle(color: cs.outline, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---- Karta statystyki -------------------------------------------------------

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? sub;
  final Color? valueColor;

  const _StatCard({
    required this.label,
    required this.value,
    this.sub,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(color: cs.outline, fontSize: 11)),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: valueColor ?? cs.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (sub != null)
              Text(sub!,
                  style: TextStyle(color: cs.outline, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

// ---- Karta podsumowania trendu ---------------------------------------------

class _TrendSummaryCard extends StatelessWidget {
  final TrendCeny? trend;
  final double zmiana;
  final double zmianaProc;
  final String odData;
  final String doData;

  const _TrendSummaryCard({
    required this.trend,
    required this.zmiana,
    required this.zmianaProc,
    required this.odData,
    required this.doData,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (trend) {
      TrendCeny.rosnacy => const Color(0xFFEF5350),
      TrendCeny.spadajacy => const Color(0xFF66BB6A),
      _ => Theme.of(context).colorScheme.outline,
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(children: [
        Icon(
          trend == TrendCeny.rosnacy
              ? Icons.trending_up
              : trend == TrendCeny.spadajacy
                  ? Icons.trending_down
                  : Icons.trending_flat,
          color: color,
          size: 28,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                trend?.porada ?? 'Cena stabilna',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              Text(
                'Zmiana: ${zmiana >= 0 ? '+' : ''}${zmiana.toStringAsFixed(2)} PLN'
                ' (${zmianaProc >= 0 ? '+' : ''}${zmianaProc.toStringAsFixed(1)}%)'
                '\n$odData → $doData',
                style: TextStyle(
                  color: color.withAlpha(200),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

// ---- Wiersz historii -------------------------------------------------------

class _HistoriaRow extends StatelessWidget {
  final HistoriaCenyModel wpis;
  const _HistoriaRow({required this.wpis});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Text(
          wpis.data,
          style: TextStyle(color: cs.outline, fontSize: 12, fontFamily: 'monospace'),
        ),
        const SizedBox(width: 16),
        Text(
          '${wpis.cenaNetto.toStringAsFixed(2)} PLN',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            wpis.zrodlo,
            style: TextStyle(color: cs.outline, fontSize: 10),
          ),
        ),
        if (wpis.uwagi.isNotEmpty) ...[
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              wpis.uwagi,
              style: TextStyle(color: cs.outline, fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ]),
    );
  }
}

// ---- Dialog dodawania ceny -------------------------------------------------

class _DodajCeneDialog extends StatefulWidget {
  final MaterialModel material;
  const _DodajCeneDialog({required this.material});

  @override
  State<_DodajCeneDialog> createState() => _DodajCeneDialogState();
}

class _DodajCeneDialogState extends State<_DodajCeneDialog> {
  final _ctrl = TextEditingController();
  final _uwagiCtrl = TextEditingController();
  String _zrodlo = 'reczne';

  @override
  void initState() {
    super.initState();
    if (widget.material.cenaNetto != null) {
      _ctrl.text = widget.material.cenaNetto!.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _uwagiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text('Nowa cena: ${widget.material.nazwa}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _ctrl,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Cena netto PLN/${widget.material.jednostka}',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _zrodlo,
              decoration: const InputDecoration(
                labelText: 'Źródło',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: 'reczne', child: Text('Ręczne')),
                DropdownMenuItem(value: 'zamowienie', child: Text('Z zamówienia')),
                DropdownMenuItem(value: 'import', child: Text('Import')),
              ],
              onChanged: (v) => setState(() => _zrodlo = v!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _uwagiCtrl,
              decoration: const InputDecoration(
                labelText: 'Uwagi (opcjonalnie)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(
                  _ctrl.text.trim().replaceAll(',', '.'));
              if (v == null) return;
              Navigator.pop(context, v);
            },
            child: const Text('Zapisz'),
          ),
        ],
      );
}
