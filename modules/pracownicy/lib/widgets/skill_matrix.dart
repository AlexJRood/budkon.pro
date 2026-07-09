import 'package:flutter/material.dart';
import '../data/models/pracownicy_model.dart';

/// Macierz umiejętności pracownika — wizualna siatka spec × poziom.
class SkillMatrix extends StatelessWidget {
  final List<UmiejetnoscModel> umiejetnosci;
  final VoidCallback? onDodaj;

  const SkillMatrix({
    super.key,
    required this.umiejetnosci,
    this.onDodaj,
  });

  @override
  Widget build(BuildContext context) {
    if (umiejetnosci.isEmpty) {
      return _EmptyMatrix(onDodaj: onDodaj);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...umiejetnosci.map((u) => _SkillRow(umiejetnosc: u)),
        if (onDodaj != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Dodaj umiejętność'),
              onPressed: onDodaj,
            ),
          ),
      ],
    );
  }
}

class _SkillRow extends StatelessWidget {
  final UmiejetnoscModel umiejetnosc;
  const _SkillRow({required this.umiejetnosc});

  Color _levelColor(PoziomDoswiadczenia p) => switch (p) {
        PoziomDoswiadczenia.uczen => const Color(0xFF9E9E9E),
        PoziomDoswiadczenia.junior => const Color(0xFF4FC3F7),
        PoziomDoswiadczenia.mid => const Color(0xFF4CAF50),
        PoziomDoswiadczenia.senior => const Color(0xFFFF9800),
        PoziomDoswiadczenia.ekspert => const Color(0xFFE91E63),
      };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final spec = umiejetnosc.specjalizacja;
    final poziom = umiejetnosc.poziom;
    final color = _levelColor(poziom);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(spec.emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                spec.label,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
            // Lata doświadczenia
            if (umiejetnosc.lataDowiadczenia > 0)
              Text(
                '${umiejetnosc.lataDowiadczenia} lat',
                style: TextStyle(color: cs.outline, fontSize: 11),
              ),
            const SizedBox(width: 10),
            // Badge poziomu
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withAlpha(80)),
              ),
              child: Text(
                poziom.label.split('(').first.trim(),
                style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ]),

          const SizedBox(height: 5),

          // Pasek poziomu — 5 kropek
          _LevelDots(rank: poziom.rank, color: color),

          // Certyfikat
          if (umiejetnosc.certyfikat.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 24),
              child: Row(children: [
                Icon(
                  umiejetnosc.certyfikatWazny
                      ? Icons.verified_outlined
                      : Icons.warning_amber_outlined,
                  size: 13,
                  color: umiejetnosc.certyfikatWazny
                      ? const Color(0xFF4CAF50)
                      : Colors.orange,
                ),
                const SizedBox(width: 4),
                Text(
                  umiejetnosc.certyfikat,
                  style: TextStyle(
                    color: umiejetnosc.certyfikatWazny
                        ? cs.outline
                        : Colors.orange,
                    fontSize: 11,
                  ),
                ),
                if (umiejetnosc.certyfikatWaznyDo != null) ...[
                  Text(
                    ' (do ${umiejetnosc.certyfikatWaznyDo})',
                    style: TextStyle(color: cs.outline, fontSize: 10),
                  ),
                ],
              ]),
            ),

          // Stawka specjalizacji
          if (umiejetnosc.stawkaSpecjalizacji != null)
            Padding(
              padding: const EdgeInsets.only(top: 3, left: 24),
              child: Text(
                '${umiejetnosc.stawkaSpecjalizacji!.toStringAsFixed(2)} PLN/h',
                style: TextStyle(
                    color: cs.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }
}

class _LevelDots extends StatelessWidget {
  final int rank; // 1-5
  final Color color;
  const _LevelDots({required this.rank, required this.color});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 24),
        child: Row(
          children: List.generate(5, (i) {
            final filled = i < rank;
            return Padding(
              padding: const EdgeInsets.only(right: 5),
              child: Container(
                width: 24,
                height: 6,
                decoration: BoxDecoration(
                  color: filled ? color : color.withAlpha(30),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            );
          }),
        ),
      );
}

class _EmptyMatrix extends StatelessWidget {
  final VoidCallback? onDodaj;
  const _EmptyMatrix({this.onDodaj});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Icon(Icons.psychology_outlined,
              size: 40, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 8),
          Text(
            'Brak zarejestrowanych umiejętności',
            style: TextStyle(
                color: Theme.of(context).colorScheme.outline),
          ),
          if (onDodaj != null) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Dodaj pierwszą'),
              onPressed: onDodaj,
            ),
          ],
        ],
      );
}

// ---- Mini karta umiejętności (do listy pracowników) -----------------------

class SkillChips extends StatelessWidget {
  final List<Map<String, dynamic>> specjalizacje;
  final int max;

  const SkillChips({super.key, required this.specjalizacje, this.max = 3});

  @override
  Widget build(BuildContext context) {
    final visible = specjalizacje.take(max).toList();
    final rest = specjalizacje.length - max;

    return Wrap(
      spacing: 5,
      runSpacing: 4,
      children: [
        ...visible.map((s) {
          final spec =
              Specjalizacja.fromValue((s['specjalizacja'] ?? '').toString());
          final poziom = PoziomDoswiadczenia.fromValue(
              (s['poziom'] ?? 'mid').toString());
          return _MiniChip(spec: spec, poziom: poziom);
        }),
        if (rest > 0)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '+$rest',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.outline,
                  fontSize: 10),
            ),
          ),
      ],
    );
  }
}

class _MiniChip extends StatelessWidget {
  final Specjalizacja spec;
  final PoziomDoswiadczenia poziom;
  const _MiniChip({required this.spec, required this.poziom});

  Color get _color => switch (poziom) {
        PoziomDoswiadczenia.uczen => const Color(0xFF9E9E9E),
        PoziomDoswiadczenia.junior => const Color(0xFF4FC3F7),
        PoziomDoswiadczenia.mid => const Color(0xFF4CAF50),
        PoziomDoswiadczenia.senior => const Color(0xFFFF9800),
        PoziomDoswiadczenia.ekspert => const Color(0xFFE91E63),
      };

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: _color.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _color.withAlpha(60)),
        ),
        child: Text(
          '${spec.emoji} ${spec.label.split('/').first.trim()}',
          style: TextStyle(
              color: _color, fontSize: 10, fontWeight: FontWeight.w600),
        ),
      );
}
