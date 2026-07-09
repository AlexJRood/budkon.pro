import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Proporcje obrazu z pól `width`/`height` przysyłanych przez backend.
///
/// Dzięki nim rezerwujemy właściwy kształt ZANIM obraz się wczyta — placeholder
/// generowania ma ten sam kształt co docelowy obraz, więc layout nie skacze.
/// Bezpieczny fallback 1:1 oraz clamp, żeby skrajne wartości nie rozwaliły layoutu.
double emmaAspectRatioFrom(Map<String, dynamic> raw) {
  final w = double.tryParse((raw['width'] ?? '').toString()) ?? 0;
  final h = double.tryParse((raw['height'] ?? '').toString()) ?? 0;
  if (w <= 0 || h <= 0) return 1.0;
  return (w / h).clamp(0.4, 2.5);
}

/// Animowany placeholder „generowania" — ciemne tło, wędrujący połysk, pulsująca
/// ikonka i kropki. Samowystarczalny (własny kontroler), więc może być użyty
/// zarówno w bloku ładowania narzędzia, jak i pod docelowym obrazem.
class GeneratingPlaceholder extends StatefulWidget {
  final String label;
  final String? sublabel;

  const GeneratingPlaceholder({
    super.key,
    this.label = 'Generuję obraz…',
    this.sublabel,
  });

  @override
  State<GeneratingPlaceholder> createState() => _GeneratingPlaceholderState();
}

class _GeneratingPlaceholderState extends State<GeneratingPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, _) {
        final t = _shimmer.value;
        return Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-1.0 + 2.0 * t - 0.6, -1.0),
                  end: Alignment(-1.0 + 2.0 * t + 0.6, 1.0),
                  colors: const [
                    Color(0xFF1C1B2E),
                    Color(0xFF2E2A4A),
                    Color(0xFF3A2F63),
                    Color(0xFF2E2A4A),
                    Color(0xFF1C1B2E),
                  ],
                  stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: 1.0 + 0.15 * math.sin(t * math.pi * 2),
                    child: const Icon(Icons.auto_awesome_rounded,
                        color: Color(0xFFC9B6FF), size: 34),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withAlpha(210),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                  if ((widget.sublabel ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        widget.sublabel!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withAlpha(130),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  _Dots(t: t),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Dots extends StatelessWidget {
  final double t;
  const _Dots({required this.t});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final phase = (t + i * 0.2) % 1.0;
        final op = 0.3 + 0.7 * (0.5 + 0.5 * math.sin(phase * math.pi * 2));
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFF9B6BFF).withValues(alpha: op.clamp(0.0, 1.0)),
              shape: BoxShape.circle,
            ),
          ),
        );
      }),
    );
  }
}
