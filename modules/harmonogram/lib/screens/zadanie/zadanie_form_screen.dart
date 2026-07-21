import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/platform/navigation_service.dart';
import '../../data/models/harmonogram_model.dart';
import '../../data/providers/harmonogram_provider.dart';

class ZadanieFormScreen extends ConsumerStatefulWidget {
  final int budowaId;
  final String budowaNazwa;
  final int? zadanieId;
  final int? etapId;

  const ZadanieFormScreen({
    super.key,
    required this.budowaId,
    required this.budowaNazwa,
    this.zadanieId,
    this.etapId,
  });

  @override
  ConsumerState<ZadanieFormScreen> createState() => _ZadanieFormScreenState();
}

class _ZadanieFormScreenState extends ConsumerState<ZadanieFormScreen> {
  late final _sideMenuKey = GlobalKey<SideMenuState>();
  final _formKey = GlobalKey<FormState>();
  final _nazwaCtrl = TextEditingController();
  final _opisCtrl = TextEditingController();
  final _budzetCtrl = TextEditingController(text: '0');
  final _dniCtrl = TextEditingController(text: '7');

  StatusZadania _status = StatusZadania.planowane;
  DateTime? _dataStart;
  DateTime? _dataKoniec;
  int? _etapId;

  @override
  void initState() {
    super.initState();
    _etapId = widget.etapId;
  }

  @override
  void dispose() {
    _nazwaCtrl.dispose();
    _opisCtrl.dispose();
    _budzetCtrl.dispose();
    _dniCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_dataStart ?? DateTime.now()) : (_dataKoniec ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _dataStart = picked;
        if (_dataKoniec != null && _dataKoniec!.isBefore(picked)) {
          _dataKoniec = picked.add(Duration(days: int.tryParse(_dniCtrl.text) ?? 7));
        }
      } else {
        _dataKoniec = picked;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final payload = <String, dynamic>{
      'nazwa': _nazwaCtrl.text.trim(),
      'opis': _opisCtrl.text.trim(),
      'status': _status.name,
      'budzet': double.tryParse(_budzetCtrl.text) ?? 0,
      'czas_trwania_dni': int.tryParse(_dniCtrl.text) ?? 7,
      if (_etapId != null) 'etap': _etapId,
      if (_dataStart != null) 'data_start': _dataStart!.toIso8601String().split('T').first,
      if (_dataKoniec != null) 'data_koniec': _dataKoniec!.toIso8601String().split('T').first,
    };
    final result = await ref.read(zadanieFormProvider.notifier).zapisz(
      budowaId: widget.budowaId, zadanieId: widget.zadanieId, payload: payload);
    if (result != null && mounted) {
      ref.invalidate(timelineProvider(widget.budowaId));
      ref.read(navigationService).beamPop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);
    final formState = ref.watch(zadanieFormProvider);

    InputDecoration dec(String label) => InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: theme.textColor.withAlpha(160)),
      filled: true,
      fillColor: theme.textFieldColor,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: theme.bordercolor.withAlpha(60))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: theme.bordercolor.withAlpha(60))),
      isDense: true,
    );

    return BarManager(
      sideMenuKey: _sideMenuKey,
      appModule: AppModule.budkon,
      verticalButtonsPc: formState.isLoading
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: theme.themeColor)))
          : TextButton(
              onPressed: _submit,
              child: Text('Zapisz', style: TextStyle(color: theme.themeColor, fontWeight: FontWeight.w700)),
            ),
      childPc: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nazwaCtrl,
              style: TextStyle(color: theme.textColor),
              decoration: dec('Nazwa zadania'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Wymagane' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _opisCtrl,
              maxLines: 3,
              style: TextStyle(color: theme.textColor),
              decoration: dec('Opis (opcjonalny)'),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<StatusZadania>(
              value: _status,
              dropdownColor: theme.popupcontainercolor,
              style: TextStyle(color: theme.textColor),
              decoration: dec('Status'),
              items: StatusZadania.values.map((s) =>
                DropdownMenuItem(value: s, child: Text(s.label, style: TextStyle(color: theme.textColor)))).toList(),
              onChanged: (v) => setState(() => _status = v!),
            ),
            const SizedBox(height: 16),

            Row(children: [
              Expanded(child: _DateField(label: 'Data start', date: _dataStart, onTap: () => _pickDate(true), theme: theme)),
              const SizedBox(width: 12),
              Expanded(child: _DateField(label: 'Data koniec', date: _dataKoniec, onTap: () => _pickDate(false), theme: theme)),
            ]),
            const SizedBox(height: 16),

            Row(children: [
              Expanded(child: TextFormField(
                controller: _dniCtrl,
                keyboardType: TextInputType.number,
                style: TextStyle(color: theme.textColor),
                decoration: dec('Czas trwania (dni)'),
              )),
              const SizedBox(width: 12),
              Expanded(child: TextFormField(
                controller: _budzetCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: theme.textColor),
                decoration: dec('Budżet (PLN)'),
              )),
            ]),

            if (formState.hasError) ...[
              const SizedBox(height: 16),
              Text(formState.error.toString(), style: const TextStyle(color: Colors.red)),
            ],

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final ThemeColors theme;

  const _DateField({required this.label, required this.date, required this.onTap, required this.theme});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: theme.textColor.withAlpha(160)),
        filled: true,
        fillColor: theme.textFieldColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: theme.bordercolor.withAlpha(60))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: theme.bordercolor.withAlpha(60))),
        isDense: true,
        suffixIcon: Icon(Icons.calendar_today, size: 18, color: theme.themeColor),
      ),
      child: Text(
        date != null ? '${date!.day.toString().padLeft(2, '0')}.${date!.month.toString().padLeft(2, '0')}.${date!.year}' : '—',
        style: TextStyle(color: theme.textColor),
      ),
    ),
  );
}
