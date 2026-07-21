import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/platform/navigation_service.dart';
import '../../data/models/pracownicy_model.dart';
import '../../data/providers/pracownicy_provider.dart';
import '../../data/services/pracownicy_api.dart';

class NowyPracownikScreen extends ConsumerStatefulWidget {
  const NowyPracownikScreen({super.key});

  @override
  ConsumerState<NowyPracownikScreen> createState() =>
      _NowyPracownikScreenState();
}

class _NowyPracownikScreenState extends ConsumerState<NowyPracownikScreen> {
  late final _sideMenuKey = GlobalKey<SideMenuState>();
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
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);

    InputDecoration dec(String label, {Widget? prefix, String? suffix, String? helper}) =>
        InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: theme.textColor.withAlpha(160)),
          filled: true,
          fillColor: theme.textFieldColor,
          prefixIcon: prefix,
          suffixText: suffix,
          helperText: helper,
          border: OutlineInputBorder(
              borderSide: BorderSide(color: theme.bordercolor.withAlpha(60))),
          enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: theme.bordercolor.withAlpha(60))),
          isDense: true,
        );

    return BarManager(
      sideMenuKey: _sideMenuKey,
      appModule: AppModule.budkon,
      childPc: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _imieCtrl,
                  style: TextStyle(color: theme.textColor),
                  decoration: dec('Imię *'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Wymagane' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _nazwiskoCtrl,
                  style: TextStyle(color: theme.textColor),
                  decoration: dec('Nazwisko *'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Wymagane' : null,
                ),
              ),
            ]),
            const SizedBox(height: 12),
            TextFormField(
              controller: _telefonCtrl,
              keyboardType: TextInputType.phone,
              style: TextStyle(color: theme.textColor),
              decoration: dec('Telefon',
                  prefix: Icon(Icons.phone_outlined,
                      color: theme.textColor.withAlpha(150))),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: theme.textColor),
              decoration: dec('E-mail (opcjonalnie)',
                  prefix: Icon(Icons.email_outlined,
                      color: theme.textColor.withAlpha(150))),
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<Specjalizacja>(
              value: _spec,
              dropdownColor: theme.popupcontainercolor,
              style: TextStyle(color: theme.textColor),
              decoration: dec('Główna specjalizacja'),
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
              dropdownColor: theme.popupcontainercolor,
              style: TextStyle(color: theme.textColor),
              decoration: dec('Typ umowy'),
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
              style: TextStyle(color: theme.textColor),
              decoration: dec(
                'Stawka godzinowa PLN/h (opcjonalnie)',
                suffix: 'PLN/h',
                helper: 'Można dodać później w profilu',
              ),
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
                  : const Text('Zapisz pracownika'),
            ),
          ],
        ),
      ),
    );
  }

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

      final stawka = double.tryParse(
          _stawkaCtrl.text.replaceAll(',', '.'));
      if (stawka != null) {
        await pracownicyApi.dodajStawke(
          p.id,
          stawka,
          DateTime.now().toIso8601String().substring(0, 10),
        );
      }

      ref.invalidate(pracownicyProvider);
      if (mounted) ref.read(navigationService).beamPop();
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Błąd: $e')));
      }
    }
  }
}
