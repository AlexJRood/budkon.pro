import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import '../data/models/analytics_model.dart';
import '../data/providers/analytics_provider.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen>
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
        title: Text('Analytics',
            style: TextStyle(
                color: theme.textColor, fontSize: 15, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: theme.themeColor,
          labelColor: theme.themeColor,
          unselectedLabelColor: theme.textColor.withAlpha(120),
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'Ranking'),
            Tab(text: 'Raporty'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: const [
          _DashboardTab(),
          _RankingTab(),
          _RaportTab(),
        ],
      ),
    );
  }
}

// ============ DASHBOARD ============

class _DashboardTab extends ConsumerWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    final kpiAsync = ref.watch(kpiProvider);
    final trendAsync = ref.watch(trendPrzychoduProvider);
    final marzaAsync = ref.watch(trendMarzyProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI cards
          kpiAsync.when(
            loading: () =>
                Center(child: CircularProgressIndicator(color: theme.themeColor)),
            error: (e, _) => _blad('$e', theme),
            data: (kpi) => _KpiGrid(kpi: kpi, theme: theme),
          ),
          const SizedBox(height: 16),
          // Trend przychodów
          Text('Trend przychodów (12 mies.)',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: theme.textColor)),
          const SizedBox(height: 8),
          trendAsync.when(
            loading: () =>
                Center(child: CircularProgressIndicator(color: theme.themeColor)),
            error: (e, _) => _blad('$e', theme),
            data: (trend) => _TrendChart(punkty: trend, color: theme.themeColor, theme: theme),
          ),
          const SizedBox(height: 16),
          Text('Trend marży (%)',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: theme.textColor)),
          const SizedBox(height: 8),
          marzaAsync.when(
            loading: () =>
                Center(child: CircularProgressIndicator(color: theme.themeColor)),
            error: (e, _) => _blad('$e', theme),
            data: (trend) => _TrendChart(
                punkty: trend, color: const Color(0xFF1E7A3A), theme: theme,
                formatujWartosc: (v) => '${v.toStringAsFixed(1)}%'),
          ),
        ],
      ),
    );
  }

  Widget _blad(String msg, ThemeColors theme) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF7B1F1F).withAlpha(15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(msg,
            style: const TextStyle(fontSize: 12, color: Color(0xFF7B1F1F))),
      );
}

class _KpiGrid extends StatelessWidget {
  final FirmoweKpiModel kpi;
  final ThemeColors theme;
  const _KpiGrid({required this.kpi, required this.theme});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: _KpiKarta(
                      tytul: 'Przychód (mies.)',
                      wartosc:
                          '${(kpi.przychodMiesiac / 1000).toStringAsFixed(0)}k zł',
                      ikona: Icons.trending_up,
                      kolor: const Color(0xFF1E7A3A),
                      theme: theme)),
              const SizedBox(width: 10),
              Expanded(
                  child: _KpiKarta(
                      tytul: 'Zysk (mies.)',
                      wartosc:
                          '${(kpi.zyskMiesiac / 1000).toStringAsFixed(0)}k zł',
                      ikona: Icons.account_balance_wallet_outlined,
                      kolor: kpi.zyskMiesiac >= 0
                          ? const Color(0xFF1E7A3A)
                          : const Color(0xFF7B1F1F),
                      theme: theme)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: _KpiKarta(
                      tytul: 'Marża śr.',
                      wartosc: '${kpi.marzaSrednia.toStringAsFixed(1)}%',
                      ikona: Icons.percent,
                      kolor: theme.themeColor,
                      theme: theme)),
              const SizedBox(width: 10),
              Expanded(
                  child: _KpiKarta(
                      tytul: 'Budowy aktywne',
                      wartosc: '${kpi.budowyAktywne}',
                      ikona: Icons.construction_outlined,
                      kolor: const Color(0xFF3A3A3A),
                      theme: theme)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: _KpiKarta(
                      tytul: 'Należności',
                      wartosc:
                          '${(kpi.naleznosciOgolne / 1000).toStringAsFixed(0)}k zł',
                      ikona: Icons.receipt_outlined,
                      kolor: const Color(0xFF7B5E00),
                      theme: theme)),
              const SizedBox(width: 10),
              Expanded(
                  child: _KpiKarta(
                      tytul: 'Przychód (rok)',
                      wartosc:
                          '${(kpi.przychodRok / 1000).toStringAsFixed(0)}k zł',
                      ikona: Icons.bar_chart,
                      kolor: theme.themeColor,
                      theme: theme)),
            ],
          ),
        ],
      );
}

