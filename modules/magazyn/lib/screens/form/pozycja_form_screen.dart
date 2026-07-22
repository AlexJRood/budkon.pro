import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import '../../data/models/magazyn_model.dart';
import '../../data/services/magazyn_api.dart';

class PozycjaFormScreen extends ConsumerStatefulWidget {
  final int budowaId;
  final MagazynPozycjaModel? existing;

  const PozycjaFormScreen({super.key, required this.budowaId, this.existing});

  @override
  ConsumerState<PozycjaFormScreen> createState() => _PozycjaFormScreenState();
}

class _PozycjaFormScreenState extends ConsumerState<PozycjaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nazwaCtrl;
  late final TextEditingController _jednostkaCtrl;
  late final TextEditingController _stanMinCtrl;
  late final TextEditingController _cenaCtrl;
  late final TextEditingController _dostawcaCtrl;
  late final TextEditingController _kodCtrl;
  late KategoriaMaterialu _kategoria;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nazwaCtrl = TextEditingController(text: e?.nazwa ?? '');
    _jednostkaCtrl = TextEditingController(text: e?.jednostka ?? 'szt');
    _stanMinCtrl =
        TextEditingController(text: e != null ? e.stanMinimalny.toString() : '');
    _cenaCtrl =
        TextEditingController(text: e != null ? e.cenaJednostkowa.toString() : '');
    _dostawcaCtrl = TextEditingController(text: e?.dostawca ?? '');
    _kodCtrl = TextEditingController(text: e?.kodKatalogowy ?? '');
    _kategoria = e?.kategoria ?? KategoriaMaterialu.inne;
  }

  @override
  void dispose() {
    _nazwaCtrl.dispose();
    _jednostkaCtrl.dispose();
    _stanMinCtrl.dispose();
    _cenaCtrl.dispose();
    _dostawcaCtrl.dispose();
    _kodCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final api = ref.read(magazynApiProvider);
    try {
      final model = MagazynPozycjaModel(
        id: widget.existing?.id ?? 0,
        budowaId: widget.budowaId,
        nazwa: _nazwaCtrl.text.trim(),
        jednostka: _jednostkaCtrl.text.trim(),
        kategoria: _kategoria,
        stanMinimalny:
            double.tryParse(_stanMinCtrl.text.replaceAll(',', '.')) ?? 0,
        cenaJednostkowa:
            double.tryParse(_cenaCtrl.text.replaceAll(',', '.')) ?? 0,
        dostawca: _dostawcaCtrl.text.trim().isEmpty ? null : _dostawcaCtrl.text.trim(),
        kodKatalogowy: _kodCtrl.text.trim().isEmpty ? null : _kodCtrl.text.trim(),
      );
      if (widget.existing == null) {
        await api.createPozycja(model);
      } else {
        await api.updatePozycja(model);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);
    return Scaffold(
      backgroundColor: theme.scaffoldColor,
      appBar: AppBar(
        backgroundColor: theme.userTile,
        title: Text(
          widget.existing == null ? 'Nowa pozycja magazynowa' : 'Edytuj pozycję',
          style: TextStyle(color: theme.textColor, fontSize: 15, fontWeight: FontWeight.bold),
        ),
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
            // Kategoria
            Text('Kategoria',
                style: TextStyle(fontSize: 12, color: theme.textColor.withAlpha(150), fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: KategoriaMaterialu.values.map((k) {
                final sel = _kategoria == k;
                return ChoiceChip(
                  label: Text('${k.emoji} ${k.label}'),
                  selected: sel,
                  onSelected: (_) => setState(() => _kategoria = k),
                  selectedColor: theme.themeColor.withAlpha(50),
                  checkmarkColor: theme.themeColor,
                  labelStyle: TextStyle(color: sel ? theme.themeColor : theme.textColor, fontSize: 12),
                  side: BorderSide(color: sel ? theme.themeColor : theme.bordercolor.withAlpha(60)),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Nazwa
            TextFormField(
              controller: _nazwaCtrl,
              style: TextStyle(color: theme.textColor),
              decoration: _dec('Nazwa materiału *', theme),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Wymagana' : null,
            ),
            const SizedBox(height: 12),

            // Jednostka
            TextFormField(
              controller: _jednostkaCtrl,
              style: TextStyle(color: theme.textColor),
              decoration: _dec('Jednostka (szt, m², kg, l…)', theme),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Wymagana' : null,
            ),
            const SizedBox(height: 12),

            // Stan min / Cena
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _stanMinCtrl,
                    style: TextStyle(color: theme.textColor),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: _dec('Stan minimalny', theme),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _cenaCtrl,
                    style: TextStyle(color: theme.textColor),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: _dec('Cena jedn. (zł)', theme),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Dostawca
            TextFormField(
              controller: _dostawcaCtrl,
              style: TextStyle(color: theme.textColor),
              decoration: _dec('Dostawca (opcjonalnie)', theme),
            ),
            const SizedBox(height: 12),

            // Kod katalogowy
            TextFormField(
              controller: _kodCtrl,
              style: TextStyle(color: theme.textColor),
              decoration: _dec('Kod katalogowy (opcjonalnie)', theme),
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      );
}
