import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/navigation_service.dart' show navigationService;
import 'package:core/platform/route_constant.dart';

import '../core/block_definition.dart';
import '../core/block_descriptor.dart';
import 'shared/block_ui.dart';
import 'shared/generating_placeholder.dart';

/// Blok wygenerowanego obrazu — z animacją „generowania" (shimmer + sparkle),
/// płynnym cross-fade do obrazu po załadowaniu i obsługą błędu.
class ImageBlockDefinition extends EmmaBlockDefinition {
  const ImageBlockDefinition();

  @override
  String get key => 'image';

  @override
  bool supports(EmmaBlockDescriptor block) => block.type == EmmaBlockType.image;

  @override
  Widget buildBlock({
    required BuildContext context,
    required WidgetRef ref,
    required EmmaBlockDescriptor block,
    required double maxWidth,
    required String messageId,
  }) {
    final url = (block.raw['url'] ?? block.raw['image_url'] ?? '').toString();
    final title = (block.raw['title'] ?? 'Wygenerowany obraz').toString();
    final caption = (block.raw['caption'] ?? '').toString();
    final savedToCloud = block.raw['saved_to_cloud'] == true ||
        (block.raw['cloud_file_id'] != null &&
            block.raw['cloud_file_id'].toString().isNotEmpty);
    final aspectRatio = emmaAspectRatioFrom(block.raw);

    return EmmaBlockCardShell(
      maxWidth: maxWidth,
      borderColor: const Color(0xFF9B6BFF),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: Color(0xFF9B6BFF), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _GeneratedImageView(url: url, aspectRatio: aspectRatio),
          if (url.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _MiniAction(
                  icon: Icons.fullscreen_rounded,
                  label: 'Pełny ekran',
                  onTap: () => _openFullscreen(context, url),
                ),
                _MiniAction(
                  icon: Icons.link_rounded,
                  label: 'Kopiuj link',
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: url));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Skopiowano link do obrazu')),
                      );
                    }
                  },
                ),
                if (savedToCloud)
                  _MiniAction(
                    icon: Icons.folder_open_rounded,
                    label: 'Cloud Storage',
                    tooltip: 'Zapisane w Cloud Storage → folder „Emma”',
                    onTap: () => ref
                        .read(navigationService)
                        .pushNamedScreen(Routes.cloudStorage),
                  ),
              ],
            ),
          ],
          if (caption.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              caption,
              style: TextStyle(
                  color: Colors.white.withAlpha(150), fontSize: 11, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}

void _openFullscreen(BuildContext context, String url) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black.withAlpha(235),
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.all(12),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 0.6,
              maxScale: 5.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(url, fit: BoxFit.contain),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: Material(
              color: Colors.black.withAlpha(120),
              shape: const CircleBorder(),
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _MiniAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? tooltip;
  const _MiniAction(
      {required this.icon, required this.label, required this.onTap, this.tooltip});

  @override
  Widget build(BuildContext context) {
    final button = InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withAlpha(30)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white.withAlpha(200)),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(color: Colors.white.withAlpha(210), fontSize: 11.5)),
          ],
        ),
      ),
    );
    if (tooltip != null && tooltip!.isNotEmpty) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}

class _GeneratedImageView extends StatefulWidget {
  final String url;
  final double aspectRatio;
  const _GeneratedImageView({required this.url, this.aspectRatio = 1.0});

  @override
  State<_GeneratedImageView> createState() => _GeneratedImageViewState();
}

class _GeneratedImageViewState extends State<_GeneratedImageView> {
  bool _loaded = false;
  // Minimalny czas animacji „generowania", żeby była widoczna nawet gdy obraz
  // wczyta się błyskawicznie (cache). Reveal dopiero po jej upływie.
  static const _minShimmer = Duration(milliseconds: 1500);
  DateTime? _start;

  @override
  void initState() {
    super.initState();
    _start = DateTime.now();
  }

  void _revealWhenReady() {
    if (_loaded || !mounted) return;
    final elapsed = DateTime.now().difference(_start ?? DateTime.now());
    final wait = _minShimmer - elapsed;
    if (wait > Duration.zero) {
      Future.delayed(wait, () {
        if (mounted) setState(() => _loaded = true);
      });
    } else {
      setState(() => _loaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);
    return GestureDetector(
      onTap: _loaded ? () => _openFullscreen(context, widget.url) : null,
      child: ClipRRect(
      borderRadius: radius,
      child: AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Placeholder „generowania" — widoczny dopóki obraz się nie załaduje.
            AnimatedOpacity(
              opacity: _loaded ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 450),
              child: const GeneratingPlaceholder(),
            ),
            if (widget.url.trim().isNotEmpty)
              Image.network(
                widget.url,
                fit: BoxFit.contain,
                gaplessPlayback: true,
                frameBuilder: (context, child, frame, wasSyncLoaded) {
                  final ready = wasSyncLoaded || frame != null;
                  if (ready && !_loaded) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _revealWhenReady();
                    });
                  }
                  return AnimatedOpacity(
                    opacity: _loaded ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 550),
                    curve: Curves.easeOut,
                    child: child,
                  );
                },
                errorBuilder: (_, __, ___) => const _ImageError(),
              )
            else
              const _ImageError(),
          ],
        ),
      ),
      ),
    );
  }
}

class _ImageError extends StatelessWidget {
  const _ImageError();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF241C1C),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image_outlined,
                color: Colors.redAccent.withAlpha(180), size: 30),
            const SizedBox(height: 8),
            Text('Nie udało się załadować obrazu',
                style: TextStyle(color: Colors.white.withAlpha(160), fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
