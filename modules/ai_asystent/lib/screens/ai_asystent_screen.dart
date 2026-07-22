import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
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
    _tabCtrl = TabController(length: 4, vsync: this);
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
                color: theme.textColor, fontSize: 15, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: theme.themeColor,
          labelColor: theme.themeColor,
          unselectedLabelColor: theme.textColor.withAlpha(120),
          isScrollable: true,
          tabs: const [
            Tab(text: 'Czat'),
            Tab(text: 'Dziennik'),
            Tab(text: 'Analiza zdjęć'),
            Tab(text: 'Predykcja'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _CzatTab(budowaId: widget.budowaId),
          _DziennikTab(budowaId: widget.budowaId),
          _AnalizaZdjecTab(budowaId: widget.budowaId),
          _PredykcjaTab(budowaId: widget.budowaId),
        ],
      ),
    );
  }
}

// ============ CZAT TAB ============

class _CzatTab extends ConsumerStatefulWidget {
  final int budowaId;
  const _CzatTab({required this.budowaId});

  @override
  ConsumerState<_CzatTab> createState() => _CzatTabState();
}

class _CzatTabState extends ConsumerState<_CzatTab> {
  final _inputCtrl = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _wyslij() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    _inputCtrl.clear();
    ref.read(czatProvider(widget.budowaId).notifier).wyslij(text);
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);
    final czat = ref.watch(czatProvider(widget.budowaId));

    return Column(
      children: [
        if (czat.historia.isEmpty)
          Expanded(child: _CzatPuste(theme: theme))
        else
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              itemCount: czat.historia.length,
              itemBuilder: (_, i) =>
                  _BubblaCzat(msg: czat.historia[i], theme: theme),
            ),
          ),
        if (czat.ladowanie)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: theme.themeColor)),
                const SizedBox(width: 8),
                Text('Asystent odpowiada...',
                    style: TextStyle(
                        fontSize: 12, color: theme.textColor.withAlpha(130))),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          color: theme.userTile,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inputCtrl,
                  style: TextStyle(color: theme.textColor, fontSize: 13),
                  maxLines: 3,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _wyslij(),
                  decoration: InputDecoration(
                    hintText: 'Zapytaj o budowę...',
                    hintStyle: TextStyle(
                        color: theme.textColor.withAlpha(80), fontSize: 13),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _wyslij,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: theme.themeColor, shape: BoxShape.circle),
                  child: const Icon(Icons.send, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CzatPuste extends StatelessWidget {
  final ThemeColors theme;
  const _CzatPuste({required this.theme});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: theme.themeColor.withAlpha(15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.smart_toy_outlined,
                  color: theme.themeColor, size: 36),
            ),
            const SizedBox(height: 16),
            Text('AI Asystent budowlany',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: theme.textColor)),
            const SizedBox(height: 8),
            Text(
              'Zapytaj o harmonogram, koszty, materiały, przepisy budowlane lub wygeneruj podsumowanie postępu prac.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: theme.textColor.withAlpha(140)),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                'Podsumuj postęp prac',
                'Jakie są zaległości?',
                'Oszacuj czas do końca',
                'Sprawdź rentowność',
              ]
                  .map((t) => GestureDetector(
                        onTap: () {},
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.themeColor.withAlpha(12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: theme.themeColor.withAlpha(60)),
                          ),
                          child: Text(t,
                              style: TextStyle(
                                  fontSize: 12, color: theme.themeColor)),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      );
}

class _BubblaCzat extends StatelessWidget {
  final WiadomoscCzatModel msg;
  final ThemeColors theme;
  const _BubblaCzat({required this.msg, required this.theme});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.rola == RolaCzat.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: isUser ? theme.themeColor : theme.userTile,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isUser ? const Radius.circular(4) : null,
            bottomLeft: isUser ? null : const Radius.circular(4),
          ),
          border: isUser
              ? null
              : Border.all(color: theme.bordercolor.withAlpha(50)),
        ),
        child: Text(
          msg.tresc,
          style: TextStyle(
              fontSize: 13,
              color: isUser ? Colors.white : theme.textColor),
        ),
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
        onPressed: () => _pokazDodajAudio(context, ref, theme),
        icon: const Icon(Icons.mic),
        label: const Text('Nagraj'),
      ),
      body: async.when(
        loading: () =>
            Center(child: CircularProgressIndicator(color: theme.themeColor)),
        error: (e, _) => Center(
            child:
                Text('Błąd: $e', style: const TextStyle(color: Color(0xFF7B1F1F)))),
        data: (wpisy) => wpisy.isEmpty
            ? Center(
                child: Text('Brak wpisów. Nagraj pierwszy dziennik głosowy.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.textColor.withAlpha(120))))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                itemCount: wpisy.length,
                itemBuilder: (_, i) => _WpisDziennikTile(w: wpisy[i], theme: theme),
              ),
      ),
    );
  }

  void _pokazDodajAudio(BuildContext ctx, WidgetRef ref, ThemeColors theme) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: theme.userTile,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _DodajAudioSheet(budowaId: budowaId, theme: theme),
    );
  }
}

