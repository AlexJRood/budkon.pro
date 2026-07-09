import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/common/shared_widgets/article_model.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/common/loading_widgets.dart';
import 'package:pie_menu/pie_menu.dart';

typedef ArticlePieActionsBuilder = List<PieAction> Function(
    WidgetRef ref, dynamic article, BuildContext context);

/// Seam: the portal module installs the article pie-menu actions at startup
/// (via an override), so this shared card renders them without importing portal.
final articlePieActionsProvider =
    Provider<ArticlePieActionsBuilder?>((ref) => null);

class ArticleCardWidget extends ConsumerStatefulWidget {
  final String imageUrl;
  final String title;
  final String description;
  final String readMoreUrl;
  final Article? article;
  final String? tag;

  const ArticleCardWidget({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.readMoreUrl,
    this.article,
    this.tag,
  });

  @override
  ConsumerState<ArticleCardWidget> createState() => _ArticleCardWidgetState();
}

class _ArticleCardWidgetState extends ConsumerState<ArticleCardWidget> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => _buildCard(context, constraints.maxWidth),
    );
  }

  Widget _buildCard(BuildContext context, double cardWidth) {
    final theme = ref.watch(themeColorsProvider);
    final textColor = theme.textColor;
    final fadedTextColor = textColor.withAlpha(204);
    final borderRadius = BorderRadius.circular(10);

    // use the ConsumerState's ref – do NOT pass WidgetRef from outside
    final nav = ref.read(navigationService);
    final currentPath = nav.currentPath == '/' ? '' : nav.currentPath;

    // safe hero tag
    final String heroTag =
        widget.tag ?? 'article-${widget.article?.slug ?? widget.title}-hero';

    final dpr = MediaQuery.of(context).devicePixelRatio;
    // scale the image with the card's width so narrower (mobile) cards
    // don't force a fixed 300px tall image and overflow the card
    final double imgHeight = (cardWidth * 1.15).clamp(140.0, 300.0);

    // limit decode size
    final int memW = (cardWidth * dpr).round().clamp(200, 1200);
    final int memH = (imgHeight * dpr).round().clamp(200, 1200);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _hovering ? Colors.grey.withAlpha(20) : Colors.transparent,
          borderRadius: borderRadius,
        ),
        child: PieMenu(
          theme: PieTheme.of(context).copyWith(
            overlayColor:
                (() {
                  final theme = ref.watch(themeColorsProvider);
                  final bool uiIsDark =
                      theme.textColor.computeLuminance() > 0.5;

                  final base = uiIsDark ? Colors.black : Colors.white;
                  return base.withValues(alpha: 0.70);
                })(),
          ),
          onPressedWithDevice: (kind) {
            if (kind == PointerDeviceKind.mouse ||
                kind == PointerDeviceKind.touch) {
              if (widget.article != null) {
                nav.openPopup(
                  '$currentPath/article/${widget.article!.slug}',
                  data: {'articles': widget.article, 'tagArticlesPop': heroTag},
                );
              } else {
                // fallback: open external link or do nothing
              }
            }
          },
          actions: ref.watch(articlePieActionsProvider)?.call(ref, widget.article, context) ?? const <PieAction>[],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image + overlay
              Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(10),
                    ),
                    child: Hero(
                      tag: heroTag,
                      child: CachedNetworkImage(
                        height: imgHeight,
                        width: double.infinity,
                        imageUrl: widget.imageUrl,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.low,
                        memCacheWidth: memW,
                        memCacheHeight: memH,
                        placeholder:
                            (context, url) => ShimmerPlaceholder(
                              width: cardWidth,
                              height: imgHeight,
                            ),
                        errorWidget:
                            (context, url, error) => Container(
                              height: imgHeight,
                              color: Colors.grey,
                              alignment: Alignment.center,
                              child: Text(
                                'no_image'.tr,
                                style: TextStyle(color: textColor),
                              ),
                            ),
                      ),
                    ),
                  ),
                  AnimatedOpacity(
                    opacity: _hovering ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      height: imgHeight,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  AnimatedOpacity(
                    opacity: _hovering ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child:  Text(
                      'Read more'.tr,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              // Title
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                color: _hovering
                    ? Colors.black.withAlpha(8)
                    : Colors.transparent,
                padding:
                const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                child: Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Description
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                color: _hovering
                    ? Colors.black.withAlpha(8)
                    : Colors.transparent,
                padding:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                child: Text(
                  widget.description,
                  style: TextStyle(fontSize: 16, color: fadedTextColor),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

// class HoverImageOverlay extends StatefulWidget {
//   final String imageUrl;
//   final double height;
//   final BorderRadius borderRadius;
//
//   const HoverImageOverlay({
//     super.key,
//     required this.imageUrl,
//     required this.height,
//     required this.borderRadius,
//   });
//
//   @override
//   State<HoverImageOverlay> createState() => _HoverImageOverlayState();
// }
//
// class _HoverImageOverlayState extends State<HoverImageOverlay> {
//   bool _hovering = false;
//
//   @override
//   Widget build(BuildContext context) {
//     final isMobile = MediaQuery.of(context).size.width < 600;
//
//     return MouseRegion(
//       onEnter: (_) => setState(() => _hovering = true),
//       onExit: (_) => setState(() => _hovering = false),
//       child: Stack(
//         alignment: Alignment.center,
//         children: [
//           ClipRRect(
//             borderRadius: widget.borderRadius,
//             child: CachedNetworkImage(
//               height: widget.height,
//               width: double.infinity,
//               imageUrl: widget.imageUrl,
//               fit: BoxFit.cover,
//               placeholder: (context, url) =>
//                   const ShimmerPlaceholder(width: 0, height: 0),
//               errorWidget: (context, url, error) => Container(
//                 height: widget.height,
//                 color: Colors.grey,
//                 alignment: Alignment.center,
//                 child: const Icon(Icons.broken_image),
//               ),
//             ),
//           ),
//           // Overlay
//           if (!isMobile)
//             AnimatedOpacity(
//               opacity: _hovering ? 0.5 : 0.0,
//               duration: const Duration(milliseconds: 200),
//               child: Container(
//                 height: widget.height,
//                 width: double.infinity,
//                 decoration: BoxDecoration(
//                   color: Colors.black,
//                   borderRadius: widget.borderRadius,
//                 ),
//               ),
//             ),
//           // Text
//           if (!isMobile)
//             AnimatedOpacity(
//               opacity: _hovering ? 1.0 : 0.0,
//               duration: const Duration(milliseconds: 200),
//               child: const Text(
//                 'Read more',
//                 style: TextStyle(
//                   fontSize: 22,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }
