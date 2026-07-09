import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/faktury_api.dart';
import '../../data/providers/faktury_provider.dart';
import '../detail/faktura_detail_screen.dart';

/// Prosty formularz nowej faktury — nabywca + VAT + termin + pozycje ręczne.
/// Dla tworzenia z oferty używaj FakturaFormScreen(ofertaId: X).
class FakturaFormScreen extends ConsumerStatefulWidget {
  final int? budowaId;
  final int? ofertaId;

  const FakturaFormScreen({super.key, this.budowaId, this.ofertaId});

  @override
  ConsumerState<FakturaFormScreen> createState() => _FakturaFormScreenState();
}

class _FakturaFormScreenState extends ConsumerState<FakturaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nabywcaCtrl = TextEditingController();
  final _nipCtrl = TextEditingController();
  final _adresCtrl = TextEditingController();
  final _wystawcaCtrl = TextEditingController();
  final _wystawcaNipCtrl = TextEditingController();
  final _wystawcaKontoCtrl = TextEditingController();
  final _uwagiCtrl = TextEditingController();

  int _stawkaVat = 23;
  DateTime _terminPlatnosci =
      DateTime.now().add(const Duration(days: 14));
  String _metoda = 'przelew';
  bool _saving = false;

  // Manualne pozycje
  final List<Map<String, dynamic>> _pozycje = [];

  @override
  void dispose() {
    for (final c in [
      _nabywcaCtrl, _nipCtrl, _adresCtrl,
      _wystawcaCtrl, _wystawcaNipCtrl, _wystawcaKontoCtrl, _uwagiCtrl,
    ]) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.ofertaId != null
              ? 'FV z oferty'
              : 'Nowa faktura'),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SectionLabel('Wystawca'),
              TextFormField(
                controller: _wystawcaCtrl,
                decoration: const InputDecoration(
                    labelText: 'Nazwa firmy wystawcy *',
                    border: OutlineInputBorder()),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Wymagane' : null,
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _wystawcaNipCtrl,
                    decoration: const InputDecoration(
                        labelText: 'NIP', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _wystawcaKontoCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Nr konta (IBAN)',
                        border: OutlineInputBorder()),
                  ),
                ),
              ]),

              const SizedBox(height: 20),
              _SectionLabel('Nabywca'),
              TextFormField(
                controller: _nabywcaCtrl,
                decoration: const InputDecoration(
                    labelText: 'Nazwa nabywcy *',
                    border: OutlineInputBorder()),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Wymagane' : null,
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _nipCtrl,
                    decoration: const InputDecoration(
                        labelText: 'NIP nabywcy',
                        border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _stawkaVat,
                    decoration: const InputDecoration(
                        labelText: 'VAT %',
                        border: OutlineInputBorder()),
                    items: [0, 5, 8, 23]
                        .map((v) => DropdownMenuItem(
                            value: v, child: Text('$v%')))
                        .toList(),
                    onChanged: (v) => setState(() => _stawkaVat = v!),
                  ),
                ),
              ]),

              const SizedBox(height: 20),
              _SectionLabel('Płatność'),
              Row(children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _metoda,
                    decoration: const InputDecoration(
                        labelText: 'Metoda',
                        border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(
                          value: 'przelew', child: Text('Przelew')),
                      DropdownMenuItem(
                          value: 'gotowka', child: Text('Gotówka')),
                      DropdownMenuItem(value: 'blik', child: Text('BLIK')),
                      DropdownMenuItem(value: 'karta', child: Text('Karta')),
                    ],
                    onChanged: (v) => setState(() => _metoda = v!),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                          labelText: 'Termin płatności',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today, size: 18)),
                      child: Text(
                        '${_terminPlatnosci.day.toString().padLeft(2, '0')}.${_terminPlatnosci.month.toString().padLeft(2, '0')}.${_terminPlatnosci.year}',
                      ),
                    ),
                  ),
                ),
              ]),

              const SizedBox(height: 20),
              _SectionLabel('Uwagi'),
              TextFormField(
                controller: _uwagiCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Opcjonalne uwagi na fakturze'),
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
                    : const Text('Wystaw fakturę'),
              ),
            ],
          ),
        ),
      );

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _terminPlatnosci,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _terminPlatnosci = d);
  }

  Future<void> _zapisz() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      FakturaDetail fv;
      final wystawca = {
        'wystawca_nazwa': _wystawcaCtrl.text.trim(),
        'wystawca_nip': _wystawcaNipCtrl.text.trim(),
        'wystawca_konto': _wystawcaKontoCtrl.text.trim(),
      };

      if (widget.ofertaId != null) {
        fv = await fakturyApi.zOferty(widget.ofertaId!, wystawca);
      } else {
        fv = await fakturyApi.utworz({
          ...wystawca,
          if (widget.budowaId != null) 'budowa_id': widget.budowaId,
          'nabywca_nazwa': _nabywcaCtrl.text.trim(),
          'nabywca_nip': _nipCtrl.text.trim(),
          'nabywca_adres': _adresCtrl.text.trim(),
          'stawka_vat': _stawkaVat,
          'metoda_platnosci': _metoda,
          'termin_platnosci': _terminPlatnosci.toIso8601String().substring(0, 10),
          'uwagi': _uwagiCtrl.text.trim(),
          'pozycje': _pozycje,
        });
      }

      ref.read(fakturyProvider.notifier).load();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => FakturaDetailScreen(fakturaId: fv.id)),
        );
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Błąd: $e')));
      }
    }
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(label,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700)),
      );
}
