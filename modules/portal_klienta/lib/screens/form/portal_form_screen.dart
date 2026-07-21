import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
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
    final theme = ref.read(themeColorsProvider);

    InputDecoration _dec(String label) => InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: theme.textColor.withAlpha(160)),
      filled: true,
      fillColor: theme.textFieldColor,
      border: OutlineInputBorder(
          borderSide: BorderSide(color: theme.bordercolor.withAlpha(60))),
      enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: theme.bordercolor.withAlpha(60))),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: theme.textColor),
        title: Text('Nowy portal klienta', style: TextStyle(color: theme.textColor)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionLabel('Dane klienta', theme: theme),
            const SizedBox(height: 10),
            TextFormField(
              controller: _nazwaCtrl,
              decoration: _dec('Imię i nazwisko / Firma *'),
              style: TextStyle(color: theme.textColor),
              validator: (v) => v == null || v.trim().isEmpty ? 'Wymagane' : null,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtrl,
              decoration: _dec('Email (opcjonalnie)'),
              style: TextStyle(color: theme.textColor),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _telefonCtrl,
              decoration: _dec('Telefon (opcjonalnie)'),
              style: TextStyle(color: theme.textColor),
              keyboardType: TextInputType.phone,
            ),

            const SizedBox(height: 24),

            _SectionLabel('Co widzi klient', theme: theme),
            const SizedBox(height: 4),
            SwitchListTile(
              title: Text('Faktury', style: TextStyle(color: theme.textColor)),
              subtitle: Text('Numery, kwoty, terminy płatności',
                  style: TextStyle(color: theme.textColor.withAlpha(150))),
              value: _pokazujFaktury,
              activeColor: theme.themeColor,
              onChanged: (v) => setState(() => _pokazujFaktury = v),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: Text('Zdjęcia z budowy', style: TextStyle(color: theme.textColor)),
              subtitle: Text('Galeria z dziennika budowy',
                  style: TextStyle(color: theme.textColor.withAlpha(150))),
              value: _pokazujZdjecia,
              activeColor: theme.themeColor,
              onChanged: (v) => setState(() => _pokazujZdjecia = v),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: Text('Harmonogram', style: TextStyle(color: theme.textColor)),
              subtitle: Text('Etapy i terminy',
                  style: TextStyle(color: theme.textColor.withAlpha(150))),
              value: _pokazujHarmonogram,
              activeColor: theme.themeColor,
              onChanged: (v) => setState(() => _pokazujHarmonogram = v),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: Text('Kosztorys', style: TextStyle(color: theme.textColor)),
              subtitle: Text('Zestawienie kosztów',
                  style: TextStyle(color: theme.textColor.withAlpha(150))),
              value: _pokazujKosztorys,
              activeColor: theme.themeColor,
              onChanged: (v) => setState(() => _pokazujKosztorys = v),
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: 24),

            _SectionLabel('Ważność linku', theme: theme),
            const SizedBox(height: 10),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.calendar_month_outlined, color: theme.themeColor),
              title: Text(
                _wygasa == null
                    ? 'Bezterminowo'
                    : 'Wygasa ${_wygasa!.day}.${_wygasa!.month.toString().padLeft(2, '0')}.${_wygasa!.year}',
                style: TextStyle(color: theme.textColor),
              ),
              subtitle: Text('Dotknij, aby ustawić datę wygaśnięcia',
                  style: TextStyle(color: theme.textColor.withAlpha(150))),
              trailing: _wygasa != null
                  ? IconButton(
                      icon: Icon(Icons.clear, color: theme.textColor),
                      onPressed: () => setState(() => _wygasa = null),
                    )
                  : null,
              onTap: _pickDate,
            ),

            const SizedBox(height: 32),

            FilledButton(
              onPressed: _saving ? null : _zapisz,
              style: FilledButton.styleFrom(
                  backgroundColor: theme.themeColor, foregroundColor: theme.buttonTextColor),
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
            ? '${_wygasa!.year}-${_wygasa!.month.toString().padLeft(2, '0')}-${_wygasa!.day.toString().padLeft(2, '0')}'
            : null,
      );

      final result = await ref.read(portalApiProvider).create(portal);
      if (mounted) Navigator.pop(context, result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Błąd: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {required this.theme});
  final String text;
  final ThemeColors theme;

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
          color: theme.textColor.withAlpha(140),
        ),
      );
}
