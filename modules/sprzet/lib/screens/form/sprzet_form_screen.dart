import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import '../../data/models/sprzet_model.dart';
import '../../data/services/sprzet_api.dart';

class SprzetFormScreen extends ConsumerStatefulWidget {
  final SprzetModel? existing;
  final int? budowaId;

  const SprzetFormScreen({super.key, this.existing, this.budowaId});

  @override
  ConsumerState<SprzetFormScreen> createState() => _SprzetFormScreenState();
}

class _SprzetFormScreenState extends ConsumerState<SprzetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nazwaCtrl;
  late final TextEditingController _nrSeryjnyCtrl;
  late final TextEditingController _nrRejCtrl;
  late final TextEditingController _lokalizacjaCtrl;
  late final TextEditingController _uwagiCtrl;
  late KategoriaSprzetu _kategoria;
  DateTime? _dataKoncaPrzegladu;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nazwaCtrl = TextEditingController(text: e?.nazwa ?? '');
    _nrSeryjnyCtrl = TextEditingController(text: e?.nrSeryjny ?? '');
    _nrRejCtrl = TextEditingController(text: e?.nrRejestracyjny ?? '');
    _lokalizacjaCtrl = TextEditingController(text: e?.lokalizacja ?? '');
    _uwagiCtrl = TextEditingController(text: e?.uwagi ?? '');
    _kategoria = e?.kategoria ?? KategoriaSprzetu.inne;
    _dataKoncaPrzegladu = e?.dataKoncaPrzegladu;
  }

  @override
  void dispose() {
    _nazwaCtrl.dispose();
    _nrSeryjnyCtrl.dispose();
    _nrRejCtrl.dispose();
    _lokalizacjaCtrl.dispose();
    _uwagiCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final api = ref.read(sprzetApiProvider);
    try {
      final model = SprzetModel(
        id: widget.existing?.id ?? 0,
        nazwa: _nazwaCtrl.text.trim(),
        kategoria: _kategoria,
        nrSeryjny: _nrSeryjnyCtrl.text.trim().isEmpty ? null : _nrSeryjnyCtrl.text.trim(),
        nrRejestracyjny: _nrRejCtrl.text.trim().isEmpty ? null : _nrRejCtrl.text.trim(),
        lokalizacja: _lokalizacjaCtrl.text.trim().isEmpty ? null : _lokalizacjaCtrl.text.trim(),
        dataKoncaPrzegladu: _dataKoncaPrzegladu,
        budowaId: widget.budowaId ?? widget.existing?.budowaId,
        uwagi: _uwagiCtrl.text.trim(),
      );
      if (widget.existing == null) {
        await api.createSprzet(model);
      } else {
        await api.updateSprzet(model);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Błąd: $e')));
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
          widget.existing == null ? 'Nowy sprzęt' : 'Edytuj sprzęt',
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
            Text('Kategoria',
                style: TextStyle(fontSize: 12, color: theme.textColor.withAlpha(150), fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: KategoriaSprzetu.values.map((k) {
                final sel = _kategoria == k;
                return ChoiceChip(
                  label: Text('${k.emoji} ${k.label}'),
                  selected: sel,
                  onSelected: (_) => setState(() => _kategoria = k),
                  selectedColor: theme.themeColor.withAlpha(50),
                  checkmarkColor: theme.themeColor,
                  labelStyle: TextStyle(
                      color: sel ? theme.themeColor : theme.textColor, fontSize: 12),
                  side: BorderSide(
                      color: sel ? theme.themeColor : theme.bordercolor.withAlpha(60)),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nazwaCtrl,
              style: TextStyle(color: theme.textColor),
              decoration: _dec('Nazwa sprzętu *', theme),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Wymagana' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _nrSeryjnyCtrl,
                    style: TextStyle(color: theme.textColor),
                    decoration: _dec('Nr seryjny', theme),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _nrRejCtrl,
                    style: TextStyle(color: theme.textColor),
                    decoration: _dec('Nr rejestracyjny', theme),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _lokalizacjaCtrl,
              style: TextStyle(color: theme.textColor),
              decoration: _dec('Lokalizacja / Budowa', theme),
            ),
            const SizedBox(height: 12),
            // Data przeglądu
            InkWell(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _dataKoncaPrzegladu ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2035),
                );
                if (d != null) setState(() => _dataKoncaPrzegladu = d);
              },
              child: InputDecorator(
                decoration: _dec('Przegląd ważny do (opcjonalnie)', theme),
                child: Text(
                  _dataKoncaPrzegladu != null
                      ? '${_dataKoncaPrzegladu!.day}.${_dataKoncaPrzegladu!.month}.${_dataKoncaPrzegladu!.year}'
                      : '—',
                  style: TextStyle(color: theme.textColor),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _uwagiCtrl,
              style: TextStyle(color: theme.textColor),
              maxLines: 3,
              decoration: _dec('Uwagi (opcjonalnie)', theme),
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
