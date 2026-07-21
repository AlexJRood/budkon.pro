import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../data/models/budowa_model.dart';
import '../../data/providers/budowa_provider.dart';

class BudowaFormScreen extends ConsumerStatefulWidget {
  const BudowaFormScreen({super.key, this.existing});
  final BudowaModel? existing;

  @override
  ConsumerState<BudowaFormScreen> createState() => _BudowaFormScreenState();
}

class _BudowaFormScreenState extends ConsumerState<BudowaFormScreen> {
  late final _sideMenuKey = GlobalKey<SideMenuState>();

  final _formKey = GlobalKey<FormState>();
  final _nazwaCtrl = TextEditingController();
  final _adresCtrl = TextEditingController();
  final _budzetCtrl = TextEditingController();

  StatusBudowy _status = StatusBudowy.oferta;
  DateTime? _dataRozpoczecia;
  DateTime? _dataZakonczenia;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nazwaCtrl.text = e.nazwa;
      _adresCtrl.text = e.adres;
      _budzetCtrl.text = e.budzet > 0 ? e.budzet.toStringAsFixed(0) : '';
      _status = e.status;
      _dataRozpoczecia = e.dataRozpoczecia;
      _dataZakonczenia = e.dataPlanowanegZakonczenia;
    }
  }

  @override
  void dispose() {
    _nazwaCtrl.dispose();
    _adresCtrl.dispose();
    _budzetCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);
    final saving = ref.watch(budowaFormProvider).isLoading;

    return BarManager(
      sideMenuKey: _sideMenuKey,
      appModule: AppModule.budkon,
      verticalButtonsPc: _isEdit
          ? IconButton(
              icon: Icon(Icons.delete_outline, color: theme.textColor),
              tooltip: 'Usuń',
              onPressed: saving ? null : _confirmDelete,
            )
          : null,
      childPc: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            _Field(
                label: 'Nazwa projektu *',
                controller: _nazwaCtrl,
                validator: (v) => (v == null || v.isEmpty) ? 'Pole wymagane' : null,
                hint: 'np. Dom jednorodzinny Kowalski',
                theme: theme),
            SizedBox(height: 12.h),
            _Field(
                label: 'Adres',
                controller: _adresCtrl,
                hint: 'ul. Leśna 5, Kraków',
                theme: theme),
            SizedBox(height: 12.h),
            _Field(
              label: 'Budżet (zł)',
              controller: _budzetCtrl,
              hint: '450000',
              keyboardType: TextInputType.number,
              theme: theme,
              validator: (v) {
                if (v != null && v.isNotEmpty && double.tryParse(v) == null)
                  return 'Podaj liczbę';
                return null;
              },
            ),
            SizedBox(height: 16.h),
            Text('Status',
                style: TextStyle(
                    color: theme.textColor.withAlpha(180),
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
            SizedBox(height: 6.h),
            SegmentedButton<StatusBudowy>(
              segments: StatusBudowy.values
                  .map((s) => ButtonSegment(value: s, label: Text(s.label)))
                  .toList(),
              selected: {_status},
              onSelectionChanged: (v) => setState(() => _status = v.first),
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                textStyle: WidgetStateProperty.all(TextStyle(fontSize: 11.sp)),
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: _DatePicker(
                    label: 'Data rozpoczęcia',
                    value: _dataRozpoczecia,
                    theme: theme,
                    onChanged: (d) => setState(() => _dataRozpoczecia = d),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _DatePicker(
                    label: 'Planowane zakończenie',
                    value: _dataZakonczenia,
                    theme: theme,
                    onChanged: (d) => setState(() => _dataZakonczenia = d),
                  ),
                ),
              ],
            ),
            SizedBox(height: 32.h),
            FilledButton(
              onPressed: saving ? null : _save,
              style: FilledButton.styleFrom(backgroundColor: theme.themeColor),
              child: saving
                  ? SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: theme.buttonTextColor))
                  : Text(_isEdit ? 'Zapisz zmiany' : 'Utwórz budowę',
                      style: TextStyle(color: theme.buttonTextColor)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final budowa = BudowaModel(
      id: widget.existing?.id ?? 0,
      nazwa: _nazwaCtrl.text.trim(),
      adres: _adresCtrl.text.trim(),
      status: _status,
      budzet: double.tryParse(_budzetCtrl.text) ?? 0,
      dataRozpoczecia: _dataRozpoczecia,
      dataPlanowanegZakonczenia: _dataZakonczenia,
    );
    final result = await ref.read(budowaFormProvider.notifier).save(budowa);
    if (!mounted) return;
    if (result != null) {
      ref.invalidate(budowaListProvider);
      ref.read(navigationService).beamPop();
    } else {
      final err = ref.read(budowaFormProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Błąd: ${err ?? "Nie udało się zapisać"}'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Usuń budowę'),
        content: Text('Czy na pewno chcesz usunąć "${widget.existing!.nazwa}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false), child: const Text('Anuluj')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await ref.read(budowaFormProvider.notifier).delete(widget.existing!.id);
      if (mounted) {
        ref.invalidate(budowaListProvider);
        ref.read(navigationService).beamPop();
      }
    }
  }
}

class _Field extends StatelessWidget {
  const _Field(
      {required this.label,
      required this.controller,
      required this.theme,
      this.hint,
      this.validator,
      this.keyboardType});

  final String label;
  final TextEditingController controller;
  final ThemeColors theme;
  final String? hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: theme.textColor.withAlpha(180),
                fontSize: 12,
                fontWeight: FontWeight.w500)),
        SizedBox(height: 6.h),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          style: TextStyle(color: theme.textColor),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: theme.textColor.withAlpha(80)),
            filled: true,
            fillColor: theme.textFieldColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: theme.bordercolor.withAlpha(60)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: theme.bordercolor.withAlpha(60)),
            ),
            isDense: true,
          ),
        ),
      ],
    );
  }
}

class _DatePicker extends StatelessWidget {
  const _DatePicker(
      {required this.label,
      this.value,
      required this.onChanged,
      required this.theme});
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final ThemeColors theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: theme.textColor.withAlpha(180),
                fontSize: 12,
                fontWeight: FontWeight.w500)),
        SizedBox(height: 6.h),
        OutlinedButton.icon(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2035),
            );
            onChanged(picked);
          },
          icon: Icon(Icons.calendar_today, size: 16, color: theme.themeColor),
          label: Text(
            value != null
                ? '${value!.day}.${value!.month}.${value!.year}'
                : 'Wybierz datę',
            style: TextStyle(fontSize: 13.sp, color: theme.textColor),
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: Size(double.infinity, 40.h),
            alignment: Alignment.centerLeft,
            side: BorderSide(color: theme.bordercolor.withAlpha(80)),
          ),
        ),
      ],
    );
  }
}