class _KpiKarta extends StatelessWidget {
  final String tytul;
  final String wartosc;
  final IconData ikona;
  final Color kolor;
  final ThemeColors theme;
  const _KpiKarta(
      {required this.tytul,
      required this.wartosc,
      required this.ikona,
      required this.kolor,
      required this.theme});

  @override
  Widget build(BuildContext context) => Container(
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
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                      color: kolor.withAlpha(20),
                      borderRadius: BorderRadius.circular(8)),
                  child: Icon(ikona, color: kolor, size: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(wartosc,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: theme.textColor)),
            const SizedBox(height: 2),
            Text(tytul,
                style: TextStyle(
                    fontSize: 11, color: theme.textColor.withAlpha(120))),
          ],
        ),
      );
}

class _TrendChart extends StatelessWidget {
  final List<TrendPunktModel> punkty;
  final Color color;
  final ThemeColors theme;
  final String Function(double)? formatujWartosc;
  const _TrendChart(
      {required this.punkty,
      required this.color,
      required this.theme,
      this.formatujWartosc});

  @override
  Widget build(BuildContext context) {
    if (punkty.isEmpty) {
      return Container(
        height: 100,
        alignment: Alignment.center,
        child: Text('Brak danych',
            style: TextStyle(color: theme.textColor.withAlpha(100))),
      );
    }

    return Container(
      height: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.userTile,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.bordercolor.withAlpha(40)),
      ),
      child: CustomPaint(
        painter: _SparklinePainter(punkty: punkty, color: color, theme: theme),
        child: Align(
          alignment: Alignment.topRight,
          child: Text(
            formatujWartosc != null
                ? formatujWartosc!(punkty.last.wartosc)
                : '${(punkty.last.wartosc / 1000).toStringAsFixed(0)}k zł',
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: color),
          ),
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<TrendPunktModel> punkty;
  final Color color;
  final ThemeColors theme;
  const _SparklinePainter(
      {required this.punkty, required this.color, required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    if (punkty.isEmpty) return;

    final wartosci = punkty.map((p) => p.wartosc).toList();
    final minV = wartosci.reduce(math.min);
    final maxV = wartosci.reduce(math.max);
    final range = (maxV - minV).abs();
    if (range == 0) return;

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color.withAlpha(25)
      ..style = PaintingStyle.fill;

    final step = size.width / (punkty.length - 1);

    Path linePath = Path();
    Path fillPath = Path();
    fillPath.moveTo(0, size.height);

    for (var i = 0; i < punkty.length; i++) {
      final x = i * step;
      final y = size.height - ((wartosci[i] - minV) / range) * size.height;
      if (i == 0) {
        linePath.moveTo(x, y);
        fillPath.lineTo(x, y);
      } else {
        linePath.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // Grid lines
    final gridPaint = Paint()
      ..color = theme.bordercolor.withAlpha(30)
      ..strokeWidth = 0.5;
    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(linePath, linePaint);

    // Last point dot
    final lastX = (punkty.length - 1) * step;
    final lastY = size.height -
        ((wartosci.last - minV) / range) * size.height;
    canvas.drawCircle(
        Offset(lastX, lastY),
        4,
        Paint()..color = color);
    canvas.drawCircle(
        Offset(lastX, lastY),
        2,
        Paint()..color = theme.userTile);
  }

  @override
  bool shouldRepaint(_SparklinePainter old) => old.punkty != punkty;
}

// ============ RANKING ============

class _RankingTab extends ConsumerWidget {
  const _RankingTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    final async = ref.watch(rankingRentownosciProvider);

    return async.when(
      loading: () =>
          Center(child: CircularProgressIndicator(color: theme.themeColor)),
      error: (e, _) => Center(
          child: Text('Błąd: $e',
              style: const TextStyle(color: Color(0xFF7B1F1F)))),
      data: (budowy) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Ranking rentowności budów',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor.withAlpha(150))),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: budowy.length,
              itemBuilder: (_, i) =>
                  _RankingRow(budowa: budowy[i], pozycja: i + 1, theme: theme),
            ),
          ),
        ],
      ),
    );
  }
}

