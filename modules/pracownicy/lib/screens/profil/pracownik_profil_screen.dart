import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/pracownicy_model.dart';
import '../../data/providers/pracownicy_provider.dart';
import '../../data/services/pracownicy_api.dart';
import '../../widgets/skill_matrix.dart';

class PracownikProfilScreen extends ConsumerWidget {
  final int pracownikId;
  const PracownikProfilScreen({super.key, required this.pracownikId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pracownikDetailProvider(pracownikId));

    return Scaffold(
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Błąd: $e')),
        data: (p) => _ProfilBody(pracownik: p),
      ),
    );
  }
}

class _ProfilBody extends ConsumerWidget {
  final PracownikDetail pracownik;
  const _ProfilBody({required this.pracownik});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return CustomScrollView(
      slivers: [
        // Header z awatarem
        SliverAppBar(
          expandedHeight: 160,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    cs.primary,
                    cs.primary.withAlpha(160),
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.white.withAlpha(40),
                      child: Text(
                        pracownik.inicjaly,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _edytuj(context, ref),
            ),
          ],
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imię + specjalizacja
                Center(
                  child: Column(
                    children: [
                      Text(
                        pracownik.pelneImie,
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            pracownik.glownaSpecjalizacja.emoji,
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            pracownik.glownaSpecjalizacja.label,
                            style: TextStyle(
                                color: cs.primary,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Stawka + kontakt
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (pracownik.aktualnaStawka != null)
                      _InfoPill(
                        icon: Icons.payments_outlined,
                        label:
                            '${pracownik.aktualnaStawka!.toStringAsFixed(2)} PLN/h',
                        color: cs.primary,
                      ),
                    if (pracownik.telefon.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      _InfoPill(
                        icon: Icons.phone_outlined,
                        label: pracownik.telefon,
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 6),

                // Typ umowy + data zatrudnienia
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.badge_outlined, size: 13, color: cs.outline),
                    const SizedBox(width: 5),
                    Text(
                      _typUmowyLabel(pracownik.typUmowy),
                      style:
                          TextStyle(color: cs.outline, fontSize: 12),
                    ),
                    if (pracownik.dataZatrudnienia != null) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.event, size: 13, color: cs.outline),
                      const SizedBox(width: 4),
                      Text(
                        'od ${pracownik.dataZatrudnienia}',
                        style:
                            TextStyle(color: cs.outline, fontSize: 12),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 28),

                // ── Macierz umiejętności ─────────────────────────────────
                _Section(
                  title: 'Umiejętności i doświadczenie',
                  action: TextButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Dodaj'),
                    onPressed: () => _dodajUmiejetnosc(context, ref),
                  ),
                ),
                const SizedBox(height: 8),

                SkillMatrix(
                  umiejetnosci: pracownik.umiejetnosci,
                  onDodaj: () => _dodajUmiejetnosc(context, ref),
                ),

                const SizedBox(height: 24),

                // ── Historia stawek ──────────────────────────────────────
                if (pracownik.historiaStawek.isNotEmpty) ...[
                  _Section(
                    title: 'Historia stawek',
                    action: TextButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Nowa stawka'),
                      onPressed: () => _dodajStawke(context, ref),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...pracownik.historiaStawek.map(
                    (s) => _StawkaRow(stawka: s),
                  ),
                ] else
                  OutlinedButton.icon(
                    icon: const Icon(Icons.payments_outlined),
                    label: const Text('Ustaw stawkę godzinową'),
                    onPressed: () => _dodajStawke(context, ref),
                  ),

                // ── Uwagi ────────────────────────────────────────────────
                if (pracownik.uwagi.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _Section(title: 'Uwagi'),
                  const SizedBox(height: 8),
                  Text(pracownik.uwagi,
                      style: TextStyle(color: cs.outline)),
                ],

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _typUmowyLabel(String typ) => switch (typ) {
        'umowa_o_prace' => 'Umowa o pracę',
        'umowa_zlecenie' => 'Umowa zlecenie',
        'b2b' => 'B2B',
        'dzieło' => 'Umowa o dzieło',
        _ => typ,
      };

  Future<void> _dodajUmiejetnosc(
      BuildContext context, WidgetRef ref) async {
    final wynik = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _DodajUmiejetnoscDialog(),
    );
    if (wynik == null) return;
    try {
      await pracownicyApi.dodajUmiejetnosc(pracownik.id, wynik);
      ref.invalidate(pracownikDetailProvider(pracownik.id));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Błąd: $e')));
      }
    }
  }

  Future<void> _dodajStawke(BuildContext context, WidgetRef ref) async {
    final wynik = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _DodajStawkeDialog(),
    );
    if (wynik == null) return;
    try {
      await pracownicyApi.dodajStawke(
        pracownik.id,
        wynik['stawka'] as double,
        wynik['data_od'] as String,
      );
      ref.invalidate(pracownikDetailProvider(pracownik.id));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Błąd: $e')));
      }
    }
  }

  Future<void> _edytuj(BuildContext context, WidgetRef ref) async {
    // TODO: formularz edycji podstawowych danych
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edycja w przygotowaniu')),
    );
  }
}

// ── Widgets pomocnicze ──────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final Widget? action;
  const _Section({required this.title, this.action});

