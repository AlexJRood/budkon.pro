import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import '../../data/models/odbiory_model.dart';
import '../../data/providers/odbiory_provider.dart';
import '../../widgets/protokol_status_badge.dart';
import '../../widgets/punkt_kontrolny_tile.dart';

class ProtokolDetailScreen extends ConsumerStatefulWidget {
  final int protokolId;
  final String tytul;

  const ProtokolDetailScreen({
    super.key,
    required this.protokolId,
    required this.tytul,
  });

  @override
  ConsumerState<ProtokolDetailScreen> createState() => _ProtokolDetailScreenState();
}

class _ProtokolDetailScreenState extends ConsumerState<ProtokolDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(protokolProvider.notifier).load(widget.protokolId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);
    final state = ref.watch(protokolProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldColor,
      appBar: AppBar(
        backgroundColor: theme.userTile,
        title: Text(widget.tytul,
            style: TextStyle(color: theme.textColor, fontSize: 15, fontWeight: FontWeight.bold)),
        actions: state.valueOrNull != null
            ? [
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showMenu(context, state.value!),
                ),
              ]
            : null,
      ),
      body: state.when(
        loading: () => Center(child: CircularProgressIndicator(color: theme.themeColor)),
        error: (e, _) => Center(child: Text('Błąd: $e')),
        data: (p) {
          if (p == null) return const SizedBox.shrink();
          return _Body(protokol: p, theme: theme);
        },
      ),
    );
  }

  void _showMenu(BuildContext context, ProtokołOdbioruModel p) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        final theme = ref.read(themeColorsProvider);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!p.podpisanyPrzezKierownika)
                ListTile(
                  leading: const Icon(Icons.draw),
                  title: const Text('Podpisz jako kierownik'),
                  onTap: () {
                    Navigator.pop(ctx);
                    ref.read(protokolProvider.notifier).podpisz(kierownik: true);
                  },
                ),
              if (!p.podpisanyPrzezInwestora)
                ListTile(
                  leading: const Icon(Icons.draw_outlined),
                  title: const Text('Podpisz jako inwestor'),
                  onTap: () {
                    Navigator.pop(ctx);
                    ref.read(protokolProvider.notifier).podpisz(kierownik: false);
                  },
                ),
              if (p.status == StatusProtokolu.roboczy)
                ListTile(
                  leading: Icon(Icons.send_outlined, color: theme.themeColor),
                  title: Text('Wyślij do podpisu',
                      style: TextStyle(color: theme.themeColor)),
                  onTap: () {
                    Navigator.pop(ctx);
                    ref
                        .read(protokolProvider.notifier)
                        .updateStatus(StatusProtokolu.do_podpisu);
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  final ProtokołOdbioruModel protokol;
  final ThemeColors theme;
  const _Body({required this.protokol, required this.theme});

  @override
  Widget build(BuildContext context) {
    final p = protokol;

    // Grupuj punkty po kategorii
    final Map<String, List<PunktKontrolnyModel>> grouped = {};
    for (final punkt in p.punkty) {
      final kat = punkt.kategoria.isEmpty ? 'Ogólne' : punkt.kategoria;
      grouped.putIfAbsent(kat, () => []).add(punkt);
    }

    final isEditable = p.status == StatusProtokolu.roboczy ||
        p.status == StatusProtokolu.do_podpisu;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ---- Nagłówek ----
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.userTile,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.bordercolor.withAlpha(40)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(p.typ.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(p.typ.label,
                        style: TextStyle(
                            color: theme.textColor, fontWeight: FontWeight.w600)),
                  ),
                  ProtokolStatusBadge(p.status),
                ],
              ),
              const SizedBox(height: 10),
              _InfoRow(Icons.calendar_today_outlined, 'Data', p.dataFmt, theme),
              if (p.kierownikImie.isNotEmpty)
                _InfoRow(Icons.engineering_outlined, 'Kierownik', p.kierownikImie, theme),
              if (p.inwestorImie.isNotEmpty)
                _InfoRow(Icons.person_outlined, 'Inwestor', p.inwestorImie, theme),
              // Postęp checklisty
              if (p.punkty.isNotEmpty) ...[
                const SizedBox(height: 12),
                _PostepBar(protokol: p, theme: theme),
              ],
              // Podpisy
              if (p.podpisanyPrzezKierownika || p.podpisanyPrzezInwestora) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    _PodpisChip(
                        label: 'Kierownik',
                        podpisany: p.podpisanyPrzezKierownika,
                        theme: theme),
                    const SizedBox(width: 8),
                    _PodpisChip(
                        label: 'Inwestor',
                        podpisany: p.podpisanyPrzezInwestora,
                        theme: theme),
                  ],
                ),
              ],
            ],
          ),
        ),

        // ---- Uwagi ogólne ----
        if (p.uwagi.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.themeColor.withAlpha(15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.themeColor.withAlpha(40)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.notes, size: 16, color: theme.themeColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(p.uwagi,
                      style: TextStyle(fontSize: 13, color: theme.textColor)),
                ),
              ],
            ),
          ),
        ],

        // ---- Checklisty ----
        if (p.punkty.isNotEmpty) ...[
          const SizedBox(height: 16),
          ...grouped.entries.map((entry) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6, top: 4),
                    child: Text(
                      entry.key,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: theme.themeColor,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  ...entry.value.map((punkt) => PunktKontrolnyTile(
                        punkt: punkt,
                        readOnly: !isEditable,
                      )),
                  const SizedBox(height: 8),
                ],
              )),
        ],

        // ---- Usterki z tego protokołu ----
        if (p.usterki.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Usterki (${p.usterki.length})',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: theme.textColor),
          ),
          const SizedBox(height: 8),
          ...p.usterki.map((u) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(10),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withAlpha(40)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_outlined,
                        size: 16, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(u.opis,
                          style: TextStyle(fontSize: 12, color: theme.textColor)),
                    ),
                  ],
                ),
              )),
        ],

        const SizedBox(height: 80),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ThemeColors theme;
  const _InfoRow(this.icon, this.label, this.value, this.theme);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Icon(icon, size: 13, color: theme.textColor.withAlpha(120)),
            const SizedBox(width: 6),
            Text('$label: ',
                style: TextStyle(
                    fontSize: 12, color: theme.textColor.withAlpha(150))),
            Text(value,
                style:
                    TextStyle(fontSize: 12, color: theme.textColor, fontWeight: FontWeight.w500)),
          ],
        ),
      );
}

