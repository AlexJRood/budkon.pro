import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/icons.dart';
import 'package:core/theme/design.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class FullScreenImageView extends ConsumerStatefulWidget {
  final String tag;
  final List<String> images;
  final int initialPage;

  const FullScreenImageView({
    super.key,
    required this.tag,
    required this.images,
    this.initialPage = 0,
  });

  @override
  FullScreenImageViewState createState() => FullScreenImageViewState();
}

class FullScreenImageViewState extends ConsumerState<FullScreenImageView> {
  late PageController _pageController;
  late FocusNode _focusNode;
  double _offset = 0.0;

  bool _isDragging = false;
  double _dragStartX = 0;
  double _dragStartPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialPage);
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _goToNextImage() {
    if ((_pageController.page ?? 0).toInt() < widget.images.length - 1) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  void _goToPreviousImage() {
    if ((_pageController.page ?? 0).toInt() > 0) {
      _pageController.previousPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _goToNextImage();
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _goToPreviousImage();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final pageWidth = MediaQuery.of(context).size.width;

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Listener(
              onPointerSignal: (pointerSignal) {
                if (pointerSignal is PointerScrollEvent) {
                  if (pointerSignal.scrollDelta.dy > 0) {
                    _goToNextImage();
                  } else if (pointerSignal.scrollDelta.dy < 0) {
                    _goToPreviousImage();
                  }
                }
              },
              onPointerDown: (event) {
                if (event.kind == PointerDeviceKind.mouse &&
                    event.buttons == kPrimaryMouseButton) {
                  _isDragging = true;
                  _dragStartX = event.position.dx;
                  _dragStartPage =
                      _pageController.page ?? widget.initialPage.toDouble();
                }
              },
              onPointerMove: (event) {
                if (!_isDragging || event.kind != PointerDeviceKind.mouse) return;
                final delta = event.position.dx - _dragStartX;
                final targetPixels =
                    (_dragStartPage * pageWidth - delta)
                        .clamp(0.0, (widget.images.length - 1) * pageWidth);
                _pageController.jumpTo(targetPixels);
              },
              onPointerUp: (event) {
                if (!_isDragging) return;
                _isDragging = false;
                final currentPage =
                    _pageController.page ?? _dragStartPage;
                _pageController.animateToPage(
                  currentPage.round().clamp(0, widget.images.length - 1),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              },
              onPointerCancel: (_) => _isDragging = false,
              child: GestureDetector(
                onVerticalDragUpdate: (details) {
                  setState(() {
                    _offset += details.primaryDelta!;
                  });
                },
                onVerticalDragEnd: (details) {
                  if (_offset > 50) {
                    Navigator.pop(context);
                  } else {
                    setState(() {
                      _offset = 0;
                    });
                  }
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.grab,
                  child: Transform.translate(
                    offset: Offset(0, _offset),
                    child: PhotoViewGallery.builder(
                      itemCount: widget.images.length,
                      pageController: _pageController,
                      backgroundDecoration:
                          const BoxDecoration(color: Colors.black),
                      builder: (context, index) {
                        return PhotoViewGalleryPageOptions(
                          imageProvider: NetworkImage(widget.images[index]),
                          heroAttributes: PhotoViewHeroAttributes(
                              tag: widget.tag + index.toString()),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 20,
              left: 20,
              child: SafeArea(
                top: false,
                bottom: false,
                child: CircleAvatar(
                  backgroundColor: Colors.black45,
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_rounded,
                      color: AppColors.light,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 20,
              top: MediaQuery.of(context).size.height * 0.5 - 30,
              child: SafeArea(
                top: false,
                bottom: false,
                child: IconButton(
                  icon: AppIcons.iosArrowLeft(
                      height: 30, width: 30, color: Colors.white),
                  onPressed: _goToPreviousImage,
                ),
              ),
            ),
            Positioned(
              right: 20,
              top: MediaQuery.of(context).size.height * 0.5 - 30,
              child: SafeArea(
                top: false,
                bottom: false,
                child: IconButton(
                  icon: AppIcons.iosArrowRight(
                      height: 30, width: 30, color: Colors.white),
                  onPressed: _goToNextImage,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