  @override
  Widget build(BuildContext context) => Row(children: [
        Text(title,
            style: Theme.of(context).textTheme.titleMedium),
        const Spacer(),
        if (action != null) action!,
      ]);
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _InfoPill({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = color ?? cs.outline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.withAlpha(15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.withAlpha(60)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: c),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                color: c, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _StawkaRow extends StatelessWidget {
  final HistoriaStawkiModel stawka;
  const _StawkaRow({required this.stawka});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Icon(Icons.circle, size: 8, color: cs.primary),
        const SizedBox(width: 10),
        Text(
          stawka.dataOd,
          style: TextStyle(
              color: cs.outline, fontSize: 12, fontFamily: 'monospace'),
        ),
        const SizedBox(width: 16),
        Text(
          '${stawka.stawkaGodz.toStringAsFixed(2)} ${stawka.waluta}/h',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ]),
    );
  }
}

// ── Dialogi ─────────────────────────────────────────────────────────────────

class _DodajUmiejetnoscDialog extends StatefulWidget {
  const _DodajUmiejetnoscDialog();

  @override
  State<_DodajUmiejetnoscDialog> createState() =>
      _DodajUmiejetnoscDialogState();
}

class _DodajUmiejetnoscDialogState extends State<_DodajUmiejetnoscDialog> {
  Specjalizacja _spec = Specjalizacja.murarz;
  PoziomDoswiadczenia _poziom = PoziomDoswiadczenia.mid;
  final _lataCtrl = TextEditingController(text: '0');
  final _certCtrl = TextEditingController();
  final _certWaznyCtrl = TextEditingController();
  final _stawkaCtrl = TextEditingController();

  @override
  void dispose() {
    _lataCtrl.dispose();
    _certCtrl.dispose();
    _certWaznyCtrl.dispose();
    _stawkaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Dodaj umiejętność'),
        scrollable: true,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<Specjalizacja>(
              value: _spec,
              decoration: const InputDecoration(
                labelText: 'Specjalizacja',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: Specjalizacja.values
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text('${s.emoji}  ${s.label}'),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _spec = v!),
            ),
            const SizedBox(height: 12),

            // Poziom — segmented button
            Text(
              'Poziom doświadczenia',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 6),
            _PoziomSelector(
              value: _poziom,
              onChanged: (v) => setState(() => _poziom = v),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _lataCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Lata doświadczenia',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _certCtrl,
              decoration: const InputDecoration(
                labelText: 'Certyfikat / uprawnienia (opcjonalnie)',
                border: OutlineInputBorder(),
                isDense: true,
                hintText: 'np. Uprawnienia SEP E do 1kV',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _certWaznyCtrl,
              decoration: const InputDecoration(
                labelText: 'Certyfikat ważny do (RRRR-MM-DD)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _stawkaCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Stawka dla tej specjalizacji PLN/h (opcjonalnie)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, {
              'specjalizacja': _spec.value,
              'poziom': _poziom.value,
              'lata_doswiadczenia':
                  int.tryParse(_lataCtrl.text) ?? 0,
              if (_certCtrl.text.trim().isNotEmpty)
                'certyfikat': _certCtrl.text.trim(),
              if (_certWaznyCtrl.text.trim().isNotEmpty)
                'certyfikat_wazny_do': _certWaznyCtrl.text.trim(),
              if (_stawkaCtrl.text.trim().isNotEmpty)
                'stawka_specjalizacji': double.tryParse(
                    _stawkaCtrl.text.replaceAll(',', '.')),
            }),
            child: const Text('Dodaj'),
          ),
        ],
      );
}

class _PoziomSelector extends StatelessWidget {
  final PoziomDoswiadczenia value;
  final ValueChanged<PoziomDoswiadczenia> onChanged;
  const _PoziomSelector({required this.value, required this.onChanged});

  Color _color(PoziomDoswiadczenia p) => switch (p) {
        PoziomDoswiadczenia.uczen => const Color(0xFF9E9E9E),
        PoziomDoswiadczenia.junior => const Color(0xFF4FC3F7),
        PoziomDoswiadczenia.mid => const Color(0xFF4CAF50),
        PoziomDoswiadczenia.senior => const Color(0xFFFF9800),
        PoziomDoswiadczenia.ekspert => const Color(0xFFE91E63),
      };

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 6,
        children: PoziomDoswiadczenia.values.map((p) {
          final selected = p == value;
          final color = _color(p);
          return GestureDetector(
            onTap: () => onChanged(p),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: selected ? color.withAlpha(30) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selected ? color : color.withAlpha(60),
                  width: selected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      p.rank,
                      (_) => Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(right: 2),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    p.label.split('(').first.trim(),
                    style: TextStyle(
                        fontSize: 9,
                        color: selected ? color : color.withAlpha(160)),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );
}

class _DodajStawkeDialog extends StatefulWidget {
  const _DodajStawkeDialog();

  @override
  State<_DodajStawkeDialog> createState() => _DodajStawkeDialogState();
}

class _DodajStawkeDialogState extends State<_DodajStawkeDialog> {
  final _stawkaCtrl = TextEditingController();
  String _dataOd = DateTime.now().toIso8601String().substring(0, 10);

  @override
  void dispose() {
    _stawkaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Nowa stawka godzinowa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _stawkaCtrl,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Stawka PLN/h',
                border: OutlineInputBorder(),
                suffixText: 'PLN/h',
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.event),
              label: Text('Od: $_dataOd'),
              onPressed: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (d != null) {
                  setState(() =>
                      _dataOd = d.toIso8601String().substring(0, 10));
                }
              },
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
              final s = double.tryParse(
                  _stawkaCtrl.text.replaceAll(',', '.'));
              if (s == null) return;
              Navigator.pop(context, {'stawka': s, 'data_od': _dataOd});
            },
            child: const Text('Zapisz'),
          ),
        ],
      );
}
