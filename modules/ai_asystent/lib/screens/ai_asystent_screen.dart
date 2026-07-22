import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emma/screens/emma_inline.dart';
import 'package:core/theme/apptheme.dart';
import '../data/models/ai_asystent_model.dart';
import '../data/providers/ai_asystent_provider.dart';

class AiAsystentScreen extends ConsumerStatefulWidget {
  final int budowaId;
  const AiAsystentScreen({super.key, required this.budowaId});

  @override
  ConsumerState<AiAsystentScreen> createState() => _AiAsystentScreenState();
}

class _AiAsystentScreenState extends ConsumerState<AiAsystentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldColor,
      appBar: AppBar(
        backgroundColor: theme.userTile,
        title: Text('AI Asystent',
            style: TextStyle(
                color: theme.textColor,
                fontSize: 15,
                fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: theme.themeColor,
          labelColor: theme.themeColor,
          unselectedLabelColor: theme.textColor.withAlpha(120),
          tabs: const [
            Tab(text: 'Emma'),
            Tab(text: 'Dziennik'),
            Tab(text: 'Predykcja'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          // Emma obsługuje: chat, STT (głos), wysyłanie zdjęć do analizy (images param)
          EmmaChatInline(
            fillParent: true,
            nodeKind: 'budowa',
            nodeId: widget.budowaId.toString(),
          ),
          _DziennikTab(budowaId: widget.budowaId),
          _PredykcjaTab(budowaId: widget.budowaId),
        ],
      ),
    );
  }
}

// ============ DZIENNIK TAB ============

class _DziennikTab extends ConsumerWidget {
  final int budowaId;
  const _DziennikTab({required this.budowaId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    final async = ref.watch(dziennikNotifierProvider(budowaId));

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: theme.themeColor,
        foregroundColor: Colors.white,
        onPressed: () => _pokazDodajWpis(context, ref, theme),
        icon: const Icon(Icons.mic),
        label: const Text('Nowy wpis'),
      ),
      body: async.when(
        loading: () =>
            Center(child: CircularProgressIndicator(color: theme.themeColor)),
        error: (e, _) => Center(
            child: Text('Błąd: $e',
                style: const TextStyle(color: Color(0xFF7B1F1F)))),
        data: (wpisy) => wpisy.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.book_outlined,
                        size: 40, color: theme.textColor.withAlpha(60)),
                    const SizedBox(height: 12),
                    Text(
                      'Brak wpisów.\nNaciśnij mikrofon, podyktuj notatkę głosową\nlub opisz postęp prac.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13, color: theme.textColor.withAlpha(120)),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                itemCount: wpisy.length,
                itemBuilder: (_, i) =>
                    _WpisDziennikTile(w: wpisy[i], theme: theme),
              ),
      ),
    );
  }

  void _pokazDodajWpis(BuildContext ctx, WidgetRef ref, ThemeColors theme) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: theme.userTile,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _NagranieDziennikSheet(budowaId: budowaId, theme: theme),
    );
  }
}

class _NagranieDziennikSheet extends ConsumerStatefulWidget {
  final int budowaId;
  final ThemeColors theme;
  const _NagranieDziennikSheet(
      {required this.budowaId, required this.theme});

  @override
  ConsumerState<_NagranieDziennikSheet> createState() =>
      _NagranieDziennikSheetState();
}

class _NagranieDziennikSheetState
    extends ConsumerState<_NagranieDziennikSheet> {
  final _tekstCtrl = TextEditingController();
  bool _ladowanie = false;
  bool _nagrywanie = false;

  @override
  void dispose() {
    _tekstCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text('Nowy wpis w dzienniku',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor)),
            ),
            IconButton(
              icon: Icon(Icons.close, color: theme.textColor.withAlpha(120)),
              onPressed: () => Navigator.pop(context),
            ),
          ]),
          const SizedBox(height: 4),
          Text(
            'Wpisz notatkę lub skorzystaj z dyktowania głosowego Emmy (ikona mikrofonu w czacie).',
            style: TextStyle(fontSize: 12, color: theme.textColor.withAlpha(130)),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _tekstCtrl,
            minLines: 3,
            maxLines: 6,
            style: TextStyle(color: theme.textColor),
            decoration: InputDecoration(
              hintText: 'Treść wpisu (np. "Zakończono wylewkę parteru, ekipa 5 osób...")',
              hintStyle: TextStyle(
                  color: theme.textColor.withAlpha(70), fontSize: 13),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: theme.themeColor,
                  foregroundColor: Colors.white),
              icon: _ladowanie
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child:
                          CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.save_outlined, size: 16),
              label: Text(_ladowanie ? 'Zapisuję...' : 'Zapisz wpis'),
              onPressed: _ladowanie ? null : _zapisz,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _zapisz() async {
    final tekst = _tekstCtrl.text.trim();
    if (tekst.isEmpty) return;
    setState(() => _ladowanie = true);
    try {
      await ref
          .read(dziennikNotifierProvider(widget.budowaId).notifier)
          .dodajTekst(tekst);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _ladowanie = false);
    }
  }
}