class _RankingRow extends StatelessWidget {
  final BudowaKartaModel budowa;
  final int pozycja;
  final ThemeColors theme;
  const _RankingRow(
      {required this.budowa, required this.pozycja, required this.theme});

  @override
  Widget build(BuildContext context) {
    final Color rankKolor = pozycja == 1
        ? const Color(0xFFD4AF37)
        : pozycja == 2
            ? const Color(0xFF9E9E9E)
            : pozycja == 3
                ? const Color(0xFF8B5E3C)
                : theme.textColor.withAlpha(80);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.userTile,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: budowa.naMinusie
              ? const Color(0xFF7B1F1F).withAlpha(60)
              : theme.bordercolor.withAlpha(40),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              '#$pozycja',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: rankKolor),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(budowa.nazwa,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.textColor)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text('Przychód: ${(budowa.przychodCalkowity / 1000).toStringAsFixed(0)}k zł',
                        style: TextStyle(
                            fontSize: 11, color: theme.textColor.withAlpha(130))),
                    const SizedBox(width: 12),
                    Text('Koszt: ${(budowa.kosztCalkowity / 1000).toStringAsFixed(0)}k zł',
                        style: TextStyle(
                            fontSize: 11, color: theme.textColor.withAlpha(130))),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: (budowa.marza / 100).clamp(0, 1),
                    minHeight: 4,
                    backgroundColor: theme.bordercolor.withAlpha(50),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      budowa.naMinusie
                          ? const Color(0xFF7B1F1F)
                          : const Color(0xFF1E7A3A),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${budowa.marza.toStringAsFixed(1)}%',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: budowa.naMinusie
                        ? const Color(0xFF7B1F1F)
                        : const Color(0xFF1E7A3A)),
              ),
              Text('marża',
                  style: TextStyle(
                      fontSize: 10, color: theme.textColor.withAlpha(100))),
            ],
          ),
        ],
      ),
    );
  }
}

// ============ RAPORTY ============

class _RaportTab extends ConsumerWidget {
  const _RaportTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    final async = ref.watch(raportMiesiecznyProvider(null));

    return async.when(
      loading: () =>
          Center(child: CircularProgressIndicator(color: theme.themeColor)),
      error: (e, _) => Center(
          child: Text('Błąd: $e',
              style: const TextStyle(color: Color(0xFF7B1F1F)))),
      data: (raporty) => raporty.isEmpty
          ? Center(
              child: Text('Brak raportów',
                  style: TextStyle(color: theme.textColor.withAlpha(120))))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: raporty.length,
              itemBuilder: (_, i) => _RaportKarta(r: raporty[i], theme: theme),
            ),
    );
  }
}

class _RaportKarta extends StatelessWidget {
  final RaportMiesiecznyModel r;
  final ThemeColors theme;
  const _RaportKarta({required this.r, required this.theme});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.userTile,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.bordercolor.withAlpha(40)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(r.tytul,
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold, color: theme.textColor)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                    child: _MiniStat(
                        label: 'Przychód',
                        wartosc:
                            '${(r.przychod / 1000).toStringAsFixed(0)}k',
                        kolor: const Color(0xFF1E7A3A),
                        theme: theme)),
                Expanded(
                    child: _MiniStat(
                        label: 'Koszt',
                        wartosc: '${(r.koszt / 1000).toStringAsFixed(0)}k',
                        kolor: theme.textColor.withAlpha(150),
                        theme: theme)),
                Expanded(
                    child: _MiniStat(
                        label: 'Zysk',
                        wartosc: '${(r.zysk / 1000).toStringAsFixed(0)}k',
                        kolor: r.zysk >= 0
                            ? const Color(0xFF1E7A3A)
                            : const Color(0xFF7B1F1F),
                        theme: theme)),
              ],
            ),
            if (r.budowyWRaporcie.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('${r.budowyWRaporcie.length} budów w raporcie',
                  style: TextStyle(
                      fontSize: 11, color: theme.textColor.withAlpha(120))),
            ],
          ],
        ),
      );
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String wartosc;
  final Color kolor;
  final ThemeColors theme;
  const _MiniStat(
      {required this.label,
      required this.wartosc,
      required this.kolor,
      required this.theme});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(wartosc,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, color: kolor)),
          Text(label,
              style: TextStyle(
                  fontSize: 10, color: theme.textColor.withAlpha(110))),
        ],
      );
}