class _DodajAudioSheet extends ConsumerWidget {
  final int budowaId;
  final ThemeColors theme;
  const _DodajAudioSheet({required this.budowaId, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Dodaj nagranie głosowe',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold, color: theme.textColor)),
            const SizedBox(height: 16),
            Text(
              'Wybierz plik audio z urządzenia lub nagraj nowe nagranie. '
              'AI automatycznie je transkrybuje i wygeneruje streszczenie.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: theme.textColor.withAlpha(140)),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: theme.themeColor, foregroundColor: Colors.white),
                icon: const Icon(Icons.upload_file),
                label: const Text('Wybierz plik audio'),
                onPressed: () async {
                  final picker = ImagePicker();
                  final file = await picker.pickVideo(source: ImageSource.gallery);
                  if (file != null) {
                    await ref
                        .read(dziennikNotifierProvider(budowaId).notifier)
                        .wyslijAudio(File(file.path));
                    if (context.mounted) Navigator.pop(context);
                  }
                },
              ),
            ),
          ],
        ),
      );
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
              Icon(Icons.mic_none, size: 16, color: theme.textColor.withAlpha(130)),
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
                    color: statusColor, borderRadius: BorderRadius.circular(6)),
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

// ============ ANALIZA ZDJĘĆ TAB ============

class _AnalizaZdjecTab extends ConsumerWidget {
  final int budowaId;
  const _AnalizaZdjecTab({required this.budowaId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    final async = ref.watch(analizaNotifierProvider(budowaId));

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: theme.themeColor,
        foregroundColor: Colors.white,
        onPressed: () => _pokazDodajZdjecie(context, ref, theme),
        icon: const Icon(Icons.add_a_photo),
        label: const Text('Analizuj'),
      ),
      body: async.when(
        loading: () =>
            Center(child: CircularProgressIndicator(color: theme.themeColor)),
        error: (e, _) => Center(
            child: Text('Błąd: $e',
                style: const TextStyle(color: Color(0xFF7B1F1F)))),
        data: (analizy) => analizy.isEmpty
            ? Center(
                child: Text('Brak analiz. Wyślij zdjęcie do analizy AI.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.textColor.withAlpha(120))))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                itemCount: analizy.length,
                itemBuilder: (_, i) =>
                    _AnalizaTile(a: analizy[i], theme: theme),
              ),
      ),
    );
  }

  void _pokazDodajZdjecie(BuildContext ctx, WidgetRef ref, ThemeColors theme) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: theme.userTile,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _DodajZdjecieSheet(budowaId: budowaId, theme: theme),
    );
  }
}

class _DodajZdjecieSheet extends ConsumerStatefulWidget {
  final int budowaId;
  final ThemeColors theme;
  const _DodajZdjecieSheet({required this.budowaId, required this.theme});

  @override
  ConsumerState<_DodajZdjecieSheet> createState() => _DodajZdjecieSheetState();
}

class _DodajZdjecieSheetState extends ConsumerState<_DodajZdjecieSheet> {
  TypAnalizy _typ = TypAnalizy.postep;
  bool _ladowanie = false;

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
          Text('Typ analizy',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.textColor.withAlpha(150))),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: TypAnalizy.values
                .map((t) => ChoiceChip(
                      label: Text('${t.emoji} ${t.label}'),
                      selected: _typ == t,
                      onSelected: (_) => setState(() => _typ = t),
                      selectedColor: theme.themeColor,
                      labelStyle: TextStyle(
                          color: _typ == t ? Colors.white : theme.textColor,
                          fontSize: 12),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.camera_alt, size: 16),
                  label: const Text('Aparat'),
                  onPressed: _ladowanie
                      ? null
                      : () => _wybierz(ImageSource.camera),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: theme.themeColor,
                      side: BorderSide(color: theme.themeColor)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.photo_library, size: 16),
                  label: const Text('Galeria'),
                  onPressed: _ladowanie
                      ? null
                      : () => _wybierz(ImageSource.gallery),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: theme.themeColor,
                      foregroundColor: Colors.white),
                ),
              ),
            ],
          ),
          if (_ladowanie)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: theme.themeColor)),
                  const SizedBox(width: 10),
                  Text('Analizuję zdjęcie...',
                      style: TextStyle(
                          fontSize: 13, color: theme.textColor.withAlpha(130))),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _wybierz(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source);
    if (file == null) return;
    setState(() => _ladowanie = true);
    await ref
        .read(analizaNotifierProvider(widget.budowaId).notifier)
        .analizuj(File(file.path), _typ);
    if (mounted) Navigator.pop(context);
  }
}

