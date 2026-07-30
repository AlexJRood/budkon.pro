import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import '../../../data/models/projekt_budowlany_model.dart';
import '../../../data/providers/projekty_provider.dart';
import '../../../data/services/projekty_api.dart';

class ProjektKosztorysTab extends ConsumerStatefulWidget {
  const ProjektKosztorysTab({super.key, required this.projektId});
  final String projektId;

  @override
  ConsumerState<ProjektKosztorysTab> createState() =>
      _ProjektKosztorysTabState();
}

class _ProjektKosztorysTabState extends ConsumerState<ProjektKosztorysTab> {
  String? _selectedDzial;
  final Map<int, TextEditingController> _cenaControllers = {};
  final Map<int, bool> _editingLp = {};
  bool _savingCeny = false;

  @override
  void dispose() {
    for (final c in _cenaControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);
    final async = ref.watch(kosztorysApiProvider(widget.projektId));

    return async.when(
      loading: () => Center(child: CircularProgressIndicator(color: theme.themeColor)),
      error: (e, _) => Center(
        child: Text('Błąd: $e', style: TextStyle(color: Colors.red)),
      ),
      data: (kosztorys) => kosztorys.brakKosztorysu || kosztorys.pozycje.isEmpty
          ? _BrakKosztorysuPlaceholder(theme: theme)
          : _KosztorysBody(
        projektId: widget.projektId,
        kosztorys: kosztorys,
        selectedDzial: _selectedDzial,
        onDzialChanged: (d) => setState(() => _selectedDzial = d),
        cenaControllers: _cenaControllers,
        editingLp: _editingLp,
        savingCeny: _savingCeny,
        onSaveCeny: () => _saveCeny(kosztorys),
        theme: theme,
      ),
    );
  }

  Future<void> _saveCeny(KosztorysApiModel kosztorys) async {
    setState(() => _savingCeny = true);

    // Zbierz zmienione ceny
    final Map<String, Map<String, double>> patch = {};
    for (final entry in _cenaControllers.entries) {
      final lp = entry.key;
      final newCena = double.tryParse(entry.value.text.replaceAll(',', '.'));
      final poz = kosztorys.pozycje.firstWhere((p) => p.lp == lp,
          orElse: () => kosztorys.pozycje.first);
      if (newCena != null && newCena != poz.cenaJednNetto) {
        patch['$lp'] = {'cena_jedn_netto': newCena};
        ref
            .read(kosztorysApiProvider(widget.projektId).notifier)
            .updateCenaOptimistic(lp, newCena);
      }
    }

    if (patch.isNotEmpty) {
      try {
        await ref.read(projektyApiProvider).patchCeny(widget.projektId, patch);
      } catch (_) {}
    }

    setState(() {
      _savingCeny = false;
      _editingLp.clear();
    });
  }
}

class _BrakKosztorysuPlaceholder extends StatelessWidget {
  const _BrakKosztorysuPlaceholder({required this.theme});
  final dynamic theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calculate_outlined, size: 56, color: theme.textColor.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text('Brak kosztorysu',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.textColor.withOpacity(0.5))),
          const SizedBox(height: 8),
          Text('Pipeline nie wygenerował pozycji kosztorysowych dla tego projektu.',
              style: TextStyle(fontSize: 13, color: theme.textColor.withOpacity(0.35)),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _KosztorysBody extends StatelessWidget {
  const _KosztorysBody({
    required this.projektId,
    required this.kosztorys,
    required this.selectedDzial,
    required this.onDzialChanged,
    required this.cenaControllers,
    required this.editingLp,
    required this.savingCeny,
    required this.onSaveCeny,
    required this.theme,
  });

  final String projektId;
  final KosztorysApiModel kosztorys;
  final String? selectedDzial;
  final ValueChanged<String?> onDzialChanged;
  final Map<int, TextEditingController> cenaControllers;
  final Map<int, bool> editingLp;
  final bool savingCeny;
  final VoidCallback onSaveCeny;
  final dynamic theme;

  @override
  Widget build(BuildContext context) {
    final dzialy = kosztorys.pozycje.map((p) => p.dzial).toSet().toList();
    final filtered = selectedDzial == null
        ? kosztorys.pozycje
        : kosztorys.pozycje.where((p) => p.dzial == selectedDzial).toList();
    final summ = kosztorys.podsumowanie;

    return Column(
      children: [
        // Podsumowanie
        _PodsumowanieBar(summ: summ, theme: theme),
        // Filtry + eksport
        _FilterBar(
          dzialy: dzialy,
          selectedDzial: selectedDzial,
          onDzialChanged: onDzialChanged,
          projektId: projektId,
          theme: theme,
        ),
        // Tabela pozycji
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (context, i) => _PozycjaTile(
              poz: filtered[i],
              theme: theme,
              cenaControllers: cenaControllers,
              editingLp: editingLp,
            ),
          ),
        ),
        // Zapisz ceny (jeśli edytowano)
        if (editingLp.isNotEmpty)
          _SaveBar(onSave: onSaveCeny, saving: savingCeny, theme: theme),
      ],
    );
  }
}

