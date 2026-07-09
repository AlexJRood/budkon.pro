import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  AutoUzupelnijParams get _autoParams => AutoUzupelnijParams(
        budowaId: widget.budowaId,
      );

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
        _pracownicyCtrl.text =
            data.liczbaPracownikowPoprzedni.toString();
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
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final autoAsync = ref.watch(autoUzupelnijProvider(_autoParams));
    final formState = ref.watch(wpisFormProvider);

    autoAsync.whenData(_applyAutoData);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.wpisId == null ? 'Nowy wpis' : 'Edytuj wpis'),
        actions: [
          if (formState.isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _submit,
              child: const Text('Zapisz'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Auto-uzupełnianie — status
            if (autoAsync.isLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: _AutoFillBanner(loading: true),
              )
            else if (_autoLoaded)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: _AutoFillBanner(loading: false),
              ),

            // Pogoda
            _SectionHeader('Pogoda'),
            _PogodaSelector(
              selected: _pogoda,
              temperatura: _temperatura,
              onChanged: (p) => setState(() => _pogoda = p),
            ),
            const SizedBox(height: 8),
            if (_pogoda != null)
              TextFormField(
                initialValue: _temperatura?.toStringAsFixed(1) ?? '',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Temperatura (°C)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) =>
                    setState(() => _temperatura = double.tryParse(v)),
              ),

            const SizedBox(height: 20),
            // Etap
            _SectionHeader('Etap budowy'),
            if (_etapNazwa != null)
              Chip(
                avatar: const Icon(Icons.construction, size: 16),
                label: Text(_etapNazwa!),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () =>
                    setState(() {
                      _etapId = null;
                      _etapNazwa = null;
                    }),
              )
            else
              Text(
                'Brak aktywnego etapu',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.outline),
              ),

            const SizedBox(height: 20),
            // Opis
            _SectionHeader('Opis dnia'),
            TextFormField(
              controller: _opisCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText:
                    'Co dzisiaj zrobiono? Jakie prace były realizowane...',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Wymagane' : null,
            ),

            const SizedBox(height: 20),
            // Pracownicy
            _SectionHeader('Zespół'),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _pracownicyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Liczba pracowników',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _godzinyCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Łączne godziny pracy',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),

            // Obecności
            if (_obecnosci.isNotEmpty) ...[
              const SizedBox(height: 12),
              ..._obecnosci.map((o) => _ObecnoscTile(o)),
            ],
            TextButton.icon(
              icon: const Icon(Icons.person_add_outlined, size: 18),
              label: const Text('Dodaj pracownika'),
              onPressed: _dodajObecnosc,
            ),

            const SizedBox(height: 20),
            // Uwagi
            _SectionHeader('Uwagi / problemy'),
            TextFormField(
              controller: _uwagiCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Dodatkowe uwagi, problemy, opóźnienia...',
                border: OutlineInputBorder(),
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

// ---- Pomocnicze widgety formularza ------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(color: Theme.of(context).colorScheme.primary),
        ),
      );
}

class _AutoFillBanner extends StatelessWidget {
  final bool loading;
  const _AutoFillBanner({required this.loading});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          if (loading)
            const SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            const Icon(Icons.auto_awesome, size: 16),
          const SizedBox(width: 8),
          Text(
            loading
                ? 'Pobieranie pogody i etapu...'
                : 'Dane uzupełnione automatycznie',
            style: Theme.of(context).textTheme.labelMedium,
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

  const _PogodaSelector({
    required this.selected,
    required this.temperatura,
    required this.onChanged,
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
        );
      }).toList(),
    );
  }
}

class _ObecnoscTile extends StatelessWidget {
  final ObecnoscModel obecnosc;
  const _ObecnoscTile(this.obecnosc);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 16,
        child: Text(obecnosc.imieNazwisko[0]),
      ),
      title: Text(obecnosc.imieNazwisko),
      subtitle: Text(obecnosc.rola),
      trailing: Text(
        '${obecnosc.godziny.toStringAsFixed(0)} h',
        style: Theme.of(context).textTheme.labelMedium,
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
