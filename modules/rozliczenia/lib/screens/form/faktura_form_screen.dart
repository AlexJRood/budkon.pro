import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import '../../data/models/rozliczenia_model.dart';
import '../../data/services/rozliczenia_api.dart';

class FakturaFormScreen extends ConsumerStatefulWidget {
  final int budowaId;
  const FakturaFormScreen({super.key, required this.budowaId});

  @override
  ConsumerState<FakturaFormScreen> createState() => _FakturaFormScreenState();
}

class _FakturaFormScreenState extends ConsumerState<FakturaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _numerCtrl = TextEditingController();
  final _inwestorCtrl = TextEditingController();
  final _wykonawcaCtrl = TextEditingController();
  final _postepCtrl = TextEditingController(text: '0');

  TypFaktury _typ = TypFaktury.postepowa;
  DateTime _dataWystawienia = DateTime.now();
  DateTime _dataTerminu = DateTime.now().add(const Duration(days: 14));

  final List<_PozycjaEntry> _pozycje = [_PozycjaEntry()];
  bool _saving = false;

  @override
  void dispose() {
    _numerCtrl.dispose();
    _inwestorCtrl.dispose();
    _wykonawcaCtrl.dispose();
    _postepCtrl.dispose();
    for (final p in _pozycje) p.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final faktura = FakturaModel(
        id: 0,
        budowaId: widget.budowaId,
        numer: _numerCtrl.text.trim(),
        typ: _typ,
        dataWystawienia: _dataWystawienia,
        dataTerminu: _dataTerminu,
        inwestorNazwa: _inwestorCtrl.text.trim(),
        wykonawcaNazwa: _wykonawcaCtrl.text.trim(),
        postepProcent: double.tryParse(_postepCtrl.text) ?? 0,
        pozycje: _pozycje.map((p) => p.toModel()).toList(),
      );
      await ref.read(rozliczeniaApiProvider).createFaktura(faktura);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Błąd: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);
    return Scaffold(
      backgroundColor: theme.scaffoldColor,
      appBar: AppBar(
        backgroundColor: theme.userTile,
        title: Text('Nowa faktura',
            style: TextStyle(color: theme.textColor, fontSize: 15, fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: theme.themeColor))
                : Text('Zapisz',
                    style: TextStyle(color: theme.themeColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Typ
            Text('Typ faktury',
                style: TextStyle(fontSize: 12, color: theme.textColor.withAlpha(150), fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: TypFaktury.values.map((t) {
                final sel = _typ == t;
                return ChoiceChip(
                  label: Text(t.label),
                  selected: sel,
                  onSelected: (_) => setState(() => _typ = t),
                  selectedColor: theme.themeColor.withAlpha(50),
                  checkmarkColor: theme.themeColor,
                  labelStyle: TextStyle(color: sel ? theme.themeColor : theme.textColor, fontSize: 12),
                  side: BorderSide(color: sel ? theme.themeColor : theme.bordercolor.withAlpha(60)),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _numerCtrl,
              style: TextStyle(color: theme.textColor),
              decoration: _dec('Numer faktury *', theme),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Wymagany' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _inwestorCtrl,
              style: TextStyle(color: theme.textColor),
              decoration: _dec('Inwestor *', theme),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Wymagany' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _wykonawcaCtrl,
              style: TextStyle(color: theme.textColor),
              decoration: _dec('Wykonawca *', theme),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Wymagany' : null,
            ),
            const SizedBox(height: 12),

            // Daty
            Row(
              children: [
                Expanded(child: _DatePicker('Data wystawienia', _dataWystawienia,
                    (d) => setState(() => _dataWystawienia = d), theme)),
                const SizedBox(width: 12),
                Expanded(child: _DatePicker('Termin płatności', _dataTerminu,
                    (d) => setState(() => _dataTerminu = d), theme)),
              ],
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _postepCtrl,
              style: TextStyle(color: theme.textColor),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: _dec('Postęp robót % (0–100)', theme),
            ),
            const SizedBox(height: 20),

            // Pozycje
            Text('Pozycje faktury',
                style: TextStyle(fontSize: 12, color: theme.textColor.withAlpha(150), fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ..._pozycje.asMap().entries.map((e) => _PozycjaWidget(
                  entry: e.value,
                  index: e.key + 1,
                  theme: theme,
                  onRemove: _pozycje.length > 1 ? () => setState(() => _pozycje.removeAt(e.key)) : null,
                )),
            TextButton.icon(
              onPressed: () => setState(() => _pozycje.add(_PozycjaEntry())),
              icon: Icon(Icons.add, color: theme.themeColor),
              label: Text('Dodaj pozycję', style: TextStyle(color: theme.themeColor)),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _dec(String label, ThemeColors theme) => InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: theme.textColor.withAlpha(150), fontSize: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: theme.bordercolor.withAlpha(80)),
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      );
}

class _PozycjaEntry {
  final opisCtrl = TextEditingController();
  final iloscCtrl = TextEditingController(text: '1');
  final jednostkaCtrl = TextEditingController(text: 'ryczałt');
  final cenaCtrl = TextEditingController();
  final vatCtrl = TextEditingController(text: '23');

  PozycjaFakturyModel toModel() => PozycjaFakturyModel(
        opis: opisCtrl.text.trim(),
        ilosc: double.tryParse(iloscCtrl.text.replaceAll(',', '.')) ?? 1,
        jednostka: jednostkaCtrl.text.trim(),
        cenaNetto: double.tryParse(cenaCtrl.text.replaceAll(',', '.')) ?? 0,
        vat: double.tryParse(vatCtrl.text) ?? 23,
      );

  void dispose() {
    opisCtrl.dispose();
    iloscCtrl.dispose();
    jednostkaCtrl.dispose();
    cenaCtrl.dispose();
    vatCtrl.dispose();
  }
}

class _PozycjaWidget extends StatelessWidget {
  final _PozycjaEntry entry;
  final int index;
  final ThemeColors theme;
  final VoidCallback? onRemove;

  const _PozycjaWidget({
    required this.entry,
    required this.index,
    required this.theme,
    this.onRemove,
  });

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: theme.textColor.withAlpha(150), fontSize: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: theme.bordercolor.withAlpha(60)),
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      );

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.userTile,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.bordercolor.withAlpha(50)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Pozycja $index',
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600, color: theme.themeColor)),
                const Spacer(),
                if (onRemove != null)
                  GestureDetector(
                    onTap: onRemove,
                    child: Icon(Icons.close, size: 18, color: Colors.red.shade400),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: entry.opisCtrl,
              style: TextStyle(color: theme.textColor),
              decoration: _dec('Opis *'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: entry.cenaCtrl,
                    style: TextStyle(color: theme.textColor),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: _dec('Cena netto'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: entry.iloscCtrl,
                    style: TextStyle(color: theme.textColor),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: _dec('Ilość'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: entry.vatCtrl,
                    style: TextStyle(color: theme.textColor),
                    keyboardType: TextInputType.number,
                    decoration: _dec('VAT %'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

class _DatePicker extends StatelessWidget {
  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final ThemeColors theme;
  const _DatePicker(this.label, this.value, this.onChanged, this.theme);

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () async {
          final d = await showDatePicker(
            context: context,
            initialDate: value,
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
          );
          if (d != null) onChanged(d);
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: theme.textColor.withAlpha(150), fontSize: 13),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          child: Text('${value.day}.${value.month}.${value.year}',
              style: TextStyle(color: theme.textColor, fontSize: 13)),
        ),
      );
}
