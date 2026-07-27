import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import '../../../data/models/projekt_budowlany_model.dart';

class ProjektPomieszczeniaTab extends ConsumerWidget {
  const ProjektPomieszczeniaTab({super.key, required this.projekt});
  final ProjektBudowlanyDetailModel projekt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    final pom = projekt.pomieszczenia;

    if (pom.isEmpty) {
      return Center(
        child: Text('Brak danych pomieszczeń',
            style: TextStyle(color: theme.textColor.withOpacity(0.5))),
      );
    }

    // Grupuj po kondygnacji
    final Map<String, List<PomieszczenieProjektuModel>> byKond = {};
    for (final p in pom) {
      byKond.putIfAbsent(p.kondygnacjaId, () => []).add(p);
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Podsumowanie powierzchni
        _PodsumowanieRow(
          pom: pom,
          theme: theme,
          totalPum: projekt.powierzchniaUzytkowa,
        ),
        const SizedBox(height: 16),
        ...byKond.entries.map((entry) => _KondygnacjaSection(
              label: entry.key,
              pomieszczenia: entry.value,
              theme: theme,
            )),
      ],
    );
  }
}

class _PodsumowanieRow extends StatelessWidget {
  const _PodsumowanieRow(
      {required this.pom, required this.theme, required this.totalPum});

  final List<PomieszczenieProjektuModel> pom;
  final dynamic theme;
  final double? totalPum;

  @override
  Widget build(BuildContext context) {
    final sumPow = pom.fold(0.0, (s, p) => s + (p.powierzchniaM2 ?? 0));
    return Card(
      color: theme.themeColor.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _StatItem(
              label: 'Pomieszczeń',
              value: '${pom.length}',
              theme: theme,
            ),
            const SizedBox(width: 24),
            _StatItem(
              label: 'Suma pow.',
              value: '${sumPow.toStringAsFixed(1)} m²',
              theme: theme,
            ),
            if (totalPum != null) ...[
              const SizedBox(width: 24),
              _StatItem(
                label: 'PUM projekt',
                value: '${totalPum!.toStringAsFixed(1)} m²',
                theme: theme,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value, required this.theme});
  final String label;
  final String value;
  final dynamic theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 11, color: theme.textColor.withOpacity(0.6))),
        Text(value,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: theme.textColor)),
      ],
    );
  }
}

class _KondygnacjaSection extends StatelessWidget {
  const _KondygnacjaSection({
    required this.label,
    required this.pomieszczenia,
    required this.theme,
  });

  final String label;
  final List<PomieszczenieProjektuModel> pomieszczenia;
  final dynamic theme;

  @override
  Widget build(BuildContext context) {
    final sumKond =
        pomieszczenia.fold(0.0, (s, p) => s + (p.powierzchniaM2 ?? 0));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: theme.themeColor)),
              const Spacer(),
              Text('${sumKond.toStringAsFixed(1)} m²',
                  style: TextStyle(
                      fontSize: 13,
                      color: theme.textColor.withOpacity(0.6))),
            ],
          ),
        ),
        Card(
          color: theme.cardColor,
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: pomieszczenia
                .asMap()
                .entries
                .map((e) => _PomieszczenieTile(
                      pom: e.value,
                      theme: theme,
                      isLast: e.key == pomieszczenia.length - 1,
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _PomieszczenieTile extends StatelessWidget {
  const _PomieszczenieTile({
    required this.pom,
    required this.theme,
    required this.isLast,
  });

  final PomieszczenieProjektuModel pom;
  final dynamic theme;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final wymiaryParts = <String>[
      if (pom.wymiarAm != null && pom.wymiarBm != null)
        '${pom.wymiarAm!.toStringAsFixed(2)} × ${pom.wymiarBm!.toStringAsFixed(2)} m',
      if (pom.wysokoscM != null)
        'wys. ${pom.wysokoscM!.toStringAsFixed(2)} m${pom.sufitSkosny ? ' (skos)' : ''}',
    ];
    final wymiaryStr = wymiaryParts.isEmpty ? null : wymiaryParts.join('  •  ');

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(pom.nazwa,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: theme.textColor)),
                        if (pom.wymiarySkoryg) ...[
                          const SizedBox(width: 6),
                          Tooltip(
                            message: 'Wymiary zostały skorygowane automatycznie',
                            child: Icon(Icons.auto_fix_high,
                                size: 14, color: Colors.orange),
                          ),
                        ],
                        if (pom.sufitSkosny) ...[
                          const SizedBox(width: 6),
                          Tooltip(
                            message: 'Sufit skośny (poddasze)',
                            child: Icon(Icons.change_history,
                                size: 13, color: theme.textColor.withOpacity(0.4)),
                          ),
                        ],
                        if (!pom.wymiarySpojne) ...[
                          const SizedBox(width: 6),
                          Tooltip(
                            message: 'Niespójne wymiary',
                            child: Icon(Icons.warning_amber_outlined,
                                size: 14, color: theme.errorColor),
                          ),
                        ],
                      ],
                    ),
                    if (wymiaryStr != null)
                      Text(wymiaryStr,
                          style: TextStyle(
                              fontSize: 11,
                              color: theme.textColor.withOpacity(0.5))),
                  ],
                ),
              ),
              if (pom.powierzchniaM2 != null)
                Text('${pom.powierzchniaM2!.toStringAsFixed(2)} m²',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.themeColor)),
            ],
          ),
        ),
        if (!isLast)
          Divider(height: 1, color: theme.textColor.withOpacity(0.08)),
      ],
    );
  }
}