class _WpisDziennikTile extends StatelessWidget {
  final WpisDziennikModel w;
  final ThemeColors theme;
  const _WpisDziennikTile({required this.w, required this.theme});

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusColor) = switch (w.status) {
      StatusWpisu.oczekuje => ('Oczekuje', const Color(0xFF7B5E00)),
      StatusWpisu.transkrybowany => ('Gotowy', const Color(0xFF1E7A3A)),
      StatusWpisu.blad => ('Błąd', const Color(0xFF7B1F1F)),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
              Icon(Icons.book_outlined,
                  size: 14, color: theme.textColor.withAlpha(120)),
              const SizedBox(width: 6),
              Text(
                '${w.data.day}.${w.data.month}.${w.data.year}',
                style: TextStyle(
                    fontSize: 12, color: theme.textColor.withAlpha(120)),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(6)),
                child: Text(statusLabel,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          if (w.streszczenie != null) ...[
            const SizedBox(height: 8),
            Text(w.streszczenie!,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: theme.textColor)),
          ],
          if (w.transkrypcja != null) ...[
            const SizedBox(height: 6),
            Text(
              w.transkrypcja!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 12, color: theme.textColor.withAlpha(150)),
            ),
          ],
          if (w.tagi.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: w.tagi
                  .map((t) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.themeColor.withAlpha(15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(t,
                            style: TextStyle(
                                fontSize: 10, color: theme.themeColor)),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// ============ PREDYKCJA TAB ============

class _PredykcjaTab extends ConsumerWidget {
  final int budowaId;
  const _PredykcjaTab({required this.budowaId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    final async = ref.watch(predykcjaProvider(budowaId));

    return async.when(
      loading: () =>
          Center(child: CircularProgressIndicator(color: theme.themeColor)),
      error: (e, _) => Center(
          child: Text('Błąd: $e',
              style: const TextStyle(color: Color(0xFF7B1F1F)))),
      data: (p) => p == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_graph_outlined,
                      size: 40, color: theme.textColor.withAlpha(60)),
                  const SizedBox(height: 12),
                  Text('Brak predykcji',
                      style:
                          TextStyle(color: theme.textColor.withAlpha(120))),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: theme.themeColor,
                        foregroundColor: Colors.white),
                    onPressed: () => ref
                        .read(predykcjaProvider(budowaId).notifier)
                        .odswiez(),
                    child: const Text('Generuj predykcję AI'),
                  ),
                ],
              ),
            )
          : _PredykcjaWidok(p: p, theme: theme, budowaId: budowaId),
    );
  }
}

class _PredykcjaWidok extends ConsumerWidget {
  final PredykcjaKosztowModel p;
  final ThemeColors theme;
  final int budowaId;
  const _PredykcjaWidok(
      {required this.p, required this.theme, required this.budowaId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final przekr = p.przekroczonyBudzet;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: przekr
                  ? const Color(0xFF7B1F1F).withAlpha(15)
                  : const Color(0xFF1E7A3A).withAlpha(15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: przekr
                    ? const Color(0xFF7B1F1F).withAlpha(60)
                    : const Color(0xFF1E7A3A).withAlpha(60),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(
                    przekr ? Icons.trending_up : Icons.check_circle_outline,
                    color: przekr
                        ? const Color(0xFF7B1F1F)
                        : const Color(0xFF1E7A3A),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      przekr
                          ? 'Przewidywane przekroczenie budżetu'
                          : 'Budżet w normie',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: przekr
                              ? const Color(0xFF7B1F1F)
                              : const Color(0xFF1E7A3A)),
                    ),
                  ),
                ]),
                const SizedBox(height: 14),
                _Stat('Koszt aktualny',
                    '${(p.kosztAktualny / 1000).toStringAsFixed(0)}k zł', theme),
                _Stat('Koszt przewidywany',
                    '${(p.kosztPrzewidywany / 1000).toStringAsFixed(0)}k zł',
                    theme),
                _Stat('Budżet',
                    '${(p.kosztBudzet / 1000).toStringAsFixed(0)}k zł', theme),
                _Stat(
                  'Odchylenie',
                  '${p.odchylenieOdBudzetu > 0 ? '+' : ''}${(p.odchylenieOdBudzetu / 1000).toStringAsFixed(0)}k zł',
                  theme,
                  color: przekr
                      ? const Color(0xFF7B1F1F)
                      : const Color(0xFF1E7A3A),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
              'Realizacja: ${p.procentWykonania.toStringAsFixed(0)}%',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.textColor)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (p.procentWykonania / 100).clamp(0, 1.5),
              minHeight: 10,
              backgroundColor: theme.bordercolor.withAlpha(60),
              valueColor: AlwaysStoppedAnimation<Color>(
                p.procentWykonania > 100
                    ? const Color(0xFF7B1F1F)
                    : theme.themeColor,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Analiza AI',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.textColor)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.userTile,
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: theme.bordercolor.withAlpha(40)),
            ),
            child: Text(p.uzasadnienie,
                style: TextStyle(
                    fontSize: 13,
                    color: theme.textColor.withAlpha(160))),
          ),
          if (p.glowneCzynniki.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text('Główne czynniki ryzyka',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor)),
            const SizedBox(height: 8),
            ...p.glowneCzynniki.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(children: [
                    const Icon(Icons.arrow_right,
                        size: 16, color: Color(0xFF7B5E00)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(c,
                          style: TextStyle(
                              fontSize: 12,
                              color: theme.textColor.withAlpha(160))),
                    ),
                  ]),
                )),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Odśwież predykcję'),
              onPressed: () =>
                  ref.read(predykcjaProvider(budowaId).notifier).odswiez(),
              style: OutlinedButton.styleFrom(
                  foregroundColor: theme.themeColor,
                  side: BorderSide(
                      color: theme.themeColor.withAlpha(80))),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Center(
              child: Text(
                'Ostatnia aktualizacja: ${p.dataGeneracji.day}.${p.dataGeneracji.month}.${p.dataGeneracji.year}',
                style: TextStyle(
                    fontSize: 11, color: theme.textColor.withAlpha(80)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final ThemeColors theme;
  final Color? color;
  const _Stat(this.label, this.value, this.theme, {this.color});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      color: theme.textColor.withAlpha(130))),
            ),
            Text(value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color ?? theme.textColor)),
          ],
        ),
      );
}
