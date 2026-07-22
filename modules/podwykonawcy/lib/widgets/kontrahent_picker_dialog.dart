import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import '../data/models/podwykonawcy_model.dart';
import '../data/providers/podwykonawcy_provider.dart';
import '../data/services/podwykonawcy_api.dart';

enum _Mode { pickExisting, createNew }

/// Dialog wzorowany na AddViewerDialog z CRM.
/// Zwraca KontrahentModel (wybrany lub nowo utworzony).
class KontrahentPickerDialog extends ConsumerStatefulWidget {
  const KontrahentPickerDialog({super.key});

  static Future<KontrahentModel?> show(BuildContext context) =>
      showDialog<KontrahentModel>(
        context: context,
        builder: (_) => const KontrahentPickerDialog(),
      );

  @override
  ConsumerState<KontrahentPickerDialog> createState() =>
      _KontrahentPickerDialogState();
}

class _KontrahentPickerDialogState
    extends ConsumerState<KontrahentPickerDialog> {
  _Mode _mode = _Mode.pickExisting;

  // --- pick existing ---
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  KontrahentModel? _selected;

  // --- create new ---
  final _formKey = GlobalKey<FormState>();
  final _imieCtrl = TextEditingController();
  final _nazwiskoCtrl = TextEditingController();
  final _firmaCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telefonCtrl = TextEditingController();
  final _nipCtrl = TextEditingController();
  BranzaTyp? _branza;
  bool _saving = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    _imieCtrl.dispose();
    _nazwiskoCtrl.dispose();
    _firmaCtrl.dispose();
    _emailCtrl.dispose();
    _telefonCtrl.dispose();
    _nipCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(kontrahentPickerProvider.notifier).szukaj(v);
    });
  }

  Future<void> _saveNew() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final k = await podwykonawcyApi.utworzKontrahenta({
        'imie': _imieCtrl.text.trim(),
        'nazwisko': _nazwiskoCtrl.text.trim(),
        'firma': _firmaCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'telefon': _telefonCtrl.text.trim(),
        'nip': _nipCtrl.text.trim(),
        if (_branza != null) 'branza': _branza!.name,
      });
      if (mounted) Navigator.pop(context, k);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('BĹ‚Ä…d: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 640),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header + mode toggle
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Dodaj podwykonawcÄ™',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Tabs â€” wybierz / nowy
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SegmentedButton<_Mode>(
                segments: const [
                  ButtonSegment(
                    value: _Mode.pickExisting,
                    icon: Icon(Icons.search, size: 18),
                    label: Text('Wyszukaj'),
                  ),
                  ButtonSegment(
                    value: _Mode.createNew,
                    icon: Icon(Icons.person_add_outlined, size: 18),
                    label: Text('Nowy kontakt'),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (s) =>
                    setState(() => _mode = s.first),
              ),
            ),

            const Divider(height: 1),

            // Body
            Flexible(
              child: _mode == _Mode.pickExisting
                  ? _PickExistingBody(
                      searchCtrl: _searchCtrl,
                      selected: _selected,
                      onSearchChanged: _onSearchChanged,
                      onSelect: (k) => setState(() => _selected = k),
                    )
                  : _CreateNewBody(
                      formKey: _formKey,
                      imieCtrl: _imieCtrl,
                      nazwiskoCtrl: _nazwiskoCtrl,
                      firmaCtrl: _firmaCtrl,
                      emailCtrl: _emailCtrl,
                      telefonCtrl: _telefonCtrl,
                      nipCtrl: _nipCtrl,
                      branza: _branza,
                      onBranzaChanged: (b) => setState(() => _branza = b),
                    ),
            ),

            const Divider(height: 1),

            // Actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Anuluj'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _mode == _Mode.pickExisting
                        ? (_selected != null
                            ? () => Navigator.pop(context, _selected)
                            : null)
                        : (_saving ? null : _saveNew),
                    child: _saving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_mode == _Mode.pickExisting
                            ? 'Dodaj'
                            : 'UtwĂłrz i dodaj'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- Pick existing body --------------------------------------------------

class _PickExistingBody extends ConsumerWidget {
  final TextEditingController searchCtrl;
  final KontrahentModel? selected;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<KontrahentModel> onSelect;

  const _PickExistingBody({
    required this.searchCtrl,
    required this.selected,
    required this.onSearchChanged,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(kontrahentPickerProvider);
    final theme = ref.watch(themeColorsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: searchCtrl,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Szukaj po nazwie, firmie, telefonie...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              isDense: true,
            ),
            onChanged: onSearchChanged,
          ),
        ),
        Flexible(
          child: async.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('BĹ‚Ä…d: $e')),
            data: (lista) {
              if (lista.isEmpty && searchCtrl.text.isEmpty) {
                return Center(
                  child: Text(
                    'Wpisz nazwÄ™ lub telefon podwykonawcy',
                    style: TextStyle(color: theme.textColor.withAlpha(120)),
                  ),
                );
              }
              if (lista.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_off,
                          size: 40, color: theme.textColor.withAlpha(100)),
                      const SizedBox(height: 8),
                      const Text('Brak wynikĂłw'),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: lista.length,
                itemBuilder: (ctx, i) {
                  final k = lista[i];
                  final isSelected = selected?.id == k.id;
                  return ListTile(
                    selected: isSelected,
                    selectedTileColor: theme.themeColor.withAlpha(40),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    leading: _KontrahentAvatar(kontrahent: k, theme: theme),
                    title: Text(k.displayName),
                    subtitle: Text([
                      if (k.branza != null) k.branza!.label,
                      if (k.telefon.isNotEmpty) k.telefon,
                    ].join('  â€˘  ')),
                    trailing: isSelected
                        ? Icon(Icons.check_circle,
                            color: theme.themeColor)
                        : null,
                    onTap: () => onSelect(k),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ---- Create new body ----------------------------------------------------

class _CreateNewBody extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController imieCtrl;
  final TextEditingController nazwiskoCtrl;
  final TextEditingController firmaCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController telefonCtrl;
  final TextEditingController nipCtrl;
  final BranzaTyp? branza;
  final ValueChanged<BranzaTyp?> onBranzaChanged;

  const _CreateNewBody({
    required this.formKey,
    required this.imieCtrl,
    required this.nazwiskoCtrl,
    required this.firmaCtrl,
    required this.emailCtrl,
    required this.telefonCtrl,
    required this.nipCtrl,
    required this.branza,
    required this.onBranzaChanged,
  });

  @override
  Widget build(BuildContext context) => Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: imieCtrl,
                  decoration: const InputDecoration(
                    labelText: 'ImiÄ™',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: nazwiskoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nazwisko',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            TextFormField(
              controller: firmaCtrl,
              decoration: const InputDecoration(
                labelText: 'Firma (opcjonalnie)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: telefonCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Telefon',
                border: OutlineInputBorder(),
                isDense: true,
                prefixIcon: Icon(Icons.phone_outlined, size: 18),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Wymagany' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'E-mail (opcjonalnie)',
                border: OutlineInputBorder(),
                isDense: true,
                prefixIcon: Icon(Icons.email_outlined, size: 18),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: nipCtrl,
              decoration: const InputDecoration(
                labelText: 'NIP (opcjonalnie)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<BranzaTyp>(
              value: branza,
              decoration: const InputDecoration(
                labelText: 'BranĹĽa',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              hint: const Text('Wybierz branĹĽÄ™'),
              items: BranzaTyp.values
                  .map((b) => DropdownMenuItem(
                        value: b,
                        child: Text('${b.emoji}  ${b.label}'),
                      ))
                  .toList(),
              onChanged: onBranzaChanged,
            ),
          ],
        ),
      );
}

// ---- Avatar -------------------------------------------------------------

class _KontrahentAvatar extends StatelessWidget {
  final KontrahentModel kontrahent;
  final ThemeColors theme;
  const _KontrahentAvatar({required this.kontrahent, required this.theme});

  String get _initials {
    final n = kontrahent.displayName;
    final parts = n.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (n.isNotEmpty) return n[0].toUpperCase();
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    if (kontrahent.avatarUrl != null) {
      return CircleAvatar(
        backgroundImage: NetworkImage(kontrahent.avatarUrl!),
      );
    }
    return CircleAvatar(
      backgroundColor: theme.themeColor.withAlpha(60),
      child: Text(_initials,
          style: TextStyle(color: theme.themeColor, fontWeight: FontWeight.w700)),
    );
  }
}

