import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:core/shell/manager/bar_manager.dart';
import '../../data/models/pracownicy_model.dart';
import '../../data/providers/pracownicy_provider.dart';
import '../../data/services/pracownicy_api.dart';
import '../../widgets/skill_matrix.dart';

class PracownikProfilScreen extends ConsumerWidget {
  final int pracownikId;
  const PracownikProfilScreen({super.key, required this.pracownikId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sideMenuKey = GlobalKey<SideMenuState>();
    final theme = ref.read(themeColorsProvider);
    final async = ref.watch(pracownikDetailProvider(pracownikId));

    return BarManager(
      sideMenuKey: sideMenuKey,
      appModule: AppModule.budkon,
      childPc: async.when(
        loading: () => Center(
            child: CircularProgressIndicator(color: theme.themeColor)),
        error: (e, _) => Center(
            child: Text('Błąd: $e', style: TextStyle(color: theme.textColor))),
        data: (p) => _ProfilBody(pracownik: p, theme: theme),
      ),
    );
  }
}

class _ProfilBody extends ConsumerWidget {
  final PracownikDetail pracownik;
  final ThemeColors theme;
  const _ProfilBody({required this.pracownik, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = pracownik;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 160,
          pinned: true,
          backgroundColor: Colors.transparent,
          iconTheme: IconThemeData(color: theme.textColor),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.themeColor,
                    theme.themeColor.withAlpha(160),
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
                        p.inicjaly,
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
              icon: Icon(Icons.edit_outlined, color: theme.textColor),
              onPressed: () => _edytuj(context),
            ),
          ],
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      Text(
                        p.pelneImie,
                        style: TextStyle(
                            color: theme.textColor,
                            fontSize: 22,
                            fontWeight: FontWeight.w700),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            p.glownaSpecjalizacja.emoji,
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            p.glownaSpecjalizacja.label,
                            style: TextStyle(
                                color: theme.themeColor,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (p.aktualnaStawka != null)
                      _InfoPill(
                        icon: Icons.payments_outlined,
                        label:
                            '${p.aktualnaStawka!.toStringAsFixed(2)} PLN/h',
                        color: theme.themeColor,
                      ),
                    if (p.telefon.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      _InfoPill(
                        icon: Icons.phone_outlined,
                        label: p.telefon,
                        color: theme.textColor.withAlpha(150),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 6),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.badge_outlined,
                        size: 13,
                        color: theme.textColor.withAlpha(130)),
                    const SizedBox(width: 5),
                    Text(
                      _typUmowyLabel(p.typUmowy),
                      style: TextStyle(
                          color: theme.textColor.withAlpha(150),
                          fontSize: 12),
                    ),
                    if (p.dataZatrudnienia != null) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.event,
                          size: 13,
                          color: theme.textColor.withAlpha(130)),
                      const SizedBox(width: 4),
                      Text(
                        'od ${p.dataZatrudnienia}',
                        style: TextStyle(
                            color: theme.textColor.withAlpha(150),
                            fontSize: 12),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 28),

                _Section(
                  title: 'Umiejętności i doświadczenie',
                  theme: theme,
                  action: TextButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Dodaj'),
                    onPressed: () => _dodajUmiejetnosc(context, ref),
                    style: TextButton.styleFrom(
                        foregroundColor: theme.themeColor),
                  ),
                ),
                const SizedBox(height: 8),

                SkillMatrix(
                  umiejetnosci: p.umiejetnosci,
                  onDodaj: () => _dodajUmiejetnosc(context, ref),
                ),

                const SizedBox(height: 24),

                if (p.historiaStawek.isNotEmpty) ...[
                  _Section(
                    title: 'Historia stawek',
                    theme: theme,
                    action: TextButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Nowa stawka'),
                      onPressed: () => _dodajStawke(context, ref),
                      style: TextButton.styleFrom(
                          foregroundColor: theme.themeColor),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...p.historiaStawek.map(
                    (s) => _StawkaRow(stawka: s, theme: theme),
                  ),
                ] else
                  OutlinedButton.icon(
                    icon: const Icon(Icons.payments_outlined),
                    label: const Text('Ustaw stawkę godzinową'),
                    onPressed: () => _dodajStawke(context, ref),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: theme.themeColor,
                        side: BorderSide(
                            color: theme.bordercolor.withAlpha(80))),
                  ),

                if (p.uwagi.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _Section(title: 'Uwagi', theme: theme),
                  const SizedBox(height: 8),
                  Text(p.uwagi,
                      style: TextStyle(
                          color: theme.textColor.withAlpha(180))),
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
      builder: (_) => const _DodajUmiejetnoscDialog(),
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

  void _edytuj(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edycja w przygotowaniu')),
    );
  }
}

// ── Widgets pomocnicze ──────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final ThemeColors theme;
  final Widget? action;
  const _Section({required this.title, required this.theme, this.action});

  @override
  Widget build(BuildContext context) => Row(children: [
        Text(title,
            style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.w700,
                fontSize: 15)),
        const Spacer(),
        if (action != null) action!,
      ]);
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoPill(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _StawkaRow extends StatelessWidget {
  final HistoriaStawkiModel stawka;
  final ThemeColors theme;
  const _StawkaRow({required this.stawka, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Icon(Icons.circle, size: 8, color: theme.themeColor),
        const SizedBox(width: 10),
        Text(
          stawka.dataOd,
          style: TextStyle(
              color: theme.textColor.withAlpha(150),
              fontSize: 12,
              fontFamily: 'monospace'),
        ),
        const SizedBox(width: 16),
        Text(
          '${stawka.stawkaGodz.toStringAsFixed(2)} ${stawka.waluta}/h',
          style: TextStyle(
              color: theme.textColor,
              fontWeight: FontWeight.w700,
              fontSize: 13),
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
