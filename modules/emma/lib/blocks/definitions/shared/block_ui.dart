import 'dart:math' as math;

import 'package:flutter/material.dart';

class EmmaBlockCardShell extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final Color borderColor;
  final EdgeInsetsGeometry? padding;

  /// Kolorowa listwa akcentu przy lewej krawędzi (powiązana z typem bloku).
  /// Można wyłączyć np. dla bloków, które same rysują pełne tło (obraz).
  final bool showAccentRail;

  const EmmaBlockCardShell({
    super.key,
    required this.child,
    required this.maxWidth,
    required this.borderColor,
    this.padding,
    this.showAccentRail = true,
  });

  @override
  Widget build(BuildContext context) {
    final accent = borderColor;

    return Container(
      margin: const EdgeInsets.only(left: 8, right: 8, top: 4, bottom: 8),
      constraints: BoxConstraints(maxWidth: maxWidth),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        // Szklisty gradient z ledwo widocznym odcieniem akcentu u góry —
        // zamiast płaskiej półprzezroczystej czerni.
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.alphaBlend(accent.withAlpha(20), Colors.black.withAlpha(128)),
            Colors.black.withAlpha(140),
          ],
        ),
        border: Border.all(color: accent.withAlpha(64), width: 1),
        boxShadow: [
          // Delikatna poświata w kolorze akcentu + cień dla głębi.
          BoxShadow(
            color: accent.withAlpha(30),
            blurRadius: 18,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.black.withAlpha(48),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      // Stack zamiast IntrinsicHeight+Row: listwa wypełnia realną wysokość karty
      // (Positioned.fill), więc nie wymuszamy intrinsic dimensions na 26 różnych
      // blokach (listy/obrazy/scrollable potrafią ich nie wspierać).
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(left: showAccentRail ? 3 : 0),
            child: Padding(
              padding: padding ?? const EdgeInsets.all(12),
              child: child,
            ),
          ),
          if (showAccentRail)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [accent, accent.withAlpha(140)],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Ikona w zaokrąglonym kaflu w kolorze akcentu — spójny nagłówek bloków.
class EmmaAccentIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const EmmaAccentIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size = 28,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(size * 0.3),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Icon(icon, color: color, size: size * 0.55),
    );
  }
}

/// Tekst z przesuwającym się połyskiem — spójny język „pracuję…" z animacją
/// generowania obrazu. Podaj [animation] (0→1, repeat), żeby współdzielić kontroler.
class EmmaShimmerText extends StatelessWidget {
  final String text;
  final Animation<double> animation;
  final Color baseColor;
  final Color highlightColor;
  final TextStyle style;

  const EmmaShimmerText({
    super.key,
    required this.text,
    required this.animation,
    required this.style,
    this.baseColor = const Color(0xB3FFFFFF),
    this.highlightColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value;
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (rect) {
            return LinearGradient(
              begin: Alignment(-1.0 + 2.0 * t - 0.5, 0),
              end: Alignment(-1.0 + 2.0 * t + 0.5, 0),
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0.35, 0.5, 0.65],
            ).createShader(rect);
          },
          child: Text(text, style: style),
        );
      },
    );
  }
}

/// Trzy płynnie pulsujące kropki (faza z [t] 0→1).
class EmmaFlowingDots extends StatelessWidget {
  final double t;
  final Color color;
  final double size;

  const EmmaFlowingDots({
    super.key,
    required this.t,
    required this.color,
    this.size = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final phase = (t + i * 0.2) % 1.0;
        final op = 0.3 + 0.7 * (0.5 + 0.5 * math.sin(phase * math.pi * 2));
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.5),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color.withValues(alpha: op.clamp(0.0, 1.0)),
              shape: BoxShape.circle,
            ),
          ),
        );
      }),
    );
  }
}

class EmmaActionPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool enabled;
  final Color? color;

  const EmmaActionPill({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.enabled = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final base = color ?? Colors.white;
    final fg = enabled ? base : base.withAlpha(90);
    final bg = enabled ? base.withAlpha(18) : base.withAlpha(8);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EmmaTag extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const EmmaTag({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(90)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}