class _PostepBar extends StatelessWidget {
  final ProtokołOdbioruModel protokol;
  final ThemeColors theme;
  const _PostepBar({required this.protokol, required this.theme});

  @override
  Widget build(BuildContext context) {
    final p = protokol;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Checklista: ',
                style: TextStyle(fontSize: 12, color: theme.textColor.withAlpha(150))),
            Text('${p.punktyOk} OK',
                style: const TextStyle(
                    fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600)),
            if (p.punktyNok > 0) ...[
              const SizedBox(width: 8),
              Text('${p.punktyNok} niezg.',
                  style: TextStyle(
                      fontSize: 12, color: Colors.red.shade400, fontWeight: FontWeight.w600)),
            ],
            const SizedBox(width: 8),
            Text('/ ${p.punkty.length}',
                style: TextStyle(fontSize: 12, color: theme.textColor.withAlpha(120))),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: p.postepProcent,
            backgroundColor: theme.bordercolor.withAlpha(50),
            valueColor: AlwaysStoppedAnimation(
              p.punktyNok > 0 ? Colors.orange : theme.themeColor,
            ),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

class _PodpisChip extends StatelessWidget {
  final String label;
  final bool podpisany;
  final ThemeColors theme;
  const _PodpisChip(
      {required this.label, required this.podpisany, required this.theme});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: podpisany ? Colors.green.withAlpha(25) : theme.bordercolor.withAlpha(30),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: podpisany ? Colors.green.withAlpha(80) : theme.bordercolor.withAlpha(60),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(podpisany ? Icons.check : Icons.hourglass_empty_outlined,
                size: 13,
                color: podpisany ? Colors.green : theme.textColor.withAlpha(100)),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: podpisany ? Colors.green : theme.textColor.withAlpha(120),
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );
}
