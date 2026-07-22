import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import '../data/models/integracje_model.dart';
import '../data/providers/integracje_provider.dart';
import '../data/services/integracje_api.dart';

class IntegracjeScreen extends ConsumerStatefulWidget {
  const IntegracjeScreen({super.key});

  @override
  ConsumerState<IntegracjeScreen> createState() => _IntegracjeScreenState();
}

class _IntegracjeScreenState extends ConsumerState<IntegracjeScreen>
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
        title: Text('Integracje',
            style: TextStyle(
                color: theme.textColor, fontSize: 15, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: theme.themeColor,
          labelColor: theme.themeColor,
          unselectedLabelColor: theme.textColor.withAlpha(120),
          tabs: const [
            Tab(text: 'GUS/CEIDG'),
            Tab(text: 'KSeF'),
            Tab(text: 'e-Zamówienia'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: const [
          _GusTab(),
          _KsefTab(),
          _EzamowieniaTab(),
        ],
      ),
    );
  }
}

// ============ GUS/CEIDG Tab ============

class _GusTab extends ConsumerStatefulWidget {
  const _GusTab();

  @override
  ConsumerState<_GusTab> createState() => _GusTabState();
}

class _GusTabState extends ConsumerState<_GusTab> {
  final _nipCtrl = TextEditingController();

  @override
  void dispose() {
    _nipCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);
    final async = ref.watch(gusSearchProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Wyszukaj firmę po NIP',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: theme.textColor.withAlpha(150))),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nipCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 10,
                  style: TextStyle(color: theme.textColor),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: 'Wpisz 10-cyfrowy NIP',
                    hintStyle: TextStyle(color: theme.textColor.withAlpha(80), fontSize: 13),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: theme.themeColor, foregroundColor: Colors.white),
                onPressed: () {
                  final nip = _nipCtrl.text.trim();
                  if (nip.length == 10) {
                    ref.read(gusSearchProvider.notifier).szukajNip(nip);
                  }
                },
                child: const Text('Szukaj'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          async.when(
            loading: () => Center(child: CircularProgressIndicator(color: theme.themeColor)),
            error: (e, _) => _ErrorCard('Nie znaleziono firmy lub błąd GUS: $e', theme),
            data: (firma) => firma == null
                ? Center(
                    child: Text('Wpisz NIP i kliknij Szukaj',
                        style: TextStyle(color: theme.textColor.withAlpha(100))))
                : _FirmaCard(firma: firma, theme: theme),
          ),
        ],
      ),
    );
  }
}

class _FirmaCard extends StatelessWidget {
  final FirmaGusModel firma;
  final ThemeColors theme;
  const _FirmaCard({required this.firma, required this.theme});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.userTile,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.bordercolor.withAlpha(50)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(firma.nazwa,
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold, color: theme.textColor)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: firma.aktywna
                        ? const Color(0xFF1E7A3A)
                        : const Color(0xFF7B1F1F),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(firma.aktywna ? 'AKTYWNA' : 'NIEAKTYWNA',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _Row('NIP', firma.nip, theme, copyable: true),
            _Row('REGON', firma.regon, theme, copyable: true),
            if (firma.krs != null) _Row('KRS', firma.krs!, theme, copyable: true),
            if (firma.formaPrawna != null) _Row('Forma prawna', firma.formaPrawna!, theme),
            _Row('Adres', firma.adres, theme),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: firma.nip));
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('NIP skopiowany')));
                },
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Kopiuj NIP'),
                style: OutlinedButton.styleFrom(
                    foregroundColor: theme.themeColor,
                    side: BorderSide(color: theme.themeColor.withAlpha(80))),
              ),
            ),
          ],
        ),
      );
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final ThemeColors theme;
  final bool copyable;
  const _Row(this.label, this.value, this.theme, {this.copyable = false});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 90,
              child: Text(label,
                  style: TextStyle(fontSize: 12, color: theme.textColor.withAlpha(120))),
            ),
            Expanded(
              child: Text(value,
                  style: TextStyle(fontSize: 12, color: theme.textColor)),
            ),
          ],
        ),
      );
}

// ============ KSeF Tab ============

class _KsefTab extends ConsumerWidget {
  const _KsefTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    final async = ref.watch(ksefHistoryProvider);

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.userTile,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.bordercolor.withAlpha(50)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.themeColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.receipt_long, color: theme.themeColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Krajowy System e-Faktur',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold, color: theme.textColor)),
                      Text('Wysyłka faktur do KSeF',
                          style: TextStyle(
                              fontSize: 12, color: theme.textColor.withAlpha(120))),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Faktury można wysłać do KSeF bezpośrednio z widoku faktury. '
                'Poniżej historia wysyłek.',
                style: TextStyle(fontSize: 12, color: theme.textColor.withAlpha(140)),
              ),
            ],
          ),
        ),
        Expanded(
          child: async.when(
            loading: () =>
                Center(child: CircularProgressIndicator(color: theme.themeColor)),
            error: (e, _) => _ErrorCard('Błąd pobierania historii KSeF: $e', theme),
            data: (historia) => historia.isEmpty
                ? Center(
                    child: Text('Brak wysłanych faktur do KSeF',
                        style: TextStyle(color: theme.textColor.withAlpha(100))))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: historia.length,
                    itemBuilder: (_, i) => _KsefTile(s: historia[i], theme: theme),
                  ),
          ),
        ),
      ],
    );
  }
}

