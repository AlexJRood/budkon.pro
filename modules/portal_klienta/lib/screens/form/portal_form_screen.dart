import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/portal_model.dart';
import '../../data/services/portal_api.dart';

class PortalFormScreen extends ConsumerStatefulWidget {
  const PortalFormScreen({super.key, required this.budowaId});

  final int budowaId;

  @override
  ConsumerState<PortalFormScreen> createState() => _PortalFormScreenState();
}

class _PortalFormScreenState extends ConsumerState<PortalFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nazwaCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telefonCtrl = TextEditingController();

  bool _pokazujFaktury = true;
  bool _pokazujZdjecia = true;
  bool _pokazujHarmonogram = true;
  bool _pokazujKosztorys = false;
  DateTime? _wygasa;
  bool _saving = false;

  @override
  void dispose() {
    _nazwaCtrl.dispose();
    _emailCtrl.dispose();
    _telefonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nowy portal klienta')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Klient
            _SectionLabel('Dane klienta'),
            const SizedBox(height: 10),
            TextFormField(
              controller: _nazwaCtrl,
              decoration: const InputDecoration(labelText: 'Imię i nazwisko / Firma *'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Wymagane' : null,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email (opcjonalnie)'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _telefonCtrl,
              decoration: const InputDecoration(labelText: 'Telefon (opcjonalnie)'),
              keyboardType: TextInputType.phone,
            ),

            const SizedBox(height: 24),

            // Uprawnienia
            _SectionLabel('Co widzi klient'),
            const SizedBox(height: 4),
            SwitchListTile(
              title: const Text('Faktury'),
              subtitle: const Text('Numery, kwoty, terminy płatności'),
              value: _pokazujFaktury,
              onChanged: (v) => setState(() => _pokazujFaktury = v),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('Zdjęcia z budowy'),
              subtitle: const Text('Galeria z dziennika budowy'),
              value: _pokazujZdjecia,
              onChanged: (v) => setState(() => _pokazujZdjecia = v),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('Harmonogram'),
              subtitle: const Text('Etapy i terminy'),
              value: _pokazujHarmonogram,
              onChanged: (v) => setState(() => _pokazujHarmonogram = v),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('Kosztorys'),
              subtitle: const Text('Zestawienie kosztów'),
              value: _pokazujKosztorys,
              onChanged: (v) => setState(() => _pokazujKosztorys = v),
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: 24),

            // Wygasanie
            _SectionLabel('Ważność linku'),
            const SizedBox(height: 10),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_month_outlined),
              title: Text(_wygasa == null
                  ? 'Bezterminowo'
                  : 'Wygasa ${_wygasa!.day}.${_wygasa!.month.toString().padLeft(2,'0')}.${_wygasa!.year}'),
              subtitle: const Text('Dotknij, aby ustawić datę wygaśnięcia'),
              trailing: _wygasa != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _wygasa = null),
                    )
                  : null,
              onTap: _pickDate,
            ),

            const SizedBox(height: 32),

            FilledButton(
              onPressed: _saving ? null : _zapisz,
              child: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Utwórz link i skopiuj'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _wygasa = picked);
  }

  Future<void> _zapisz() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final portal = PortalKlientaModel(
        id: 0,
        budowaId: widget.budowaId,
        token: '',
        nazwaKlienta: _nazwaCtrl.text.trim(),
        emailKlienta: _emailCtrl.text.trim(),
        telefonKlienta: _telefonCtrl.text.trim(),
        pokazujFaktury: _pokazujFaktury,
        pokazujZdjecia: _pokazujZdjecia,
        pokazujHarmonogram: _pokazujHarmonogram,
        pokazujKosztorys: _pokazujKosztorys,
        wygasa: _wygasa != null
            ? '${_wygasa!.year}-${_wygasa!.month.toString().padLeft(2,'0')}-${_wygasa!.day.toString().padLeft(2,'0')}'
            : null,
      );

      final result = await ref.read(portalApiProvider).create(portal);
      if (mounted) Navigator.pop(context, result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Błąd: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
}