class _PodsumowanieBar extends StatelessWidget {
  const _PodsumowanieBar({required this.summ, required this.theme});
  final KosztorysPodsumowanieModel summ;
  final dynamic theme;

  @override
  Widget build(BuildContext context) {
    final sk = summ.skladniki;
    return Container(
      color: theme.themeColor.withOpacity(0.08),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Wrap(
        spacing: 20,
        runSpacing: 8,
        children: [
          _SummItem(label: 'Netto', value: _fmt(summ.sumaNetto), theme: theme),
          _SummItem(label: 'VAT 23%', value: _fmt(summ.vat23), theme: theme),
          _SummItem(label: 'Brutto', value: _fmt(summ.brutto), theme: theme, bold: true),
          if (sk != null) ...[
            _SummItem(label: 'Robocizna', value: _fmt(sk.robocizna), theme: theme),
            _SummItem(label: 'Materiały', value: _fmt(sk.materialy), theme: theme),
            _SummItem(label: 'Rbh łącznie', value: '${sk.razemRbh.toStringAsFixed(1)} rbh', theme: theme),
          ],
        ],
      ),
    );
  }

  String _fmt(double v) =>
      '${v.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} PLN';
}

class _SummItem extends StatelessWidget {
  const _SummItem({
    required this.label,
    required this.value,
    required this.theme,
    this.bold = false,
  });
  final String label;
  final String value;
  final dynamic theme;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 11, color: theme.textColor.withOpacity(0.6))),
        Text(value,
            style: TextStyle(
                fontSize: bold ? 16 : 14,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: theme.textColor)),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.dzialy,
    required this.selectedDzial,
    required this.onDzialChanged,
    required this.projektId,
    required this.theme,
  });

  final List<String> dzialy;
  final String? selectedDzial;
  final ValueChanged<String?> onDzialChanged;
  final String projektId;
  final dynamic theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Wszystkie',
                    selected: selectedDzial == null,
                    onTap: () => onDzialChanged(null),
                    theme: theme,
                  ),
                  ...dzialy.map((d) => _FilterChip(
                        label: d,
                        selected: selectedDzial == d,
                        onTap: () =>
                            onDzialChanged(selectedDzial == d ? null : d),
                        theme: theme,
                      )),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Eksport
          PopupMenuButton<String>(
            icon: Icon(Icons.download_outlined, color: theme.themeColor),
            tooltip: 'Eksportuj kosztorys',
            onSelected: (format) {
              // URL do otworzenia przez platformę
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'pdf', child: Text('Pobierz PDF')),
              PopupMenuItem(value: 'excel', child: Text('Pobierz Excel')),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.theme,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final dynamic theme;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? theme.themeColor : theme.themeColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
              fontSize: 12,
              color: selected ? Colors.white : theme.themeColor,
              fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

class _PozycjaTile extends StatefulWidget {
  const _PozycjaTile({
    required this.poz,
    required this.theme,
    required this.cenaControllers,
    required this.editingLp,
  });

  final KosztorysPozycjaApiModel poz;
  final dynamic theme;
  final Map<int, TextEditingController> cenaControllers;
  final Map<int, bool> editingLp;

  @override
  State<_PozycjaTile> createState() => _PozycjaTileState();
}

class _PozycjaTileState extends State<_PozycjaTile> {
  bool _expanded = false;

  KosztorysPozycjaApiModel get poz => widget.poz;
  dynamic get theme => widget.theme;
  Map<int, TextEditingController> get cenaControllers => widget.cenaControllers;
  Map<int, bool> get editingLp => widget.editingLp;

  TextEditingController _controller() {
    return cenaControllers.putIfAbsent(
      poz.lp,
      () => TextEditingController(
          text: poz.cenaJednNetto.toStringAsFixed(2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = editingLp[poz.lp] ?? false;
    return Card(
      color: theme.cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: theme.textColor.withOpacity(0.08)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.themeColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('${poz.lp}',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: theme.themeColor)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(poz.opis,
                        style:
                            TextStyle(fontSize: 13, color: theme.textColor)),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: theme.textColor.withOpacity(0.4),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  // Dział
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.themeColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(poz.dzial,
                        style: TextStyle(
                            fontSize: 10, color: theme.themeColor)),
                  ),
                  if (poz.knr != null) ...[
                    const SizedBox(width: 6),
                    Text('KNR ${poz.knr}',
                        style: TextStyle(
                            fontSize: 10,
                            color: theme.textColor.withOpacity(0.5))),
                  ],
                  const Spacer(),
                  // Ilość
                  Text(
                    '${poz.ilosc.toStringAsFixed(2)} ${poz.jednostka}',
                    style: TextStyle(
                        fontSize: 12, color: theme.textColor.withOpacity(0.7)),
                  ),
                  const SizedBox(width: 12),
                  // Cena jednostkowa (edytowalna)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        editingLp[poz.lp] = true;
                        _controller();
                      });
                    },
                    child: editing
                        ? SizedBox(
                            width: 80,
                            child: TextField(
                              controller: _controller(),
                              autofocus: true,
                              style: TextStyle(
                                  fontSize: 12, color: theme.textColor),
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 4),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true),
                              onSubmitted: (_) =>
                                  setState(() => editingLp[poz.lp] = false),
                            ),
                          )
                        : Row(
                            children: [
                              Text(
                                '${poz.cenaJednNetto.toStringAsFixed(2)} PLN/${poz.jednostka}',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: theme.textColor.withOpacity(0.7)),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.edit,
                                  size: 12,
                                  color: theme.textColor.withOpacity(0.3)),
                            ],
                          ),
                  ),
                  const SizedBox(width: 12),
                  // Wartość netto
                  Text(
                    '${poz.wartoscNetto.toStringAsFixed(2)} PLN',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.textColor),
                  ),
                ],
              ),
              if (_expanded) ...[
                Divider(height: 20, color: theme.textColor.withOpacity(0.08)),
                _SzczegolyPozycji(poz: poz, theme: theme),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SzczegolyPozycji extends StatelessWidget {
  const _SzczegolyPozycji({required this.poz, required this.theme});
  final KosztorysPozycjaApiModel poz;
  final dynamic theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _row('Dział', poz.dzial),
        if (poz.knr != null) _row('Podstawa (KNR)', poz.knr!),
        _row('Wyliczenie',
            '${poz.ilosc.toStringAsFixed(2)} ${poz.jednostka} × ${poz.cenaJednNetto.toStringAsFixed(2)} PLN/${poz.jednostka} = ${poz.wartoscNetto.toStringAsFixed(2)} PLN'),
        if (poz.hasBreakdown) ...[
          const SizedBox(height: 10),
          _BreakdownTable(poz: poz, theme: theme),
        ],
        if (poz.uwagi != null) ...[
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 13, color: theme.themeColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(poz.uwagi!,
                    style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: theme.textColor.withOpacity(0.7))),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Text(label,
                  style: TextStyle(
                      fontSize: 11, color: theme.textColor.withOpacity(0.5))),
            ),
            Expanded(
              child: Text(value,
                  style: TextStyle(fontSize: 12, color: theme.textColor)),
            ),
          ],
        ),
      );
}

