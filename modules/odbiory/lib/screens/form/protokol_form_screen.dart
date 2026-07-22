import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import '../../data/models/odbiory_model.dart';
import '../../data/services/odbiory_api.dart';

class ProtokolFormScreen extends ConsumerStatefulWidget {
  final int budowaId;
  final int? etapId;

  const ProtokolFormScreen({super.key, required this.budowaId, this.etapId});

  @override
  ConsumerState<ProtokolFormScreen> createState() => _ProtokolFormScreenState();
}

class _ProtokolFormScreenState extends ConsumerState<ProtokolFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tytulCtrl = TextEditingController();
  final _kierownikCtrl = TextEditingController();
  final _inwestorCtrl = TextEditingController();
  final _uwagiCtrl = TextEditingController();

  TypOdbioru _typ = TypOdbioru.etapowy;
  DateTime _data = DateTime.now();
  bool _saving = false;

  // Szablony checklisty
  static const _szablony = {
    'Fundamenty': [
      'Głębokość posadowienia zgodna z projektem',
      'Zbrojenie zgodne z dokumentacją',
      'Beton klasy zgodnej z projektem',
      'Izolacja przeciwwilgociowa wykonana',
      'Warstwowanie fundamentów prawidłowe',
    ],
    'Stan surowy': [
      'Ściany nośne w osiach projektowych',
      'Stropy - grubość i poziom',
      'Otwory drzwiowe i okienne zgodne z projektem',
      'Wieńce żelbetowe wykonane',
      'Kominy murowane prawidłowo',
    ],
    'Instalacje': [
      'Instalacja elektryczna - trasy kablowe',
      'Instalacja wod-kan - spadki i uszczelnienie',
      'Ogrzewanie - próba szczelności',
      'Wentylacja - drożność kanałów',
      'Instalacja gazowa - próba ciśnieniowa',
    ],
    'Wykończenie': [
      'Tynki - równość i grubość',
      'Posadzki - poziom i równość',
      'Stolarka okienna - osadzenie i uszczelnienie',
      'Drzwi - działanie i poziom',
      'Malowanie - jednorodność powłoki',
    ],
  };

  String? _wybranyBszalon;

  @override
  void dispose() {
    _tytulCtrl.dispose();
    _kierownikCtrl.dispose();
    _inwestorCtrl.dispose();
    _uwagiCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final api = ref.read(odbioryApiProvider);
      await api.createProtokol(ProtokołOdbioruModel(
        id: 0,
        budowaId: widget.budowaId,
        etapId: widget.etapId,
        tytul: _tytulCtrl.text.trim(),
        typ: _typ,
        data: _data,
        kierownikImie: _kierownikCtrl.text.trim(),
        inwestorImie: _inwestorCtrl.text.trim(),
        uwagi: _uwagiCtrl.text.trim(),
      ));
      if (mounted) Navigator.pop(context);
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
        title: Text('Nowy protokół odbioru',
            style: TextStyle(color: theme.textColor, fontSize: 15, fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: theme.themeColor))
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
            // ---- Typ odbioru ----
            Text('Typ odbioru',
                style: TextStyle(
                    fontSize: 12, color: theme.textColor.withAlpha(150), fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: TypOdbioru.values.map((t) {
                final selected = _typ == t;
                return ChoiceChip(
                  label: Text('${t.emoji} ${t.label}'),
                  selected: selected,
                  onSelected: (_) => setState(() => _typ = t),
                  selectedColor: theme.themeColor.withAlpha(50),
                  checkmarkColor: theme.themeColor,
                  labelStyle: TextStyle(
                    color: selected ? theme.themeColor : theme.textColor,
                    fontSize: 12,
                  ),
                  side: BorderSide(
                    color: selected ? theme.themeColor : theme.bordercolor.withAlpha(60),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // ---- Tytuł ----
            TextFormField(
              controller: _tytulCtrl,
              style: TextStyle(color: theme.textColor),
              decoration: _inputDecor('Tytuł protokołu *', theme),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Wymagany' : null,
            ),
            const SizedBox(height: 12),

            // ---- Data ----
            InkWell(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _data,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (d != null) setState(() => _data = d);
              },
              child: InputDecorator(
                decoration: _inputDecor('Data odbioru', theme),
                child: Text(
                  '${_data.day}.${_data.month}.${_data.year}',
                  style: TextStyle(color: theme.textColor),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ---- Kierownik / Inwestor ----
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _kierownikCtrl,
                    style: TextStyle(color: theme.textColor),
                    decoration: _inputDecor('Kierownik budowy', theme),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _inwestorCtrl,
                    style: TextStyle(color: theme.textColor),
                    decoration: _inputDecor('Inwestor', theme),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ---- Uwagi ----
            TextFormField(
              controller: _uwagiCtrl,
              style: TextStyle(color: theme.textColor),
              maxLines: 3,
              decoration: _inputDecor('Uwagi ogólne (opcjonalnie)', theme),
            ),
            const SizedBox(height: 20),

            // ---- Szablon checklisty ----
            Text('Szablon checklisty',
                style: TextStyle(
                    fontSize: 12, color: theme.textColor.withAlpha(150), fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Opcjonalnie — wybierz gotowy szablon lub zostaw puste.',
                style: TextStyle(fontSize: 11, color: theme.textColor.withAlpha(100))),
            const SizedBox(height: 8),
            ..._szablony.entries.map((e) => _SzablonTile(
                  nazwa: e.key,
                  punkty: e.value,
                  selected: _wybranyBszalon == e.key,
                  theme: theme,
                  onTap: () =>
                      setState(() => _wybranyBszalon = _wybranyBszalon == e.key ? null : e.key),
                )),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecor(String label, ThemeColors theme) => InputDecoration(
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

class _SzablonTile extends StatelessWidget {
  final String nazwa;
  final List<String> punkty;
  final bool selected;
  final ThemeColors theme;
  final VoidCallback onTap;

  const _SzablonTile({
    required this.nazwa,
    required this.punkty,
    required this.selected,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? theme.themeColor.withAlpha(25) : theme.userTile,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? theme.themeColor : theme.bordercolor.withAlpha(50),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_box : Icons.check_box_outline_blank,
              size: 20,
              color: selected ? theme.themeColor : theme.textColor.withAlpha(80),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nazwa,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.textColor)),
                  Text('${punkty.length} punktów kontrolnych',
                      style: TextStyle(
                          fontSize: 11, color: theme.textColor.withAlpha(120))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