class _KsefTile extends StatelessWidget {
  final KsefStatusModel s;
  final ThemeColors theme;
  const _KsefTile({required this.s, required this.theme});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (s.status) {
      StatusKsef.niezgloszona => ('NIEZGŁOSZONA', const Color(0xFF3A3A3A)),
      StatusKsef.oczekuje => ('OCZEKUJE', const Color(0xFF7B5E00)),
      StatusKsef.przyjeta => ('PRZYJĘTA', const Color(0xFF1E7A3A)),
      StatusKsef.odrzucona => ('ODRZUCONA', const Color(0xFF7B1F1F)),
      StatusKsef.blad => ('BŁĄD', const Color(0xFF7B1F1F)),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.userTile,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.bordercolor.withAlpha(40)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Faktura #${s.fakturaId}',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, color: theme.textColor)),
                if (s.ksefNumer != null)
                  Text('KSeF: ${s.ksefNumer}',
                      style: TextStyle(
                          fontSize: 11, color: const Color(0xFF1E7A3A))),
                if (s.bladOpis != null)
                  Text(s.bladOpis!,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF7B1F1F))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
            child: Text(label,
                style: const TextStyle(
                    color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ============ e-Zamówienia Tab ============

class _EzamowieniaTab extends ConsumerStatefulWidget {
  const _EzamowieniaTab();

  @override
  ConsumerState<_EzamowieniaTab> createState() => _EzamowieniaTabState();
}

class _EzamowieniaTabState extends ConsumerState<_EzamowieniaTab> {
  final _szukajCtrl = TextEditingController();
  final _cpvCtrl = TextEditingController();

  @override
  void dispose() {
    _szukajCtrl.dispose();
    _cpvCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);
    final async = ref.watch(przetargiProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _szukajCtrl,
                      style: TextStyle(color: theme.textColor),
                      decoration: InputDecoration(
                        hintText: 'Fraza (np. roboty budowlane)',
                        hintStyle: TextStyle(
                            color: theme.textColor.withAlpha(80), fontSize: 13),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _cpvCtrl,
                      style: TextStyle(color: theme.textColor),
                      decoration: InputDecoration(
                        hintText: 'Kod CPV',
                        hintStyle: TextStyle(
                            color: theme.textColor.withAlpha(80), fontSize: 13),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: theme.themeColor, foregroundColor: Colors.white),
                  icon: const Icon(Icons.search, size: 16),
                  label: const Text('Szukaj przetargów'),
                  onPressed: () => ref.read(przetargiProvider.notifier).szukaj(
                        fraza: _szukajCtrl.text.trim().isEmpty
                            ? null
                            : _szukajCtrl.text.trim(),
                        cpv: _cpvCtrl.text.trim().isEmpty ? null : _cpvCtrl.text.trim(),
                      ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: async.when(
            loading: () =>
                Center(child: CircularProgressIndicator(color: theme.themeColor)),
            error: (e, _) => _ErrorCard('Błąd: $e', theme),
            data: (przetargi) => przetargi.isEmpty
                ? Center(
                    child: Text('Wpisz frazę i szukaj przetargów',
                        style: TextStyle(color: theme.textColor.withAlpha(100))))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: przetargi.length,
                    itemBuilder: (_, i) =>
                        _PrzetargCard(p: przetargi[i], theme: theme),
                  ),
          ),
        ),
      ],
    );
  }
}

class _PrzetargCard extends StatelessWidget {
  final PrzetargPublicznyModel p;
  final ThemeColors theme;
  const _PrzetargCard({required this.p, required this.theme});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.userTile,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: p.krotkoTerminowy
                ? const Color(0xFF7B5E00).withAlpha(80)
                : theme.bordercolor.withAlpha(50),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(p.tytul,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: theme.textColor)),
            const SizedBox(height: 4),
            Text(p.zamawiajacy,
                style: TextStyle(fontSize: 12, color: theme.textColor.withAlpha(140))),
            const SizedBox(height: 6),
            Row(
              children: [
                if (p.cpv != null) ...[
                  _chip('CPV: ${p.cpv}', theme.themeColor.withAlpha(20), theme.themeColor),
                  const SizedBox(width: 8),
                ],
                _chip(
                  'Termin: ${p.terminSkladania.day}.${p.terminSkladania.month}.${p.terminSkladania.year}',
                  p.krotkoTerminowy
                      ? const Color(0xFF7B5E00).withAlpha(30)
                      : theme.bordercolor.withAlpha(20),
                  p.krotkoTerminowy
                      ? const Color(0xFF7B5E00)
                      : theme.textColor.withAlpha(120),
                ),
                if (p.wartoscSzacunkowa != null) ...[
                  const SizedBox(width: 8),
                  _chip(
                    '≈${(p.wartoscSzacunkowa! / 1000).toStringAsFixed(0)}k zł',
                    theme.userTile,
                    theme.textColor.withAlpha(120),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                // url_launcher would open p.url
              },
              child: Row(
                children: [
                  Icon(Icons.open_in_new, size: 13, color: theme.themeColor),
                  const SizedBox(width: 4),
                  Text('Otwórz w e-Zamówieniach',
                      style: TextStyle(
                          fontSize: 12,
                          color: theme.themeColor,
                          decoration: TextDecoration.underline)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _chip(String label, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
        child: Text(label, style: TextStyle(fontSize: 10, color: fg)),
      );
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final ThemeColors theme;
  const _ErrorCard(this.message, this.theme);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF7B1F1F).withAlpha(15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF7B1F1F).withAlpha(60)),
          ),
          child: Text(message,
              style: const TextStyle(fontSize: 13, color: Color(0xFF7B1F1F))),
        ),
      );
}