class _BreakdownTable extends StatelessWidget {
  const _BreakdownTable({required this.poz, required this.theme});
  final KosztorysPozycjaApiModel poz;
  final dynamic theme;

  @override
  Widget build(BuildContext context) {
    final rows = [
      _BRow('R  Robocizna', poz.robocizna, rbh: poz.rbh),
      _BRow('M  Materiały', poz.materialy),
      _BRow('S  Sprzęt', poz.sprzet),
      _BRow('KP Koszty pośrednie', poz.kp),
      _BRow('Z  Zysk', poz.z),
    ];

    return Container(
      decoration: BoxDecoration(
        color: theme.themeColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: theme.themeColor.withOpacity(0.12)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        children: [
          ...rows.map((r) => _buildRow(r)),
          Divider(height: 12, color: theme.textColor.withOpacity(0.15)),
          Row(
            children: [
              Expanded(
                child: Text('Razem netto',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: theme.textColor)),
              ),
              Text(_fmt(poz.wartoscNetto),
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: theme.textColor,
                      fontFeatures: const [FontFeature.tabularFigures()])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRow(_BRow r) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(r.label,
                style: TextStyle(
                    fontSize: 11, color: theme.textColor.withOpacity(0.65))),
          ),
          if (r.rbh != null)
            Text('${r.rbh!.toStringAsFixed(1)} rbh  ',
                style: TextStyle(
                    fontSize: 10, color: theme.textColor.withOpacity(0.45))),
          Text(
            r.value != null ? _fmt(r.value!) : '—',
            style: TextStyle(
                fontSize: 11,
                color: theme.textColor.withOpacity(0.8),
                fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) => '${v.toStringAsFixed(2)} PLN';
}

class _BRow {
  final String label;
  final double? value;
  final double? rbh;
  const _BRow(this.label, this.value, {this.rbh});
}

class _SaveBar extends StatelessWidget {
  const _SaveBar(
      {required this.onSave, required this.saving, required this.theme});
  final VoidCallback onSave;
  final bool saving;
  final dynamic theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Row(
        children: [
          Icon(Icons.edit_note, size: 18, color: theme.themeColor),
          const SizedBox(width: 8),
          Text('Ceny zostały zmienione',
              style: TextStyle(fontSize: 13, color: theme.textColor)),
          const Spacer(),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: theme.themeColor,
                foregroundColor: Colors.white),
            onPressed: saving ? null : onSave,
            child: saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Zapisz ceny'),
          ),
        ],
      ),
    );
  }
}
