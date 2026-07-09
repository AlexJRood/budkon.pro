import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers/emma_inbox_provider.dart';

/// Sekcja proaktywnych wiadomości Emmy — renderowana nad listą przetargów.
/// Znika gdy brak nowych rekomendacji.
class EmmaInboxWidget extends ConsumerWidget {
  const EmmaInboxWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(emmaInboxProvider);

    return state.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (wiadomosci) {
        if (wiadomosci.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  _EmmaAvatar(),
                  const SizedBox(width: 8),
                  Text(
                    'Emma mówi',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                  ),
                  const Spacer(),
                  Text(
                    '${wiadomosci.length} ${_plural(wiadomosci.length)}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ],
              ),
            ),
            ...wiadomosci.map(
              (w) => _EmmaKarta(wiadomosc: w),
            ),
            const Divider(height: 24, indent: 16, endIndent: 16),
          ],
        );
      },
    );
  }

  String _plural(int n) {
    if (n == 1) return 'nowa rekomendacja';
    if (n < 5) return 'nowe rekomendacje';
    return 'rekomendacji';
  }
}

// ------------------------------------------------------------------ //
// Karta pojedynczej wiadomości Emmy                                    //
// ------------------------------------------------------------------ //

class _EmmaKarta extends ConsumerStatefulWidget {
  final EmmaWiadomosc wiadomosc;
  const _EmmaKarta({required this.wiadomosc});

  @override
  ConsumerState<_EmmaKarta> createState() => _EmmaKartaState();
}

class _EmmaKartaState extends ConsumerState<_EmmaKarta> {
  bool _rozwiniety = false;

  static const _accentColor = Color(0xFFFF9800);

  @override
  Widget build(BuildContext context) {
    final w = widget.wiadomosc;
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _accentColor.withAlpha(18),
            cs.surfaceContainerLow,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accentColor.withAlpha(60)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => _rozwiniety = !_rozwiniety),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nagłówek
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _EmmaAvatar(size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tekst Emmy (zawsze widoczny — 2 linie)
                          Text(
                            w.tekst,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: cs.onSurface,
                                  height: 1.45,
                                ),
                            maxLines: _rozwiniety ? null : 2,
                            overflow: _rozwiniety
                                ? TextOverflow.visible
                                : TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (w.przetargAiScore != null)
                      _ScorePill(score: w.przetargAiScore!),
                  ],
                ),

                // Rozwinięte szczegóły
                if (_rozwiniety) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          w.przetargTytul,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        if (w.wartoscLabel.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          _MetaRow(
                            icon: Icons.payments_outlined,
                            text: w.wartoscLabel,
                            color: cs.primary,
                          ),
                        ],
                        if (w.przetargLokalizacja.isNotEmpty)
                          _MetaRow(
                            icon: Icons.location_on_outlined,
                            text: w.przetargLokalizacja,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Przyciski akcji
                  Row(
                    children: [
                      if (w.kosztorysId != null)
                        Expanded(
                          child: FilledButton.icon(
                            icon: const Icon(Icons.calculate_outlined,
                                size: 16),
                            label: const Text('Otwórz kosztorys'),
                            style: FilledButton.styleFrom(
                              backgroundColor: _accentColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              textStyle: const TextStyle(fontSize: 13),
                            ),
                            onPressed: () {
                              ref
                                  .read(emmaInboxProvider.notifier)
                                  .akceptuj(w.id);
                              Navigator.of(context)
                                  .pushNamed('/kosztorysy/${w.kosztorysId}');
                            },
                          ),
                        ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          child: const Text('Przetarg'),
                          onPressed: () {
                            ref
                                .read(emmaInboxProvider.notifier)
                                .akceptuj(w.id);
                            Navigator.of(context)
                                .pushNamed('/przetargi/${w.przetargId}');
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.close,
                            size: 18, color: cs.onSurfaceVariant),
                        tooltip: 'Odrzuć',
                        onPressed: () =>
                            ref.read(emmaInboxProvider.notifier).odrzuc(w.id),
                      ),
                    ],
                  ),
                ],

                // Strzałka rozwijania
                if (!_rozwiniety)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      size: 16,
                      color: cs.onSurfaceVariant.withOpacity(0.5),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ //
// Helpers                                                              //
// ------------------------------------------------------------------ //

class _EmmaAvatar extends StatelessWidget {
  final double size;
  const _EmmaAvatar({this.size = 22});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF9C27B0), Color(0xFF3F51B5)],
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          'E',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.52,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _ScorePill extends StatelessWidget {
  final int score;
  const _ScorePill({required this.score});

  Color get _color {
    if (score >= 70) return Colors.green.shade700;
    if (score >= 45) return Colors.orange.shade700;
    return Colors.red.shade700;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Text(
        '$score',
        style: TextStyle(
          color: _color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;
  const _MetaRow({required this.icon, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Icon(icon, size: 13, color: c),
          const SizedBox(width: 4),
          Flexible(
            child: Text(text,
                style: TextStyle(
                    fontSize: 12, color: c, fontWeight: color != null ? FontWeight.w600 : null)),
          ),
        ],
      ),
    );
  }
}
