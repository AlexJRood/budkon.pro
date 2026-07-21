import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:intl/intl.dart';
import '../../data/models/dziennik_model.dart';
import '../../data/providers/dziennik_provider.dart';
import '../../widgets/pogoda_badge.dart';

class DziennikFormScreen extends ConsumerStatefulWidget {
  final int budowaId;
  final String budowaNazwa;
  final int? wpisId;

  const DziennikFormScreen({
    super.key,
    required this.budowaId,
    required this.budowaNazwa,
    this.wpisId,
  });

  @override
  ConsumerState<DziennikFormScreen> createState() => _DziennikFormScreenState();
}

class _DziennikFormScreenState extends ConsumerState<DziennikFormScreen> {
  late final _sideMenuKey = GlobalKey<SideMenuState>();

  final _formKey = GlobalKey<FormState>();
  final _opisCtrl = TextEditingController();
  final _uwagiCtrl = TextEditingController();
  final _pracownicyCtrl = TextEditingController(text: '0');
  final _godzinyCtrl = TextEditingController(text: '8');

  PogodaTyp? _pogoda;
  double? _temperatura;
  int? _etapId;
  String? _etapNazwa;
  bool _autoLoaded = false;
  List<ObecnoscModel> _obecnosci = [];

  AutoUzupelnijParams get _autoParams => AutoUzupelnijParams(budowaId: widget.budowaId);

  @override
  void dispose() {
    _opisCtrl.dispose();
    _uwagiCtrl.dispose();
    _pracownicyCtrl.dispose();
    _godzinyCtrl.dispose();
    super.dispose();
  }

