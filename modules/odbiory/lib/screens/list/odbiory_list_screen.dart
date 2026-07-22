import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:core/theme/apptheme.dart';
import '../../data/models/odbiory_model.dart';
import '../../data/providers/odbiory_provider.dart';
import '../../widgets/protokol_card.dart';
import '../../widgets/usterka_status_badge.dart';
import '../form/protokol_form_screen.dart';
import '../detail/protokol_detail_screen.dart';

class OdbioryListScreen extends ConsumerStatefulWidget {
  final int budowaId;
  final String budowaNazwa;

  const OdbioryListScreen({
    super.key,
    required this.budowaId,
    required this.budowaNazwa,
  });

  @override
  ConsumerState<OdbioryListScreen> createState() => _OdbioryListScreenState();
}

class _OdbioryListScreenState extends ConsumerState<OdbioryListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(usterkiProvider.notifier).load(budowaId: widget.budowaId);
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);
    final protokolyAsync = ref.watch(protokolyProvider(widget.budowaId));
    final usterkiAsync = ref.watch(usterkiProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldColor,
      appBar: AppBar(
        backgroundColor: theme.userTile,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Odbiory', style: TextStyle(color: theme.textColor, fontSize: 16, fontWeight: FontWeight.bold)),
            Text(widget.budowaNazwa,
                style: TextStyle(color: theme.textColor.withAlpha(150), fontSize: 11)),
          ],
        ),
        bottom: TabBar(
          controller: _tab,
          labelColor: theme.themeColor,
          unselectedLabelColor: theme.textColor.withAlpha(120),
          indicatorColor: theme.themeColor,
          tabs: const [
            Tab(text: 'Protokoły'),
            Tab(text: 'Usterki'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: theme.themeColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(_tab.index == 0 ? 'Nowy protokół' : 'Nowa usterka'),
        onPressed: () => _tab.index == 0 ? _addProtokal() : _addUsterka(),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          // ---- Protokoły ----
          protokolyAsync.when(
            loading: () => Center(child: CircularProgressIndicator(color: theme.themeColor)),
            error: (e, _) => Center(child: Text('Błąd: $e', style: TextStyle(color: theme.textColor))),
            data: (list) {
              if (list.isEmpty) {
                return _Empty(
                  icon: Icons.assignment_outlined,
                  text: 'Brak protokołów odbioru',
                  sub: 'Dodaj pierwszy protokół aby rozpocząć kontrolę jakości.',
                  theme: theme,
                );
              }
              return ListView.builder(
                padding: EdgeInsets.all(16.w),
                itemCount: list.length,
                itemBuilder: (ctx, i) => ProtokolCard(
                  protokol: list[i],
                  onTap: () => _openProtokol(list[i]),
                ),
              );
            },
          ),
          // ---- Usterki ----
          usterkiAsync.when(
            loading: () => Center(child: CircularProgressIndicator(color: theme.themeColor)),
            error: (e, _) => Center(child: Text('Błąd: $e', style: TextStyle(color: theme.textColor))),
            data: (list) {
              if (list.isEmpty) {
                return _Empty(
                  icon: Icons.bug_report_outlined,
                  text: 'Brak usterek',
                  sub: 'Żadnych niezgodności — świetnie!',
                  theme: theme,
                );
              }
              final otwarte = list.where((u) => u.isOtwarta).toList();
              final pozostale = list.where((u) => !u.isOtwarta).toList();
              return ListView(
                padding: EdgeInsets.all(16.w),
                children: [
                  if (otwarte.isNotEmpty) ...[
                    _SectionHeader('Otwarte (${otwarte.length})', theme: theme),
                    ...otwarte.map((u) => _UsterkaCard(usterka: u, theme: theme)),
                  ],
                  if (pozostale.isNotEmpty) ...[
                    _SectionHeader('Zamknięte (${pozostale.length})', theme: theme),
                    ...pozostale.map((u) => _UsterkaCard(usterka: u, theme: theme)),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _openProtokol(ProtokołOdbioruModel p) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProtokolDetailScreen(
          protokolId: p.id,
          tytul: p.tytul,
        ),
      ),
    );
  }

  void _addProtokal() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProtokolFormScreen(budowaId: widget.budowaId),
      ),
    ).then((_) => ref.invalidate(protokolyProvider(widget.budowaId)));
  }

  void _addUsterka() {
    // TODO: UsterkaFormScreen
  }
}

class _Empty extends StatelessWidget {
  final IconData icon;
  final String text;
  final String sub;
  final ThemeColors theme;
  const _Empty({required this.icon, required this.text, required this.sub, required this.theme});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: theme.textColor.withAlpha(60)),
              const SizedBox(height: 16),
              Text(text,
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600, color: theme.textColor)),
              const SizedBox(height: 6),
              Text(sub,
                  style: TextStyle(color: theme.textColor.withAlpha(150), fontSize: 13),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final ThemeColors theme;
  const _SectionHeader(this.label, {required this.theme});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 8),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.textColor.withAlpha(150),
                letterSpacing: 0.5)),
      );
}

class _UsterkaCard extends ConsumerWidget {
  final UsterkaModel usterka;
  final ThemeColors theme;
  const _UsterkaCard({required this.usterka, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final u = usterka;
    return Card(
      elevation: 0,
      color: theme.userTile,
      margin: const EdgeInsets.only(bottom: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: u.isPoTerminie ? Colors.red.withAlpha(100) : theme.bordercolor.withAlpha(40),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(u.opis,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.textColor)),
                ),
                UsterkaStatusBadge(u.status),
              ],
            ),
            if (u.lokalizacja.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 12, color: theme.textColor.withAlpha(100)),
                  const SizedBox(width: 4),
                  Text(u.lokalizacja,
                      style: TextStyle(fontSize: 11, color: theme.textColor.withAlpha(150))),
                ],
              ),
            ],
            const SizedBox(height: 6),
            Row(
              children: [
                Text('Odkryto: ${u.dataOdkryciaFmt}',
                    style: TextStyle(fontSize: 11, color: theme.textColor.withAlpha(120))),
                if (u.dataTerminuFmt != null) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.event,
                      size: 12,
                      color: u.isPoTerminie ? Colors.red : theme.textColor.withAlpha(100)),
                  const SizedBox(width: 3),
                  Text(
                    'Termin: ${u.dataTerminuFmt}',
                    style: TextStyle(
                      fontSize: 11,
                      color: u.isPoTerminie ? Colors.red : theme.textColor.withAlpha(120),
                      fontWeight: u.isPoTerminie ? FontWeight.w700 : FontWeight.normal,
                    ),
                  ),
                ],
                const Spacer(),
                if (u.fotoUrls.isNotEmpty)
                  Icon(Icons.photo_camera_outlined,
                      size: 14, color: theme.textColor.withAlpha(100)),
              ],
            ),
            if (u.isOtwarta) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _StatusBtn(
                    label: 'W naprawie',
                    color: const Color(0xFF7B5E00),
                    onTap: () => ref
                        .read(usterkiProvider.notifier)
                        .updateStatus(u.id, StatusUsterki.naprawiana),
                  ),
                  const SizedBox(width: 8),
                  _StatusBtn(
                    label: 'Naprawiono ✓',
                    color: const Color(0xFF1E7A3A),
                    onTap: () => ref
                        .read(usterkiProvider.notifier)
                        .updateStatus(u.id, StatusUsterki.naprawiona),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _StatusBtn({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withAlpha(80)),
          ),
          child: Text(label,
              style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ),
      );
}
