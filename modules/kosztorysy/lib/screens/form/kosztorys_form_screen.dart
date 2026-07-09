import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../data/models/kosztorys_model.dart';
import '../../data/providers/kosztorysy_provider.dart';

class KosztorysFormScreen extends ConsumerStatefulWidget {
  const KosztorysFormScreen({super.key, this.existing, this.defaultBudowaId});

  final KosztorysListItemModel? existing;
  final int? defaultBudowaId;

  @override
  ConsumerState<KosztorysFormScreen> createState() =>
      _KosztorysFormScreenState();
}

class _KosztorysFormScreenState extends ConsumerState<KosztorysFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nazwaCtrl = TextEditingController();
  final _opisCtrl = TextEditingController();

  StatusKosztorysu _status = StatusKosztorysu.roboczy;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nazwaCtrl.text = e.nazwa;
      _opisCtrl.text = e.opis;
      _status = e.status;
    }
  }

  @override
  void dispose() {
    _nazwaCtrl.dispose();
    _opisCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(kosztorysFormProvider).isLoading;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edytuj kosztorys' : 'Nowy kosztorys'),
        actions: [
          if (_isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: saving ? null : _confirmDelete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            _label(theme, 'Nazwa kosztorysu *'),
            SizedBox(height: 6.h),
            TextFormField(
              controller: _nazwaCtrl,
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Pole wymagane' : null,
              decoration: InputDecoration(
                hintText: 'np. Kosztorys — remont łazienki',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r)),
                isDense: true,
              ),
            ),
            SizedBox(height: 12.h),
            _label(theme, 'Opis / zakres robót'),
            SizedBox(height: 6.h),
            TextFormField(
              controller: _opisCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText:
                    'Krótki opis zakresu — AI użyje tego do generowania pozycji',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r)),
                isDense: true,
              ),
            ),
            SizedBox(height: 16.h),
            _label(theme, 'Status'),
            SizedBox(height: 6.h),
            SegmentedButton<StatusKosztorysu>(
              segments: StatusKosztorysu.values
                  .map((s) => ButtonSegment(value: s, label: Text(s.label)))
                  .toList(),
              selected: {_status},
              onSelectionChanged: (v) =>
                  setState(() => _status = v.first),
              style: ButtonStyle(
                textStyle: WidgetStateProperty.all(
                    TextStyle(fontSize: 12.sp)),
              ),
            ),
            SizedBox(height: 32.h),
            FilledButton(
              onPressed: saving ? null : _save,
              child: saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(_isEdit ? 'Zapisz zmiany' : 'Utwórz kosztorys'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(ThemeData theme, String text) =>
      Text(text, style: theme.textTheme.labelMedium);

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'nazwa': _nazwaCtrl.text.trim(),
      'opis': _opisCtrl.text.trim(),
      'status': _status.apiValue,
      if (widget.defaultBudowaId != null) 'budowa_id': widget.defaultBudowaId,
    };

    final result = await ref
        .read(kosztorysFormProvider.notifier)
        .save(data, existingId: widget.existing?.id);

    if (result != null && mounted) Navigator.of(context).pop(result);
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Usuń kosztorys'),
        content: Text(
            'Czy na pewno chcesz usunąć "${widget.existing!.nazwa}"?\nWszystkie pozycje zostaną utracone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Anuluj')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await ref
          .read(kosztorysFormProvider.notifier)
          .delete(widget.existing!.id);
      if (mounted) Navigator.of(context).pop();
    }
  }
}