  void _applyAutoData(AutoUzupelnijData data) {
    if (_autoLoaded) return;
    _autoLoaded = true;
    setState(() {
      _pogoda = data.pogoda;
      _temperatura = data.temperatura;
      _etapId = data.etapId;
      _etapNazwa = data.etapNazwa;
      if (data.liczbaPracownikowPoprzedni > 0) {
        _pracownicyCtrl.text = data.liczbaPracownikowPoprzedni.toString();
      }
      if (data.obecnosciPoprzednie.isNotEmpty) {
        _obecnosci = List.of(data.obecnosciPoprzednie);
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final payload = <String, dynamic>{
      'budowa_id': widget.budowaId,
      'opis': _opisCtrl.text.trim(),
      'uwagi': _uwagiCtrl.text.trim(),
      'liczba_pracownikow': int.tryParse(_pracownicyCtrl.text) ?? 0,
      'godziny_pracy': double.tryParse(_godzinyCtrl.text) ?? 8,
      if (_pogoda != null) 'pogoda': _pogoda!.name,
      if (_temperatura != null) 'temperatura': _temperatura,
      if (_etapId != null) 'etap_id': _etapId,
      'obecnosci': _obecnosci.map((o) => o.toJson()).toList(),
    };

    final result = await ref
        .read(wpisFormProvider.notifier)
        .zapisz(budowaId: widget.budowaId, wpisId: widget.wpisId, payload: payload);

    if (result != null && mounted) {
      ref.invalidate(dziennikListProvider(widget.budowaId));
      if (widget.wpisId != null) ref.invalidate(wpisDetailProvider(widget.wpisId!));
      ref.read(navigationService).beamPop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);
    final autoAsync = ref.watch(autoUzupelnijProvider(_autoParams));
    final formState = ref.watch(wpisFormProvider);

    autoAsync.whenData(_applyAutoData);

    return BarManager(
      sideMenuKey: _sideMenuKey,
      appModule: AppModule.budkon,
      verticalButtonsPc: formState.isLoading
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : TextButton(
              onPressed: _submit,
              child: Text('Zapisz',
                  style:
                      TextStyle(color: theme.themeColor, fontWeight: FontWeight.w700)),
            ),
      childPc: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (autoAsync.isLoading)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _AutoFillBanner(loading: true, theme: theme),
              )
            else if (_autoLoaded)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _AutoFillBanner(loading: false, theme: theme),
              ),

            _SectionHeader('Pogoda', theme: theme),
            _PogodaSelector(
              selected: _pogoda,
              temperatura: _temperatura,
              onChanged: (p) => setState(() => _pogoda = p),
              theme: theme,
            ),
            const SizedBox(height: 8),
            if (_pogoda != null)
              TextFormField(
                initialValue: _temperatura?.toStringAsFixed(1) ?? '',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: theme.textColor),
                decoration: InputDecoration(
                  labelText: 'Temperatura (°C)',
                  labelStyle: TextStyle(color: theme.textColor.withAlpha(160)),
                  filled: true,
                  fillColor: theme.textFieldColor,
                  border: OutlineInputBorder(
                      borderSide: BorderSide(color: theme.bordercolor.withAlpha(60))),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _temperatura = double.tryParse(v)),
              ),

            const SizedBox(height: 20),
            _SectionHeader('Etap budowy', theme: theme),
            if (_etapNazwa != null)
              Chip(
                avatar: const Icon(Icons.construction, size: 16),
                label: Text(_etapNazwa!),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => setState(() {
                  _etapId = null;
                  _etapNazwa = null;
                }),
              )
            else
              Text(
                'Brak aktywnego etapu',
                style: TextStyle(color: theme.textColor.withAlpha(150)),
              ),

            const SizedBox(height: 20),
            _SectionHeader('Opis dnia', theme: theme),
            TextFormField(
              controller: _opisCtrl,
              maxLines: 4,
              style: TextStyle(color: theme.textColor),
              decoration: InputDecoration(
                hintText: 'Co dzisiaj zrobiono? Jakie prace były realizowane...',
                hintStyle: TextStyle(color: theme.textColor.withAlpha(100)),
                filled: true,
                fillColor: theme.textFieldColor,
                border: OutlineInputBorder(
                    borderSide: BorderSide(color: theme.bordercolor.withAlpha(60))),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Wymagane' : null,
            ),

            const SizedBox(height: 20),
            _SectionHeader('Zespół', theme: theme),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _pracownicyCtrl,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: theme.textColor),
                    decoration: InputDecoration(
                      labelText: 'Liczba pracowników',
                      labelStyle: TextStyle(color: theme.textColor.withAlpha(160)),
                      filled: true,
                      fillColor: theme.textFieldColor,
                      border: OutlineInputBorder(
                          borderSide: BorderSide(color: theme.bordercolor.withAlpha(60))),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _godzinyCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(color: theme.textColor),
                    decoration: InputDecoration(
                      labelText: 'Łączne godziny pracy',
                      labelStyle: TextStyle(color: theme.textColor.withAlpha(160)),
                      filled: true,
                      fillColor: theme.textFieldColor,
                      border: OutlineInputBorder(
                          borderSide: BorderSide(color: theme.bordercolor.withAlpha(60))),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),

            if (_obecnosci.isNotEmpty) ...[
              const SizedBox(height: 12),
              ..._obecnosci.map((o) => _ObecnoscTile(o, theme: theme)),
            ],
            TextButton.icon(
              icon: Icon(Icons.person_add_outlined, size: 18, color: theme.themeColor),
              label: Text('Dodaj pracownika', style: TextStyle(color: theme.themeColor)),
              onPressed: _dodajObecnosc,
            ),

            const SizedBox(height: 20),
            _SectionHeader('Uwagi / problemy', theme: theme),
            TextFormField(
              controller: _uwagiCtrl,
              maxLines: 3,
              style: TextStyle(color: theme.textColor),
              decoration: InputDecoration(
                hintText: 'Dodatkowe uwagi, problemy, opóźnienia...',
                hintStyle: TextStyle(color: theme.textColor.withAlpha(100)),
                filled: true,
                fillColor: theme.textFieldColor,
                border: OutlineInputBorder(
                    borderSide: BorderSide(color: theme.bordercolor.withAlpha(60))),
              ),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Future<void> _dodajObecnosc() async {
    final result = await showDialog<ObecnoscModel>(
      context: context,
      builder: (_) => const _ObecnoscDialog(),
    );
    if (result != null) {
      setState(() => _obecnosci = [..._obecnosci, result]);
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  final ThemeColors theme;
  const _SectionHeader(this.text, {required this.theme});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: TextStyle(color: theme.themeColor, fontWeight: FontWeight.w700, fontSize: 12),
        ),
      );
}

class _AutoFillBanner extends StatelessWidget {
  final bool loading;
  final ThemeColors theme;
  const _AutoFillBanner({required this.loading, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.themeColor.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.themeColor.withAlpha(60)),
      ),
      child: Row(
        children: [
          if (loading)
            SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: theme.themeColor),
            )
          else
            Icon(Icons.auto_awesome, size: 16, color: theme.themeColor),
          const SizedBox(width: 8),
          Text(
            loading ? 'Pobieranie pogody i etapu...' : 'Dane uzupełnione automatycznie',
            style: TextStyle(color: theme.textColor, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _PogodaSelector extends StatelessWidget {
  final PogodaTyp? selected;
  final double? temperatura;
  final ValueChanged<PogodaTyp?> onChanged;
  final ThemeColors theme;

  const _PogodaSelector({
    required this.selected,
    required this.temperatura,
    required this.onChanged,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: PogodaTyp.values.map((p) {
        final isSelected = selected == p;
        return FilterChip(
          label: Text('${p.emoji} ${p.label}'),
          selected: isSelected,
          onSelected: (_) => onChanged(isSelected ? null : p),
          showCheckmark: false,
          selectedColor: theme.themeColor.withAlpha(60),
          labelStyle: TextStyle(color: isSelected ? theme.themeColor : theme.textColor),
          backgroundColor: theme.userTile,
          side: BorderSide(color: isSelected ? theme.themeColor : theme.bordercolor.withAlpha(60)),
        );
      }).toList(),
    );
  }
}

class _ObecnoscTile extends StatelessWidget {
  final ObecnoscModel obecnosc;
  final ThemeColors theme;
  const _ObecnoscTile(this.obecnosc, {required this.theme});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: theme.themeColor.withAlpha(40),
        child: Text(obecnosc.imieNazwisko[0],
            style: TextStyle(color: theme.themeColor, fontWeight: FontWeight.w700)),
      ),
      title: Text(obecnosc.imieNazwisko, style: TextStyle(color: theme.textColor)),
      subtitle: Text(obecnosc.rola, style: TextStyle(color: theme.textColor.withAlpha(150))),
      trailing: Text(
        '${obecnosc.godziny.toStringAsFixed(0)} h',
        style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ObecnoscDialog extends StatefulWidget {
  const _ObecnoscDialog();

  @override
  State<_ObecnoscDialog> createState() => _ObecnoscDialogState();
}

class _ObecnoscDialogState extends State<_ObecnoscDialog> {
  final _nameCtrl = TextEditingController();
  final _rolaCtrl = TextEditingController();
  double _godziny = 8;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _rolaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Dodaj pracownika'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Imię i nazwisko',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _rolaCtrl,
            decoration: const InputDecoration(
              labelText: 'Rola / stanowisko',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Godziny: ${_godziny.round()}h'),
              Expanded(
                child: Slider(
                  value: _godziny,
                  min: 1,
                  max: 12,
                  divisions: 11,
                  onChanged: (v) => setState(() => _godziny = v),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Anuluj'),
        ),
        FilledButton(
          onPressed: () {
            if (_nameCtrl.text.isEmpty) return;
            Navigator.pop(
              context,
              ObecnoscModel(
                imieNazwisko: _nameCtrl.text,
                rola: _rolaCtrl.text,
                godziny: _godziny,
              ),
            );
          },
          child: const Text('Dodaj'),
        ),
      ],
    );
  }
}
