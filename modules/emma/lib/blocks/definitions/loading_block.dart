import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';

import '../core/block_definition.dart';
import '../core/block_descriptor.dart';
import 'shared/block_ui.dart';
import 'shared/generating_placeholder.dart';

class LoadingBlockDefinition extends EmmaBlockDefinition {
  const LoadingBlockDefinition();

  @override
  String get key => 'loading';

  @override
  bool supports(EmmaBlockDescriptor block) {
    return block.type == EmmaBlockType.loading;
  }

  @override
  Widget buildBlock({
    required BuildContext context,
    required WidgetRef ref,
    required EmmaBlockDescriptor block,
    required double maxWidth,
    required String messageId,
  }) {
    final title = (block.raw['title'] ?? 'Loading...'.tr).toString();
    // Backend wysyła `detail`/`description`; `subtitle` zostaje jako fallback.
    final subtitle = (block.raw['subtitle'] ??
            block.raw['detail'] ??
            block.raw['description'] ??
            '')
        .toString();

    // Generacja obrazu dostaje pełnoprawny, animowany placeholder w proporcji
    // docelowego obrazu — dzięki temu blok płynnie „staje się" obrazem.
    final blockType = (block.raw['block_type'] ?? '').toString().toLowerCase();
    final isImageGeneration = blockType.contains('generate_image');

    if (isImageGeneration) {
      return EmmaBlockCardShell(
        maxWidth: maxWidth,
        borderColor: const Color(0xFF9B6BFF),
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome_rounded,
                    color: Color(0xFF9B6BFF), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                // Backend przysyła docelowe wymiary już w tool_call_started,
                // więc shimmer ma od razu kształt przyszłego obrazu.
                aspectRatio: emmaAspectRatioFrom(block.raw),
                child: GeneratingPlaceholder(
                  label: 'Generuję obraz…',
                  sublabel: subtitle.trim().isEmpty ? null : subtitle,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return EmmaBlockCardShell(
      maxWidth: maxWidth,
      borderColor: const Color(0xFF37B6FF),
      child: _LoadingContent(title: title, subtitle: subtitle),
    );
  }
}

/// Animowana zawartość kafelka „pracuję…": pulsująca ikona, tytuł z przesuwającym
/// się połyskiem i płynące kropki — spójne z animacją generowania obrazu.
class _LoadingContent extends StatefulWidget {
  final String title;
  final String subtitle;

  const _LoadingContent({required this.title, required this.subtitle});

  @override
  State<_LoadingContent> createState() => _LoadingContentState();
}

class _LoadingContentState extends State<_LoadingContent>
    with SingleTickerProviderStateMixin {
  static const _accent = Color(0xFF37B6FF);
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Pulsująca ikona w kaflu akcentu.
            AnimatedBuilder(
              animation: _c,
              builder: (context, child) {
                final pulse = 0.85 + 0.15 * (0.5 + 0.5 * math.sin(_c.value * math.pi * 2));
                return Transform.scale(scale: pulse, child: child);
              },
              child: const EmmaAccentIcon(
                icon: Icons.auto_awesome_rounded,
                color: _accent,
                size: 26,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: EmmaShimmerText(
                text: widget.title,
                animation: _c,
                baseColor: Colors.white.withAlpha(140),
                highlightColor: Colors.white,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedBuilder(
              animation: _c,
              builder: (context, _) =>
                  EmmaFlowingDots(t: _c.value, color: _accent),
            ),
          ],
        ),
        if (widget.subtitle.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 36),
            child: Text(
              widget.subtitle,
              style: TextStyle(
                color: Colors.white.withAlpha(150),
                fontSize: 11.5,
                height: 1.35,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
