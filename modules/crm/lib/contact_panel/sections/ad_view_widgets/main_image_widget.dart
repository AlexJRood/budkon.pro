import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:core/theme/apptheme.dart';

class MainImageWidget extends ConsumerStatefulWidget {
  const MainImageWidget({
    super.key,
    required this.mainImageBytes,
    required this.mainImageUrl,
    required this.mainImageWidth,
    required this.mainImageHeight,
    required this.canNavigateImages,
    required this.imageCount,
    this.onPrevPressed,
    this.onNextPressed,
    this.onRemovePressed,
    this.showRemoveButton = false,
    this.onAddPressed,
  });

  final Uint8List? mainImageBytes;
  final String? mainImageUrl;
  final double mainImageWidth;
  final double mainImageHeight;
  final bool canNavigateImages;
  final int imageCount;
  final VoidCallback? onPrevPressed;
  final VoidCallback? onNextPressed;
  final VoidCallback? onRemovePressed;
  final bool showRemoveButton;

  /// Called when the placeholder (no photo) is tapped.
  ///
  /// Lets the user add a photo directly, without switching to edit mode
  /// first.
  final VoidCallback? onAddPressed;

  @override
  ConsumerState<MainImageWidget> createState() => _MainImageState();
}

class _MainImageState extends ConsumerState<MainImageWidget> {
  bool _hovered = false;

  bool get _hasImage =>
      widget.mainImageBytes != null ||
      (widget.mainImageUrl != null && widget.mainImageUrl!.trim().isNotEmpty);

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final isCompact = MediaQuery.of(context).size.width < 900;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: widget.mainImageWidth,
          height: widget.mainImageHeight,
          decoration: BoxDecoration(
            color: theme.dashboardContainer.withAlpha(120),
            border: Border.all(
              color: theme.textFieldColor.withAlpha(110),
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildImage(theme),
              _buildSoftGradientOverlay(),

              if (widget.imageCount > 0)
                Positioned(
                  top: 14,
                  right: widget.showRemoveButton && _hasImage ? 62 : 14,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(105),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withAlpha(30),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.photo_library_outlined,
                          size: 15,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${widget.imageCount} ${'photos_count_label'.tr}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              if (widget.showRemoveButton && _hasImage)
                Positioned(
                  top: 14,
                  right: 14,
                  child: _ImageActionButton(
                    icon: Icons.delete_outline_rounded,
                    tooltip: 'remove_current_photo_tooltip'.tr,
                    onTap: widget.onRemovePressed,
                  ),
                ),

              if (widget.canNavigateImages) ...[
                Positioned(
                  left: 14,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _ImageNavButton(
                      icon: Icons.chevron_left_rounded,
                      visible: _hovered || isCompact,
                      onTap: widget.onPrevPressed,
                    ),
                  ),
                ),
                Positioned(
                  right: 14,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _ImageNavButton(
                      icon: Icons.chevron_right_rounded,
                      visible: _hovered || isCompact,
                      onTap: widget.onNextPressed,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(ThemeColors theme) {
    if (widget.mainImageBytes != null) {
      return Image.memory(
        widget.mainImageBytes!,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      );
    }

    if (widget.mainImageUrl != null && widget.mainImageUrl!.trim().isNotEmpty) {
      return Image.network(
        widget.mainImageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _emptyPlaceholder(theme),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Stack(
            fit: StackFit.expand,
            children: [
              Container(color: theme.dashboardContainer.withAlpha(120)),
              const Center(
                child: SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ],
          );
        },
      );
    }

    return _emptyPlaceholder(theme);
  }

  Widget _emptyPlaceholder(ThemeColors theme) {
    final canAdd = widget.onAddPressed != null;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          canAdd ? Icons.add_photo_alternate_outlined : Icons.image_not_supported_outlined,
          size: 44,
          color: theme.textColor.withAlpha(140),
        ),
        const SizedBox(height: 10),
        Text(
          canAdd ? 'add_photo_label'.tr : 'no_photo_label'.tr,
          style: TextStyle(
            color: theme.textColor.withAlpha(170),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );

    return Material(
      color: theme.dashboardContainer.withAlpha(120),
      child: InkWell(
        onTap: canAdd ? widget.onAddPressed : null,
        child: Center(child: content),
      ),
    );
  }

  Widget _buildSoftGradientOverlay() {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withAlpha(18),
              Colors.transparent,
              Colors.transparent,
              Colors.black.withAlpha(28),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageNavButton extends StatelessWidget {
  const _ImageNavButton({
    required this.icon,
    required this.visible,
    this.onTap,
  });

  final IconData icon;
  final bool visible;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: visible ? 1 : 0.55,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(85),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withAlpha(26),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white.withAlpha(230),
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}

class _ImageActionButton extends StatelessWidget {
  const _ImageActionButton({
    required this.icon,
    required this.tooltip,
    this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(105),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withAlpha(26),
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}