class _AnalizaTile extends StatelessWidget {
  final AnalizaZdjeciaModel a;
  final ThemeColors theme;
  const _AnalizaTile({required this.a, required this.theme});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.userTile,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: a.maProblemy
                ? const Color(0xFF7B5E00).withAlpha(80)
                : theme.bordercolor.withAlpha(40),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(a.typ.emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(a.typ.label,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.textColor)),
                const Spacer(),
                Text(
                  '${a.data.day}.${a.data.month}.${a.data.year}',
                  style: TextStyle(
                      fontSize: 11, color: theme.textColor.withAlpha(110)),
                ),
              ],
            ),
            if (a.postepProcent != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('Postęp: ',
                      style: TextStyle(
                          fontSize: 12, color: theme.textColor.withAlpha(130))),
                  Text('${a.postepProcent!.toStringAsFixed(0)}%',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor)),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (a.postepProcent! / 100).clamp(0, 1),
                  minHeight: 6,
                  backgroundColor: theme.bordercolor.withAlpha(60),
                  valueColor: AlwaysStoppedAnimation<Color>(theme.themeColor),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(a.opis,
                style:
                    TextStyle(fontSize: 12, color: theme.textColor.withAlpha(160))),
            if (a.problemy.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...a.problemy.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber,
                            size: 13, color: Color(0xFF7B5E00)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(p,
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF7B5E00))),
                        ),
                      ],
                    ),
                  )),
            ],
            if (a.rekomendacje.isNotEmpty) ...[
              const SizedBox(height: 6),
              ...a.rekomendacje.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(
                      children: [
                        const Icon(Icons.lightbulb_outline,
                            size: 13, color: Color(0xFF1E7A3A)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(r,
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF1E7A3A))),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      );
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
                  Text('Brak predykcji',
                      style: TextStyle(color: theme.textColor.withAlpha(120))),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: theme.themeColor,
                        foregroundColor: Colors.white),
                    onPressed: () =>
                        ref.read(predykcjaProvider(budowaId).notifier).odswiez(),
                    child: const Text('Generuj predykcję'),
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
          // Główna karta
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
                Row(
                  children: [
                    Icon(
                      przekr ? Icons.trending_up : Icons.check_circle_outline,
                      color: przekr
                          ? const Color(0xFF7B1F1F)
                          : const Color(0xFF1E7A3A),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      przekr ? 'Przewidywane przekroczenie budżetu' : 'Budżet w normie',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: przekr
                              ? const Color(0xFF7B1F1F)
                              : const Color(0xFF1E7A3A)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _StatRow('Koszt aktualny',
                    '${(p.kosztAktualny / 1000).toStringAsFixed(0)}k zł', theme),
                _StatRow('Koszt przewidywany',
                    '${(p.kosztPrzewidywany / 1000).toStringAsFixed(0)}k zł', theme),
                _StatRow('Budżet',
                    '${(p.kosztBudzet / 1000).toStringAsFixed(0)}k zł', theme),
                _StatRow(
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
          // Pasek wykonania
          Text('Realizacja budżetu: ${p.procentWykonania.toStringAsFixed(0)}%',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: theme.textColor)),
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
          // Uzasadnienie
          Text('Analiza AI',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: theme.textColor)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.userTile,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.bordercolor.withAlpha(40)),
            ),
            child: Text(p.uzasadnienie,
                style:
                    TextStyle(fontSize: 13, color: theme.textColor.withAlpha(160))),
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
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_right,
                          size: 16, color: Color(0xFF7B5E00)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(c,
                            style: TextStyle(
                                fontSize: 12, color: theme.textColor.withAlpha(160))),
                      ),
                    ],
                  ),
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
                  side: BorderSide(color: theme.themeColor.withAlpha(80))),
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

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final ThemeColors theme;
  final Color? color;
  const _StatRow(this.label, this.value, this.theme, {this.color});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 12, color: theme.textColor.withAlpha(130))),
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
