import 'package:flutter/material.dart';
import '../../data/models/kontakty_model.dart';
import '../../data/services/kontakty_api.dart';

class KontrahentFormScreen extends StatefulWidget {
  final KontrahentDetail? existing;
  const KontrahentFormScreen({super.key, this.existing});

  @override
  State<KontrahentFormScreen> createState() => _KontrahentFormScreenState();
}

class _KontrahentFormScreenState extends State<KontrahentFormScreen> {
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
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(_editing ? 'Edytuj kontakt' : 'Nowy kontakt'),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Firma lub osoba
              TextFormField(
                controller: _firmaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nazwa firmy',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business_outlined),
                  helperText: 'Zostaw puste jeśli osoba prywatna',
                ),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _imieCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Imię',
                        border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _nazwiskoCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Nazwisko',
                        border: OutlineInputBorder()),
                  ),
                ),
              ]),
              const SizedBox(height: 12),

              // Branża
              DropdownButtonFormField<Branza?>(
                value: _branza,
                decoration: const InputDecoration(
                    labelText: 'Branża',
                    border: OutlineInputBorder()),
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
                decoration: const InputDecoration(
                    labelText: 'Telefon',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone_outlined)),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                    labelText: 'E-mail',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined)),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _nipCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'NIP',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge_outlined)),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _adresCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                    labelText: 'Adres',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on_outlined)),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _uwagiCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: 'Uwagi',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true),
              ),

              const SizedBox(height: 24),

              FilledButton(
                onPressed: _saving ? null : _zapisz,
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

  Future<void> _zapisz() async {
    if (!_formKey.currentState!.validate()) return;
    // Wymagane: firma LUB (imię + nazwisko)
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
