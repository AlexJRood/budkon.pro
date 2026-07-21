import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import '../../data/models/kontakty_model.dart';
import '../../data/services/kontakty_api.dart';

class KontrahentFormScreen extends ConsumerStatefulWidget {
  final KontrahentDetail? existing;
  const KontrahentFormScreen({super.key, this.existing});

  @override
  ConsumerState<KontrahentFormScreen> createState() =>
      _KontrahentFormScreenState();
}

class _KontrahentFormScreenState extends ConsumerState<KontrahentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firmaCtrl;
  late final TextEditingController _imieCtrl;
  late final TextEditingController _nazwiskoCtrl;
  late final TextEditingController _telefonCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _nipCtrl;
  late final TextEditingController _adresCtrl;
  late final TextEditingController _uwagiCtrl;
  Branza? _branza;
  bool _saving = false;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _firmaCtrl = TextEditingController(text: e?.firma ?? '');
    _imieCtrl = TextEditingController(text: e?.imie ?? '');
    _nazwiskoCtrl = TextEditingController(text: e?.nazwisko ?? '');
    _telefonCtrl = TextEditingController(text: e?.telefon ?? '');
    _emailCtrl = TextEditingController(text: e?.email ?? '');
    _nipCtrl = TextEditingController(text: e?.nip ?? '');
    _adresCtrl = TextEditingController(text: e?.adres ?? '');
    _uwagiCtrl = TextEditingController(text: e?.uwagi ?? '');
    _branza = e?.branza;
  }

  @override
  void dispose() {
    for (final c in [
      _firmaCtrl, _imieCtrl, _nazwiskoCtrl, _telefonCtrl,
      _emailCtrl, _nipCtrl, _adresCtrl, _uwagiCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);

    InputDecoration _dec(String label, {Widget? prefix}) => InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: theme.textColor.withAlpha(160)),
      filled: true,
      fillColor: theme.textFieldColor,
      prefixIcon: prefix,
      border: OutlineInputBorder(
          borderSide: BorderSide(color: theme.bordercolor.withAlpha(60))),
      enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: theme.bordercolor.withAlpha(60))),
      isDense: true,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: theme.textColor),
        title: Text(_editing ? 'Edytuj kontakt' : 'Nowy kontakt',
            style: TextStyle(color: theme.textColor)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _firmaCtrl,
              style: TextStyle(color: theme.textColor),
              decoration: _dec('Nazwa firmy',
                  prefix: Icon(Icons.business_outlined,
                      color: theme.textColor.withAlpha(150))).copyWith(
                helperText: 'Zostaw puste jeśli osoba prywatna',
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _imieCtrl,
                  style: TextStyle(color: theme.textColor),
                  decoration: _dec('Imię'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _nazwiskoCtrl,
                  style: TextStyle(color: theme.textColor),
                  decoration: _dec('Nazwisko'),
                ),
              ),
            ]),
            const SizedBox(height: 12),

            DropdownButtonFormField<Branza?>(
              value: _branza,
              dropdownColor: theme.popupcontainercolor,
              style: TextStyle(color: theme.textColor),
              decoration: _dec('Branża'),
              items: [
                const DropdownMenuItem(value: null, child: Text('— brak —')),
                ...Branza.values.map((b) => DropdownMenuItem(
                      value: b,
                      child: Text('${b.emoji}  ${b.label}'),
                    )),
              ],
              onChanged: (v) => setState(() => _branza = v),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _telefonCtrl,
              keyboardType: TextInputType.phone,
              style: TextStyle(color: theme.textColor),
              decoration: _dec('Telefon',
                  prefix: Icon(Icons.phone_outlined,
                      color: theme.textColor.withAlpha(150))),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: theme.textColor),
              decoration: _dec('E-mail',
                  prefix: Icon(Icons.email_outlined,
                      color: theme.textColor.withAlpha(150))),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _nipCtrl,
              keyboardType: TextInputType.number,
              style: TextStyle(color: theme.textColor),
              decoration: _dec('NIP',
                  prefix: Icon(Icons.badge_outlined,
                      color: theme.textColor.withAlpha(150))),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _adresCtrl,
              maxLines: 2,
              style: TextStyle(color: theme.textColor),
              decoration: _dec('Adres',
                  prefix: Icon(Icons.location_on_outlined,
                      color: theme.textColor.withAlpha(150))),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _uwagiCtrl,
              maxLines: 3,
              style: TextStyle(color: theme.textColor),
              decoration: _dec('Uwagi').copyWith(alignLabelWithHint: true),
            ),

            const SizedBox(height: 24),

            FilledButton(
              onPressed: _saving ? null : _zapisz,
              style: FilledButton.styleFrom(
                  backgroundColor: theme.themeColor,
                  foregroundColor: theme.buttonTextColor),
              child: _saving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(_editing ? 'Zapisz zmiany' : 'Dodaj kontakt'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _zapisz() async {
    if (!_formKey.currentState!.validate()) return;
    if (_firmaCtrl.text.trim().isEmpty &&
        _imieCtrl.text.trim().isEmpty &&
        _nazwiskoCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Podaj nazwę firmy lub imię i nazwisko')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final payload = {
        'firma': _firmaCtrl.text.trim(),
        'imie': _imieCtrl.text.trim(),
        'nazwisko': _nazwiskoCtrl.text.trim(),
        'telefon': _telefonCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'nip': _nipCtrl.text.trim(),
        'adres': _adresCtrl.text.trim(),
        'uwagi': _uwagiCtrl.text.trim(),
        if (_branza != null) 'branza': _branza!.name,
      };

      if (_editing) {
        await kontaktyApi.edytuj(widget.existing!.id, payload);
      } else {
        await kontaktyApi.utworz(payload);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Błąd: $e')));
      }
    }
  }
}
