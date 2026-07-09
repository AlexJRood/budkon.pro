import 'package:flutter/material.dart';
import '../../data/models/pracownicy_model.dart';
import '../../data/services/pracownicy_api.dart';

/// Prosty formularz nowego pracownika — imię, nazwisko, specjalizacja, stawka.
class NowyPracownikScreen extends StatefulWidget {
  const NowyPracownikScreen({super.key});

  @override
  State<NowyPracownikScreen> createState() => _NowyPracownikScreenState();
}

class _NowyPracownikScreenState extends State<NowyPracownikScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imieCtrl = TextEditingController();
  final _nazwiskoCtrl = TextEditingController();
  final _telefonCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _stawkaCtrl = TextEditingController();
  Specjalizacja _spec = Specjalizacja.murarz;
  String _typUmowy = 'umowa_zlecenie';
  bool _saving = false;

  @override
  void dispose() {
    _imieCtrl.dispose();
    _nazwiskoCtrl.dispose();
    _telefonCtrl.dispose();
    _emailCtrl.dispose();
    _stawkaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Nowy pracownik')),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _imieCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Imię *',
                        border: OutlineInputBorder()),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Wymagane' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _nazwiskoCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Nazwisko *',
                        border: OutlineInputBorder()),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Wymagane' : null,
                  ),
                ),
              ]),
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
                    labelText: 'E-mail (opcjonalnie)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined)),
              ),
              const SizedBox(height: 12),

              // Główna specjalizacja
              DropdownButtonFormField<Specjalizacja>(
                value: _spec,
                decoration: const InputDecoration(
                    labelText: 'Główna specjalizacja',
                    border: OutlineInputBorder()),
                items: Specjalizacja.values
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text('${s.emoji}  ${s.label}'),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _spec = v!),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _typUmowy,
                decoration: const InputDecoration(
                    labelText: 'Typ umowy',
                    border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(
                      value: 'umowa_o_prace', child: Text('Umowa o pracę')),
                  DropdownMenuItem(
                      value: 'umowa_zlecenie',
                      child: Text('Umowa zlecenie')),
                  DropdownMenuItem(value: 'b2b', child: Text('B2B')),
                  DropdownMenuItem(
                      value: 'dzieło', child: Text('Umowa o dzieło')),
                ],
                onChanged: (v) => setState(() => _typUmowy = v!),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _stawkaCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Stawka godzinowa PLN/h (opcjonalnie)',
                  border: OutlineInputBorder(),
                  suffixText: 'PLN/h',
                  helperText:
                      'Można dodać później w profilu',
                ),
              ),

              const SizedBox(height: 24),

              FilledButton(
                onPressed: _saving ? null : _zapisz,
                child: _saving
                    ? const SizedBox.square(
                        dimension: 20,
                        child:
                            CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Zapisz pracownika'),
              ),
            ],
          ),
        ),
      );

  Future<void> _zapisz() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final p = await pracownicyApi.utworz({
        'imie': _imieCtrl.text.trim(),
        'nazwisko': _nazwiskoCtrl.text.trim(),
        'telefon': _telefonCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'glowna_specjalizacja': _spec.value,
        'typ_umowy': _typUmowy,
      });

      // Jeśli podano stawkę — zapisz też historię
      final stawka = double.tryParse(
          _stawkaCtrl.text.replaceAll(',', '.'));
      if (stawka != null) {
        await pracownicyApi.dodajStawke(
          p.id,
          stawka,
          DateTime.now().toIso8601String().substring(0, 10),
        );
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
